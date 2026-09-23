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
  const AfericaoFalhou();
}

final class AfericaoMedindo extends EstadoDaAfericao {
  const AfericaoMedindo({this.nivel, this.progresso = 0});

  /// Última leitura, em dBFS. Nula até a primeira chegar.
  final double? nivel;

  /// De 0 a 1.
  final double progresso;
}

final class AfericaoConcluida extends EstadoDaAfericao {
  const AfericaoConcluida({required this.resultado, this.ajuste});

  final ResultadoDaAfericao resultado;

  /// O que o aparelho mudou do formato pedido, se mudou.
  final AjusteDeConfiguracao? ajuste;

  /// A gravação pode começar? Só não pode com o microfone mudo.
  bool get liberaGravacao =>
      resultado.conclusao != ConclusaoDaAfericao.microfoneMudo;
}

/// Conduz a aferição: permissão, microfone aberto por
/// [AfericaoDeRuido.duracao], conclusão.
///
/// A regra de o que a aferição conclui mora no domínio
/// ([AfericaoDeRuido.concluir]); aqui só se colhe e se entrega.
class AfericaoControlador extends Notifier<EstadoDaAfericao> {
  late FonteDeNivel _fonte;

  @override
  EstadoDaAfericao build() {
    // `watch`, não `read`: mantém a fonte viva enquanto o controlador viver.
    // Quando a tela sai, os dois são descartados e a fonte fecha o microfone.
    _fonte = ref.watch(fonteDeNivelProvider);
    return const AfericaoNaoIniciada();
  }

  Future<void> medir() async {
    // Toque duplo abriria o microfone duas vezes.
    if (state is AfericaoMedindo) return;
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

    if (ref.mounted) {
      state = falhou
          ? const AfericaoFalhou()
          : AfericaoConcluida(
              resultado: AfericaoDeRuido.concluir(leituras),
              ajuste: ajuste,
            );
    }

    // Fecha o microfone depois de mostrar o resultado, pelo mesmo motivo.
    // Se a tela já saiu, o descarte da fonte fecha de qualquer jeito.
    try {
      await _fonte.fechar();
    } catch (_) {
      // Fechar é limpeza; falhar aqui não muda o que foi medido.
    }
  }
}

final afericaoControladorProvider =
    NotifierProvider.autoDispose<AfericaoControlador, EstadoDaAfericao>(
      AfericaoControlador.new,
    );
