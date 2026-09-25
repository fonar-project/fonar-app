import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/conexao.dart';
import '../breakpoints.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import 'app_cabecalho_de_tarefa.dart';
import 'app_indicador_conexao.dart';

/// Cabeçalho das telas com navegação principal — cadastro, fila —: o título
/// e, quando não há barra lateral, o indicador de conexão.
///
/// Na largura expandida a conexão já aparece no rodapé da barra lateral, e
/// dois indicadores na mesma tela fazem procurar a diferença entre eles. Nas
/// outras larguras não há barra lateral, e o indicador vem para cá.
///
/// Para telas de tarefa, sem navegação principal, há o
/// `AppCabecalhoDeTarefa`, com o botão de voltar.
class AppCabecalhoDeSecao extends ConsumerWidget {
  const AppCabecalhoDeSecao({
    required this.titulo,
    required this.largura,
    this.situacao,
    super.key,
  });

  final String titulo;

  /// No desktop, uma pílula à direita com a situação da tela — ex.: a fila
  /// lembrando que nada se perde sem conexão. Nas outras larguras o lugar é
  /// do indicador de conexão, e a tela diz o mesmo no corpo, se precisar.
  final String? situacao;

  /// Faixa de largura da área em que o cabeçalho está.
  final LarguraDeTela largura;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final compacta = largura == LarguraDeTela.compacta;
    final texto = Semantics(
      header: true,
      child: Text(
        titulo,
        style: compacta ? textos.titleLarge : textos.headlineSmall,
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lavandaClaro)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          // Altura MÍNIMA, a mesma da barra da lista de pacientes: com o
          // texto ampliado o título quebra linha e a barra cresce junto.
          constraints: BoxConstraints(minHeight: compacta ? 0 : 76),
          padding: EdgeInsets.symmetric(
            horizontal: compacta ? AppSpacing.md : 30,
            vertical: AppSpacing.sm,
          ),
          alignment: Alignment.centerLeft,
          child: largura == LarguraDeTela.expandida
              ? (situacao == null
                    ? texto
                    : SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            texto,
                            AppPilulaDeSituacao(texto: situacao!),
                          ],
                        ),
                      ))
              // Wrap, não Row: com o texto do sistema ampliado, título e
              // indicador não cabem lado a lado em 390 px e o indicador desce.
              // A largura toda é para o `spaceBetween` levar o indicador à
              // direita.
              : SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      texto,
                      AppIndicadorConexao(
                        online: ref.watch(conexaoOnlineProvider),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
