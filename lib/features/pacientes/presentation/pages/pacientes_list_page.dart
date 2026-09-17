import 'package:flutter/material.dart';

import '../../../../design_system/widgets/tela_placeholder.dart';
import '../../../../l10n/app_strings.dart';

/// TODO: implementar lista de pacientes.
class PacientesListPage extends StatelessWidget {
  const PacientesListPage({super.key});

  @override
  Widget build(BuildContext context) => const TelaPlaceholder(
    titulo: AppStrings.pacientesTitulo,
    rota: '/pacientes',
  );
}
