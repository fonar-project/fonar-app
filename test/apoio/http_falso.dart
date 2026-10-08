// Um servidor HTTP de mentira para o Dio: nada sai da máquina.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Uma resposta programada: status e corpo JSON — ou, com [semRede], a
/// conexão que nem chega a abrir.
class RespostaFalsa {
  const RespostaFalsa(this.status, [this.corpo = const {}]) : semRede = false;
  const RespostaFalsa.semRede() : status = 0, corpo = const {}, semRede = true;

  final int status;
  final Object corpo;
  final bool semRede;
}

/// Uma requisição como chegou: método, endereço, cabeçalhos e corpo em texto.
class RequisicaoFeita {
  RequisicaoFeita(this.opcoes, this.corpo);

  final RequestOptions opcoes;
  final String corpo;

  Uri get uri => opcoes.uri;
  Map<String, dynamic> get cabecalhos => opcoes.headers;
  Map<String, Object?> get json => jsonDecode(corpo) as Map<String, Object?>;
  Map<String, String> get formulario => Uri.splitQueryString(corpo);
}

/// Responde, em ordem, o que [respostas] mandar — e anota cada pedido.
class AdaptadorFalso implements HttpClientAdapter {
  AdaptadorFalso(this.respostas);

  final List<RespostaFalsa> respostas;
  final feitas = <RequisicaoFeita>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final parte in requestStream) {
        bytes.addAll(parte);
      }
    }
    feitas.add(RequisicaoFeita(options, utf8.decode(bytes)));
    if (respostas.isEmpty) {
      throw StateError('requisição sem resposta programada');
    }
    final resposta = respostas.removeAt(0);
    if (resposta.semRede) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'sem rede (teste)',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(resposta.corpo),
      resposta.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// O erro do Firebase no formato da API REST.
RespostaFalsa erroDoFirebase(String codigo, {int status = 400}) =>
    RespostaFalsa(status, {
      'error': {'code': status, 'message': codigo},
    });
