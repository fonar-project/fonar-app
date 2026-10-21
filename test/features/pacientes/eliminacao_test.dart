import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/pacientes/data/eliminacao_do_paciente.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/http_falso.dart';

/// Os arquivos de mentira: só anota o que foi apagado.
class _Arquivos implements ArquivosDeAmostra {
  final apagados = <String>[];

  @override
  Future<void> apagar(String caminho) async => apagados.add(caminho);

  @override
  Future<Uint8List?> lerTudo(String caminho) async => null;

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async => null;

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao tarefa) =>
      throw UnimplementedError();
}

Future<void> _semear(BancoLocal banco, String paciente) async {
  await banco
      .into(banco.pacientes)
      .insert(
        PacientesCompanion.insert(
          id: paciente,
          nome: 'Paciente $paciente de Teste',
          queixa: '',
          cadastradoEm: DateTime(2026, 10, 1),
        ),
      );
  final consentimento = await banco
      .into(banco.consentimentos)
      .insert(
        ConsentimentosCompanion.insert(
          pacienteId: paciente,
          registradoEm: DateTime(2026, 10, 1, 9),
          versaoDoTermo: '1',
          quemAutoriza: 'paciente',
        ),
      );
  await banco
      .into(banco.retiradasDeConsentimento)
      .insert(
        RetiradasDeConsentimentoCompanion.insert(
          pacienteId: paciente,
          consentimentoId: Value(consentimento),
          retiradaEm: DateTime(2026, 10, 2, 9),
          quemPediu: 'paciente',
        ),
      );
  await banco
      .into(banco.amostras)
      .insert(
        AmostrasCompanion.insert(
          id: 'a-$paciente',
          pacienteId: paciente,
          sessaoId: 's-$paciente',
          tarefa: 'vogalSustentada',
          caminho: '/amostras/$paciente/a.wav',
          gravadaEm: DateTime(2026, 10, 1, 9, 30),
          duracaoEmMs: 3000,
          taxaDeAmostragem: 44100,
          canais: 1,
          problemas: '',
        ),
      );
  await banco
      .into(banco.envios)
      .insert(
        EnviosCompanion.insert(
          id: 'envio-$paciente',
          pacienteId: paciente,
          nomeDoPaciente: 'Paciente $paciente de Teste',
          sessaoId: 's-$paciente',
          criadoEm: DateTime(2026, 10, 1, 9, 31),
          situacao: 'enviado',
          tentativas: 1,
        ),
      );
  await banco
      .into(banco.amostrasDoEnvio)
      .insert(
        AmostrasDoEnvioCompanion.insert(
          envioId: 'envio-$paciente',
          amostraId: 'a-$paciente',
          ordem: 0,
        ),
      );
  await banco
      .into(banco.avaliacoesCapeV)
      .insert(
        AvaliacoesCapeVCompanion.insert(
          analiseId: 's-$paciente',
          pacienteId: paciente,
          registradaEm: DateTime(2026, 10, 1, 10),
          comentarios: '',
        ),
      );
  await banco
      .into(banco.notasCapeV)
      .insert(
        NotasCapeVCompanion.insert(
          analiseId: 's-$paciente',
          parametro: 'grauGeral',
          valor: const Value(0),
        ),
      );
  await banco
      .into(banco.laudos)
      .insert(
        LaudosCompanion.insert(
          id: 'laudo-$paciente',
          analiseId: 's-$paciente',
          pacienteId: paciente,
          conclusao: 'x',
          geradoEm: DateTime(2026, 10, 1, 11),
          pdf: Uint8List.fromList([1, 2, 3]),
        ),
      );
}

Future<Map<String, int>> _contar(BancoLocal banco) async => {
  for (final (nome, tabela) in [
    ('pacientes', banco.pacientes.actualTableName),
    ('consentimentos', banco.consentimentos.actualTableName),
    ('retiradas', banco.retiradasDeConsentimento.actualTableName),
    ('amostras', banco.amostras.actualTableName),
    ('envios', banco.envios.actualTableName),
    ('amostrasDoEnvio', banco.amostrasDoEnvio.actualTableName),
    ('capeV', banco.avaliacoesCapeV.actualTableName),
    ('notasCapeV', banco.notasCapeV.actualTableName),
    ('laudos', banco.laudos.actualTableName),
  ])
    nome:
        (await banco
                .customSelect('SELECT count(*) AS n FROM $tabela')
                .getSingle())
            .read<int>('n'),
};

void main() {
  late BancoLocal banco;
  late _Arquivos arquivos;
  late AdaptadorFalso servidor;

  setUp(() async {
    banco = bancoEmMemoria();
    arquivos = _Arquivos();
    await _semear(banco, 'p1');
    await _semear(banco, 'p2');
  });
  tearDown(() => banco.close());

  EliminacaoDoPaciente eliminacao(List<RespostaFalsa> respostas) {
    servidor = AdaptadorFalso(respostas);
    return EliminacaoDoPaciente(
      banco,
      arquivos,
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = servidor
        ..interceptors.add(const ErrorInterceptor()),
    );
  }

  test(
    'apaga no servidor e depois tudo daqui; o outro paciente fica',
    () async {
      await eliminacao([const RespostaFalsa(200, {})]).eliminar('p1');

      expect(servidor.feitas.single.opcoes.method, 'DELETE');
      expect(servidor.feitas.single.uri.path, '/v1/pacientes/p1');
      // Sobra só o p2, inteiro.
      expect(await _contar(banco), {
        for (final nome in [
          'pacientes',
          'consentimentos',
          'retiradas',
          'amostras',
          'envios',
          'amostrasDoEnvio',
          'capeV',
          'notasCapeV',
          'laudos',
        ])
          nome: 1,
      });
      expect(arquivos.apagados, ['/amostras/p1/a.wav']);
    },
  );

  test('paciente que nunca subiu: o servidor não tem, e aqui sai', () async {
    await eliminacao([
      const RespostaFalsa(404, {
        'detail': {'codigo': 'paciente_nao_encontrado', 'mensagem': 'x'},
      }),
    ]).eliminar('p1');

    expect((await _contar(banco))['pacientes'], 1);
  });

  test('servidor fora: nada daqui é apagado', () async {
    await expectLater(
      eliminacao([const RespostaFalsa(503, {})]).eliminar('p1'),
      throwsA(isA<AppException>()),
    );
    expect((await _contar(banco))['pacientes'], 2);
    expect(arquivos.apagados, isEmpty);
  });

  test('sem API (modo de exemplo), só o aparelho', () async {
    await EliminacaoDoPaciente(banco, arquivos).eliminar('p2');
    expect((await _contar(banco))['laudos'], 1);
    expect(arquivos.apagados, ['/amostras/p2/a.wav']);
  });
}
