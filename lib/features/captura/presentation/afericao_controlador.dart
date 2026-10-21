import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../reproducao/presentation/reproducao_controlador.dart';
import '../data/fonte_de_nivel_record.dart';
import '../domain/ajuste_de_configuracao.dart';
import '../domain/afericao_de_ruido.dart';
import '../domain/fonte_de_nivel.dart';
import '../domain/microfone.dart';
import 'microfone_controlador.dart';

/// Em que ponto está a aferição de ruído ambiente.
sealed class EstadoDaAfericao {
  const EstadoDaAfericao();
}

final class AfericaoNaoIniciada extends EstadoDaAfericao {
  const AfericaoNaoIniciada();
}

final class AfericaoSemPermissao extends EstadoDaAfericao {
  const AfericaoSemPermissao();
}

/// O microfone não abriu, ou caiu no meio.
final class AfericaoFalhou extends EstadoDaAfericao {
  const AfericaoFalhou({
    this.microfoneLiberado = true,
    this.demorouParaLiberar = false,
  });

  /// Ver [AfericaoConcluida.microfoneLiberado].
  final bool microfoneLiberado;
  final bool demorouParaLiberar;
}

final class AfericaoMedindo extends EstadoDaAfericao {
  const AfericaoMedindo({this.nivel, this.progresso = 0});

  /// Última leitura, em dBFS. Nula até a primeira chegar.
  final double? nivel;

  /// De 0 a 1.
  final double progresso;
}

/// Escutando a voz de quem está perto do microfone, depois de a sala ter
/// dado silêncio digital — ver [AfericaoDeRuido.concluirComAVoz].
final class AfericaoConferindoVoz extends EstadoDaAfericao {
  const AfericaoConferindoVoz({this.nivel, this.progresso = 0});

  /// Última leitura, em dBFS. Nula até a primeira chegar.
  final double? nivel;

  /// De 0 a 1, do tempo máximo da conferência.
  final double progresso;
}

final class AfericaoConcluida extends EstadoDaAfericao {
  const AfericaoConcluida({
    required this.resultado,
    this.ajuste,
    this.microfoneLiberado = true,
    this.demorouParaLiberar = false,
    this.bancoSoNaMemoria = false,
  });

  final ResultadoDaAfericao resultado;

  /// O que o aparelho mudou do pedido, se mudou: o formato, ou o
  /// processamento automático que ficou ligado.
  final AjusteDeConfiguracao? ajuste;

  /// O navegador não deu onde guardar os dados (US42, `bancoSoNaMemoria`):
  /// a gravação se perderia ao fechar a página.
  final bool bancoSoNaMemoria;

  /// O microfone da aferição já foi fechado.
  ///
  /// O resultado aparece antes — assim que as leituras terminam —, mas
  /// medir de novo e gravar esperam por isto: abrir outra captura com a
  /// anterior ainda fechando faria as duas disputarem o mesmo aparelho.
  final bool microfoneLiberado;

  /// O fechamento passou de [AfericaoControlador.esperaParaLiberar] e ainda
  /// não terminou. A tela avisa; os botões continuam travados.
  final bool demorouParaLiberar;

  /// O processamento automático do microfone ficou ligado (US42): a
  /// captura não serve para a análise, e a gravação não abre.
  bool get processamentoLigado => ajuste?.manteveProcessamento ?? false;

  /// A gravação pode começar? Não com o microfone mudo, nem com o
  /// processamento automático ligado, nem sem onde guardar a gravação — e
  /// não antes de o microfone da aferição ser liberado.
  bool get liberaGravacao =>
      microfoneLiberado &&
      resultado.conclusao != ConclusaoDaAfericao.microfoneMudo &&
      !processamentoLigado &&
      !bancoSoNaMemoria;

  /// Cabe conferir o microfone com a voz: a sala deu silêncio digital, e o
  /// microfone da aferição já fechou.
  bool get podeConferirComAVoz =>
      microfoneLiberado &&
      resultado.conclusao == ConclusaoDaAfericao.microfoneMudo;
}

