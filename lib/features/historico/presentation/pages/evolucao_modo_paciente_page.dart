import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/catalogo_de_referencias_vazio.dart';
import '../../../analise/data/repositorio_analises_placeholder.dart';
import '../../../analise/domain/resultado_da_analise.dart';
import '../../../analise/presentation/apresentacao_da_medida.dart';
import '../../../pacientes/data/repositorio_pacientes_placeholder.dart';
import '../../domain/serie_da_medida.dart';
import '../leituras_da_sessao.dart';
import '../medida_da_evolucao.dart';
import '../widgets/grafico_de_evolucao.dart';

/// Modo paciente: a evolução como o profissional a mostra ao paciente,
/// virando o aparelho para ele.
///
/// Mostra SÓ a medida que o profissional escolheu antes de virar a tela, em
/// tamanho de ler a um braço de distância. Fica de fora tudo o que é conversa
/// do profissional: classificação frente à faixa, leitura de melhora ou piora,
/// queixa, outros pacientes, a navegação do aplicativo. Um paciente olhando
/// para "fora da faixa" sem ninguém explicar é exatamente o diagnóstico que o
/// FONAR não emite.
///
/// A saída fica no alto e diz para quem é: "Voltar à tela do profissional".
/// O voltar do sistema também sai.
///
/// TODO(clínico): o que o paciente vê, e com que palavras — ver o comentário
/// em `AppStrings.modoPacienteTitulo`.
class EvolucaoModoPacientePage extends ConsumerWidget {
  const EvolucaoModoPacientePage({required this.pacienteId, super.key});

  final String pacienteId;

  void _sair(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        AppRoutes.evolucaoNome,
        pathParameters: {AppRoutes.paramPacienteId: pacienteId},
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analises = ref.watch(analisesDoPacienteProvider(pacienteId));
    final sair = AppBotao.secundario(
      rotulo: AppStrings.modoPacienteSair,
      icone: NomeIcone.voltar,
      aoTocar: () => _sair(context),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricoes) {
            final compacta =
                Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.compacta;
            return switch (analises) {
              AsyncData(:final value) => switch (sessoesAnalisadas(value)) {
                [] => AppEstado.central(
                  titulo: AppStrings.evolucaoVaziaTitulo,
                  acao: sair,
                ),
                final sessoes => _ParaOPaciente(
                  pacienteId: pacienteId,
                  sessoes: sessoes,
                  compacta: compacta,
                  sair: sair,
                ),
              },
              AsyncError() => AppEstado.central(
                titulo: AppStrings.evolucaoErroCarregar,
                acao: sair,
              ),
              _ => const Center(
                child: CircularProgressIndicator(color: AppColors.roxoProfundo),
              ),
            };
          },
        ),
      ),
    );
  }
}

class _ParaOPaciente extends ConsumerWidget {
  const _ParaOPaciente({
    required this.pacienteId,
    required this.sessoes,
    required this.compacta,
    required this.sair,
  });

  final String pacienteId;
  final List<ResultadoDaAnalise> sessoes;
  final bool compacta;
  final Widget sair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final medida = ref.watch(medidaDaEvolucaoProvider(pacienteId));
    final serie = serieDe(medida, sessoes);
    final leituras = leiturasDaSessao(
      medida: medida,
      sessoes: sessoes,
      paciente: ref.watch(pacienteProvider(pacienteId)).value,
      catalogo: ref.watch(catalogoDeReferenciasProvider),
    );
    final faixa = leituras.last?.faixa;
    final tela = MediaQuery.sizeOf(context);
    final exemplo = sessoes.any((s) => s.exemplo);

    // Celular deitado: o gráfico logo abaixo da saída, na altura que sobra.
    // Título e explicação descem — ver o mesmo cuidado na tela do
    // profissional.
    final baixa =
        MediaQuery.orientationOf(context) == Orientation.landscape &&
        tela.height < 500;
    final altura = baixa
        ? (tela.height - 170).clamp(160.0, 560.0)
        : (tela.height * 0.5).clamp(260.0, 560.0);

    final medidaEUnidade = Text(
      medida.unidade.isEmpty
          ? '${medida.nome} — ${medida.descricao}'
          : '${medida.nome} — ${medida.descricao} (${medida.unidade})',
      style: textos.titleLarge,
    );

    final apresentacao = [
      if (exemplo) ...[
        const AppSituacao(
          icone: NomeIcone.informacao,
          titulo: AppStrings.resultadoExemploTitulo,
          texto: AppStrings.resultadoExemploTexto,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      Semantics(
        header: true,
        child: Text(
          AppStrings.modoPacienteTitulo,
          style: compacta ? textos.headlineSmall : textos.headlineMedium,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      if (!baixa) ...[medidaEUnidade, const SizedBox(height: AppSpacing.xs)],
      Text(
        AppStrings.modoPacienteExplicacao,
        style: textos.bodyLarge?.copyWith(
          color: AppColors.secundarioSobreCreme,
        ),
      ),
    ];

    final grafico = [
      if (baixa) ...[
        medidaEUnidade,
        if (exemplo)
          Text(
            AppStrings.resultadoExemploTitulo,
            style: textos.bodyMedium?.copyWith(
              color: AppColors.secundarioSobreCreme,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
      ],
      GraficoDeEvolucao(
        medida: medida,
        pontos: serie,
        faixa: faixa,
        altura: altura,
        grande: true,
      ),
      if (faixa != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.evolucaoFaixaLegenda(medida.descreverFaixa(faixa)),
          style: textos.bodyMedium?.copyWith(
            color: AppColors.secundarioSobreCreme,
          ),
        ),
      ],
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: sair),
              const SizedBox(height: AppSpacing.lg),
              if (baixa) ...[
                ...grafico,
                const SizedBox(height: AppSpacing.lg),
                ...apresentacao,
              ] else ...[
                ...apresentacao,
                const SizedBox(height: AppSpacing.lg),
                ...grafico,
              ],
              const SizedBox(height: AppSpacing.lg),
              // Na ordem do gráfico, da esquerda para a direita.
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: [
                  for (final ponto in serie)
                    MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.data(ponto.realizadaEm),
                            style: textos.bodyLarge?.copyWith(
                              color: AppColors.secundarioSobreCreme,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            switch (ponto.valor) {
                              null => AppStrings.resultadoNaoCalculada,
                              final v when medida.unidade.isEmpty =>
                                medida.formatar(v),
                              final v =>
                                '${medida.formatar(v)} ${medida.unidade}',
                            },
                            style: ponto.valor == null
                                ? textos.titleMedium
                                : AppTypography.medida.copyWith(
                                    color: AppColors.cinzaChumbo,
                                  ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
