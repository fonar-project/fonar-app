import 'package:flutter/material.dart';

import '../../../../design_system/widgets/tela_placeholder.dart';
import '../../../../l10n/app_strings.dart';

/// TODO: implementar detalhe do paciente.
class PacienteDetalhePage extends StatelessWidget {
  const PacienteDetalhePage({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  Widget build(BuildContext context) => TelaPlaceholder(
    titulo: AppStrings.pacienteDetalheTitulo,
    rota: '/pacientes/$pacienteId',
  );
}
