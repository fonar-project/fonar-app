import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_movimento.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../l10n/app_strings.dart';

/// Os atalhos de teclado do aplicativo, num diálogo (US50, pela Ajuda).
///
/// Só o que existe: cada linha corresponde a uma tecla tratada no código —
/// a gravação guiada (`gravacao_guiada.dart`) e o espectrograma
/// (`espectrograma_page.dart`). Atalho novo entra lá e aqui.
Future<void> mostrarAtalhosDeTeclado(BuildContext context) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppStrings.atalhosFechar,
      barrierColor: context.cores.barreira,
      transitionDuration: AppMovimento.duracao(context, AppMovimento.rapida),
      pageBuilder: (_, _, _) => const _Atalhos(),
      transitionBuilder: (_, animacao, _, filho) =>
          FadeTransition(opacity: animacao, child: filho),
    );

typedef _Atalho = ({String teclas, String oQueFaz});

const _grupos = <(String, List<_Atalho>)>[
  (
    AppStrings.atalhosEmQualquerTela,
    [
      (teclas: AppStrings.atalhosTab, oQueFaz: AppStrings.atalhosTabTexto),
      (
        teclas: AppStrings.atalhosAtivar,
        oQueFaz: AppStrings.atalhosAtivarTexto,
      ),
      (teclas: AppStrings.atalhosEsc, oQueFaz: AppStrings.atalhosEscTexto),
    ],
  ),
  (
    AppStrings.atalhosNaGravacao,
    [
      (
        teclas: AppStrings.atalhosEspaco,
        oQueFaz: AppStrings.atalhosEspacoTexto,
      ),
      (teclas: AppStrings.atalhosR, oQueFaz: AppStrings.atalhosRTexto),
    ],
  ),
  (
    AppStrings.atalhosNoEspectrograma,
    [
      (teclas: AppStrings.atalhosSetas, oQueFaz: AppStrings.atalhosSetasTexto),
      (teclas: AppStrings.atalhosMais, oQueFaz: AppStrings.atalhosMaisTexto),
      (teclas: AppStrings.atalhosZero, oQueFaz: AppStrings.atalhosZeroTexto),
    ],
  ),
];

class _Atalhos extends StatelessWidget {
  const _Atalhos();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: context.cores.fundo,
            borderRadius: AppRadius.bordaMedia,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: AppStrings.atalhosTitulo,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        AppStrings.atalhosTitulo,
                        style: textos.titleLarge,
                      ),
                    ),
                    for (final (titulo, atalhos) in _grupos) ...[
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        header: true,
                        child: Text(
                          titulo,
                          style: textos.titleSmall?.copyWith(
                            color: context.cores.secundario,
                          ),
                        ),
                      ),
                      for (final atalho in atalhos) _Linha(atalho),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppBotao.primario(
                      rotulo: AppStrings.atalhosFechar,
                      aoTocar: () => Navigator.of(context).pop(),
                      ocupaLargura: true,
                      autofocus: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tecla e o que ela faz, lidas juntas pelo leitor de tela.
class _Linha extends StatelessWidget {
  const _Linha(this.atalho);

  final _Atalho atalho;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        // Proporção, não largura fixa: com o texto do sistema ampliado as
        // duas colunas quebram linha em vez de estourar.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                atalho.teclas,
                style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: Text(atalho.oQueFaz, style: textos.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
