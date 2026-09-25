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
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../design_system/widgets/app_status_medida.dart';
import '../../../../l10n/app_strings.dart';
import '../../../cape_v/data/repositorio_cape_v_local.dart';
import '../../../cape_v/domain/avaliacao_cape_v.dart';
import '../../../cape_v/presentation/apresentacao_cape_v.dart';
import '../../../captura/domain/amostra.dart';
import '../../../fila/presentation/fila_controlador.dart';
import '../../../historico/domain/evolucao_da_medida.dart';
import '../../../reproducao/presentation/widgets/player_de_amostra.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../pacientes/domain/paciente.dart';
import '../../data/catalogo_de_referencias_vazio.dart';
import '../../data/imagem_do_servidor.dart';
import '../../data/repositorio_analises_placeholder.dart';
import '../../domain/leitura_do_resultado.dart';
import '../../domain/resultado_da_analise.dart';
import '../apresentacao_da_medida.dart';
import '../aviso_de_outro_paciente.dart';

/// Tela 07 — resultado da análise.
///
/// Só EXIBE: toda medida chega pronta do servidor, e o espectrograma chega
/// como imagem. Nenhum cálculo acústico acontece aqui.
///
/// As regras que moldam esta tela, todas do CLAUDE.md:
/// - apoio à decisão, nunca diagnóstico — o vocabulário descreve a medida
///   frente à faixa, nunca o paciente;
/// - faixa de referência vem do catálogo, com procedência, e sem faixa
///   validada a medida aparece sem classificação, dizendo por quê;
/// - status nunca só por cor: ícone e texto sempre.
class AnaliseResultadoPage extends ConsumerWidget {
  const AnaliseResultadoPage({
    required this.pacienteId,
    required this.analiseId,
    super.key,
  });

  final String pacienteId;
  final String analiseId;

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
    final analise = ref.watch(
      analiseDoPacienteProvider((pacienteId: pacienteId, analiseId: analiseId)),
    );
    final paciente = ref.watch(pacienteProvider(pacienteId)).value;
    void atualizar() => ref.invalidate(analiseProvider(analiseId));

    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);
            final compacta = largura == LarguraDeTela.compacta;

            final Widget conteudo = switch (analise) {
              AsyncData(:final value) => switch (value.situacao) {
                SituacaoDaAnalise.processando => AppEstado.central(
                  titulo: AppStrings.resultadoProcessandoTitulo,
                  texto: AppStrings.resultadoProcessandoTexto,
                  acao: AppBotao.secundario(
                    rotulo: AppStrings.resultadoAtualizar,
                    aoTocar: atualizar,
                  ),
                ),
                SituacaoDaAnalise.falhou => AppEstado.central(
                  titulo: AppStrings.resultadoFalhouTitulo,
                  texto: value.motivoDaFalha,
                  acao: AppBotao.secundario(
                    rotulo: AppStrings.voltar,
                    aoTocar: () => _voltar(context),
                  ),
                ),
                SituacaoDaAnalise.concluida => _Resultado(
                  pacienteId: pacienteId,
                  resultado: value,
                  paciente: paciente,
                  compacta: compacta,
                ),
              },
              // A análise precisa ser do paciente da rota — ver `daPaciente`.
              AsyncError(:final error) when error is AnaliseDeOutroPaciente =>
                AvisoDeOutroPaciente(aoVoltar: () => _voltar(context)),
              AsyncError() => AppEstado.central(
                titulo: AppStrings.resultadoErroCarregar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.tentarNovamente,
                  aoTocar: atualizar,
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
                  titulo: AppStrings.analiseResultadoTitulo,
                  aoVoltar: () => _voltar(context),
                  largura: largura,
                  subtitulo: paciente?.nome,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: pacienteId,
                      nome: paciente?.nome,
                    ),
                    ItemDaTrilha(AppStrings.analiseResultadoTitulo),
                  ],
                  situacao: AppStrings.situacaoApoioADecisao,
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

class _Resultado extends ConsumerWidget {
  const _Resultado({
    required this.pacienteId,
    required this.resultado,
    required this.paciente,
    required this.compacta,
  });

  final String pacienteId;
  final ResultadoDaAnalise resultado;
  final Paciente? paciente;
  final bool compacta;

  /// As medidas em destaque, como no protótipo: as duas que resumem a
  /// qualidade vocal. As demais vêm menores, embaixo.
  static const _principais = {MedidaAcustica.avqi, MedidaAcustica.cpps};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final medidas = lerMedidas(
      resultado: resultado,
      sexo: paciente?.sexo,
      dataDeNascimento: paciente?.dataDeNascimento,
      catalogo: ref.watch(catalogoDeReferenciasProvider),
    );
    final quando = resultado.realizadaEm;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final motivo = motivoComum(medidas);
    final capeV = ref.watch(capeVDaAnaliseProvider(resultado.id)).value;

