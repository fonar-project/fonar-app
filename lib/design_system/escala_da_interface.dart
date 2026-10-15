import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// O tamanho da interface, escolhido na Conta (US48).
///
/// A tipografia e os espaçamentos do app são os mesmos em toda largura. Num
/// monitor Full HD em escala 100% isso sobra vazio e deixa tudo miúdo. A
/// escala amplia a interface inteira por um fator — como o zoom do
/// navegador —, e o fator vem da LARGURA da janela, nunca do sistema
/// operacional.
enum TamanhoDaInterface {
  /// Pela largura da janela: 100% até 1280 px, 110% até 1600 px, 120% daí
  /// para cima.
  automatico,
  cem,
  centoEQuinze,
  centoETrinta,
}

/// O fator para [tamanho] numa janela de [largura] × [altura], em pixels
/// lógicos do sistema.
///
/// O fator nunca diminui a interface, e para antes de mudar a faixa de
/// largura: a janela, vista pelo app, continua com pelo menos
/// [Breakpoints.mediaAte] de largura e [alturaMinima] de altura. Por isso o
/// celular e a janela estreita ficam idênticos — no celular, quem amplia é
/// o tamanho de texto do sistema.
double fatorDaInterface(
  TamanhoDaInterface tamanho, {
  required double largura,
  required double altura,
}) {
  final pedido = switch (tamanho) {
    TamanhoDaInterface.automatico =>
      largura < 1280
          ? 1.0
          : largura < 1600
          ? 1.1
          : 1.2,
    TamanhoDaInterface.cem => 1.0,
    TamanhoDaInterface.centoEQuinze => 1.15,
    TamanhoDaInterface.centoETrinta => 1.3,
  };
  final cabe = math.min(
    largura / Breakpoints.mediaAte,
    altura / EscalaDaInterface.alturaMinima,
  );
  return math.max(1.0, math.min(pedido, cabe));
}

/// Amplia [child] — o aplicativo inteiro, no `MaterialApp.builder` — pelo
/// fator de [tamanho].
///
/// Por dentro, o app vê uma janela menor (largura, altura e margens divididas
/// pelo fator), e é por ela que os breakpoints decidem. Por fora, tudo é
/// desenhado [fator] vezes maior. A densidade de pixels sobe junto, para
/// imagem e prévia do laudo rasterizarem nítidas no tamanho final. Toque,
/// mouse e teclado seguem a transformação.
class EscalaDaInterface extends StatelessWidget {
  const EscalaDaInterface({
    required this.tamanho,
    required this.child,
    super.key,
  });

  final TamanhoDaInterface tamanho;
  final Widget child;

  /// A janela, vista pelo app, nunca fica mais baixa que isto.
  static const alturaMinima = 700.0;

  /// O fator em vigor, para a Conta mostrar o que o "Automático" escolheu.
  static double fatorDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Fator>()?.fator ?? 1;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final fator = fatorDaInterface(
      tamanho,
      largura: mq.size.width,
      altura: mq.size.height,
    );
    if (fator == 1) return _Fator(fator: 1, child: child);

    final tamanhoInterno = mq.size / fator;
    return _Fator(
      fator: fator,
      child: MediaQuery(
        data: mq.copyWith(
          size: tamanhoInterno,
          devicePixelRatio: mq.devicePixelRatio * fator,
          padding: mq.padding / fator,
          viewPadding: mq.viewPadding / fator,
          viewInsets: mq.viewInsets / fator,
          systemGestureInsets: mq.systemGestureInsets / fator,
        ),
        child: Transform.scale(
          scale: fator,
          alignment: Alignment.topLeft,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: tamanhoInterno.width,
            maxWidth: tamanhoInterno.width,
            minHeight: tamanhoInterno.height,
            maxHeight: tamanhoInterno.height,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Fator extends InheritedWidget {
  const _Fator({required this.fator, required super.child});

  final double fator;

  @override
  bool updateShouldNotify(_Fator antigo) => antigo.fator != fator;
}
