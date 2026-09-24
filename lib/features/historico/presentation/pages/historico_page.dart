import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_estrutura.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_secao.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/domain/resultado_da_analise.dart';
import '../../../analise/presentation/apresentacao_da_medida.dart';
import '../../domain/entrada_do_historico.dart';
import '../../domain/evolucao_da_medida.dart';
import '../historico_controlador.dart';

/// O histórico geral: as avaliações de todos os pacientes, da mais recente
/// para a mais antiga, agrupadas por mês.
///
/// Serve para achar uma avaliação pelo quando, não pelo quem — "a de ontem à
/// tarde", "as de agosto". Pelo quem, o caminho é o perfil do paciente.
///
/// Mostra o AVQI como número, e só: sem faixa de referência validada, nada
/// aqui diz se ele está bom ou ruim. A leitura fica no resultado.
class HistoricoPage extends ConsumerWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historico = ref.watch(historicoProvider);
    final termo = ref.watch(buscaDoHistoricoProvider).trim();
    final textos = Theme.of(context).textTheme;

    return AppEstrutura(
      destino: DestinoPrincipal.historico,
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final largura = Breakpoints.de(restricoes.maxWidth);
          final compacta = largura == LarguraDeTela.compacta;
          final margem = compacta ? AppSpacing.md : AppSpacing.xl;

          // Descrição e busca rolam junto com a lista: com o texto do
          // sistema grande, fixas em cima, não sobraria altura para ela.
          final topo = SliverPadding(
            padding: EdgeInsets.fromLTRB(
              margem,
              AppSpacing.md,
              margem,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.historicoDescricao,
                    style: textos.bodyMedium?.copyWith(
                      color: AppColors.secundarioSobreCreme,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _CampoBusca(),
                ],
              ),
            ),
          );

          Widget estado(Widget filho) =>
              SliverFillRemaining(hasScrollBody: false, child: filho);

          final Widget corpo = switch (historico) {
            AsyncData(value: final todas) when todas.isEmpty => estado(
              AppEstado.central(
                titulo: AppStrings.historicoVazioTitulo,
                texto: AppStrings.historicoVazioTexto,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.navNovaAvaliacao,
                  icone: NomeIcone.adicionar,
                  aoTocar: () => context.goNamed(AppRoutes.novaAvaliacaoNome),
                ),
              ),
            ),
            AsyncData(value: final todas) => switch (montarHistorico(
              todas,
              termo: termo,
            )) {
              final vazia when vazia.isEmpty => estado(
                AppEstado.central(
                  titulo: AppStrings.historicoSemResultado(termo),
                  acao: AppBotao.secundario(
                    rotulo: AppStrings.historicoLimparBusca,
                    aoTocar: () =>
                        ref.read(buscaDoHistoricoProvider.notifier).digitar(''),
                  ),
                ),
              ),
              final entradas => SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  margem,
                  AppSpacing.xs,
                  margem,
                  AppSpacing.xl,
                ),
                sliver: SliverList.list(
                  children: _itens(
                    entradas,
                    exemplo: todas.any((e) => e.analise.exemplo),
                  ),
                ),
              ),
            },
            AsyncError() => estado(
              AppEstado.central(
                titulo: AppStrings.historicoErroCarregar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.tentarNovamente,
                  aoTocar: () => ref.invalidate(historicoProvider),
                ),
              ),
            ),
            _ => estado(
              const Center(
                child: CircularProgressIndicator(color: AppColors.roxoProfundo),
              ),
            ),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCabecalhoDeSecao(
                titulo: AppStrings.historicoTitulo,
                largura: largura,
              ),
              Expanded(child: CustomScrollView(slivers: [topo, corpo])),
            ],
          );
        },
      ),
    );
  }
}

/// As linhas do histórico, com o título de cada mês. Sem data — a que o
/// servidor ainda está analisando — é um grupo próprio, no topo.
List<Widget> _itens(
  List<EntradaDoHistorico> entradas, {
  required bool exemplo,
}) {
  String grupo(EntradaDoHistorico e) => switch (e.analise.realizadaEm) {
    final d? => AppStrings.mesEAno(d),
    null => AppStrings.historicoSemData,
  };

  final itens = <Widget>[
    if (exemplo) ...[
      const AppSituacao(
        icone: NomeIcone.informacao,
        titulo: AppStrings.resultadoExemploTitulo,
        texto: AppStrings.resultadoExemploTexto,
      ),
      const SizedBox(height: AppSpacing.md),
    ],
  ];
  String? anterior;
  for (final e in entradas) {
    final atual = grupo(e);
    if (atual != anterior) {
      itens.add(_TituloDoMes(atual, primeiro: anterior == null));
      anterior = atual;
    }
    itens
      ..add(_Linha(entrada: e))
      ..add(const SizedBox(height: AppSpacing.xs));
  }
  return itens;
}

