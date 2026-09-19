import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Área clicável que não é botão: linha de lista, card, item de navegação.
///
/// Existe pelo anel de foco. O `InkWell` puro marca o foco com um véu de 7% do
/// tema — invisível para quem navega por teclado no Windows, e navegação por
/// teclado é requisito. Aqui o foco desenha um anel de 3 px por cima do
/// conteúdo, sem mexer no layout.
class AppToque extends StatefulWidget {
  const AppToque({
    required this.aoTocar,
    required this.child,
    this.corDoFoco = AppColors.foco,
    this.corDoHover = AppColors.roxoVeu,
    this.raio = BorderRadius.zero,
    this.selecionado,
    super.key,
  });

  final VoidCallback aoTocar;
  final Widget child;

  /// Sobre fundo roxo o azul de foco some; ali, passe [AppColors.creme].
  final Color corDoFoco;

  final Color corDoHover;
  final BorderRadius raio;

  /// Para itens de navegação: anuncia ao leitor de tela qual está ativo.
  final bool? selecionado;

  @override
  State<AppToque> createState() => _AppToqueState();
}

class _AppToqueState extends State<AppToque> {
  var _focado = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selecionado,
      child: InkWell(
        onTap: widget.aoTocar,
        onFocusChange: (focado) => setState(() => _focado = focado),
        borderRadius: widget.raio,
        focusColor: Colors.transparent,
        hoverColor: widget.corDoHover,
        highlightColor: widget.corDoHover,
        splashFactory: NoSplash.splashFactory,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.raio,
            border: _focado
                ? Border.all(color: widget.corDoFoco, width: 3)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
