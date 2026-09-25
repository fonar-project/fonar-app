import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/conexao.dart';
import '../design_system/breakpoints.dart';
import '../design_system/tokens/app_cores.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/widgets/app_indicador_conexao.dart';
import '../design_system/widgets/app_toque.dart';
import '../features/auth/data/profissional_atual.dart';
import '../l10n/app_strings.dart';
import 'router/app_routes.dart';

/// Destinos da navegação principal.
enum DestinoPrincipal {
  pacientes(
    rotulo: AppStrings.navPacientes,
    rotuloCurto: AppStrings.navPacientes,
    rota: AppRoutes.pacientesNome,
  ),
  novaAvaliacao(
    rotulo: AppStrings.navNovaAvaliacao,
    rotuloCurto: AppStrings.navNovaAvaliacaoCurto,
    rota: AppRoutes.novaAvaliacaoNome,
  ),
  historico(
    rotulo: AppStrings.navHistorico,
    rotuloCurto: AppStrings.navHistorico,
    rota: AppRoutes.historicoNome,
  ),
  fila(
    rotulo: AppStrings.navFila,
    rotuloCurto: AppStrings.navFilaCurto,
    rota: AppRoutes.filaNome,
  ),
  conta(
    rotulo: AppStrings.navConta,
    rotuloCurto: AppStrings.navConta,
    rota: AppRoutes.contaNome,
  );

  const DestinoPrincipal({
    required this.rotulo,
    required this.rotuloCurto,
    required this.rota,
  });

  /// Na barra lateral do desktop.
  final String rotulo;

  /// Na barra inferior do celular.
  final String rotuloCurto;

  /// Nome da rota no go_router.
  final String rota;
}

/// Moldura das telas com navegação principal.
///
/// Expandida: barra lateral roxa com a marca, os destinos, a conexão e o
/// profissional logado. Compacta e média: destinos em abas de texto embaixo.
/// O cabeçalho do celular é da tela, não daqui — cada tela põe nele o que
/// precisa (a lista de pacientes, por exemplo, põe a busca).
///
/// ## Convenção: CADA TELA SE EMBRULHA, o roteador nunca embrulha
///
/// Quem decide ter navegação principal é a tela, no seu próprio `build` — não
/// o roteador por `ShellRoute` nem por `AppEstrutura` em volta do `builder`.
/// Vale sem exceção, inclusive para as telas de andaime: a `TelaPlaceholder`
/// recebe o `destino` e se embrulha sozinha.
///
/// O motivo é que as telas não têm todas a mesma navegação: as de tarefa —
/// perfil, gravação, resultado, CAPE-V — ficam ao lado da barra lateral no
/// desktop, como no protótipo, mas ocupam a tela inteira no celular
/// ([navegacaoInferior] falso); o login vem antes de haver navegação. Com o
/// roteador embrulhando, a lista de quem fica de fora vira uma lista de
/// exceções espalhada pelas rotas, longe da tela que ela descreve. Aqui basta
/// abrir a tela para saber a resposta.
///
/// O roteador estava embrulhando as três telas de andaime enquanto esta
/// documentação dizia o contrário. As duas convenções funcionam; ter as duas
/// ao mesmo tempo é que não.
class AppEstrutura extends StatelessWidget {
  const AppEstrutura({
    required this.destino,
    required this.child,
    this.navegacaoInferior = true,
    super.key,
  });

  /// Qual destino marcar como ativo.
  final DestinoPrincipal destino;

  final Widget child;

  /// Abas embaixo fora do desktop. Falso nas telas de tarefa: no celular elas
  /// ocupam a tela inteira, com o próprio voltar, e [child] aparece sozinho.
  final bool navegacaoInferior;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        if (Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.expandida) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BarraLateral(ativo: destino),
                Expanded(child: SafeArea(left: false, child: child)),
              ],
            ),
          );
        }
        if (!navegacaoInferior) return child;
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              _BarraInferior(ativo: destino),
            ],
          ),
        );
      },
    );
  }
}

