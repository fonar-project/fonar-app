import 'nivel_de_audio.dart';

/// O que a aferição de ruído ambiente concluiu.
enum ConclusaoDaAfericao {
  /// O microfone não entregou som de verdade. BLOQUEIA a gravação.
  ///
  /// É o risco documentado em `core/permissions/microphone_permission.dart`:
  /// no Windows, com o microfone bloqueado pela privacidade do sistema, a
  /// captura roda sem erro e grava silêncio. Descoberto só depois, é consulta
  /// perdida — a coleta não se repete.
  microfoneMudo,

  /// O ambiente está mais barulhento que o limite. Não bloqueia: o
  /// profissional decide, sabendo disso.
  ruidoAlto,

  /// Nada impede a gravação.
  semRestricao,
}

/// Resultado da aferição: a conclusão e o nível típico medido.
class ResultadoDaAfericao {
  const ResultadoDaAfericao({required this.conclusao, this.nivelTipico});

  final ConclusaoDaAfericao conclusao;

  /// Mediana das leituras, em dBFS. Nula quando não houve leitura válida.
  final double? nivelTipico;
}

/// Regras da aferição de ruído ambiente.
abstract final class AfericaoDeRuido {
  /// Quanto tempo o microfone fica aberto medindo a sala.
  static const duracao = Duration(seconds: 5);

  /// De quanto em quanto tempo o nível é lido.
  static const intervalo = Duration(milliseconds: 100);

  /// Menos leituras que isto e a aferição não prova nada.
  static const leiturasMinimas = 10;

  /// Ruído ambiente típico acima disto é [ConclusaoDaAfericao.ruidoAlto].
  ///
  /// TODO(calibração): valor de partida, NÃO validado. O quanto de ruído a
  /// análise tolera depende do microfone, da distância e das medidas — é
  /// decisão a tomar com quem mantém a API de análise e com a orientação
  /// clínica, e deve virar configuração, não constante.
  static const limiteDeRuido = -50.0;

  /// Variação mínima, em dB, entre a maior e a menor leitura.
  ///
  /// Ruído de verdade oscila. Leitura parada no mesmo valor por segundos
  /// seguidos é o microfone entregando um número fixo, não uma sala. O caso
  /// concreto: plataforma sem suporte a amplitude devolve sempre zero, que
  /// sem esta regra seria lido como "saturando" — e aprovado como "sinal
  /// presente".
  static const variacaoMinima = 0.5;

  /// Conclui a partir das leituras colhidas durante [duracao].
  ///
  /// Na dúvida, conclui [ConclusaoDaAfericao.microfoneMudo]: deixar gravar
  /// com o microfone mudo custa uma consulta; bloquear um microfone bom custa
  /// uma segunda aferição.
  static ResultadoDaAfericao concluir(List<double> leituras) {
    final validas = [
      for (final l in leituras)
        if (zonaDe(l) != ZonaDeNivel.semSinal) l,
    ];

    // Silêncio digital em parte das leituras, com o resto válido, acontece
    // no começo da captura, antes de o primeiro trecho chegar. Por isso a
    // exigência é de leituras VÁLIDAS suficientes, não de todas válidas.
    if (validas.length < leiturasMinimas) {
      return const ResultadoDaAfericao(
        conclusao: ConclusaoDaAfericao.microfoneMudo,
      );
    }

    validas.sort();
    final variacao = validas.last - validas.first;
    if (variacao < variacaoMinima) {
      return const ResultadoDaAfericao(
        conclusao: ConclusaoDaAfericao.microfoneMudo,
      );
    }

    final mediana = validas[validas.length ~/ 2];
    return ResultadoDaAfericao(
      conclusao: mediana > limiteDeRuido
          ? ConclusaoDaAfericao.ruidoAlto
          : ConclusaoDaAfericao.semRestricao,
      nivelTipico: mediana,
    );
  }
}
