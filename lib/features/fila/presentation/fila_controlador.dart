import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/conexao.dart';
import '../../../core/relogio.dart';
import '../../auth/data/sessao.dart';
import '../../captura/domain/amostra.dart';
import '../data/envio_de_analise_api.dart';
import '../data/repositorio_fila_local.dart';
import '../domain/item_da_fila.dart';
import '../domain/repositorio_fila.dart';

/// A fila de sincronização, viva enquanto o app estiver aberto.
///
/// Não é `autoDispose` de propósito: a fila trabalha sem ninguém olhando. O
/// profissional manda para análise, vai atender o próximo paciente, e o envio
/// acontece quando a rede deixar. Quem a acorda na abertura do app é o
/// `FonarApp`.
///
/// Regras:
/// - um envio por vez, do mais antigo para o mais novo — WAV sem compressão
///   pesa, e dois ao mesmo tempo em rede de consultório só atrasam os dois;
/// - sem conexão, nada é tentado; quando a conexão volta, tudo o que esperava
///   por ela é tentado na hora, sem esperar o fim da espera;
/// - sem sessão aberta, também nada: sair da conta pausa a fila e interrompe
///   o envio em curso, e entrar de novo a retoma (ver `Sessao`);
/// - falha passageira espera cada vez mais (ver [PoliticaDeReenvio]); sessão
///   expirada e envio recusado não se repetem sozinhos.
class FilaControlador extends AsyncNotifier<List<ItemDaFila>> {
  Timer? _proxima;
  var _processando = false;

  /// O cancelamento do envio que está no ar, se houver.
  Cancelamento? _emCurso;

  /// O item desse envio.
  String? _idEmCurso;

  /// Há rede e há quem esteja com a sessão aberta.
  bool get _podeEnviar =>
      ref.read(conexaoOnlineProvider) && ref.read(sessaoAbertaProvider);

  DateTime _agora() => ref.read(relogioProvider)();

  @override
  Future<List<ItemDaFila>> build() async {
    ref.onDispose(() => _proxima?.cancel());
    ref.listen(conexaoOnlineProvider, (antes, online) {
      if (online && antes != true) unawaited(_aoVoltarConexao());
    });
    ref.listen(sessaoAbertaProvider, (antes, aberta) {
      if (aberta && antes != true) {
        unawaited(_aoVoltarConexao());
      } else if (!aberta) {
        // Saiu da conta: nenhum relógio armado, e o que está subindo para.
        _proxima?.cancel();
        _proxima = null;
        _emCurso?.pedir();
      }
    });

    final repositorio = ref.read(repositorioFilaProvider);
    final itens = [
      for (final item in await repositorio.listar())
        await _recuperarInterrompido(repositorio, item),
    ];
    // Depois de o estado existir: o que ficou pendente de antes sobe já.
    Future.microtask(processar);
    return itens;
  }

  /// Item que ficou gravado como "enviando" sem envio nenhum no ar: o app
  /// fechou no meio do upload. Volta para a fila com a MESMA chave — se a API
  /// chegou a receber, a chave de idempotência evita a análise em dobro.
  ///
  /// Só aqui, na carga, e não a cada leitura da lista: fora da carga,
  /// "enviando" pode ser um envio de verdade em curso (revisão de 24/09).
  Future<ItemDaFila> _recuperarInterrompido(
    RepositorioFila repositorio,
    ItemDaFila item,
  ) async {
    if (item.situacao != SituacaoDoEnvio.enviando || item.id == _idEmCurso) {
      return item;
    }
    final recuperado = item.copiar(
      situacao: SituacaoDoEnvio.naFila,
      proximaTentativa: () => null,
    );
    await repositorio.atualizar(recuperado);
    return recuperado;
  }

