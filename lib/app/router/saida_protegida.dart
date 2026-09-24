import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/widgets/app_confirmacao.dart';
import '../../l10n/app_strings.dart';

/// Os formulários abertos com alterações que ainda não foram salvas, por
/// chave ([chaveDoCadastro], [chaveDaEdicao]).
///
/// Quem sabe se o formulário mudou é a tela; quem pergunta antes de sair é o
/// roteador ([confirmarSaida]) — por qualquer caminho: voltar do sistema,
/// botão de voltar, "Cancelar" ou a navegação principal.
class FormulariosAlterados extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Nada mais conta como alterado — quem sai da conta já decidiu perder o
  /// que estava pela metade.
  void esquecerTodos() => state = const {};

  void marcar(String chave, {required bool alterado}) {
    if (state.contains(chave) == alterado) return;
    state = alterado ? {...state, chave} : ({...state}..remove(chave));
  }
}

final formulariosAlteradosProvider =
    NotifierProvider<FormulariosAlterados, Set<String>>(
      FormulariosAlterados.new,
    );

const chaveDoCadastro = 'cadastro';
String chaveDaEdicao(String pacienteId) => 'edicao:$pacienteId';

/// O `onExit` de uma rota com formulário: com alteração não salva, pergunta
/// antes de sair — e sair descarta.
///
/// Com o paciente ao lado e pouco tempo, um toque errado no voltar apagaria
/// o cadastro inteiro digitado.
ExitCallback confirmarSaida(Ref ref, String Function(GoRouterState) chave) =>
    (context, state) async {
      final k = chave(state);
      if (!ref.read(formulariosAlteradosProvider).contains(k)) return true;
      final sair = await appConfirmar(
        context,
        titulo: AppStrings.saidaTitulo,
        texto: AppStrings.saidaTexto,
        confirmar: AppStrings.saidaDescartar,
        cancelar: AppStrings.saidaContinuar,
      );
      if (sair) {
        ref
            .read(formulariosAlteradosProvider.notifier)
            .marcar(k, alterado: false);
      }
      return sair;
    };