    final acoes = _Acoes(
      pacienteId: pacienteId,
      analiseId: resultado.id,
      capeVRegistrada: capeV != null,
    );

    final corpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resultado.exemplo) ...[
          const AppSituacao(
            icone: NomeIcone.informacao,
            titulo: AppStrings.resultadoExemploTitulo,
            texto: AppStrings.resultadoExemploTexto,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (quando != null)
          Text(
            AppStrings.resultadoGravadoEm(
              AppStrings.data(quando),
              AppStrings.hora(quando),
            ),
            style: secundario,
          ),
        const SizedBox(height: AppSpacing.xxs),
        // Antes das medidas, não no rodapé: é a moldura em que elas devem
        // ser lidas.
        Text(AppStrings.avisoApoioDecisao, style: secundario),
        const SizedBox(height: AppSpacing.lg),
        _Secao(titulo: AppStrings.resultadoMedidasTitulo),
        if (motivo != null) ...[
          AppSituacao(
            icone: NomeIcone.semReferencia,
            titulo: AppStrings.statusSemReferencia,
            texto: explicarSemClassificacao(motivo),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _GradeDeMedidas(
          medidas: [
            for (final m in medidas)
              if (_principais.contains(m.medida)) m,
          ],
          motivoJaDito: motivo,
          destaque: true,
        ),
        const SizedBox(height: AppSpacing.md),
        _GradeDeMedidas(
          medidas: [
            for (final m in medidas)
              if (!_principais.contains(m.medida)) m,
          ],
          motivoJaDito: motivo,
          destaque: false,
        ),
        const SizedBox(height: AppSpacing.xl),
        _CartaoDaAmostra(
          pacienteId: pacienteId,
          resultado: resultado,
          compacta: compacta,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Secao(titulo: AppStrings.capeVSecaoTitulo),
        _ResumoCapeV(avaliacao: capeV),
        if (compacta) ...[
          // No celular, só a ação principal fica presa embaixo; as outras
          // fecham a página.
          const SizedBox(height: AppSpacing.xl),
          acoes.secundarias(ocupaLargura: true),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: corpo,
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.lavandaClaro)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: compacta
                  ? acoes.principal(ocupaLargura: true)
                  : Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Text(
                            AppStrings.resultadoRodape,
                            style: secundario,
                          ),
                        ),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            acoes.secundarias(ocupaLargura: false),
                            acoes.principal(ocupaLargura: false),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Os próximos passos depois de ler o resultado. O principal é registrar a
/// CAPE-V; registrada, é preparar o laudo — o passo que fecha a sessão.
class _Acoes {
  const _Acoes({
    required this.pacienteId,
    required this.analiseId,
    required this.capeVRegistrada,
  });

  final String pacienteId;
  final String analiseId;
  final bool capeVRegistrada;

  Map<String, String> get _params => {
    AppRoutes.paramPacienteId: pacienteId,
    AppRoutes.paramAnaliseId: analiseId,
  };

  AppBotao _capeV(BuildContext context, {required bool primario}) => AppBotao(
    variante: primario ? VarianteBotao.primario : VarianteBotao.secundario,
    rotulo: capeVRegistrada
        ? AppStrings.capeVEditar
        : AppStrings.capeVRegistrar,
    icone: NomeIcone.avancar,
    aoTocar: () =>
        context.goNamed(AppRoutes.capeVNome, pathParameters: _params),
  );

  AppBotao _laudo(BuildContext context, {required bool primario}) => AppBotao(
    variante: primario ? VarianteBotao.primario : VarianteBotao.secundario,
    rotulo: AppStrings.resultadoPrepararLaudo,
    icone: NomeIcone.avancar,
    aoTocar: () =>
        context.goNamed(AppRoutes.laudoNome, pathParameters: _params),
  );

  Widget principal({required bool ocupaLargura}) => Builder(
    builder: (context) {
      final botao = capeVRegistrada
          ? _laudo(context, primario: true)
          : _capeV(context, primario: true);
      return ocupaLargura
          ? SizedBox(width: double.infinity, child: botao)
          : botao;
    },
  );

  Widget secundarias({required bool ocupaLargura}) => Builder(
    builder: (context) {
      final botoes = [
        // A medida de hoje ganha sentido ao lado das anteriores. `push`: o
        // voltar da evolução traz de volta a este resultado.
        AppBotao.secundario(
          rotulo: AppStrings.resultadoVerEvolucao,
          icone: NomeIcone.avancar,
          aoTocar: () => context.pushNamed(
            AppRoutes.evolucaoNome,
            pathParameters: {AppRoutes.paramPacienteId: pacienteId},
          ),
        ),
        capeVRegistrada
            ? _capeV(context, primario: false)
            : _laudo(context, primario: false),
      ];
      if (ocupaLargura) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, b) in botoes.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              b,
            ],
          ],
        );
      }
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: botoes,
      );
    },
  );
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

