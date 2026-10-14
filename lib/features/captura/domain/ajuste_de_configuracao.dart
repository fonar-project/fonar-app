import 'processamento_automatico.dart';

/// A configuração que o aparelho usou no lugar da pedida.
///
/// Existe porque PEDIR NÃO É RECEBER: a regra de captura do CLAUDE.md manda
/// verificar empiricamente o que saiu. Vale para as duas capturas — a da
/// aferição (`FonteDeNivel.ajuste`) e a da gravação (`Gravador.ajuste`) —, e
/// por isso não mora no arquivo de nenhuma das duas.
///
/// Taxa, canais e o processamento automático que ficou ligado. Os bits não:
/// o pacote `record` não tem parâmetro de profundidade de bits e não avisa
/// sobre ela. Eles são conferidos no cabeçalho do WAV
/// (`VerificacaoDaAmostra`), única evidência que existe.
class AjusteDeConfiguracao {
  const AjusteDeConfiguracao({
    required this.taxaDeAmostragem,
    required this.canais,
    this.processamentoLigado = const {},
  });

  final int taxaDeAmostragem;
  final int canais;

  /// O processamento automático que o aparelho manteve ligado, ou que não
  /// confirmou ter desligado (US42). Vazio: os três desligados.
  ///
  /// No Android e no desktop o `record` repassa o que foi pedido, e isto
  /// fica vazio. No navegador, é o que o próprio navegador relata da faixa
  /// de áudio — e é lá que o pedido pode não ser atendido.
  final Set<ProcessamentoAutomatico> processamentoLigado;

  /// Algum processamento ficou ligado? Então a captura não serve.
  bool get manteveProcessamento => processamentoLigado.isNotEmpty;

  /// Bate com o que foi pedido? Aparelho que aceitou tudo ainda pode chamar
  /// o aviso — é mais seguro responder aqui do que em cada chamador.
  ///
  /// Só o formato: o processamento é [manteveProcessamento].
  bool confere({required int taxaPedida, required int canaisPedidos}) =>
      taxaDeAmostragem == taxaPedida && canais == canaisPedidos;

  /// Junta o aviso do pacote de captura ([doGravador], nulo se ele não
  /// avisou nada) com o que a conferência do navegador encontrou
  /// ([doNavegador]). Nulo quando nenhum dos dois tem o que dizer.
  static AjusteDeConfiguracao? juntar(
    AjusteDeConfiguracao? doGravador,
    Set<ProcessamentoAutomatico> doNavegador, {
    required int taxaPedida,
    required int canaisPedidos,
  }) {
    if (doNavegador.isEmpty) return doGravador;
    return AjusteDeConfiguracao(
      taxaDeAmostragem: doGravador?.taxaDeAmostragem ?? taxaPedida,
      canais: doGravador?.canais ?? canaisPedidos,
      processamentoLigado: {
        ...?doGravador?.processamentoLigado,
        ...doNavegador,
      },
    );
  }
}
