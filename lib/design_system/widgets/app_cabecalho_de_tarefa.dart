import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/conexao.dart';
import '../../l10n/app_strings.dart';
import '../breakpoints.dart';
import '../tokens/app_cores.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';
import 'app_indicador_conexao.dart';
import 'app_toque.dart';

/// Um passo da trilha do cabeçalho — "Pacientes / Paciente A. / Laudo".
///
/// Sem [aoTocar], é o passo atual: aparece em negrito e não é link.
class ItemDaTrilha {
  const ItemDaTrilha(this.rotulo, {this.aoTocar});

  final String rotulo;
  final VoidCallback? aoTocar;
}

/// Cabeçalho das telas de tarefa — perfil, gravação, resultado, laudo.
///
/// Na largura expandida a tela fica ao lado da barra lateral (ver
/// `AppEstrutura`), e o cabeçalho mostra onde se está: a [trilha] até a tela
/// atual, uma [situacao] em pílula e as [acoes] da tela. Voltar é tocar num
/// passo da trilha; a conexão já está na barra lateral.
///
/// Nas outras larguras não há barra lateral: voltar, [titulo], [subtitulo] e
/// conexão. As ações ficam no corpo da tela, perto do conteúdo.
class AppCabecalhoDeTarefa extends ConsumerWidget {
  const AppCabecalhoDeTarefa({
    required this.titulo,
    required this.aoVoltar,
    required this.largura,
    this.subtitulo,
    this.trilha = const [],
    this.situacao,
    this.acoes = const [],
    super.key,
  });

  final String titulo;
  final VoidCallback aoVoltar;

  /// Faixa de largura da área em que o cabeçalho está: título e margens
  /// menores na compacta.
  final LarguraDeTela largura;

  /// Linha menor embaixo do título, fora do desktop — o paciente, por
  /// exemplo.
  final String? subtitulo;

  /// Os passos até aqui, no desktop. Vazia, vale só o [titulo].
  final List<ItemDaTrilha> trilha;

  /// Uma frase curta sobre o estado da tela, no desktop.
  final String? situacao;

  /// Botões da tela, no desktop.
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A barra lateral existe quando a JANELA é expandida (ver
    // `AppEstrutura`) — e não a área da tela, que fica 222 px mais estreita
    // por causa dela. É isso que decide trilha ou voltar.
    final comBarraLateral =
        Breakpoints.de(MediaQuery.sizeOf(context).width) ==
        LarguraDeTela.expandida;
    if (comBarraLateral) return _expandido(context);

    final textos = Theme.of(context).textTheme;
    final compacta = largura == LarguraDeTela.compacta;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cores.borda)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: BoxConstraints(minHeight: compacta ? 0 : 76),
          padding: EdgeInsets.symmetric(
            horizontal: compacta ? AppSpacing.xs : AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Semantics(
                label: AppStrings.voltar,
                child: AppToque(
                  aoTocar: aoVoltar,
                  raio: AppRadius.bordaPequena,
                  child: SizedBox.square(
                    dimension: AppSpacing.alvoDeToqueMinimo,
                    child: Center(
                      child: AppIcone(
                        nome: NomeIcone.voltar,
                        cor: context.cores.acento,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              // Wrap no espaço que sobra ao lado do voltar: com o texto do
              // sistema ampliado, o indicador de conexão desce para a linha
              // de baixo e o título quebra linha em vez de estourar.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Semantics(
                      header: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: compacta
                                ? textos.titleLarge
                                : textos.headlineSmall,
                          ),
                          if (subtitulo case final sub?)
                            Text(
                              sub,
                              style: textos.bodySmall?.copyWith(
                                color: context.cores.secundario,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: AppIndicadorConexao(
                        online: ref.watch(conexaoOnlineProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _expandido(BuildContext context) {
    final passos = trilha.isEmpty ? [ItemDaTrilha(titulo)] : trilha;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cores.borda)),
      ),
      child: SafeArea(
        bottom: false,
        left: false,
        child: Container(
          // Altura MÍNIMA: com o texto ampliado, trilha e ações quebram linha
          // e o cabeçalho cresce junto.
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: AppSpacing.xs,
          ),
          alignment: Alignment.centerLeft,
          // Trilha, pílula e ações dividem a largura: com o texto do sistema
          // ampliado, cada uma quebra linha dentro do seu espaço em vez de
          // uma empurrar a outra para uma coluna de uma palavra.
          child: Row(
            children: [
              Expanded(flex: 3, child: _Trilha(passos: passos)),
              if (situacao case final texto?) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppPilulaDeSituacao(texto: texto),
                  ),
                ),
              ],
              if (acoes.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  flex: 3,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: acoes,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Trilha extends StatelessWidget {
  const _Trilha({required this.passos});

  final List<ItemDaTrilha> passos;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontSize: 14, color: context.cores.secundario);
    return Semantics(
      header: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, passo) in passos.indexed) ...[
            if (i > 0) Text(' / ', style: base),
            if (passo.aoTocar case final tocar?)
              Semantics(
                link: true,
                child: AppToque(
                  aoTocar: tocar,
                  raio: AppRadius.bordaPequena,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      passo.rotulo,
                      style: base?.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: context.cores.secundario,
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                passo.rotulo,
                style: base?.copyWith(
                  color: context.cores.texto,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Pílula com uma frase curta sobre o estado da tela — "Consentimento
/// registrado", "Apoio à decisão — não é diagnóstico".
///
/// Texto sempre: a pílula não comunica nada só por cor.
class AppPilulaDeSituacao extends StatelessWidget {
  const AppPilulaDeSituacao({required this.texto, super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: context.cores.borda)),
        borderRadius: AppRadius.bordaPilula,
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.cores.texto,
        ),
      ),
    );
  }
}
