import 'dart:async';
import 'dart:typed_data';

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
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/catalogo_de_referencias_vazio.dart';
import '../../../analise/data/repositorio_analises_placeholder.dart';
import '../../../analise/domain/resultado_da_analise.dart';
import '../../../analise/presentation/aviso_de_outro_paciente.dart';
import '../../../auth/data/profissional_atual.dart';
import '../../../cape_v/data/repositorio_cape_v_local.dart';
import '../../../cape_v/domain/avaliacao_cape_v.dart';
import '../../../consentimento/data/repositorio_consentimento_local.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../pacientes/domain/paciente.dart';
import '../../data/saida_do_laudo.dart';
import '../../domain/conteudo_do_laudo.dart';
import '../../domain/laudo.dart';
import '../laudo_controlador.dart';

/// Telas 10 e 11 — conferência, conclusão e geração do laudo.
///
/// O laudo reúne o que o servidor mediu, o que o profissional registrou na
/// CAPE-V e a conclusão que ele escreve aqui. O aplicativo não escreve nem
/// sugere conclusão: apoio à decisão, nunca diagnóstico.
///
/// No desktop, a pré-visualização A4 fica ao lado. No celular e no tablet em
/// pé ela vira um resumo do que vai no documento, com as ações de abrir,
/// compartilhar e imprimir — como pede o CLAUDE.md. As mesmas ações nas duas
/// larguras.
class LaudoPage extends ConsumerWidget {
  const LaudoPage({
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
        AppRoutes.analiseResultadoNome,
        pathParameters: {
          AppRoutes.paramPacienteId: pacienteId,
          AppRoutes.paramAnaliseId: analiseId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A análise pela conferência de paciente — ver `daPaciente` — e o
    // cadastro como dado OBRIGATÓRIO: sem ele o laudo sairia sem
    // identificação (achados da revisão de 23/09).
    final analise = ref.watch(
      analiseDoPacienteProvider((pacienteId: pacienteId, analiseId: analiseId)),
    );
    final paciente = ref.watch(pacienteProvider(pacienteId));
    final laudo = ref.watch(laudoControladorProvider(analiseId));
    final capeV = ref.watch(capeVDaAnaliseProvider(analiseId));
    final consentimento = ref.watch(consentimentoProvider(pacienteId));
    final cargas = [analise, paciente, laudo, capeV, consentimento];

    void tentarDeNovo() {
      ref.invalidate(analiseProvider(analiseId));
      ref.invalidate(pacientesProvider);
      ref.invalidate(laudoControladorProvider(analiseId));
      ref.invalidate(capeVDaAnaliseProvider(analiseId));
      ref.invalidate(consentimentoProvider(pacienteId));
    }

    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);

            final Widget conteudo;
            if (analise.error is AnaliseDeOutroPaciente) {
              conteudo = AvisoDeOutroPaciente(aoVoltar: () => _voltar(context));
            } else if (cargas.any((a) => a.hasError)) {
              conteudo = AppEstado.central(
                titulo: AppStrings.laudoErroCarregar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.tentarNovamente,
                  aoTocar: tentarDeNovo,
                ),
              );
            } else if (cargas.every((a) => a.hasValue)) {
              if (paciente.requireValue case final cadastro?) {
                conteudo = _Laudo(
                  pacienteId: pacienteId,
                  resultado: analise.requireValue,
                  estado: laudo.requireValue,
                  capeV: capeV.value,
                  temConsentimento: consentimento.value != null,
                  paciente: cadastro,
                  largura: largura,
                );
              } else {
                // Carregou, e o paciente não está neste aparelho: diferente de
                // "ainda carregando" e de "falhou ao carregar".
                conteudo = AppEstado.central(
                  titulo: AppStrings.laudoSemPaciente,
                  texto: AppStrings.laudoSemPacienteTexto,
                  acao: AppBotao.secundario(
                    rotulo: AppStrings.voltar,
                    aoTocar: () => _voltar(context),
                  ),
                );
              }
            } else {
              conteudo = const Center(
                child: CircularProgressIndicator(color: AppColors.roxoProfundo),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCabecalhoDeTarefa(
                  titulo: AppStrings.laudoTitulo,
                  aoVoltar: () => _voltar(context),
                  largura: largura,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: pacienteId,
                      nome: paciente.value?.nome,
                    ),
                    ItemDaTrilha(AppStrings.laudoTitulo),
                  ],
                  situacao: AppStrings.situacaoLaudo,
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

class _Laudo extends ConsumerStatefulWidget {
  const _Laudo({
    required this.pacienteId,
    required this.resultado,
    required this.estado,
    required this.capeV,
    required this.temConsentimento,
    required this.paciente,
    required this.largura,
  });

  final String pacienteId;
  final ResultadoDaAnalise resultado;
  final EstadoDoLaudo estado;
  final AvaliacaoCapeV? capeV;
  final bool temConsentimento;
  final Paciente paciente;
  final LarguraDeTela largura;

  @override
  ConsumerState<_Laudo> createState() => _LaudoState();
}

class _LaudoState extends ConsumerState<_Laudo> {
  late final _conclusao = TextEditingController(
    text: widget.estado.laudo?.conclusao ?? '',
  );

  /// O texto que a pré-visualização mostra. Anda atrás do campo, com um
  /// respiro: remontar o PDF a cada tecla travaria a digitação.
  late var _textoDaPrevia = _conclusao.text;
  Timer? _respiro;

  var _saindo = false;
  var _falhouSaida = false;

  // A pré-visualização só é refeita quando algo que vai no documento muda —
  // ver [_previa].
  Object? _chaveDaPrevia;
  Future<Uint8List> Function()? _gerarPrevia;

  @override
  void initState() {
    super.initState();
    _conclusao.addListener(_aoDigitar);
  }

  @override
  void dispose() {
    _respiro?.cancel();
    _conclusao.dispose();
    super.dispose();
  }

  void _aoDigitar() {
    // A conferência (conclusão escrita ou não) responde na hora.
    setState(() {});
    _respiro?.cancel();
    _respiro = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _textoDaPrevia = _conclusao.text);
    });
  }

