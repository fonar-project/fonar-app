import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/conexao.dart';
import '../../../l10n/app_strings.dart';
import '../data/bloqueio_por_inatividade.dart';
import '../data/profissional_atual.dart';
import '../data/repositorio_autenticacao_placeholder.dart';

class EstadoDoDesbloqueio {
  const EstadoDoDesbloqueio({this.conferindo = false, this.erro});

  final bool conferindo;

  /// O que dizer embaixo do campo de senha.
  final String? erro;
}

/// Desbloqueia com a senha do profissional desta sessão.
///
/// Sem conexão, a senha não tem com quem ser conferida — e o app vale a
/// mesma regra do "entrar em modo offline" do login, que também não
/// confere. A tela diz isso com todas as letras, em vez de pedir uma senha
/// que ninguém confere.
///
/// TODO(auth): com o Firebase, conferir sem rede por uma credencial local
/// (PIN do app ou biometria do aparelho) — ver `PENDENCIAS.md`.
class DesbloqueioControlador extends Notifier<EstadoDoDesbloqueio> {
  @override
  EstadoDoDesbloqueio build() => const EstadoDoDesbloqueio();

  Future<bool> desbloquear(String senha) async {
    if (state.conferindo) return false;
    final online = ref.read(conexaoOnlineProvider);
    if (online && senha.isEmpty) {
      state = const EstadoDoDesbloqueio(erro: AppStrings.bloqueioInformeSenha);
      return false;
    }

    state = const EstadoDoDesbloqueio(conferindo: true);
    final container = ref.container;
    String? erro;
    if (online) {
      try {
        await ref
            .read(repositorioAutenticacaoProvider)
            .entrar(
              email: ref.read(profissionalAtualProvider).email,
              senha: senha,
            );
      } on CredencialInvalida {
        erro = AppStrings.bloqueioSenhaNaoConfere;
      } on AppException catch (e) {
        erro = e.mensagem;
      } catch (_) {
        erro = AppStrings.erroDesconhecido;
      }
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
