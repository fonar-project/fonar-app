import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_movimento.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/passo_do_guia.dart';
import '../alvos_do_guia.dart';

/// Abre o guia por cima de tudo e espera que ele feche: concluído, pulado
/// (o botão ou Esc) ou pelo voltar do sistema — os três valem o mesmo.
///
/// É uma rota, como o `appConfirmar`: prende o foco (Tab circula dentro do
/// balão), anuncia-se ao leitor de tela e devolve o foco ao fechar. A
/// barreira da rota só segura os toques; o véu, com o recorte do elemento,
/// é o do guia.
Future<void> mostrarGuia(
  BuildContext context, {
  List<PassoDoGuia> passos = passosDoGuiaDoInicio,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  RawDialogRoute<void>(
    barrierDismissible: false,
    barrierColor: null,
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    transitionDuration: AppMovimento.duracao(context, AppMovimento.rapida),
    transitionBuilder: (_, animacao, _, filho) =>
        FadeTransition(opacity: animacao, child: filho),
    pageBuilder: (_, _, _) => GuiaNaTela(passos: passos),
  ),
);

/// O guia aberto: o véu com o recorte do elemento do passo e o balão que diz
/// o que ele é.
///
/// O recorte não anima de um elemento para o outro: o balão muda de lugar e
/// só o texto novo entra, com a entrada curta do `AppMovimento` — nada com
/// movimento reduzido.
class GuiaNaTela extends ConsumerStatefulWidget {
  const GuiaNaTela({required this.passos, super.key});

  final List<PassoDoGuia> passos;

  @override
  ConsumerState<GuiaNaTela> createState() => _GuiaNaTelaState();
}

class _GuiaNaTelaState extends ConsumerState<GuiaNaTela> {
  final _area = GlobalKey();
  var _indice = 0;

  /// O elemento do passo, nas coordenadas do guia. Nulo: não está na tela.
  Rect? _recorte;

  /// Já se mediu ao menos uma vez — antes disso, nada se desenha, para o
  /// balão não aparecer num lugar e pular para outro.
  var _medido = false;
  int? _anunciado;

  PassoDoGuia get _passo => widget.passos[_indice];
  bool get _ultimo => _indice == widget.passos.length - 1;

  Rect? _ondeEsta(PassoDoGuia passo) {
    final area = _area.currentContext?.findRenderObject();
    if (area is! RenderBox || !area.hasSize) return null;
    return ref.read(alvosDoGuiaProvider).onde(passo.papel, area);
  }

  /// Depois de cada quadro: o elemento pode ter mudado de lugar (a janela
  /// mudou de tamanho, a lista terminou de entrar). Mede de novo até parar.
  void _medir() {
    if (!mounted) return;
    final recorte = _ondeEsta(_passo);
    if (!_medido || recorte != _recorte) {
      setState(() {
        _recorte = recorte;
        _medido = true;
      });
    }
    _anunciar();
  }

  void _anunciar() {
    if (_anunciado == _indice) return;
    _anunciado = _indice;
    final texto = _passo.textoQuando(comAlvo: _recorte != null);
    final onde = widget.passos.length == 1
        ? AppStrings.dicaRotulo
        : AppStrings.guiaPasso(_indice + 1, widget.passos.length);
    SemanticsService.sendAnnouncement(
      View.of(context),
      '$onde. ${_passo.titulo}. $texto',
      Directionality.of(context),
    );
  }

  /// Muda de passo já com o lugar novo: o balão nunca aparece com o texto
  /// de um elemento ao lado de outro.
  void _irPara(int indice) {
    setState(() {
      _indice = indice;
      _recorte = _ondeEsta(_passo);
    });
    _anunciar();
  }

  void _fechar() => Navigator.of(context).pop();

  void _proximo() => _ultimo ? _fechar() : _irPara(_indice + 1);

  @override
  Widget build(BuildContext context) {
    // Muda a janela, muda o lugar do elemento: reconstrói e mede de novo.
    MediaQuery.sizeOf(context);
    final margens = MediaQuery.paddingOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());

    final recorte = _recorte?.inflate(_folga);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _fechar},
      child: Stack(
        key: _area,
        fit: StackFit.expand,
        children: [
          if (_medido) ...[
            ExcludeSemantics(
              child: CustomPaint(
                painter: _Veu(
                  recorte: recorte,
                  cor: context.cores.barreira,
                  anelDeDentro: context.cores.acento,
                  anelDeFora: context.cores.fundo,
                ),
              ),
            ),
            CustomSingleChildLayout(
              delegate: _LugarDoBalao(
                recorte: recorte,
                margens: margens + const EdgeInsets.all(AppSpacing.md),
              ),
              child: _Balao(
                passo: _passo,
                indice: _indice,
                total: widget.passos.length,
                comAlvo: _recorte != null,
                aoPular: _fechar,
                aoAnterior: _indice == 0 ? null : () => _irPara(_indice - 1),
                aoProximo: _proximo,
                ultimo: _ultimo,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// O recorte passa um pouco do elemento, para o anel não cobrir a borda.
  static const _folga = 6.0;
}

/// O véu escurece tudo menos o elemento do passo, que fica com um anel em
/// volta: claro por fora (aparece sobre o véu e sobre a barra lateral roxa)
/// e no acento por dentro (aparece sobre o fundo da tela).
class _Veu extends CustomPainter {
  _Veu({
    required this.recorte,
    required this.cor,
    required this.anelDeDentro,
    required this.anelDeFora,
  });

  final Rect? recorte;
  final Color cor;
  final Color anelDeDentro;
  final Color anelDeFora;

  static const _raio = Radius.circular(12);

  @override
  void paint(Canvas canvas, Size size) {
    final veu = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    final buraco = recorte == null
        ? null
        : RRect.fromRectAndRadius(recorte!, _raio);
    if (buraco != null) veu.addRRect(buraco);
    canvas.drawPath(veu, Paint()..color = cor);
    if (buraco == null) return;
    canvas
      ..drawRRect(
        buraco.inflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = anelDeFora,
      )
      ..drawRRect(
        buraco,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = anelDeDentro,
      );
  }

  @override
  bool shouldRepaint(_Veu antigo) =>
      antigo.recorte != recorte ||
      antigo.cor != cor ||
      antigo.anelDeDentro != anelDeDentro ||
      antigo.anelDeFora != anelDeFora;
}

/// Põe o balão ao lado do elemento, onde couber: embaixo, em cima, à
/// direita ou à esquerda. Elemento na faixa esquerda da tela — a barra
/// lateral — prefere a direita. Sem elemento, ou sem lugar, no centro.
class _LugarDoBalao extends SingleChildLayoutDelegate {
  _LugarDoBalao({required this.recorte, required this.margens});

  final Rect? recorte;
  final EdgeInsets margens;

  /// Pular, Anterior e Próximo cabem numa linha no desktop.
  static const _larguraMaxima = 440.0;
  static const _vao = AppSpacing.sm;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints restricoes) {
    final largura = math.min(
      _larguraMaxima,
      restricoes.maxWidth - margens.horizontal,
    );
    return BoxConstraints(
      minWidth: largura,
      maxWidth: largura,
      maxHeight: math.max(0, restricoes.maxHeight - margens.vertical),
    );
  }

  @override
  Offset getPositionForChild(Size area, Size balao) {
    double x(double centro) => (centro - balao.width / 2).clamp(
      margens.left,
      math.max(margens.left, area.width - margens.right - balao.width),
    );
    double y(double centro) => (centro - balao.height / 2).clamp(
      margens.top,
      math.max(margens.top, area.height - margens.bottom - balao.height),
    );
    final centro = Offset(x(area.width / 2), y(area.height / 2));

    final r = recorte;
    if (r == null) return centro;

    final embaixo =
        r.bottom + _vao + balao.height <= area.height - margens.bottom
        ? Offset(x(r.center.dx), r.bottom + _vao)
        : null;
    final emCima = r.top - _vao - balao.height >= margens.top
        ? Offset(x(r.center.dx), r.top - _vao - balao.height)
        : null;
    final aDireita = r.right + _vao + balao.width <= area.width - margens.right
        ? Offset(r.right + _vao, y(r.center.dy))
        : null;
    final aEsquerda = r.left - _vao - balao.width >= margens.left
        ? Offset(r.left - _vao - balao.width, y(r.center.dy))
        : null;

    final naFaixaEsquerda = r.center.dx < area.width / 3;
    return (naFaixaEsquerda ? aDireita : null) ??
        embaixo ??
        emCima ??
        aDireita ??
        aEsquerda ??
        Offset(x(area.width / 2), area.height - margens.bottom - balao.height);
  }

  @override
  bool shouldRelayout(_LugarDoBalao antigo) =>
      antigo.recorte != recorte || antigo.margens != margens;
}

class _Balao extends StatelessWidget {
  const _Balao({
    required this.passo,
    required this.indice,
    required this.total,
    required this.comAlvo,
    required this.aoPular,
    required this.aoAnterior,
    required this.aoProximo,
    required this.ultimo,
  });

  final PassoDoGuia passo;
  final int indice;
  final int total;
  final bool comAlvo;
  final VoidCallback aoPular;
  final VoidCallback? aoAnterior;
  final VoidCallback aoProximo;
  final bool ultimo;

  /// Um passo só é a dica de uma tela: sem número, sem "Pular", e o botão
  /// é "Entendi".
  bool get _dica => total == 1;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Material(
      color: context.cores.fundo,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.bordaMedia,
        side: BorderSide(color: context.cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: _dica ? AppStrings.dicaRotulo : AppStrings.guiaRotulo,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Só o texto troca: os botões ficam, e o foco fica no
              // "Próximo" de um passo para o outro.
              AppTrocaAnimada(
                chave: indice,
                alinhamento: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_dica
                              ? AppStrings.dicaRotulo
                              : AppStrings.guiaPasso(indice + 1, total))
                          .toUpperCase(),
                      style: AppTypography.overline.copyWith(
                        color: context.cores.secundario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Semantics(
                      header: true,
                      child: Text(passo.titulo, style: textos.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      passo.textoQuando(comAlvo: comAlvo),
                      style: textos.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_dica)
                Align(
                  alignment: Alignment.centerRight,
                  child: AppBotao.primario(
                    rotulo: AppStrings.dicaEntendi,
                    aoTocar: aoProximo,
                    autofocus: true,
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Pular(aoTocar: aoPular),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (aoAnterior case final voltar?)
                          AppBotao.secundario(
                            key: const ValueKey('anterior'),
                            rotulo: AppStrings.guiaAnterior,
                            aoTocar: voltar,
                          ),
                        AppBotao.primario(
                          key: const ValueKey('proximo'),
                          rotulo: ultimo
                              ? AppStrings.guiaConcluir
                              : AppStrings.guiaProximo,
                          aoTocar: aoProximo,
                          autofocus: true,
                        ),
                      ],
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

/// "Pular o guia": sempre à vista, com menos peso que o "Próximo".
class _Pular extends StatelessWidget {
  const _Pular({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => AppToque(
    aoTocar: aoTocar,
    raio: AppRadius.bordaPequena,
    conteudo: (context) => ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.alvoDeToqueMinimo,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Text(
            AppStrings.guiaPular,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.cores.acento,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: context.cores.acento,
            ),
          ),
        ),
      ),
    ),
  );
}
