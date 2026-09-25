import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_fundo.dart';
import 'app_icone.dart';
import 'app_mensagem_de_campo.dart';
import 'app_toque.dart';

/// Caixa de marcação com o texto ao lado — para uma declaração que a pessoa
/// precisa afirmar, como a concordância com um termo.
///
/// O texto inteiro é área de toque, não só o quadrado: 24 px é pouco para
/// acertar com pressa, e o texto é o que se lê antes de marcar.
///
/// Mesmo contrato dos outros campos: erro embaixo, com ícone e texto. Marcada,
/// a caixa ganha o visto — a marcação não depende só da cor.
class AppCaixaDeMarcacao extends StatelessWidget {
  const AppCaixaDeMarcacao({
    required this.rotulo,
    required this.marcada,
    required this.aoMudar,
    this.erro,
    super.key,
  });

  final String rotulo;
  final bool marcada;

  /// Nulo deixa a caixa só para leitura — ex.: enquanto o formulário é salvo.
  final ValueChanged<bool>? aoMudar;

  final String? erro;

  static const _aresta = 24.0;

  bool get _temErro => erro != null && erro!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final borda = switch ((marcada, _temErro)) {
      (true, _) => AppColors.roxoProfundo,
      (false, true) => AppColors.erro,
      (false, false) => AppColors.cinzaChumbo,
    };

    // Altura mínima de alvo de toque, com respiro vertical pequeno: o texto de
    // erro vem logo embaixo e precisa parecer da caixa, não do que vem depois.
    final linha = Container(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.alvoDeToqueMinimo,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _aresta,
            height: _aresta,
            decoration: BoxDecoration(
              color: marcada ? AppColors.roxoProfundo : null,
              border: Border.all(color: borda, width: 1.5),
              borderRadius: AppRadius.bordaPequena,
            ),
            child: marcada
                ? const AppIcone(
                    nome: NomeIcone.confirmacao,
                    cor: AppColors.creme,
                    tamanho: 18,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(rotulo, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MergeSemantics(
          child: Semantics(
            checked: marcada,
            enabled: aoMudar != null,
            child: aoMudar == null
                ? linha
                : AppToque(
                    aoTocar: () => aoMudar!(!marcada),
                    raio: AppRadius.bordaPequena,
                    // `linha` não tem cor que dependa do fundo; se algum dia
                    // tiver, ela precisa ser montada aqui dentro.
                    conteudo: (_) => linha,
                  ),
          ),
        ),
        AppMensagemDeCampo(
          erro: _temErro ? erro : null,
          corDoApoio: AppFundo.secundarioDe(context),
        ),
      ],
    );
  }
}
