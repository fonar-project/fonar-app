import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/trilhas.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../../app/app_estrutura.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../l10n/app_strings.dart';
import '../../data/imagem_do_servidor.dart';
import '../../data/repositorio_analises_placeholder.dart';
import '../../domain/resultado_da_analise.dart';
import '../aviso_de_outro_paciente.dart';

/// O espectrograma em tela cheia, para ler os detalhes — no celular, deitado.
///
/// A imagem é a que o servidor gerou, e só ela: aproximar e percorrer mudam
/// o que se vê, não o que foi medido. Nada aqui desenha ou recalcula o
/// espectrograma — ver a regra de processamento de áudio no CLAUDE.md.
///
/// Não força a rotação, como a evolução (US09) também não: o aparelho pode
/// estar na mão do paciente, e virar a tela sozinho no meio da consulta
/// assusta. Em pé e estreita, a tela sugere girar; deitada, a imagem ganha a
/// altura toda.
///
/// Tudo o que se faz com gesto também se faz sem ele: botões para aproximar
/// e ajustar, e, com a imagem em foco, setas, mais, menos e zero no teclado.
class EspectrogramaPage extends ConsumerStatefulWidget {
  const EspectrogramaPage({
    required this.pacienteId,
    required this.analiseId,
    super.key,
  });

  final String pacienteId;
  final String analiseId;

  /// Aproximação máxima, e o quanto cada toque em "Aproximar" aproxima.
  static const maximo = 6.0;
  static const passo = 1.5;

  @override
  ConsumerState<EspectrogramaPage> createState() => _EspectrogramaPageState();
}

class _EspectrogramaPageState extends ConsumerState<EspectrogramaPage> {
  final _visao = TransformationController();
  final _area = GlobalKey();
  final _foco = FocusNode(debugLabel: 'espectrograma');

