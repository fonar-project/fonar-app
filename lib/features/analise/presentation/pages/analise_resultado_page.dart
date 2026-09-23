import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
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
import '../../../cape_v/data/repositorio_cape_v_em_memoria.dart';
import '../../../cape_v/domain/avaliacao_cape_v.dart';
import '../../../cape_v/presentation/apresentacao_cape_v.dart';
import '../../../captura/domain/amostra.dart';
import '../../../pacientes/data/repositorio_pacientes_placeholder.dart';
import '../../../pacientes/domain/paciente.dart';
import '../../data/catalogo_de_referencias_vazio.dart';
import '../../data/repositorio_analises_placeholder.dart';
import '../../domain/faixa_de_referencia.dart';
import '../../domain/leitura_do_resultado.dart';
import '../../domain/resultado_da_analise.dart';
import '../apresentacao_da_medida.dart';

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
    final analise = ref.watch(analiseProvider(analiseId));
    final paciente = ref.watch(pacienteProvider(pacienteId)).value;
    void atualizar() => ref.invalidate(analiseProvider(analiseId));

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final compacta =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.compacta;

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
                compacta: compacta,
              ),
              Expanded(child: conteudo),
            ],
          );
        },
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
            children: [
              if (resultado.exemplo) ...[
                const AppSituacao(
                  icone: NomeIcone.informacao,
                  titulo: AppStrings.resultadoExemploTitulo,
                  texto: AppStrings.resultadoExemploTexto,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (paciente case final p?)
                Text(
                  AppStrings.consentimentoPaciente(p.nome),
                  style: textos.titleMedium,
                ),
              if (quando != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppStrings.resultadoGravadoEm(
                    AppStrings.data(quando),
                    AppStrings.hora(quando),
                  ),
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.secundarioSobreCreme,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // Antes das medidas, não no rodapé: é a moldura em que elas
              // devem ser lidas.
              Text(
                AppStrings.avisoApoioDecisao,
                style: textos.bodySmall?.copyWith(
                  color: AppColors.secundarioSobreCreme,
                ),
              ),
              if (resultado.qualidade.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _Secao(titulo: AppStrings.resultadoQualidadeTitulo),
                for (final MapEntry(key: tarefa, value: q)
                    in resultado.qualidade.entries) ...[
                  _QualidadeDaAmostra(tarefa: tarefa, qualidade: q),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              _Secao(titulo: AppStrings.resultadoMedidasTitulo),
              if (_motivoComum(medidas) case final motivo?) ...[
                AppSituacao(
                  icone: NomeIcone.semReferencia,
                  titulo: AppStrings.statusSemReferencia,
                  texto: _explicar(motivo),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _GradeDeMedidas(
                medidas: medidas,
                motivoJaDito: _motivoComum(medidas),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Secao(titulo: AppStrings.capeVSecaoTitulo),
              _ResumoCapeV(pacienteId: pacienteId, analiseId: resultado.id),
              const SizedBox(height: AppSpacing.xl),
              _Secao(titulo: AppStrings.resultadoEspectrogramaTitulo),
              _Espectrograma(url: resultado.espectrogramaUrl),
            ],
          ),
        ),
      ),
    );
  }
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

class _QualidadeDaAmostra extends StatelessWidget {
  const _QualidadeDaAmostra({required this.tarefa, required this.qualidade});

  final TarefaDeGravacao tarefa;
  final QualidadeDaAmostra qualidade;

  @override
  Widget build(BuildContext context) {
    final nome = switch (tarefa) {
      TarefaDeGravacao.vogalSustentada => AppStrings.tarefaVogalTitulo,
      TarefaDeGravacao.falaEncadeada => AppStrings.tarefaFalaTitulo,
    };
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

/// Cartões de medida em uma, duas ou três colunas, conforme a largura.
class _GradeDeMedidas extends StatelessWidget {
  const _GradeDeMedidas({required this.medidas, this.motivoJaDito});

  final List<MedidaLida> medidas;

  /// Motivo já explicado acima da grade, que os cartões não repetem.
  final SemClassificacaoPorque? motivoJaDito;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final colunas = switch (restricoes.maxWidth) {
          >= 880 => 3,
          >= 520 => 2,
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
                child: _CartaoDaMedida(lida: m, motivoJaDito: motivoJaDito),
              ),
          ],
        );
      },
    );
  }
}

