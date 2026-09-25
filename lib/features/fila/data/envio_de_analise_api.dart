import 'dart:async';
import 'dart:io';

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
  const EnvioDeAnaliseApi(this._dio, {this.existe = _existeNoDisco});

  final Dio _dio;

  /// O arquivo está no disco? Parâmetro para o teste poder responder sem
  /// disco; em produção é sempre [_existeNoDisco].
  final Future<bool> Function(String caminho) existe;

  static Future<bool> _existeNoDisco(String caminho) => File(caminho).exists();

  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) async {
    // O Dio interrompe pelo CancelToken; o ErrorInterceptor traduz a
    // interrupção em `EnvioCancelado`.
    final interromper = CancelToken();
    unawaited(cancelamento?.quandoPedido.then((_) => interromper.cancel()));
    try {
      if (cancelamento?.pedido ?? false) throw const EnvioCancelado();
      // Conferido ANTES de montar o corpo. Sem isto, o arquivo que sumiu vira
      // uma exceção de sistema de arquivos, o tratamento genérico lá embaixo
      // a traduz em `FalhaDesconhecida`, e a fila reenvia a cada 30 minutos
      // para sempre um envio que nunca vai poder acontecer.
      for (final amostra in item.amostras) {
        if (!await existe(amostra.caminho)) {
          // O caminho vai só para o log — `causa` nunca é exibida.
          throw GravacaoNaoEncontrada(causa: amostra.caminho);
        }
      }
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
    } on FileSystemException catch (e) {
      // O arquivo sumiu ENTRE a conferência e a leitura, ou está ilegível. A
      // conclusão é a mesma da conferência: sem o WAV não há o que enviar, e
      // tentar de novo não o traz de volta.
      throw GravacaoNaoEncontrada(causa: e);
    } catch (e) {
      throw FalhaDesconhecida(causa: e);
    }
  }
}
