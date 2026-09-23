import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/novo_id.dart';
import '../../fila/presentation/fila_controlador.dart';
import '../../reproducao/presentation/reproducao_controlador.dart';
import '../data/configuracao_de_captura.dart';
import '../data/gravador_record.dart';
import '../data/repositorio_amostras_local.dart';
import '../domain/afericao_de_ruido.dart';
import '../domain/amostra.dart';
import '../domain/cabecalho_wav.dart';
import '../domain/gravador.dart';
import '../domain/verificacao_da_amostra.dart';

/// Por que a gravação não começou ou não terminou.
enum FalhaDaGravacao {
  semPermissao,
  naoIniciou,
  naoFinalizou,

  /// O fluxo de nível deu erro ou acabou sozinho no meio da gravação — o
  /// microfone parou de responder. A gravação é descartada: ter leituras
  /// boas antes da queda não faz dela uma amostra confiável.
  interrompida,
}

/// Estado das gravações de uma sessão.
class EstadoDaGravacao {
  const EstadoDaGravacao({
    required this.sessaoId,
    this.amostras = const {},
    this.rejeitadas = const {},
    this.gravando,
    this.conferindo,
    this.nivel,
    this.decorrido = Duration.zero,
    this.falha,
    this.enviando = false,
  });

  final String sessaoId;

  /// Pondo a sessão na fila de envio. Curto — a fila só registra —, mas é o
  /// que impede o segundo toque de criar um segundo envio.
  final bool enviando;

  /// A amostra guardada de cada tarefa: a mais recente que passou na
  /// conferência. Pode ter ressalvas (saturação), nunca problema que invalide.
  final Map<TarefaDeGravacao, Amostra> amostras;

  /// A última tentativa descartada de cada tarefa, com o porquê.
  ///
  /// Gravação inválida NÃO substitui a amostra boa anterior: a coleta não se
  /// repete, e um microfone que emudeceu na regravação não pode apagar a
  /// gravação que tinha dado certo.
  final Map<TarefaDeGravacao, List<ProblemaNaAmostra>> rejeitadas;

  /// A tarefa sendo gravada agora, se houver. Uma de cada vez: há um
  /// microfone só.
  final TarefaDeGravacao? gravando;

  /// A tarefa cujo arquivo está sendo conferido, logo depois de parar.
  final TarefaDeGravacao? conferindo;

  /// Última leitura do medidor durante a gravação.
  final double? nivel;
  final Duration decorrido;

  /// A última tentativa que falhou, e em qual tarefa.
  final ({TarefaDeGravacao tarefa, FalhaDaGravacao motivo})? falha;

  bool get ocupado => gravando != null || conferindo != null || enviando;

  /// Todas as tarefas do protocolo gravadas, e todas válidas.
  bool get completa =>
      TarefaDeGravacao.values.every((t) => amostras[t]?.valida ?? false);
}

/// Grava as tarefas de UMA sessão de UM paciente.
///
/// Cada vez que a tela abre é uma sessão nova. TODO(equipe): retomar a sessão
/// em andamento em vez de abrir outra — as gravações dela já ficam no banco
/// local (`RepositorioAmostras.daSessao`), mas sair da tela no meio ainda
/// deixa a sessão para trás.
class GravacaoControlador extends Notifier<EstadoDaGravacao> {
  GravacaoControlador(this.pacienteId);

  final String pacienteId;

  late Gravador _gravador;
  final _leituras = <double>[];
  StreamSubscription<double>? _inscricao;
  String? _caminho;

  @override
  EstadoDaGravacao build() {
    // `watch`: o gravador vive enquanto o controlador viver, e o descarte dos
    // dois — ao sair da tela — para e apaga uma gravação pela metade.
    _gravador = ref.watch(gravadorProvider);
    ref.onDispose(() => unawaited(_inscricao?.cancel()));
    return EstadoDaGravacao(
      // Também forma a chave de idempotência do envio (`envio-<sessão>`): não
      // pode repetir entre aparelhos.
      sessaoId: novoId(),
    );
  }

