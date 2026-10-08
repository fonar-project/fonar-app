import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../l10n/app_strings.dart';
import 'app_routes.dart';

/// Os passos da trilha do cabeçalho que se repetem entre as telas — ver
/// `AppCabecalhoDeTarefa`. Cada tela junta os seus e termina no passo atual,
/// sem link.
abstract final class Trilhas {
  /// "Pacientes", para a lista.
  static ItemDaTrilha pacientes(BuildContext context) => ItemDaTrilha(
    AppStrings.navPacientes,
    aoTocar: () => context.goNamed(AppRoutes.pacientesNome),
  );

  /// O nome do paciente, para o perfil dele. Enquanto o nome não carrega,
  /// "Paciente".
  static ItemDaTrilha paciente(
    BuildContext context, {
    required String pacienteId,
    required String? nome,
  }) => ItemDaTrilha(
    nome ?? AppStrings.pacienteDetalheTitulo,
    aoTocar: () => context.goNamed(
      AppRoutes.pacienteDetalheNome,
      pathParameters: {AppRoutes.paramPacienteId: pacienteId},
    ),
  );

  /// "Resultado da análise", para a tela do resultado.
  static ItemDaTrilha resultado(
    BuildContext context, {
    required String pacienteId,
    required String analiseId,
  }) => ItemDaTrilha(
    AppStrings.analiseResultadoTitulo,
    aoTocar: () => context.goNamed(
      AppRoutes.analiseResultadoNome,
      pathParameters: {
        AppRoutes.paramPacienteId: pacienteId,
        AppRoutes.paramAnaliseId: analiseId,
      },
    ),
  );

  /// Pacientes / nome do paciente — o começo de quase toda trilha.
  static List<ItemDaTrilha> doPaciente(
    BuildContext context, {
    required String pacienteId,
    required String? nome,
  }) => [
    pacientes(context),
    paciente(context, pacienteId: pacienteId, nome: nome),
  ];
}
