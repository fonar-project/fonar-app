/// De onde vem o nível do microfone.
///
/// Contrato para que a regra da aferição e a tela possam ser testadas sem
/// microfone. A implementação real está em `data/fonte_de_nivel_record.dart`.
abstract interface class FonteDeNivel {
  /// Pede — se ainda não houver — a permissão de microfone.
  ///
  /// No Windows tende a responder `true` sempre: não há diálogo, e o bloqueio
  /// por privacidade só aparece como silêncio. É por isso que a aferição
  /// existe.
  Future<bool> pedirPermissao();

  /// Abre o microfone e emite o nível, em dBFS, a cada `intervalo`.
  ///
  /// Pode emitir valor não finito (menos infinito) quando o trecho é silêncio
  /// digital — ver `zonaDe`.
  Future<Stream<double>> abrir(Duration intervalo);

  /// Fecha o microfone. Seguro de chamar mais de uma vez, ou sem ter aberto.
  Future<void> fechar();

  /// O que o aparelho mudou da configuração pedida, ou `null` se aceitou
  /// tudo. Só faz sentido depois de [abrir].
  ///
  /// É a verificação do que de fato saiu, e não do que foi pedido — regra da
  /// captura no CLAUDE.md.
  AjusteDeConfiguracao? get ajuste;
}

/// A configuração que o aparelho usou no lugar da pedida.
class AjusteDeConfiguracao {
  const AjusteDeConfiguracao({
    required this.taxaDeAmostragem,
    required this.canais,
  });

  final int taxaDeAmostragem;
  final int canais;
}