/// A amostra junto do espectrograma, como no protótipo: o que se ouve ao
/// lado do que o servidor desenhou dela.
class _CartaoDaAmostra extends ConsumerWidget {
  const _CartaoDaAmostra({
    required this.pacienteId,
    required this.resultado,
    required this.compacta,
  });

  final String pacienteId;
  final ResultadoDaAnalise resultado;
  final bool compacta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final audios = ref.watch(amostrasDaAnaliseProvider(resultado.id));
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );

    final amostras = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Secao(titulo: AppStrings.resultadoQualidadeTitulo),
        for (final MapEntry(key: tarefa, value: q)
            in resultado.qualidade.entries) ...[
          _QualidadeDaAmostra(tarefa: tarefa, qualidade: q),
          if (audios[tarefa] case final amostra?) ...[
            const SizedBox(height: AppSpacing.xs),
            PlayerDeAmostra(
              caminho: amostra.caminho,
              rotulo: _nomeDaTarefa(tarefa),
              duracaoConhecida: amostra.duracao,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
        if (audios.isEmpty)
          Text(AppStrings.resultadoAudioIndisponivel, style: secundario),
      ],
    );
    final espectrograma = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Secao(titulo: AppStrings.resultadoEspectrogramaTitulo),
        _Espectrograma(
          url: resultado.espectrogramaUrl,
          pacienteId: pacienteId,
          analiseId: resultado.id,
        ),
      ],
    );
    final temQualidade = resultado.qualidade.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.branco,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: LayoutBuilder(
        builder: (context, restricoes) {
          // Lado a lado quando cabe; senão, um embaixo do outro.
          if (temQualidade && restricoes.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: amostras),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 3, child: espectrograma),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (temQualidade) ...[
                amostras,
                const SizedBox(height: AppSpacing.md),
              ],
              espectrograma,
            ],
          );
        },
      ),
    );
  }
}

class _QualidadeDaAmostra extends StatelessWidget {
  const _QualidadeDaAmostra({required this.tarefa, required this.qualidade});

  final TarefaDeGravacao tarefa;
  final QualidadeDaAmostra qualidade;

  @override
  Widget build(BuildContext context) {
    final nome = _nomeDaTarefa(tarefa);
    return qualidade.adequada
        ? AppSituacao(
            icone: NomeIcone.confirmacao,
            titulo: AppStrings.resultadoAmostraAdequada(nome),
          )
        : AppSituacao(
            icone: NomeIcone.alerta,
            titulo: AppStrings.resultadoAmostraComProblema(nome),
            texto: qualidade.motivo ?? AppStrings.resultadoAmostraSemMotivo,
          );
  }
}

String _nomeDaTarefa(TarefaDeGravacao tarefa) => switch (tarefa) {
  TarefaDeGravacao.vogalSustentada => AppStrings.tarefaVogalTitulo,
  TarefaDeGravacao.falaEncadeada => AppStrings.tarefaFalaTitulo,
};

/// Cartões de medida em uma, duas ou três colunas, conforme a largura.
class _GradeDeMedidas extends StatelessWidget {
  const _GradeDeMedidas({
    required this.medidas,
    required this.destaque,
    this.motivoJaDito,
  });

  final List<MedidaLida> medidas;

  /// As principais: duas por linha, número grande.
  final bool destaque;