class _BarraLateral extends ConsumerWidget {
  const _BarraLateral({required this.ativo});

  final DestinoPrincipal ativo;

  static const _largura = 222.0;
  static const _margem = 22.0;
  static Widget _divisoria(BuildContext context) =>
      Divider(color: context.cores.sobrePrimaria.withValues(alpha: 0.18));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final profissional = ref.watch(profissionalAtualProvider);
    final creme = context.cores.sobrePrimaria;

    return Container(
      width: _largura,
      color: context.cores.lateral,
      child: SafeArea(
        right: false,
        // Rola quando não cabe. Com o texto do sistema em 200% os quatro
        // destinos mais a marca e o rodapé passam da altura da tela, e a
        // coluna estourava por baixo — escondendo justamente o profissional
        // logado e o estado da conexão. O `IntrinsicHeight` com altura mínima
        // igual à da tela mantém o `Spacer` empurrando o rodapé para baixo
        // enquanto há espaço sobrando; passando disso, vira rolagem.
        child: LayoutBuilder(
          builder: (context, restricoes) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: restricoes.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _margem,
                        _margem,
                        _margem,
                        18,
                      ),
                      child: Semantics(
                        header: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.appTitle,
                              style: textos.titleLarge?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: creme,
                              ),
                            ),
                            Text(
                              AppStrings.loginSubtitulo,
                              style: textos.bodySmall?.copyWith(
                                color: creme.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _divisoria(context),
                    const SizedBox(height: AppSpacing.sm),
                    for (final destino in DestinoPrincipal.values)
                      _ItemLateral(destino: destino, ativo: destino == ativo),
                    const Spacer(),
                    _divisoria(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _margem,
                        14,
                        _margem,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIndicadorConexao(
                            online: ref.watch(conexaoOnlineProvider),
                            sobreFundoEscuro: true,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            profissional.nome,
                            style: textos.labelSmall?.copyWith(color: creme),
                          ),
                          Text(
                            profissional.registro,
                            style: textos.bodySmall?.copyWith(
                              color: creme.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({required this.destino, required this.ativo});

  final DestinoPrincipal destino;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final creme = context.cores.sobrePrimaria;
    return AppToque(
      aoTocar: () => context.goNamed(destino.rota),
      selecionado: ativo,
      // Azul some sobre o roxo; o anel aqui é creme.
      corDoFoco: creme,
      corDoHover: creme.withValues(alpha: 0.08),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.alvoDeToqueMinimo,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
        decoration: BoxDecoration(
          color: ativo ? creme.withValues(alpha: 0.14) : null,
          // Marca à esquerda no ativo: o estado não depende só do fundo.
          border: Border(
            left: BorderSide(
              color: ativo ? creme : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          destino.rotulo,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ativo ? creme : creme.withValues(alpha: 0.8),
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.ativo});

  final DestinoPrincipal ativo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cores.fundo,
        border: Border(top: BorderSide(color: context.cores.borda)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final destino in DestinoPrincipal.values)
              Expanded(
                child: _ItemInferior(destino: destino, ativo: destino == ativo),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemInferior extends StatelessWidget {
  const _ItemInferior({required this.destino, required this.ativo});

  final DestinoPrincipal destino;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return AppToque(
      aoTocar: () => context.goNamed(destino.rota),
      selecionado: ativo,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.alvoDeToqueMinimo + AppSpacing.xs,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 12),
        decoration: BoxDecoration(
          // Traço em cima da aba ativa, além do peso e da cor do texto.
          border: Border(
            top: BorderSide(
              color: ativo ? context.cores.acento : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        // FittedBox reduz o rótulo só quando ele não cabe na aba. Com o texto
        // do sistema em 200%, "Pacientes" quebrava no meio da palavra
        // ("Pacien/tes"), que é pior que letra um pouco menor.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            destino.rotuloCurto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ativo
                  ? context.cores.acento
                  // A barra inferior é creme, não lavanda: o token escuro aqui
                  // seria o do fundo errado.
                  : context.cores.secundario,
              fontWeight: ativo ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
