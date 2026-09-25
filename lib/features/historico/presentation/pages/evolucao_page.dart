import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/trilhas.dart';
import '../../../../app/app_estrutura.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../design_system/widgets/app_status_medida.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/catalogo_de_referencias_vazio.dart';
import '../../../analise/data/repositorio_analises_placeholder.dart';
import '../../../analise/domain/leitura_do_resultado.dart';
import '../../../analise/domain/resultado_da_analise.dart';
import '../../../analise/presentation/apresentacao_da_medida.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../pacientes/domain/paciente.dart';
import '../../data/limiares_de_mudanca_indefinidos.dart';
import '../../domain/evolucao_da_medida.dart';
import '../../domain/serie_da_medida.dart';
import '../leituras_da_sessao.dart';
import '../medida_da_evolucao.dart';
import '../widgets/grafico_de_evolucao.dart';

/// Tela 09 — evolução do paciente entre sessões.
///
/// Só EXIBE valores que o servidor calculou, um por sessão. Os princípios da
/// tela de resultado valem aqui também: apoio à decisão, nunca diagnóstico;
/// faixa de referência só do catálogo; nada dito só por cor.
///
/// E um a mais, próprio da evolução: a tela não diz que uma medida mudou sem
/// um limiar de mudança validado — ver `LimiaresDeMudanca`. Sem ele, os dois
/// últimos valores aparecem lado a lado, e a leitura é do profissional.
class EvolucaoPage extends ConsumerWidget {
  const EvolucaoPage({required this.pacienteId, super.key});

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
    final analises = ref.watch(analisesDoPacienteProvider(pacienteId));
    final paciente = ref.watch(pacienteProvider(pacienteId)).value;

    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);
            final compacta = largura == LarguraDeTela.compacta;

            final Widget conteudo = switch (analises) {
              AsyncData(:final value) => switch (sessoesAnalisadas(value)) {
                [] => AppEstado.central(
                  titulo: AppStrings.evolucaoVaziaTitulo,
                  texto: AppStrings.evolucaoVaziaTexto,
                  acao: AppBotao.secundario(
                    rotulo: AppStrings.voltar,
                    aoTocar: () => _voltar(context),
                  ),
                ),
                final sessoes => _Evolucao(
                  pacienteId: pacienteId,
                  paciente: paciente,
                  sessoes: sessoes,
                  compacta: compacta,
                  expandida: largura == LarguraDeTela.expandida,
                ),
              },
              AsyncError() => AppEstado.central(
                titulo: AppStrings.evolucaoErroCarregar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.tentarNovamente,
                  aoTocar: () =>
                      ref.invalidate(analisesDoPacienteProvider(pacienteId)),
                ),
              ),
              _ => Center(
                child: CircularProgressIndicator(color: context.cores.acento),
              ),
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCabecalhoDeTarefa(
                  titulo: AppStrings.evolucaoTitulo,
                  aoVoltar: () => _voltar(context),
                  largura: largura,
                  subtitulo: paciente?.nome,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: pacienteId,
                      nome: paciente?.nome,
                    ),
                    ItemDaTrilha(AppStrings.evolucaoTitulo),
                  ],
                  // No desktop a ação sobe para o cabeçalho, como no
                  // protótipo; nas outras larguras, fica no corpo.
                  acoes: [
                    if (analises.value case final v?
                        when sessoesAnalisadas(v).isNotEmpty)
                      _MostrarAoPaciente(pacienteId: pacienteId),
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

class _Evolucao extends ConsumerWidget {
  const _Evolucao({
    required this.pacienteId,
    required this.paciente,
    required this.sessoes,
    required this.compacta,
    required this.expandida,
  });

  final String pacienteId;
  final Paciente? paciente;
  final List<ResultadoDaAnalise> sessoes;
  final bool compacta;

  /// Desktop: gráfico e sessões lado a lado, e "mostrar ao paciente" no
  /// cabeçalho.
  final bool expandida;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: context.cores.secundario,
    );
    final medida = ref.watch(medidaDaEvolucaoProvider(pacienteId));
    final serie = serieDe(medida, sessoes);
    final leituras = leiturasDaSessao(
      medida: medida,
      sessoes: sessoes,
      paciente: paciente,
      catalogo: ref.watch(catalogoDeReferenciasProvider),
    );
    final comparacao = compararUltimas(
      serie,
      limiar: ref.watch(limiaresDeMudancaProvider).limiar(medida),
    );
    final faixa = leituras.last?.faixa;
    final motivo = motivoComum(leituras.nonNulls);
    final primeira = sessoes.first.realizadaEm!;
    final ultima = sessoes.last.realizadaEm!;

    // No celular em pé o gráfico fica baixo; deitado, ganha a altura da tela.
    final tela = MediaQuery.sizeOf(context);
    final emPe = MediaQuery.orientationOf(context) == Orientation.portrait;

    // Tela deitada e baixa — o celular virado para ver o gráfico maior, como
    // pede o CLAUDE.md. Aí o gráfico vem primeiro e ocupa a altura que sobra
    // do cabeçalho; o resto da tela continua embaixo, rolando.
    final baixa = !emPe && tela.height < 500;
    final alturaDoGrafico = baixa
        ? (tela.height - 230).clamp(150.0, 420.0)
        : (tela.height * (emPe ? 0.32 : 0.6)).clamp(220.0, 420.0);
    final exemplo = sessoes.any((s) => s.exemplo);

    final abertura = [
      if (exemplo) ...[
        const AppSituacao(
          icone: NomeIcone.informacao,
          titulo: AppStrings.resultadoExemploTitulo,
          texto: AppStrings.resultadoExemploTexto,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      Text(
        AppStrings.evolucaoSessoes(
          sessoes.length,
          AppStrings.data(primeira),
          AppStrings.data(ultima),
        ),
        style: secundario,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(AppStrings.avisoApoioDecisao, style: secundario),
    ];

    final seletor = AppEscolhaUnica<MedidaAcustica>(
      rotulo: AppStrings.evolucaoMedidaNoGrafico,
      opcoes: [
        for (final m in MedidaAcustica.values)
          AppOpcao(valor: m, rotulo: m.nome),
      ],
      selecionado: medida,
      aoEscolher: (m) =>
          ref.read(medidaDaEvolucaoProvider(pacienteId).notifier).escolher(m),
    );

    final comparacaoDasUltimas = _Comparacao(
      medida: medida,
      comparacao: comparacao,
      valores: serie.where((p) => p.valor != null).length,
    );

    final cartao = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        border: Border.all(color: context.cores.borda),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(medida.nome, style: textos.titleLarge),
          ),
          Text(
            medida.unidade.isEmpty
                ? medida.descricao
                : '${medida.descricao}. '
                      '${AppStrings.evolucaoUnidade(medida.unidade)}',
            style: secundario,
          ),
          // Com o gráfico no topo, o aviso de exemplo ficou lá embaixo: uma
          // captura desta tela precisa continuar dizendo que é exemplo.
          if (baixa && exemplo) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                AppIcone(
                  nome: NomeIcone.informacao,
                  cor: context.cores.secundario,
                  tamanho: 16,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    AppStrings.resultadoExemploTitulo,
                    style: secundario,
                  ),
                ),
              ],
            ),
          ],
          if (!baixa) ...[
            const SizedBox(height: AppSpacing.md),
            comparacaoDasUltimas,
          ],
          const SizedBox(height: AppSpacing.lg),
          GraficoDeEvolucao(
            medida: medida,
            pontos: serie,
            faixa: faixa,
            altura: alturaDoGrafico,
          ),
          if (faixa != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.evolucaoFaixaLegenda(medida.descreverFaixa(faixa)),
              style: secundario,
            ),
          ],
          if (compacta && emPe) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(AppStrings.evolucaoGireAparelho, style: secundario),
          ],
          if (baixa) ...[
            const SizedBox(height: AppSpacing.md),
            comparacaoDasUltimas,
          ],
        ],
      ),
    );

    final mostrarAoPaciente = Align(
      alignment: Alignment.centerLeft,
      child: _MostrarAoPaciente(pacienteId: pacienteId),
    );

    final listaDeSessoes = [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Semantics(
          header: true,
          child: Text(
            AppStrings.evolucaoSessoesTitulo,
            style: textos.titleLarge,
          ),
        ),
      ),
      if (motivo != null) ...[
        AppSituacao(
          icone: NomeIcone.semReferencia,
          titulo: AppStrings.statusSemReferencia,
          texto: explicarSemClassificacao(motivo),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      // Da mais recente para a mais antiga: é a ordem em que se procura. O
      // gráfico, ao contrário, lê da esquerda para a direita.
      for (var i = sessoes.length - 1; i >= 0; i--)
        _LinhaDaSessao(
          pacienteId: pacienteId,
          sessao: sessoes[i],
          medida: medida,
          leitura: leituras[i],
          mostrarStatus: motivo == null,
        ),
    ];

    if (expandida && !baixa) {
      // Como no protótipo: o gráfico à esquerda, as sessões à direita, cada
      // coluna rolando por conta própria.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...abertura,
                  const SizedBox(height: AppSpacing.lg),
                  seletor,
                  const SizedBox(height: AppSpacing.lg),
                  cartao,
                ],
              ),
            ),
          ),
          SizedBox(
            width: 400,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: listaDeSessoes,
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: baixa
                ? [
                    cartao,
                    const SizedBox(height: AppSpacing.lg),
                    seletor,
                    const SizedBox(height: AppSpacing.md),
                    mostrarAoPaciente,
                    const SizedBox(height: AppSpacing.xl),
                    ...abertura,
                    const SizedBox(height: AppSpacing.xl),
                    ...listaDeSessoes,
                  ]
                : [
                    ...abertura,
                    const SizedBox(height: AppSpacing.lg),
                    seletor,
                    const SizedBox(height: AppSpacing.lg),
                    cartao,
                    const SizedBox(height: AppSpacing.md),
                    mostrarAoPaciente,
                    const SizedBox(height: AppSpacing.xl),
                    ...listaDeSessoes,
                  ],
          ),
        ),
      ),
    );
  }
}

