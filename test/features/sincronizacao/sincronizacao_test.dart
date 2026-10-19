import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/firestore/firestore_rest.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/sincronizacao/data/sincronizacao_firestore.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/http_falso.dart';
import '../../core/migracoes/schema.dart';

const _uid = 'uid-de-teste';
const _paciente = '0f8b7e5c-3c1a-4d2e-9f00-1a2b3c4d5e6f';
const _sessao = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const _documentos = 'projects/demo/databases/(default)/documents';
const _base = 'profissionais/$_uid/pacientes/$_paciente';

const _naoExiste = RespostaFalsa(404, {
  'error': {'code': 404, 'status': 'NOT_FOUND'},
});
const _ok = RespostaFalsa(200, {});

final _gravadaEm = DateTime.utc(2026, 10, 11, 13, 30);

ItemDaFila _item() => ItemDaFila(
  id: 'envio-$_sessao',
  pacienteId: _paciente,
  nomeDoPaciente: 'Ana de Teste',
  sessaoId: _sessao,
  amostras: [
    Amostra(
      id: 'a1',
      pacienteId: _paciente,
      sessaoId: _sessao,
      tarefa: TarefaDeGravacao.vogalSustentada,
      caminho: '/amostras/a1.wav',
      gravadaEm: _gravadaEm,
      duracao: const Duration(seconds: 3),
      taxaDeAmostragem: 44100,
      canais: 1,
      problemas: const [],
    ),
  ],
  criadoEm: _gravadaEm,
);

class _Montagem {
  _Montagem(this.banco, this.servidor)
    : sincronizacao = SincronizacaoFirestore(
        FirestoreRest(
          Dio(
              BaseOptions(
                baseUrl: 'https://firestore.googleapis.com/v1/',
                contentType: Headers.jsonContentType,
              ),
            )
            ..httpClientAdapter = servidor
            ..interceptors.add(const ErrorInterceptor()),
          projeto: 'demo',
        ),
        banco,
        uid: () => _uid,
      );

  final BancoLocal banco;
  final AdaptadorFalso servidor;
  final SincronizacaoFirestore sincronizacao;

  /// As escritas feitas, na ordem: o `update` de cada commit.
  List<Map<String, Object?>> get escritas => [
    for (final pedido in servidor.feitas)
      if (pedido.opcoes.method == 'POST')
        (pedido.json['writes'] as List).single as Map<String, Object?>,
  ];
}

Future<_Montagem> _montar(
  List<RespostaFalsa> respostas, {
  bool comRetirada = false,
  String? responsavel,
}) async {
  final banco = bancoEmMemoria();
  addTearDown(banco.close);
  await banco
      .into(banco.pacientes)
      .insert(
        PacientesCompanion.insert(
          id: _paciente,
          nome: 'Ana de Teste',
          queixa: 'rouquidão (teste)',
          sexo: const Value('feminino'),
          dataDeNascimento: Value(DateTime(1990, 6, 15)),
          cadastradoEm: DateTime(2026, 10, 1),
        ),
      );
  final consentimento = await banco
      .into(banco.consentimentos)
      .insert(
        ConsentimentosCompanion.insert(
          pacienteId: _paciente,
          registradoEm: DateTime.utc(2026, 10, 1, 9),
          versaoDoTermo: 'provisorio-1',
          quemAutoriza: responsavel == null ? 'paciente' : 'responsavelLegal',
          nomeDoResponsavel: Value(responsavel),
        ),
      );
  if (comRetirada) {
    await banco
        .into(banco.retiradasDeConsentimento)
        .insert(
          RetiradasDeConsentimentoCompanion.insert(
            pacienteId: _paciente,
            consentimentoId: Value(consentimento),
            retiradaEm: DateTime.utc(2026, 10, 2, 9),
            quemPediu: 'paciente',
            nomeDoResponsavel: const Value(null),
          ),
        );
  }
  return _Montagem(banco, AdaptadorFalso(respostas));
}

Map<String, Object?> _paginaDeConsentimentos(List<Map<String, Object?>> c) => {
  'documents': [
    for (final campos in c)
      {
        'name': '$_documentos/$_base/consentimentos/${campos['seq']}',
        'fields': codificar(campos),
      },
  ],
};

