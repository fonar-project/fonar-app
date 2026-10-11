import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/analise/data/imagem_do_servidor.dart';

import '../../apoio/http_falso.dart';

/// PNG de 1×1, no lugar do espectrograma que a API gera.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

const _caminho = '/v1/pacientes/p/sessoes/s/amostras/a/espectrograma';

Dio _dio(AdaptadorFalso servidor) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = servidor
      ..interceptors.add(const ErrorInterceptor());

/// Resolve a imagem como o widget `Image` faria, e devolve o resultado.
Future<ImageInfo> _carregar(ImageProvider imagem) {
  final pronta = Completer<ImageInfo>();
  imagem
      .resolve(ImageConfiguration.empty)
      .addListener(
        ImageStreamListener(
          pronta.complete,
          onError: (erro, pilha) => pronta.completeError(erro, pilha),
        ),
      );
  return pronta.future;
}

void main() {
  testWidgets('a imagem vem pelo cliente da API, no caminho da análise', (
    tester,
  ) async {
    final servidor = AdaptadorFalso([
      RespostaFalsa.bytes(200, _png, 'image/png'),
    ]);
    final info = await tester.runAsync(
      () => _carregar(ImagemDaApi(_caminho, _dio(servidor))),
    );
    expect(info!.image.width, 1);
    expect(servidor.feitas.single.uri.toString(), 'https://api.test$_caminho');
  });

  testWidgets('recusa da API é erro da imagem, não imagem vazia', (
    tester,
  ) async {
    final servidor = AdaptadorFalso([
      const RespostaFalsa(404, {
        'detail': {'codigo': 'audio_nao_encontrado', 'mensagem': 'x'},
      }),
    ]);
    final falha = await tester.runAsync(() async {
      try {
        await _carregar(ImagemDaApi(_caminho, _dio(servidor)));
        return null;
      } catch (erro) {
        return erro;
      }
    });
    expect(falha, isNotNull);
  });

  test('o mesmo caminho é a mesma imagem no cache', () {
    final dio = Dio();
    expect(ImagemDaApi(_caminho, dio), ImagemDaApi(_caminho, dio));
    expect(ImagemDaApi(_caminho, dio), isNot(ImagemDaApi('/outra', dio)));
  });
}
