import 'conta_autenticada.dart';

abstract interface class RepositorioAutenticacao {
  /// Confere e-mail e senha e guarda a credencial no aparelho.
  ///
  /// Lança `CredencialInvalida` quando o par é recusado, `MuitasTentativas`
  /// e `ContaDesativada` quando a conta não deixa entrar agora, e qualquer
  /// outra `AppException` quando a falha é de rede ou de servidor.
  Future<ContaAutenticada> entrar({
    required String email,
    required String senha,
  });

  /// A conta da última entrada com senha neste aparelho, se a credencial
  /// ainda está guardada. É com ela que o modo offline entra. Não vai à rede.
  Future<ContaAutenticada?> contaGuardada();

  /// Pede o e-mail com o link de redefinição de senha.
  ///
  /// Não diz se o e-mail tem conta. Lança `CredencialInvalida` para e-mail
  /// mal formado e a `AppException` da rede.
  Future<void> pedirRedefinicaoDeSenha(String email);

  /// Apaga a credencial guardada. Lança só `AppException`: credencial que
  /// não saiu tem de ser dita, e não fingida.
  Future<void> sair();
}
