import 'package:flutter/material.dart';

import '../../../../design_system/widgets/tela_placeholder.dart';
import '../../../../l10n/app_strings.dart';

/// TODO: implementar exibição do resultado da análise.
///
/// As medidas (f0, jitter, shimmer, HNR, CPPS, AVQI) vêm PRONTAS do servidor.
/// Esta tela só exibe: nenhum cálculo acústico ocorre no app.
/// Nenhum texto aqui pode sugerir diagnóstico.
class AnaliseResultadoPage extends StatelessWidget {
  const AnaliseResultadoPage({
    required this.pacienteId,
    required this.analiseId,
    super.key,
  });

  final String pacienteId;
  final String analiseId;

  @override
  Widget build(BuildContext context) => TelaPlaceholder(
    titulo: AppStrings.analiseResultadoTitulo,
    rota: '/pacientes/$pacienteId/analise/$analiseId',
  );
}
