import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../tokens/app_cores.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_fundo.dart';
import 'app_mensagem_de_campo.dart';
import 'app_toque.dart';

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
/// ## Com o mouse
///
/// A régua INTEIRA é área de clique e de arraste — os tracinhos, a linha e os
/// números —, e não só a faixa fina em volta da linha: no teste com o
/// profissional, quem mirava o tracinho do 30 com o mouse clicava acima da
/// linha e nada acontecia. Com o ponteiro em cima, uma marca clara e o número
/// mostram onde o clique vai cair, antes de clicar.
///
/// O − e o + dos lados ajustam de 1 em 1 a marca já feita — o ajuste fino
/// que o arraste não dá com o mouse. Sem marca, ficam apagados: a primeira
/// marca é um julgamento feito na linha, não um número que se incrementa
/// a partir do zero.
///
/// ## A régua
///
/// Como no protótipo, a linha é uma régua: um tracinho por unidade (na
/// CAPE-V, o milímetro), maior a cada 5 e a cada 10, com os números embaixo.
/// A régua é desenhada atrás do `Slider`, com o mesmo recuo da trilha — ver
/// [_TrilhaDaRegua] —, para o tracinho e o ponto tocado coincidirem.
class AppEscalaVisual extends StatefulWidget {
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
  State<AppEscalaVisual> createState() => _AppEscalaVisualState();
}

class _AppEscalaVisualState extends State<AppEscalaVisual> {
  /// O valor sob o ponteiro do mouse, enquanto ele passa pela régua sem
  /// botão apertado. Nulo fora da régua e durante o clique e o arraste.
  int? _sobre;

  int get _minimo => widget.minimo;
  int get _maximo => widget.maximo;

  /// O valor na posição [dx] da régua de [largura]: a mesma conta do Slider,
  /// com o mesmo recuo — ver [_TrilhaDaRegua].
  int _valorEm(double dx, double largura) {
    final util = largura - 2 * _recuo;
    if (util <= 0) return _minimo;
    final fracao = ((dx - _recuo) / util).clamp(0.0, 1.0);
    return (_minimo + fracao * (_maximo - _minimo)).round();
  }

  double _xDe(int valor, double largura) =>
      _recuo + (valor - _minimo) / (_maximo - _minimo) * (largura - 2 * _recuo);

