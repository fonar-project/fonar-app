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
import '../../../../design_system/widgets/app_escala_visual.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_mensagem_de_campo.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/repositorio_analises_placeholder.dart';
import '../../../analise/domain/resultado_da_analise.dart';
import '../../../analise/presentation/aviso_de_outro_paciente.dart';
import '../../../captura/domain/amostra.dart';
import '../../../fila/presentation/fila_controlador.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../reproducao/presentation/widgets/player_de_amostra.dart';
import '../../domain/avaliacao_cape_v.dart';
import '../apresentacao_cape_v.dart';
import '../cape_v_controlador.dart';

/// Tela 08 — escala CAPE-V.
///
/// Tela cheia dedicada em qualquer largura, como pede o CLAUDE.md para o
/// celular: marcar seis escalas com o paciente ao lado não pode dividir
/// espaço com navegação. No desktop, as mesmas escalas em largura de leitura.
///
/// É registro do julgamento do profissional — a tela não sugere nota, não
/// pré-marca nada e não comenta o que foi marcado.
///
/// TODO(clínico): o protótipo põe "leve", "moderado" e "severo" sob a régua.
/// Onde cada âncora fica na linha, e com que termo, é do protocolo — até a
/// orientação dizer, a régua só tem os números.
///
/// TODO(clínico): o número aparece enquanto se marca. Na folha de papel
/// quem avalia não vê o número, e vê-lo pode influenciar a marcação. Se a
/// orientação preferir escondê-lo durante a avaliação, o ajuste é no
/// `AppEscalaVisual`.
class CapeVPage extends ConsumerWidget {
  const CapeVPage({
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
    final analise = ref.watch(
      analiseDoPacienteProvider((pacienteId: pacienteId, analiseId: analiseId)),
    );
    final estado = ref.watch(capeVControladorProvider(analiseId));
    void tentarDeNovo() {
      ref.invalidate(analiseProvider(analiseId));
      ref.invalidate(capeVControladorProvider(analiseId));
    }

    final nomeDoPaciente = ref.watch(pacienteProvider(pacienteId)).value?.nome;
    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);
            final compacta = largura == LarguraDeTela.compacta;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCabecalhoDeTarefa(
                  titulo: AppStrings.capeVTitulo,
                  aoVoltar: () => _voltar(context),
                  largura: largura,
                  subtitulo: nomeDoPaciente,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: pacienteId,
                      nome: nomeDoPaciente,
                    ),
                    Trilhas.resultado(
                      context,
                      pacienteId: pacienteId,
                      analiseId: analiseId,
                    ),
                    ItemDaTrilha(AppStrings.capeVTitulo),
                  ],
                  situacao: AppStrings.situacaoCapeV,
                ),
                Expanded(
                  child: switch ((analise, estado)) {
                    // A análise precisa ser deste paciente — ver `daPaciente`.
                    (AsyncError(:final error), _)
                        when error is AnaliseDeOutroPaciente =>
                      AvisoDeOutroPaciente(aoVoltar: () => _voltar(context)),
                    (AsyncError(), _) || (_, AsyncError()) => AppEstado.central(
                      titulo: AppStrings.capeVErroCarregar,
                      acao: AppBotao.secundario(
                        rotulo: AppStrings.tentarNovamente,
                        aoTocar: tentarDeNovo,
                      ),
                    ),
                    (AsyncData(), AsyncData(:final value)) => _Formulario(
                      pacienteId: pacienteId,
                      analiseId: analiseId,
                      estado: value,
                      compacta: compacta,
                      aoRegistrar: () => _voltar(context),
                    ),
                    _ => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.roxoProfundo,
                      ),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({
    required this.pacienteId,
    required this.analiseId,
    required this.estado,
    required this.compacta,
    required this.aoRegistrar,
  });

  final String pacienteId;
  final String analiseId;
  final EstadoCapeV estado;
  final bool compacta;
  final VoidCallback aoRegistrar;

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  late final _comentarios = TextEditingController(
    text: widget.estado.comentariosIniciais,
  );

  @override
  void dispose() {
    _comentarios.dispose();
    super.dispose();
  }

  CapeVControlador get _controlador =>
      ref.read(capeVControladorProvider(widget.analiseId).notifier);

  Future<void> _registrar() async {
    final registrou = await _controlador.registrar(
      pacienteId: widget.pacienteId,
      comentarios: _comentarios.text,
    );
    if (registrou && mounted) widget.aoRegistrar();
  }

  /// A escala de [parametro] em tela cheia — no celular, onde a linha de
  /// 100 mm não cabe com precisão na lista. Lá se avança de um parâmetro ao
  /// outro; o formulário é o mesmo controlador.
  void _abrir(ParametroCapeV parametro) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          _EscalaEmTelaCheia(analiseId: widget.analiseId, inicial: parametro),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final textos = Theme.of(context).textTheme;
    final ocupado = estado.registrando;
    final compacta = widget.compacta;
    final lateral = compacta ? AppSpacing.md : AppSpacing.xl;

    final registrar = AppBotao.primario(
      rotulo: ocupado ? AppStrings.capeVRegistrando : AppStrings.capeVRegistrar,
      aoTocar: _registrar,
      ocupaLargura: compacta,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fora da rolagem no desktop: ouve-se enquanto se marca.
        if (!compacta)
          _Faixa(embaixo: true, child: _Ouvir(analiseId: widget.analiseId)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: lateral,
              vertical: AppSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (compacta) ...[
                      _Ouvir(analiseId: widget.analiseId),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      AppStrings.capeVExplicacao,
                      style: textos.bodyMedium?.copyWith(
                        color: AppColors.secundarioSobreCreme,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final parametro in ParametroCapeV.values) ...[
                      if (compacta)
                        _ParametroCompacto(
                          parametro: parametro,
                          nota: estado.notas[parametro] ?? const NotaCapeV(),
                          problema: estado.problemas[parametro],
                          aoAbrir: ocupado ? null : () => _abrir(parametro),
                        )
                      else
                        _Parametro(
                          parametro: parametro,
                          nota: estado.notas[parametro] ?? const NotaCapeV(),
                          problema: estado.problemas[parametro],
                          habilitado: !ocupado,
                          controlador: _controlador,
                        ),
                      SizedBox(
                        height: compacta ? AppSpacing.sm : AppSpacing.md,
                      ),
                    ],
                    AppCampoTexto(
                      rotulo: AppStrings.capeVComentarios,
                      controlador: _comentarios,
                      somenteLeitura: ocupado,
                      linhas: 3,
                      capitalizacao: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Registrar preso embaixo: com seis escalas, o botão no fim da
        // página ficava longe de quem acabou de marcar a última.
        _Faixa(
          embaixo: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: compacta
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  registrar,
                  AppMensagemDeCampo(
                    erro: estado.erroGeral,
                    corDoApoio: AppColors.secundarioSobreCreme,
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

/// Uma faixa presa no topo ou embaixo da tela, separada por uma linha.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.embaixo, required this.child});

  /// A linha fica embaixo (faixa do topo) ou em cima (rodapé).
  final bool embaixo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borda = BorderSide(color: AppColors.lavandaClaro);
    final compacta =
        Breakpoints.de(MediaQuery.sizeOf(context).width) ==
        LarguraDeTela.compacta;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: embaixo
            ? const Border(bottom: borda)
            : const Border(top: borda),
      ),
      child: SafeArea(
        top: false,
        bottom: !embaixo,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A amostra que se avalia, para ouvir enquanto se marca. Com as duas
/// tarefas no aparelho, escolhe-se qual.
class _Ouvir extends ConsumerStatefulWidget {
  const _Ouvir({required this.analiseId});

  final String analiseId;

  @override
  ConsumerState<_Ouvir> createState() => _OuvirState();
}

class _OuvirState extends ConsumerState<_Ouvir> {
  TarefaDeGravacao? _escolhida;

  @override
  Widget build(BuildContext context) {
    final audios = ref.watch(amostrasDaAnaliseProvider(widget.analiseId));
    if (audios.isEmpty) {
      return Text(
        AppStrings.resultadoAudioIndisponivel,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.secundarioSobreCreme),
      );
    }
    final tarefa = audios.containsKey(_escolhida)
        ? _escolhida!
        : audios.keys.first;
    final amostra = audios[tarefa]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (audios.length > 1)
          AppEscolhaUnica<TarefaDeGravacao>(
            rotulo: AppStrings.capeVAmostra,
            opcoes: [
              for (final t in audios.keys)
                AppOpcao(valor: t, rotulo: _nomeDaTarefa(t)),
            ],
            selecionado: tarefa,
            aoEscolher: (t) => setState(() => _escolhida = t),
          ),
        PlayerDeAmostra(
          // Uma chave por amostra: trocar de tarefa não herda o estado.
          key: ValueKey(amostra.caminho),
          caminho: amostra.caminho,
          rotulo: _nomeDaTarefa(tarefa),
          duracaoConhecida: amostra.duracao,
        ),
      ],
    );
  }
}

String _nomeDaTarefa(TarefaDeGravacao tarefa) => switch (tarefa) {
  TarefaDeGravacao.vogalSustentada => AppStrings.tarefaVogalTitulo,
  TarefaDeGravacao.falaEncadeada => AppStrings.tarefaFalaTitulo,
};

class _Parametro extends StatelessWidget {
  const _Parametro({
    required this.parametro,
    required this.nota,
    required this.problema,
    required this.habilitado,
    required this.controlador,
  });

  final ParametroCapeV parametro;
  final NotaCapeV nota;
  final ProblemaNaNota? problema;
  final bool habilitado;
  final CapeVControlador controlador;

  @override
  Widget build(BuildContext context) {
    // Cada problema aparece junto do controle que o resolve.
    String? erroSe(ProblemaNaNota p) =>
        problema == p ? mensagemDoProblema(p) : null;

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
          AppEscalaVisual(
            rotulo: parametro.nome,
            valor: nota.valor,
            aoMudar: habilitado
                ? (v) => controlador.marcar(parametro, v)
                : null,
            rotuloMinimo: AppStrings.capeVSemDesvio,
            rotuloMaximo: AppStrings.capeVDesvioExtremo,
            textoNaoMarcado: AppStrings.capeVNaoMarcado,
            erro: erroSe(ProblemaNaNota.naoMarcada),
          ),
          _Qualificacao(
            parametro: parametro,
            nota: nota,
            problema: problema,
            habilitado: habilitado,
            controlador: controlador,
          ),
        ],
      ),
    );
  }
}

/// Consistência e sentido do desvio. Só aparecem com desvio marcado: sem
/// desvio, não há o que qualificar.
class _Qualificacao extends StatelessWidget {
  const _Qualificacao({
    required this.parametro,
    required this.nota,
    required this.problema,
    required this.habilitado,
    required this.controlador,
  });

  final ParametroCapeV parametro;
  final NotaCapeV nota;
  final ProblemaNaNota? problema;
  final bool habilitado;
  final CapeVControlador controlador;

  @override
  Widget build(BuildContext context) {
    if (!nota.temDesvio) return const SizedBox.shrink();
    String? erroSe(ProblemaNaNota p) =>
        problema == p ? mensagemDoProblema(p) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        AppEscolhaUnica<Consistencia>(
          rotulo: AppStrings.capeVConsistencia,
          opcoes: [
            for (final c in Consistencia.values)
              AppOpcao(valor: c, rotulo: nomeDaConsistencia(c)),
          ],
          selecionado: nota.consistencia,
          aoEscolher: habilitado
              ? (c) => controlador.definirConsistencia(parametro, c)
              : null,
          erro: erroSe(ProblemaNaNota.semConsistencia),
        ),
        if (parametro.temDirecao) ...[
          const SizedBox(height: AppSpacing.sm),
          AppEscolhaUnica<DirecaoDoDesvio>(
            rotulo: AppStrings.capeVSentido,
            opcoes: [
              for (final d in DirecaoDoDesvio.values)
                AppOpcao(valor: d, rotulo: parametro.nomeDaDirecao(d)),
            ],
            selecionado: nota.direcao,
            aoEscolher: habilitado
                ? (d) => controlador.definirDirecao(parametro, d)
                : null,
            erro: erroSe(ProblemaNaNota.semDirecao),
          ),
        ],
      ],
    );
  }
}

