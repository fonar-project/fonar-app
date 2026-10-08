import 'package:flutter/widgets.dart';

import '../tokens/app_cores.dart';
import '../tokens/app_radius.dart';

/// Moldura para imagem que chega pronta do servidor — o espectrograma.
///
/// A imagem vem com as cores dela, desenhadas para fundo claro. No tema
/// escuro, solta sobre o fundo, ela parece um erro de carregamento; com uma
/// borda clara em volta, fica claro que é uma figura. No tema claro não há
/// moldura nenhuma, e a imagem aparece como sempre apareceu.
class AppMolduraDeImagem extends StatelessWidget {
  const AppMolduraDeImagem({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final moldura = context.cores.molduraDeImagem;
    if (moldura.a == 0) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: moldura,
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Padding(padding: const EdgeInsets.all(4), child: child),
    );
  }
}
