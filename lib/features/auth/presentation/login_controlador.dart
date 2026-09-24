import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../data/repositorio_autenticacao_placeholder.dart';
import '../data/sessao.dart';

/// Estado do formulário de login.
class EstadoLogin {
  const EstadoLogin({
    this.carregando = false,
    this.erroEmail,
    this.erroSenha,
    this.erroGeral,
  });

  final bool carregando;
  final String? erroEmail;

  /// Também recebe a credencial recusada: o protótipo marca o campo de senha,
  /// que é o que o usuário vai redigitar.
  final String? erroSenha;

  /// Falha que não pertence a um campo — rede, servidor.
  final String? erroGeral;
}

class LoginControlador extends Notifier<EstadoLogin> {
  @override
  EstadoLogin build() => const EstadoLogin();

  /// Tenta entrar. Devolve `true` quando a autenticação passou; a navegação
  /// fica com a tela, que é quem tem o `BuildContext`.
  Future<bool> entrar({required String email, required String senha}) async {
    // Toque duplo no botão, ou Enter no campo enquanto a primeira tentativa
    // ainda está no ar.
    if (state.carregando) return false;

    final emailLimpo = email.trim();
    final erroEmail = emailLimpo.isEmpty ? AppStrings.loginInformeEmail : null;
    // A senha não é aparada: espaço pode fazer parte dela.
    final erroSenha = senha.isEmpty ? AppStrings.loginInformeSenha : null;
    if (erroEmail != null || erroSenha != null) {
      state = EstadoLogin(erroEmail: erroEmail, erroSenha: erroSenha);
      return false;
    }

    state = const EstadoLogin(carregando: true);
    EstadoLogin resultado;
    try {
      await ref
          .read(repositorioAutenticacaoProvider)
          .entrar(email: emailLimpo, senha: senha);
      resultado = const EstadoLogin();
    } on CredencialInvalida catch (e) {
      resultado = EstadoLogin(erroSenha: e.mensagem);
    } on AppException catch (e) {
      resultado = EstadoLogin(erroGeral: e.mensagem);
    } catch (_) {
      // O contrato do repositório é lançar só AppException. Se outra coisa
      // escapar, o pior desfecho é o botão preso em "Entrando…" para sempre.
      resultado = const EstadoLogin(erroGeral: AppStrings.erroDesconhecido);
    }

    // A tela pode ter saído enquanto a autenticação estava no ar.
    if (!ref.mounted) return false;
    state = resultado;
    final entrou = resultado.erroSenha == null && resultado.erroGeral == null;
    if (entrou) ref.read(sessaoAbertaProvider.notifier).abrir();
    return entrou;
  }

  /// Entra sem conexão, com os dados já guardados no aparelho. A sessão abre
  /// do mesmo jeito: a fila espera a rede, não um novo login.
  void entrarOffline() => ref.read(sessaoAbertaProvider.notifier).abrir();
}

final loginControladorProvider =
    NotifierProvider.autoDispose<LoginControlador, EstadoLogin>(
      LoginControlador.new,
    );
