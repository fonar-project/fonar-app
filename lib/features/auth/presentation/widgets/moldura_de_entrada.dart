import 'package:flutter/material.dart';

import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_indicador_conexao.dart';
import '../../../../l10n/app_strings.dart';

/// A moldura das telas de entrada — entrar, criar conta, confirmar o
/// e-mail, preencher o cadastro: a marca, o estado da rede e o aviso de
/// apoio à decisão, com o formulário no meio.
///
/// Largura expandida: painel da marca à esquerda, formulário à direita.
/// Compacta e média: cabeçalho roxo em cima, formulário embaixo.
///
/// [formulario] recebe se o título vai dentro dele: na largura expandida, o
/// painel da marca não diz o nome da tela, e o formulário diz.
class MolduraDeEntrada extends StatelessWidget {
  const MolduraDeEntrada({
    required this.online,
    required this.formulario,
    super.key,
  });

  final bool online;
  final Widget Function(bool comTitulo) formulario;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final expandida =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.expandida;
          final conteudo = formulario(expandida);
          return expandida
              ? _LayoutExpandido(online: online, formulario: conteudo)
              : _LayoutCompacto(online: online, formulario: conteudo);
        },
      ),
    );
  }
}

/// Um link de texto da entrada ("Esqueci a senha", "Criar conta"), com o
/// mesmo anel de foco dos outros controles.
class LinkDaEntrada extends StatelessWidget {
  const LinkDaEntrada({required this.rotulo, required this.aoTocar, super.key});

  final String rotulo;

  /// Nulo desabilita — ex.: enquanto um pedido está no ar.
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: TextButton(
        onPressed: aoTocar,
        style:
            TextButton.styleFrom(
              foregroundColor: context.cores.acento,
              minimumSize: const Size(0, AppSpacing.alvoDeToqueMinimo),
              textStyle: textos.labelSmall?.copyWith(
                decoration: TextDecoration.underline,
              ),
            ).copyWith(
              // O foco padrão do TextButton é um véu de 7%: some para quem
              // navega por teclado. Mesmo anel dos outros controles.
              side: WidgetStateProperty.resolveWith(
                (estados) => estados.contains(WidgetState.focused)
                    ? BorderSide(color: context.cores.foco, width: 3)
                    : BorderSide.none,
              ),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: AppRadius.bordaPequena),
              ),
            ),
        child: Text(rotulo),
      ),
    );
  }
}

/// Desktop e tablet em paisagem: marca à esquerda, formulário à direita.
class _LayoutExpandido extends StatelessWidget {
  const _LayoutExpandido({required this.online, required this.formulario});

  final bool online;
  final Widget formulario;

  static const _larguraDoPainel = 560.0;
  static const _larguraDoFormulario = 440.0;
  static const _margemDoPainel = 60.0;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final creme = context.cores.sobrePrimaria;
    final cremeSuave = creme.withValues(alpha: 0.85);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: _larguraDoPainel,
          color: context.cores.lateral,
          // Rola quando não couber: com o texto do sistema em 200%, marca,
          // subtítulo e descrição passam da altura de uma janela de 900 px.
          // Alinhado à esquerda, como antes — `Center` o centralizaria na
          // horizontal também.
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(_margemDoPainel),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Marca(tamanho: 44),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.loginSubtitulo,
                    style: textos.bodyLarge?.copyWith(
                      fontSize: 19,
                      color: cremeSuave,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(
                      AppStrings.loginDescricao,
                      style: textos.bodyMedium?.copyWith(
                        height: 1.6,
                        color: cremeSuave,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            left: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _margemDoPainel,
                vertical: AppSpacing.xl - 2,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppIndicadorConexao(online: online),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _larguraDoFormulario,
                          ),
                          child: formulario,
                        ),
                      ),
                    ),
                  ),
                  const _AvisoApoioDecisao(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Celular e janela estreita: cabeçalho roxo, formulário rolável embaixo.
class _LayoutCompacto extends StatelessWidget {
  const _LayoutCompacto({required this.online, required this.formulario});

  final bool online;
  final Widget formulario;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: context.cores.lateral,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl + 2,
                AppSpacing.lg,
                AppSpacing.lg + 2,
              ),
              // Wrap, não Row: com o texto do sistema ampliado, marca e
              // indicador não cabem lado a lado em 390 px, e o indicador desce
              // para a linha de baixo em vez de espremer o subtítulo.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Marca(tamanho: 30),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.loginSubtitulo,
                        style: textos.bodySmall?.copyWith(
                          color: context.cores.sobrePrimaria.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppIndicadorConexao(online: online, sobreFundoEscuro: true),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg - 4,
              vertical: AppSpacing.lg,
            ),
            // Na largura média o formulário não estica até a borda: campo de
            // e-mail com 900 px de largura é difícil de ler e de mirar.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                // O aviso vai no fim da rolagem, não fixo embaixo: fixo, ele e
                // o cabeçalho comiam a altura toda com o texto ampliado, e o
                // formulário ficava sem espaço nenhum.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    formulario,
                    const SizedBox(height: AppSpacing.xl),
                    const SafeArea(top: false, child: _AvisoApoioDecisao()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca({required this.tamanho});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        AppStrings.appTitle,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: tamanho,
          letterSpacing: tamanho * 0.05,
          color: context.cores.sobrePrimaria,
        ),
      ),
    );
  }
}

class _AvisoApoioDecisao extends StatelessWidget {
  const _AvisoApoioDecisao();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.avisoApoioDecisao,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.cores.secundario),
    );
  }
}

/// Falha que não é de um campo específico: rede caiu no meio, servidor fora.
class ErroDaEntrada extends StatelessWidget {
  const ErroDaEntrada({required this.mensagem, super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcone(
              nome: NomeIcone.alerta,
              cor: context.cores.erro,
              tamanho: 16,
            ),
            const SizedBox(width: AppSpacing.xxs + 2),
            Expanded(
              child: Text(
                mensagem,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.cores.erro,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
