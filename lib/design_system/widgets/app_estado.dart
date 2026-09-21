import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_fundo.dart';

/// Estado da tela que não é conteúdo: lista vazia, busca sem resultado, falha
/// ao carregar, aviso de que o modo offline está disponível.
///
/// Sempre o mesmo contrato, porque é sempre a mesma conversa: **o que
/// aconteceu** ([titulo]), **por quê** ([texto], opcional) e **o que dá para
/// fazer agora** ([acao]). A ação não é opcional de propósito — uma tela que
/// só informa deixa o profissional parado no meio da consulta, e se realmente
/// não houver o que fazer a ação vira um botão desabilitado com motivo, que o
/// `AppBotao` já obriga a explicar.
///
/// ## O fundo é lavanda, e isso é contrato
///
/// A superfície é sempre `lavandaSuave` com borda lavanda, e o componente
/// declara isso para quem está dentro dele com um [AppFundo]. Sem essa
/// declaração, um botão secundário desabilitado ou um texto de apoio aqui
/// dentro escolheria o tom "sobre creme", que cai para 3,62:1 sobre a lavanda
/// e reprova em AA. Ver `app_colors_test.dart`.
///
/// Por isso o texto secundário daqui usa [AppColors.secundarioSobreLavanda]
/// direto: é o tom do fundo que este componente mesmo pinta.
class AppEstado extends StatelessWidget {
  /// Faixa dentro do fluxo da tela, acima ou abaixo de outro conteúdo.
  ///
  /// Ocupa só a altura de que precisa e alinha à esquerda. É a forma do aviso
  /// de conexão na tela de login, que divide espaço com o formulário.
  const AppEstado.faixa({
    required this.titulo,
    required this.acao,
    this.texto,
    super.key,
  }) : _central = false;

  /// Ocupa a área de conteúdo inteira, centralizado.
  ///
  /// É a forma de quando NÃO HÁ conteúdo nenhum para dividir espaço: lista
  /// vazia, busca sem resultado, falha ao carregar. Rola quando não couber —
  /// com o texto do sistema ampliado, título mais texto mais botão passam da
  /// altura de um celular.
  const AppEstado.central({
    required this.titulo,
    required this.acao,
    this.texto,
    super.key,
  }) : _central = true;

  /// O que aconteceu, em uma linha.
  final String titulo;

  /// Por que aconteceu, ou o que isso significa. Opcional: há estados em que o
  /// título já diz tudo.
  final String? texto;

  /// O que dá para fazer agora. Normalmente um [AppBotao].
  final Widget acao;

  final bool _central;

  /// Teto de largura da forma central. Linha de texto mais longa que isso
  /// cansa de ler, e centralizada fica pior ainda.
  static const _larguraMaxima = 440.0;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final alinhamento = _central ? TextAlign.center : TextAlign.start;

    final cartao = Container(
      padding: EdgeInsets.symmetric(
        horizontal: _central ? AppSpacing.lg : AppSpacing.md + 2,
        vertical: _central ? AppSpacing.lg : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.lavandaSuave,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      // Quem pinta a superfície declara o fundo: a ação aqui dentro é um
      // componente do design system e, desabilitada, precisa do tom de texto
      // secundário da lavanda, não o do creme.
      child: AppFundo(
        fundo: FundoDeTexto.lavanda,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              textAlign: alinhamento,
              // Na forma central o estado é a tela inteira e o título é o
              // cabeçalho dela; na faixa ele divide atenção com o conteúdo em
              // volta e não pode gritar mais alto que o título da tela.
              style: _central ? textos.headlineSmall : textos.titleMedium,
            ),
            if (texto case final texto?) ...[
              SizedBox(height: _central ? AppSpacing.sm : AppSpacing.xxs),
              Text(
                texto,
                textAlign: alinhamento,
                style: (_central ? textos.bodyMedium : textos.bodySmall)
                    ?.copyWith(color: AppColors.secundarioSobreLavanda),
              ),
            ],
            SizedBox(height: _central ? AppSpacing.lg : AppSpacing.sm),
            acao,
          ],
        ),
      ),
    );

    if (!_central) return cartao;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _larguraMaxima),
          child: cartao,
        ),
      ),
    );
  }
}