/// No celular: o parâmetro resumido — nome, número, a linha com a marca —
/// e "Abrir escala", que leva à escala em tela cheia.
class _ParametroCompacto extends StatelessWidget {
  const _ParametroCompacto({
    required this.parametro,
    required this.nota,
    required this.problema,
    required this.aoAbrir,
  });

  final ParametroCapeV parametro;
  final NotaCapeV nota;
  final ProblemaNaNota? problema;
  final VoidCallback? aoAbrir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final valor = nota.valor;
    final resumo = valor == null
        ? AppStrings.capeVNaoMarcado
        : resumirNota(parametro, nota);

    final conteudo = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm,
            children: [
              Text(parametro.nome, style: textos.titleMedium),
              if (valor == null)
                Text(AppStrings.capeVNaoMarcado, style: secundario)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$valor',
                      style: AppTypography.medidaCompacta.copyWith(
                        color: AppColors.cinzaChumbo,
                      ),
                    ),
                    Text(' /100', style: secundario),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 14,
            child: CustomPaint(painter: _LinhaCompacta(valor: valor)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              if (valor != null && nota.temDesvio)
                Text(
                  resumo.split(' · ').skip(1).join(' · '),
                  style: secundario,
                ),
              Text(
                '${AppStrings.capeVAbrirEscala} ›',
                style: textos.labelLarge?.copyWith(
                  color: AppColors.roxoProfundo,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.roxoProfundo,
                ),
              ),
            ],
          ),
          if (problema case final p?)
            AppMensagemDeCampo(
              erro: mensagemDoProblema(p),
              corDoApoio: AppColors.secundarioSobreCreme,
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.branco,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Semantics(
        // Um nó por parâmetro: "Rugosidade, 31, consistente. Abrir escala".
        label: '${parametro.nome}, $resumo. ${AppStrings.capeVAbrirEscala}',
        button: true,
        child: ExcludeSemantics(
          child: aoAbrir == null
              ? conteudo
              : AppToque(
                  aoTocar: aoAbrir!,
                  raio: AppRadius.bordaMedia,
                  child: conteudo,
                ),
        ),
      ),
    );
  }
}