/// Conduz a aferição: permissão, microfone aberto por
/// [AfericaoDeRuido.duracao], conclusão.
///
/// A regra de o que a aferição conclui mora no domínio
/// ([AfericaoDeRuido.concluir]); aqui só se colhe e se entrega.
class AfericaoControlador extends Notifier<EstadoDaAfericao> {
  late FonteDeNivel _fonte;

  /// Quanto esperar o microfone fechar antes de avisar que está demorando.
  static const esperaParaLiberar = Duration(seconds: 3);

  /// O fechamento do microfone da última aferição, enquanto não termina.
  Future<void>? _fechando;

  @override
  EstadoDaAfericao build() {
    // `watch`, não `read`: mantém a fonte viva enquanto o controlador viver.
    // Quando a tela sai, os dois são descartados e a fonte fecha o microfone.
    _fonte = ref.watch(fonteDeNivelProvider);
    return const AfericaoNaoIniciada();
  }

  bool get _ocupado =>
      state is AfericaoMedindo ||
      state is AfericaoConferindoVoz ||
      _fechando != null;

  Future<void> medir() async {
    // Toque duplo abriria o microfone duas vezes; e com o anterior ainda
    // fechando, os dois disputariam o aparelho.
    if (_ocupado) return;
    state = const AfericaoMedindo();
    await _colher(
      duracao: AfericaoDeRuido.duracao,
      progresso: (nivel, progresso) =>
          AfericaoMedindo(nivel: nivel, progresso: progresso),
      concluir: AfericaoDeRuido.concluir,
    );
  }

  /// Escuta a voz de quem está perto do microfone, depois de a sala ter
  /// dado silêncio digital.
  ///
  /// Silêncio digital é o que entrega o microfone bloqueado — e também, numa
  /// sala silenciosa de verdade, o microfone que zera o sinal quando não há
  /// som (teste de homologação de 18/10/2026: sala quieta lida como
  /// microfone mudo). Só som separa os dois. A voz que chega prova que o
  /// microfone capta; nada chegar confirma que não capta. A regra é a da
  /// gravação ([AfericaoDeRuido.vozChegou]), e cada gravação continua
  /// conferida depois, no arquivo.
  ///
  /// Termina assim que a voz chega, ou em
  /// [AfericaoDeRuido.duracaoDaConferencia].
  Future<void> conferirComAVoz() async {
    final atual = state;
    if (_ocupado || atual is! AfericaoConcluida || !atual.podeConferirComAVoz) {
      return;
    }
    state = const AfericaoConferindoVoz();
    await _colher(
      duracao: AfericaoDeRuido.duracaoDaConferencia,
      progresso: (nivel, progresso) =>
          AfericaoConferindoVoz(nivel: nivel, progresso: progresso),
      concluir: AfericaoDeRuido.concluirComAVoz,
      basta: AfericaoDeRuido.vozChegou,
    );
  }