  @override
  void dispose() {
    _visao.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _voltar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        AppRoutes.analiseResultadoNome,
        pathParameters: {
          AppRoutes.paramPacienteId: widget.pacienteId,
          AppRoutes.paramAnaliseId: widget.analiseId,
        },
      );
    }
  }

  Size get _tamanhoDaArea =>
      (_area.currentContext?.findRenderObject() as RenderBox?)?.size ??
      Size.zero;

  /// Aproxima (ou afasta) em torno do centro do que se vê. Sem animação: a
  /// resposta é imediata, e respeita quem pede menos movimento.
  void _aproximar(double fator) {
    final atual = _visao.value.getMaxScaleOnAxis();
    final alvo = (atual * fator).clamp(1.0, EspectrogramaPage.maximo);
    if (alvo <= 1.001) {
      _visao.value = Matrix4.identity();
      return;
    }
    final centro = _tamanhoDaArea.center(Offset.zero);
    final f = alvo / atual;
    _aplicar(
      (Matrix4.identity()
            ..translateByDouble(centro.dx, centro.dy, 0, 1)
            ..scaleByDouble(f, f, 1, 1)
            ..translateByDouble(-centro.dx, -centro.dy, 0, 1))
          .multiplied(_visao.value),
    );
  }

  /// Percorre a imagem aproximada: [direcao] em frações da área visível.
  void _percorrer(Offset direcao) {
    final area = _tamanhoDaArea;
    _aplicar(
      (Matrix4.identity()..translateByDouble(
            -direcao.dx * area.width,
            -direcao.dy * area.height,
            0,
            1,
          ))
          .multiplied(_visao.value),
    );
  }

  /// Aplica sem deixar a imagem sair da área: nenhuma borda vazia entra.
  void _aplicar(Matrix4 matriz) {
    final area = _tamanhoDaArea;
    final escala = matriz.getMaxScaleOnAxis();
    final t = matriz.getTranslation();
    final x = t.x.clamp(area.width * (1 - escala), 0.0);
    final y = t.y.clamp(area.height * (1 - escala), 0.0);
    _visao.value = matriz..setTranslationRaw(x, y, 0);
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent && evento is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    const setas = 0.1;
    final VoidCallback? acao = switch (evento.logicalKey) {
      LogicalKeyboardKey.arrowLeft => () => _percorrer(const Offset(-setas, 0)),
      LogicalKeyboardKey.arrowRight => () => _percorrer(const Offset(setas, 0)),
      LogicalKeyboardKey.arrowUp => () => _percorrer(const Offset(0, -setas)),
      LogicalKeyboardKey.arrowDown => () => _percorrer(const Offset(0, setas)),
      LogicalKeyboardKey.equal ||
      LogicalKeyboardKey.add ||
      LogicalKeyboardKey.numpadAdd => () => _aproximar(EspectrogramaPage.passo),
      LogicalKeyboardKey.minus || LogicalKeyboardKey.numpadSubtract =>
        () => _aproximar(1 / EspectrogramaPage.passo),
      LogicalKeyboardKey.digit0 ||
      LogicalKeyboardKey.numpad0 => () => _visao.value = Matrix4.identity(),
      _ => null,
    };
    if (acao == null) return KeyEventResult.ignored;
    acao();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final chave = (pacienteId: widget.pacienteId, analiseId: widget.analiseId);
    final analise = ref.watch(analiseDoPacienteProvider(chave));

    final nomeDoPaciente = ref
        .watch(pacienteProvider(widget.pacienteId))
        .value
        ?.nome;
    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);
            final compacta = largura == LarguraDeTela.compacta;

            final Widget conteudo = switch (analise) {
              AsyncData(value: ResultadoDaAnalise(:final espectrogramaUrl?)) =>
                _visor(espectrogramaUrl, compacta: compacta),
              AsyncData() => AppEstado.central(
                titulo: AppStrings.resultadoEspectrogramaIndisponivel,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.voltar,
                  aoTocar: _voltar,
                ),
              ),
              AsyncError(:final error) when error is AnaliseDeOutroPaciente =>
                AvisoDeOutroPaciente(aoVoltar: _voltar),
              AsyncError() => AppEstado.central(
                titulo: AppStrings.resultadoErroCarregar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.tentarNovamente,
                  aoTocar: () =>
                      ref.invalidate(analiseProvider(widget.analiseId)),
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
                  titulo: AppStrings.resultadoEspectrogramaTitulo,
                  aoVoltar: _voltar,
                  largura: largura,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: widget.pacienteId,
                      nome: nomeDoPaciente,
                    ),
                    Trilhas.resultado(
                      context,
                      pacienteId: widget.pacienteId,
                      analiseId: widget.analiseId,
                    ),
                    ItemDaTrilha(AppStrings.resultadoEspectrogramaTitulo),
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

  Widget _visor(String url, {required bool compacta}) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: context.cores.secundario,
    );
    final tela = MediaQuery.sizeOf(context);
    final emPe = MediaQuery.orientationOf(context) == Orientation.portrait;
    // Deitada e baixa: a imagem fica com toda a altura que der, e as dicas
    // saem do caminho.
    final baixa = !emPe && tela.height < 500;

    // Ocupa a altura que sobra — e rola só quando não sobra o bastante, com
    // o texto do sistema grande: aí a imagem mantém um mínimo legível, em
    // vez de sumir espremida entre as dicas e os botões.
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compacta && emPe)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      const AppIcone(nome: NomeIcone.girarAparelho),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          AppStrings.espectrogramaGireAparelho,
                          style: textos.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                // Altura exata como MEDIDA, não como tamanho: é o que a rolagem
                // pergunta para saber se tudo cabe. Na hora de desenhar, vale a
                // altura que o Expanded der — e a imagem fica com toda a sobra.
                child: SizedBox(
                  height: _alturaMinima,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Focus(
                      focusNode: _foco,
                      onKeyEvent: _tecla,
                      child: ListenableBuilder(
                        listenable: _foco,
                        // Foco visível: quem chega pelo teclado precisa saber que as
                        // setas agora mexem na imagem.
                        builder: (context, filho) => DecoratedBox(
                          position: DecorationPosition.foreground,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _foco.hasFocus
                                  ? context.cores.acento
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: filho,
                        ),
                        child: Semantics(
                          image: true,
                          label: AppStrings.resultadoEspectrogramaDescricao,
                          hint: AppStrings.espectrogramaAreaDica,
                          child: ClipRect(
                            key: _area,
                            child: GestureDetector(
                              // Tocar na imagem a põe em foco, para o teclado
                              // continuar dali.
                              onTap: _foco.requestFocus,
                              child: InteractiveViewer(
                                transformationController: _visao,
                                minScale: 1,
                                maxScale: EspectrogramaPage.maximo,
                                // Ocupa a área toda, e o `contain` encaixa a imagem nela —
                                // sem isso, fica no tamanho natural.
                                // No escuro, a área fica clara como a
                                // imagem — ver `AppMolduraDeImagem`.
                                child: ColoredBox(
                                  color: context.cores.molduraDeImagem,
                                  child: SizedBox.expand(
                                    child: Image(
                                      image: ref.watch(
                                        imagemDoServidorProvider,
                                      )(url),
                                      fit: BoxFit.contain,
                                      excludeFromSemantics: true,
                                      loadingBuilder: (_, filho, progresso) =>
                                          progresso == null
                                          ? filho
                                          : Center(
                                              child: CircularProgressIndicator(
                                                color: context.cores.acento,
                                              ),
                                            ),
                                      errorBuilder: (_, _, _) => Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.md,
                                          ),
                                          child: Text(
                                            AppStrings
                                                .resultadoEspectrogramaErro,
                                            style: textos.bodyMedium?.copyWith(
                                              color: context.cores.secundario,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  baixa ? 0 : AppSpacing.xs,
                  AppSpacing.md,
                  baixa ? AppSpacing.xs : AppSpacing.md,
                ),
                child: ValueListenableBuilder<Matrix4>(
                  valueListenable: _visao,
                  builder: (context, matriz, _) {
                    final noMaximo =
                        matriz.getMaxScaleOnAxis() >=
                        EspectrogramaPage.maximo - 1e-3;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppBotao.secundario(
                              rotulo: AppStrings.espectrogramaAproximar,
                              aoTocar: noMaximo
                                  ? null
                                  : () => _aproximar(EspectrogramaPage.passo),
                              motivoDesabilitado:
                                  AppStrings.espectrogramaNoMaximo,
                            ),
                            AppBotao.secundario(
                              rotulo: AppStrings.espectrogramaAjustar,
                              aoTocar: matriz.isIdentity()
                                  ? null
                                  : () => _visao.value = Matrix4.identity(),
                              motivoDesabilitado:
                                  AppStrings.espectrogramaNoTamanhoDaTela,
                            ),
                          ],
                        ),
                        if (!baixa) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppStrings.espectrogramaGestos,
                            style: secundario,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Menos que isto, e a imagem vira um borrão entre os controles.
  static const _alturaMinima = 220.0;
}