/// A linha do cartão compacto, com a marca. Só leitura.
class _LinhaCompacta extends CustomPainter {
  _LinhaCompacta({required this.valor});

  final int? valor;

  @override
  void paint(Canvas canvas, Size size) {
    final meio = size.height / 2;
    canvas.drawLine(
      Offset(0, meio),
      Offset(size.width, meio),
      Paint()
        ..color = AppColors.lavandaClaro
        ..strokeWidth = 2,
    );
    if (valor case final v?) {
      final x = size.width * v / 100;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = AppColors.roxoProfundo
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_LinhaCompacta antes) => antes.valor != valor;
}

/// Um parâmetro por vez, com a régua na largura toda — deitado, de ponta a
/// ponta da tela. Anterior e próximo percorrem os seis sem voltar à lista.
class _EscalaEmTelaCheia extends ConsumerStatefulWidget {
  const _EscalaEmTelaCheia({required this.analiseId, required this.inicial});

  final String analiseId;
  final ParametroCapeV inicial;

  @override
  ConsumerState<_EscalaEmTelaCheia> createState() => _EscalaEmTelaCheiaState();
}

class _EscalaEmTelaCheiaState extends ConsumerState<_EscalaEmTelaCheia> {
  late var _parametro = widget.inicial;

  @override
  Widget build(BuildContext context) {
    final estado =
        ref.watch(capeVControladorProvider(widget.analiseId)).value ??
        const EstadoCapeV();
    final controlador = ref.read(
      capeVControladorProvider(widget.analiseId).notifier,
    );
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
    );
    final todos = ParametroCapeV.values;
    final i = todos.indexOf(_parametro);
    final nota = estado.notas[_parametro] ?? const NotaCapeV();
    final problema = estado.problemas[_parametro];
    final habilitado = !estado.registrando;
    final emPe = MediaQuery.orientationOf(context) == Orientation.portrait;
    void ir(int j) => setState(() => _parametro = todos[j]);
    void concluir() => Navigator.of(context).pop();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.lavandaClaro),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: AppStrings.voltar,
                          child: AppToque(
                            aoTocar: concluir,
                            raio: AppRadius.bordaPequena,
                            child: const SizedBox.square(
                              dimension: AppSpacing.alvoDeToqueMinimo,
                              child: Center(
                                child: AppIcone(
                                  nome: NomeIcone.voltar,
                                  cor: AppColors.roxoProfundo,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  _parametro.nome,
                                  style: textos.titleMedium,
                                ),
                              ),
                              Text(
                                AppStrings.capeVParametroDe(
                                  i + 1,
                                  todos.length,
                                ),
                                style: secundario,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        // Nas pontas, o botão some em vez de ficar apagado.
                        if (i > 0)
                          AppBotao.secundario(
                            rotulo: AppStrings.capeVAnterior,
                            aoTocar: () => ir(i - 1),
                          ),
                        if (i < todos.length - 1)
                          AppBotao.secundario(
                            rotulo: AppStrings.capeVProximo,
                            aoTocar: () => ir(i + 1),
                          ),
                        AppBotao.primario(
                          rotulo: AppStrings.capeVConcluir,
                          aoTocar: concluir,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (emPe) ...[
                      Row(
                        children: [
                          const AppIcone(nome: NomeIcone.girarAparelho),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              AppStrings.capeVGireAparelho,
                              style: textos.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _Ouvir(analiseId: widget.analiseId),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: nota.valor == null
                          ? Text(AppStrings.capeVNaoMarcado, style: secundario)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${nota.valor}',
                                  style: AppTypography.medidaDestaque.copyWith(
                                    color: AppColors.cinzaChumbo,
                                  ),
                                ),
                                Text(' /100', style: secundario),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppEscalaVisual(
                      // Uma escala por parâmetro: trocar de parâmetro não
                      // arrasta o foco nem o arraste da anterior.
                      key: ValueKey(_parametro),
                      rotulo: _parametro.nome,
                      valor: nota.valor,
                      aoMudar: habilitado
                          ? (v) => controlador.marcar(_parametro, v)
                          : null,
                      rotuloMinimo: AppStrings.capeVSemDesvio,
                      rotuloMaximo: AppStrings.capeVDesvioExtremo,
                      textoNaoMarcado: AppStrings.capeVNaoMarcado,
                      erro: problema == ProblemaNaNota.naoMarcada
                          ? mensagemDoProblema(problema!)
                          : null,
                      mostrarCabecalho: false,
                    ),
                    _Qualificacao(
                      parametro: _parametro,
                      nota: nota,
                      problema: problema,
                      habilitado: habilitado,
                      controlador: controlador,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
