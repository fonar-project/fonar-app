/// ÚNICO ponto do aplicativo que carrega SVG.
///
/// Nenhuma tela importa `flutter_svg`, `vector_graphics` ou um arquivo de
/// `assets/` direto. Se um ícone precisa aparecer em algum lugar, ele entra no
/// enum [NomeIcone] e é usado via [AppIcone]. O teste
/// `test/design_system/app_icone_test.dart` falha se esse contrato for
/// quebrado.
///
/// O carregamento usa o binário pré-compilado (`.svg.vec`) gerado por
/// `tool/compilar_icones.dart`, não o XML. O parse do SVG acontece no build,
/// não no primeiro frame.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// Nome de ícone do design system.
///
/// Nunca passe caminho de arquivo como string: o nome é sempre um valor deste
/// enum. Assim remover ou renomear um arquivo vira erro de compilação — ou, no
/// pior caso, falha de teste — em vez de ícone faltando em tempo de execução.
///
/// O índice de uso por tela está em `assets/icons/README.md`. A pasta
/// `assets/icons/` é espelhada com a landing page: alterar aqui exige alterar
/// no outro repositório.
enum NomeIcone {
  // Estado de medida e de amostra.
  confirmacao('confirmacao'),
  alerta('alerta'),
  negacao('negacao'),
  semReferencia('sem-referencia'),

  // Captura e reprodução.
  gravar('gravar'),
  reproduzir('reproduzir'),
  pausar('pausar'),

  // Direção do valor entre duas sessões. O nome é a DIREÇÃO, não a leitura:
  // no AVQI descer é melhorar, no CPPS é piorar. Quem diz o que a direção
  // significa é `lerEvolucao`, no domínio — nunca o ícone.
  tendenciaSobe('tendencia-sobe'),
  tendenciaEstavel('tendencia-estavel'),
  tendenciaDesce('tendencia-desce'),

  // Navegação.
  voltar('voltar'),
  avancar('avancar'),
  adicionar('adicionar'),
  informacao('informacao'),

  // Orientação do aparelho.
  virarParaPaciente('virar-para-paciente'),
  girarAparelho('girar-aparelho'),

  // Fila de sincronização e conexão.
  passoPendente('passo-pendente'),
  estadoOnline('estado-online'),
  estadoSemConexao('estado-sem-conexao');

  const NomeIcone(this.arquivo);

  /// Nome do arquivo, sem extensão. Em kebab-case, como está em disco.
  final String arquivo;

  /// Pasta dos SVG de origem, espelhada com a landing page.
  static const pastaOrigem = 'assets/icons';

  /// Pasta dos binários gerados por `tool/compilar_icones.dart`.
  static const pastaCompilada = 'assets/icons_vec';

  /// Extensão dos SVG de origem.
  static const extensaoOrigem = '.svg';

  /// Sufixo dos binários pré-compilados.
  static const extensaoCompilada = '.svg.vec';

  /// Caminho do SVG de origem. Não é asset de runtime — é entrada de build,
  /// usada pelo compilador e pelo teste de paridade entre enum e disco.
  String get caminhoOrigem => '$pastaOrigem/$arquivo$extensaoOrigem';

  /// Caminho do binário pré-compilado, esse sim declarado no `pubspec.yaml`.
  String get caminhoCompilado => '$pastaCompilada/$arquivo$extensaoCompilada';
}

/// Ícone do design system.
///
/// Por padrão herda cor e tamanho do [IconTheme] em volta, igual a um [Icon]
/// do Material — o que faz o ícone acompanhar o contexto (header roxo, card
/// lavanda, texto chumbo) sem que cada tela repita token de cor.
///
/// Acessibilidade: ícone que carrega informação precisa de [rotuloSemantico].
/// Sem rótulo, o ícone é tratado como decorativo e sai da árvore de semântica,
/// o que é o correto quando existe texto ao lado dizendo a mesma coisa. Cor
/// nunca é o único portador da informação — isso é responsabilidade de quem
/// monta a tela, não deste widget.
class AppIcone extends StatelessWidget {
  const AppIcone({
    required this.nome,
    this.cor,
    this.tamanho,
    this.rotuloSemantico,
    super.key,
  });

  /// Os SVG são 24×24. Ampliar é aceitável; reduzir muito perde legibilidade
  /// do traço.
  static const tamanhoPadrao = 24.0;

  /// Qual ícone desenhar.
  final NomeIcone nome;

  /// Cor do traço e do preenchimento. Se nulo, usa a cor do [IconTheme].
  ///
  /// O `currentColor` do SVG é resolvido em tempo de compilação, então aqui a
  /// cor é aplicada por filtro sobre o desenho inteiro.
  final Color? cor;

  /// Aresta do quadrado do ícone. Se nulo, usa o tamanho do [IconTheme].
  final double? tamanho;

  /// Texto lido por leitor de tela. Nulo significa ícone decorativo.
  final String? rotuloSemantico;

  @override
  Widget build(BuildContext context) {
    final temaIcone = IconTheme.of(context);
    final corFinal =
        cor ?? temaIcone.color ?? Theme.of(context).colorScheme.onSurface;
    final tamanhoFinal = tamanho ?? temaIcone.size ?? tamanhoPadrao;

    return SvgPicture(
      AssetBytesLoader(nome.caminhoCompilado),
      width: tamanhoFinal,
      height: tamanhoFinal,
      colorFilter: ColorFilter.mode(corFinal, BlendMode.srcIn),
      semanticsLabel: rotuloSemantico,
      excludeFromSemantics: rotuloSemantico == null,
    );
  }
}
