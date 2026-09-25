import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/trilhas.dart';
import '../../../../app/app_estrutura.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../l10n/app_strings.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../widgets/gravacao_guiada.dart';

/// Tela 04 — gravação, guiada por etapas: a aferição de ruído ambiente,
/// cada tarefa do protocolo e a revisão antes de enviar — ver
/// `GravacaoGuiada`.
///
/// A aferição vem antes de qualquer gravação, e existe por dois motivos, e o segundo é o que a torna
/// obrigatória:
///
/// 1. saber se a sala está barulhenta demais antes de gastar a gravação;
/// 2. descobrir o microfone mudo ANTES da consulta, não depois. Silêncio
///    absoluto é tratado como falha e bloqueia a gravação — ver
///    `core/permissions/microphone_permission.dart`.
///
/// Só se chega aqui com consentimento registrado: o roteador bloqueia.
///
/// Leia antes de mexer aqui: a regra de captura no CLAUDE.md.
class CapturaPage extends ConsumerWidget {
  const CapturaPage({required this.pacienteId, super.key});

  final String pacienteId;

  void _voltar(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        AppRoutes.pacienteDetalheNome,
        pathParameters: {AppRoutes.paramPacienteId: pacienteId},
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(pacienteProvider(pacienteId)).value;

    return AppEstrutura(
      destino: DestinoPrincipal.novaAvaliacao,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCabecalhoDeTarefa(
                  titulo: AppStrings.capturaTitulo,
                  aoVoltar: () => _voltar(context),
                  largura: largura,
                  subtitulo: paciente?.nome,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: pacienteId,
                      nome: paciente?.nome,
                    ),
                    ItemDaTrilha(AppStrings.navNovaAvaliacao),
                  ],
                  situacao: AppStrings.situacaoConsentimentoRegistrado,
                ),
                Expanded(child: GravacaoGuiada(pacienteId: pacienteId)),
              ],
            );
          },
        ),
      ),
    );
  }
}
