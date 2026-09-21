import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_movimento.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_fundo.dart';
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
         aoTocar != null ||
             (motivoDesabilitado != null && motivoDesabilitado != ''),
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

  /// Altura do botão principal. Maior que o alvo mínimo de toque: é a ação que
  /// o profissional procura com o canto do olho.
  static const alturaPrimario = 52.0;

  /// Altura do secundário — o alvo mínimo de toque, nunca menos.
  static const alturaSecundario = AppSpacing.alvoDeToqueMinimo;

  bool get _desabilitado => aoTocar == null;

  @override
  Widget build(BuildContext context) {
    final botao = variante == VarianteBotao.primario
        ? _construirPrimario(context)
        : _construirSecundario(context);

    final comLargura = ocupaLargura
        ? SizedBox(width: double.infinity, child: botao)
        : botao;

    // Sem motivo, só em build de produção: o assert do construtor pega isso em
    // desenvolvimento. Em produção os asserts somem, e aí é melhor mostrar o
    // botão apagado sem explicação do que derrubar a tela inteira.
    final motivo = motivoDesabilitado?.trim() ?? '';
    if (!_desabilitado || motivo.isEmpty) return comLargura;

    // O motivo é anunciado junto do rótulo, para o leitor de tela não ler
    // "botão desabilitado" e parar aí.
    return Semantics(
      hint: motivo,
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
              motivo,
              // O tom vem do fundo declarado em volta: este mesmo motivo
              // aparece sobre o creme e dentro de faixa de aviso lavanda, e o
              // token claro cai para 4,48:1 na segunda.
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppFundo.secundarioDe(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPrimario(BuildContext context) {
    return FilledButton(
      onPressed: aoTocar,
      style: _estiloBase(context, alturaPrimario).copyWith(
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
        // Anel de foco de 3 px na cor de foco do projeto. Sem isso, navegar por
        // teclado no desktop vira adivinhação.
        side: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.focused)
              ? const BorderSide(color: AppColors.foco, width: 3)
              : BorderSide.none,
        ),
      ),
      child: _conteudo(),
    );
  }

  Widget _construirSecundario(BuildContext context) {
    return OutlinedButton(
      onPressed: aoTocar,
      style: _estiloBase(context, alturaSecundario).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.pressed) ||
              estados.contains(WidgetState.hovered)) {
            return AppColors.roxoVeu;
          }
          return Colors.transparent;
        }),
        // O secundário desabilitado não pinta fundo nenhum — quem aparece
        // atrás do rótulo é a superfície da tela. Dentro de um aviso lavanda o
        // token "sobre creme" daria 4,48:1 e reprovaria em AA.
        foregroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.disabled)
              ? AppFundo.secundarioDe(context)
              : AppColors.roxoProfundo,
        ),
        side: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) {
            return const BorderSide(color: AppColors.lavandaClaro);
          }
          if (estados.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.foco, width: 3);
          }
          return const BorderSide(color: AppColors.roxoProfundo, width: 1.5);
        }),
      ),
      child: _conteudo(),
    );
  }

  ButtonStyle _estiloBase(BuildContext context, double altura) => ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, altura)),
    // Respiro vertical só aparece quando o rótulo quebra linha (texto do
    // sistema ampliado): no tamanho normal a altura mínima já sobra.
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: AppSpacing.lg + AppSpacing.xxs,
        vertical: AppSpacing.sm,
      ),
    ),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.bordaPequena),
    ),
    // Do tema, não de `AppTypography.textTheme` direto: a família Urbanist é
    // aplicada pelo ThemeData, e o estilo cru sai na fonte do sistema.
    textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
    // Pela preferência do sistema: com movimento reduzido a cor troca no
    // mesmo frame do toque, sem os 150 ms de transição.
    animationDuration: AppMovimento.duracao(context, AppMovimento.rapida),
    elevation: const WidgetStatePropertyAll(0),
    // A mudança de cor já está em `backgroundColor`; a tinta por cima do
    // Material duplicaria o efeito e sujaria o roxo.
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );

  Widget _conteudo() {
    // Centralizado: se o rótulo quebrar linha, a segunda linha não pode
    // grudar na esquerda de um botão centralizado.
    final texto = Text(rotulo, textAlign: TextAlign.center);
    if (icone == null) return texto;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcone(nome: icone!, tamanho: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: texto),
      ],
    );
  }
}
