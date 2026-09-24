import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../reproducao_controlador.dart';

/// Ouvir uma gravação: tocar e pausar, o tempo e onde se está nela.
///
/// Uma gravação por vez na tela: tocar esta para a que estava tocando.
/// Com [bloqueio] preenchido, não toca e diz por quê — é o caso de uma
/// gravação ou aferição em andamento.
class PlayerDeAmostra extends ConsumerWidget {
  const PlayerDeAmostra({
    required this.caminho,
    required this.rotulo,
    this.duracaoConhecida,
    this.bloqueio,
    super.key,
  });

  /// O arquivo, no aparelho.
  final String caminho;

  /// De que gravação se trata, para o leitor de tela: "Vogal sustentada /a/".
  final String rotulo;

  /// A duração que já se sabe (do cabeçalho do WAV), antes de carregar.
  final Duration? duracaoConhecida;

  final String? bloqueio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(reproducaoControladorProvider);
    final controlador = ref.read(reproducaoControladorProvider.notifier);
    final textos = Theme.of(context).textTheme;
    final minha = estado.eDe(caminho);
    final tocando = minha && estado.tocando;
    final falhou = minha && estado.falhou;
    final duracao = (minha ? estado.duracao : null) ?? duracaoConhecida;
    final posicao = minha ? estado.posicao : Duration.zero;
    final livre = bloqueio == null;
    final total = duracao == null
        ? '–:––'
        : AppStrings.minutosSegundos(duracao);
    final atual = AppStrings.minutosSegundos(posicao);
    final fracao = duracao == null || duracao == Duration.zero
        ? 0.0
        : (posicao.inMilliseconds / duracao.inMilliseconds).clamp(0.0, 1.0);

    final estiloDoTempo = textos.bodySmall?.copyWith(
      color: AppColors.secundarioSobreCreme,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final textoDoTempo = AppStrings.reproducaoTempo(atual, total);
    final tempo = ExcludeSemantics(
      child: Text(textoDoTempo, style: estiloDoTempo),
    );

    return LayoutBuilder(
      builder: (context, restricoes) {
        // O tempo fica ao lado da barra quando cabe; com o texto do sistema
        // grande, ou num cartão estreito, desce para baixo dela — em vez de
        // espremer a barra até sumir.
        final larguraDoTempo = (TextPainter(
          text: TextSpan(text: textoDoTempo, style: estiloDoTempo),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout()).width;
        final tempoNaLinha =
            AppSpacing.alvoDeToqueMinimo +
                AppSpacing.xs +
                _larguraMinimaDaBarra +
                larguraDoTempo <=
            restricoes.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Semantics(
                  label: tocando
                      ? AppStrings.reproducaoPausar(rotulo)
                      : AppStrings.reproducaoOuvir(rotulo),
                  enabled: livre,
                  excludeSemantics: true,
                  button: true,
                  child: livre
                      ? AppToque(
                          aoTocar: () => controlador.alternar(caminho),
                          raio: BorderRadius.circular(
                            AppSpacing.alvoDeToqueMinimo,
                          ),
                          child: _Botao(tocando: tocando, livre: true),
                        )
                      : const _Botao(tocando: false, livre: false),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  // Rótulo e valor num nó só, e ajustável pelo leitor de tela:
                  // quem não vê a barra também precisa poder voltar um trecho.
                  child: MergeSemantics(
                    child: Semantics(
                      label: AppStrings.reproducaoPosicao,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.roxoProfundo,
                          inactiveTrackColor: AppColors.lavandaClaro,
                          thumbColor: AppColors.roxoProfundo,
                          overlayColor: AppColors.roxoVeu,
                          // Antes de abrir o arquivo a barra não arrasta, mas a
                          // gravação está disponível: nada de cinza de "desligado"
                          // do padrão, que também está fora da paleta.
                          disabledActiveTrackColor: AppColors.lavandaClaro,
                          disabledInactiveTrackColor: AppColors.lavandaClaro,
                          disabledThumbColor: AppColors.secundarioSobreCreme,
                        ),
                        child: Slider(
                          value: fracao,
                          semanticFormatterCallback: (_) =>
                              AppStrings.reproducaoPosicaoDe(atual, total),
                          onChanged:
                              minha && livre && !falhou && duracao != null
                              ? (f) => controlador.irPara(caminho, duracao * f)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (tempoNaLinha) tempo,
              ],
            ),
            if (!tempoNaLinha)
              Align(alignment: Alignment.centerRight, child: tempo),
            if (falhou)
              const AppSituacao(
                icone: NomeIcone.alerta,
                titulo: AppStrings.reproducaoFalhou,
              ),
            if (bloqueio case final motivo?)
              Text(
                motivo,
                style: textos.bodySmall?.copyWith(
                  color: AppColors.secundarioSobreCreme,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Menos que isto, a barra não dá para arrastar com o dedo.
  static const _larguraMinimaDaBarra = 120.0;
}

class _Botao extends StatelessWidget {
  const _Botao({required this.tocando, required this.livre});

  final bool tocando;
  final bool livre;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSpacing.alvoDeToqueMinimo,
    height: AppSpacing.alvoDeToqueMinimo,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: livre ? AppColors.roxoProfundo : AppColors.lavandaClaro,
    ),
    child: AppIcone(
      nome: tocando ? NomeIcone.pausar : NomeIcone.reproduzir,
      cor: livre ? AppColors.branco : AppColors.secundarioSobreLavanda,
    ),
  );
}
