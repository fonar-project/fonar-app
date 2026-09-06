import 'package:flutter/material.dart';

import '../../../../design_system/widgets/tela_placeholder.dart';
import '../../../../l10n/app_strings.dart';

/// TODO: implementar captura de áudio — módulo de maior risco do projeto.
///
/// Antes de escrever qualquer linha aqui, ler:
///  - a regra de captura no CLAUDE.md (ganho automático, supressão de ruído e
///    cancelamento de eco DESLIGADOS; WAV PCM; verificar empiricamente o que
///    saiu);
///  - o TODO de risco em `core/permissions/microphone_permission.dart`, sobre
///    gravação muda no Windows.
class CapturaPage extends StatelessWidget {
  const CapturaPage({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  Widget build(BuildContext context) => TelaPlaceholder(
        titulo: AppStrings.capturaTitulo,
        rota: '/pacientes/$pacienteId/captura',
      );
}
