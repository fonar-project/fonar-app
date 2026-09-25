import 'package:flutter/material.dart';

import '../tokens/app_cores.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_fundo.dart';
import 'app_icone.dart';
import 'app_mensagem_de_campo.dart';
import 'app_toque.dart';

/// Uma opção da [AppEscolhaUnica].
class AppOpcao<T> {
  const AppOpcao({required this.valor, required this.rotulo});

  final T valor;
  final String rotulo;
}

/// Escolha de UMA entre poucas opções, todas visíveis de uma vez.
///
/// Para duas a quatro opções curtas. Menu suspenso esconde as alternativas
/// atrás de um toque a mais e, no celular, abre uma folha que cobre o
/// formulário; aqui o profissional vê tudo e escolhe com um toque.
///
/// Mesmo contrato do `AppCampoTexto`: rótulo sempre visível em cima, erro
/// embaixo com ícone e texto. A opção escolhida não depende só da cor — ganha
/// o ícone de confirmação ao lado do rótulo, e o leitor de tela a anuncia como
/// marcada num grupo de opções exclusivas.
///
/// Começa sem nada escolhido quando [selecionado] é nulo. De propósito: uma
/// opção pré-marcada vira resposta que ninguém deu.
class AppEscolhaUnica<T> extends StatelessWidget {
  const AppEscolhaUnica({
    required this.rotulo,
    required this.opcoes,
    required this.selecionado,
    required this.aoEscolher,
    this.erro,
    this.apoio,
    super.key,
  });

  final String rotulo;
  final List<AppOpcao<T>> opcoes;
  final T? selecionado;

  /// Nulo deixa o grupo só para leitura — ex.: enquanto o formulário é salvo.
  final ValueChanged<T>? aoEscolher;

  final String? erro;
  final String? apoio;

  bool get _temErro => erro != null && erro!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // O rótulo visual fica fora da árvore semântica e vai como nome do
        // grupo: o leitor de tela anuncia "Sexo, grupo" ao entrar, e depois
        // cada opção com o próprio estado.
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: rotulo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  rotulo,
                  style: textos.labelSmall?.copyWith(
                    color: context.cores.texto,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs + 2),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final opcao in opcoes)
                    _Opcao(
                      rotulo: opcao.rotulo,
                      marcada: opcao.valor == selecionado,
                      comErro: _temErro,
                      aoTocar: aoEscolher == null
                          ? null
                          : () => aoEscolher!(opcao.valor),
                    ),
                ],
              ),
            ],
          ),
        ),
        AppMensagemDeCampo(
          erro: _temErro ? erro : null,
          apoio: apoio,
          corDoApoio: AppFundo.secundarioDe(context),
        ),
      ],
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.rotulo,
    required this.marcada,
    required this.comErro,
    required this.aoTocar,
  });

  final String rotulo;
  final bool marcada;
  final bool comErro;
  final VoidCallback? aoTocar;

  static const _marca = 18.0;

  @override
  Widget build(BuildContext context) {
    final corDoTexto = marcada
        ? context.cores.sobrePrimaria
        : context.cores.texto;
    final borda = switch ((marcada, comErro)) {
      (true, _) => context.cores.primaria,
      (false, true) => context.cores.erro,
      (false, false) => context.cores.bordaDeCampo,
    };

    final conteudo = Container(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.alvoDeToqueMinimo,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: marcada ? context.cores.primaria : null,
        border: Border.all(color: borda, width: 1.5),
        borderRadius: AppRadius.bordaPilula,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marca que não depende de cor: círculo vazio na desmarcada, visto
          // na marcada. O círculo também diz, antes do primeiro toque, que é
          // para escolher uma — como o botão de rádio que todo mundo conhece.
          // Os dois têm o mesmo tamanho, e a opção não muda de largura ao ser
          // escolhida.
          SizedBox.square(
            dimension: _marca,
            child: marcada
                ? AppIcone(
                    nome: NomeIcone.confirmacao,
                    cor: corDoTexto,
                    tamanho: _marca,
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borda, width: 1.5),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.xxs + 2),
          Flexible(
            child: Text(
              rotulo,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: corDoTexto),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: marcada,
      enabled: aoTocar != null,
      child: aoTocar == null
          ? conteudo
          : AppToque(
              aoTocar: aoTocar!,
              raio: AppRadius.bordaPilula,
              child: conteudo,
            ),
    );
  }
}
