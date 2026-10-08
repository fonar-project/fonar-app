import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/auth/credencial.dart';
import 'package:fonar_app/core/auth/firebase_auth_rest.dart';
import 'package:fonar_app/core/auth/fonte_de_token.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/auth_interceptor.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_firebase.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_placeholder.dart';
import 'package:fonar_app/features/auth/domain/conta_autenticada.dart';

import '../../apoio/http_falso.dart';
import '../../apoio/repositorios_em_memoria.dart';

final _agora = DateTime.utc(2026, 10, 8, 14);

Credencial _credencial({required DateTime expiraEm, String uid = 'uid-1'}) =>
    Credencial(
      uid: uid,
      email: 'fono@exemplo.com',
      idToken: 'token-1',
      refreshToken: 'renova-1',
      expiraEm: expiraEm,
    );

const _renovou = RespostaFalsa(200, {
  'id_token': 'token-2',
  'refresh_token': 'renova-2',
  'expires_in': '3600',
  'user_id': 'uid-1',
});

FirebaseAuthRest _firebase(HttpClientAdapter adaptador) {
  final dio = Dio()
    ..httpClientAdapter = adaptador
    ..interceptors.add(const ErrorInterceptor());
  return FirebaseAuthRest(dio, chave: 'chave', agora: () => _agora);
}