  /// Abre o microfone, colhe as leituras por até [duracao] — ou até [basta]
  /// responder que sim —, conclui e fecha.
  Future<void> _colher({
    required Duration duracao,
    required EstadoDaAfericao Function(double nivel, double progresso)
    progresso,
    required ResultadoDaAfericao Function(List<double> leituras) concluir,
    bool Function(List<double> leituras)? basta,
  }) async {
    // Nada toca enquanto se mede o silêncio da sala.
    if (ref.exists(reproducaoControladorProvider)) {
      await ref.read(reproducaoControladorProvider.notifier).parar();
      if (!ref.mounted) return;
    }

    final bool permitido;
    try {
      permitido = await _fonte.pedirPermissao();
    } catch (_) {
      if (ref.mounted) state = const AfericaoFalhou();
      return;
    }
    if (!ref.mounted) return;
    if (!permitido) {
      state = const AfericaoSemPermissao();
      return;
    }

    final leituras = <double>[];
    final esperadas =
        duracao.inMilliseconds / AfericaoDeRuido.intervalo.inMilliseconds;
    var falhou = false;
    StreamSubscription<double>? inscricao;
    // Termina no tempo, ou antes, quando [basta] diz que já se sabe.
    final terminou = Completer<void>();
    Timer? prazo;

    try {
      final microfone = await microfoneParaCapturar(ref);
      if (!ref.mounted) return;
      final niveis = await _fonte.abrir(
        AfericaoDeRuido.intervalo,
        microfone: microfone,
      );
      inscricao = niveis.listen((nivel) {
        leituras.add(nivel);
        if (ref.mounted) {
          state = progresso(nivel, (leituras.length / esperadas).clamp(0, 1));
        }
        if (basta != null && basta(leituras) && !terminou.isCompleted) {
          terminou.complete();
        }
      }, onError: (Object _) => falhou = true);
      // O tempo conta do microfone aberto, como sempre contou.
      prazo = Timer(duracao, () {
        if (!terminou.isCompleted) terminou.complete();
      });
      await terminou.future;
    } catch (_) {
      falhou = true;
    }
    prazo?.cancel();

    // O cancelamento NÃO é esperado. Em teste, esperar o `cancel` de uma
    // inscrição deixou a aferição presa em "Medindo…" para sempre; no app
    // real, um plugin que demore a responder faria o mesmo. As leituras já
    // estão colhidas — o resultado não pode depender de o fluxo fechar.
    unawaited(inscricao?.cancel());
    final ajuste = _fonte.ajuste;
    final resultado = falhou ? null : concluir(leituras);

    EstadoDaAfericao estado({required bool liberado, bool demorou = false}) =>
        resultado == null
        ? AfericaoFalhou(
            microfoneLiberado: liberado,
            demorouParaLiberar: demorou,
          )
        : AfericaoConcluida(
            resultado: resultado,
            ajuste: ajuste,
            microfoneLiberado: liberado,
            demorouParaLiberar: demorou,
            bancoSoNaMemoria: bancoSoNaMemoria.value,
          );

    // O resultado aparece já; os botões esperam o microfone fechar.
    if (ref.mounted) state = estado(liberado: false);

    final fechando = _fechar();
    _fechando = fechando;
    await fechando.timeout(
      esperaParaLiberar,
      onTimeout: () {
        // Não libera por conta própria: avisa e continua esperando o
        // fechamento de verdade.
        if (ref.mounted) state = estado(liberado: false, demorou: true);
        return fechando;
      },
    );
    _fechando = null;
    if (ref.mounted) state = estado(liberado: true);
    // Um microfone recém-ligado aparece na escolha; no navegador, os nomes
    // só vêm depois da permissão, que a aferição acabou de pedir.
    if (ref.mounted && ref.exists(microfoneControladorProvider)) {
      ref.read(microfoneControladorProvider.notifier).atualizar();
    }
  }

  /// Troca o microfone e mede a sala de novo com ele: a aferição anterior
  /// foi de outro microfone, e não vale para este.
  Future<void> trocarMicrofone(Microfone? microfone) async {
    if (_ocupado) return;
    await ref.read(microfoneControladorProvider.notifier).escolher(microfone);
    if (!ref.mounted) return;
    await medir();
  }

  /// Fecha o microfone. Falhar aqui é limpeza que não deu certo — não muda o
  /// que foi medido, e o plugin já respondeu, então o aparelho está livre.
  /// Se a tela já saiu, o descarte da fonte fecha de qualquer jeito.
  Future<void> _fechar() async {
    try {
      await _fonte.fechar();
    } catch (_) {}
  }
}

final afericaoControladorProvider =
    NotifierProvider.autoDispose<AfericaoControlador, EstadoDaAfericao>(
      AfericaoControlador.new,
    );
