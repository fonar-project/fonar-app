import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../network/interceptors/error_interceptor.dart';
import '../relogio.dart';
import 'credencial.dart';

/// O Firebase Authentication pela API REST, com o mesmo código no Android e
/// no Windows.
///
/// Por que não o `firebase_auth`: o plugin oficial declara o Windows como
/// "só para desenvolvimento, produção não suportada". A regra do projeto é
/// que as duas plataformas têm exatamente as mesmas funcionalidades — e a
/// API REST é o que o próprio SDK chama por baixo. Sem pacote novo: o Dio já
/// estava aqui.
///
/// Documentação dos três pontos usados:
/// - `accounts:signInWithPassword` e `accounts:sendOobCode`, no Identity
///   Toolkit;
/// - `token`, no Secure Token, que troca o token de renovação por um novo.
class FirebaseAuthRest {
  FirebaseAuthRest(this._dio, {required this.chave, required this.agora});

  final Dio _dio;

  /// A "Web API key" do projeto. Não é segredo — vai dentro de todo app que
  /// usa o Firebase —, mas entra por `--dart-define` para cada ambiente
  /// apontar para o seu projeto (ver `AppConfig.firebaseApiKey`).
  final String chave;
  final DateTime Function() agora;

  static const _identidade = 'https://identitytoolkit.googleapis.com/v1';
  static const _tokens = 'https://securetoken.googleapis.com/v1';

  /// Confere e-mail e senha.
  ///
  /// Lança [CredencialInvalida], [MuitasTentativas], [ContaDesativada] ou a
  /// `AppException` da rede.
  Future<Credencial> entrar({
    required String email,
    required String senha,
  }) async {
    final corpo = await _post('$_identidade/accounts:signInWithPassword', {
      'email': email,
      'password': senha,
      'returnSecureToken': true,
    }, traduzir: _erroDeEntrada);
    return Credencial(
      uid: _texto(corpo, 'localId'),
      email: _texto(corpo, 'email'),
      idToken: _texto(corpo, 'idToken'),
      refreshToken: _texto(corpo, 'refreshToken'),
      expiraEm: _vencimento(corpo['expiresIn']),
    );
  }

  /// Troca o token vencido por um novo, sem senha.
  ///
  /// Lança [NaoAutorizado] quando o Firebase não renova mais — senha trocada,
  /// conta desativada ou apagada: só entrando de novo. Falha de rede sai como
  /// a `AppException` da rede, e a credencial continua valendo.
  Future<Credencial> renovar(Credencial credencial) async {
    final corpo = await _post(
      '$_tokens/token',
      {'grant_type': 'refresh_token', 'refresh_token': credencial.refreshToken},
      formulario: true,
      traduzir: (codigo, erro) => switch (codigo) {
        'TOKEN_EXPIRED' ||
        'INVALID_REFRESH_TOKEN' ||
        'MISSING_REFRESH_TOKEN' ||
        'USER_NOT_FOUND' ||
        'USER_DISABLED' ||
        'invalid_grant' => NaoAutorizado(causa: erro),
        _ => null,
      },
    );
    if (_texto(corpo, 'user_id') != credencial.uid) {
      // Não acontece; se acontecer, o token novo é de outra pessoa.
      throw NaoAutorizado(causa: 'renovação devolveu outra conta');
    }
    return credencial.renovada(
      idToken: _texto(corpo, 'id_token'),
      refreshToken: _texto(corpo, 'refresh_token'),
      expiraEm: _vencimento(corpo['expires_in']),
    );
  }

  /// Pede ao Firebase o e-mail com o link de redefinição de senha.
  ///
  /// Conta inexistente NÃO é erro: dizer "não há conta com este e-mail" é
  /// dizer a qualquer um quem usa o FONAR. A tela responde igual nos dois
  /// casos.
  Future<void> pedirRedefinicaoDeSenha(String email) async {
    try {
      await _post(
        '$_identidade/accounts:sendOobCode',
        {'requestType': 'PASSWORD_RESET', 'email': email},
        traduzir: (codigo, erro) => switch (codigo) {
          'EMAIL_NOT_FOUND' => const _ContaInexistente(),
          'INVALID_EMAIL' || 'MISSING_EMAIL' => CredencialInvalida(causa: erro),
          'TOO_MANY_ATTEMPTS_TRY_LATER' => MuitasTentativas(causa: erro),
          _ => null,
        },
      );
    } on _ContaInexistente {
      return;
    }
  }