/// Abre o modo paciente: o gráfico em tela cheia, para virar o aparelho.
class _MostrarAoPaciente extends StatelessWidget {
  const _MostrarAoPaciente({required this.pacienteId});

  final String pacienteId;

  @override
  Widget build(BuildContext context) => AppBotao.secundario(
    rotulo: AppStrings.evolucaoMostrarAoPaciente,
    icone: NomeIcone.virarParaPaciente,
    aoTocar: () => context.goNamed(
      AppRoutes.modoPacienteNome,
      pathParameters: {AppRoutes.paramPacienteId: pacienteId},
    ),
  );
}

/// As duas últimas sessões com valor, lado a lado — e, só se houver limiar de
/// mudança validado, a frase sobre para onde a medida foi.
class _Comparacao extends StatelessWidget {
  const _Comparacao({
    required this.medida,
    required this.comparacao,
    required this.valores,
  });

  final MedidaAcustica medida;
  final ComparacaoDasUltimas? comparacao;

  /// Quantas sessões têm a medida calculada.
  final int valores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: context.cores.secundario,
    );
    final comparacao = this.comparacao;
    if (comparacao == null) {
      // Sem nenhum valor, quem avisa é o próprio gráfico.
      if (valores == 0) return const SizedBox.shrink();
      return Text(AppStrings.evolucaoUmValor, style: secundario);
    }

    final frase = _fraseDaDirecao(comparacao.direcao);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.sm,
          children: [
            _ValorDaSessao(
              rotulo: AppStrings.evolucaoAnterior,
              medida: medida,
              ponto: comparacao.anterior,
            ),
            _ValorDaSessao(
              rotulo: AppStrings.evolucaoMaisRecente,
              medida: medida,
              ponto: comparacao.atual,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (frase == null)
          Text(AppStrings.evolucaoSemLimiar, style: secundario)
        else
          Row(
            children: [
              AppIcone(
                nome: switch (comparacao.direcao) {
                  DirecaoDaMedida.subiu => NomeIcone.tendenciaSobe,
                  DirecaoDaMedida.desceu => NomeIcone.tendenciaDesce,
                  _ => NomeIcone.tendenciaEstavel,
                },
                cor: context.cores.texto,
                tamanho: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(frase, style: textos.bodyMedium)),
            ],
          ),
      ],
    );
  }

  /// A frase sobre a direção, ou `null` quando não há base para ela.
  String? _fraseDaDirecao(DirecaoDaMedida direcao) {
    final palavra = switch (direcao) {
      DirecaoDaMedida.subiu => AppStrings.evolucaoSubiu,
      DirecaoDaMedida.desceu => AppStrings.evolucaoDesceu,
      DirecaoDaMedida.estavel => AppStrings.evolucaoFicouEstavel,
      DirecaoDaMedida.semComparacao => null,
    };
    if (palavra == null) return null;
    final leitura = switch (lerEvolucao(medida: medida, direcao: direcao)) {
      LeituraDaEvolucao.melhora => AppStrings.tendenciaMelhorando,
      LeituraDaEvolucao.piora => AppStrings.tendenciaPiorando,
      // "Ficou estável (estável)" não diz nada a mais.
      LeituraDaEvolucao.estavel || LeituraDaEvolucao.semLeitura => null,
    };
    return AppStrings.evolucaoDirecao(medida.nome, palavra, leitura: leitura);
  }
}

