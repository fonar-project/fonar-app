import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_cores.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/domain/faixa_de_referencia.dart';
import '../../../analise/presentation/apresentacao_da_medida.dart';
import '../../domain/evolucao_da_medida.dart';
import '../../domain/serie_da_medida.dart';

/// Linha de uma medida ao longo das sessões.
///
/// Só DESENHA valores que chegaram prontos do servidor. Não é gráfico de
/// sinal — forma de onda e espectrograma vêm como imagem da API; aqui são
/// meia dúzia de números, um por sessão.
///
/// Decisões que moldam o desenho:
/// - o eixo do tempo é proporcional às datas, não à ordem das sessões: duas
///   sessões com uma semana de intervalo e duas com três meses não podem
///   parecer igualmente espaçadas;
/// - sessão em que a medida não foi calculada interrompe a linha, em vez de
///   ligar os vizinhos como se houvesse um valor no meio;
/// - a faixa de referência, quando existe, é uma área sombreada DESCRITA em
///   texto ao lado — nunca informação só de cor;
/// - sem toque nem dica flutuante: os valores estão na lista de sessões, que
///   o leitor de tela e o teclado alcançam. O gráfico é um nó só, com uma
///   descrição, para o leitor de tela;
/// - sem animação: o FONAR não tem movimento decorativo, e a linha
///   "escorregando" de uma medida para outra misturaria as duas escalas.
class GraficoDeEvolucao extends StatelessWidget {
  const GraficoDeEvolucao({
    required this.medida,
    required this.pontos,
    required this.altura,
    this.faixa,
    this.grande = false,
    super.key,
  });

  final MedidaAcustica medida;

  /// Da sessão mais antiga para a mais recente — ver `serieDe`.
  final List<PontoDaSerie> pontos;

  final double altura;

  /// A faixa de referência a sombrear. Nula: nenhuma área é desenhada.
  final FaixaDeReferencia? faixa;

  /// Traço e texto maiores, para o modo paciente — lido a um braço de
  /// distância.
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final comValor = [
      for (final p in pontos)
        if (p.valor != null) p,
    ];
    final textos = Theme.of(context).textTheme;
    if (comValor.isEmpty) {
      return Text(
        AppStrings.evolucaoNenhumValor,
        style: textos.bodyMedium?.copyWith(color: context.cores.secundario),
      );
    }

    final escala = MediaQuery.textScalerOf(context);
    final estiloDoEixo = (grande ? textos.bodyMedium : textos.bodySmall)
        ?.copyWith(
          color: context.cores.secundario,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    final primeira = pontos.first.realizadaEm;
    final ultima = pontos.last.realizadaEm;
    final comAno = primeira.year != ultima.year;
    final eixoX = _EixoDoTempo(pontos);
    final eixoY = _EixoDoValor.para(medida, comValor, faixa);

    final reservaEsquerda = escala.scale(grande ? 56 : 48);
    final reservaEmbaixo = escala.scale(grande ? 34 : 28);

    return Semantics(
      container: true,
      image: true,
      label: AppStrings.evolucaoGraficoDescricao(
        medida.nome,
        pontos.length,
        AppStrings.data(primeira),
        AppStrings.data(ultima),
      ),
      child: ExcludeSemantics(
        child: SizedBox(
          height: altura,
          child: LayoutBuilder(
            builder: (context, restricoes) {
              final rotulos = eixoX.rotulosQueCabem(
                larguraUtil: restricoes.maxWidth - reservaEsquerda,
                vaoMinimo: escala.scale(comAno ? 80 : 60),
                comAno: comAno,
              );
              return LineChart(
                _dados(
                  cores: context.cores,
                  eixoX: eixoX,
                  eixoY: eixoY,
                  rotulos: rotulos,
                  estiloDoEixo: estiloDoEixo,
                  reservaEsquerda: reservaEsquerda,
                  reservaEmbaixo: reservaEmbaixo,
                ),
                duration: Duration.zero,
              );
            },
          ),
        ),
      ),
    );
  }

