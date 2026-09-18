/// Entrada do profissional no aplicativo.
///
/// A tela de login conhece só esta interface. Quem autentica de verdade vai
/// ser o Firebase Auth, e trocar a implementação não pode exigir mexer em
/// widget.
abstract interface class RepositorioAutenticacao {
  /// Autentica com e-mail e senha.
  ///
  /// Lança `CredencialInvalida` quando o par é recusado, e qualquer outra
  /// `AppException` quando a falha é de rede ou de servidor.
  Future<void> entrar({required String email, required String senha});
}
