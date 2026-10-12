import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/faixa_de_referencia.dart';
import '../domain/resultado_da_analise.dart';

/// Os resultados lidos da API de análise (repositório `fonar-api`).
///
/// A análise é a SESSÃO (ADR-014 da API):
///
/// - `GET /v1/pacientes/{p}/sessoes/{s}/analise`: a sessão, com cada
///   gravação e o resultado mais recente dela;
/// - `GET /v1/pacientes/{p}/analises`: as sessões gravadas do paciente, da
///   mais antiga à mais recente.
///
/// Os números são os do motor (parselmouth, que executa o Praat), sem conta
/// nenhuma aqui — ver [analiseDaApi].
class RepositorioAnalisesApi implements RepositorioAnalises {
  const RepositorioAnalisesApi(this._dio);

  final Dio _dio;

  @override
  Future<ResultadoDaAnalise> buscar(String pacienteId, String analiseId) async {
    final corpo = await _ler(
      '/v1/pacientes/$pacienteId/sessoes/$analiseId/analise',
    );
    if (corpo is! Map) {
      throw const FalhaDesconhecida(causa: 'análise sem corpo');
    }
    return analiseDaApi(corpo);
  }

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async {
    final Object? corpo;
    try {
      corpo = await _ler('/v1/pacientes/$pacienteId/analises');
    } on NaoEncontrado {
      // Paciente que nunca mandou nada para a análise ainda não está no
      // Firebase: não tem análise, e não é erro.
      return const [];
    }
    if (corpo is! List) {
      throw const FalhaDesconhecida(causa: 'lista sem corpo');
    }
    return [
      for (final analise in corpo)
        if (analise is Map) analiseDaApi(analise),
    ];
  }

  Future<Object?> _ler(String caminho) async {
    try {
      return (await _dio.get<Object?>(caminho)).data;
    } on DioException catch (e) {
      final falha = e.error;
      throw falha is AppException ? falha : FalhaDesconhecida(causa: e);
    }
  }
}

/// De qual medida do motor vem cada medida da tela.
///
/// Jitter, shimmer, HNR, f0 e CPPS são da gravação da vogal sustentada. O
/// AVQI é da SESSÃO — junta a vogal e a fala encadeada —, e a API o manda à
/// parte, em `resultado_da_sessao` (ADR-016 do `fonar-api`): o script
/// oficial do AVQI v03.01, rodado no Praat do servidor.
///
/// Medida sem identificador (nulo) é a que a API ainda não calcula: aparece
/// como "ainda não disponível", nunca como zero — e nunca como se a
/// gravação tivesse dado problema.
const identificadorNaApi = <MedidaAcustica, String?>{
  MedidaAcustica.avqi: 'avqi.valor',
  MedidaAcustica.cpps: 'cpps.mean_db',
  MedidaAcustica.jitter: 'jitter.local',
  MedidaAcustica.shimmer: 'shimmer.local',
  MedidaAcustica.hnr: 'hnr.mean_db',
  MedidaAcustica.f0: 'f0.mean_hz',
};

