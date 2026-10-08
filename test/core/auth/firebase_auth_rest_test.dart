import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/auth/credencial.dart';
import 'package:fonar_app/core/auth/firebase_auth_rest.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';

import '../../apoio/http_falso.dart';

final _agora = DateTime.utc(2026, 10, 8, 14);

/// O cliente como o app monta, com o servidor de mentira.
FirebaseAuthRest _cliente(AdaptadorFalso adaptador) {
  final dio = Dio(BaseOptions(contentType: Headers.jsonContentType))
    ..httpClientAdapter = adaptador
    ..interceptors.add(const ErrorInterceptor());
  return FirebaseAuthRest(dio, chave: 'chave-de-teste', agora: () => _agora);
}

const _entrou = RespostaFalsa(200, {
  'localId': 'uid-1',
  'email': 'fono@exemplo.com',
  'idToken': 'token-1',
  'refreshToken': 'renova-1',
  'expiresIn': '3600',
});

final _credencial = Credencial(
  uid: 'uid-1',
  email: 'fono@exemplo.com',
  idToken: 'token-1',
  refreshToken: 'renova-1',
  expiraEm: _agora,
);

void main() {
  group('entrar', () {
    test('confere no Identity Toolkit, com a chave, e devolve a credencial', () async {
      final servidor = AdaptadorFalso([_entrou]);

      final credencial = await _cliente(servidor)
          .entrar(email: 'fono@exemplo.com', senha: 'segredo');

      final pedido = servidor.feitas.single;
      expect(pedido.opcoes.method, 'POST');
      expect(
        pedido.uri.toString(),
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
        '?key=chave-de-teste',
      );
      expect(pedido.json, {
        'email': 'fono@exemplo.com',
        'password': 'segredo',
        'returnSecureToken': true,
      });
      expect(credencial.uid, 'uid-1');
      expect(credencial.idToken, 'token-1');
      expect(credencial.refreshToken, 'renova-1');
      expect(credencial.expiraEm, _agora.add(const Duration(hours: 1)));
    });

    for (final codigo in [
      'INVALID_LOGIN_CREDENTIALS',
      'EMAIL_NOT_FOUND',
      'INVALID_PASSWORD',
      'INVALID_EMAIL',
    ]) {
      test('$codigo vira credencial inválida', () async {
        await expectLater(
          _cliente(AdaptadorFalso([erroDoFirebase(codigo)]))
              .entrar(email: 'a@b.c', senha: 'x'),
          throwsA(isA<CredencialInvalida>()),
        );
      });
    }

    test('muitas tentativas, com o detalhe depois do código', () async {
      await expectLater(
        _cliente(
          AdaptadorFalso([
            erroDoFirebase(
              'TOO_MANY_ATTEMPTS_TRY_LATER : Access to this account has been '
              'temporarily disabled',
            ),
          ]),
        ).entrar(email: 'a@b.c', senha: 'x'),
        throwsA(isA<MuitasTentativas>()),
      );
    });

    test('conta desativada', () async {
      await expectLater(
        _cliente(AdaptadorFalso([erroDoFirebase('USER_DISABLED')]))
            .entrar(email: 'a@b.c', senha: 'x'),
        throwsA(isA<ContaDesativada>()),
      );
    });

    test('erro de configuração não culpa a senha', () async {
      // Chave errada, ou e-mail e senha desligados no console.
      await expectLater(
        _cliente(
          AdaptadorFalso([
            erroDoFirebase('API key not valid. Please pass a valid API key.'),
          ]),
        ).entrar(email: 'a@b.c', senha: 'x'),
        throwsA(isA<FalhaDesconhecida>()),
      );
    });

    test('sem rede, é falha de conexão', () async {
      await expectLater(
        _cliente(AdaptadorFalso([const RespostaFalsa.semRede()]))
            .entrar(email: 'a@b.c', senha: 'x'),
        throwsA(isA<FalhaDeConexao>()),
      );
    });

    test('resposta sem token não vira credencial pela metade', () async {
      await expectLater(
        _cliente(
          AdaptadorFalso([
            const RespostaFalsa(200, {'localId': 'uid-1', 'email': 'a@b.c'}),
          ]),
        ).entrar(email: 'a@b.c', senha: 'x'),
        throwsA(isA<FalhaDesconhecida>()),
      );
    });
  });

  group('renovar', () {
    test(
      'troca o token de renovação no Secure Token, como formulário',
      () async {
        final servidor = AdaptadorFalso([
          const RespostaFalsa(200, {
            'id_token': 'token-2',
            'refresh_token': 'renova-2',
            'expires_in': '3600',
            'user_id': 'uid-1',
            'token_type': 'Bearer',
          }),
        ]);

        final nova = await _cliente(servidor).renovar(_credencial);

        final pedido = servidor.feitas.single;
        expect(
          pedido.uri.toString(),
          'https://securetoken.googleapis.com/v1/token?key=chave-de-teste',
        );
        expect(pedido.opcoes.contentType, Headers.formUrlEncodedContentType);
        expect(pedido.formulario, {
          'grant_type': 'refresh_token',
          'refresh_token': 'renova-1',
        });
        expect(nova.uid, 'uid-1');
        expect(nova.email, 'fono@exemplo.com');
        expect(nova.idToken, 'token-2');
        expect(nova.refreshToken, 'renova-2');
        expect(nova.expiraEm, _agora.add(const Duration(hours: 1)));
      },
    );

    for (final codigo in [
      'TOKEN_EXPIRED',
      'USER_DISABLED',
      'INVALID_REFRESH_TOKEN',
    ]) {
      test('$codigo: só entrando de novo', () async {
        await expectLater(
          _cliente(AdaptadorFalso([erroDoFirebase(codigo)]))
              .renovar(_credencial),
          throwsA(isA<NaoAutorizado>()),
        );
      });
    }

    test('sem rede não é sessão expirada', () async {
      await expectLater(
        _cliente(AdaptadorFalso([const RespostaFalsa.semRede()]))
            .renovar(_credencial),
        throwsA(isA<FalhaDeConexao>()),
      );
    });

    test('erro de configuração não é sessão expirada', () async {
      // Senão uma chave errada apagaria a credencial de quem já entrou.
      await expectLater(
        _cliente(AdaptadorFalso([erroDoFirebase('API key not valid.')]))
            .renovar(_credencial),
        throwsA(isA<FalhaDesconhecida>()),
      );
    });

    test('token novo de outra conta é recusado', () async {
      await expectLater(
        _cliente(
          AdaptadorFalso([
            const RespostaFalsa(200, {
              'id_token': 'token-2',
              'refresh_token': 'renova-2',
              'expires_in': '3600',
              'user_id': 'outra',
            }),
          ]),
        ).renovar(_credencial),
        throwsA(isA<NaoAutorizado>()),
      );
    });
  });

  group('redefinição de senha', () {
    test('pede o e-mail de redefinição, em português', () async {
      final servidor = AdaptadorFalso([
        const RespostaFalsa(200, {'email': 'fono@exemplo.com'}),
      ]);

      await _cliente(servidor).pedirRedefinicaoDeSenha('fono@exemplo.com');

      final pedido = servidor.feitas.single;
      expect(
        pedido.uri.toString(),
        'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode'
        '?key=chave-de-teste',
      );
      expect(pedido.json, {
        'requestType': 'PASSWORD_RESET',
        'email': 'fono@exemplo.com',
      });
      expect(pedido.cabecalhos['X-Firebase-Locale'], 'pt-BR');
    });

    test('e-mail sem conta responde igual: não diz quem usa o FONAR', () async {
      await expectLater(
        _cliente(AdaptadorFalso([erroDoFirebase('EMAIL_NOT_FOUND')]))
            .pedirRedefinicaoDeSenha('ninguem@exemplo.com'),
        completes,
      );
    });

    test('e-mail mal formado é dito', () async {
      await expectLater(
        _cliente(AdaptadorFalso([erroDoFirebase('INVALID_EMAIL')]))
            .pedirRedefinicaoDeSenha('fono@'),
        throwsA(isA<CredencialInvalida>()),
      );
    });
  });
}