  LineChartData _dados({
    required AppCores cores,
    required _EixoDoTempo eixoX,
    required _EixoDoValor eixoY,
    required Map<int, String> rotulos,
    required TextStyle? estiloDoEixo,
    required double reservaEsquerda,
    required double reservaEmbaixo,
  }) {
    final faixa = this.faixa;
    const semTitulos = AxisTitles();

    return LineChartData(
      minX: eixoX.minimo,
      maxX: eixoX.maximo,
      minY: eixoY.minimo,
      maxY: eixoY.maximo,
      lineTouchData: const LineTouchData(enabled: false),
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: eixoY.passo,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: cores.borda, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: cores.borda),
          bottom: BorderSide(color: cores.borda),
        ),
      ),
      rangeAnnotations: RangeAnnotations(
        horizontalRangeAnnotations: [
          if (faixa != null)
            HorizontalRangeAnnotation(
              y1: faixa.minimo ?? eixoY.minimo,
              y2: faixa.maximo ?? eixoY.maximo,
              color: cores.veu,
            ),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: semTitulos,
        rightTitles: semTitulos,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: eixoY.passo,
            reservedSize: reservaEsquerda,
            getTitlesWidget: (valor, meta) => SideTitleWidget(
              meta: meta,
              child: Text(medida.formatar(valor), style: estiloDoEixo),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            // Um candidato por dia; só os dias que têm rótulo desenham algo.
            interval: 1,
            minIncluded: false,
            maxIncluded: false,
            reservedSize: reservaEmbaixo,
            getTitlesWidget: (valor, meta) {
              final dia = valor.round();
              final rotulo = rotulos[dia];
              if (rotulo == null || (valor - dia).abs() > 1e-6) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                child: Text(rotulo, style: estiloDoEixo),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (final p in pontos)
              if (p.valor case final valor?)
                FlSpot(eixoX.dia(p.realizadaEm).toDouble(), valor)
              else
                FlSpot.nullSpot,
          ],
          color: cores.acento,
          barWidth: grande ? 4 : 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: grande ? 6 : 4.5,
              color: cores.acento,
              strokeWidth: 2,
              strokeColor: cores.cartao,
            ),
          ),
        ),
      ],
    );
  }
}

/// Eixo horizontal: dias desde a primeira sessão.
class _EixoDoTempo {
  _EixoDoTempo(this.pontos)
    : _inicio = _soData(pontos.first.realizadaEm),
      _ultimoDia = _soData(pontos.last.realizadaEm)
          .difference(_soData(pontos.first.realizadaEm))
          .inDays;

  final List<PontoDaSerie> pontos;
  final DateTime _inicio;
  final int _ultimoDia;

  // Em UTC, só a data: o horário de verão não pode fazer uma diferença de
  // dias dar 29,96.
  static DateTime _soData(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  int dia(DateTime d) => _soData(d).difference(_inicio).inDays;

  /// Folga dos dois lados, para o primeiro e o último ponto não ficarem
  /// colados na borda. Não inteira de propósito: assim as bordas não caem em
  /// dia nenhum e não ganham rótulo.
  double get _folga => math.max(1, _ultimoDia * 0.06) + 0.5;

  double get minimo => -_folga;
  double get maximo => _ultimoDia + _folga;

  /// Os rótulos de data que cabem sem se sobrepor, por dia.
  ///
  /// Da sessão mais recente para a mais antiga: se não couber tudo, quem
  /// perde o rótulo são as antigas — a última sessão é a que o profissional
  /// procura primeiro.
  Map<int, String> rotulosQueCabem({
    required double larguraUtil,
    required double vaoMinimo,
    required bool comAno,
  }) {
    final pixelsPorDia = larguraUtil / (maximo - minimo);
    final rotulos = <int, String>{};
    int? ultimoPosto;
    for (final p in pontos.reversed) {
      final d = dia(p.realizadaEm);
      if (rotulos.containsKey(d)) continue;
      if (ultimoPosto != null && (ultimoPosto - d) * pixelsPorDia < vaoMinimo) {
        continue;
      }
      rotulos[d] = AppStrings.dataCurta(p.realizadaEm, comAno: comAno);
      ultimoPosto = d;
    }
    return rotulos;
  }
}

/// Eixo vertical: dos valores (e da faixa, se houver) com folga, em passos
/// redondos.
class _EixoDoValor {
  const _EixoDoValor(this.minimo, this.maximo, this.passo);

  factory _EixoDoValor.para(
    MedidaAcustica medida,
    List<PontoDaSerie> comValor,
    FaixaDeReferencia? faixa,
  ) {
    final valores = [
      for (final p in comValor) p.valor!,
      ?faixa?.minimo,
      ?faixa?.maximo,
    ];
    var baixo = valores.reduce(math.min);
    var alto = valores.reduce(math.max);

    // Vão mínimo de dez vezes a última casa exibida: sem ele, duas sessões
    // com 3,12 e 3,13 virariam uma subida de parede a parede.
    final vaoMinimo = 10 * math.pow(10, -medida.casasDecimais).toDouble();
    if (alto - baixo < vaoMinimo) {
      final meio = (alto + baixo) / 2;
      baixo = meio - vaoMinimo / 2;
      alto = meio + vaoMinimo / 2;
    }

    final passo = _passoRedondo((alto - baixo) / 4);
    var minimo = ((baixo - passo / 2) / passo).floorToDouble() * passo;
    final maximo = ((alto + passo / 2) / passo).ceilToDouble() * passo;
    // Nenhuma das medidas é negativa: o eixo não mostra valor impossível.
    if (valores.every((v) => v >= 0)) minimo = math.max(0, minimo);
    return _EixoDoValor(minimo, maximo, passo);
  }

  final double minimo;
  final double maximo;
  final double passo;

  /// 1, 2 ou 5 vezes uma potência de dez.
  static double _passoRedondo(double bruto) {
    final base = math.pow(10, (math.log(bruto) / math.ln10).floor()).toDouble();
    final fracao = bruto / base;
    final redondo = fracao <= 1
        ? 1
        : fracao <= 2
        ? 2
        : fracao <= 5
        ? 5
        : 10;
    return redondo * base;
  }
}
