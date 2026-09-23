import '../../analise/domain/resultado_da_analise.dart';
import 'evolucao_da_medida.dart';

/// O valor de UMA medida em UMA sessão analisada.
class PontoDaSerie {
  const PontoDaSerie({
    required this.analiseId,
    required this.realizadaEm,
    required this.valor,
  });

  final String analiseId;
  final DateTime realizadaEm;

  /// Nulo quando o servidor não calculou a medida nesta sessão. O gráfico
  /// interrompe a linha aí e a tabela diz "não calculada" — nunca zero, que
  /// seria um valor que ninguém mediu.
  final double? valor;
}

/// As sessões que entram na evolução: análise concluída e com data, da mais
/// antiga para a mais recente.
///
/// Análise ainda processando ou que falhou fica de fora: não tem medida para
/// mostrar, e um ponto vazio no fim da linha pareceria queda.
List<ResultadoDaAnalise> sessoesAnalisadas(
  Iterable<ResultadoDaAnalise> analises,
) => [
  for (final a in analises)
    if (a.situacao == SituacaoDaAnalise.concluida && a.realizadaEm != null) a,
]..sort((a, b) => a.realizadaEm!.compareTo(b.realizadaEm!));

/// A série de [medida] ao longo das sessões, da mais antiga para a mais
/// recente.
///
/// Só REÚNE valores que chegaram prontos do servidor. Nada aqui é medida
/// acústica — ver a regra de processamento de áudio no CLAUDE.md.
List<PontoDaSerie> serieDe(
  MedidaAcustica medida,
  Iterable<ResultadoDaAnalise> analises,
) => [
  for (final sessao in sessoesAnalisadas(analises))
    PontoDaSerie(
      analiseId: sessao.id,
      realizadaEm: sessao.realizadaEm!,
      valor: sessao.medidas.where((m) => m.medida == medida).firstOrNull?.valor,
    ),
];

/// Quanto uma medida precisa variar entre duas sessões para a diferença
/// contar como mudança.
///
/// É dado clínico, não de interface: toda medida varia entre gravações do
/// mesmo paciente no mesmo dia, e chamar de mudança uma diferença dentro dessa
/// variação seria enganoso. Mesma regra das faixas de referência — o valor
/// vem de fonte validada, nunca do código.
abstract interface class LimiaresDeMudanca {
  /// O limiar de [medida], na unidade dela, ou `null` se ainda não houver um
  /// definido.
  double? limiar(MedidaAcustica medida);
}

/// As duas sessões mais recentes em que a medida foi calculada, e para onde
/// ela foi entre elas.
class ComparacaoDasUltimas {
  const ComparacaoDasUltimas({
    required this.anterior,
    required this.atual,
    required this.direcao,
  });

  final PontoDaSerie anterior;
  final PontoDaSerie atual;

  /// [DirecaoDaMedida.semComparacao] quando não há limiar de mudança para a
  /// medida: os dois valores aparecem, mas nenhuma afirmação sobre eles.
  final DirecaoDaMedida direcao;
}

/// Compara as duas últimas sessões COM VALOR de [serie].
///
/// Sessão em que a medida não foi calculada é pulada — as datas vão junto na
/// comparação, e a tela as mostra, para ninguém tomar a penúltima sessão pela
/// última.
///
/// `null` com menos de dois valores: não há o que comparar.
ComparacaoDasUltimas? compararUltimas(
  List<PontoDaSerie> serie, {
  required double? limiar,
}) {
  final comValor = [
    for (final p in serie)
      if (p.valor != null) p,
  ];
  if (comValor.length < 2) return null;

  final anterior = comValor[comValor.length - 2];
  final atual = comValor.last;
  return ComparacaoDasUltimas(
    anterior: anterior,
    atual: atual,
    direcao: limiar == null
        ? DirecaoDaMedida.semComparacao
        : direcaoEntre(anterior.valor!, atual.valor!, limiar: limiar),
  );
}

/// Para onde a medida foi de [anterior] a [atual].
///
/// Diferença MENOR que o [limiar] é estável; do limiar para cima, mudou. Valor
/// igual é estável com qualquer limiar, inclusive zero — com limiar zero, a
/// diferença zero não era "menor que o limiar" e caía em "desceu" (achado da
/// revisão de 23/09).
///
/// Entrada que não dá base para comparar — valor ou limiar não finito,
/// limiar negativo — não vira direção nenhuma: [DirecaoDaMedida.semComparacao].
DirecaoDaMedida direcaoEntre(
  double anterior,
  double atual, {
  required double limiar,
}) {
  if (!anterior.isFinite || !atual.isFinite) {
    return DirecaoDaMedida.semComparacao;
  }
  if (!limiar.isFinite || limiar < 0) return DirecaoDaMedida.semComparacao;
  final diferenca = atual - anterior;
  if (diferenca == 0 || diferenca.abs() < limiar) {
    return DirecaoDaMedida.estavel;
  }
  return diferenca > 0 ? DirecaoDaMedida.subiu : DirecaoDaMedida.desceu;
}
