import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../captura/domain/amostra.dart';
import '../../sincronizacao/data/sincronizacao_firestore.dart';
import '../../sincronizacao/domain/sincronizacao.dart';
import '../domain/item_da_fila.dart';
import '../domain/repositorio_fila.dart';

final envioDeAnaliseProvider = Provider<EnvioDeAnalise>(
  (ref) => EnvioDeAnaliseApi(
    ref.watch(dioProvider),
    ref.watch(sincronizacaoProvider),
  ),
);

/// Envia a sessão para a API de análise (repositório `fonar-api`).
///
/// O contrato está na ADR-014 da API:
///
/// 1. Antes do primeiro WAV, o paciente, o livro de consentimentos e a
///    sessão sobem para o Firebase ([Sincronizacao]). A API confere o
///    consentimento lá, e não aqui.
/// 2. Cada gravação da sessão vai numa requisição própria,
///    `POST /v1/pacientes/{p}/sessoes/{s}/amostras` (multipart), com o id da
///    amostra (`amostra_id`). É ele que torna o reenvio seguro: a mesma
///    gravação com o mesmo id devolve o que já existe, sem análise em dobro.
///    A resposta de um envio que deu certo se perde com frequência em rede de
///    consultório, e a fila tenta de novo.
/// 3. A análise é a SESSÃO: o id da análise devolvido para a fila é o id da
///    sessão, lido depois em `GET /v1/pacientes/{p}/sessoes/{s}/analise`.
///
/// Taxa de amostragem e canais vão declarados, como a conferência do
/// aparelho os leu no cabeçalho: a API confere de novo, e divergência é
/// recusa (`captura_divergente`).
class EnvioDeAnaliseApi implements EnvioDeAnalise {
  const EnvioDeAnaliseApi(
    this._dio,
    this._sincronizacao, {
    this.existe = _existeNoDisco,
    this.plataforma = _plataformaDoAparelho,
  });

  final Dio _dio;
  final Sincronizacao _sincronizacao;

  /// O arquivo está no disco? Parâmetro para o teste poder responder sem
  /// disco; em produção é sempre [_existeNoDisco].
  final Future<bool> Function(String caminho) existe;

  /// Sistema e versão do aparelho, que vão com cada gravação como metadado
  /// de captura. Parâmetro para o teste; em produção, [_plataformaDoAparelho].
  ///
  /// Não decide nada de layout nem de funcionalidade — só descreve de onde
  /// veio a gravação, para a análise clínica poder separar por aparelho.
  final ({String sistema, String versao}) Function() plataforma;

  static Future<bool> _existeNoDisco(String caminho) => File(caminho).exists();

  static ({String sistema, String versao}) _plataformaDoAparelho() => (
    sistema: Platform.operatingSystem,
    versao: Platform.operatingSystemVersion,
  );

  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) async {
    // O Dio interrompe pelo CancelToken; o ErrorInterceptor traduz a
    // interrupção em `EnvioCancelado`.
    final interromper = CancelToken();
    unawaited(cancelamento?.quandoPedido.then((_) => interromper.cancel()));
    void conferirCancelamento() {
      if (cancelamento?.pedido ?? false) throw const EnvioCancelado();
    }

    try {
      conferirCancelamento();
      // Conferido ANTES de tudo. Sem isto, o arquivo que sumiu vira uma
      // exceção de sistema de arquivos, o tratamento genérico lá embaixo a
      // traduz em `FalhaDesconhecida`, e a fila reenvia a cada 30 minutos
      // para sempre um envio que nunca vai poder acontecer.
      for (final amostra in item.amostras) {
        if (!await existe(amostra.caminho)) {
          // O caminho vai só para o log — `causa` nunca é exibida.
          throw GravacaoNaoEncontrada(causa: amostra.caminho);
        }
      }
      await _sincronizacao.prepararEnvio(item);
      for (final amostra in item.amostras) {
        conferirCancelamento();
        await _enviarAmostra(item, amostra, interromper);
      }
      return item.sessaoId;
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

  Future<void> _enviarAmostra(
    ItemDaFila item,
    Amostra amostra,
    CancelToken interromper,
  ) async {
    final aparelho = plataforma();
    final corpo = FormData.fromMap({
      'arquivo': await MultipartFile.fromFile(
        amostra.caminho,
        filename: '${amostra.id}.wav',
        contentType: DioMediaType('audio', 'wav'),
      ),
      'amostra_id': amostra.id,
      'tipo_tarefa': tipoDaTarefa(amostra.tarefa),
      'plataforma': aparelho.sistema,
      'dispositivo': _ate(aparelho.versao, 200),
      'taxa_amostragem_hz': '${amostra.taxaDeAmostragem}',
      'canais': '${amostra.canais}',
    });
    await _dio.post<Object?>(
      '/v1/pacientes/${item.pacienteId}/sessoes/${item.sessaoId}/amostras',
      data: corpo,
      cancelToken: interromper,
    );
  }

  static String _ate(String texto, int limite) =>
      texto.length <= limite ? texto : texto.substring(0, limite);
}

/// O nome da tarefa na API.
String tipoDaTarefa(TarefaDeGravacao tarefa) => switch (tarefa) {
  TarefaDeGravacao.vogalSustentada => 'vogal_sustentada',
  TarefaDeGravacao.falaEncadeada => 'fala_encadeada',
};
