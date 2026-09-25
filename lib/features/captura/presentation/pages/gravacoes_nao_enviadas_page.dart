import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/trilhas.dart';
import '../../../../app/app_estrutura.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../consentimento/data/repositorio_consentimento_local.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../reproducao/presentation/widgets/player_de_amostra.dart';
import '../../domain/amostra.dart';
import '../../domain/sessao_nao_enviada.dart';
import '../gravacoes_nao_enviadas_controlador.dart';

/// As sessões de um paciente que ficaram no aparelho sem ir para a análise.
///
/// Voz de paciente não fica esquecida no disco: aqui o profissional ouve,
/// manda para a análise a sessão completa, ou descarta. Descartar pede
/// confirmação na própria sessão — apaga áudio de paciente, e não se desfaz.
class GravacoesNaoEnviadasPage extends ConsumerWidget {
  const GravacoesNaoEnviadasPage({required this.pacienteId, super.key});

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
    final sessoes = ref.watch(sessoesNaoEnviadasProvider(pacienteId));
    final paciente = ref.watch(pacienteProvider(pacienteId)).value;
    final textos = Theme.of(context).textTheme;

    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);
            final compacta = largura == LarguraDeTela.compacta;

            final Widget conteudo = switch (sessoes) {
              AsyncData(value: final lista) when lista.isEmpty =>
                AppEstado.central(
                  titulo: AppStrings.naoEnviadasVazia,
                  acao: AppBotao.secundario(
                    rotulo: AppStrings.retiradaVoltarAoPaciente,
                    aoTocar: () => _voltar(context),
                  ),
                ),
              AsyncData(value: final lista) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (paciente != null)
                          Text(
                            AppStrings.consentimentoPaciente(paciente.nome),
                            style: textos.titleMedium,
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          AppStrings.naoEnviadasExplicacao,
                          style: textos.bodyMedium?.copyWith(
                            color: AppColors.secundarioSobreCreme,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (final sessao in lista) ...[
                          _CartaoDaSessao(
                            pacienteId: pacienteId,
                            nomeDoPaciente: paciente?.nome ?? '',
                            sessao: sessao,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              AsyncError() => AppEstado.central(
                titulo: AppStrings.naoEnviadasErroCarregar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.tentarNovamente,
                  aoTocar: () =>
                      ref.invalidate(sessoesNaoEnviadasProvider(pacienteId)),
                ),
              ),
              _ => const Center(
                child: CircularProgressIndicator(color: AppColors.roxoProfundo),
              ),
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCabecalhoDeTarefa(
                  titulo: AppStrings.naoEnviadasTitulo,
                  aoVoltar: () => _voltar(context),
                  largura: largura,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: pacienteId,
                      nome: paciente?.nome,
                    ),
                    ItemDaTrilha(AppStrings.naoEnviadasTitulo),
                  ],
                ),
                Expanded(child: conteudo),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartaoDaSessao extends ConsumerWidget {
  const _CartaoDaSessao({
    required this.pacienteId,
    required this.nomeDoPaciente,
    required this.sessao,
  });

  final String pacienteId;
  final String nomeDoPaciente;
  final SessaoNaoEnviada sessao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final estado = ref.watch(limpezaControladorProvider(pacienteId));
    final controlador = ref.read(
      limpezaControladorProvider(pacienteId).notifier,
    );
    final ocupada = estado.ocupada != null;
    final confirmando = estado.confirmando == sessao.sessaoId;
    final erro = estado.erro?.sessaoId == sessao.sessaoId
        ? estado.erro!.mensagem
        : null;
    // Fail-closed, como a gravação: só com consentimento em vigor.
    final comConsentimento =
        ref.watch(consentimentoProvider(pacienteId)).value != null;
    final inicio = sessao.gravadaEm;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.naoEnviadasSessao(
                AppStrings.data(inicio),
                AppStrings.hora(inicio),
              ),
              style: textos.titleSmall,
            ),
          ),
          Text(
            AppStrings.naoEnviadasTarefas(
              sessao.amostras.length,
              TarefaDeGravacao.values.length,
            ),
            style: textos.bodySmall?.copyWith(
              color: AppColors.secundarioSobreCreme,
            ),
          ),
          for (final tarefa in TarefaDeGravacao.values)
            if (sessao.amostras[tarefa] case final amostra?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_nomeDaTarefa(tarefa), style: textos.bodyMedium),
              if (sessao.semArquivo.contains(tarefa))
                const AppSituacao(
                  icone: NomeIcone.alerta,
                  titulo: AppStrings.naoEnviadasSemArquivo,
                )
              else
                PlayerDeAmostra(
                  caminho: amostra.caminho,
                  rotulo: _nomeDaTarefa(tarefa),
                  duracaoConhecida: amostra.duracao,
                ),
            ],
          const SizedBox(height: AppSpacing.md),
          if (confirmando) ...[
            AppSituacao(
              icone: NomeIcone.alerta,
              titulo: AppStrings.naoEnviadasConfirmar(sessao.amostras.length),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppBotao.secundario(
                  rotulo: AppStrings.naoEnviadasManter,
                  aoTocar: ocupada ? null : controlador.manter,
                  motivoDesabilitado: AppStrings.naoEnviadasDescartando,
                ),
                AppBotao.secundario(
                  rotulo: AppStrings.naoEnviadasDescartarDeVez,
                  aoTocar: ocupada ? null : () => controlador.descartar(sessao),
                  motivoDesabilitado: AppStrings.naoEnviadasDescartando,
                ),
              ],
            ),
          ] else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppBotao.secundario(
                  rotulo: AppStrings.naoEnviadasEnviar,
                  icone: NomeIcone.avancar,
                  aoTocar: sessao.completa && comConsentimento && !ocupada
                      ? () => controlador.enviar(
                          sessao,
                          nomeDoPaciente: nomeDoPaciente,
                        )
                      : null,
                  motivoDesabilitado: sessao.semArquivo.isNotEmpty
                      ? AppStrings.naoEnviadasFaltaArquivo
                      : !sessao.completa
                      ? AppStrings.naoEnviadasIncompleta
                      : !comConsentimento
                      ? AppStrings.naoEnviadasSemConsentimento
                      : AppStrings.naoEnviadasOcupada,
                ),
                AppBotao.secundario(
                  rotulo: AppStrings.naoEnviadasDescartar,
                  aoTocar: ocupada
                      ? null
                      : () => controlador.pedirDescarte(sessao.sessaoId),
                  motivoDesabilitado: AppStrings.naoEnviadasOcupada,
                ),
              ],
            ),
          if (erro != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSituacao(icone: NomeIcone.alerta, titulo: erro),
          ],
        ],
      ),
    );
  }
}

String _nomeDaTarefa(TarefaDeGravacao tarefa) => switch (tarefa) {
  TarefaDeGravacao.vogalSustentada => AppStrings.tarefaVogalTitulo,
  TarefaDeGravacao.falaEncadeada => AppStrings.tarefaFalaTitulo,
};
