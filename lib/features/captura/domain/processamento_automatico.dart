/// O processamento que o sistema pode aplicar ao microfone por conta própria.
///
/// Os três mudam exatamente o que a análise mede (CLAUDE.md, captura de
/// áudio): o ganho automático achata a variação de intensidade, a supressão
/// de ruído come parte do sinal junto com o ruído, e o cancelamento de eco
/// filtra a voz como se fosse eco. A captura pede os três desligados; este
/// tipo é o que se descobre ter ficado LIGADO.
enum ProcessamentoAutomatico {
  ganhoAutomatico,
  supressaoDeRuido,
  cancelamentoDeEco,
}

/// O que o navegador NÃO confirmou ter desligado, pelo que ele mesmo relata
/// da faixa de áudio aberta (`MediaStreamTrack.getSettings()`) — US42.
///
/// Cada parâmetro é o valor relatado: `true`, ligado; `false`, desligado;
/// `null`, o navegador não relata essa propriedade.
///
/// A regra, de propósito assimétrica:
///
/// - **Cancelamento de eco** tem de vir relatado, e desligado. Todo motor de
///   navegador relata esta propriedade; quem não a relata não deu evidência
///   nenhuma, e sem evidência não se grava (verificar empiricamente, não
///   confiar no pedido).
/// - **Ganho automático e supressão de ruído** bloqueiam quando relatados
///   ligados. Não relatados, não bloqueiam: é o caso do Safari (WebKit), em
///   que os dois não são controles separados — fazem parte do mesmo
///   processamento de voz do sistema que o `echoCancellation` liga e
///   desliga. Com o cancelamento de eco confirmado desligado, eles também
///   estão.
///
/// A premissa do WebKit precisa ser conferida no iPhone (PENDENCIAS.md); se
/// não se confirmar, o certo é bloquear também os não relatados.
Set<ProcessamentoAutomatico> naoConfirmadosDesligados({
  required bool? ganho,
  required bool? ruido,
  required bool? eco,
}) => {
  if (ganho ?? false) ProcessamentoAutomatico.ganhoAutomatico,
  if (ruido ?? false) ProcessamentoAutomatico.supressaoDeRuido,
  if (eco != false) ProcessamentoAutomatico.cancelamentoDeEco,
};
