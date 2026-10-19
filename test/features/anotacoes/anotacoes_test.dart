import 'package:dio/dio.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/firestore/firestore_rest.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/anotacoes/data/anotacoes_no_firestore.dart';
import 'package:fonar_app/features/anotacoes/data/repositorio_anotacoes_local.dart';
import 'package:fonar_app/features/anotacoes/domain/anotacao.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/http_falso.dart';
import '../../core/migracoes/schema.dart';

const _uid = 'uid-de-teste';
const _paciente = '0f8b7e5c-3c1a-4d2e-9f00-1a2b3c4d5e6f';
const _documentos = 'projects/demo/databases/(default)/documents';

const _naoExiste = RespostaFalsa(404, {
  'error': {'code': 404, 'status': 'NOT_FOUND'},
});
const _ok = RespostaFalsa(200, {});
const _negado = RespostaFalsa(403, {
  'error': {'code': 403, 'status': 'PERMISSION_DENIED'},
});

VersaoDaAnotacao _versao(
  String id,
  DateTime em, {
  String? substitui,
  bool lembrar = false,
  DateTime? visto,
  String texto = 'texto (teste)',
}) => VersaoDaAnotacao(
  id: id,
  pacienteId: _paciente,
  texto: texto,
  escritaEm: em,
  substitui: substitui,
  lembrarNaProxima: lembrar,
  lembreteVistoEm: visto,
);

FirestoreRest _firestore(AdaptadorFalso servidor) => FirestoreRest(
  Dio(
      BaseOptions(
        baseUrl: 'https://firestore.googleapis.com/v1/',
        contentType: Headers.jsonContentType,
      ),
    )
    ..httpClientAdapter = servidor
    ..interceptors.add(const ErrorInterceptor()),
  projeto: 'demo',
);

String _caminho(String id) =>
    'profissionais/$_uid/pacientes/$_paciente/anotacoes/$id';

/// Os campos de uma escrita feita, decodificados.
Map<String, Object?> _campos(Map<String, Object?> escrita) {
  final update = escrita['update'] as Map<String, Object?>;
  return {
    for (final MapEntry(:key, :value)
        in (update['fields'] as Map<String, Object?>).entries)
      key: decodificarValor(value),
  };
}

List<Map<String, Object?>> _escritas(AdaptadorFalso servidor) => [
  for (final pedido in servidor.feitas)
    if (pedido.opcoes.method == 'POST')
      (pedido.json['writes'] as List).single as Map<String, Object?>,
];