  ConteudoDoLaudo _montar(String conclusao, DateTime? geradoEm) =>
      montarConteudo(
        resultado: widget.resultado,
        paciente: widget.paciente,
        capeV: widget.capeV,
        conclusao: conclusao,
        profissional: ref.read(profissionalAtualProvider),
        catalogo: ref.read(catalogoDeReferenciasProvider),
        geradoEm: geradoEm,
      );

  Future<void> _gerar() async {
    await ref
        .read(laudoControladorProvider(widget.resultado.id).notifier)
        .gerar(
          pacienteId: widget.pacienteId,
          conclusao: _conclusao.text,
          montar: (geradoEm) => _montar(_conclusao.text, geradoEm),
        );
  }

  Future<void> _enviar({required bool imprimir}) async {
    final laudo = widget.estado.laudo;
    if (laudo == null || _saindo) return;
    setState(() {
      _saindo = true;
      _falhouSaida = false;
    });
    final saida = ref.read(saidaDoLaudoProvider);
    final nome = AppStrings.laudoNomeDoArquivo(
      widget.resultado.realizadaEm ?? laudo.geradoEm,
    );
    try {
      if (imprimir) {
        await saida.imprimir(laudo.pdf, nomeDoArquivo: nome);
      } else {
        await saida.compartilhar(laudo.pdf, nomeDoArquivo: nome);
      }
    } catch (_) {
      if (mounted) setState(() => _falhouSaida = true);
    } finally {
      if (mounted) setState(() => _saindo = false);
    }
  }

  /// O gerador da pré-visualização, refeito só quando o documento muda.
  ///
  /// O `PdfPreview` remonta a imagem sempre que recebe uma função nova; sem
  /// esta guarda, qualquer reconstrução da tela — um foco, um hover — o faria
  /// rasterizar o A4 de novo.
  Future<Uint8List> Function() _previa() {
    final laudo = widget.estado.laudo;
    final gerado = laudo != null && laudo.conclusao == _textoDaPrevia.trim();
    final chave = (
      _textoDaPrevia,
      laudo?.geradoEm,
      widget.capeV?.registradaEm,
      widget.resultado.id,
      widget.paciente.nome,
    );
    if (chave != _chaveDaPrevia || _gerarPrevia == null) {
      _chaveDaPrevia = chave;
      final gerador = ref.read(geradorDePdfProvider);
      // Texto igual ao do laudo gerado: mostra O documento gerado. Senão, o
      // rascunho do que seria gerado agora.
      _gerarPrevia = gerado
          ? () async => laudo.pdf
          : () => gerador(_montar(_textoDaPrevia, null));
    }
    return _gerarPrevia!;
  }

