import 'package:flutter/widgets.dart';

import '../tokens/app_colors.dart';

/// Declara, para os componentes abaixo, sobre qual fundo eles estão desenhados.
///
/// Existe por um motivo só: o par de tokens de texto secundário. O tom claro
/// passa em AA sobre o creme e REPROVA sobre a lavanda, e um botão ou campo
/// não tem como saber o que pintaram atrás dele. Sem esta declaração o
/// componente chuta — e o chute fica errado na primeira vez que alguém o
/// coloca dentro de um card lavanda ou de uma faixa de aviso.
///
/// Quem pinta a superfície declara:
///
/// ```dart
/// Container(
///   color: AppColors.lavandaSuave,
///   child: const AppFundo(
///     fundo: FundoDeTexto.lavanda,
///     child: AppBotao.secundario(...),
///   ),
/// )
/// ```
///
/// Sem nenhum `AppFundo` em volta, o fundo é o creme — o fundo principal do
/// aplicativo, e o caso de longe mais comum.
class AppFundo extends InheritedWidget {
  const AppFundo({required this.fundo, required super.child, super.key});

  final FundoDeTexto fundo;

  /// O fundo declarado mais próximo, ou [FundoDeTexto.creme] se não houver.
  static FundoDeTexto de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppFundo>()?.fundo ??
      FundoDeTexto.creme;

  /// O tom de texto secundário do fundo em volta.
  static Color secundarioDe(BuildContext context) =>
      AppColors.secundarioSobre(de(context));

  @override
  bool updateShouldNotify(AppFundo anterior) => anterior.fundo != fundo;
}
