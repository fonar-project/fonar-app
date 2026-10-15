import '../../../l10n/app_strings.dart';

/// O que um elemento da tela É, para o guia (US50).
///
/// O guia aponta para o elemento pelo papel, nunca pela posição: no desktop
/// a fila é um item da barra lateral, no celular uma aba embaixo, e a
/// conexão sobe do rodapé da barra lateral para o cabeçalho da lista. Cada
/// elemento se declara com `AlvoDoGuia`, onde quer que esteja.
enum PapelNoGuia { novaAvaliacao, lista, fila, conta, conexao, ajuda }

/// Um passo do guia: o elemento que ele destaca e o que diz dele.
class PassoDoGuia {
  const PassoDoGuia({
    required this.papel,
    required this.titulo,
    required this.texto,
    this.textoSemAlvo,
  });

  final PapelNoGuia papel;

  /// O nome do elemento. O recorte na tela não é a única pista: o balão diz
  /// em texto o que está destacado.
  final String titulo;
  final String texto;

  /// O texto quando o elemento não está na tela — a lista, na conta nova,
  /// ainda vazia. Aí o passo vira explicação, sem apontar para o nada.
  final String? textoSemAlvo;

  String textoQuando({required bool comAlvo}) =>
      comAlvo ? texto : (textoSemAlvo ?? texto);
}

/// O guia da tela inicial, na ordem em que se lê a tela: por onde começa,
/// onde ficam os pacientes, para onde vão as gravações, a conta, a conexão
/// e onde rever o guia.
const passosDoGuiaDoInicio = <PassoDoGuia>[
  PassoDoGuia(
    papel: PapelNoGuia.novaAvaliacao,
    titulo: AppStrings.guiaNovaAvaliacaoTitulo,
    texto: AppStrings.guiaNovaAvaliacaoTexto,
  ),
  PassoDoGuia(
    papel: PapelNoGuia.lista,
    titulo: AppStrings.guiaListaTitulo,
    texto: AppStrings.guiaListaTexto,
    textoSemAlvo: AppStrings.guiaListaVaziaTexto,
  ),
  PassoDoGuia(
    papel: PapelNoGuia.fila,
    titulo: AppStrings.guiaFilaTitulo,
    texto: AppStrings.guiaFilaTexto,
  ),
  PassoDoGuia(
    papel: PapelNoGuia.conta,
    titulo: AppStrings.guiaContaTitulo,
    texto: AppStrings.guiaContaTexto,
  ),
  PassoDoGuia(
    papel: PapelNoGuia.conexao,
    titulo: AppStrings.guiaConexaoTitulo,
    texto: AppStrings.guiaConexaoTexto,
  ),
  PassoDoGuia(
    papel: PapelNoGuia.ajuda,
    titulo: AppStrings.guiaAjudaTitulo,
    texto: AppStrings.guiaAjudaTexto,
  ),
];
