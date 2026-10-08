import '../../../core/auth/credencial.dart';
import '../../../core/error/app_exception.dart';
import '../domain/conta_autenticada.dart';
import '../domain/repositorio_autenticacao.dart';

/// PLACEHOLDER — o login de exemplo, para quando o build não recebeu a chave
/// do Firebase. Aceita qualquer e-mail e senha, e a tela de entrada diz isso.
///
/// Cada e-mail vira uma conta "de exemplo" diferente, para que a fila e o
/// perfil se comportem como com o Firebase: o que um gravou não sobe na
/// sessão do outro.
class RepositorioAutenticacaoPlaceholder implements RepositorioAutenticacao {
  const RepositorioAutenticacaoPlaceholder(this._cofre);

  final CofreDeCredencial _cofre;

  static String uidDe(String email) => 'exemplo:${email.toLowerCase()}';

  @override
  Future<ContaAutenticada> entrar({
    required String email,
    required String senha,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final conta = ContaAutenticada(uid: uidDe(email), email: email);
    // Sem token nenhum: a API de análise também é de exemplo. Guardada só
    // para o modo offline saber quem entrou por último.
    await _cofre.guardar(
      Credencial(
        uid: conta.uid,
        email: email,
        idToken: '',
        refreshToken: '',
        expiraEm: DateTime.utc(9999),
      ),
    );
    return conta;
  }

  @override
  Future<ContaAutenticada?> contaGuardada() async {
    final credencial = await _cofre.ler();
    if (credencial == null) return null;
    return ContaAutenticada(uid: credencial.uid, email: credencial.email);
  }

  /// Não envia e-mail nenhum, e não finge que mandou. A tela de entrada nem
  /// chega a chamar: com o login de exemplo, ela explica que a recuperação
  /// não existe (`loginDeExemploProvider`).
  @override
  Future<void> pedirRedefinicaoDeSenha(String email) async =>
      throw const FalhaDesconhecida(causa: 'login de exemplo não envia e-mail');

  @override
  Future<void> sair() => _cofre.apagar();
}
