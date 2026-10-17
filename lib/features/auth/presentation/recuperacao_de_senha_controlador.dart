import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../data/repositorio_autenticacao_firebase.dart';

/// Em que pé está o pedido do link para criar uma senha nova.
class EstadoDaRecuperacao {
  const EstadoDaRecuperacao({
    this.enviando = false,
    this.enviadoPara,
    this.erroDoEmail,
    this.erroGeral,
  });

  final bool enviando;

  /// O e-mail para o qual o pedido saiu. Preenchido, a tela troca o
  /// formulário pela confirmação.
  final String? enviadoPara;

  /// O que corrigir no campo: vazio, ou um endereço que o Firebase recusou.
  final String? erroDoEmail;

  /// Falha que não é do campo — rede, servidor, pedidos demais.
  final String? erroGeral;

  bool get enviado => enviadoPara != null;
}

/// "Esqueci a senha": pede ao Firebase o e-mail com o link de redefinição.
///
/// A resposta é a mesma exista ou não conta para o e-mail: dizer "não há
/// conta" seria dizer a qualquer um quem usa o FONAR (CLAUDE.md,
/// "Autenticação"). Por isso só o e-mail vazio e o mal formado viram erro do
/// campo.
class RecuperacaoDeSenhaControlador extends Notifier<EstadoDaRecuperacao> {
  @override
  EstadoDaRecuperacao build() => const EstadoDaRecuperacao();

  /// O profissional mexeu no e-mail: o erro de antes sai.
  void editou() {
    if (state.erroDoEmail == null && state.erroGeral == null) return;
    state = const EstadoDaRecuperacao();
  }

  /// Pede o link. Com o e-mail em branco, nem tenta: o erro é do campo.
  Future<void> pedir(String email) async {
    if (state.enviando) return;
    final limpo = email.trim();
    if (limpo.isEmpty) {
      state = const EstadoDaRecuperacao(
        erroDoEmail: AppStrings.recuperarInformeEmail,
      );
      return;
    }
    state = const EstadoDaRecuperacao(enviando: true);
    EstadoDaRecuperacao fim;
    try {
      await ref
          .read(repositorioAutenticacaoProvider)
          .pedirRedefinicaoDeSenha(limpo);
      fim = EstadoDaRecuperacao(enviadoPara: limpo);
    } on CredencialInvalida {
      fim = const EstadoDaRecuperacao(
        erroDoEmail: AppStrings.loginRecuperacaoEmailInvalido,
      );
    } on AppException catch (e) {
      fim = EstadoDaRecuperacao(erroGeral: e.mensagem);
    } catch (_) {
      fim = const EstadoDaRecuperacao(erroGeral: AppStrings.erroDesconhecido);
    }
    if (ref.mounted) state = fim;
  }

  /// "Usar outro e-mail": volta ao formulário.
  void outroEmail() => state = const EstadoDaRecuperacao();
}

final recuperacaoDeSenhaProvider =
    NotifierProvider.autoDispose<
      RecuperacaoDeSenhaControlador,
      EstadoDaRecuperacao
    >(RecuperacaoDeSenhaControlador.new);
