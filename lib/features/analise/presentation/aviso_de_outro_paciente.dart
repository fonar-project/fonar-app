import 'package:flutter/material.dart';

import '../../../design_system/widgets/app_botao.dart';
import '../../../design_system/widgets/app_estado.dart';
import '../../../l10n/app_strings.dart';

/// O que resultado, CAPE-V e laudo mostram quando a análise pedida é de
/// outro paciente — ver `daPaciente`. Nada da análise aparece: nem medida,
/// nem formulário.
class AvisoDeOutroPaciente extends StatelessWidget {
  const AvisoDeOutroPaciente({required this.aoVoltar, super.key});

  final VoidCallback aoVoltar;

  @override
  Widget build(BuildContext context) => AppEstado.central(
    titulo: AppStrings.resultadoDeOutroPaciente,
    texto: AppStrings.resultadoDeOutroPacienteTexto,
    acao: AppBotao.secundario(rotulo: AppStrings.voltar, aoTocar: aoVoltar),
  );
}
