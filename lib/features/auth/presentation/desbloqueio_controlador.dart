import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/senha_sem_rede.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/conexao.dart';
import '../../../l10n/app_strings.dart';
import '../data/bloqueio_por_inatividade.dart';
import '../data/repositorio_autenticacao_firebase.dart';
import '../data/sessao.dart';

class EstadoDoDesbloqueio {
  const EstadoDoDesbloqueio({this.conferindo = false, this.erro});

  final bool conferindo;

  /// O que dizer embaixo do campo de senha.
  final String? erro;
}

/// Desbloqueia com a senha do profissional desta sessão.
///
/// Com conexão, quem confere é o Firebase. Sem conexão (US43), o verificador
/// que a última entrada com rede guardou no aparelho ([SenhaSemRede]) — a
/// mesma senha, nunca um atalho. Sem verificador desta conta, sem rede não
/// se desbloqueia: o profissional espera a conexão ou sai da conta.
class DesbloqueioControlador extends Notifier<EstadoDoDesbloqueio> {
  @override
  EstadoDoDesbloqueio build() => const EstadoDoDesbloqueio();

  Future<bool> desbloquear(String senha) async {
    if (state.conferindo) return false;
    final online = ref.read(conexaoOnlineProvider);
    if (senha.isEmpty) {
      state = const EstadoDoDesbloqueio(erro: AppStrings.bloqueioInformeSenha);
      return false;
    }

    state = const EstadoDoDesbloqueio(conferindo: true);
    final container = ref.container;
    // Lido antes das esperas: a tela pode fechar no meio delas.
    final senhas = ref.read(senhaSemRedeProvider);
    String? erro;
    final conta = ref.read(sessaoProvider);
    if (online && conta != null) {
      try {
        final conferida = await ref
            .read(repositorioAutenticacaoProvider)
            .entrar(email: conta.email, senha: senha);
        // O e-mail é o da sessão, então a conta é a mesma — conferido assim
        // mesmo: desbloquear com a senha de outra pessoa seria abrir os
        // dados desta para ela.
        if (conferida.uid != conta.uid) {
          erro = AppStrings.bloqueioSenhaNaoConfere;
        }
        if (erro == null) {
          unawaited(senhas.lembrar(conta.uid, senha));
        }
      } on CredencialInvalida {
        erro = AppStrings.bloqueioSenhaNaoConfere;
      } on AppException catch (e) {
        erro = e.mensagem;
      } catch (_) {
        erro = AppStrings.erroDesconhecido;
      }
    } else if (conta != null) {
      erro = switch (await senhas.conferir(conta.uid, senha)) {
        ConferenciaSemRede.confere => null,
        ConferenciaSemRede.naoConfere => AppStrings.bloqueioSenhaNaoConfere,
        ConferenciaSemRede.semRegistro =>
          AppStrings.bloqueioSemRedeSemSenhaGuardada,
      };
    } else {
      erro = AppStrings.erroDesconhecido;
    }

    if (erro == null) {
      container.read(bloqueioPorInatividadeProvider.notifier).desbloquear();
    }
    if (ref.mounted) state = EstadoDoDesbloqueio(erro: erro);
    return erro == null;
  }
}

final desbloqueioControladorProvider =
    NotifierProvider.autoDispose<DesbloqueioControlador, EstadoDoDesbloqueio>(
      DesbloqueioControlador.new,
    );