/// A análise da API no formato das telas.
///
/// Só troca de unidade: o motor dá jitter e shimmer como FRAÇÃO (0,0104), e
/// a tela mostra em porcentagem (1,04 %) — multiplicar por 100 é formatação,
/// não análise. Valor e limites da faixa mudam juntos.
///
/// Faixa PROVISÓRIA (`referencia_provisoria`, ainda sem validação clínica)
/// não vem para a tela: a medida aparece com o valor do motor e sem
/// classificação, como manda a regra das faixas (CLAUDE.md). Quando o
/// co-orientador validar, a faixa passa a vir, sem mudar nada aqui.
ResultadoDaAnalise analiseDaApi(Map<Object?, Object?> corpo) {
  final amostras = [
    for (final a in (corpo['amostras'] as List?) ?? const [])
      if (a is Map) a,
  ];
  final vogal = amostras
      .where(
        (a) =>
            (a['amostra'] as Map?)?['tipo_tarefa'] == 'vogal_sustentada' &&
            a['resultado'] is Map,
      )
      .firstOrNull;
  final medidasDaVogal = <String, Map<Object?, Object?>>{
    if (vogal != null)
      for (final m
          in ((vogal['resultado'] as Map)['medidas'] as List?) ?? const [])
        if (m is Map && m['identificador'] is String)
          m['identificador'] as String: m,
  };

  // O AVQI vem da sessão, não de uma gravação. Nulo enquanto a sessão não
  // tem as duas tarefas, ou quando a API não pôde calcular agora; com
  // `erro`, vem sem medidas. Nos dois casos o AVQI fica "não calculado".
  final daSessao = corpo['resultado_da_sessao'];
  final medidasDaSessao = <String, Map<Object?, Object?>>{
    if (daSessao is Map)
      for (final m in (daSessao['medidas'] as List?) ?? const [])
        if (m is Map && m['identificador'] is String)
          m['identificador'] as String: m,
  };
  // Os identificadores da sessão (`avqi.*`) não se repetem nos da vogal:
  // o CPPS da equação do AVQI é `avqi.cpps_db`, não o `cpps.mean_db`.
  final medidasDaApi = {...medidasDaVogal, ...medidasDaSessao};

  final completa = corpo['completa'] == true;
  final pacienteId = corpo['paciente_id'] as String;
  final sessaoId = (corpo['sessao_id'] ?? corpo['id']) as String;
  final amostraDaVogal = (vogal?['amostra'] as Map?)?['id'];
  return ResultadoDaAnalise(
    id: corpo['id'] as String,
    pacienteId: pacienteId,
    situacao: completa
        ? SituacaoDaAnalise.concluida
        : SituacaoDaAnalise.processando,
    realizadaEm: DateTime.tryParse('${corpo['data']}'),
    // O espectrograma da vogal, gerado pela API a partir do áudio guardado.
    // Caminho relativo: quem busca é o cliente da API, com o token (ver
    // `imagemDoServidorProvider`).
    espectrogramaUrl: amostraDaVogal is String
        ? '/v1/pacientes/$pacienteId/sessoes/$sessaoId/amostras/'
              '$amostraDaVogal/espectrograma'
        : null,
    medidas: [
      for (final MapEntry(key: medida, value: identificador)
          in identificadorNaApi.entries)
        if (identificador == null)
          MedidaCalculada(medida: medida, valor: null, disponivel: false)
        else
          _medida(medida, medidasDaApi[identificador]),
    ],
  );
}

MedidaCalculada _medida(MedidaAcustica medida, Map<Object?, Object?>? daApi) {
  if (daApi == null) return MedidaCalculada(medida: medida, valor: null);
  final escala = daApi['unidade'] == 'fracao' ? 100.0 : 1.0;
  final valor = daApi['valor'];
  return MedidaCalculada(
    medida: medida,
    valor: valor is num ? valor.toDouble() * escala : null,
    faixa: _faixaValidada(daApi['faixa'], escala),
  );
}

FaixaDeReferencia? _faixaValidada(Object? faixa, double escala) {
  if (faixa is! Map || faixa['referencia_provisoria'] != false) return null;
  double? limite(Object? v) => v is num ? v.toDouble() * escala : null;
  final minimo = limite(faixa['limite_inferior']);
  final maximo = limite(faixa['limite_superior']);
  if (minimo == null && maximo == null) return null;
  final fonte = '${faixa['fonte_bibliografica'] ?? ''}'.trim();
  final populacao = '${faixa['populacao_descricao'] ?? ''}'.trim();
  return FaixaDeReferencia(
    minimo: minimo,
    maximo: maximo,
    procedencia: populacao.isEmpty ? fonte : '$fonte — $populacao',
  );
}