  @override
  Widget build(BuildContext context) {
    final conferencia = conferirLaudo(
      temConsentimento: widget.temConsentimento,
      resultado: widget.resultado,
      capeV: widget.capeV,
      conclusao: _conclusao.text,
    );
    final expandida = widget.largura == LarguraDeTela.expandida;

    final painel = _Painel(
      pacienteId: widget.pacienteId,
      analiseId: widget.resultado.id,
      conferencia: conferencia,
      conclusao: _conclusao,
      estado: widget.estado,
      saindo: _saindo,
      falhouSaida: _falhouSaida,
      aoGerar: _gerar,
      aoCompartilhar: () => _enviar(imprimir: false),
      aoImprimir: () => _enviar(imprimir: true),
      resumo: expandida
          ? null
          : _Resumo(
              conteudo: _montar(_conclusao.text, widget.estado.laudo?.geradoEm),
            ),
    );

    if (!expandida) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: widget.largura == LarguraDeTela.compacta
              ? AppSpacing.md
              : AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: painel,
          ),
        ),
      );
    }

    // Como no protótipo: a folha à esquerda, onde o olho começa, e o que se
    // preenche ao lado dela.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.lavandaClaro)),
            ),
            child: Semantics(
              label: AppStrings.laudoPreviaTitulo,
              container: true,
              child: ref.watch(previaDoPdfProvider)(_previa()),
            ),
          ),
        ),
        SizedBox(
          width: 460,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: painel,
          ),
        ),
      ],
    );
  }
}

/// Conferência, conclusão e ações — a coluna ao lado da folha no desktop, a
/// tela inteira no celular.
class _Painel extends StatelessWidget {
  const _Painel({
    required this.pacienteId,
    required this.analiseId,
    required this.conferencia,
    required this.conclusao,
    required this.estado,
    required this.saindo,
    required this.falhouSaida,
    required this.aoGerar,
    required this.aoCompartilhar,
    required this.aoImprimir,
    required this.resumo,
  });

  final String pacienteId;
  final String analiseId;
  final ConferenciaDoLaudo conferencia;
  final TextEditingController conclusao;
  final EstadoDoLaudo estado;
  final bool saindo;
  final bool falhouSaida;
  final VoidCallback aoGerar;
  final VoidCallback aoCompartilhar;
  final VoidCallback aoImprimir;

  /// Só fora do desktop, no lugar da pré-visualização A4.
  final Widget? resumo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final laudo = estado.laudo;
    final mudou = laudo != null && laudo.conclusao != conclusao.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.avisoApoioDecisao, style: secundario),
        // No lugar da folha, fora do desktop: o que o PDF vai ter vem antes
        // do que falta para gerá-lo, como no protótipo.
        if (resumo case final resumo?) ...[
          const SizedBox(height: AppSpacing.lg),
          resumo,
        ],
        const SizedBox(height: AppSpacing.lg),
        _Titulo(AppStrings.laudoConferenciaTitulo),
        for (final MapEntry(key: item, value: situacao)
            in conferencia.itens.entries)
          _ItemDaConferencia(
            item: item,
            situacao: situacao,
            pacienteId: pacienteId,
            analiseId: analiseId,
          ),
        const SizedBox(height: AppSpacing.lg),
        AppCampoTexto(
          rotulo: AppStrings.laudoCampoConclusao,
          controlador: conclusao,
          apoio: AppStrings.laudoConclusaoApoio,
          linhas: 8,
          capitalizacao: TextCapitalization.sentences,
          somenteLeitura: estado.gerando,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppBotao.primario(
          rotulo: estado.gerando
              ? AppStrings.laudoGerando
              : AppStrings.laudoGerar,
          aoTocar: conferencia.podeGerar && !estado.gerando ? aoGerar : null,
          motivoDesabilitado: estado.gerando
              ? AppStrings.laudoGerando
              : AppStrings.laudoGerarBloqueado,
          ocupaLargura: true,
        ),
        if (estado.falhou) ...[
          const SizedBox(height: AppSpacing.sm),
          const AppSituacao(
            icone: NomeIcone.alerta,
            titulo: AppStrings.laudoErroGerar,
          ),
        ],
        if (laudo != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: AppSituacao(
              icone: NomeIcone.confirmacao,
              titulo: AppStrings.laudoGeradoEm(
                AppStrings.data(laudo.geradoEm),
                AppStrings.hora(laudo.geradoEm),
              ),
              texto: mudou ? AppStrings.laudoTextoMudou : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppBotao.secundario(
                rotulo: AppStrings.laudoCompartilhar,
                aoTocar: saindo ? null : aoCompartilhar,
                motivoDesabilitado: AppStrings.laudoGerando,
              ),
              AppBotao.secundario(
                rotulo: AppStrings.laudoImprimir,
                aoTocar: saindo ? null : aoImprimir,
                motivoDesabilitado: AppStrings.laudoGerando,
              ),
            ],
          ),
          if (falhouSaida) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppSituacao(
              icone: NomeIcone.alerta,
              titulo: AppStrings.laudoErroSaida,
            ),
          ],
        ],
      ],
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

