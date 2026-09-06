import 'package:flutter/widgets.dart';

/// Faixas de largura de tela.
///
/// REGRA INEGOCIÁVEL DO PROJETO: a interface adapta por LARGURA, nunca por
/// sistema operacional. É proibido usar `Platform.isAndroid` ou
/// `Platform.isWindows` para decidir layout — Android e Windows têm
/// exatamente o mesmo conjunto de funcionalidades.
///
/// Um tablet Android em paisagem e um notebook Windows recebem o mesmo
/// layout porque têm a mesma largura, e é isso que queremos.
///
/// Uso: `LayoutBuilder` + [Breakpoints.de], ou [context.larguraDeTela].
enum LarguraDeTela {
  /// Celular em retrato. Uma coluna, navegação inferior.
  compacta,

  /// Tablet em retrato, janela estreita no desktop. Uma ou duas colunas.
  media,

  /// Desktop, tablet em paisagem. Duas colunas, navegação lateral.
  expandida,
}

abstract final class Breakpoints {
  /// Abaixo disto: [LarguraDeTela.compacta].
  static const compactaAte = 600.0;

  /// Abaixo disto: [LarguraDeTela.media]. Daí para cima, expandida.
  static const mediaAte = 1024.0;

  static LarguraDeTela de(double largura) => switch (largura) {
        < compactaAte => LarguraDeTela.compacta,
        < mediaAte => LarguraDeTela.media,
        _ => LarguraDeTela.expandida,
      };
}

extension LarguraDeTelaContext on BuildContext {
  /// Faixa de largura da JANELA. Dentro de um painel estreito, prefira
  /// `LayoutBuilder` — o que importa é o espaço disponível ao widget.
  LarguraDeTela get larguraDeTela =>
      Breakpoints.de(MediaQuery.sizeOf(this).width);
}
