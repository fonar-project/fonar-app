import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fonte_de_nivel_record.dart';
import '../domain/afericao_de_ruido.dart';
import '../domain/fonte_de_nivel.dart';

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

final class AfericaoConcluida extends EstadoDaAfericao {
  const AfericaoConcluida({
    required this.resultado,
    this.ajuste,
    this.microfoneLiberado = true,
    this.demorouParaLiberar = false,
  });

  final ResultadoDaAfericao resultado;

  /// O que o aparelho mudou do formato pedido, se mudou.
  final AjusteDeConfiguracao? ajuste;

  /// O microfone da aferição já foi fechado.
  ///
  /// O resultado aparece antes — assim que as leituras terminam —, mas
  /// medir de novo e gravar esperam por isto: abrir outra captura com a
  /// anterior ainda fechando faria as duas disputarem o mesmo aparelho.
  final bool microfoneLiberado;

  /// O fechamento passou de [AfericaoControlador.esperaParaLiberar] e ainda
  /// não terminou. A tela avisa; os botões continuam travados.
  final bool demorouParaLiberar;

  /// A gravação pode começar? Não com o microfone mudo, e não antes de o
  /// microfone da aferição ser liberado.
  bool get liberaGravacao =>
      microfoneLiberado &&
      resultado.conclusao != ConclusaoDaAfericao.microfoneMudo;
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

  Future<void> medir() async {
    // Toque duplo abriria o microfone duas vezes; e com o anterior ainda
    // fechando, os dois disputariam o aparelho.
    if (state is AfericaoMedindo || _fechando != null) return;
    state = const AfericaoMedindo();

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
        AfericaoDeRuido.duracao.inMilliseconds /
        AfericaoDeRuido.intervalo.inMilliseconds;
    var falhou = false;
    StreamSubscription<double>? inscricao;

    try {
      final niveis = await _fonte.abrir(AfericaoDeRuido.intervalo);
      inscricao = niveis.listen((nivel) {
        leituras.add(nivel);
        if (ref.mounted) {
          state = AfericaoMedindo(
            nivel: nivel,
            progresso: (leituras.length / esperadas).clamp(0, 1),
          );
        }
      }, onError: (Object _) => falhou = true);
      await Future<void>.delayed(AfericaoDeRuido.duracao);
    } catch (_) {
      falhou = true;
    }

    // O cancelamento NÃO é esperado. Em teste, esperar o `cancel` de uma
    // inscrição deixou a aferição presa em "Medindo…" para sempre; no app
    // real, um plugin que demore a responder faria o mesmo. As leituras já
    // estão colhidas — o resultado não pode depender de o fluxo fechar.
    unawaited(inscricao?.cancel());
    final ajuste = _fonte.ajuste;
    final resultado = falhou ? null : AfericaoDeRuido.concluir(leituras);

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
