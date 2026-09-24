import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/relogio.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/repositorio_analises_placeholder.dart';
import '../../../analise/domain/resultado_da_analise.dart';
import '../../../analise/presentation/apresentacao_da_medida.dart';
import '../../../consentimento/data/repositorio_consentimento_local.dart';
import '../../../consentimento/domain/consentimento.dart';
import '../../../consentimento/presentation/texto_da_retirada.dart';
import '../../../captura/presentation/gravacoes_nao_enviadas_controlador.dart';
import '../../../fila/domain/item_da_fila.dart';
import '../../../fila/presentation/fila_controlador.dart';
import '../../../historico/domain/evolucao_da_medida.dart';
import '../../../laudo/data/repositorio_laudos_local.dart';
import '../../../laudo/domain/laudo.dart';
import '../../data/repositorio_pacientes_local.dart';
import '../../domain/novo_paciente.dart';
import '../../domain/paciente.dart';

/// Tela 02 — perfil do paciente (US12).
///
/// É o ponto de partida de tudo o que se faz COM um paciente: gravar, ver o
/// consentimento, rever as sessões, a evolução e os laudos. Tudo o que é
/// deste paciente passa por aqui, e volta para cá.
///
/// A gravação fica atrás do consentimento aqui também — mas só como
/// orientação: o bloqueio de verdade é do roteador (ver `app_router.dart`).
/// Enquanto o consentimento não carregou, a tela trata como não registrado:
/// na dúvida, não se oferece gravar.
class PacienteDetalhePage extends ConsumerWidget {
  const PacienteDetalhePage({required this.pacienteId, super.key});

  final String pacienteId;

  void _voltar(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.pacientesNome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(pacienteProvider(pacienteId));

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final largura = Breakpoints.de(restricoes.maxWidth);

          final Widget conteudo = switch (paciente) {
            AsyncData(value: final p?) => _Perfil(
              paciente: p,
              largura: largura,
            ),
            AsyncData() => AppEstado.central(
              titulo: AppStrings.perfilNaoEncontrado,
              texto: AppStrings.perfilNaoEncontradoTexto,
              acao: AppBotao.secundario(
                rotulo: AppStrings.perfilVoltarParaLista,
                aoTocar: () => context.goNamed(AppRoutes.pacientesNome),
              ),
            ),
            AsyncError() => AppEstado.central(
              titulo: AppStrings.perfilErroCarregar,
              acao: AppBotao.secundario(
                rotulo: AppStrings.tentarNovamente,
                aoTocar: () => ref.invalidate(pacientesProvider),
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
                titulo: AppStrings.pacienteDetalheTitulo,
                aoVoltar: () => _voltar(context),
                compacta: largura == LarguraDeTela.compacta,
              ),
              Expanded(child: conteudo),
            ],
          );
        },
      ),
    );
  }
}

class _Perfil extends StatelessWidget {
  const _Perfil({required this.paciente, required this.largura});

  final Paciente paciente;
  final LarguraDeTela largura;

  @override
  Widget build(BuildContext context) {
    final dados = _DadosEAcoes(paciente: paciente);
    final sessoes = _Sessoes(pacienteId: paciente.id);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: largura == LarguraDeTela.compacta
            ? AppSpacing.md
            : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          // No desktop, lado a lado: quem é e o que fazer à esquerda, o que
          // já foi feito à direita. Nas outras larguras, um embaixo do outro.
          child: largura == LarguraDeTela.expandida
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: dados),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(flex: 7, child: sessoes),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    dados,
                    const SizedBox(height: AppSpacing.xl),
                    sessoes,
                  ],
                ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

// -------------------------------------------------------- dados e ações --

