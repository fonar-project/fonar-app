import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_fundo.dart';
import 'app_mensagem_de_campo.dart';

/// Escala visual analógica: uma linha de [minimo] a [maximo] em que se marca
/// um ponto. É a forma da CAPE-V.
///
/// ## Começa SEM marca
///
/// Com [valor] nulo não há ponto na linha, e o número diz "não marcado". Um
/// ponto pré-posicionado em zero seria uma avaliação que ninguém fez — e zero,
/// aqui, é uma resposta ("sem desvio"), não a ausência de uma.
///
/// Toque ou arraste na linha marca; no teclado, as setas movem de 1 em 1. Por
/// baixo é o `Slider` do Material, que já traz foco, teclado e semântica de
/// controle ajustável.
class AppEscalaVisual extends StatelessWidget {
  const AppEscalaVisual({
    required this.rotulo,
    required this.valor,
    required this.aoMudar,
    required this.rotuloMinimo,
    required this.rotuloMaximo,
    required this.textoNaoMarcado,
    this.minimo = 0,
    this.maximo = 100,
    this.erro,
    super.key,
  });

  final String rotulo;
  final int? valor;

  /// Nulo deixa a escala só para leitura.
  final ValueChanged<int>? aoMudar;

  /// O que significa cada ponta, ex.: "sem desvio" e "desvio extremo".
  final String rotuloMinimo;
  final String rotuloMaximo;

  /// Mostrado no lugar do número enquanto não há marca.
  final String textoNaoMarcado;

  final int minimo;
  final int maximo;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = AppFundo.secundarioDe(context);
    final marcado = valor != null;
    final temErro = erro != null && erro!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wrap, não Row: com o texto do sistema ampliado, o nome do
        // parâmetro e o "não marcado" não cabem lado a lado, e o valor desce.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AppSpacing.sm,
          children: [
            ExcludeSemantics(child: Text(rotulo, style: textos.titleMedium)),
            ExcludeSemantics(
              child: Text(
                marcado ? '$valor' : textoNaoMarcado,
                style: marcado
                    ? AppTypography.medidaCompacta.copyWith(
                        color: AppColors.cinzaChumbo,
                      )
                    : textos.bodySmall?.copyWith(color: secundario),
              ),
            ),
          ],
        ),
        // Um nó só: nome, valor e as ações de aumentar e diminuir. Sem a
        // fusão, o leitor de tela anunciava "Grau geral" e, à parte, um
        // controle deslizante sem nome.
        MergeSemantics(
          child: Semantics(
            label: rotulo,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: marcado
                    ? AppColors.roxoProfundo
                    : AppColors.lavandaClaro,
                inactiveTrackColor: temErro
                    ? AppColors.erro
                    : AppColors.lavandaClaro,
                thumbColor: AppColors.roxoProfundo,
                // Sem marca, sem ponto. Só a cor transparente não bastava: o
                // contorno e a sombra do polegar continuavam desenhados em 0,
                // e a escala parecia marcada em "sem desvio".
                thumbShape: marcado
                    ? const RoundSliderThumbShape(enabledThumbRadius: 10)
                    : SliderComponentShape.noThumb,
                overlayColor: AppColors.roxoVeu,
                // Sem marcas de divisão: a escala é contínua para quem marca.
                tickMarkShape: SliderTickMarkShape.noTickMark,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: (valor ?? minimo).toDouble(),
                min: minimo.toDouble(),
                max: maximo.toDouble(),
                divisions: maximo - minimo,
                onChanged: aoMudar == null ? null : (v) => aoMudar!(v.round()),
                // O Slider só chama `onChanged` quando o valor MUDA — e a escala
                // sem marca está, por dentro, no mínimo. Sem isto, tocar na
                // ponta esquerda (ou a seta para a esquerda no teclado) numa
                // escala sem marca não marcava nada: "sem desvio" era
                // impossível de registrar com um toque. O fim do toque é
                // avisado sempre, com o valor tocado.
                onChangeEnd: aoMudar == null
                    ? null
                    : (v) => aoMudar!(v.round()),
                // Sem marca, o Slider anunciaria o mínimo — "0", uma resposta
                // que ninguém deu.
                semanticFormatterCallback: (v) =>
                    marcado ? '${v.round()} de $maximo' : textoNaoMarcado,
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rotuloMinimo,
                  style: textos.bodySmall?.copyWith(color: secundario),
                ),
              ),
              Expanded(
                child: Text(
                  rotuloMaximo,
                  textAlign: TextAlign.end,
                  style: textos.bodySmall?.copyWith(color: secundario),
                ),
              ),
            ],
          ),
        ),
        AppMensagemDeCampo(erro: temErro ? erro : null, corDoApoio: secundario),
      ],
    );
  }
}
