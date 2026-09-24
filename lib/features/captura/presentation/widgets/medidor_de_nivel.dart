import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_movimento.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/nivel_de_audio.dart';

/// Medidor de nível (VU meter): barra, número em dBFS e a zona por escrito.
///
/// Verde, amarelo e vermelho aqui são permitidos — saturação de áudio é um
/// dos dois usos reservados dessas cores. Mesmo assim a cor nunca vai
/// sozinha: a zona aparece escrita, e "Saturando" leva o ícone de alerta.
///
/// ## Movimento reduzido
///
/// Exceção proposital à regra: o medidor CONTINUA respondendo ao áudio com
/// movimento reduzido, porque é feedback clínico, não decoração. O que some é
/// a suavização — a barra salta direto para o valor novo.
///
/// ## Na aferição de ruído as zonas não valem
///
/// "Baixo", "adequado" e "alto" dizem se a VOZ chega bem ao microfone. Para
/// o ruído da sala a leitura é a oposta — quanto mais baixo, melhor —, e uma
/// sala barulhenta aparecendo como "sinal adequado", em verde, diria ao
/// profissional o contrário do que acontece. Com [ambiente], a barra fica
/// neutra e só "sem sinal" e "saturando", que valem nos dois casos, aparecem.
class MedidorDeNivel extends StatelessWidget {
  const MedidorDeNivel({required this.dbfs, this.ambiente = false, super.key});

  /// Nulo antes da primeira leitura.
  final double? dbfs;

  /// Medindo o ruído da sala, não a voz. Ver a documentação da classe.
  final bool ambiente;

  /// Suavização entre leituras. Curta: mais que o intervalo de leitura e a
  /// barra ficaria sempre atrasada em relação ao som.
  static const _suavizacao = Duration(milliseconds: 80);
  static const _altura = 16.0;

  @override
  Widget build(BuildContext context) {
    final valor = dbfs;
    final zona = valor == null ? null : zonaDe(valor);
    final fracao = valor == null ? 0.0 : fracaoDoMedidor(valor);
    final textos = Theme.of(context).textTheme;

    final neutro =
        ambiente &&
        zona != null &&
        zona != ZonaDeNivel.semSinal &&
        zona != ZonaDeNivel.saturando;
    final rotuloDaZona = switch (zona) {
      _ when neutro => AppStrings.medidorAmbiente,
      null || ZonaDeNivel.semSinal => AppStrings.medidorSemSinal,
      ZonaDeNivel.baixo => AppStrings.medidorBaixo,
      ZonaDeNivel.adequado => AppStrings.medidorAdequado,
      ZonaDeNivel.alto => AppStrings.medidorAlto,
      ZonaDeNivel.saturando => AppStrings.medidorSaturando,
    };
    final corDaBarra = switch (zona) {
      _ when neutro => AppColors.roxoProfundo,
      null || ZonaDeNivel.semSinal => AppColors.lavandaClaro,
      ZonaDeNivel.baixo => AppColors.cinzaChumbo,
      ZonaDeNivel.adequado => AppColors.sucesso,
      ZonaDeNivel.alto => AppColors.atencao,
      ZonaDeNivel.saturando => AppColors.erro,
    };
    // A cor do TEXTO só muda na saturação — o único estado que pede ação
    // imediata. Nos outros, texto verde ou amarelo sobre creme competiria
    // com a própria barra.
    final corDoTexto = zona == ZonaDeNivel.saturando
        ? AppColors.erro
        : AppColors.cinzaChumbo;
    final numero = valor == null ? '' : AppStrings.nivelDbfs(valor);

    // Um nó só para o leitor de tela, sem `liveRegion`: o valor muda dez
    // vezes por segundo, e anunciar cada leitura tornaria o leitor inútil.
    return Semantics(
      container: true,
      label: '${AppStrings.medidorRotulo}: $rotuloDaZona',
      value: numero,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (zona == ZonaDeNivel.saturando) ...[
                      const AppIcone(
                        nome: NomeIcone.alerta,
                        cor: AppColors.erro,
                        tamanho: 18,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    Text(
                      rotuloDaZona,
                      style: textos.titleSmall?.copyWith(color: corDoTexto),
                    ),
                  ],
                ),
                Text(
                  numero,
                  style: AppTypography.medidaCompacta.copyWith(
                    color: corDoTexto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppRadius.bordaPilula,
              child: Container(
                height: _altura,
                color: AppColors.lavandaSuave,
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fracao),
                  duration: AppMovimento.duracao(context, _suavizacao),
                  builder: (context, preenchido, _) => FractionallySizedBox(
                    widthFactor: preenchido,
                    heightFactor: 1,
                    child: ColoredBox(color: corDaBarra),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
