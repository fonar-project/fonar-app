import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_movimento.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_icone.dart';

/// Peso visual do botão dentro da tela.
enum VarianteBotao {
  /// Ação principal da tela. No máximo um por tela.
  primario,

  /// Ação alternativa. Borda roxa, fundo transparente.
  secundario,
}

/// Botão do design system.
///
/// Por baixo é um botão do Material — o que significa que hover, foco de
/// teclado, resposta ao toque, alvo mínimo e semântica já vêm prontos e
/// testados. Aqui só entram os tokens do FONAR. Não troque por
/// `GestureDetector`: o Windows é usado com teclado e o `Tab` precisa parar
/// aqui.
///
/// ## Botão desabilitado sempre diz por quê
///
/// Passar `aoTocar: null` sem [motivoDesabilitado] é erro de programação e o
/// construtor recusa. A regra vem do design system — "estados desabilitados
/// sempre acompanham texto explicativo, nunca só a mudança de cor" — e vale
/// duplamente aqui: um botão apagado sem explicação, para quem não distingue o
/// cinza do roxo, é um botão que simplesmente não funciona.
class AppBotao extends StatelessWidget {
  const AppBotao({
    required this.rotulo,
    required this.aoTocar,
    this.variante = VarianteBotao.primario,
    this.icone,
    this.motivoDesabilitado,
    this.ocupaLargura = false,
    super.key,
  }) : assert(
         aoTocar != null || motivoDesabilitado != null,
         'Botão desabilitado precisa de motivoDesabilitado: o usuário tem de '
         'saber por que não pode agir. Cor apagada não é explicação.',
       );

  /// Atalho para o botão da ação principal.
  const AppBotao.primario({
    required String rotulo,
    required VoidCallback? aoTocar,
    NomeIcone? icone,
    String? motivoDesabilitado,
    bool ocupaLargura = false,
    Key? key,
  }) : this(
         rotulo: rotulo,
         aoTocar: aoTocar,
         variante: VarianteBotao.primario,
         icone: icone,
         motivoDesabilitado: motivoDesabilitado,
         ocupaLargura: ocupaLargura,
         key: key,
       );

  /// Atalho para a ação alternativa.
  const AppBotao.secundario({
    required String rotulo,
    required VoidCallback? aoTocar,
    NomeIcone? icone,
    String? motivoDesabilitado,
    bool ocupaLargura = false,
    Key? key,
  }) : this(
         rotulo: rotulo,
         aoTocar: aoTocar,
         variante: VarianteBotao.secundario,
         icone: icone,
         motivoDesabilitado: motivoDesabilitado,
         ocupaLargura: ocupaLargura,
         key: key,
       );

  /// Texto do botão. Verbo no infinitivo, dizendo o que vai acontecer.
  final String rotulo;

  /// `null` desabilita o botão — e aí [motivoDesabilitado] é obrigatório.
  final VoidCallback? aoTocar;

  final VarianteBotao variante;

  /// Ícone opcional à esquerda do rótulo. Decorativo: quem carrega a
  /// informação é o texto.
  final NomeIcone? icone;

  /// Por que o botão está desabilitado. Aparece abaixo dele e vai para o
  /// leitor de tela. Ex.: "Disponível depois de registrar o consentimento".
  final String? motivoDesabilitado;

  /// Esticar até a largura do pai. Usado no mobile, onde o botão principal
  /// ocupa a linha inteira.
  final bool ocupaLargura;

  bool get _desabilitado => aoTocar == null;

  @override
  Widget build(BuildContext context) {
    final botao = variante == VarianteBotao.primario
        ? _construirPrimario(context)
        : _construirSecundario(context);

    final comLargura = ocupaLargura
        ? SizedBox(width: double.infinity, child: botao)
        : botao;

    if (!_desabilitado) return comLargura;

    // O motivo é anunciado junto do rótulo, para o leitor de tela não ler
    // "botão desabilitado" e parar aí.
    return Semantics(
      hint: motivoDesabilitado,
      child: Column(
        crossAxisAlignment: ocupaLargura
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          comLargura,
          const SizedBox(height: AppSpacing.xs),
          ExcludeSemantics(
            child: Text(
              motivoDesabilitado!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.secundarioSobreCreme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPrimario(BuildContext context) {
    return FilledButton(
      onPressed: aoTocar,
      style: _estiloBase().copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) {
            return AppColors.lavandaClaro;
          }
          if (estados.contains(WidgetState.pressed)) {
            return AppColors.roxoPressionado;
          }
          if (estados.contains(WidgetState.hovered)) return AppColors.roxoHover;
          return AppColors.roxoProfundo;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.disabled)
              ? AppColors.secundarioSobreLavanda
              : AppColors.creme,
        ),
        // Anel de foco de 3 px por fora do botão. Sem isso, navegar por teclado
        // no desktop vira adivinhação.
        side: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.focused)
              ? const BorderSide(color: AppColors.roxoAnel, width: 3)
              : BorderSide.none,
        ),
      ),
      child: _conteudo(),
    );
  }

  Widget _construirSecundario(BuildContext context) {
    return OutlinedButton(
      onPressed: aoTocar,
      style: _estiloBase().copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.pressed) ||
              estados.contains(WidgetState.hovered)) {
            return AppColors.roxoVeu;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.disabled)
              ? AppColors.secundarioSobreCreme
              : AppColors.roxoProfundo,
        ),
        side: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) {
            return const BorderSide(color: AppColors.lavandaClaro);
          }
          if (estados.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.roxoProfundo, width: 3);
          }
          return const BorderSide(color: AppColors.roxoProfundo, width: 1.5);
        }),
      ),
      child: _conteudo(),
    );
  }

  ButtonStyle _estiloBase() => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(
      Size(0, AppSpacing.alvoDeToqueMinimo),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.lg + AppSpacing.xxs),
    ),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.bordaMedia),
    ),
    textStyle: WidgetStatePropertyAll(AppTypography.textTheme.labelLarge),
    animationDuration: AppMovimento.rapida,
    elevation: const WidgetStatePropertyAll(0),
    // A mudança de cor já está em `backgroundColor`; a tinta por cima do
    // Material duplicaria o efeito e sujaria o roxo.
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );

  Widget _conteudo() {
    if (icone == null) return Text(rotulo);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcone(nome: icone!, tamanho: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(rotulo)),
      ],
    );
  }
}
