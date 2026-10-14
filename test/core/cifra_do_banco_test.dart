import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/banco/chave_do_banco.dart';
import 'package:fonar_app/core/banco/cifra_do_banco.dart';
import 'package:sqlite3/sqlite3.dart';

const _chave =
    '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

void main() {
  // US44: o banco local cifrado no aparelho, pelo SQLite3 Multiple Ciphers
  // que o hook do `sqlite3` traz (`hooks` no pubspec). Estes testes rodam
  // com a mesma biblioteca: se o hook voltasse ao SQLite comum, o `rekey`
  // seria ignorado em silêncio — e o "ficou cifrado" abaixo reprova.
  late Directory pasta;
  late String caminho;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('fonar-cifra-');
    addTearDown(() => pasta.deleteSync(recursive: true));
    caminho = '${pasta.path}/fonar.sqlite';
  });

  void criarBancoSemCifra() {
    final banco = sqlite3.open(caminho);
    banco
      ..execute('CREATE TABLE t (x TEXT)')
      ..execute("INSERT INTO t VALUES ('voz de paciente')")
      ..close();
  }

  group('cifrarBancoDeAntes', () {
    test('o banco de antes fica cifrado, e abre só com a chave', () async {
      criarBancoSemCifra();
      expect(
        await estadoDoArquivoDoBanco(caminho),
        EstadoDoArquivoDoBanco.semCifra,
      );

      await cifrarBancoDeAntes(caminho, _chave);

      expect(
        await estadoDoArquivoDoBanco(caminho),
        EstadoDoArquivoDoBanco.cifrado,
      );
      // O conteúdo não aparece no arquivo.
      final bytes = File(caminho).readAsBytesSync();
      expect(String.fromCharCodes(bytes).contains('voz de paciente'), isFalse);

      final comChave = sqlite3.open(caminho)..execute("PRAGMA key = '$_chave'");
      expect(comChave.select('SELECT x FROM t').single['x'], 'voz de paciente');
      comChave.close();

      final semChave = sqlite3.open(caminho);
      expect(() => semChave.select('SELECT x FROM t'), throwsA(anything));
      semChave.close();
    });

    test('banco que não existe, ou já cifrado, fica como está', () async {
      await cifrarBancoDeAntes(caminho, _chave);
      expect(File(caminho).existsSync(), isFalse);

      criarBancoSemCifra();
      await cifrarBancoDeAntes(caminho, _chave);
      final antes = File(caminho).readAsBytesSync();
      await cifrarBancoDeAntes(caminho, _chave);
      expect(File(caminho).readAsBytesSync(), antes);
    });

    test('o banco do app abre cifrado e guarda como sempre', () async {
      final banco = BancoLocal(
        NativeDatabase(
          File(caminho),
          setup: (db) => db.execute("PRAGMA key = '$_chave'"),
        ),
      );
      await banco
          .into(banco.preferencias)
          .insert(PreferenciasCompanion.insert(chave: 'tema', valor: 'escuro'));
      await banco.close();

      expect(
        await estadoDoArquivoDoBanco(caminho),
        EstadoDoArquivoDoBanco.cifrado,
      );
      final deNovo = BancoLocal(
        NativeDatabase(
          File(caminho),
          setup: (db) => db.execute("PRAGMA key = '$_chave'"),
        ),
      );
      addTearDown(deNovo.close);
      expect(
        (await deNovo.select(deNovo.preferencias).getSingle()).valor,
        'escuro',
      );
    });
  });

  group('ChaveDoBanco', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('criada uma vez, aleatória, e a mesma depois', () async {
      final cofre = ChaveDoBanco(
        const FlutterSecureStorage(),
        aleatorio: Random(3),
      );
      var perdeu = false;
      final primeira = await cofre.obter(
        caminho,
        aoPerderOBanco: () async => perdeu = true,
      );
      final segunda = await cofre.obter(
        caminho,
        aoPerderOBanco: () async => perdeu = true,
      );

      expect(primeira, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(segunda, primeira);
      expect(perdeu, isFalse);
    });

    test('banco cifrado sem chave no cofre: sai do caminho', () async {
      criarBancoSemCifra();
      await cifrarBancoDeAntes(caminho, _chave);
      var perdeu = false;

      final nova = await ChaveDoBanco(const FlutterSecureStorage())
          .obter(caminho, aoPerderOBanco: () async => perdeu = true);

      expect(perdeu, isTrue);
      expect(nova, isNot(_chave));
    });

    test(
      'banco de antes, sem cifra: ganha chave, sem sair do caminho',
      () async {
        criarBancoSemCifra();
        var perdeu = false;
        await ChaveDoBanco(const FlutterSecureStorage())
            .obter(caminho, aoPerderOBanco: () async => perdeu = true);
        expect(perdeu, isFalse);
      },
    );
  });
}