  Future<void> iniciar(TarefaDeGravacao tarefa) async {
    if (state.ocupado) return;
    // O som do alto-falante entraria no microfone: nada toca enquanto grava.
    if (ref.exists(reproducaoControladorProvider)) {
      await ref.read(reproducaoControladorProvider.notifier).parar();
      if (!ref.mounted || state.ocupado) return;
    }
    state = EstadoDaGravacao(
      sessaoId: state.sessaoId,
      amostras: state.amostras,
      rejeitadas: state.rejeitadas,
      gravando: tarefa,
    );

    // Cada espera abaixo pode terminar com a tela já fechada. Sem conferir,
    // o microfone abriria sem ninguém olhando — achado da revisão de 23/09.
    final arquivos = ref.read(arquivosDeAmostraProvider);
    String? caminho;
    try {
      if (!await _gravador.pedirPermissao()) {
        _falhar(tarefa, FalhaDaGravacao.semPermissao);
        return;
      }
      if (!ref.mounted) return;
      caminho = await arquivos.novoCaminho(pacienteId, tarefa);
      if (!ref.mounted) return;
      _caminho = caminho;
      _leituras.clear();
      final niveis = await _gravador.iniciar(
        caminho,
        AfericaoDeRuido.intervalo,
      );
      if (!ref.mounted) {
        // Abriu depois de a tela fechar: fecha de novo e não deixa arquivo.
        await _descartar(arquivos, caminho);
        return;
      }
      _inscricao = niveis.listen(
        (nivel) {
          _leituras.add(nivel);
          if (!ref.mounted) return;
          state = EstadoDaGravacao(
            sessaoId: state.sessaoId,
            amostras: state.amostras,
            rejeitadas: state.rejeitadas,
            gravando: tarefa,
            nivel: nivel,
            decorrido: AfericaoDeRuido.intervalo * _leituras.length,
          );
        },
        // Sem estes dois, um erro do plugin escaparia para a zona, e um fluxo
        // que acabasse sozinho deixaria a tela em "gravando" para sempre.
        onError: (Object _) => unawaited(_interromper(tarefa)),
        onDone: () => unawaited(_interromper(tarefa)),
      );
    } catch (_) {
      _caminho = null;
      await _descartar(arquivos, caminho);
      _falhar(tarefa, FalhaDaGravacao.naoIniciou);
    }
  }

  /// O microfone parou de responder no meio da gravação.
  Future<void> _interromper(TarefaDeGravacao tarefa) async {
    // Parar de propósito cancela a inscrição antes; aqui só chega a queda.
    if (!ref.mounted || state.gravando != tarefa) return;
    final caminho = _caminho;
    unawaited(_inscricao?.cancel());
    _inscricao = null;
    _caminho = null;
    await _descartar(ref.read(arquivosDeAmostraProvider), caminho);
    _falhar(tarefa, FalhaDaGravacao.interrompida);
  }

  /// Para o gravador e apaga o arquivo começado, sem deixar falha de limpeza
  /// esconder o motivo de verdade.
  Future<void> _descartar(ArquivosDeAmostra arquivos, String? caminho) async {
    try {
      await _gravador.descartar();
    } catch (_) {}
    if (caminho != null) {
      try {
        await arquivos.apagar(caminho);
      } catch (_) {}
    }
  }

