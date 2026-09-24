import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/conexao.dart';
import '../../l10n/app_strings.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';
import 'app_indicador_conexao.dart';
import 'app_toque.dart';

/// Cabeçalho das telas de tarefa — consentimento, gravação — que ocupam a tela
/// inteira, sem a navegação principal: voltar, título e conexão.
///
/// A conexão aparece aqui em qualquer largura, porque estas telas não têm a
/// barra lateral onde ela ficaria no desktop.
class AppCabecalhoDeTarefa extends ConsumerWidget {
  const AppCabecalhoDeTarefa({
    required this.titulo,
    required this.aoVoltar,
    required this.compacta,
    super.key,
  });

  final String titulo;
  final VoidCallback aoVoltar;

  /// Largura compacta: título menor e margens mais justas.
  final bool compacta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lavandaClaro)),
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
                      child: Text(
                        titulo,
                        style: compacta
                            ? textos.titleLarge
                            : textos.headlineSmall,
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
}
