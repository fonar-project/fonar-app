import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../tokens/app_spacing.dart';

/// Andaime temporário das telas do esqueleto.
///
/// TODO: este widget deve DESAPARECER. Cada uso dele é uma tela que ainda não
/// foi implementada — se ele ainda existir no fim do projeto, algo ficou para
/// trás.
class TelaPlaceholder extends StatelessWidget {
  const TelaPlaceholder({required this.titulo, this.rota, super.key});

  final String titulo;

  /// Rota que levou até aqui. Só para orientar durante o desenvolvimento.
  final String? rota;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.telaEmConstrucao,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (rota case final rota?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(rota, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
