import '../../captura/domain/amostra.dart';
import '../../historico/domain/evolucao_da_medida.dart';

/// Em que pé a análise está no servidor.
enum SituacaoDaAnalise {
  /// Recebida, ainda calculando. A análise roda no servidor
  /// (parselmouth/Praat) e não é instantânea.
  processando,
  concluida,

  /// O servidor não conseguiu analisar — ex.: amostra inaproveitável.
  falhou,
}

/// Uma medida como chegou do servidor.
class MedidaCalculada {
  const MedidaCalculada({required this.medida, required this.valor});

  final MedidaAcustica medida;

  /// Nulo quando o servidor não conseguiu calcular esta medida — acontece,
  /// por exemplo, com f0 numa amostra muito irregular. A medida aparece como
  /// "não calculada", nunca como zero.
  final double? valor;
}

/// O que o servidor achou da amostra como material de análise.
class QualidadeDaAmostra {
  const QualidadeDaAmostra({required this.adequada, this.motivo});

  final bool adequada;

  /// Por que não é adequada, nas palavras do servidor.
  final String? motivo;
}

/// Resultado de uma análise, pronto do servidor.
///
/// NENHUM valor aqui é calculado no aplicativo: toda medida vem da API, que usa
/// o motor do Praat. Regra arquitetural do projeto — ver CLAUDE.md.
class ResultadoDaAnalise {
  const ResultadoDaAnalise({
    required this.id,
    required this.pacienteId,
    required this.situacao,
    this.realizadaEm,
    this.medidas = const [],
    this.qualidade = const {},
    this.espectrogramaUrl,
    this.motivoDaFalha,
    this.exemplo = false,
  });

  final String id;
  final String pacienteId;
  final SituacaoDaAnalise situacao;

  /// Quando as amostras foram gravadas — é a data que vale para a idade do
  /// paciente na faixa de referência.
  final DateTime? realizadaEm;
  final List<MedidaCalculada> medidas;
  final Map<TarefaDeGravacao, QualidadeDaAmostra> qualidade;

  /// Imagem PRONTA do servidor. O aplicativo não desenha espectrograma — ver
  /// CLAUDE.md.
  final String? espectrogramaUrl;

  /// Quando [SituacaoDaAnalise.falhou].
  final String? motivoDaFalha;

  /// Dado de desenvolvimento, fictício. A tela avisa, para que nenhuma
  /// captura de tela o faça passar por resultado de verdade.
  final bool exemplo;
}

/// A análise pedida não é do paciente em que se está.
class AnaliseDeOutroPaciente implements Exception {
  const AnaliseDeOutroPaciente();
}

/// [resultado], se for de [pacienteId]; senão lança [AnaliseDeOutroPaciente].
///
/// Uma análise só é lida, avaliada ou laudada no contexto do paciente a que
/// pertence. Sem esta conferência, as medidas de um paciente eram lidas com o
/// perfil de outro, e um laudo podia sair com o nome de A e as medidas de B
/// (achado da revisão de 23/09). Resultado, CAPE-V e laudo passam todos por
/// aqui.
ResultadoDaAnalise daPaciente(ResultadoDaAnalise resultado, String pacienteId) {
  if (resultado.pacienteId != pacienteId) throw const AnaliseDeOutroPaciente();
  return resultado;
}

/// De onde vêm os resultados.
abstract interface class RepositorioAnalises {
  /// Lança só `AppException`.
  Future<ResultadoDaAnalise> buscar(String analiseId);
}