  /// Põe uma sessão gravada na fila. Funciona sem conexão.
  Future<ItemDaFila> enfileirar({
    required String pacienteId,
    required String nomeDoPaciente,
    required String sessaoId,
    required List<Amostra> amostras,
  }) async {
    await _carregada();
    // Uma sessão, um envio. Mandar de novo a mesma sessão devolve o envio que
    // já existe em vez de criar outro — e a análise não sai em dobro.
    final existente = _itens.where((i) => i.sessaoId == sessaoId).firstOrNull;
    if (existente != null) return existente;

    final item = ItemDaFila(
      // É também a chave de idempotência do envio. Vem da sessão, que é
      // única, e não do relógio: dois envios criados no mesmo instante
      // ganhariam a mesma chave, e a API juntaria duas sessões numa análise.
      id: 'envio-$sessaoId',
      pacienteId: pacienteId,
      nomeDoPaciente: nomeDoPaciente,
      sessaoId: sessaoId,
      amostras: amostras,
      criadoEm: _agora(),
    );
    await ref.read(repositorioFilaProvider).adicionar(item);
    if (!ref.mounted) return item;
    _publicar([..._itens, item]);
    unawaited(processar());
    return item;
  }

  /// O profissional pediu para tentar de novo, sem esperar.
  Future<void> tentarAgora(String id) async {
    await _carregada();
    final item = _itens.where((i) => i.id == id).firstOrNull;
    if (item == null || !item.pendente) return;
    if (item.situacao == SituacaoDoEnvio.enviando) return;
    await _salvar(
      item.copiar(
        situacao: SituacaoDoEnvio.naFila,
        proximaTentativa: () => null,
      ),
    );
    await processar();
  }

  /// Envia, um por vez, tudo o que estiver pronto. Chamar de novo enquanto
  /// roda não faz nada — quem está rodando pega o que chegou.
  Future<void> processar() async {
    if (_processando) return;
    _processando = true;
    try {
      await _carregada();
      while (ref.mounted && _podeEnviar) {
        final agora = _agora();
        final proximo = _itens.where((i) => i.prontoEm(agora)).firstOrNull;
        if (proximo == null) break;
        await _enviar(proximo);
      }
    } finally {
      _processando = false;
      if (ref.mounted) _agendar();
    }
  }

  Future<void> _enviar(ItemDaFila item) async {
    // O cancelamento existe desde o começo, e não só quando o upload
    // começa: sair da conta durante as esperas abaixo também precisa ser
    // visto. Antes, quem saía nesse meio-tempo não achava envio nenhum para
    // interromper, e o upload começava com a sessão já fechada (revisão de
    // 24/09).
    final cancelamento = Cancelamento();
    _emCurso = cancelamento;
    _idEmCurso = item.id;
    try {
      final tentativas = item.tentativas + 1;
      await _salvar(
        item.copiar(situacao: SituacaoDoEnvio.enviando, tentativas: tentativas),
      );
      // Toda espera pode terminar com a fila descartada (app fechando).
      if (!ref.mounted) return;
      // Última conferência antes de transmitir: ninguém pediu para parar, e
      // ainda há rede e sessão.
      if (cancelamento.pedido || !_podeEnviar) {
        await _devolverAFila(item);
        return;
      }

      try {
        final analiseId = await ref
            .read(envioDeAnaliseProvider)
            .enviar(item, cancelamento: cancelamento);
        if (!ref.mounted) return;
        await _salvar(
          item.copiar(
            situacao: SituacaoDoEnvio.enviado,
            tentativas: tentativas,
            analiseId: analiseId,
            proximaTentativa: () => null,
            ultimaFalha: () => null,
          ),
        );
      } catch (erro) {
        if (!ref.mounted) return;
        // O contrato é lançar só AppException. Se outra coisa escapar, o item
        // não pode ficar preso em "enviando" para sempre: vira falha
        // passageira.
        final falha = erro is AppException
            ? erro
            : FalhaDesconhecida(causa: erro);
        // Interrompido porque o profissional saiu: não foi falha do envio.
        if (falha is EnvioCancelado && cancelamento.pedido) {
          await _devolverAFila(item);
          return;
        }
        final situacao = PoliticaDeReenvio.depoisDe(falha);
        await _salvar(
          item.copiar(
            situacao: situacao,
            tentativas: tentativas,
            ultimaFalha: () => falha.mensagem,
            proximaTentativa: () =>
                situacao == SituacaoDoEnvio.aguardandoNovaTentativa
                ? _agora().add(PoliticaDeReenvio.esperaApos(tentativas))
                : null,
          ),
        );
      }
    } finally {
      if (identical(_emCurso, cancelamento)) {
        _emCurso = null;
        _idEmCurso = null;
      }
    }
  }

  /// O envio foi interrompido antes de ser tentado de verdade: volta para a
  /// fila como estava, sem contar tentativa nem esperar.
  Future<void> _devolverAFila(ItemDaFila item) => _salvar(
    item.copiar(situacao: SituacaoDoEnvio.naFila, proximaTentativa: () => null),
  );

