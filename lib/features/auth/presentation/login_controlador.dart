import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../cadastro/presentation/entrada.dart';
import '../data/repositorio_autenticacao_firebase.dart';
import '../data/sessao.dart';
import '../domain/conta_autenticada.dart';

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

  /// Falha que não pertence a um campo — rede, servidor, conta pausada.
  final String? erroGeral;
}

/// Em que pé está o pedido de redefinição de senha.
enum PedidoDeRedefinicao { nenhum, enviando, enviado }

class LoginControlador extends Notifier<EstadoLogin> {
  @override
  EstadoLogin build() => const EstadoLogin();

  /// Tenta entrar. Devolve para onde ir quando a senha conferiu — os
  /// pacientes, ou o passo que falta do primeiro acesso (confirmar o e-mail,
  /// preencher o cadastro) —, e `null` quando não entrou. A navegação fica
  /// com a tela, que é quem tem o `BuildContext`.
  Future<DestinoDaEntrada?> entrar({
    required String email,
    required String senha,
  }) async {
    // Toque duplo no botão, ou Enter no campo enquanto a primeira tentativa
    // ainda está no ar.
    if (state.carregando) return null;

    final emailLimpo = email.trim();
    final erroEmail = emailLimpo.isEmpty ? AppStrings.loginInformeEmail : null;
    // A senha não é aparada: espaço pode fazer parte dela.
    final erroSenha = senha.isEmpty ? AppStrings.loginInformeSenha : null;
    if (erroEmail != null || erroSenha != null) {
      state = EstadoLogin(erroEmail: erroEmail, erroSenha: erroSenha);
      return null;
    }

    state = const EstadoLogin(carregando: true);
    EstadoLogin resultado;
    ContaAutenticada? conta;
    try {
      conta = await ref
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
    if (!ref.mounted) return null;
    if (conta == null) {
      state = resultado;
      return null;
    }

    // A senha conferiu; falta saber em que pé está o cadastro. O botão
    // continua em "Entrando…" enquanto a API responde.
    final destino = await conferirCadastro(ref);
    if (!ref.mounted) return null;
    state = resultado;
    switch (destino) {
      case EntrarNoApp():
        abrirSessao(ref, conta);
      case VerificarEmail() || CompletarCadastro():
        // A credencial fica no cofre: é com ela que a confirmação pede o
        // token novo e o cadastro vai à API.
        ref.invalidate(contaGuardadaProvider);
    }
    return destino;
  }

  /// Entra sem conexão, com a conta da última entrada com senha neste
  /// aparelho. A sessão abre do mesmo jeito: a fila espera a rede, não um
  /// novo login. Devolve `false` se não há conta guardada.
  Future<bool> entrarOffline() async {
    final ContaAutenticada? conta;
    try {
      conta = await ref.read(repositorioAutenticacaoProvider).contaGuardada();
    } catch (_) {
      if (ref.mounted) {
        state = const EstadoLogin(erroGeral: AppStrings.erroDesconhecido);
      }
      return false;
    }
    if (conta == null || !ref.mounted) return false;
    ref.read(sessaoProvider.notifier).abrir(conta);
    return true;
  }
}

/// A conta com que o modo offline entraria — a da última entrada com senha
/// neste aparelho —, ou `null`.
final contaGuardadaProvider = FutureProvider.autoDispose<ContaAutenticada?>(
  (ref) => ref.watch(repositorioAutenticacaoProvider).contaGuardada(),
);

/// "Esqueci a senha": pede o e-mail de redefinição ao Firebase.
class RedefinicaoDeSenhaControlador extends Notifier<PedidoDeRedefinicao> {
  @override
  PedidoDeRedefinicao build() => PedidoDeRedefinicao.nenhum;

  /// Devolve o erro a mostrar, ou `null` quando o pedido saiu. Com o e-mail
  /// em branco, nem tenta: o erro é o do campo.
  Future<String?> pedir(String email) async {
    if (state == PedidoDeRedefinicao.enviando) return null;
    final limpo = email.trim();
    if (limpo.isEmpty) return AppStrings.loginRecuperacaoInformeEmail;
    state = PedidoDeRedefinicao.enviando;
    String? erro;
    try {
      await ref
          .read(repositorioAutenticacaoProvider)
          .pedirRedefinicaoDeSenha(limpo);
    } on CredencialInvalida {
      erro = AppStrings.loginRecuperacaoEmailInvalido;
    } on AppException catch (e) {
      erro = e.mensagem;
    } catch (_) {
      erro = AppStrings.erroDesconhecido;
    }
    if (!ref.mounted) return erro;
    state = erro == null
        ? PedidoDeRedefinicao.enviado
        : PedidoDeRedefinicao.nenhum;
    return erro;
  }
}

final redefinicaoDeSenhaProvider =
    NotifierProvider.autoDispose<
      RedefinicaoDeSenhaControlador,
      PedidoDeRedefinicao
    >(RedefinicaoDeSenhaControlador.new);

final loginControladorProvider =
    NotifierProvider.autoDispose<LoginControlador, EstadoLogin>(
      LoginControlador.new,
    );
