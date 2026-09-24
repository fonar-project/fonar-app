import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/item_da_fila.dart';
import '../domain/repositorio_fila.dart';

final envioDeAnaliseProvider = Provider<EnvioDeAnalise>(
  (ref) => EnvioDeAnaliseApi(ref.watch(dioProvider)),
);

/// Envia a sessão para a API de análise.
///
/// TODO(backend): CONTRATO SUPOSTO. A API de análise ainda não publicou a
/// rota de envio; o que está aqui é o formato mais simples que serve, para
/// ser acertado com quem mantém a API:
///
/// - `POST /analises`, `multipart/form-data`;
/// - campos `paciente_id` e `sessao_id`;
/// - um arquivo por tarefa, no campo com o nome da tarefa
///   (`vogalSustentada`, `falaEncadeada`);
/// - cabeçalho `Idempotency-Key` com o id do item da fila;
/// - resposta `{"id": "<id da análise>"}`.
///
/// A idempotência não é opcional: em rede de consultório, a resposta de um
/// envio que deu certo se perde com frequência, e a fila tenta de novo. Sem
/// a chave, cada nova tentativa criaria uma análise a mais do mesmo áudio.
class EnvioDeAnaliseApi implements EnvioDeAnalise {
  const EnvioDeAnaliseApi(this._dio);

  final Dio _dio;

  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) async {
    // O Dio interrompe pelo CancelToken; o ErrorInterceptor traduz a
    // interrupção em `EnvioCancelado`.
    final interromper = CancelToken();
    unawaited(cancelamento?.quandoPedido.then((_) => interromper.cancel()));
    try {
      if (cancelamento?.pedido ?? false) throw const EnvioCancelado();
      final corpo = FormData.fromMap({
        'paciente_id': item.pacienteId,
        'sessao_id': item.sessaoId,
        for (final amostra in item.amostras)
          amostra.tarefa.name: await MultipartFile.fromFile(
            amostra.caminho,
            filename: '${amostra.tarefa.name}.wav',
            contentType: DioMediaType('audio', 'wav'),
          ),
      });
      final resposta = await _dio.post<Map<String, dynamic>>(
        '/analises',
        data: corpo,
        options: Options(headers: {'Idempotency-Key': item.id}),
        cancelToken: interromper,
      );
      final id = resposta.data?['id'];
      if (id is! String || id.isEmpty) {
        throw const FalhaDesconhecida(causa: 'resposta sem id de análise');
      }
      return id;
    } on DioException catch (e) {
      // O ErrorInterceptor já traduziu o erro; o que sobe daqui é só
      // AppException, como o contrato pede.
      final falha = e.error;
      throw falha is AppException ? falha : FalhaDesconhecida(causa: e);
    } on AppException {
      rethrow;
    } catch (e) {
      // Arquivo apagado ou ilegível no disco, por exemplo.
      throw FalhaDesconhecida(causa: e);
    }
  }
}