void main() {
  test('nada no Firebase: sobem o paciente, o livro e a sessão', () async {
    final m = await _montar([
      _naoExiste, // paciente
      _ok, // cria o paciente
      _ok, // lista os consentimentos: nenhum
      _ok, // cria o consentimento 1
      _naoExiste, // sessão
      _ok, // cria a sessão
    ]);

    await m.sincronizacao.prepararEnvio(_item());

    final [paciente, consentimento, sessao] = m.escritas;
    expect(paciente['currentDocument'], {'exists': false});
    expect((paciente['update'] as Map)['name'], '$_documentos/$_base');
    expect((paciente['update'] as Map)['fields'], {
      'nome': {'stringValue': 'Ana de Teste'},
      // Data sem hora, à meia-noite UTC.
      'data_nascimento': {'timestampValue': '1990-06-15T00:00:00.000Z'},
      'sexo_referencia': {'stringValue': 'feminino'},
      'queixa_principal': {'stringValue': 'rouquidão (teste)'},
    });
    expect(paciente['updateTransforms'], [
      {'fieldPath': 'criado_em', 'setToServerValue': 'REQUEST_TIME'},
    ]);

    expect(
      (consentimento['update'] as Map)['name'],
      '$_documentos/$_base/consentimentos/1',
    );
    expect((consentimento['update'] as Map)['fields'], {
      'seq': {'integerValue': '1'},
      'tipo': {'stringValue': 'concessao'},
      'data': {'timestampValue': '2026-10-01T09:00:00.000Z'},
      'versao_termo': {'stringValue': 'provisorio-1'},
      'declarante': {'stringValue': 'paciente'},
    });
    expect(consentimento['updateTransforms'], [
      {'fieldPath': 'registrado_em', 'setToServerValue': 'REQUEST_TIME'},
    ]);

    expect(
      (sessao['update'] as Map)['name'],
      '$_documentos/$_base/sessoes/$_sessao',
    );
    expect((sessao['update'] as Map)['fields'], {
      'data': {'timestampValue': '2026-10-11T13:30:00.000Z'},
      'estado': {'stringValue': 'concluida'},
    });
  });

  test(
    'o responsável legal vai com o nome; a retirada vem logo depois',
    () async {
      final m = await _montar(
        [_naoExiste, _ok, _ok, _ok, _ok, _naoExiste, _ok],
        comRetirada: true,
        responsavel: 'Maria Souza',
      );

      await m.sincronizacao.prepararEnvio(_item());

      final concessao = (m.escritas[1]['update'] as Map)['fields'] as Map;
      expect(concessao['declarante'], {'stringValue': 'responsavel_legal'});
      expect(concessao['nome_responsavel'], {'stringValue': 'Maria Souza'});
      final retirada = (m.escritas[2]['update'] as Map)['fields'] as Map;
      expect(retirada['seq'], {'integerValue': '2'});
      expect(retirada['tipo'], {'stringValue': 'retirada'});
      // A retirada é da mesma versão do termo, e quem pediu foi o paciente:
      // sem nome de terceiro.
      expect(retirada['versao_termo'], {'stringValue': 'provisorio-1'});
      expect(retirada['declarante'], {'stringValue': 'paciente'});
      expect(retirada.containsKey('nome_responsavel'), isFalse);
    },
  );

  test('o que já está lá não é gravado de novo', () async {
    final m = await _montar([
      RespostaFalsa(200, {
        'name': '$_documentos/$_base',
        'fields': codificar({
          'nome': 'Ana de Teste',
          'data_nascimento': DateTime.utc(1990, 6, 15),
          'sexo_referencia': 'feminino',
          'queixa_principal': 'rouquidão (teste)',
          'criado_em': DateTime.utc(2026, 10, 1),
        }),
      }),
      RespostaFalsa(
        200,
        _paginaDeConsentimentos([
          {'seq': 1, 'tipo': 'concessao', 'versao_termo': 'provisorio-1'},
        ]),
      ),
      const RespostaFalsa(200, {'name': 'sessao', 'fields': {}}),
    ]);

    await m.sincronizacao.prepararEnvio(_item());

    expect(m.escritas, isEmpty);
    expect(m.servidor.feitas, hasLength(3));
  });

  test('o cadastro corrigido no aparelho atualiza o do Firebase', () async {
    final m = await _montar([
      RespostaFalsa(200, {
        'name': '$_documentos/$_base',
        'fields': codificar({
          'nome': 'Ana de Teste',
          'data_nascimento': DateTime.utc(1990, 6, 15),
          'sexo_referencia': 'feminino',
          'queixa_principal': 'queixa antiga',
        }),
      }),
      _ok, // atualiza o paciente
      RespostaFalsa(
        200,
        _paginaDeConsentimentos([
          {'seq': 1, 'tipo': 'concessao', 'versao_termo': 'provisorio-1'},
        ]),
      ),
      const RespostaFalsa(200, {'name': 'sessao', 'fields': {}}),
    ]);

    await m.sincronizacao.prepararEnvio(_item());

    final atualizacao = m.escritas.single;
    expect(atualizacao['currentDocument'], {'exists': true});
    expect(atualizacao['updateMask'], {
      'fieldPaths': [
        'nome',
        'data_nascimento',
        'sexo_referencia',
        'queixa_principal',
      ],
    });
    // A hora de criação não está na máscara: fica como o servidor gravou.
    expect(atualizacao.containsKey('updateTransforms'), isFalse);
  });

  test(
    'livro diferente no Firebase: nada é gravado e o envio é recusado',
    () async {
      final m = await _montar([
        _naoExiste,
        _ok,
        RespostaFalsa(
          200,
          _paginaDeConsentimentos([
            {'seq': 1, 'tipo': 'concessao', 'versao_termo': 'outra-versao'},
          ]),
        ),
      ]);

      await expectLater(
        m.sincronizacao.prepararEnvio(_item()),
        throwsA(isA<FalhaDeValidacao>()),
      );
      // Só o paciente subiu; consentimento e sessão, não.
      expect(m.escritas, hasLength(1));
      expect(
        PoliticaDeReenvio.depoisDe(const FalhaDeValidacao()),
        SituacaoDoEnvio.recusado,
      );
    },
  );

  test('sem sessão aberta, nada sai', () async {
    final m = await _montar([]);
    final semConta = SincronizacaoFirestore(
      FirestoreRest(Dio()..httpClientAdapter = m.servidor, projeto: 'demo'),
      m.banco,
      uid: () => null,
    );
    await expectLater(
      semConta.prepararEnvio(_item()),
      throwsA(isA<NaoAutorizado>()),
    );
    expect(m.servidor.feitas, isEmpty);
  });

  test('paciente que não está no banco (de exemplo) não sobe', () async {
    final m = await _montar([]);
    await m.banco.delete(m.banco.pacientes).go();
    await expectLater(
      m.sincronizacao.prepararEnvio(_item()),
      throwsA(isA<FalhaDeValidacao>()),
    );
    expect(m.servidor.feitas, isEmpty);
  });

  // Teste de homologação de 18/10/2026: o paciente cadastrado num aparelho,
  // sem gravação, não aparecia na versão web da mesma conta.
  group('sincronizar (sem envio)', () {
    /// O paciente de [_montar], da conta da sessão e cadastrado aqui.
    Future<_Montagem> montarDaConta(List<RespostaFalsa> respostas) async {
      final m = await _montar(respostas);
      await (m.banco.update(
        m.banco.pacientes,
      )..where((p) => p.id.equals(_paciente))).write(
        PacientesCompanion(
          profissionalId: const Value(_uid),
          alteradoEm: Value(DateTime(2026, 10, 1, 10)),
        ),
      );
      return m;
    }

    Future<LinhaDoPaciente> linha(_Montagem m) => (m.banco.select(
      m.banco.pacientes,
    )..where((p) => p.id.equals(_paciente))).getSingle();

    test('o cadastrado aqui sobe com o livro, sem sessão nenhuma', () async {
      final m = await montarDaConta([
        _naoExiste, // paciente
        _ok, // cria o paciente
        _ok, // lista os consentimentos: nenhum
        _ok, // cria o consentimento 1
      ]);

      expect(await m.sincronizacao.sincronizar(), 1);

      final [paciente, consentimento] = m.escritas;
      expect((paciente['update'] as Map)['name'], '$_documentos/$_base');
      expect(
        (consentimento['update'] as Map)['name'],
        '$_documentos/$_base/consentimentos/1',
      );
      // Nada de sessão: ela só existe com um envio.
      expect(
        m.servidor.feitas.where((f) => f.uri.path.contains('sessoes')),
        isEmpty,
      );
      final depois = await linha(m);
      expect(depois.sincronizadoEm, isNotNull);
      expect(depois.livroNoFirebase, 1);
    });

    test('subido, a vez seguinte não pergunta nada ao servidor', () async {
      final m = await montarDaConta([_naoExiste, _ok, _ok, _ok]);
      await m.sincronizacao.sincronizar();
      final feitas = m.servidor.feitas.length;

      expect(await m.sincronizacao.sincronizar(), 0);
      expect(m.servidor.feitas, hasLength(feitas));
    });

    test('a retirada registrada depois sobe sozinha', () async {
      final m = await montarDaConta([_naoExiste, _ok, _ok, _ok]);
      await m.sincronizacao.sincronizar();
      await m.banco
          .into(m.banco.retiradasDeConsentimento)
          .insert(
            RetiradasDeConsentimentoCompanion.insert(
              pacienteId: _paciente,
              consentimentoId: const Value(1),
              retiradaEm: DateTime.utc(2026, 10, 2, 9),
              quemPediu: 'paciente',
              nomeDoResponsavel: const Value(null),
            ),
          );
      m.servidor.respostas.addAll([
        RespostaFalsa(200, {
          'name': '$_documentos/$_base',
          'fields': codificar({
            'nome': 'Ana de Teste',
            'data_nascimento': DateTime.utc(1990, 6, 15),
            'sexo_referencia': 'feminino',
            'queixa_principal': 'rouquidão (teste)',
          }),
        }),
        RespostaFalsa(
          200,
          _paginaDeConsentimentos([
            {'seq': 1, 'tipo': 'concessao', 'versao_termo': 'provisorio-1'},
          ]),
        ),
        _ok, // cria a retirada
      ]);
      final antes = m.escritas.length;

      expect(await m.sincronizacao.sincronizar(), 1);

      // O cadastro já estava igual: só a retirada é escrita.
      final novas = m.escritas.sublist(antes);
      expect(novas, hasLength(1));
      expect(
        (novas.single['update'] as Map)['name'],
        '$_documentos/$_base/consentimentos/2',
      );
      expect((await linha(m)).livroNoFirebase, 2);
    });

    test('paciente de outra conta neste aparelho não sobe', () async {
      final m = await montarDaConta(const []);
      await (m.banco.update(m.banco.pacientes)
            ..where((p) => p.id.equals(_paciente)))
          .write(const PacientesCompanion(profissionalId: Value('outra')));

      expect(await m.sincronizacao.sincronizar(), 0);
      expect(m.servidor.feitas, isEmpty);
    });

    test('um paciente que falha não impede os outros', () async {
      final m = await montarDaConta([
        _naoExiste, // o completo; o incompleto nem chega ao servidor
        _ok,
        _ok,
      ]);
      // Cadastro de antes da US40, sem nascimento: não passa nas regras.
      await m.banco
          .into(m.banco.pacientes)
          .insert(
            PacientesCompanion.insert(
              id: 'incompleto',
              nome: 'Sem Nascimento (teste)',
              queixa: '',
              cadastradoEm: DateTime(2026, 9, 1),
              profissionalId: const Value(_uid),
              alteradoEm: Value(DateTime(2026, 9, 1)),
            ),
          );
      await (m.banco.delete(
        m.banco.consentimentos,
      )..where((c) => c.pacienteId.equals(_paciente))).go();

      await expectLater(
        m.sincronizacao.sincronizar(),
        throwsA(isA<FalhaDeValidacao>()),
      );
      expect((await linha(m)).sincronizadoEm, isNotNull);
    });

    test('sem sessão aberta, nada sai', () async {
      final m = await montarDaConta(const []);
      final semConta = SincronizacaoFirestore(
        FirestoreRest(Dio()..httpClientAdapter = m.servidor, projeto: 'demo'),
        m.banco,
        uid: () => null,
      );

      await expectLater(semConta.sincronizar(), throwsA(isA<NaoAutorizado>()));
      expect(m.servidor.feitas, isEmpty);
    });
  });

  test(
    'migração: o banco da versão 8 ganha a marca do livro, em zero',
    () async {
      final verificador = SchemaVerifier(GeneratedHelper());
      final esquema = await verificador.schemaAt(8);
      final banco = BancoLocal(esquema.newConnection());
      addTearDown(banco.close);
      await verificador.migrateAndValidate(banco, banco.schemaVersion);

      await banco
          .into(banco.pacientes)
          .insert(
            PacientesCompanion.insert(
              id: _paciente,
              nome: 'Ana de Teste',
              queixa: '',
              cadastradoEm: DateTime(2026, 10, 1),
            ),
          );
      // Zero: a primeira subida confere o livro com o do Firebase e acerta.
      expect(
        (await banco.select(banco.pacientes).getSingle()).livroNoFirebase,
        0,
      );
    },
  );
}
