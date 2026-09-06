import 'package:flutter/material.dart';

import '../../../../design_system/widgets/tela_placeholder.dart';
import '../../../../l10n/app_strings.dart';

/// TODO: implementar histórico de avaliações.
class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) => const TelaPlaceholder(
        titulo: AppStrings.historicoTitulo,
        rota: '/historico',
      );
}
