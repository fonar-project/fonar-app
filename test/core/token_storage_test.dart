import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/features/conta/presentation/conta_controlador.dart';
import 'package:fonar_app/l10n/app_strings.dart';

/// Cofre que falha na operação pedida, e anota o que tentaram apagar.
class _CofreQuebrado extends FlutterSecureStorage {
  _CofreQuebrado({
    this.lendo = false,
    this.gravando = false,
    this.apagando = false,
  });

  final bool lendo;
  final bool gravando;
  final bool apagando;
  final apagadas = <String>[];

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (lendo) throw Exception('Failed to unwrap key');
    return null;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (gravando) throw Exception('cofre indisponível');
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    apagadas.add(key);
    if (apagando) throw Exception('cofre indisponível');
  }
}

void main() {
  group('TokenStorageSeguro', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('guarda no cofre, lê de volta e apaga', () async {
      const tokens = TokenStorageSeguro(FlutterSecureStorage());
      expect(await tokens.lerToken(), isNull);

      await tokens.salvarToken('token-de-teste');
      expect(await tokens.lerToken(), 'token-de-teste');
      // Na chave do FONAR, e não solto.
      expect(
        await const FlutterSecureStorage().read(key: TokenStorageSeguro.chave),
        'token-de-teste',
      );

      await tokens.limpar();
      expect(await tokens.lerToken(), isNull);
    });

    test('token ilegível: some, e fica como não guardado', () async {
      // O caso do aparelho restaurado de outro: a chave do Keystore não veio
      // junto, e o valor não decifra.
      final cofre = _CofreQuebrado(lendo: true);

      expect(await TokenStorageSeguro(cofre).lerToken(), isNull);
      expect(cofre.apagadas, [TokenStorageSeguro.chave]);
    });

    test('ilegível e impossível de apagar: ainda assim não trava', () async {
      final cofre = _CofreQuebrado(lendo: true, apagando: true);

      expect(await TokenStorageSeguro(cofre).lerToken(), isNull);
    });

    test('não conseguir guardar é dito, e não fingido', () async {
      await expectLater(
        TokenStorageSeguro(_CofreQuebrado(gravando: true)).salvarToken('t'),
        throwsA(isA<FalhaDesconhecida>()),
      );
    });

    test('não conseguir apagar ao sair é dito, e não fingido', () async {
      await expectLater(
        TokenStorageSeguro(_CofreQuebrado(apagando: true)).limpar(),
        throwsA(isA<FalhaDesconhecida>()),
      );
    });
  });

  test(
    'sair da conta com o token preso no cofre: diz, e não finge que saiu',
    () async {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(
            TokenStorageSeguro(_CofreQuebrado(apagando: true)),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(contaControladorProvider, (_, _) {});

      final saiu = await container
          .read(contaControladorProvider.notifier)
          .sair();

      expect(saiu, isFalse);
      expect(
        container.read(contaControladorProvider).erroGeral,
        AppStrings.erroDesconhecido,
      );
    },
  );

  group('backup automático do Android', () {
    // Guarda contra quem "limpar" o manifesto: o padrão do Android sobe o
    // banco local e os WAV para o Google Drive, e o token restaurado não
    // decifra. Ver o comentário no próprio AndroidManifest.xml.
    final manifesto = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    test('fica desligado até o Android 11', () {
      expect(manifesto, contains('android:allowBackup="false"'));
    });

    test('e do 12 em diante, na nuvem e na troca de aparelho', () {
      expect(
        manifesto,
        contains('android:dataExtractionRules="@xml/regras_de_extracao"'),
      );
      final regras = File('android/app/src/main/res/xml/regras_de_extracao.xml')
          .readAsStringSync();
      for (final secao in ['cloud-backup', 'device-transfer']) {
        final inicio = regras.indexOf('<$secao>');
        final fim = regras.indexOf('</$secao>');
        expect(inicio, isNonNegative, reason: secao);
        final trecho = regras.substring(inicio, fim);
        for (final dominio in ['root', 'file', 'database', 'sharedpref']) {
          expect(
            trecho,
            contains('<exclude domain="$dominio" path="." />'),
            reason: '$secao sem excluir $dominio',
          );
        }
      }
    });
  });
}
