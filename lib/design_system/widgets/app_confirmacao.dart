import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_botao.dart';

/// Pergunta antes de uma ação que não se desfaz, e devolve `true` só se a
/// pessoa confirmou.
///
/// O caminho seguro é o principal e o que vale por padrão: tocar fora, a
/// tecla Esc ou o voltar do sistema respondem [cancelar], nunca [confirmar].
/// Nada de vermelho: a gravidade está no texto, que diz o que se perde.
///
/// Sem animação de entrada quando o sistema pede menos movimento.
Future<bool> appConfirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String confirmar,
  required String cancelar,
}) async {
  final semMovimento = MediaQuery.disableAnimationsOf(context);
  final resposta = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelar,
    barrierColor: AppColors.cinzaChumbo.withValues(alpha: 0.4),
    transitionDuration: semMovimento
        ? Duration.zero
        : const Duration(milliseconds: 150),
    pageBuilder: (context, _, _) => _Confirmacao(
      titulo: titulo,
      texto: texto,
      confirmar: confirmar,
      cancelar: cancelar,
    ),
    transitionBuilder: (context, animacao, _, filho) =>
        FadeTransition(opacity: animacao, child: filho),
  );
  return resposta ?? false;
}

class _Confirmacao extends StatelessWidget {
  const _Confirmacao({
    required this.titulo,
    required this.texto,
    required this.confirmar,
    required this.cancelar,
  });

  final String titulo;
  final String texto;
  final String confirmar;
  final String cancelar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            color: AppColors.creme,
            borderRadius: AppRadius.bordaMedia,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: titulo,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(titulo, style: textos.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(texto, style: textos.bodyLarge),
                    const SizedBox(height: AppSpacing.lg),
                    // O seguro em cima, onde o olho chega primeiro.
                    AppBotao.primario(
                      rotulo: cancelar,
                      aoTocar: () => Navigator.of(context).pop(false),
                      ocupaLargura: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppBotao.secundario(
                      rotulo: confirmar,
                      aoTocar: () => Navigator.of(context).pop(true),
                      ocupaLargura: true,
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
