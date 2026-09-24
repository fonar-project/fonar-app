import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';

/// Em que pé está uma etapa: ícone, o que é e o que significa.
///
/// Ex.: "Consentimento não registrado — a gravação fica bloqueada até…".
/// Nunca só cor: o ícone e o título dizem o estado, e o texto diz a
/// consequência ou o que fazer.
///
/// O ícone é roxo, não verde nem vermelho: essas cores são reservadas a
/// status de medida e a saturação de áudio.
class AppSituacao extends StatelessWidget {
  const AppSituacao({
    required this.icone,
    required this.titulo,
    this.texto,
    super.key,
  });

  final NomeIcone icone;
  final String titulo;

  /// Opcional: há situações em que o título já diz tudo.
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcone(nome: icone, cor: AppColors.roxoProfundo, tamanho: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textos.titleMedium),
                if (texto case final texto? when texto.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    texto,
                    style: textos.bodyMedium?.copyWith(
                      color: AppColors.secundarioSobreCreme,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
