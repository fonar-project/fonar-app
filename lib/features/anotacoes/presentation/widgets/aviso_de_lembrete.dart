import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../anotacoes_controlador.dart';

/// O lembrete deixado numa consulta anterior (US51), no topo do perfil e no
/// início da gravação.
///
/// Discreto de propósito: às vezes o paciente vê a tela. Diz só que há um
/// lembrete, e de que consulta; o texto aparece quando o profissional toca
/// em "Mostrar", e "Ok, vi" o dá por visto. Roxo e lavanda, com ícone e
/// texto — nada de verde, amarelo ou vermelho, que são de status de medida.
///
/// Sem lembrete pendente, não ocupa espaço nenhum (nem a [margem]).
class AvisoDeLembrete extends ConsumerStatefulWidget {
  const AvisoDeLembrete({
    required this.pacienteId,
    this.margem = EdgeInsets.zero,
    super.key,
  });

  final String pacienteId;
  final EdgeInsets margem;

  @override
  ConsumerState<AvisoDeLembrete> createState() => _AvisoDeLembreteState();
}

class _AvisoDeLembreteState extends ConsumerState<AvisoDeLembrete> {
  var _mostrando = false;

  @override
  Widget build(BuildContext context) {
    final lembretes = ref.watch(lembretesDoPacienteProvider(widget.pacienteId));
    if (lembretes.isEmpty) return const SizedBox.shrink();

    final textos = Theme.of(context).textTheme;
    final titulo = lembretes.length == 1
        ? AppStrings.lembreteUm(AppStrings.diaEMes(lembretes.single.criadaEm))
        : AppStrings.lembreteVarios(lembretes.length);

    return Padding(
      padding: widget.margem,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.cores.suave,
          border: Border.all(color: context.cores.borda),
          borderRadius: AppRadius.bordaMedia,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcone(
              nome: NomeIcone.informacao,
              cor: context.cores.acento,
              tamanho: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: textos.titleSmall),
                  if (_mostrando)
                    // Anunciado quando aparece: quem não vê a tela ouve o
                    // que acabou de abrir.
                    Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final lembrete in lembretes) ...[
                            const SizedBox(height: AppSpacing.sm),
                            if (lembretes.length > 1)
                              Text(
                                AppStrings.lembreteDaConsulta(
                                  AppStrings.diaEMes(lembrete.criadaEm),
                                ),
                                style: textos.labelMedium?.copyWith(
                                  color: context.cores.secundario,
                                ),
                              ),
                            Text(lembrete.texto, style: textos.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Link(
                        rotulo: _mostrando
                            ? AppStrings.lembreteEsconder
                            : AppStrings.lembreteMostrar,
                        aoTocar: () => setState(() => _mostrando = !_mostrando),
                      ),
                      // Dá por visto quem leu: só depois de mostrar.
                      if (_mostrando)
                        AppBotao.secundario(
                          rotulo: AppStrings.lembreteVi,
                          aoTocar: () => ref
                              .read(anotacoesControladorProvider)
                              .marcarVistos(lembretes),
                        ),
                    ],
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

/// Uma ação de texto, sublinhada, com o alvo de toque mínimo.
class _Link extends StatelessWidget {
  const _Link({required this.rotulo, required this.aoTocar});

  final String rotulo;
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Text(
            rotulo,
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

/// O selo "Lembrete" do paciente na lista: texto, nunca só cor.
class SeloDeLembrete extends StatelessWidget {
  const SeloDeLembrete({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: AppRadius.bordaPilula,
      border: Border.all(color: context.cores.acento, width: 1.5),
    ),
    child: Text(
      AppStrings.lembreteSelo,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: context.cores.acento, fontWeight: FontWeight.w700),
    ),
  );
}
