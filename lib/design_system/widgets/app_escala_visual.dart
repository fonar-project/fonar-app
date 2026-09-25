import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_fundo.dart';
import 'app_mensagem_de_campo.dart';

/// Escala visual analógica: uma linha de [minimo] a [maximo] em que se marca
/// um ponto. É a forma da CAPE-V.
///
/// ## Começa SEM marca
///
/// Com [valor] nulo não há ponto na linha, e o número diz "não marcado". Um
/// ponto pré-posicionado em zero seria uma avaliação que ninguém fez — e zero,
/// aqui, é uma resposta ("sem desvio"), não a ausência de uma.
///
/// Toque ou arraste na linha marca; no teclado, as setas movem de 1 em 1. Por
/// baixo é o `Slider` do Material, que já traz foco, teclado e semântica de
/// controle ajustável.
///
/// ## A régua
///
/// Como no protótipo, a linha é uma régua: um tracinho por unidade (na
/// CAPE-V, o milímetro), maior a cada 5 e a cada 10, com os números embaixo.
/// A régua é desenhada atrás do `Slider`, com o mesmo recuo da trilha — ver
/// [_TrilhaDaRegua] —, para o tracinho e o ponto tocado coincidirem.
class AppEscalaVisual extends StatelessWidget {
  const AppEscalaVisual({
    required this.rotulo,
    required this.valor,
    required this.aoMudar,
    required this.rotuloMinimo,
    required this.rotuloMaximo,
    required this.textoNaoMarcado,
    this.minimo = 0,
    this.maximo = 100,
    this.erro,
    this.mostrarCabecalho = true,
    super.key,
  });

  final String rotulo;
  final int? valor;

  /// Nulo deixa a escala só para leitura.
  final ValueChanged<int>? aoMudar;

  /// O que significa cada ponta, ex.: "sem desvio" e "desvio extremo".
  final String rotuloMinimo;
  final String rotuloMaximo;

  /// Mostrado no lugar do número enquanto não há marca.
  final String textoNaoMarcado;

  final int minimo;
  final int maximo;
  final String? erro;

  /// Falso quando a tela já mostra o nome e o número em outro lugar — na
  /// escala em tela cheia, por exemplo, com o número grande.
  final bool mostrarCabecalho;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = AppFundo.secundarioDe(context);
    final marcado = valor != null;
    final espacoDosNumeros = MediaQuery.textScalerOf(context).scale(14) + 6;
    final temErro = erro != null && erro!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mostrarCabecalho)
          // Wrap, não Row: com o texto do sistema ampliado, o nome do
          // parâmetro e o "não marcado" não cabem lado a lado, e o valor desce.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm,
            children: [
              ExcludeSemantics(child: Text(rotulo, style: textos.titleMedium)),
              ExcludeSemantics(
                child: marcado
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$valor',
                            style: AppTypography.medidaCompacta.copyWith(
                              color: AppColors.cinzaChumbo,
                            ),
                          ),
                          Text(
                            ' /$maximo',
                            style: textos.bodySmall?.copyWith(
                              color: secundario,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        textoNaoMarcado,
                        style: textos.bodySmall?.copyWith(color: secundario),
                      ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        // A régua atrás, o Slider na frente, na mesma caixa.
        CustomPaint(
          painter: _Regua(
            minimo: minimo,
            maximo: maximo,
            valor: valor,
            corDoTraco: AppColors.cinzaChumbo,
            corDaMarca: AppColors.roxoProfundo,
            estiloDoNumero: textos.labelSmall!.copyWith(color: secundario),
            espacoDosNumeros: espacoDosNumeros,
            escalaDoTexto: MediaQuery.textScalerOf(context),
            direcao: Directionality.of(context),
          ),
          child: Padding(
            // Espaço, embaixo da trilha, para os números da régua.
            padding: EdgeInsets.only(bottom: espacoDosNumeros),
            // Um nó só: nome, valor e as ações de aumentar e diminuir. Sem a
            // fusão, o leitor de tela anunciava "Grau geral" e, à parte, um
            // controle deslizante sem nome.
            child: MergeSemantics(
              child: Semantics(
                label: rotulo,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    trackShape: const _TrilhaDaRegua(),
                    padding: EdgeInsets.zero,
                    activeTrackColor: AppColors.cinzaChumbo,
                    inactiveTrackColor: temErro
                        ? AppColors.erro
                        : AppColors.cinzaChumbo,
                    thumbColor: AppColors.roxoProfundo,
                    // Sem marca, sem ponto. Só a cor transparente não bastava:
                    // o contorno e a sombra do polegar continuavam desenhados
                    // em 0, e a escala parecia marcada em "sem desvio".
                    thumbShape: marcado
                        ? const RoundSliderThumbShape(enabledThumbRadius: 8)
                        : SliderComponentShape.noThumb,
                    overlayColor: AppColors.roxoVeu,
                    // A régua já marca as divisões.
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    value: (valor ?? minimo).toDouble(),
                    min: minimo.toDouble(),
                    max: maximo.toDouble(),
                    divisions: maximo - minimo,
                    onChanged: aoMudar == null
                        ? null
                        : (v) => aoMudar!(v.round()),
                    // O Slider só chama `onChanged` quando o valor MUDA — e a
                    // escala sem marca está, por dentro, no mínimo. Sem isto,
                    // tocar na ponta esquerda (ou a seta para a esquerda no
                    // teclado) numa escala sem marca não marcava nada: "sem
                    // desvio" era impossível de registrar com um toque. O fim
                    // do toque é avisado sempre, com o valor tocado.
                    onChangeEnd: aoMudar == null
                        ? null
                        : (v) => aoMudar!(v.round()),
                    // Sem marca, o Slider anunciaria o mínimo — "0", uma
                    // resposta que ninguém deu.
                    semanticFormatterCallback: (v) =>
                        marcado ? '${v.round()} de $maximo' : textoNaoMarcado,
                  ),
                ),
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rotuloMinimo,
                  style: textos.bodySmall?.copyWith(color: secundario),
                ),
              ),
              Expanded(
                child: Text(
                  rotuloMaximo,
                  textAlign: TextAlign.end,
                  style: textos.bodySmall?.copyWith(color: secundario),
                ),
              ),
            ],
          ),
        ),
        AppMensagemDeCampo(erro: temErro ? erro : null, corDoApoio: secundario),
      ],
    );
  }
}

