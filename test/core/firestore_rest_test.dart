import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/firestore/firestore_rest.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';

import '../apoio/http_falso.dart';

const _documentos = 'projects/demo/databases/(default)/documents';

/// O cliente como o app monta, com o servidor de mentira.
FirestoreRest _cliente(AdaptadorFalso adaptador) {
  final dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://firestore.googleapis.com/v1/',
            contentType: Headers.jsonContentType,
          ),
        )
        ..httpClientAdapter = adaptador
        ..interceptors.add(const ErrorInterceptor());
  return FirestoreRest(dio, projeto: 'demo');
}

void main() {
  group('valores', () {
    test('cada tipo no formato da API REST', () {
      expect(codificar({'n': 3, 'x': 1.5, 's': 'a', 'b': true, 'z': null}), {
        'n': {'integerValue': '3'},
        'x': {'doubleValue': 1.5},
        's': {'stringValue': 'a'},
        'b': {'booleanValue': true},
        'z': {'nullValue': null},
      });
    });

    test('data e hora vão em UTC', () {
      final local = DateTime.utc(2026, 10, 11, 12).toLocal();
      expect(codificarValor(local), {
        'timestampValue': '2026-10-11T12:00:00.000Z',
      });
    });

    test('ida e volta', () {
      final valores = <String, Object?>{
        'n': 7,
        's': 'texto',
        't': DateTime.utc(1990, 6, 15),
        'm': {'a': 1},
        'l': ['x', 2],
      };
      final volta = {
        for (final MapEntry(:key, :value) in codificar(valores).entries)
          key: decodificarValor(value),
      };
      expect(volta, valores);
    });
  });

  group('ler', () {
    test('devolve os campos do documento', () async {
      final servidor = AdaptadorFalso([
        const RespostaFalsa(200, {
          'name': '$_documentos/a/b',
          'fields': {
            'nome': {'stringValue': 'Ana'},
          },
        }),
      ]);
      expect(await _cliente(servidor).ler('a/b'), {'nome': 'Ana'});
      expect(
        servidor.feitas.single.uri.toString(),
        'https://firestore.googleapis.com/v1/$_documentos/a/b',
      );
    });

    test('documento que não existe é null, não erro', () async {
      final servidor = AdaptadorFalso([
        const RespostaFalsa(404, {
          'error': {'code': 404, 'status': 'NOT_FOUND'},
        }),
      ]);
      expect(await _cliente(servidor).ler('a/b'), isNull);
    });

    test('acesso negado pelas regras é Proibido', () async {
      final servidor = AdaptadorFalso([
        const RespostaFalsa(403, {
          'error': {'code': 403, 'status': 'PERMISSION_DENIED'},
        }),
      ]);
      await expectLater(
        _cliente(servidor).ler('a/b'),
        throwsA(isA<Proibido>()),
      );
    });
  });

  test('listar segue as páginas', () async {
    final servidor = AdaptadorFalso([
      const RespostaFalsa(200, {
        'documents': [
          {
            'name': '$_documentos/c/1',
            'fields': {
              'seq': {'integerValue': '1'},
            },
          },
        ],
        'nextPageToken': 'p2',
      }),
      const RespostaFalsa(200, {
        'documents': [
          {
            'name': '$_documentos/c/2',
            'fields': {
              'seq': {'integerValue': '2'},
            },
          },
        ],
      }),
    ]);
    final documentos = await _cliente(servidor).listar('c');
    expect([for (final d in documentos) d.id], ['1', '2']);
    expect([for (final d in documentos) d.campos['seq']], [1, 2]);
    expect(servidor.feitas[1].uri.queryParameters['pageToken'], 'p2');
  });

  test('coleção vazia não tem "documents"', () async {
    final servidor = AdaptadorFalso([const RespostaFalsa(200, {})]);
    expect(await _cliente(servidor).listar('c'), isEmpty);
  });

  test('criar exige que não exista e põe a hora do servidor', () async {
    final servidor = AdaptadorFalso([const RespostaFalsa(200, {})]);
    await _cliente(servidor)
        .criar('a/b', {'nome': 'Ana'}, horaDoServidor: ['criado_em']);
    final pedido = servidor.feitas.single;
    expect(pedido.opcoes.method, 'POST');
    expect(pedido.uri.path, '/v1/$_documentos:commit');
    expect(pedido.json['writes'], [
      {
        'update': {
          'name': '$_documentos/a/b',
          'fields': {
            'nome': {'stringValue': 'Ana'},
          },
        },
        'currentDocument': {'exists': false},
        'updateTransforms': [
          {'fieldPath': 'criado_em', 'setToServerValue': 'REQUEST_TIME'},
        ],
      },
    ]);
  });

  test('atualizar troca só os campos da máscara', () async {
    final servidor = AdaptadorFalso([const RespostaFalsa(200, {})]);
    await _cliente(
      servidor,
    ).atualizar('a/b', {'nome': 'Ana'}, mascara: ['nome', 'queixa_principal']);
    expect(servidor.feitas.single.json['writes'], [
      {
        'update': {
          'name': '$_documentos/a/b',
          'fields': {
            'nome': {'stringValue': 'Ana'},
          },
        },
        'updateMask': {
          'fieldPaths': ['nome', 'queixa_principal'],
        },
        'currentDocument': {'exists': true},
      },
    ]);
  });
}
