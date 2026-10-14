import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'conexao.dart';

/// A última chamada a um servidor — a API, o Firestore, o login — chegou
/// lá? (US06)
///
/// A interface de rede é só pista ([conexaoOnlineProvider]): Wi-Fi atrás de
/// portal cativo aparece como conectado e não chega a lugar nenhum. Este
/// estado cruza a pista com o que as chamadas de verdade encontraram: `true`
/// quando a última tentativa não chegou ao servidor (conexão recusada, tempo
/// de conexão esgotado). Qualquer resposta, até um erro 4xx ou 5xx, é sinal
/// de que chegou.
///
/// A interface que volta zera a suspeita: a próxima chamada diz de novo.
class AlcanceDoServidor extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(conexaoOnlineProvider, (antes, online) {
      if (online && antes == false) state = false;
    });
    return false;
  }

  /// Uma resposta chegou.
  void chegou() {
    if (state) state = false;
  }

  /// A chamada não alcançou o servidor.
  void naoChegou() {
    if (!state) state = true;
  }
}

final servidorInalcancavelProvider = NotifierProvider<AlcanceDoServidor, bool>(
  AlcanceDoServidor.new,
);

/// Há interface de rede, mas o servidor não responde: o indicador diz
/// "Sem acesso ao servidor", e não "Online".
final semAcessoAoServidorProvider = Provider<bool>(
  (ref) =>
      ref.watch(conexaoOnlineProvider) &&
      ref.watch(servidorInalcancavelProvider),
);

/// Anota em [AlcanceDoServidor] o que cada chamada encontrou. Vai antes do
/// `ErrorInterceptor`, para ver o tipo da falha como o Dio a deu.
class AlcanceInterceptor extends Interceptor {
  AlcanceInterceptor(this._alcance);

  /// Lido na hora: o interceptor nasce com o cliente, e o estado vive à
  /// parte.
  final AlcanceDoServidor Function() _alcance;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _alcance().chegou();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionError ||
          DioExceptionType.connectionTimeout ||
          DioExceptionType.badCertificate:
        _alcance().naoChegou();
      case DioExceptionType.badResponse:
        _alcance().chegou();
      case DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.transformTimeout ||
          DioExceptionType.cancel ||
          DioExceptionType.unknown:
        // Chegou e demorou, ou foi interrompida aqui: não diz nada sobre o
        // caminho até o servidor.
        break;
    }
    handler.next(err);
  }
}
