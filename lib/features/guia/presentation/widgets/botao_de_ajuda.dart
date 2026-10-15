import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/passo_do_guia.dart';
import '../alvos_do_guia.dart';
import 'atalhos_de_teclado.dart';

/// O botão de Ajuda (US50): o mesmo em toda tela que o tem — no desktop, no
/// canto direito do cabeçalho das telas principais; no celular, no topo da
/// lista de pacientes.
///
/// Abre um menu com "Rever o guia" e "Atalhos de teclado". Rever o guia leva
/// à lista de pacientes, que é a tela que o guia explica, e o abre lá.
class BotaoDeAjuda extends ConsumerStatefulWidget {
  const BotaoDeAjuda({super.key});

  @override
  ConsumerState<BotaoDeAjuda> createState() => _BotaoDeAjudaState();
}

class _BotaoDeAjudaState extends ConsumerState<BotaoDeAjuda> {
  final _menu = MenuController();
  final _primeiroItem = FocusNode(debugLabel: AppStrings.ajudaReverGuia);

  @override
  void dispose() {
    _primeiroItem.dispose();
    super.dispose();
  }

  void _alternar() {
    if (_menu.isOpen) {
      _menu.close();
      return;
    }
    _menu.open();
    // O foco entra no menu: pelo teclado, a próxima tecla já escolhe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _menu.isOpen) _primeiroItem.requestFocus();
    });
  }

  void _reverGuia() {
    ref.read(pedidoDoGuiaProvider.notifier).pedir();
    context.goNamed(AppRoutes.pacientesNome);
  }

  @override
  Widget build(BuildContext context) {
    final estiloDoItem = ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(context.cores.texto),
      backgroundColor: WidgetStateProperty.resolveWith(
        (estados) =>
            estados.contains(WidgetState.hovered) ||
                estados.contains(WidgetState.focused)
            ? context.cores.veu
            : context.cores.fundo,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: const WidgetStatePropertyAll(
        Size(220, AppSpacing.alvoDeToqueMinimo),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.bodyMedium),
      // Anel de foco de 3 px, como em todo controle: navegar o menu pelo
      // teclado não pode ser adivinhação.
      side: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.focused)
            ? BorderSide(color: context.cores.foco, width: 3)
            : BorderSide.none,
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.bordaPequena),
      ),
    );

    return AlvoDoGuia(
      papel: PapelNoGuia.ajuda,
      child: MenuAnchor(
        controller: _menu,
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(context.cores.fundo),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: context.cores.borda)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.bordaMedia),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.xxs)),
        ),
        menuChildren: [
          MenuItemButton(
            focusNode: _primeiroItem,
            style: estiloDoItem,
            onPressed: _reverGuia,
            child: const Text(AppStrings.ajudaReverGuia),
          ),
          MenuItemButton(
            style: estiloDoItem,
            onPressed: () => mostrarAtalhosDeTeclado(context),
            child: const Text(AppStrings.ajudaAtalhos),
          ),
        ],
        child: AppToque(
          aoTocar: _alternar,
          raio: AppRadius.bordaPequena,
          conteudo: (context) => ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.alvoDeToqueMinimo,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcone(
                    nome: NomeIcone.ajuda,
                    cor: context.cores.acento,
                    tamanho: 22,
                  ),
                  const SizedBox(width: AppSpacing.xxs + 2),
                  Text(
                    AppStrings.ajuda,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.cores.acento,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