class _ValorDaSessao extends StatelessWidget {
  const _ValorDaSessao({
    required this.rotulo,
    required this.medida,
    required this.ponto,
  });

  final String rotulo;
  final MedidaAcustica medida;
  final PontoDaSerie ponto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: AppTypography.overline.copyWith(
              color: context.cores.secundario,
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.xxs,
            children: [
              Text(
                medida.formatar(ponto.valor!),
                style: AppTypography.medidaCompacta.copyWith(
                  color: context.cores.texto,
                ),
              ),
              if (medida.unidade.isNotEmpty)
                Text(medida.unidade, style: textos.bodyMedium),
            ],
          ),
          Text(
            AppStrings.data(ponto.realizadaEm),
            style: textos.bodySmall?.copyWith(
              color: context.cores.secundario,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma sessão na lista: data, valor e, quando há o que dizer, a
/// classificação. Toca para abrir o resultado completo daquela sessão.
class _LinhaDaSessao extends StatelessWidget {
  const _LinhaDaSessao({
    required this.pacienteId,
    required this.sessao,
    required this.medida,
    required this.leitura,
    required this.mostrarStatus,
  });

  final String pacienteId;
  final ResultadoDaAnalise sessao;
  final MedidaAcustica medida;
  final MedidaLida? leitura;

  /// Falso quando todas as sessões estão sem classificação pelo mesmo motivo,
  /// já dito uma vez acima da lista.
  final bool mostrarStatus;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final valor = leitura?.valor;
    final data = AppStrings.data(sessao.realizadaEm!);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cores.borda)),
      ),
      child: Semantics(
        hint: AppStrings.evolucaoAbrirSessao(data),
        child: AppToque(
          // `push`, não `go`: o resultado não fica embaixo da evolução na
          // árvore de rotas, e o voltar dele precisa trazer o profissional
          // de volta para cá.
          aoTocar: () => context.pushNamed(
            AppRoutes.analiseResultadoNome,
            pathParameters: {
              AppRoutes.paramPacienteId: pacienteId,
              AppRoutes.paramAnaliseId: sessao.id,
            },
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        data,
                        style: textos.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        valor == null
                            ? AppStrings.resultadoNaoCalculada
                            : medida.unidade.isEmpty
                            ? medida.formatar(valor)
                            : '${medida.formatar(valor)} ${medida.unidade}',
                        style: valor == null
                            ? textos.bodyMedium?.copyWith(
                                color: context.cores.secundario,
                              )
                            : textos.titleMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                      ),
                      if (mostrarStatus && valor != null)
                        AppStatusMedida(
                          status: statusDaClassificacao(leitura!.classificacao),
                          compacto: true,
                        ),
                    ],
                  ),
                ),
                AppIcone(
                  nome: NomeIcone.avancar,
                  cor: context.cores.acento,
                  tamanho: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
