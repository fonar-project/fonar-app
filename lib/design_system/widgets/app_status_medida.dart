import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../tokens/app_cores.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';

/// Situação de uma medida acústica frente à faixa de referência.
///
/// O vocabulário descreve a MEDIDA, nunca o paciente: "fora da faixa" é um
/// fato sobre um número comparado a um intervalo. "Alterado" e "patológico"
/// são leitura clínica e o sistema não faz leitura clínica.
enum StatusMedida {
  dentroDaFaixa(
    rotulo: AppStrings.statusDentroDaFaixa,
    icone: NomeIcone.confirmacao,
  ),
  limitrofe(rotulo: AppStrings.statusLimitrofe, icone: NomeIcone.alerta),
  foraDaFaixa(rotulo: AppStrings.statusForaDaFaixa, icone: NomeIcone.negacao),

  /// Não existe faixa validada para este perfil de paciente e equipamento.
  ///
  /// Estado de primeira classe, não caso de erro. A medida e o valor aparecem
  /// normalmente; só a classificação fica de fora. Classificar sem referência
  /// válida é pior que não classificar.
  semReferencia(
    rotulo: AppStrings.statusSemReferencia,
    icone: NomeIcone.semReferencia,
  );

  const StatusMedida({required this.rotulo, required this.icone});

  /// Texto exibido. É ele que carrega a informação — a cor só reforça.
  final String rotulo;

  /// Ícone. **Um por status**, de forma distinta: quem não distingue o verde
  /// do vermelho ainda distingue um "confere" de um "x".
  final NomeIcone icone;

  /// A cor do status no tema de [cores].
  Color cor(AppCores cores) => switch (this) {
    dentroDaFaixa => cores.sucesso,
    limitrofe => cores.atencao,
    foraDaFaixa => cores.erro,
    // O tom de "sobre lavanda", não o secundário comum: o selo pinta o
    // próprio fundo com a cor a 10%, e no claro, sobre essa mistura, o tom
    // comum cai para 4,41:1.
    semReferencia => cores.secundarioSobreLavanda,
  };
}

/// Selo de status de uma medida acústica.
///
/// Sempre ícone + texto + cor, nessa ordem de importância. Remover o texto ou
/// o ícone quebra o requisito de acessibilidade do projeto — nenhuma
/// informação crítica é comunicada apenas por cor — e status de medida é a
/// informação mais crítica que esta interface exibe.
///
/// A cor de fundo é o próprio tom de status a 10%, e o texto usa o tom cheio
/// sobre ele. Não inverta: texto branco sobre verde pequeno reprova em AA.
class AppStatusMedida extends StatelessWidget {
  const AppStatusMedida({
    required this.status,
    this.compacto = false,
    super.key,
  });

  final StatusMedida status;

  /// Versão de linha de tabela: sem fundo, só ícone e texto.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cor = status.cor(context.cores);
    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcone(nome: status.icone, cor: cor, tamanho: 18),
        const SizedBox(width: AppSpacing.xxs + 2),
        // Flexible: num cartão estreito, ou com o texto do sistema ampliado,
        // o rótulo quebra linha em vez de estourar o selo.
        Flexible(
          child: Text(
            status.rotulo,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
          ),
        ),
      ],
    );

    // O par ícone+texto já diz tudo; para o leitor de tela é uma coisa só.
    final semantico = MergeSemantics(child: conteudo);

    if (compacto) return semantico;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: AppRadius.bordaPequena,
      ),
      child: semantico,
    );
  }
}