  /// O código de erro do Firebase vem no corpo, como
  /// `{"error": {"message": "INVALID_LOGIN_CREDENTIALS"}}` — às vezes com um
  /// detalhe depois de " : ". [traduzir] devolve o erro do app para o
  /// código, ou `null` para o que não é dele.
  Future<Map<String, Object?>> _post(
    String url,
    Map<String, Object> dados, {
    bool formulario = false,
    required Object? Function(String codigo, DioException erro) traduzir,
  }) async {
    try {
      final resposta = await _dio.post<Object?>(
        url,
        data: dados,
        queryParameters: {'key': chave},
        options: Options(
          // O Secure Token documenta o corpo como formulário.
          contentType: formulario ? Headers.formUrlEncodedContentType : null,
          // O e-mail de redefinição sai em português.
          headers: const {'X-Firebase-Locale': 'pt-BR'},
        ),
      );
      final corpo = resposta.data;
      if (corpo is! Map<String, Object?>) {
        throw FalhaDesconhecida(causa: 'resposta sem corpo JSON');
      }
      return corpo;
    } on DioException catch (e) {
      final codigo = _codigo(e.response?.data);
      if (codigo != null) {
        final traduzido = traduzir(codigo, e);
        if (traduzido != null) throw traduzido;
        // Chave errada, provedor de e-mail e senha desligado no console:
        // configuração, e não algo que o profissional resolva.
        throw FalhaDesconhecida(causa: 'Firebase: $codigo');
      }
      final falha = e.error;
      throw falha is AppException ? falha : FalhaDesconhecida(causa: e);
    }
  }

  static AppException? _erroDeEntrada(String codigo, DioException erro) =>
      switch (codigo) {
        'INVALID_LOGIN_CREDENTIALS' ||
        'EMAIL_NOT_FOUND' ||
        'INVALID_PASSWORD' ||
        'INVALID_EMAIL' ||
        'MISSING_PASSWORD' ||
        'MISSING_EMAIL' => CredencialInvalida(causa: erro),
        'TOO_MANY_ATTEMPTS_TRY_LATER' => MuitasTentativas(causa: erro),
        'USER_DISABLED' => ContaDesativada(causa: erro),
        _ => null,
      };

  static String? _codigo(Object? corpo) {
    if (corpo is! Map) return null;
    final erro = corpo['error'];
    // O Secure Token às vezes responde com o erro OAuth simples:
    // `{"error": "invalid_grant"}`.
    final mensagem = erro is Map ? erro['message'] : erro;
    if (mensagem is! String || mensagem.isEmpty) return null;
    return mensagem.split(' : ').first.trim();
  }

  static String _texto(Map<String, Object?> corpo, String campo) {
    final valor = corpo[campo];
    if (valor is String && valor.isNotEmpty) return valor;
    throw FalhaDesconhecida(causa: 'resposta do Firebase sem "$campo"');
  }

  /// O Firebase manda a validade em segundos, como texto.
  DateTime _vencimento(Object? segundos) {
    final s = int.tryParse('$segundos');
    if (s == null || s <= 0) {
      throw FalhaDesconhecida(causa: 'resposta do Firebase sem validade');
    }
    return agora().add(Duration(seconds: s));
  }
}

/// Sinal interno: o e-mail não tem conta. Nunca sai daqui.
class _ContaInexistente implements Exception {
  const _ContaInexistente();
}

/// O cliente do Firebase, ou `null` quando o build não recebeu a chave — e o
/// app roda com o login de exemplo (ver `repositorioAutenticacaoProvider`).
final firebaseAuthRestProvider = Provider<FirebaseAuthRest?>((ref) {
  const chave = AppConfig.firebaseApiKey;
  if (chave.isEmpty) return null;
  final dio = Dio(
    BaseOptions(
      connectTimeout: AppConfig.timeoutConexao,
      receiveTimeout: AppConfig.timeoutConexao,
      sendTimeout: AppConfig.timeoutConexao,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  // Um Dio só do Firebase, sem o `AuthInterceptor`: estas chamadas são as
  // que OBTÊM o token, e o interceptor pediria um token para fazê-las.
  dio.interceptors.add(const ErrorInterceptor());
  ref.onDispose(dio.close);
  return FirebaseAuthRest(dio, chave: chave, agora: ref.watch(relogioProvider));
});
