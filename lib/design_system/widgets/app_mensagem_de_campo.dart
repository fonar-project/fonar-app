import 'package:flutter/material.dart';

import '../tokens/app_cores.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';

/// A linha embaixo de um campo de formulário: erro ou texto de apoio.
///
/// Compartilhada pelos campos do design system — o [AppCampoTexto] e a
/// [AppEscolhaUnica] — para que o erro tenha a mesma cara em qualquer campo.
/// Erro nunca é só cor: aparece com ícone e com texto dizendo o que corrigir,
/// e é anunciado pelo leitor de tela no momento em que surge.
///
/// Com [erro] preenchido o [apoio] some: duas mensagens embaixo do mesmo campo
/// competem por atenção. Sem nenhum dos dois, não ocupa espaço.
class AppMensagemDeCampo extends StatelessWidget {
  const AppMensagemDeCampo({
    required this.corDoApoio,
    this.erro,
    this.apoio,
    super.key,
  });

  final String? erro;
  final String? apoio;

  /// Tom de texto secundário do fundo em volta — ver `AppColors.secundarioSobre`.
  final Color corDoApoio;

  @override
  Widget build(BuildContext context) {
    if (erro case final erro? when erro.isNotEmpty) {
      return _Linha(
        texto: erro,
        cor: context.cores.erro,
        icone: NomeIcone.alerta,
        ehErro: true,
      );
    }
    if (apoio case final apoio?) {
      return _Linha(texto: apoio, cor: corDoApoio);
    }
    return const SizedBox.shrink();
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.texto,
    required this.cor,
    this.icone,
    this.ehErro = false,
  });

  final String texto;
  final Color cor;
  final NomeIcone? icone;
  final bool ehErro;

  @override
  Widget build(BuildContext context) {
    final linha = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icone != null) ...[
            AppIcone(nome: icone!, cor: cor, tamanho: 16),
            const SizedBox(width: AppSpacing.xxs + 2),
          ],
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cor,
                fontWeight: ehErro ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );

    // `liveRegion` faz o leitor de tela anunciar o erro no momento em que ele
    // aparece, em vez de esperar o usuário voltar o foco ao campo.
    return Semantics(
      liveRegion: ehErro,
      child: MergeSemantics(child: linha),
    );
  }
}
