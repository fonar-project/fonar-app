import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/health_check_provider.dart';
import '../../../../core/network/health_check_repository.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_strings.dart';

/// Tela de diagnóstico que exibe o status de conectividade com a API.
///
/// Não é voltada ao paciente — é ferramenta interna para o fonoaudiólogo (ou
/// para quem está implantando) confirmar que a API Python no Cloud Run está
/// acessível antes de iniciar gravações e análises.
class HealthCheckPage extends ConsumerWidget {
  const HealthCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultado = ref.watch(healthCheckProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.healthCheckTitulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: resultado.when(
            loading: () => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text(AppStrings.healthCheckVerificando),
              ],
            ),
            error: (_, __) => _StatusCard(
              online: false,
              theme: theme,
              onTentarNovamente: () =>
                  ref.invalidate(healthCheckProvider),
            ),
            data: (check) => _StatusCard(
              online: check.online,
              tempoRespostaMs: check.tempoRespostaMs,
              versaoApi: check.versaoApi,
              theme: theme,
              onTentarNovamente: () =>
                  ref.invalidate(healthCheckProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.online,
    required this.theme,
    required this.onTentarNovamente,
    this.tempoRespostaMs,
    this.versaoApi,
  });

  final bool online;
  final int? tempoRespostaMs;
  final String? versaoApi;
  final ThemeData theme;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final cor = online ? AppColors.sucesso : AppColors.erro;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              online ? Icons.check_circle_outline : Icons.error_outline,
              size: 64,
              color: cor,
              semanticLabel:
                  online ? AppStrings.healthCheckOnline : AppStrings.healthCheckOffline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              online ? AppStrings.healthCheckOnline : AppStrings.healthCheckOffline,
              style: theme.textTheme.headlineSmall?.copyWith(color: cor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              online
                  ? AppStrings.healthCheckDescricaoOnline
                  : AppStrings.healthCheckDescricaoOffline,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (tempoRespostaMs != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${AppStrings.healthCheckTempo} ${tempoRespostaMs}ms',
                style: theme.textTheme.labelMedium,
              ),
            ],
            if (versaoApi != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${AppStrings.healthCheckVersaoApi} $versaoApi',
                style: theme.textTheme.labelMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.healthCheckTentarNovamente),
            ),
          ],
        ),
      ),
    );
  }
}
