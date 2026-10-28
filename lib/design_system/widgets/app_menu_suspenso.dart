import 'package:flutter/material.dart';

import '../tokens/app_cores.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_escolha_unica.dart';
import 'app_fundo.dart';
import 'app_icone.dart';
import 'app_mensagem_de_campo.dart';

/// Escolha de UMA opção numa lista que a tela não conhece de antemão.
///
/// A [AppEscolhaUnica] é a escolha do projeto, e continua sendo para poucas
/// opções curtas, todas à vista. Este menu é para o caso em que ela não
/// serve: a lista vem do aparelho — quantos itens, e com que nome, só o
/// sistema sabe. Os microfones são o exemplo: um computador com webcam,
/// headset e aplicativo de câmera tem cinco ou seis, com nomes como
/// "Microfone (Realtek(R) Audio)", e as pílulas viravam um bloco de texto.
///
/// Mesmo contrato do `AppCampoTexto` e da [AppEscolhaUnica]: rótulo sempre
/// visível em cima, apoio embaixo, a mesma borda de campo do tema. O nome
/// longo fica inteiro no menu aberto e com reticências no campo fechado.
class AppMenuSuspenso<T> extends StatelessWidget {
  const AppMenuSuspenso({
    required this.rotulo,
    required this.opcoes,
    required this.selecionado,
    required this.aoEscolher,
    this.apoio,
    super.key,
  });

  final String rotulo;
  final List<AppOpcao<T>> opcoes;

  /// Precisa ser o valor de uma das [opcoes] — inclusive `null`, quando uma
  /// opção o tem (ex.: "Padrão do sistema").
  final T selecionado;

  /// Nulo deixa o menu só para leitura, mostrando o escolhido.
  final ValueChanged<T>? aoEscolher;

  final String? apoio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final habilitado = aoEscolher != null;
    final corSecundaria = context.cores.secundarioSobre(AppFundo.de(context));
    final corDoTexto = habilitado ? context.cores.texto : corSecundaria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Como na escolha única: o rótulo visual sai da árvore semântica e
        // vira o nome do grupo, e o botão do menu anuncia o escolhido.
        Semantics(
          container: true,
          label: rotulo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  rotulo,
                  style: textos.labelSmall?.copyWith(color: corDoTexto),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs + 2),
              DropdownButtonFormField<T>(
                // Sem chave: quando a escolha muda por fora (o microfone
                // desconectado volta ao padrão), o próprio campo troca o
                // valor — o `didUpdateWidget` dele lê o `initialValue` novo.
                // Uma chave recriaria o campo a cada escolha, e quem escolhe
                // pelo teclado perderia o foco.
                initialValue: selecionado,
                isExpanded: true,
                itemHeight: null,
                style: textos.bodyMedium?.copyWith(color: corDoTexto),
                dropdownColor: context.cores.cartao,
                borderRadius: AppRadius.bordaPequena,
                focusColor: Colors.transparent,
                // O chevron do "avançar", deitado: o projeto não tem ícone
                // de seta para baixo, e um SVG novo teria de ir também para
                // a landing, que espelha a pasta de ícones.
                icon: RotatedBox(
                  quarterTurns: 1,
                  child: AppIcone(
                    nome: NomeIcone.avancar,
                    cor: corDoTexto,
                    tamanho: 20,
                  ),
                ),
                decoration: InputDecoration(
                  filled: !habilitado,
                  fillColor: context.cores.suave,
                ),
                onChanged: aoEscolher == null
                    ? null
                    : (valor) => aoEscolher!(valor as T),
                // Fechado, uma linha só; aberto, o nome inteiro.
                selectedItemBuilder: (context) => [
                  for (final opcao in opcoes)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        opcao.rotulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                items: [
                  for (final opcao in opcoes)
                    DropdownMenuItem<T>(
                      value: opcao.valor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          opcao.rotulo,
                          style: textos.bodyMedium?.copyWith(
                            color: context.cores.texto,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        AppMensagemDeCampo(apoio: apoio, corDoApoio: corSecundaria),
      ],
    );
  }
}