class _CartaoDaMedida extends StatelessWidget {
  const _CartaoDaMedida({required this.lida, this.motivoJaDito});

  final MedidaLida lida;
  final SemClassificacaoPorque? motivoJaDito;

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
        : _explicar(motivo);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                      : AppTypography.medida.copyWith(
                          color: AppColors.cinzaChumbo,
                        ),
                ),
                if (valor != null && medida.unidade.isNotEmpty)
                  Text(medida.unidade, style: textos.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppStatusMedida(status: _status(lida.classificacao)),
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

String _explicar(SemClassificacaoPorque motivo) => switch (motivo) {
  SemClassificacaoPorque.naoCalculada => AppStrings.resultadoNaoCalculadaTexto,
  SemClassificacaoPorque.perfilIncompleto =>
    AppStrings.resultadoPerfilIncompleto,
  SemClassificacaoPorque.semFaixaValidada =>
    AppStrings.resultadoSemFaixaValidada,
};

/// O motivo, quando TODAS as medidas calculadas estão sem classificação pelo
/// mesmo motivo. Aí ele é dito uma vez, acima das medidas: seis cartões com a
/// mesma frase são ruído, e o ruído esconde a medida que tem algo diferente.
SemClassificacaoPorque? _motivoComum(List<MedidaLida> medidas) {
  final motivos = {
    for (final m in medidas)
      if (m.valor != null) m.semClassificacaoPorque,
  };
  return motivos.length == 1 ? motivos.single : null;
}

/// A CAPE-V desta análise: o que foi marcado, ou o convite para marcar.
///
/// Fica na mesma tela das medidas porque é lida junto delas — a avaliação
/// perceptiva do profissional ao lado do que o servidor mediu —, mas nunca
/// misturada a elas: são coisas de natureza diferente.
class _ResumoCapeV extends ConsumerWidget {
  const _ResumoCapeV({required this.pacienteId, required this.analiseId});

  final String pacienteId;
  final String analiseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final avaliacao = ref.watch(capeVDaAnaliseProvider(analiseId)).value;
    final secundario = textos.bodyMedium?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    void abrir() => context.goNamed(
      AppRoutes.capeVNome,
      pathParameters: {
        AppRoutes.paramPacienteId: pacienteId,
        AppRoutes.paramAnaliseId: analiseId,
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avaliacao == null)
          Text(AppStrings.capeVAindaNao, style: secundario)
        else ...[
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
        const SizedBox(height: AppSpacing.sm),
        AppBotao.secundario(
          rotulo: avaliacao == null
              ? AppStrings.capeVRegistrar
              : AppStrings.capeVEditar,
          aoTocar: abrir,
        ),
      ],
    );
  }
}

StatusMedida _status(ClassificacaoDaMedida c) => switch (c) {
  ClassificacaoDaMedida.dentroDaFaixa => StatusMedida.dentroDaFaixa,
  ClassificacaoDaMedida.limitrofe => StatusMedida.limitrofe,
  ClassificacaoDaMedida.foraDaFaixa => StatusMedida.foraDaFaixa,
  ClassificacaoDaMedida.semReferencia => StatusMedida.semReferencia,
};

/// Imagem pronta do servidor. O aplicativo não desenha espectrograma.
///
/// TODO(US07 mobile): no celular, o protótipo pede o espectrograma em modo
/// paisagem, em tela cheia. Hoje a imagem só ocupa a largura da tela.
class _Espectrograma extends StatelessWidget {
  const _Espectrograma({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final secundario = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.secundarioSobreCreme);
    final endereco = url;
    if (endereco == null) {
      return Text(
        AppStrings.resultadoEspectrogramaIndisponivel,
        style: secundario,
      );
    }
    return ClipRRect(
      borderRadius: AppRadius.bordaMedia,
      child: Image.network(
        endereco,
        semanticLabel: AppStrings.resultadoEspectrogramaDescricao,
        fit: BoxFit.fitWidth,
        errorBuilder: (_, _, _) =>
            Text(AppStrings.resultadoEspectrogramaErro, style: secundario),
      ),
    );
  }
}
