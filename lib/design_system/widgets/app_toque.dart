import 'package:flutter/material.dart';

import '../tokens/app_cores.dart';

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
    this.corDoFoco,
    this.corDoHover,
    this.raio = BorderRadius.zero,
    this.selecionado,
    super.key,
  });

  final VoidCallback aoTocar;
  final Widget child;

  /// Sem valor, a cor de foco do tema. Sobre fundo roxo o azul de foco some;
  /// ali, passe `context.cores.sobrePrimaria`.
  final Color? corDoFoco;

  /// Sem valor, o véu do tema.
  final Color? corDoHover;
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
        hoverColor: widget.corDoHover ?? context.cores.veu,
        highlightColor: widget.corDoHover ?? context.cores.veu,
        splashFactory: NoSplash.splashFactory,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.raio,
            border: _focado
                ? Border.all(
                    color: widget.corDoFoco ?? context.cores.foco,
                    width: 3,
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
