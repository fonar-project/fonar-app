import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

/// O espectrograma que vai no laudo: a imagem PRONTA do servidor, baixada
/// antes de emitir. O aplicativo não desenha espectrograma (ver a regra de
/// processamento de áudio no CLAUDE.md).
class EspectrogramaDoLaudo {
  const EspectrogramaDoLaudo({this.imagem, this.previsto = false});

  /// Sem espectrograma: a análise não tem, ou não há servidor (modo de
  /// exemplo).
  static const nenhum = EspectrogramaDoLaudo();

  /// O PNG, como a API mandou.
  final Uint8List? imagem;

  /// A análise tem espectrograma no servidor.
  final bool previsto;

  /// Devia vir e não veio: o documento diz que ficou de fora.
  bool get indisponivel => previsto && imagem == null;
}

/// O espectrograma da análise para o laudo, pelo [caminho] que o resultado
/// traz (`ResultadoDaAnalise.espectrogramaUrl`).
///
/// Nunca falha: sem rede ou com a API fora do ar, devolve "previsto, mas
/// indisponível", e o laudo sai dizendo isso — emitir não depende da
/// imagem. Com a API, vem pelo mesmo cliente das outras chamadas, que põe o
/// token.
final espectrogramaDoLaudoProvider = FutureProvider.autoDispose
    .family<EspectrogramaDoLaudo, String?>((ref, caminho) async {
      if (caminho == null || !AppConfig.apiConfigurada) {
        return EspectrogramaDoLaudo.nenhum;
      }
      final dio = ref.watch(dioProvider);
      try {
        final resposta = await dio.get<List<int>>(
          caminho,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = resposta.data;
        if (bytes == null || bytes.isEmpty) {
          return const EspectrogramaDoLaudo(previsto: true);
        }
        return EspectrogramaDoLaudo(
          imagem: Uint8List.fromList(bytes),
          previsto: true,
        );
      } catch (_) {
        return const EspectrogramaDoLaudo(previsto: true);
      }
    });
