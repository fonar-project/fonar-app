import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/core/network/conexao.dart';

/// Plugin controlável pelo teste.
class _ConectividadeFalsa implements Connectivity {
  _ConectividadeFalsa(this._inicial);

  final List<ConnectivityResult> _inicial;
  final _mudancas = StreamController<List<ConnectivityResult>>();

  void mudarPara(List<ConnectivityResult> resultado) =>
      _mudancas.add(resultado);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _inicial;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _mudancas.stream;
}

ProviderContainer _container(_ConectividadeFalsa plugin) {
  final container = ProviderContainer(
    overrides: [conectividadeProvider.overrideWithValue(plugin)],
  );
  addTearDown(container.dispose);
  // Sem um ouvinte o provider não é criado, e a stream nunca começa.
  container.listen(conexaoOnlineProvider, (_, _) {});
  return container;
}

void main() {
  group('temInterfaceDeRede', () {
    test('sem nenhuma interface é offline', () {
      expect(temInterfaceDeRede([ConnectivityResult.none]), isFalse);
      expect(temInterfaceDeRede([]), isFalse);
    });

    test('qualquer interface conta como online', () {
      for (final resultado in [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
        ConnectivityResult.other,
      ]) {
        expect(temInterfaceDeRede([resultado]), isTrue, reason: '$resultado');
      }
    });

    test('lista mista conta como online', () {
      // O aparelho pode ter Wi-Fi e dados móveis ao mesmo tempo, e o plugin
      // devolve os dois.
      expect(
        temInterfaceDeRede([ConnectivityResult.none, ConnectivityResult.wifi]),
        isTrue,
      );
    });
  });

  group('conexaoOnlineProvider', () {
    test('a leitura inicial do aparelho chega à interface', () async {
      // O ramo offline do login precisa existir no app rodando, não só nos
      // testes que sobrescrevem o provider. Um aparelho que ABRE o aplicativo
      // já sem rede nunca vê a stream de mudanças emitir nada.
      final container = _container(
        _ConectividadeFalsa([ConnectivityResult.none]),
      );

      // Otimista até a primeira leitura, para não piscar "Sem conexão".
      expect(container.read(conexaoOnlineProvider), isTrue);

      await container.read(interfaceDeRedeProvider.future);
      expect(container.read(conexaoOnlineProvider), isFalse);
    });

    test('acompanha a rede caindo e voltando', () async {
      final plugin = _ConectividadeFalsa([ConnectivityResult.wifi]);
      final container = _container(plugin);

      await container.read(interfaceDeRedeProvider.future);
      expect(container.read(conexaoOnlineProvider), isTrue);

      plugin.mudarPara([ConnectivityResult.none]);
      await pumpEventQueue();
      expect(container.read(conexaoOnlineProvider), isFalse);

      plugin.mudarPara([ConnectivityResult.mobile]);
      await pumpEventQueue();
      expect(container.read(conexaoOnlineProvider), isTrue);
    });

    test('continua sobrescrevível por valor, para os testes de tela', () {
      final container = ProviderContainer(
        overrides: [conexaoOnlineProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      // Sem plugin, sem canal de plataforma, sem stream falsa.
      expect(container.read(conexaoOnlineProvider), isFalse);
    });
  });
}
