/// Leitura do nível do microfone, em tempo real.
///
/// É a ÚNICA leitura de áudio que o aplicativo faz por conta própria — a
/// exceção da regra de que nenhuma análise acústica roda no cliente. Serve ao
/// medidor de nível e à aferição de ruído ambiente, por exigência de latência.
/// Não é medida clínica e nunca vai para o laudo.
///
/// O valor é o pico do trecho em dBFS: 0 é o máximo digital (a partir dali o
/// sinal é cortado), e quanto mais negativo, mais baixo.
library;

/// Faixa em que o nível está, do ponto de vista da CAPTURA — não da voz.
///
/// "Adequado" quer dizer "o sinal chega inteiro e acima do ruído do próprio
/// equipamento", nada mais. Não diz nada sobre a voz do paciente.
enum ZonaDeNivel {
  /// Silêncio digital, ou leitura impossível. Microfone mudo, desligado ou
  /// bloqueado pelo sistema — nunca uma sala silenciosa.
  semSinal,
  baixo,
  adequado,
  alto,

  /// Perto do máximo digital: o pico da onda é cortado, e o corte altera
  /// justamente o que a análise mede.
  saturando,
}

/// Onde cada zona começa, em dBFS.
///
/// TODO(calibração): valores de partida, de convenção de gravação, NÃO
/// validados com o equipamento do projeto. Precisam ser conferidos
/// empiricamente — com o microfone e os aparelhos reais — e combinados com
/// quem mantém a API de análise. Não são faixa de referência clínica.
abstract final class LimitesDeNivel {
  /// Abaixo disto é silêncio digital. Um microfone de verdade, ligado, numa
  /// sala real, nunca chega aqui: o ruído do próprio circuito fica acima.
  static const pisoDigital = -90.0;

  static const baixoAbaixoDe = -40.0;
  static const altoAPartirDe = -12.0;
  static const saturaAPartirDe = -1.0;

  /// Faixa desenhada no medidor. Abaixo de [minimoDoMedidor] a barra fica
  /// vazia; o número continua aparecendo.
  static const minimoDoMedidor = -60.0;
}

/// A zona de uma leitura em dBFS.
///
/// Leitura que não é número finito cai em [ZonaDeNivel.semSinal]. Não é
/// cuidado teórico: no Windows, amostras todas zeradas — o microfone mudo por
/// privacidade — viram `20·log10(0)`, que é menos infinito.
ZonaDeNivel zonaDe(double dbfs) {
  if (!dbfs.isFinite || dbfs <= LimitesDeNivel.pisoDigital) {
    return ZonaDeNivel.semSinal;
  }
  if (dbfs >= LimitesDeNivel.saturaAPartirDe) return ZonaDeNivel.saturando;
  if (dbfs >= LimitesDeNivel.altoAPartirDe) return ZonaDeNivel.alto;
  if (dbfs < LimitesDeNivel.baixoAbaixoDe) return ZonaDeNivel.baixo;
  return ZonaDeNivel.adequado;
}

/// Quanto da barra do medidor preencher, de 0 a 1.
double fracaoDoMedidor(double dbfs) {
  if (!dbfs.isFinite) return dbfs > 0 ? 1 : 0;
  const minimo = LimitesDeNivel.minimoDoMedidor;
  return ((dbfs - minimo) / (0 - minimo)).clamp(0.0, 1.0);
}

/// Leituras válidas mínimas para afirmar que há sinal.
const leiturasValidasMinimas = 10;

/// Variação mínima, em dB, entre a maior e a menor leitura válida.
///
/// Som de verdade oscila — ruído de sala, voz, até o chiado do circuito.
/// Leitura parada no mesmo valor é o microfone entregando um número fixo. O
/// caso concreto: plataforma sem suporte a amplitude devolve sempre zero, que
/// sem esta regra seria lido como "saturando" — e aprovado como sinal.
const variacaoMinima = 0.5;

/// As leituras mostram um microfone que NÃO capta som?
///
/// Vale para a aferição e para a gravação. Na dúvida, responde que sim:
/// deixar passar um microfone mudo custa uma consulta; barrar um microfone bom
/// custa repetir a medida.
///
/// Silêncio digital em PARTE das leituras é normal no começo da captura,
/// antes do primeiro trecho chegar — por isso se exige um mínimo de leituras
/// válidas, e não que todas sejam válidas.
bool microfoneMudo(List<double> leituras) {
  final validas = [
    for (final l in leituras)
      if (zonaDe(l) != ZonaDeNivel.semSinal) l,
  ];
  if (validas.length < leiturasValidasMinimas) return true;
  validas.sort();
  return validas.last - validas.first < variacaoMinima;
}
