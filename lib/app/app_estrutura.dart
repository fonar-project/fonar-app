import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/conexao.dart';
import '../design_system/breakpoints.dart';
import '../design_system/tokens/app_colors.dart';
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
/// Cada tela se embrulha nesta estrutura, em vez de o roteador fazer isso por
/// `ShellRoute`: gravação, revisão e CAPE-V ocupam a tela inteira, e declarar
/// quem tem navegação na própria tela é mais fácil de ler que exceções no
/// roteador.
class AppEstrutura extends StatelessWidget {
  const AppEstrutura({required this.destino, required this.child, super.key});

  /// Qual destino marcar como ativo.
  final DestinoPrincipal destino;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          if (Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.expandida) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BarraLateral(ativo: destino),
                Expanded(child: SafeArea(left: false, child: child)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              _BarraInferior(ativo: destino),
            ],
          );
        },
      ),
    );
  }
}

class _BarraLateral extends ConsumerWidget {
  const _BarraLateral({required this.ativo});

  final DestinoPrincipal ativo;

  static const _largura = 222.0;
  static const _margem = 22.0;
  static const _divisoria = Divider(color: Color(0x2EFFF7EB)); // creme a 18%

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final profissional = ref.watch(profissionalAtualProvider);
    const creme = AppColors.creme;

    return Container(
      width: _largura,
      color: AppColors.roxoProfundo,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_margem, _margem, _margem, 18),
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
            _divisoria,
            const SizedBox(height: AppSpacing.sm),
            for (final destino in DestinoPrincipal.values)
              _ItemLateral(destino: destino, ativo: destino == ativo),
            const Spacer(),
            _divisoria,
            Padding(
              padding: const EdgeInsets.fromLTRB(_margem, 14, _margem, 18),
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
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({required this.destino, required this.ativo});

  final DestinoPrincipal destino;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    const creme = AppColors.creme;
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
      decoration: const BoxDecoration(
        color: AppColors.creme,
        border: Border(top: BorderSide(color: AppColors.lavandaClaro)),
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
              color: ativo ? AppColors.roxoProfundo : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          destino.rotuloCurto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ativo
                ? AppColors.roxoProfundo
                : AppColors.secundarioSobreLavanda,
            fontWeight: ativo ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
