import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/auth/senha_sem_rede.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // Os vetores publicados de PBKDF2-HMAC-SHA256 ("password", "salt") — os
  // da RFC 6070, refeitos para SHA-256 e reproduzidos em toda biblioteca
  // que implementa a função. Não são saída nossa: são o que a derivação
  // TEM de dar.
  group('pbkdf2HmacSha256 contra os vetores publicados', () {
    final senha = utf8.encode('password');
    final sal = utf8.encode('salt');

    test('1 iteração', () {
      expect(
        _hex(pbkdf2HmacSha256(senha, sal, 1, 32)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('2 iterações', () {
      expect(
        _hex(pbkdf2HmacSha256(senha, sal, 2, 32)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('4096 iterações', () {
      expect(
        _hex(pbkdf2HmacSha256(senha, sal, 4096, 32)),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });
  });

  test('comparação em tempo constante', () {
    expect(iguaisEmTempoConstante([1, 2, 3], [1, 2, 3]), isTrue);
    expect(iguaisEmTempoConstante([1, 2, 3], [1, 2, 4]), isFalse);
    expect(iguaisEmTempoConstante([1, 2], [1, 2, 3]), isFalse);
  });

  group('SenhaSemRedeNoCofre', () {
    late SenhaSemRedeNoCofre senhas;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      senhas = SenhaSemRedeNoCofre(
        const FlutterSecureStorage(),
        // Poucas voltas e a derivação aqui mesmo: o que se testa é o
        // guardar e o conferir, não o custo.
        iteracoes: 10,
        aleatorio: Random(7),
        derivar: (senha, sal, iteracoes) async =>
            pbkdf2HmacSha256(utf8.encode(senha), sal, iteracoes, 32),
      );
    });

    test('sem nada guardado, não há com o que conferir', () async {
      expect(
        await senhas.conferir('uid-1', 'certa'),
        ConferenciaSemRede.semRegistro,
      );
    });

    test('a senha lembrada confere; outra, não', () async {
      await senhas.lembrar('uid-1', 'certa');

      expect(
        await senhas.conferir('uid-1', 'certa'),
        ConferenciaSemRede.confere,
      );
      expect(
        await senhas.conferir('uid-1', 'errada'),
        ConferenciaSemRede.naoConfere,
      );
    });

    test('é de uma conta só: a de outra não confere nada', () async {
      await senhas.lembrar('uid-1', 'certa');
      expect(
        await senhas.conferir('uid-2', 'certa'),
        ConferenciaSemRede.semRegistro,
      );
    });

    test('o cofre não guarda a senha, só o verificador', () async {
      await senhas.lembrar('uid-1', 'senha-muito-especifica');
      final guardado = await const FlutterSecureStorage().read(
        key: SenhaSemRedeNoCofre.chave,
      );
      expect(guardado, isNot(contains('senha-muito-especifica')));
      expect(jsonDecode(guardado!), containsPair('iteracoes', 10));
    });

    test('esquecer apaga', () async {
      await senhas.lembrar('uid-1', 'certa');
      await senhas.esquecer();
      expect(
        await senhas.conferir('uid-1', 'certa'),
        ConferenciaSemRede.semRegistro,
      );
    });

    test('a derivação de produção tem o custo previsto', () {
      expect(iteracoesDaSenhaSemRede, greaterThanOrEqualTo(100000));
    });
  });
}
