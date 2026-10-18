import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/auth/credencial.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/storage/token_storage.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/data/sessao_mantida.dart';

import '../../apoio/repositorios_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

final _guardada = Credencial(
  uid: contaDeTeste.uid,
  email: contaDeTeste.email,
  idToken: 'token',
  refreshToken: 'renova',
  expiraEm: DateTime.utc(2026, 10, 18, 12),
);

/// O cofre que falha, ou que não responde nunca.
class _CofreQuebrado implements TokenStorage {
  _CofreQuebrado({this.travado = false});

  final bool travado;

  @override
  Future<String?> lerToken() => travado
      ? Completer<String?>().future
      : Future.error(const FalhaDesconhecida());

  @override
  Future<void> salvarToken(String token) async {}

  @override
  Future<void> limpar() async {}
}

void main() {
  late TokenStorageEmMemoria tokens;
  late CofreDeCredencial cofre;
  late SessaoMantida mantida;

  setUp(() {
    tokens = TokenStorageEmMemoria();
    cofre = CofreDeCredencial(tokens);
    mantida = SessaoMantida(cofre);
  });

  group('SessaoMantida', () {
    test('sem credencial no cofre, não há o que abrir nem marcar', () async {
      await mantida.manter(contaDeTeste.uid);

      expect(await mantida.contaAAbrir(), isNull);
      expect(tokens.token, isNull);
    });

    test('a credencial de quem não marcou não abre sozinha', () async {
      await cofre.guardar(_guardada);

      expect(await mantida.contaAAbrir(), isNull);
    });

    test('marcada, abre a conta dela, com os mesmos tokens', () async {
      await cofre.guardar(_guardada);

      await mantida.manter(contaDeTeste.uid);

      expect(await mantida.contaAAbrir(), contaDeTeste);
      final lida = await cofre.ler();
      expect(lida!.idToken, 'token');
      expect(lida.refreshToken, 'renova');
      expect(lida.manterConectado, isTrue);
    });

    test('não marca a credencial de outra conta', () async {
      await cofre.guardar(_guardada);

      await mantida.manter(outraConta.uid);

      expect(await mantida.contaAAbrir(), isNull);
    });

    test('sair apaga a credencial, e a marca vai junto', () async {
      await cofre.guardar(_guardada.comManterConectado(true));

      await cofre.apagar();

      expect(await mantida.contaAAbrir(), isNull);
    });
  });

  group('na abertura do app', () {
    ProviderContainer container(TokenStorage tokens) {
      final c = ProviderContainer(
        overrides: [tokenStorageProvider.overrideWithValue(tokens)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('com a marca, a sessão já abre antes da primeira tela', () async {
      await cofre.guardar(_guardada.comManterConectado(true));
      final c = container(tokens);

      await abrirSessaoMantida(c);

      expect(c.read(sessaoProvider), contaDeTeste);
    });

    test('sem a marca, abre na entrada', () async {
      await cofre.guardar(_guardada);
      final c = container(tokens);

      await abrirSessaoMantida(c);

      expect(c.read(sessaoAbertaProvider), isFalse);
    });

    test('o cofre que falha não segura o app: abre na entrada', () async {
      final c = container(_CofreQuebrado());

      await abrirSessaoMantida(c);

      expect(c.read(sessaoAbertaProvider), isFalse);
    });

    test('nem o cofre que não responde', () async {
      final c = container(_CofreQuebrado(travado: true));

      await abrirSessaoMantida(c, limite: const Duration(milliseconds: 20));

      expect(c.read(sessaoAbertaProvider), isFalse);
    });
  });
}