  void _passar(int? valor) {
    if (valor != _sobre) setState(() => _sobre = valor);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = AppFundo.secundarioDe(context);
    final valor = widget.valor;
    final marcado = valor != null;
    final erro = widget.erro;
    final temErro = erro != null && erro.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.mostrarCabecalho)
          // Wrap, não Row: com o texto do sistema ampliado, o nome do
          // parâmetro e o "não marcado" não cabem lado a lado, e o valor desce.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm,
            children: [
              ExcludeSemantics(
                child: Text(widget.rotulo, style: textos.titleMedium),
              ),
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
                              color: context.cores.texto,
                            ),
                          ),
                          Text(
                            ' /$_maximo',
                            style: textos.bodySmall?.copyWith(
                              color: secundario,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.textoNaoMarcado,
                        style: textos.bodySmall?.copyWith(color: secundario),
                      ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        _linhaComAjuste(context, temErro: temErro),
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.rotuloMinimo,
                  style: textos.bodySmall?.copyWith(color: secundario),
                ),
              ),
              Expanded(
                child: Text(
                  widget.rotuloMaximo,
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

  /// − régua +, com os botões na altura da linha.
  Widget _linhaComAjuste(BuildContext context, {required bool temErro}) {
    final escala = MediaQuery.textScalerOf(context);
    final geometria = _Geometria(escala);
    final aoMudar = widget.aoMudar;
    if (aoMudar == null) {
      return _regua(context, geometria, temErro: temErro);
    }
    final valor = widget.valor;
    // O botão centrado na linha, e não na caixa: a caixa inclui a faixa do
    // número sob o ponteiro, em cima, e a dos números da régua, embaixo.
    final topo = (geometria.linha - AppSpacing.alvoDeToqueMinimo / 2).clamp(
      0.0,
      double.infinity,
    );
    Widget botao({required bool menos}) {
      final alvo = valor == null ? null : valor + (menos ? -1 : 1);
      return Padding(
        padding: EdgeInsets.only(top: topo),
        child: _BotaoDeAjuste(
          simbolo: menos ? '−' : '+',
          rotulo: menos
              ? AppStrings.escalaDiminuir(widget.rotulo)
              : AppStrings.escalaAumentar(widget.rotulo),
          dica: menos ? AppStrings.escalaMenosUm : AppStrings.escalaMaisUm,
          aoTocar: alvo != null && alvo >= _minimo && alvo <= _maximo
              ? () => aoMudar(alvo)
              : null,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        botao(menos: true),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(child: _regua(context, geometria, temErro: temErro)),
        const SizedBox(width: AppSpacing.xxs),
        botao(menos: false),
      ],
    );
  }

  Widget _regua(
    BuildContext context,
    _Geometria geometria, {
    required bool temErro,
  }) {
    final textos = Theme.of(context).textTheme;
    final secundario = AppFundo.secundarioDe(context);
    final valor = widget.valor;
    final marcado = valor != null;
    final aoMudar = widget.aoMudar;
    final escala = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, restricoes) {
        final largura = restricoes.maxWidth;
        final sobre = aoMudar == null ? null : _sobre;

        // A régua atrás, o Slider na frente, na mesma caixa — e o Slider
        // ocupa a caixa INTEIRA: o clique nos tracinhos ou nos números marca
        // tanto quanto o clique na linha.
        Widget regua = CustomPaint(
          painter: _Regua(
            minimo: _minimo,
            maximo: _maximo,
            valor: valor,
            sobre: sobre,
            linha: geometria.linha,
            corDoTraco: context.cores.texto,
            corDaMarca: context.cores.acento,
            estiloDoNumero: textos.labelSmall!.copyWith(color: secundario),
            escalaDoTexto: escala,
            direcao: Directionality.of(context),
          ),
          child: SizedBox(
            height: geometria.altura,
            // Um nó só: nome, valor e as ações de aumentar e diminuir. Sem a
            // fusão, o leitor de tela anunciava "Grau geral" e, à parte, um
            // controle deslizante sem nome.
            child: MergeSemantics(
              child: Semantics(
                label: widget.rotulo,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    trackShape: _TrilhaDaRegua(geometria.linha),
                    padding: EdgeInsets.zero,
                    activeTrackColor: context.cores.texto,
                    inactiveTrackColor: temErro
                        ? context.cores.erro
                        : context.cores.texto,
                    thumbColor: context.cores.acento,
                    // Sem marca, sem ponto. Só a cor transparente não bastava:
                    // o contorno e a sombra do polegar continuavam desenhados
                    // em 0, e a escala parecia marcada em "sem desvio".
                    thumbShape: marcado
                        ? const RoundSliderThumbShape(enabledThumbRadius: 8)
                        : SliderComponentShape.noThumb,
                    overlayColor: context.cores.veu,
                    // A régua já marca as divisões.
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    value: (valor ?? _minimo).toDouble(),
                    min: _minimo.toDouble(),
                    max: _maximo.toDouble(),
                    divisions: _maximo - _minimo,
                    onChanged: aoMudar == null
                        ? null
                        : (v) => aoMudar(v.round()),
                    // O Slider só chama `onChanged` quando o valor MUDA — e a
                    // escala sem marca está, por dentro, no mínimo. Sem isto,
                    // tocar na ponta esquerda (ou a seta para a esquerda no
                    // teclado) numa escala sem marca não marcava nada: "sem
                    // desvio" era impossível de registrar com um toque. O fim
                    // do toque é avisado sempre, com o valor tocado.
                    onChangeEnd: aoMudar == null
                        ? null
                        : (v) => aoMudar(v.round()),
                    // Sem marca, o Slider anunciaria o mínimo — "0", uma
                    // resposta que ninguém deu.
                    semanticFormatterCallback: (v) => marcado
                        ? '${v.round()} de $_maximo'
                        : widget.textoNaoMarcado,
                  ),
                ),
              ),
            ),
          ),
        );
        if (aoMudar == null) return regua;

        regua = Listener(
          // Apertou: quem manda agora é o Slider, e a marca de prévia sai
          // para não ficar parada no lugar do clique enquanto arrasta.
          onPointerDown: (_) => _passar(null),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (e) => _passar(_valorEm(e.localPosition.dx, largura)),
            onExit: (_) => _passar(null),
            child: regua,
          ),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            regua,
            if (sobre != null)
              Positioned(
                left: _xDe(sobre, largura),
                top: 0,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(
                        '$sobre',
                        key: const ValueKey('escala-sobre'),
                        style: textos.labelMedium?.copyWith(
                          color: context.cores.acento,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// As alturas da caixa da régua, de cima para baixo: o número sob o
/// ponteiro, os tracinhos acima da linha, a linha, os números da régua.
class _Geometria {
  _Geometria(TextScaler escala)
    : _rotulo = escala.scale(14) + 4,
      _numeros = escala.scale(14) + 6;

  final double _rotulo;
  final double _numeros;

  /// Onde fica a linha (e a trilha do Slider), medido do topo da caixa.
  double get linha => _rotulo + 20;

  double get altura => linha + 8 + _numeros;
}

/// O − ou o + do ajuste fino: alvo de toque mínimo, nome para o leitor de
/// tela e dica para o mouse. Sem [aoTocar], apagado.
class _BotaoDeAjuste extends StatelessWidget {
  const _BotaoDeAjuste({
    required this.simbolo,
    required this.rotulo,
    required this.dica,
    required this.aoTocar,
  });

  final String simbolo;
  final String rotulo;
  final String dica;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    Widget simboloNa(Color cor) => SizedBox.square(
      dimension: AppSpacing.alvoDeToqueMinimo,
      child: Center(
        child: Text(
          simbolo,
          style: textos.titleLarge?.copyWith(
            color: cor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    final tocar = aoTocar;
    // O símbolo não é lido: "−" sozinho não diz o que faz. O nome diz.
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: tocar != null,
        label: rotulo,
        child: tocar == null
            ? ExcludeSemantics(child: simboloNa(context.cores.borda))
            : Tooltip(
                message: dica,
                excludeFromSemantics: true,
                child: AppToque(
                  aoTocar: tocar,
                  raio: AppRadius.bordaPequena,
                  conteudo: (context) =>
                      ExcludeSemantics(child: simboloNa(context.cores.acento)),
                ),
              ),
      ),
    );
  }
}

/// Recuo da trilha em cada ponta: o espaço do polegar na ponta da régua.
/// A régua usa o mesmo — ver [_Regua].
const _recuo = 12.0;

/// A trilha do Slider com um recuo fixo, conhecido pela régua. O recuo
/// padrão do Material depende do tema e do tamanho do polegar.
///
/// A trilha fica na altura da [linha] da régua, e não no meio da caixa: a
/// caixa do Slider é a régua inteira (ver [_Geometria]).
class _TrilhaDaRegua extends RoundedRectSliderTrackShape {
  const _TrilhaDaRegua(this.linha);

  final double linha;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final altura = sliderTheme.trackHeight ?? 2;
    final topo = offset.dy + linha - altura / 2;
    return Rect.fromLTWH(
      offset.dx + _recuo,
      topo,
      parentBox.size.width - 2 * _recuo,
      altura,
    );
  }
}

/// Os tracinhos e os números da régua, a linha da marca e a prévia do mouse.
class _Regua extends CustomPainter {
  _Regua({
    required this.minimo,
    required this.maximo,
    required this.valor,
    required this.sobre,
    required this.linha,
    required this.corDoTraco,
    required this.corDaMarca,
    required this.estiloDoNumero,
    required this.escalaDoTexto,
    required this.direcao,
  });

  final int minimo;
  final int maximo;
  final int? valor;

  /// O valor sob o ponteiro: uma marca clara, de prévia.
  final int? sobre;

  /// A altura da linha na caixa — a mesma da trilha do Slider.
  final double linha;
  final Color corDoTraco;
  final Color corDaMarca;
  final TextStyle estiloDoNumero;
  final TextScaler escalaDoTexto;
  final TextDirection direcao;

  @override
  void paint(Canvas canvas, Size size) {
    final largura = size.width - 2 * _recuo;
    if (largura <= 0) return;
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

    if (sobre case final s? when s != valor) {
      canvas.drawLine(
        Offset(x(s), linha - 18),
        Offset(x(s), linha + 6),
        Paint()
          ..color = corDaMarca.withValues(alpha: 0.4)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
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
      antes.sobre != sobre ||
      antes.linha != linha ||
      antes.minimo != minimo ||
      antes.maximo != maximo ||
      antes.estiloDoNumero != estiloDoNumero ||
      antes.escalaDoTexto != escalaDoTexto;
}