class _CampoBusca extends ConsumerStatefulWidget {
  const _CampoBusca();

  @override
  ConsumerState<_CampoBusca> createState() => _CampoBuscaState();
}

/// Como a busca da lista de pacientes: o rótulo vai para o leitor de tela, e
/// a dica — que some ao digitar — só aparece na tela.
class _CampoBuscaState extends ConsumerState<_CampoBusca> {
  late final _texto = TextEditingController(
    text: ref.read(buscaDoHistoricoProvider),
  );

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(buscaDoHistoricoProvider, (_, termo) {
      if (termo != _texto.text) _texto.text = termo;
    });
    final estilo = Theme.of(context).textTheme.bodyMedium;

    return MergeSemantics(
      child: Semantics(
        label: AppStrings.historicoBuscaDica,
        textField: true,
        child: TextField(
          controller: _texto,
          onChanged: (termo) =>
              ref.read(buscaDoHistoricoProvider.notifier).digitar(termo),
          textInputAction: TextInputAction.search,
          autocorrect: false,
          style: estilo,
          decoration: InputDecoration(
            hint: ExcludeSemantics(
              child: Text(
                AppStrings.historicoBuscaDica,
                style: estilo?.copyWith(color: AppColors.secundarioSobreCreme),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TituloDoMes extends StatelessWidget {
  const _TituloDoMes(this.texto, {required this.primeiro});

  final String texto;
  final bool primeiro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: primeiro ? 0 : AppSpacing.md,
      bottom: AppSpacing.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        // "Setembro de 2026", com maiúscula só no começo.
        '${texto[0].toUpperCase()}${texto.substring(1)}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ),
  );
}

class _Linha extends StatelessWidget {
  const _Linha({required this.entrada});

  final EntradaDoHistorico entrada;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final analise = entrada.analise;
    final quando = switch (analise.realizadaEm) {
      final d? => '${AppStrings.data(d)}, ${AppStrings.hora(d)}',
      null => AppStrings.historicoSemData,
    };
    final avqi = analise.medidas
        .where((m) => m.medida == MedidaAcustica.avqi)
        .firstOrNull
        ?.valor;

    final Widget direita = switch (analise.situacao) {
      SituacaoDaAnalise.processando => Text(
        AppStrings.historicoProcessando,
        style: secundario,
      ),
      SituacaoDaAnalise.falhou => Text(
        AppStrings.historicoFalhou,
        style: secundario,
      ),
      SituacaoDaAnalise.concluida when avqi == null => Text(
        AppStrings.historicoAvqiNaoCalculado,
        style: secundario,
      ),
      SituacaoDaAnalise.concluida => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(MedidaAcustica.avqi.nome, style: secundario),
          Text(
            MedidaAcustica.avqi.formatar(avqi!),
            style: AppTypography.medidaCompacta.copyWith(
              color: AppColors.cinzaChumbo,
            ),
          ),
        ],
      ),
    };

    return Semantics(
      button: true,
      label: AppStrings.historicoAbrir(entrada.paciente.nome, quando),
      child: AppToque(
        raio: AppRadius.bordaMedia,
        aoTocar: () => context.pushNamed(
          AppRoutes.analiseResultadoNome,
          pathParameters: {
            AppRoutes.paramPacienteId: entrada.paciente.id,
            AppRoutes.paramAnaliseId: analise.id,
          },
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lavandaClaro),
            borderRadius: AppRadius.bordaMedia,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entrada.paciente.nome, style: textos.titleSmall),
                    Text(quando, style: secundario),
                    if (entrada.temLaudo) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcone(
                            nome: NomeIcone.confirmacao,
                            cor: AppColors.roxoProfundo,
                            tamanho: 16,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(
                              AppStrings.historicoLaudoGerado,
                              style: secundario,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Encostado à direita, com teto: "Em análise no servidor" quebra
              // em linhas em vez de empurrar o nome para fora.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: direita,
              ),
              const SizedBox(width: AppSpacing.xs),
              const AppIcone(
                nome: NomeIcone.avancar,
                cor: AppColors.roxoProfundo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