/// Segura a resposta do Firebase até o teste soltar.
class _AdaptadorLento implements HttpClientAdapter {
  _AdaptadorLento(this._resposta);
  final AdaptadorFalso _resposta;
  final solta = Completer<void>();
  var pedidos = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    pedidos++;
    await solta.future;
    return _resposta.fetch(options, null, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late TokenStorageEmMemoria tokens;
  late CofreDeCredencial cofre;
  setUp(() {
    tokens = TokenStorageEmMemoria();
    cofre = CofreDeCredencial(tokens);
  });

  group('CofreDeCredencial', () {
    test('guarda e lê de volta, inteira', () async {
      final guardada = _credencial(expiraEm: _agora);
      await cofre.guardar(guardada);

      final lida = await cofre.ler();
      expect(lida!.uid, guardada.uid);
      expect(lida.email, guardada.email);
      expect(lida.idToken, guardada.idToken);
      expect(lida.refreshToken, guardada.refreshToken);
      expect(lida.expiraEm, guardada.expiraEm);
    });

    test(
      'o token solto de antes da US32 vira nenhuma, e sai do cofre',
      () async {
        tokens.token = 'token-antigo';

        expect(await cofre.ler(), isNull);
        expect(tokens.token, isNull);
      },
    );

    test('JSON sem o dono também não serve', () async {
      tokens.token = '{"idToken": "x", "refreshToken": "y"}';

      expect(await cofre.ler(), isNull);
      expect(tokens.token, isNull);
    });
  });

  group('FonteDeToken', () {
    test('token ainda válido: sai do cofre, sem ir à rede', () async {
      await cofre.guardar(
        _credencial(expiraEm: _agora.add(const Duration(minutes: 30))),
      );
      final servidor = AdaptadorFalso([]);

      final token = await FonteDeToken(
        cofre,
        _firebase(servidor),
        () => _agora,
      ).tokenDeAcesso();

      expect(token, 'token-1');
      expect(servidor.feitas, isEmpty);
    });

    test('perto de vencer: renova antes, e guarda o novo', () async {
      // Quatro minutos: dentro da folga — o envio de um WAV demora.
      await cofre.guardar(
        _credencial(expiraEm: _agora.add(const Duration(minutes: 4))),
      );
      final servidor = AdaptadorFalso([_renovou]);

      final token = await FonteDeToken(
        cofre,
        _firebase(servidor),
        () => _agora,
      ).tokenDeAcesso();

      expect(token, 'token-2');
      expect(servidor.feitas, hasLength(1));
      final guardada = await cofre.ler();
      expect(guardada!.idToken, 'token-2');
      expect(guardada.refreshToken, 'renova-2');
    });

    test('dois pedidos ao mesmo tempo: uma renovação só', () async {
      await cofre.guardar(_credencial(expiraEm: _agora));
      final lento = _AdaptadorLento(AdaptadorFalso([_renovou]));
      final fonte = FonteDeToken(cofre, _firebase(lento), () => _agora);

      final a = fonte.tokenDeAcesso();
      final b = fonte.tokenDeAcesso();
      await pumpEventQueue();
      lento.solta.complete();

      expect(await a, 'token-2');
      expect(await b, 'token-2');
      expect(lento.pedidos, 1);
    });

    test('o Firebase não renova mais: a credencial sai do cofre', () async {
      await cofre.guardar(_credencial(expiraEm: _agora));
      final fonte = FonteDeToken(
        cofre,
        _firebase(AdaptadorFalso([erroDoFirebase('TOKEN_EXPIRED')])),
        () => _agora,
      );

      await expectLater(fonte.tokenDeAcesso(), throwsA(isA<NaoAutorizado>()));
      // Senão o modo offline entraria numa conta que não vale mais.
      expect(await cofre.ler(), isNull);
    });

    test('sem rede: a credencial fica, para tentar de novo depois', () async {
      await cofre.guardar(_credencial(expiraEm: _agora));
      final fonte = FonteDeToken(
        cofre,
        _firebase(AdaptadorFalso([const RespostaFalsa.semRede()])),
        () => _agora,
      );

      await expectLater(fonte.tokenDeAcesso(), throwsA(isA<FalhaDeConexao>()));
      expect((await cofre.ler())!.refreshToken, 'renova-1');
    });

    test('saiu da conta durante a renovação: nada volta ao cofre', () async {
      await cofre.guardar(_credencial(expiraEm: _agora));
      final lento = _AdaptadorLento(AdaptadorFalso([_renovou]));
      final fonte = FonteDeToken(cofre, _firebase(lento), () => _agora);

      final pedido = fonte.tokenDeAcesso();
      await pumpEventQueue();
      await cofre.apagar();
      lento.solta.complete();

      await expectLater(pedido, throwsA(isA<NaoAutorizado>()));
      expect(await cofre.ler(), isNull);
    });

    test('ninguém entrou com senha: não há com que autenticar', () async {
      final fonte = FonteDeToken(
        cofre,
        _firebase(AdaptadorFalso([])),
        () => _agora,
      );

      await expectLater(fonte.tokenDeAcesso(), throwsA(isA<NaoAutorizado>()));
    });

    test('login de exemplo: sem token, e sem erro', () async {
      expect(
        await FonteDeToken(cofre, null, () => _agora).tokenDeAcesso(),
        isNull,
      );
    });
  });

  group('AuthInterceptor', () {
    Dio api(FonteDeToken fonte, AdaptadorFalso servidor) =>
        Dio(BaseOptions(baseUrl: 'https://api.exemplo.invalid'))
          ..httpClientAdapter = servidor
          ..interceptors.addAll([
            AuthInterceptor(fonte),
            const ErrorInterceptor(),
          ]);

    test('leva o token no cabeçalho', () async {
      await cofre.guardar(
        _credencial(expiraEm: _agora.add(const Duration(hours: 1))),
      );
      final servidor = AdaptadorFalso([const RespostaFalsa(200)]);

      await api(
        FonteDeToken(cofre, _firebase(AdaptadorFalso([])), () => _agora),
        servidor,
      ).get<Object?>('/analises');

      expect(
        servidor.feitas.single.cabecalhos['Authorization'],
        'Bearer token-1',
      );
    });

    test('sem token que sirva, a requisição nem sai', () async {
      final servidor = AdaptadorFalso([]);
      final pedido = api(
        FonteDeToken(cofre, _firebase(AdaptadorFalso([])), () => _agora),
        servidor,
      ).get<Object?>('/analises');

      await expectLater(
        pedido,
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'erro',
            isA<NaoAutorizado>(),
          ),
        ),
      );
      expect(servidor.feitas, isEmpty);
    });
  });

  group('repositórios de autenticação', () {
    test('Firebase: entrar guarda a credencial; sair a apaga', () async {
      final repositorio = RepositorioAutenticacaoFirebase(
        _firebase(
          AdaptadorFalso([
            const RespostaFalsa(200, {
              'localId': 'uid-1',
              'email': 'fono@exemplo.com',
              'idToken': 'token-1',
              'refreshToken': 'renova-1',
              'expiresIn': '3600',
            }),
          ]),
        ),
        cofre,
      );

      final conta = await repositorio.entrar(
        email: 'fono@exemplo.com',
        senha: 'segredo',
      );

      const esperada = ContaAutenticada(
        uid: 'uid-1',
        email: 'fono@exemplo.com',
      );
      expect(conta, esperada);
      expect(await repositorio.contaGuardada(), esperada);
      expect((await cofre.ler())!.refreshToken, 'renova-1');

      await repositorio.sair();
      expect(await repositorio.contaGuardada(), isNull);
    });

    test('Firebase: senha recusada não guarda nada', () async {
      final repositorio = RepositorioAutenticacaoFirebase(
        _firebase(
          AdaptadorFalso([erroDoFirebase('INVALID_LOGIN_CREDENTIALS')]),
        ),
        cofre,
      );

      await expectLater(
        repositorio.entrar(email: 'a@b.c', senha: 'x'),
        throwsA(isA<CredencialInvalida>()),
      );
      expect(await repositorio.contaGuardada(), isNull);
    });

    test('exemplo: cada e-mail é uma conta, marcada como de exemplo', () async {
      final repositorio = RepositorioAutenticacaoPlaceholder(cofre);

      final conta = await repositorio.entrar(
        email: 'Fono@Exemplo.com',
        senha: '',
      );

      expect(conta.uid, 'exemplo:fono@exemplo.com');
      expect(await repositorio.contaGuardada(), conta);
      // Sem token: a API também é de exemplo.
      expect(
        await FonteDeToken(cofre, null, () => _agora).tokenDeAcesso(),
        isEmpty,
      );
    });
  });
}
