import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/senha_sem_rede.dart';
import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../cadastro/presentation/entrada.dart';
import '../data/repositorio_autenticacao_firebase.dart';
import '../data/sessao.dart';
import '../data/sessao_mantida.dart';
import '../domain/conta_autenticada.dart';

/// Estado do formulário de login.
class EstadoLogin {
  const EstadoLogin({
    this.carregando = false,
    this.erroEmail,
    this.erroSenha,
    this.erroGeral,
    this.erroSemRede,
  });

  final bool carregando;
  final String? erroEmail;

  /// Também recebe a credencial recusada: o protótipo marca o campo de senha,
  /// que é o que o usuário vai redigitar.
  final String? erroSenha;

  /// Falha que não pertence a um campo — rede, servidor, conta pausada.
  final String? erroGeral;

  /// O que dizer no campo de senha da entrada sem rede (US43).
  final String? erroSemRede;
}

class LoginControlador extends Notifier<EstadoLogin> {
  @override
  EstadoLogin build() => const EstadoLogin();

  /// Tenta entrar. Devolve para onde ir quando a senha conferiu — os
  /// pacientes, ou o passo que falta do primeiro acesso (confirmar o e-mail,
  /// preencher o cadastro) —, e `null` quando não entrou. A navegação fica
  /// com a tela, que é quem tem o `BuildContext`.
  ///
  /// Com [manterConectado] (US59), a sessão que abrir daqui abre sozinha nas
  /// próximas aberturas do app, até a pessoa sair. Só quando ela abre de
  /// fato: quem ainda vai confirmar o e-mail ou completar o cadastro não
  /// pula esses passos na abertura seguinte.
  Future<DestinoDaEntrada?> entrar({
    required String email,
    required String senha,
    bool manterConectado = false,
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
    final senhas = ref.read(senhaSemRedeProvider);
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

    // A senha conferiu: o verificador dela fica no aparelho, para a entrada
    // sem rede (US43). Não segura a entrada.
    unawaited(senhas.lembrar(conta.uid, senha));

    // Falta saber em que pé está o cadastro. O botão continua em
    // "Entrando…" enquanto a API responde.
    final destino = await conferirCadastro(ref);
    if (!ref.mounted) return null;
    if (manterConectado && destino is EntrarNoApp) {
      await _manter(conta.uid);
      if (!ref.mounted) return null;
    }
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

  /// Marca a credencial recém-guardada para abrir sozinha. Se o cofre
  /// falhar, entra do mesmo jeito: a próxima abertura só pede a senha.
  Future<void> _manter(String uid) async {
    try {
      await ref.read(sessaoMantidaProvider).manter(uid);
    } catch (erro) {
      debugPrint('Não foi possível manter a sessão: $erro');
    }
  }

  /// Entra sem conexão, com a conta da última entrada com senha neste
  /// aparelho. A sessão abre do mesmo jeito: a fila espera a rede, não um
  /// novo login. Devolve `false` se não entrou.
  ///
  /// A [senha] é conferida com o verificador que a última entrada com rede
  /// guardou (US43, [SenhaSemRede]). Antes, entrava sem senha nenhuma: os
  /// dados de saúde do aparelho abriam para quem o tivesse na mão.
  Future<bool> entrarOffline(String senha) async {
    if (state.carregando) return false;
    if (senha.isEmpty) {
      state = const EstadoLogin(erroSemRede: AppStrings.loginInformeSenha);
      return false;
    }
    state = const EstadoLogin(carregando: true);
    final senhas = ref.read(senhaSemRedeProvider);
    final ContaAutenticada? conta;
    final ConferenciaSemRede conferencia;
    try {
      conta = await ref.read(repositorioAutenticacaoProvider).contaGuardada();
      conferencia = conta == null
          ? ConferenciaSemRede.semRegistro
          : await senhas.conferir(conta.uid, senha);
    } catch (_) {
      if (ref.mounted) {
        state = const EstadoLogin(erroGeral: AppStrings.erroDesconhecido);
      }
      return false;
    }
    if (!ref.mounted) return false;
    switch (conferencia) {
      case ConferenciaSemRede.confere when conta != null:
        state = const EstadoLogin();
        ref.read(sessaoProvider.notifier).abrir(conta);
        return true;
      case ConferenciaSemRede.naoConfere:
        state = const EstadoLogin(
          erroSemRede: AppStrings.loginSemRedeSenhaNaoConfere,
        );
      case _:
        state = const EstadoLogin(
          erroSemRede: AppStrings.loginSemRedeSemSenhaGuardada,
        );
    }
    return false;
  }
}

/// A conta com que o modo offline entraria — a da última entrada com senha
/// neste aparelho —, ou `null`.
final contaGuardadaProvider = FutureProvider.autoDispose<ContaAutenticada?>(
  (ref) => ref.watch(repositorioAutenticacaoProvider).contaGuardada(),
);

final loginControladorProvider =
    NotifierProvider.autoDispose<LoginControlador, EstadoLogin>(
      LoginControlador.new,
    );
