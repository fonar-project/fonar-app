import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/analise/data/catalogo_de_referencias_vazio.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_api.dart';
import 'package:fonar_app/features/analise/domain/faixa_de_referencia.dart';
import 'package:fonar_app/features/analise/domain/leitura_do_resultado.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';

import '../../apoio/http_falso.dart';

const _paciente = '0f8b7e5c-3c1a-4d2e-9f00-1a2b3c4d5e6f';
const _sessao = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

/// Uma medida como a API manda.
Map<String, Object?> _medida(
  String identificador,
  num? valor,
  String unidade, {
  Map<String, Object?>? faixa,
}) => {
  'identificador': identificador,
  'nome': identificador,
  'unidade': unidade,
  'valor': valor,
  'situacao': faixa == null ? 'sem_referencia' : 'dentro_da_faixa',
  'faixa': faixa,
};

/// A faixa do jitter como a API manda: em fração, como o motor mede.
Map<String, Object?> _faixaDoJitter({required bool provisoria}) => {
  'limite_inferior': null,
  'limite_superior': 0.0104,
  'unidade': 'fracao',
  'referencia_provisoria': provisoria,
  'fonte_bibliografica': 'MDVP',
  'populacao_descricao': 'adultos',
};

/// A análise de uma sessão como a API manda, com as duas tarefas: a fala
/// encadeada VEM ANTES, para provar que as medidas são lidas da vogal.
Map<String, Object?> _analise({bool completa = true, bool provisoria = true}) =>
    {
      'id': _sessao,
      'paciente_id': _paciente,
      'sessao_id': _sessao,
      'data': '2026-10-11T13:30:00Z',
      'estado': 'concluida',
      'tarefas': ['vogal_sustentada', 'fala_encadeada'],
      'completa': completa,
      'amostras': [
        {
          'amostra': {'id': 'a2', 'tipo_tarefa': 'fala_encadeada'},
          'resultado': {
            'id': 'r2',
            'medidas': [_medida('jitter.local', 0.05, 'fracao')],
          },
        },
        {
          'amostra': {'id': 'a1', 'tipo_tarefa': 'vogal_sustentada'},
          'resultado': {
            'id': 'r1',
            'medidas': [
              _medida(
                'jitter.local',
                0.0042,
                'fracao',
                faixa: _faixaDoJitter(provisoria: provisoria),
              ),
              _medida('shimmer.local', 0.031, 'fracao'),
              _medida('hnr.mean_db', 21.5, 'db'),
              _medida('f0.mean_hz', 212, 'hz'),
              _medida('cpps.mean_db', 14.2, 'db'),
              _medida('pulses.n_points', 239, 'contagem'),
            ],
          },
        },
      ],
    };

({RepositorioAnalisesApi repositorio, AdaptadorFalso servidor}) _montar(
  List<RespostaFalsa> respostas,
) {
  final servidor = AdaptadorFalso(respostas);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = servidor
    ..interceptors.add(const ErrorInterceptor());
  return (repositorio: RepositorioAnalisesApi(dio), servidor: servidor);
}

double? _valor(ResultadoDaAnalise r, MedidaAcustica m) => r.valorDe(m);