  /// A conexão voltou, ou a sessão abriu: o que esperava não precisa mais
  /// esperar.
  ///
  /// TODO(verificar em aparelho): testado só num ProviderContainer sem a
  /// árvore de widgets, onde o Riverpod não propaga a mudança de rede
  /// sozinho. Conferir no Android e no Windows: desligar a rede, mandar uma
  /// gravação, religar e ver se ela sobe sem tocar em nada.
  Future<void> _aoVoltarConexao() async {
    if (!ref.mounted) return;
    await _carregada();
    final esperando = [
      for (final i in _itens)
        if (i.situacao == SituacaoDoEnvio.aguardandoNovaTentativa) i.id,
    ];
    for (final id in esperando) {
      if (!ref.mounted) return;
      // Relido a cada passo: entre um salvar e outro a fila pode ter mexido
      // no item.
      final atual = _itens.where((i) => i.id == id).firstOrNull;
      if (atual?.situacao == SituacaoDoEnvio.aguardandoNovaTentativa) {
        await _salvar(atual!.copiar(proximaTentativa: () => null));
      }
    }
    await processar();
  }

  /// Acorda a fila na hora da próxima tentativa agendada, se houver.
  ///
  /// Sem conexão, nenhum relógio: quem acorda a fila é a volta da rede
  /// ([_aoVoltarConexao]). Com um prazo já vencido, um temporizador armado
  /// offline disparava na hora, achava a rede fora e se reagendava — um
  /// ciclo sem pausa, gastando bateria justamente sem rede (achado da
  /// revisão de 23/09).
  void _agendar() {
    _proxima?.cancel();
    _proxima = null;
    if (!_podeEnviar) return;
    final agendadas = [
      for (final i in _itens)
        if (i.situacao == SituacaoDoEnvio.aguardandoNovaTentativa &&
            i.proximaTentativa != null)
          i.proximaTentativa!,
    ];
    if (agendadas.isEmpty) return;
    final maisCedo = agendadas.reduce((a, b) => a.isBefore(b) ? a : b);
    final espera = maisCedo.difference(_agora());
    _proxima = Timer(espera.isNegative ? Duration.zero : espera, () {
      unawaited(processar());
    });
  }

  Future<void> _salvar(ItemDaFila item) async {
    if (!ref.mounted) return;
    await ref.read(repositorioFilaProvider).atualizar(item);
    // A lista é lida AGORA, depois da espera, e não antes: ler antes de
    // esperar e escrever depois desfaria o que mudou nesse meio-tempo — um
    // item que virou "enviando" voltaria a "na fila" e subiria duas vezes.
    _publicar([for (final i in _itens) i.id == item.id ? item : i]);
  }

  /// Espera a primeira carga da lista — e só ela.
  ///
  /// Não é `await future` direto: chamado de dentro do aviso de mudança de
  /// conexão, o `future` do notifier ficava esperando para sempre, e a fila
  /// não subia quando a rede voltava. Com a lista já carregada, não há o que
  /// esperar.
  Future<void> _carregada() async {
    if (!state.hasValue) await future;
  }

  /// A lista como está neste instante.
  List<ItemDaFila> get _itens =>
      ref.mounted ? state.value ?? const [] : const [];

  void _publicar(List<ItemDaFila> itens) {
    if (ref.mounted) state = AsyncData(itens);
  }
}

final filaControladorProvider =
    AsyncNotifierProvider<FilaControlador, List<ItemDaFila>>(
      FilaControlador.new,
    );

/// As amostras que viraram a análise [analiseId], se ainda estão neste
/// aparelho — achadas pelo envio da fila que devolveu essa análise.
///
/// TODO(backend): com a API, ouvir também análises gravadas em outro
/// aparelho — o áudio viria dela.
final amostrasDaAnaliseProvider = Provider.autoDispose
    .family<Map<TarefaDeGravacao, Amostra>, String>((ref, analiseId) {
      final itens = ref.watch(filaControladorProvider).value ?? const [];
      final envio = itens.where((i) => i.analiseId == analiseId).firstOrNull;
      return {
        for (final amostra in envio?.amostras ?? const <Amostra>[])
          amostra.tarefa: amostra,
      };
    });