void main() {
  group('domínio', () {
    final dia1 = DateTime(2026, 10, 12, 9);
    final dia2 = DateTime(2026, 10, 13, 10);
    final dia3 = DateTime(2026, 10, 14, 11);

    test('editar é a mesma anotação, com a história em ordem', () {
      final anotacoes = montarAnotacoes([
        _versao('b', dia2, substitui: 'a', texto: 'segunda'),
        _versao('a', dia1, texto: 'primeira'),
        _versao('c', dia3, substitui: 'b', texto: 'terceira'),
      ]);

      final unica = anotacoes.single;
      expect(unica.texto, 'terceira');
      expect(unica.criadaEm, dia1);
      expect(unica.editadaEm, dia3);
      expect(
        [for (final v in unica.anteriores) v.texto],
        ['segunda', 'primeira'],
      );
    });

    test('da mais recente à mais antiga, pela data em que foi feita', () {
      final anotacoes = montarAnotacoes([
        _versao('a', dia1),
        _versao('b', dia3),
        _versao('c', dia2),
      ]);
      expect([for (final a in anotacoes) a.id], ['b', 'c', 'a']);
      expect(anotacoes.first.editadaEm, isNull);
    });

    test('duas edições da mesma versão: duas anotações, nada se perde', () {
      final anotacoes = montarAnotacoes([
        _versao('a', dia1),
        _versao('b', dia2, substitui: 'a'),
        _versao('c', dia3, substitui: 'a'),
      ]);
      expect({for (final a in anotacoes) a.id}, {'b', 'c'});
      for (final a in anotacoes) {
        expect(a.anteriores.single.id, 'a');
      }
    });

    test('a versão de antes que ainda não desceu encerra a história', () {
      final anotacoes = montarAnotacoes([_versao('b', dia2, substitui: 'x')]);
      expect(anotacoes.single.versoes.single.id, 'b');
    });

    test('o lembrete espera um dia seguinte e some quando visto', () {
      final hoje = DateTime(2026, 10, 12, 18);
      final pedido = Anotacao([_versao('a', dia1, lembrar: true)]);
      expect(pedido.lembretePendente(hoje), isFalse, reason: 'mesmo dia');
      expect(pedido.lembretePendente(DateTime(2026, 10, 13, 8)), isTrue);
      final visto = Anotacao([_versao('a', dia1, lembrar: true, visto: dia2)]);
      expect(visto.lembretePendente(dia3), isFalse);
      final semPedido = Anotacao([_versao('a', dia1)]);
      expect(semPedido.lembretePendente(dia3), isFalse);
    });

    test('quem vale é a versão vigente: editar pode tirar o lembrete', () {
      final anotacoes = montarAnotacoes([
        _versao('a', dia1, lembrar: true),
        _versao('b', dia1, substitui: 'a'),
      ]);
      expect(lembretesPendentes(anotacoes, dia3), isEmpty);
    });
  });

  group('banco local', () {
    late BancoLocal banco;
    late RepositorioAnotacoesLocal repositorio;
    setUp(() {
      banco = bancoEmMemoria();
      repositorio = RepositorioAnotacoesLocal(banco);
    });
    tearDown(() => banco.close());

    Future<VersaoDaAnotacao> escrever(
      DateTime em, {
      String? substitui,
      bool lembrar = false,
      String conta = _uid,
      String texto = 'texto (teste)',
    }) => repositorio.escrever(
      pacienteId: _paciente,
      profissionalId: conta,
      texto: texto,
      lembrarNaProxima: lembrar,
      agora: em,
      substitui: substitui,
    );

    test('escrever e editar: a versão de antes continua lá', () async {
      final primeira = await escrever(DateTime.utc(2026, 10, 12), texto: 'a');
      await escrever(
        DateTime.utc(2026, 10, 13),
        substitui: primeira.id,
        texto: 'b',
      );

      final anotacoes = await repositorio.doPaciente(_paciente);
      expect(anotacoes.single.texto, 'b');
      expect(anotacoes.single.anteriores.single.texto, 'a');
    });

    test('ver o lembrete marca uma vez, e o visto volta a subir', () async {
      final versao = await escrever(DateTime.utc(2026, 10, 12), lembrar: true);
      await repositorio.marcarSincronizada(versao, DateTime.utc(2026, 10, 12));
      expect(await repositorio.porSubir(_uid), isEmpty);

      await repositorio.marcarLembretesVistos([
        versao.id,
      ], DateTime.utc(2026, 10, 13));
      await repositorio.marcarLembretesVistos([
        versao.id,
      ], DateTime.utc(2026, 10, 20));

      final pendente = (await repositorio.porSubir(_uid)).single;
      expect(pendente.lembreteVistoEm, DateTime.utc(2026, 10, 13));
    });

    test('por subir: só da conta, da mais antiga à mais nova', () async {
      await escrever(DateTime.utc(2026, 10, 14), texto: 'nova');
      await escrever(DateTime.utc(2026, 10, 12), texto: 'antiga');
      await escrever(DateTime.utc(2026, 10, 13), conta: 'outra');

      final pendentes = await repositorio.porSubir(_uid);
      expect([for (final v in pendentes) v.texto], ['antiga', 'nova']);
    });

    test('o visto que mudou durante a subida continua por subir', () async {
      final versao = await escrever(DateTime.utc(2026, 10, 12), lembrar: true);
      await repositorio.marcarLembretesVistos([
        versao.id,
      ], DateTime.utc(2026, 10, 13));
      // A versão que subiu era a de antes do visto.
      await repositorio.marcarSincronizada(versao, DateTime.utc(2026, 10, 13));
      expect(await repositorio.porSubir(_uid), hasLength(1));
    });

    test('trazer: a que falta entra; a que existe só ganha o visto', () async {
      final local = await escrever(
        DateTime.utc(2026, 10, 12),
        lembrar: true,
        texto: 'daqui',
      );
      final agora = DateTime.utc(2026, 10, 15);

      final mudou = await repositorio.trazer(
        _versao(
          local.id,
          local.escritaEm,
          lembrar: true,
          visto: DateTime.utc(2026, 10, 14),
          texto: 'outro texto que não pode entrar',
        ),
        conta: _uid,
        agora: agora,
      );
      expect(mudou, isTrue);
      final daqui = (await repositorio.doPaciente(_paciente)).single;
      expect(daqui.texto, 'daqui');
      expect(daqui.vigente.lembreteVistoEm, DateTime.utc(2026, 10, 14));

      expect(
        await repositorio.trazer(
          _versao('de-outro-aparelho', DateTime.utc(2026, 10, 13)),
          conta: _uid,
          agora: agora,
        ),
        isTrue,
      );
      expect(await repositorio.doPaciente(_paciente), hasLength(2));
      // A que desceu já está igual dos dois lados.
      expect(
        (await repositorio.porSubir(_uid))
            .where((v) => v.id == 'de-outro-aparelho'),
        isEmpty,
      );
    });
  });

  group('subida', () {
    late BancoLocal banco;
    late RepositorioAnotacoesLocal repositorio;
    late List<String> pacientesGarantidos;
    setUp(() {
      banco = bancoEmMemoria();
      repositorio = RepositorioAnotacoesLocal(banco);
      pacientesGarantidos = [];
    });
    tearDown(() => banco.close());

    AnotacoesNoFirestore montar(
      AdaptadorFalso servidor, {
      Future<void> Function(String)? garantir,
    }) => AnotacoesNoFirestore(
      _firestore(servidor),
      repositorio,
      garantirPaciente: garantir ?? (id) async => pacientesGarantidos.add(id),
      uid: () => _uid,
      agora: () => DateTime.utc(2026, 10, 15),
    );

    test('cria no formato das regras, com o paciente antes', () async {
      final versao = await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'Retorno em 15 dias (teste).',
        lembrarNaProxima: true,
        agora: DateTime.utc(2026, 10, 12, 14),
      );
      final servidor = AdaptadorFalso([_naoExiste, _ok]);

      expect(await montar(servidor).sincronizar(), 1);

      expect(pacientesGarantidos, [_paciente]);
      final escrita = _escritas(servidor).single;
      expect(
        (escrita['update'] as Map)['name'],
        '$_documentos/${_caminho(versao.id)}',
      );
      expect(_campos(escrita), {
        'texto': 'Retorno em 15 dias (teste).',
        'escrita_em': DateTime.utc(2026, 10, 12, 14),
        'substitui': null,
        'lembrar_na_proxima': true,
        'lembrete_visto_em': null,
      });
      // A hora do servidor, e só criar: se já existir, recusa.
      expect(escrita['updateTransforms'], [
        {'fieldPath': 'registrada_em', 'setToServerValue': 'REQUEST_TIME'},
      ]);
      expect(escrita['currentDocument'], {'exists': false});
      expect(await repositorio.porSubir(_uid), isEmpty);
    });

    test('já está lá: só o lembrete visto sobe, e só ele', () async {
      final versao = await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'x',
        lembrarNaProxima: true,
        agora: DateTime.utc(2026, 10, 12),
      );
      await repositorio.marcarLembretesVistos([
        versao.id,
      ], DateTime.utc(2026, 10, 13));
      final remota = RespostaFalsa(200, {
        'name': '$_documentos/${_caminho(versao.id)}',
        'fields': codificar({
          'texto': 'x',
          'lembrar_na_proxima': true,
          'lembrete_visto_em': null,
        }),
      });
      final servidor = AdaptadorFalso([remota, _ok]);

      expect(await montar(servidor).sincronizar(), 1);

      final escrita = _escritas(servidor).single;
      expect(escrita['updateMask'], {
        'fieldPaths': ['lembrete_visto_em'],
      });
      expect(_campos(escrita), {
        'lembrete_visto_em': DateTime.utc(2026, 10, 13),
      });
    });

    test('a edição sobe depois da versão que ela substitui', () async {
      final a = await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'a',
        lembrarNaProxima: false,
        agora: DateTime.utc(2026, 10, 12),
      );
      await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'b',
        lembrarNaProxima: false,
        agora: DateTime.utc(2026, 10, 13),
        substitui: a.id,
      );
      final servidor = AdaptadorFalso([_naoExiste, _ok, _naoExiste, _ok]);

      expect(await montar(servidor).sincronizar(), 2);

      final textos = [for (final e in _escritas(servidor)) _campos(e)['texto']];
      expect(textos, ['a', 'b']);
      expect(_campos(_escritas(servidor).last)['substitui'], a.id);
    });

    test('recusada: fica por subir, e a seguinte do paciente espera', () async {
      await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'a',
        lembrarNaProxima: false,
        agora: DateTime.utc(2026, 10, 12),
      );
      await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'b',
        lembrarNaProxima: false,
        agora: DateTime.utc(2026, 10, 13),
      );
      final servidor = AdaptadorFalso([_naoExiste, _negado]);

      await expectLater(
        montar(servidor).sincronizar(),
        throwsA(isA<AppException>()),
      );
      expect(await repositorio.porSubir(_uid), hasLength(2));
      // Uma tentativa só: a segunda não foi.
      expect(servidor.feitas, hasLength(2));
    });

    test('o paciente que não sobe segura as anotações dele', () async {
      await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'a',
        lembrarNaProxima: false,
        agora: DateTime.utc(2026, 10, 12),
      );
      final servidor = AdaptadorFalso([]);

      await expectLater(
        montar(
          servidor,
          garantir: (_) async =>
              throw const FalhaDeValidacao(causa: 'sem nascimento'),
        ).sincronizar(),
        throwsA(isA<FalhaDeValidacao>()),
      );
      expect(servidor.feitas, isEmpty);
      expect(await repositorio.porSubir(_uid), hasLength(1));
    });
  });

  group('descida', () {
    test('desce o que falta e o visto de outro aparelho', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repositorio = RepositorioAnotacoesLocal(banco);
      final local = await repositorio.escrever(
        pacienteId: _paciente,
        profissionalId: _uid,
        texto: 'daqui',
        lembrarNaProxima: true,
        agora: DateTime.utc(2026, 10, 12),
      );
      Map<String, Object?> documento(String id, Map<String, Object?> c) => {
        'name': '$_documentos/${_caminho(id)}',
        'fields': codificar(c),
      };
      final servidor = AdaptadorFalso([
        RespostaFalsa(200, {
          'documents': [
            documento(local.id, {
              'texto': 'daqui',
              'escrita_em': DateTime.utc(2026, 10, 12),
              'substitui': null,
              'lembrar_na_proxima': true,
              'lembrete_visto_em': DateTime.utc(2026, 10, 13),
            }),
            documento('de-outro-aparelho', {
              'texto': 'de lá',
              'escrita_em': DateTime.utc(2026, 10, 11),
              'substitui': null,
              'lembrar_na_proxima': false,
              'lembrete_visto_em': null,
            }),
            // Fora do formato: não desce.
            documento('torta', {'texto': 42}),
          ],
        }),
      ]);

      final mudaram = await descerAnotacoes(
        _firestore(servidor),
        repositorio,
        conta: _uid,
        pacienteId: _paciente,
        agora: DateTime.utc(2026, 10, 15),
      );

      expect(mudaram, 2);
      final anotacoes = await repositorio.doPaciente(_paciente);
      expect({for (final a in anotacoes) a.texto}, {'daqui', 'de lá'});
      expect(
        anotacoes.firstWhere((a) => a.texto == 'daqui').vigente.lembreteVistoEm,
        DateTime.utc(2026, 10, 13),
      );
    });
  });

  test('migração: o banco da versão 7 ganha as anotações', () async {
    final verificador = SchemaVerifier(GeneratedHelper());
    final esquema = await verificador.schemaAt(7);
    final banco = BancoLocal(esquema.newConnection());
    addTearDown(banco.close);
    await verificador.migrateAndValidate(banco, banco.schemaVersion);

    await RepositorioAnotacoesLocal(banco).escrever(
      pacienteId: _paciente,
      profissionalId: _uid,
      texto: 'depois de atualizar (teste)',
      lembrarNaProxima: false,
      agora: DateTime.utc(2026, 10, 15),
    );
    expect(
      await RepositorioAnotacoesLocal(banco).doPaciente(_paciente),
      hasLength(1),
    );
  });
}
