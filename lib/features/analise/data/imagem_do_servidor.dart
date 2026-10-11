import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

/// De onde vem a imagem pronta que o servidor gerou — o espectrograma.
///
/// Só busca e mostra: o aplicativo não desenha espectrograma (ver a regra de
/// processamento de áudio no CLAUDE.md). Trocável nos testes, que não têm
/// rede.
///
/// Com a API configurada, a imagem é dado de paciente e a API exige o token:
/// ela vem pelo mesmo cliente das outras chamadas ([dioProvider]), que põe o
/// token e renova antes de vencer. Sem a API, é a imagem de exemplo, por URL
/// aberta.
final imagemDoServidorProvider = Provider<ImageProvider Function(String url)>((
  ref,
) {
  if (!AppConfig.apiConfigurada) return NetworkImage.new;
  final dio = ref.watch(dioProvider);
  return (caminho) => ImagemDaApi(caminho, dio);
});

/// Uma imagem da API, buscada com o token.
///
/// A mesma imagem (mesmo [caminho]) é a mesma chave no cache de imagens do
/// Flutter: abrir a tela de novo não baixa outra vez. A API ainda manda o
/// `ETag` e diz que a imagem não muda.
@immutable
class ImagemDaApi extends ImageProvider<ImagemDaApi> {
  const ImagemDaApi(this.caminho, this._dio);

  /// Relativo à base da API, ex.: `/v1/pacientes/.../espectrograma`.
  final String caminho;
  final Dio _dio;

  @override
  Future<ImagemDaApi> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<ImagemDaApi>(this);

  @override
  ImageStreamCompleter loadImage(
    ImagemDaApi key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _carregar(decode),
    scale: 1,
    debugLabel: caminho,
  );

  Future<ui.Codec> _carregar(ImageDecoderCallback decode) async {
    final resposta = await _dio.get<List<int>>(
      caminho,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = resposta.data;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('a API mandou uma imagem vazia');
    }
    return decode(
      await ui.ImmutableBuffer.fromUint8List(Uint8List.fromList(bytes)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ImagemDaApi && other.caminho == caminho;

  @override
  int get hashCode => caminho.hashCode;

  @override
  String toString() => 'ImagemDaApi($caminho)';
}
