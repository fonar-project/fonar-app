import 'package:flutter/material.dart';

/// Tokens de movimento.
///
/// O FONAR tem um só tipo de transição: mudança de cor de fundo em controle
/// interativo. Sem parallax, sem zoom, sem animação de entrada. A tela é lida
/// com pressa, às vezes com o paciente esperando — movimento decorativo só
/// atrasa a leitura.
abstract final class AppMovimento {
  /// Transição de estado de controle (hover, pressionado, foco).
  static const rapida = Duration(milliseconds: 150);

  /// Mudança de conteúdo dentro de uma mesma tela.
  static const media = Duration(milliseconds: 250);

  static const curva = Curves.easeOut;

  /// O usuário pediu menos movimento no sistema operacional?
  ///
  /// Chame antes de qualquer animação e devolva o estado final direto quando
  /// for `true`.
  ///
  /// EXCEÇÃO PROPOSITAL: o medidor de nível (VU meter) continua respondendo ao
  /// áudio mesmo com movimento reduzido. Ele não é decoração — é o feedback que
  /// diz ao profissional se a captura está saturando. Reduza a suavização,
  /// mantenha a resposta.
  static bool reduzido(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Duração já ajustada à preferência de movimento reduzido.
  static Duration duracao(BuildContext context, Duration padrao) =>
      reduzido(context) ? Duration.zero : padrao;

  /// Sem animação de troca de página em nenhuma plataforma.
  ///
  /// O padrão do Material desliza a tela lateralmente; no Windows isso parece
  /// defeito, e no celular só adiciona espera entre a pergunta do profissional
  /// e a resposta na tela.
  static const transicoesDePagina = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _SemTransicao(),
      TargetPlatform.windows: _SemTransicao(),
    },
  );
}

class _SemTransicao extends PageTransitionsBuilder {
  const _SemTransicao();

  /// Sem isto a rota continuaria levando os 300 ms padrão para trocar de tela —
  /// invisíveis, porque não há animação, mas ainda assim esperados antes de o
  /// toque virar resultado.
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