  Future<void> parar() async {
    final tarefa = state.gravando;
    final caminho = _caminho;
    if (tarefa == null || caminho == null) return;

    // Não esperar o cancelamento — ver o mesmo cuidado na aferição.
    unawaited(_inscricao?.cancel());
    _inscricao = null;
    _caminho = null;
    final leituras = List<double>.of(_leituras);

    state = EstadoDaGravacao(
      sessaoId: state.sessaoId,
      amostras: state.amostras,
      rejeitadas: state.rejeitadas,
      conferindo: tarefa,
    );

    final arquivos = ref.read(arquivosDeAmostraProvider);
    try {
      await _gravador.parar();
      final lido = await arquivos.ler(caminho);
      if (!ref.mounted) return;

      final cabecalho = lido == null ? null : lerCabecalhoWav(lido.inicio);
      final problemas = VerificacaoDaAmostra.verificar(
        cabecalho: cabecalho,
        tamanhoDoArquivo: lido?.tamanho ?? 0,
        leituras: leituras,
        taxaPedida: ConfiguracaoDeCaptura.taxaDeAmostragem,
        canaisPedidos: ConfiguracaoDeCaptura.canais,
      );
      if (problemas.any((p) => p.invalida)) {
        // Descartada: o arquivo sai, a amostra anterior (se houver) fica.
        await arquivos.apagar(caminho);
        if (!ref.mounted) return;
        state = EstadoDaGravacao(
          sessaoId: state.sessaoId,
          amostras: state.amostras,
          rejeitadas: {...state.rejeitadas, tarefa: problemas},
        );
        return;
      }

      final amostra = Amostra(
        id: novoId(),
        pacienteId: pacienteId,
        sessaoId: state.sessaoId,
        tarefa: tarefa,
        caminho: caminho,
        gravadaEm: DateTime.now(),
        duracao: cabecalho!.duracao,
        taxaDeAmostragem: cabecalho.taxaDeAmostragem,
        canais: cabecalho.canais,
        problemas: problemas,
      );

      await ref.read(repositorioAmostrasProvider).guardar(amostra);
      // A anterior da mesma tarefa foi substituída no registro; o arquivo
      // dela não tem mais quem o referencie.
      final anterior = state.amostras[tarefa];
      if (anterior != null) await arquivos.apagar(anterior.caminho);

      if (!ref.mounted) return;
      state = EstadoDaGravacao(
        sessaoId: state.sessaoId,
        amostras: {...state.amostras, tarefa: amostra},
        rejeitadas: {...state.rejeitadas}..remove(tarefa),
      );
    } catch (_) {
      await arquivos.apagar(caminho).catchError((_) {});
      _falhar(tarefa, FalhaDaGravacao.naoFinalizou);
    }
  }

  /// Põe a sessão na fila de envio para a análise. Devolve `true` se pôs.
  ///
  /// Só com todas as tarefas gravadas e válidas. Funciona sem conexão: a fila
  /// guarda e envia quando der.
  Future<bool> enviarParaAnalise({required String nomeDoPaciente}) async {
    if (!state.completa || state.ocupado) return false;
    final anterior = state;
    state = EstadoDaGravacao(
      sessaoId: anterior.sessaoId,
      amostras: anterior.amostras,
      rejeitadas: anterior.rejeitadas,
      enviando: true,
    );
    try {
      await ref
          .read(filaControladorProvider.notifier)
          .enfileirar(
            pacienteId: pacienteId,
            nomeDoPaciente: nomeDoPaciente,
            sessaoId: anterior.sessaoId,
            amostras: [
              for (final t in TarefaDeGravacao.values) anterior.amostras[t]!,
            ],
          );
      return true;
    } catch (_) {
      if (ref.mounted) state = anterior;
      return false;
    }
  }

  void _falhar(TarefaDeGravacao tarefa, FalhaDaGravacao motivo) {
    if (!ref.mounted) return;
    state = EstadoDaGravacao(
      sessaoId: state.sessaoId,
      amostras: state.amostras,
      rejeitadas: state.rejeitadas,
      falha: (tarefa: tarefa, motivo: motivo),
    );
  }
}

final gravacaoControladorProvider = NotifierProvider.autoDispose
    .family<GravacaoControlador, EstadoDaGravacao, String>(
      GravacaoControlador.new,
    );
