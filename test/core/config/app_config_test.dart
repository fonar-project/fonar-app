import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/config/app_config.dart';

void main() {
  // Os testes rodam no modo de exemplo (`test/flutter_test_config.dart`);
  // aqui ele sai por um instante, para ver o que o app abre de verdade.
  void foraDoExemplo() {
    AppConfig.mudarModoDeExemplo(ligado: false);
    addTearDown(() => AppConfig.mudarModoDeExemplo(ligado: true));
  }

  test('os testes rodam no modo de exemplo, sem rede', () {
    expect(AppConfig.exemplo, isTrue);
    expect(AppConfig.firebaseApiKey, isEmpty);
    expect(AppConfig.apiConfigurada, isFalse);
    expect(AppConfig.baseUrl, 'http://localhost:8080');
  });

  test('sem --dart-define, o app abre no Firebase e na API de produção', () {
    foraDoExemplo();
    // Uma chave Web API do Google: "AIza" e mais 35 caracteres.
    expect(AppConfig.firebaseApiKey, matches(RegExp(r'^AIza[\w-]{35}$')));
    expect(AppConfig.apiConfigurada, isTrue);
    expect(
      AppConfig.baseUrl,
      'https://fonar-api-97444293253.southamerica-east1.run.app',
    );
    expect(AppConfig.firebaseProjectId, 'fonar-763db');
  });
}
