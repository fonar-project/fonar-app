import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/fonte_de_token.dart';
import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';

/// O Cloud Firestore pela API REST, com o token de quem está na sessão.
///
/// Pela REST, e não pelo `cloud_firestore`, pelo mesmo motivo da
/// autenticação (US32): o plugin declara o Windows "só para
/// desenvolvimento", e as duas plataformas têm as mesmas funcionalidades.
///
/// Quem decide o que pode ser gravado são as regras de segurança do projeto
/// (`firestore.rules`, no repositório da API): cada conta só toca
/// `profissionais/{seu uid}/...`, e paciente, consentimento e sessão são
/// validados campo a campo. Os campos que levam a hora do servidor
/// (`criado_em`, `registrado_em`) vão como transformação `REQUEST_TIME`,
/// como o SDK faz com `serverTimestamp()` — hora do aparelho é recusada.
///
/// Só o que a sincronização usa: ler, listar, criar e alterar.
class FirestoreRest {
  FirestoreRest(this._dio, {required String projeto})
    : _documentos = 'projects/$projeto/databases/(default)/documents';

  final Dio _dio;

  /// O prefixo do nome de todo documento do projeto.
  final String _documentos;

  /// Os campos do documento em [caminho], ou `null` se ele não existe.
  ///
  /// Lança só `AppException`.
  Future<Map<String, Object?>?> ler(String caminho) async {
    try {
      final resposta = await _dio.get<Object?>('$_documentos/$caminho');
      return _campos(resposta.data);
    } on DioException catch (e) {
      final falha = _falha(e);
      if (falha is NaoEncontrado) return null;
      throw falha;
    }
  }

  /// Os documentos da coleção em [caminho], cada um com os campos e o id.
  ///
  /// Lança só `AppException`.
  Future<List<({String id, Map<String, Object?> campos})>> listar(
    String caminho,
  ) async {
    final documentos = <({String id, Map<String, Object?> campos})>[];
    String? pagina;
    do {
      final Response<Object?> resposta;
      try {
        resposta = await _dio.get<Object?>(
          '$_documentos/$caminho',
          queryParameters: {'pageSize': 300, 'pageToken': ?pagina},
        );
      } on DioException catch (e) {
        throw _falha(e);
      }
      final corpo = resposta.data;
      if (corpo is! Map) break;
      for (final documento in (corpo['documents'] as List?) ?? const []) {
        final nome = (documento as Map)['name'] as String;
        documentos.add((
          id: nome.split('/').last,
          campos: _campos(documento) ?? const {},
        ));
      }
      final proxima = corpo['nextPageToken'];
      pagina = proxima is String && proxima.isNotEmpty ? proxima : null;
    } while (pagina != null);
    return documentos;
  }

  /// Cria o documento em [caminho]. Falha se ele já existir.
  ///
  /// [horaDoServidor]: campos preenchidos com a hora do servidor.
  Future<void> criar(
    String caminho,
    Map<String, Object?> campos, {
    List<String> horaDoServidor = const [],
  }) => _gravar({
    'update': {'name': '$_documentos/$caminho', 'fields': codificar(campos)},
    'currentDocument': {'exists': false},
    'updateTransforms': [
      for (final campo in horaDoServidor)
        {'fieldPath': campo, 'setToServerValue': 'REQUEST_TIME'},
    ],
  });

  /// Troca, no documento que tem de existir em [caminho], os campos de
  /// [mascara] pelos de [campos]. Campo da máscara ausente de [campos] é
  /// apagado do documento; campo fora da máscara fica como está.
  Future<void> atualizar(
    String caminho,
    Map<String, Object?> campos, {
    required List<String> mascara,
  }) => _gravar({
    'update': {'name': '$_documentos/$caminho', 'fields': codificar(campos)},
    'updateMask': {'fieldPaths': mascara},
    'currentDocument': {'exists': true},
  });

  Future<void> _gravar(Map<String, Object?> escrita) async {
    try {
      await _dio.post<Object?>(
        '$_documentos:commit',
        data: {
          'writes': [escrita],
        },
      );
    } on DioException catch (e) {
      throw _falha(e);
    }
  }

  static AppException _falha(DioException e) {
    final falha = e.error;
    return falha is AppException ? falha : FalhaDesconhecida(causa: e);
  }

  static Map<String, Object?>? _campos(Object? documento) {
    if (documento is! Map) return null;
    final campos = documento['fields'];
    if (campos is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in campos.entries)
        key as String: decodificarValor(value),
    };
  }
}

/// [campos] no formato de valor da API REST do Firestore.
Map<String, Object?> codificar(Map<String, Object?> campos) => {
  for (final MapEntry(:key, :value) in campos.entries)
    key: codificarValor(value),
};

/// Um valor do Dart no formato da API REST do Firestore.
///
/// Data e hora vão em UTC: o Firestore não guarda fuso, e o domínio da API
/// lê tudo como UTC.
Map<String, Object?> codificarValor(Object? valor) => switch (valor) {
  null => {'nullValue': null},
  final bool b => {'booleanValue': b},
  final int i => {'integerValue': '$i'},
  final double d => {'doubleValue': d},
  final String s => {'stringValue': s},
  final DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
  final Map<String, Object?> m => {
    'mapValue': {'fields': codificar(m)},
  },
  final List<Object?> l => {
    'arrayValue': {'values': [for (final v in l) codificarValor(v)]},
  },
  _ => throw ArgumentError.value(valor, 'valor', 'tipo sem formato no Firestore'),
};

/// O valor da API REST do Firestore como valor do Dart.
Object? decodificarValor(Object? valor) {
  if (valor is! Map) return null;
  if (valor.containsKey('stringValue')) return valor['stringValue'];
  if (valor.containsKey('integerValue')) {
    return int.parse('${valor['integerValue']}');
  }
  if (valor.containsKey('doubleValue')) {
    return (valor['doubleValue'] as num).toDouble();
  }
  if (valor.containsKey('booleanValue')) return valor['booleanValue'];
  if (valor.containsKey('timestampValue')) {
    return DateTime.parse(valor['timestampValue'] as String);
  }
  if (valor.containsKey('mapValue')) {
    final campos = (valor['mapValue'] as Map)['fields'];
    return {
      if (campos is Map)
        for (final MapEntry(:key, :value) in campos.entries)
          key as String: decodificarValor(value),
    };
  }
  if (valor.containsKey('arrayValue')) {
    final valores = (valor['arrayValue'] as Map)['values'];
    return [
      if (valores is List)
        for (final v in valores) decodificarValor(v),
    ];
  }
  return null;
}

/// O cliente do Firestore do app, com o mesmo token da API de análise.
final firestoreRestProvider = Provider<FirestoreRest>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://firestore.googleapis.com/v1/',
      connectTimeout: AppConfig.timeoutConexao,
      receiveTimeout: AppConfig.timeoutRecebimento,
      sendTimeout: AppConfig.timeoutConexao,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  // A mesma ordem do `dioProvider`: o token entra antes de a requisição
  // sair, e o erro é traduzido por último.
  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(fonteDeTokenProvider)),
    const ErrorInterceptor(),
  ]);
  ref.onDispose(dio.close);
  return FirestoreRest(dio, projeto: AppConfig.firebaseProjectId);
});
