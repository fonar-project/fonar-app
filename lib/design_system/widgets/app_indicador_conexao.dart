import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';

/// Indicador de conexão, sempre visível no cabeçalho.
///
/// Não é enfeite: gravação funciona offline, análise exige conexão. O
/// profissional precisa saber, ANTES de começar a consulta, se o resultado vai
/// sair hoje ou entrar na fila. Descobrir isso depois de gravar é perder a
/// amostra e o tempo do paciente.
///
/// Ícone e texto sempre juntos — um ponto colorido no canto não comunica
/// estado de conexão para quem não distingue verde de cinza.
class AppIndicadorConexao extends StatelessWidget {
  const AppIndicadorConexao({
    required this.online,
    this.sobreFundoEscuro = false,
    super.key,
  });

  final bool online;

  /// No cabeçalho roxo o indicador inverte: creme sobre roxo. A cor de status
  /// perde contraste ali, então quem diferencia é o ícone mais o texto.
  final bool sobreFundoEscuro;

  @override
  Widget build(BuildContext context) {
    final cor = sobreFundoEscuro
        ? AppColors.creme
        : (online ? AppColors.sucesso : AppColors.secundarioSobreCreme);

    final texto = online ? AppStrings.conexaoOnline : AppStrings.conexaoOffline;

    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: sobreFundoEscuro
              ? AppColors.creme.withValues(alpha: 0.12)
              : cor.withValues(alpha: 0.10),
          borderRadius: AppRadius.bordaPequena,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcone(
              nome: online
                  ? NomeIcone.estadoOnline
                  : NomeIcone.estadoSemConexao,
              cor: cor,
              tamanho: 16,
            ),
            const SizedBox(width: AppSpacing.xxs + 2),
            Text(
              texto,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: cor),
            ),
          ],
        ),
      ),
    );
  }
}
