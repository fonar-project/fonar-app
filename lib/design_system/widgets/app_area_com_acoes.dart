import 'package:flutter/widgets.dart';

/// Uma área rolável com uma faixa de ações presa embaixo — e, quando a tela é
/// baixa demais para isso, as mesmas ações rolando junto do conteúdo.
///
/// Ação presa embaixo é ótima no celular em pé: o polegar acha "Registrar" ou
/// "Enviar" sem procurar. Mas ela toma altura que não volta, e com o celular
/// deitado (390 px de altura) ou com o texto do sistema em 200%, o cabeçalho e
/// a faixa de ações juntos não deixavam espaço para o conteúdo — a tela
/// estourava, e a matriz de layout acusou isso no resultado e na gravação.
///
/// A regra é uma só, para o aplicativo inteiro: a faixa só fica presa quando
/// sobram pelo menos [alturaParaFixar] pontos — medidos já com a escala de
/// texto, porque é ela que faz a faixa crescer. Abaixo disso, tudo rola junto,
/// e a ação continua lá, no fim do conteúdo.
class AppAreaComAcoes extends StatelessWidget {
  const AppAreaComAcoes({
    required this.corpo,
    required this.acoes,
    this.topo,
    this.padding = EdgeInsets.zero,
    this.centralizar = false,
    super.key,
  });

  /// O conteúdo. Sem rolagem própria: quem rola é esta área.
  final Widget corpo;

  /// A faixa de ações, já com borda e respiro próprios.
  final Widget acoes;

  /// Uma faixa no topo — o player da CAPE-V, as etapas da gravação. Presa
  /// junto com as ações, e rolando junto quando não cabe.
  final Widget? topo;

  /// Respiro em volta do [corpo].
  final EdgeInsets padding;

  /// Centraliza o [corpo] na altura quando sobra espaço — a instrução da
  /// gravação guiada fica no meio da tela, como no protótipo.
  final bool centralizar;

  /// A altura a partir da qual a faixa fica presa, já na escala de texto.
  static double alturaParaFixar(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(520);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final fixa = restricoes.maxHeight >= alturaParaFixar(context);
        if (!fixa) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?topo,
                Padding(padding: padding, child: corpo),
                acoes,
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?topo,
            Expanded(
              child: LayoutBuilder(
                builder: (context, area) => SingleChildScrollView(
                  padding: padding,
                  child: centralizar
                      ? ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (area.maxHeight - padding.vertical)
                                .clamp(0, double.infinity),
                          ),
                          child: Center(child: corpo),
                        )
                      : corpo,
                ),
              ),
            ),
            acoes,
          ],
        );
      },
    );
  }
}
