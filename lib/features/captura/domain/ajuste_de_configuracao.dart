/// A configuração que o aparelho usou no lugar da pedida.
///
/// Existe porque PEDIR NÃO É RECEBER: a regra de captura do CLAUDE.md manda
/// verificar empiricamente o que saiu. Vale para as duas capturas — a da
/// aferição (`FonteDeNivel.ajuste`) e a da gravação (`Gravador.ajuste`) —, e
/// por isso não mora no arquivo de nenhuma das duas.
///
/// Só taxa e canais: o pacote `record` não tem parâmetro de profundidade de
/// bits e não avisa sobre ela. Os bits são conferidos no cabeçalho do WAV
/// (`VerificacaoDaAmostra`), única evidência que existe.
class AjusteDeConfiguracao {
  const AjusteDeConfiguracao({
    required this.taxaDeAmostragem,
    required this.canais,
  });

  final int taxaDeAmostragem;
  final int canais;

  /// Bate com o que foi pedido? Aparelho que aceitou tudo ainda pode chamar
  /// o aviso — é mais seguro responder aqui do que em cada chamador.
  bool confere({required int taxaPedida, required int canaisPedidos}) =>
      taxaDeAmostragem == taxaPedida && canais == canaisPedidos;
}