/// Um item da conferência: o que é, em que pé está — em ícone E texto — e,
/// quando não está resolvido, o que fazer.
class _ItemDaConferencia extends StatelessWidget {
  const _ItemDaConferencia({
    required this.item,
    required this.situacao,
    required this.pacienteId,
    required this.analiseId,
  });

  final ItemDaConferencia item;
  final SituacaoDoItem situacao;
  final String pacienteId;
  final String analiseId;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final (nome, explicacao) = switch (item) {
      ItemDaConferencia.consentimento => (
        AppStrings.laudoItemConsentimento,
        AppStrings.laudoItemConsentimentoFalta,
      ),
      ItemDaConferencia.analiseConcluida => (
        AppStrings.laudoItemAnalise,
        AppStrings.laudoItemAnaliseFalta,
      ),
      ItemDaConferencia.qualidadeDasAmostras => (
        AppStrings.laudoItemQualidade,
        AppStrings.laudoItemQualidadeAviso,
      ),
      ItemDaConferencia.capeV => (
        AppStrings.laudoItemCapeV,
        AppStrings.laudoItemCapeVAviso,
      ),
      ItemDaConferencia.conclusao => (
        AppStrings.laudoItemConclusao,
        AppStrings.laudoItemConclusaoFalta,
      ),
    };
    // Sem verde, amarelo ou vermelho: são reservados a status de medida e
    // saturação. A situação vem no ícone e, sobretudo, no texto.
    final (icone, rotulo) = switch (situacao) {
      SituacaoDoItem.ok => (
        NomeIcone.confirmacao,
        AppStrings.laudoConferenciaOk,
      ),
      SituacaoDoItem.pendente => (
        NomeIcone.alerta,
        AppStrings.laudoConferenciaPendente,
      ),
      SituacaoDoItem.aviso => (
        NomeIcone.informacao,
        AppStrings.laudoConferenciaAviso,
      ),
    };

    // Levam à tela que resolve, e voltam para cá: `push`.
    final acao = switch ((item, situacao)) {
      (ItemDaConferencia.consentimento, SituacaoDoItem.pendente) =>
        AppBotao.secundario(
          rotulo: AppStrings.laudoIrParaConsentimento,
          aoTocar: () => context.pushNamed(
            AppRoutes.consentimentoNome,
            pathParameters: {AppRoutes.paramPacienteId: pacienteId},
          ),
        ),
      (ItemDaConferencia.capeV, SituacaoDoItem.aviso) => AppBotao.secundario(
        rotulo: AppStrings.laudoIrParaCapeV,
        aoTocar: () => context.pushNamed(
          AppRoutes.capeVNome,
          pathParameters: {
            AppRoutes.paramPacienteId: pacienteId,
            AppRoutes.paramAnaliseId: analiseId,
          },
        ),
      ),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppIcone(
              nome: icone,
              cor: situacao == SituacaoDoItem.ok
                  ? AppColors.roxoProfundo
                  : AppColors.cinzaChumbo,
              tamanho: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: textos.titleMedium),
                      Text(rotulo, style: secundario),
                      if (situacao != SituacaoDoItem.ok)
                        Text(explicacao, style: textos.bodySmall),
                    ],
                  ),
                ),
                if (acao != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  acao,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O que vai no laudo, no lugar da pré-visualização A4 fora do desktop.
class _Resumo extends StatelessWidget {
  const _Resumo({required this.conteudo});

  final ConteudoDoLaudo conteudo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodyMedium?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final quando = conteudo.realizadaEm;
    final conclusao = conteudo.conclusao;

    Widget linha(String texto, {TextStyle? estilo}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Text(texto, style: estilo ?? textos.bodyMedium),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.branco,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Titulo(AppStrings.laudoResumoTitulo),
          if (conteudo.exemplo)
            linha(AppStrings.laudoDocExemplo, estilo: textos.titleMedium),
          linha(AppStrings.consentimentoPaciente(conteudo.nomeDoPaciente)),
          if (quando != null)
            linha(
              AppStrings.resultadoGravadoEm(
                AppStrings.data(quando),
                AppStrings.hora(quando),
              ),
            ),
          linha(AppStrings.laudoResumoMedidas(conteudo.medidas.length)),
          linha(
            conteudo.capeV == null
                ? AppStrings.laudoResumoSemCapeV
                : AppStrings.laudoResumoComCapeV,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(AppStrings.laudoResumoConclusao, style: textos.titleSmall),
          Text(
            conclusao.isEmpty ? AppStrings.laudoResumoSemConclusao : conclusao,
            style: secundario,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
