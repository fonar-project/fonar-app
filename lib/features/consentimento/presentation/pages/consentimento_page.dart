import 'package:flutter/material.dart';

import '../../../../design_system/widgets/tela_placeholder.dart';
import '../../../../l10n/app_strings.dart';

/// TODO: implementar registro de consentimento (LGPD).
///
/// Enquanto não houver consentimento registrado para o paciente, a captura
/// fica bloqueada tecnicamente — ver o TODO de redirect em `app_router.dart`.
class ConsentimentoPage extends StatelessWidget {
  const ConsentimentoPage({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  Widget build(BuildContext context) => TelaPlaceholder(
    titulo: AppStrings.consentimentoTitulo,
    rota: '/pacientes/$pacienteId/consentimento',
  );
}
