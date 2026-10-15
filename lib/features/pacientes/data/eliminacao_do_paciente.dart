import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../captura/data/gravador_record.dart';
import '../../captura/domain/gravador.dart';

final eliminacaoDoPacienteProvider = Provider<EliminacaoDoPaciente>(
  (ref) => EliminacaoDoPaciente(
    ref.watch(bancoLocalProvider),
    ref.watch(arquivosDeAmostraProvider),
    dio: AppConfig.apiConfigurada ? ref.watch(dioProvider) : null,
  ),
);

/// Elimina um paciente e tudo o que decorre dele (US43) — o direito de
/// eliminação da LGPD (art. 18, VI), a pedido do paciente.
///
/// Primeiro no servidor, pela API (`DELETE /v1/pacientes/{p}`, que apaga a
/// árvore dele no Firestore e os áudios no Storage, e guarda a comprovação
/// sem nome nem id); depois aqui: cadastro, consentimentos e retiradas,
/// gravações (o registro e o WAV), envios da fila, CAPE-V, laudos e
/// anotações.
///
/// Nessa ordem porque o servidor é o que não se alcança depois: se apagar
/// aqui falhar no meio, repetir termina o serviço (o servidor responde que o
/// paciente já não existe). Ao contrário, o paciente sumiria do aparelho e
/// continuaria no servidor, sem ninguém para pedir de novo.
///
/// Irreversível. Quem pergunta antes é a tela.
class EliminacaoDoPaciente {
  EliminacaoDoPaciente(this._banco, this._arquivos, {this._dio});

  final BancoLocal _banco;
  final ArquivosDeAmostra _arquivos;

  /// A API, ou `null` no modo de exemplo — sem servidor, só o aparelho.
  final Dio? _dio;

  /// Lança só `AppException`.
  Future<void> eliminar(String pacienteId) async {
    if (_dio case final dio?) {
      try {
        await dio.delete<Object?>('/v1/pacientes/$pacienteId');
      } on DioException catch (e) {
        final falha = e.error;
        // Paciente que nunca subiu, ou já eliminado: lá não há o que apagar.
        if (falha is! NaoEncontrado) {
          throw falha is AppException ? falha : FalhaDesconhecida(causa: e);
        }
      }
    }
    try {
      final caminhos = await _eliminarDoBanco(pacienteId);
      for (final caminho in caminhos) {
        try {
          await _arquivos.apagar(caminho);
        } catch (_) {
          // Sem registro, o arquivo que sobrar sai na limpeza da abertura
          // (`apagarWavsSemRegistro`).
        }
      }
    } catch (erro) {
      throw FalhaDesconhecida(causa: erro);
    }
  }

  /// Apaga as linhas do paciente e devolve os caminhos dos WAV dele.
  Future<List<String>> _eliminarDoBanco(String pacienteId) =>
      _banco.transaction(() async {
        final amostras = await (_banco.select(
          _banco.amostras,
        )..where((a) => a.pacienteId.equals(pacienteId))).get();
        // Na ordem das chaves estrangeiras: o envio leva os vínculos com as
        // amostras; a retirada sai antes do consentimento que ela retira; a
        // avaliação CAPE-V leva as notas.
        await (_banco.delete(
          _banco.envios,
        )..where((e) => e.pacienteId.equals(pacienteId))).go();
        await (_banco.delete(
          _banco.amostras,
        )..where((a) => a.pacienteId.equals(pacienteId))).go();
        await (_banco.delete(
          _banco.avaliacoesCapeV,
        )..where((a) => a.pacienteId.equals(pacienteId))).go();
        await (_banco.delete(
          _banco.laudos,
        )..where((l) => l.pacienteId.equals(pacienteId))).go();
        // As anotações, todas as versões (US51): prontuário, que só sai aqui.
        await (_banco.delete(
          _banco.anotacoesDoPaciente,
        )..where((a) => a.pacienteId.equals(pacienteId))).go();
        await (_banco.delete(
          _banco.retiradasDeConsentimento,
        )..where((r) => r.pacienteId.equals(pacienteId))).go();
        await (_banco.delete(
          _banco.consentimentos,
        )..where((c) => c.pacienteId.equals(pacienteId))).go();
        await (_banco.delete(
          _banco.pacientes,
        )..where((p) => p.id.equals(pacienteId))).go();
        return [for (final a in amostras) a.caminho];
      });
}