class _DadosEAcoes extends ConsumerWidget {
  const _DadosEAcoes({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodyMedium?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final consentimento = ref.watch(consentimentoProvider(paciente.id));
    final retirada = ref.watch(retiradaEmVigorProvider(paciente.id)).value;
    // Fail-closed: só "registrado" libera a gravação; carregando e erro, não.
    final temConsentimento = consentimento.value != null;
    final analises = ref.watch(analisesDoPacienteProvider(paciente.id)).value;
    final temSessao =
        analises?.any((a) => a.situacao == SituacaoDaAnalise.concluida) ??
        false;
    final nascimento = paciente.dataDeNascimento;
    final perfilIncompleto =
        nascimento == null ||
        paciente.sexo == null ||
        paciente.sexo == SexoDeReferencia.naoInformado;
    final rotaDoPaciente = {AppRoutes.paramPacienteId: paciente.id};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(paciente.nome, style: textos.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(AppStrings.perfilQueixa(paciente.queixa), style: textos.bodyLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          nascimento == null
              ? AppStrings.perfilNascimentoNaoInformado
              : AppStrings.perfilNascimento(
                  AppStrings.data(nascimento),
                  idadeEntre(nascimento, ref.watch(relogioProvider)()),
                ),
          style: secundario,
        ),
        Text(switch (paciente.sexo) {
          SexoDeReferencia.feminino => AppStrings.perfilSexo(
            AppStrings.cadastroSexoFeminino,
          ),
          SexoDeReferencia.masculino => AppStrings.perfilSexo(
            AppStrings.cadastroSexoMasculino,
          ),
          SexoDeReferencia.naoInformado ||
          null => AppStrings.perfilSexoNaoInformado,
        }, style: secundario),
        if (perfilIncompleto) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.perfilSemPerfilDeReferencia,
            style: textos.bodySmall?.copyWith(
              color: AppColors.secundarioSobreCreme,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: AppBotao.secundario(
            rotulo: AppStrings.perfilEditarDados,
            aoTocar: paciente.exemplo
                ? null
                : () => context.pushNamed(
                    AppRoutes.edicaoPacienteNome,
                    pathParameters: rotaDoPaciente,
                  ),
            motivoDesabilitado: AppStrings.edicaoExemplo,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (consentimento) {
          AsyncData(value: final c?) => AppSituacao(
            icone: NomeIcone.confirmacao,
            titulo: AppStrings.consentimentoRegistrado,
            texto: _textoDoConsentimento(c),
          ),
          AsyncData() when retirada != null => AppSituacao(
            icone: NomeIcone.negacao,
            titulo: AppStrings.consentimentoRetirado,
            texto: textoDaRetirada(retirada),
          ),
          AsyncData() => const AppSituacao(
            icone: NomeIcone.negacao,
            titulo: AppStrings.consentimentoNaoRegistrado,
            texto: AppStrings.consentimentoNaoRegistradoTexto,
          ),
          AsyncError() => AppSituacao(
            icone: NomeIcone.alerta,
            titulo: AppStrings.consentimentoErroCarregar,
            texto: AppStrings.consentimentoNaoRegistradoTexto,
          ),
          _ => const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.roxoProfundo,
              ),
            ),
          ),
        },
        // Junto do consentimento, e não das ações da consulta: é direito do
        // paciente, mas não é o que se faz a cada atendimento — e não pode
        // parecer o botão de gravar.
        if (temConsentimento) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: AppBotao.secundario(
              rotulo: AppStrings.retiradaAcao,
              aoTocar: () => context.goNamed(
                AppRoutes.retiradaConsentimentoNome,
                pathParameters: rotaDoPaciente,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // Uma ação primária só: gravar quando pode, registrar o consentimento
        // quando ainda não pode. O gravar bloqueado continua à vista, dizendo
        // por quê.
        if (temConsentimento)
          AppBotao.primario(
            rotulo: AppStrings.perfilNovaGravacao,
            icone: NomeIcone.gravar,
            aoTocar: () => context.goNamed(
              AppRoutes.capturaNome,
              pathParameters: rotaDoPaciente,
            ),
            ocupaLargura: true,
          )
        else ...[
          AppBotao.primario(
            rotulo: AppStrings.perfilRegistrarConsentimento,
            aoTocar: () => context.goNamed(
              AppRoutes.consentimentoNome,
              pathParameters: rotaDoPaciente,
            ),
            ocupaLargura: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppBotao.secundario(
            rotulo: AppStrings.perfilNovaGravacao,
            icone: NomeIcone.gravar,
            aoTocar: null,
            motivoDesabilitado: AppStrings.perfilGravacaoBloqueada,
            ocupaLargura: true,
          ),
        ],
        if (temSessao) ...[
          const SizedBox(height: AppSpacing.sm),
          AppBotao.secundario(
            rotulo: AppStrings.perfilVerEvolucao,
            icone: NomeIcone.avancar,
            aoTocar: () => context.goNamed(
              AppRoutes.evolucaoNome,
              pathParameters: rotaDoPaciente,
            ),
            ocupaLargura: true,
          ),
        ],
      ],
    );
  }
}

String _textoDoConsentimento(Consentimento c) =>
    AppStrings.consentimentoRegistradoTexto(
      data: AppStrings.data(c.registradoEm),
      hora: AppStrings.hora(c.registradoEm),
      quem: switch (c.quemAutoriza) {
        QuemAutoriza.paciente => AppStrings.consentimentoPeloPaciente,
        QuemAutoriza.responsavelLegal =>
          AppStrings.consentimentoPeloResponsavel(c.nomeDoResponsavel ?? ''),
      },
      versao: c.versaoDoTermo,
    );

// -------------------------------------------------------------- sessões --

class _Sessoes extends ConsumerWidget {
  const _Sessoes({required this.pacienteId});

  final String pacienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodyMedium?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final analises = ref.watch(analisesDoPacienteProvider(pacienteId));
    final laudos = {
      for (final l
          in ref.watch(laudosDoPacienteProvider(pacienteId)).value ??
              const <Laudo>[])
        l.analiseId: l,
    };
    // Gravado e ainda não enviado: não é análise ainda, mas é deste
    // paciente e o profissional precisa saber que está a caminho.
    // As paradas pela retirada do consentimento não estão a caminho: contam
    // à parte, dizendo por quê.
    final doPaciente = [
      for (final i
          in ref.watch(filaControladorProvider).value ?? const <ItemDaFila>[])
        if (i.pacienteId == pacienteId && i.pendente) i,
    ];
    final parados = doPaciente
        .where((i) => i.situacao == SituacaoDoEnvio.semConsentimento)
        .length;
    final naFila = doPaciente.length - parados;
    // Voz de paciente parada no aparelho, sem ir para a análise: aparece
    // aqui para não ficar esquecida.
    final naoEnviadas =
        ref.watch(sessoesNaoEnviadasProvider(pacienteId)).value?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(AppStrings.perfilSessoesTitulo),
        if (naFila > 0)
          AppSituacao(
            icone: NomeIcone.passoPendente,
            titulo: AppStrings.perfilNaFila(naFila),
          ),
        if (parados > 0)
          AppSituacao(
            icone: NomeIcone.negacao,
            titulo: AppStrings.perfilParadosNaFila(parados),
          ),
        if (naoEnviadas > 0) ...[
          AppSituacao(
            icone: NomeIcone.alerta,
            titulo: AppStrings.perfilNaoEnviadas(naoEnviadas),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppBotao.secundario(
              rotulo: AppStrings.perfilRevisarGravacoes,
              icone: NomeIcone.avancar,
              aoTocar: () => context.pushNamed(
                AppRoutes.gravacoesNaoEnviadasNome,
                pathParameters: {AppRoutes.paramPacienteId: pacienteId},
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (naFila > 0 || parados > 0) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: AppBotao.secundario(
              rotulo: AppStrings.perfilVerFila,
              icone: NomeIcone.avancar,
              aoTocar: () => context.goNamed(AppRoutes.filaNome),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ...switch (analises) {
          AsyncData(:final value) when value.isEmpty => [
            Text(AppStrings.perfilSemSessoes, style: secundario),
          ],
          AsyncData(:final value) => [
            if (value.any((a) => a.exemplo)) ...[
              const AppSituacao(
                icone: NomeIcone.informacao,
                titulo: AppStrings.resultadoExemploTitulo,
                texto: AppStrings.resultadoExemploTexto,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (final analise in _maisRecentesPrimeiro(value))
              _LinhaDaSessao(
                pacienteId: pacienteId,
                analise: analise,
                laudo: laudos[analise.id],
              ),
          ],
          AsyncError() => [
            AppEstado.faixa(
              titulo: AppStrings.evolucaoErroCarregar,
              acao: AppBotao.secundario(
                rotulo: AppStrings.tentarNovamente,
                aoTocar: () =>
                    ref.invalidate(analisesDoPacienteProvider(pacienteId)),
              ),
            ),
          ],
          _ => [
            const Center(
              child: CircularProgressIndicator(color: AppColors.roxoProfundo),
            ),
          ],
        },
      ],
    );
  }
}

/// Da mais recente para a mais antiga; sem data, no fim.
List<ResultadoDaAnalise> _maisRecentesPrimeiro(
  List<ResultadoDaAnalise> analises,
) => [...analises]
  ..sort((a, b) {
    final da = a.realizadaEm;
    final db = b.realizadaEm;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });

/// Uma sessão: quando, o AVQI (o índice que resume as outras medidas), a
/// qualidade das amostras e se já tem laudo. Toca para abrir o resultado.
class _LinhaDaSessao extends StatelessWidget {
  const _LinhaDaSessao({
    required this.pacienteId,
    required this.analise,
    required this.laudo,
  });

  final String pacienteId;
  final ResultadoDaAnalise analise;
  final Laudo? laudo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final quando = analise.realizadaEm;
    final data = quando == null
        ? AppStrings.perfilSemData
        : AppStrings.data(quando);
    final avqi = analise.medidas
        .where((m) => m.medida == MedidaAcustica.avqi)
        .firstOrNull
        ?.valor;
    final comProblema = analise.qualidade.values.any((q) => !q.adequada);
    final laudo = this.laudo;

    Widget marca(NomeIcone icone, String texto) => Row(
      children: [
        AppIcone(nome: icone, cor: AppColors.cinzaChumbo, tamanho: 18),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(child: Text(texto, style: textos.bodySmall)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        hint: AppStrings.perfilAbrirSessao(data),
        child: AppToque(
          aoTocar: () => context.goNamed(
            AppRoutes.analiseResultadoNome,
            pathParameters: {
              AppRoutes.paramPacienteId: pacienteId,
              AppRoutes.paramAnaliseId: analise.id,
            },
          ),
          raio: AppRadius.bordaMedia,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.branco,
              border: Border.all(color: AppColors.lavandaClaro),
              borderRadius: AppRadius.bordaMedia,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            quando == null
                                ? data
                                : '$data, ${AppStrings.hora(quando)}',
                            style: textos.titleMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (analise.situacao == SituacaoDaAnalise.concluida &&
                              avqi != null)
                            Text(
                              '${MedidaAcustica.avqi.nome} '
                              '${MedidaAcustica.avqi.formatar(avqi)}',
                              style: textos.titleMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      switch (analise.situacao) {
                        SituacaoDaAnalise.processando => Text(
                          AppStrings.perfilAnaliseProcessando,
                          style: secundario,
                        ),
                        SituacaoDaAnalise.falhou => marca(
                          NomeIcone.alerta,
                          AppStrings.perfilAnaliseFalhou,
                        ),
                        SituacaoDaAnalise.concluida => marca(
                          comProblema
                              ? NomeIcone.alerta
                              : NomeIcone.confirmacao,
                          comProblema
                              ? AppStrings.perfilAmostraComProblema
                              : AppStrings.perfilAmostrasAdequadas,
                        ),
                      },
                      if (laudo != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          AppStrings.perfilLaudoGerado(
                            AppStrings.data(laudo.geradoEm),
                          ),
                          style: secundario,
                        ),
                      ],
                    ],
                  ),
                ),
                const AppIcone(
                  nome: NomeIcone.avancar,
                  cor: AppColors.roxoProfundo,
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
