import '../../../l10n/app_strings.dart';
import '../domain/avaliacao_cape_v.dart';

/// Como cada parâmetro e cada opção aparecem. Só apresentação.
extension ApresentacaoDoParametro on ParametroCapeV {
  String get nome => switch (this) {
    ParametroCapeV.grauGeral => AppStrings.capeVGrauGeral,
    ParametroCapeV.rugosidade => AppStrings.capeVRugosidade,
    ParametroCapeV.soprosidade => AppStrings.capeVSoprosidade,
    ParametroCapeV.tensao => AppStrings.capeVTensao,
    ParametroCapeV.pitch => AppStrings.capeVPitch,
    ParametroCapeV.loudness => AppStrings.capeVLoudness,
  };

  /// Rótulo de cada sentido de desvio — só pitch e loudness têm.
  String nomeDaDirecao(DirecaoDoDesvio d) => switch ((this, d)) {
    (ParametroCapeV.pitch, DirecaoDoDesvio.abaixo) =>
      AppStrings.capeVPitchAbaixo,
    (ParametroCapeV.pitch, DirecaoDoDesvio.acima) => AppStrings.capeVPitchAcima,
    (ParametroCapeV.loudness, DirecaoDoDesvio.abaixo) =>
      AppStrings.capeVLoudnessAbaixo,
    (_, DirecaoDoDesvio.acima) => AppStrings.capeVLoudnessAcima,
    (_, DirecaoDoDesvio.abaixo) => AppStrings.capeVLoudnessAbaixo,
  };
}

String nomeDaConsistencia(Consistencia c) => switch (c) {
  Consistencia.consistente => AppStrings.capeVConsistente,
  Consistencia.intermitente => AppStrings.capeVIntermitente,
};

String mensagemDoProblema(ProblemaNaNota p) => switch (p) {
  ProblemaNaNota.naoMarcada => AppStrings.capeVMarque,
  ProblemaNaNota.semConsistencia => AppStrings.capeVEscolhaConsistencia,
  ProblemaNaNota.semDirecao => AppStrings.capeVEscolhaSentido,
};

/// "37 · consistente · mais grave". Para o resumo na tela de resultado.
String resumirNota(ParametroCapeV parametro, NotaCapeV nota) => [
  '${nota.valor}',
  if (nota.consistencia case final c?) nomeDaConsistencia(c).toLowerCase(),
  if (nota.direcao case final d?) parametro.nomeDaDirecao(d).toLowerCase(),
].join(' · ');
