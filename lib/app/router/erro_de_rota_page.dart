import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/widgets/app_botao.dart';
import '../../design_system/widgets/app_estado.dart';
import '../../l10n/app_strings.dart';
import 'app_routes.dart';

/// Endereço que não leva a tela nenhuma — um link antigo, uma rota digitada
/// errado no desktop, um paciente que já não existe neste aparelho.
///
/// Em português, com o caminho de volta, no lugar da página padrão do
/// go_router, que mostra a exceção em inglês. O endereço não aparece: pode
/// conter o id de um paciente.
class ErroDeRotaPage extends StatelessWidget {
  const ErroDeRotaPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AppEstado.central(
        titulo: AppStrings.rotaNaoEncontradaTitulo,
        texto: AppStrings.rotaNaoEncontradaTexto,
        acao: AppBotao.primario(
          rotulo: AppStrings.rotaVoltarAoInicio,
          aoTocar: () => context.goNamed(AppRoutes.pacientesNome),
        ),
      ),
    ),
  );
}