  /// Motivo já explicado acima da grade, que os cartões não repetem.
  final SemClassificacaoPorque? motivoJaDito;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final colunas = destaque
            ? (restricoes.maxWidth >= 520 ? 2 : 1)
            : switch (restricoes.maxWidth) {
                >= 880 => 4,
                >= 320 => 2,
                _ => 1,
              };
        const vao = AppSpacing.md;
        final largura = (restricoes.maxWidth - vao * (colunas - 1)) / colunas;
        return Wrap(
          spacing: vao,
          runSpacing: vao,
          children: [
            for (final m in medidas)
              SizedBox(
                width: largura,
                child: _CartaoDaMedida(
                  lida: m,
                  motivoJaDito: motivoJaDito,
                  destaque: destaque,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CartaoDaMedida extends StatelessWidget {
  const _CartaoDaMedida({
    required this.lida,
    required this.destaque,
    this.motivoJaDito,
  });

  final MedidaLida lida;
  final SemClassificacaoPorque? motivoJaDito;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final medida = lida.medida;
    final valor = lida.valor;
    final faixa = lida.faixa;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );

    final motivo = lida.semClassificacaoPorque;
    final explicacao = motivo == null || motivo == motivoJaDito
        ? null
        : explicarSemClassificacao(motivo);

    return Container(
      padding: EdgeInsets.all(destaque ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.branco,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(medida.nome, style: textos.titleMedium),
          Text(medida.descricao, style: secundario),
          const SizedBox(height: AppSpacing.sm),
          // Valor e unidade num nó só para o leitor de tela: "3,12", depois
          // "dB" solto, não diz nada.
          MergeSemantics(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpacing.xxs,
              children: [
                Text(
                  valor == null
                      ? AppStrings.resultadoNaoCalculada
                      : medida.formatar(valor),
                  style: valor == null
                      ? textos.titleMedium
                      : (destaque
                                ? AppTypography.medidaDestaque
                                : AppTypography.medida)
                            .copyWith(color: AppColors.cinzaChumbo),
                ),
                if (valor != null && medida.unidade.isNotEmpty)
                  Text(medida.unidade, style: textos.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppStatusMedida(status: statusDaClassificacao(lida.classificacao)),
          if (faixa != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.resultadoFaixa(medida.descreverFaixa(faixa)),
              style: secundario,
            ),
            const SizedBox(height: AppSpacing.xxs),
            // A procedência sempre à vista: a faixa é tão confiável quanto a
            // sua fonte, e o profissional precisa poder julgar isso.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcone(
                  nome: NomeIcone.informacao,
                  cor: AppColors.secundarioSobreCreme,
                  tamanho: 16,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    AppStrings.resultadoProcedencia(faixa.procedencia),
                    style: secundario,
                  ),
                ),
              ],
            ),
          ],
          if (explicacao != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(explicacao, style: secundario),
          ],
        ],
      ),
    );
  }
}

/// A CAPE-V desta análise: o que foi marcado, ou o convite para marcar.
///
/// Fica na mesma tela das medidas porque é lida junto delas — a avaliação
/// perceptiva do profissional ao lado do que o servidor mediu —, mas nunca
/// misturada a elas: são coisas de natureza diferente.
class _ResumoCapeV extends StatelessWidget {
  const _ResumoCapeV({required this.avaliacao});

  final AvaliacaoCapeV? avaliacao;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodyMedium?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final avaliacao = this.avaliacao;
    // Registrar ou editar fica nas ações da tela — ver `_Acoes`.
    if (avaliacao == null) {
      return Text(AppStrings.capeVAindaNao, style: secundario);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.capeVRegistradaEm(
            AppStrings.data(avaliacao.registradaEm),
            AppStrings.hora(avaliacao.registradaEm),
          ),
          style: secundario,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final p in ParametroCapeV.values)
          if (avaliacao.notas[p] case final nota?)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Text(
                '${p.nome}: ${resumirNota(p, nota)}',
                style: textos.bodyMedium,
              ),
            ),
        if (avaliacao.comentarios.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(avaliacao.comentarios, style: secundario),
        ],
      ],
    );
  }
}

/// Imagem pronta do servidor. O aplicativo não desenha espectrograma.
///
/// Aqui, na largura da página; para ler os detalhes — no celular, deitado —,
/// abre em tela cheia ([EspectrogramaPage]).
class _Espectrograma extends ConsumerWidget {
  const _Espectrograma({
    required this.url,
    required this.pacienteId,
    required this.analiseId,
  });

  final String? url;
  final String pacienteId;
  final String analiseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secundario = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.secundarioSobreCreme);
    final endereco = url;
    if (endereco == null) {
      return Text(
        AppStrings.resultadoEspectrogramaIndisponivel,
        style: secundario,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.bordaMedia,
          child: Image(
            image: ref.watch(imagemDoServidorProvider)(endereco),
            semanticLabel: AppStrings.resultadoEspectrogramaDescricao,
            fit: BoxFit.fitWidth,
            errorBuilder: (_, _, _) =>
                Text(AppStrings.resultadoEspectrogramaErro, style: secundario),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppBotao.secundario(
          rotulo: AppStrings.resultadoEspectrogramaTelaCheia,
          icone: NomeIcone.avancar,
          // `push`: voltar da tela cheia traz de volta a este ponto.
          aoTocar: () => context.pushNamed(
            AppRoutes.espectrogramaNome,
            pathParameters: {
              AppRoutes.paramPacienteId: pacienteId,
              AppRoutes.paramAnaliseId: analiseId,
            },
          ),
        ),
      ],
    );
  }
}