void main() {
  test('a análise é a sessão, com as medidas da vogal sustentada', () async {
    final m = _montar([RespostaFalsa(200, _analise())]);

    final resultado = await m.repositorio.buscar(_paciente, _sessao);

    expect(
      m.servidor.feitas.single.uri.toString(),
      'https://api.test/v1/pacientes/$_paciente/sessoes/$_sessao/analise',
    );
    expect(resultado.id, _sessao);
    expect(resultado.pacienteId, _paciente);
    expect(resultado.situacao, SituacaoDaAnalise.concluida);
    expect(resultado.realizadaEm, DateTime.utc(2026, 10, 11, 13, 30));
    expect(resultado.exemplo, isFalse);
    // O jitter da VOGAL (0,0042), e não o da fala (0,05) - em porcentagem.
    expect(_valor(resultado, MedidaAcustica.jitter), closeTo(0.42, 1e-9));
    expect(_valor(resultado, MedidaAcustica.shimmer), closeTo(3.1, 1e-9));
    // dB e Hz chegam como estão.
    expect(_valor(resultado, MedidaAcustica.hnr), 21.5);
    expect(_valor(resultado, MedidaAcustica.f0), 212);
    expect(_valor(resultado, MedidaAcustica.cpps), 14.2);
    // O que a API ainda não calcula aparece como "não calculada".
    expect(_valor(resultado, MedidaAcustica.avqi), isNull);
    // O espectrograma é o da gravação da VOGAL (a1), pedido à API.
    expect(
      resultado.espectrogramaUrl,
      '/v1/pacientes/$_paciente/sessoes/$_sessao/amostras/a1/espectrograma',
    );
    expect(resultado.medidas.map((x) => x.medida), MedidaAcustica.values);
  });

  test('faixa provisória não classifica: o valor aparece sem faixa', () async {
    final m = _montar([RespostaFalsa(200, _analise())]);
    final resultado = await m.repositorio.buscar(_paciente, _sessao);
    final jitter = resultado.medidas.firstWhere(
      (x) => x.medida == MedidaAcustica.jitter,
    );
    expect(jitter.faixa, isNull);

    final lidas = lerMedidas(
      resultado: resultado,
      sexo: SexoDeReferencia.feminino,
      dataDeNascimento: DateTime(1990, 6, 15),
      catalogo: const CatalogoDeReferenciasVazio(),
    );
    final lida = lidas.firstWhere((x) => x.medida == MedidaAcustica.jitter);
    expect(lida.valor, closeTo(0.42, 1e-9));
    expect(lida.classificacao, ClassificacaoDaMedida.semReferencia);
    expect(
      lida.semClassificacaoPorque,
      SemClassificacaoPorque.semFaixaValidada,
    );
  });

  test('faixa validada vem na unidade da tela e classifica', () async {
    final m = _montar([RespostaFalsa(200, _analise(provisoria: false))]);
    final resultado = await m.repositorio.buscar(_paciente, _sessao);
    final faixa = resultado.medidas
        .firstWhere((x) => x.medida == MedidaAcustica.jitter)
        .faixa!;
    expect(faixa.minimo, isNull);
    expect(faixa.maximo, closeTo(1.04, 1e-9));
    expect(faixa.procedencia, 'MDVP — adultos');

    final lida = lerMedidas(
      resultado: resultado,
      sexo: SexoDeReferencia.feminino,
      dataDeNascimento: DateTime(1990, 6, 15),
      catalogo: const CatalogoDeReferenciasVazio(),
    ).firstWhere((x) => x.medida == MedidaAcustica.jitter);
    expect(lida.classificacao, ClassificacaoDaMedida.dentroDaFaixa);
  });

  test('sessão sem todos os resultados ainda está processando', () async {
    final m = _montar([RespostaFalsa(200, _analise(completa: false))]);
    final resultado = await m.repositorio.buscar(_paciente, _sessao);
    expect(resultado.situacao, SituacaoDaAnalise.processando);
  });

  test('a evolução é a lista do paciente, na ordem da API', () async {
    final segunda = {..._analise(), 'id': 's2', 'data': '2026-11-01T10:00:00Z'};
    final m = _montar([
      RespostaFalsa(200, [_analise(), segunda]),
    ]);
    final analises = await m.repositorio.doPaciente(_paciente);
    expect(
      m.servidor.feitas.single.uri.toString(),
      'https://api.test/v1/pacientes/$_paciente/analises',
    );
    expect([for (final a in analises) a.id], [_sessao, 's2']);
  });

  test('paciente que ainda não subiu não tem análise, e não é erro', () async {
    final m = _montar([
      const RespostaFalsa(404, {
        'detail': {'codigo': 'paciente_nao_encontrado', 'mensagem': 'x'},
      }),
    ]);
    expect(await m.repositorio.doPaciente(_paciente), isEmpty);
  });

  test('a análise que não existe é NaoEncontrado', () async {
    final m = _montar([
      const RespostaFalsa(404, {
        'detail': {'codigo': 'sessao_nao_encontrada', 'mensagem': 'x'},
      }),
    ]);
    await expectLater(
      m.repositorio.buscar(_paciente, _sessao),
      throwsA(isA<NaoEncontrado>()),
    );
  });

  test('sem gravação da vogal, nada é lido da fala encadeada', () {
    final corpo = _analise();
    corpo['amostras'] = [(corpo['amostras'] as List).first];
    final resultado = analiseDaApi(corpo);
    for (final m in resultado.medidas) {
      expect(m.valor, isNull, reason: m.medida.name);
    }
    // Nem o espectrograma: ele é o da vogal.
    expect(resultado.espectrogramaUrl, isNull);
  });

  test('a faixa que veio do servidor é usada antes do catálogo', () {
    const doServidor = FaixaDeReferencia(procedencia: 'servidor', maximo: 1);
    final resultado = ResultadoDaAnalise(
      id: 's',
      pacienteId: 'p',
      situacao: SituacaoDaAnalise.concluida,
      realizadaEm: DateTime(2026, 10, 11),
      medidas: const [
        MedidaCalculada(
          medida: MedidaAcustica.jitter,
          valor: 2,
          faixa: doServidor,
        ),
      ],
    );
    final lida = lerMedidas(
      resultado: resultado,
      sexo: SexoDeReferencia.masculino,
      dataDeNascimento: DateTime(1980),
      catalogo: const CatalogoDeReferenciasVazio(),
    ).single;
    expect(lida.classificacao, ClassificacaoDaMedida.foraDaFaixa);
    expect(lida.faixa, same(doServidor));
  });
}