/// Recuo da trilha em cada ponta: o espaço do polegar na ponta da régua.
/// A régua usa o mesmo — ver [_Regua].
const _recuo = 12.0;

/// A trilha do Slider com um recuo fixo, conhecido pela régua. O recuo
/// padrão do Material depende do tema e do tamanho do polegar.
class _TrilhaDaRegua extends RoundedRectSliderTrackShape {
  const _TrilhaDaRegua();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final altura = sliderTheme.trackHeight ?? 2;
    final topo = offset.dy + (parentBox.size.height - altura) / 2;
    return Rect.fromLTWH(
      offset.dx + _recuo,
      topo,
      parentBox.size.width - 2 * _recuo,
      altura,
    );
  }
}

/// Os tracinhos e os números da régua, e a linha da marca.
class _Regua extends CustomPainter {
  _Regua({
    required this.minimo,
    required this.maximo,
    required this.valor,
    required this.corDoTraco,
    required this.corDaMarca,
    required this.estiloDoNumero,
    required this.espacoDosNumeros,
    required this.escalaDoTexto,
    required this.direcao,
  });

  final int minimo;
  final int maximo;
  final int? valor;
  final Color corDoTraco;
  final Color corDaMarca;
  final TextStyle estiloDoNumero;

  /// A faixa de baixo da caixa, reservada aos números. O resto é do Slider,
  /// com a trilha no meio.
  final double espacoDosNumeros;
  final TextScaler escalaDoTexto;
  final TextDirection direcao;

  @override
  void paint(Canvas canvas, Size size) {
    final largura = size.width - 2 * _recuo;
    if (largura <= 0) return;
    final linha = (size.height - espacoDosNumeros) / 2;
    final passo = largura / (maximo - minimo);
    double x(int v) => _recuo + (v - minimo) * passo;

    final traco = Paint()
      ..color = corDoTraco.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final tracoForte = Paint()
      ..color = corDoTraco
      ..strokeWidth = 1.5;
    // Tracinho de unidade só quando há espaço para vê-lo separado.
    final comUnidade = passo >= 2.5;
    for (var v = minimo; v <= maximo; v++) {
      final dez = v % 10 == 0;
      final cinco = v % 5 == 0;
      if (!dez && !cinco && !comUnidade) continue;
      final altura = dez
          ? 16.0
          : cinco
          ? 10.0
          : 6.0;
      canvas.drawLine(
        Offset(x(v), linha),
        Offset(x(v), linha - altura),
        dez ? tracoForte : traco,
      );
    }

    // Os números: de 10 em 10 quando cabem; senão de 20 em 20, ou 50.
    final numeros = <int, TextPainter>{};
    TextPainter numero(int v) => numeros[v] ??= TextPainter(
      text: TextSpan(text: '$v', style: estiloDoNumero),
      textDirection: direcao,
      textScaler: escalaDoTexto,
    )..layout();
    final larguraMaxima = numero(maximo).width + 6;
    final intervalo = [10, 20, 50, 100].firstWhere(
      (i) => i * passo >= larguraMaxima,
      orElse: () => maximo - minimo,
    );
    for (var v = minimo; v <= maximo; v += intervalo) {
      final p = numero(v);
      final esquerda = (x(v) - p.width / 2).clamp(0.0, size.width - p.width);
      p.paint(canvas, Offset(esquerda, linha + 8));
    }

    if (valor case final v?) {
      canvas.drawLine(
        Offset(x(v), linha - 18),
        Offset(x(v), linha + 6),
        Paint()
          ..color = corDaMarca
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final p in numeros.values) {
      p.dispose();
    }
  }

  @override
  bool shouldRepaint(_Regua antes) =>
      antes.valor != valor ||
      antes.minimo != minimo ||
      antes.maximo != maximo ||
      antes.estiloDoNumero != estiloDoNumero ||
      antes.escalaDoTexto != escalaDoTexto;
}
