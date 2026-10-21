import 'nivel_de_audio.dart';

/// O que a aferição de ruído ambiente concluiu.
enum ConclusaoDaAfericao {
  /// O microfone não entregou som de verdade. BLOQUEIA a gravação.
  ///
  /// É o risco documentado em `core/permissions/microphone_permission.dart`:
  /// no Windows, com o microfone bloqueado pela privacidade do sistema, a
  /// captura roda sem erro e grava silêncio. Descoberto só depois, é consulta
  /// perdida — a coleta não se repete.
  ///
  /// Silêncio digital também é o que entrega, numa sala silenciosa de
  /// verdade, um microfone que zera o sinal enquanto não há som. Os dois
  /// casos só se separam com som: a conferência com a voz
  /// ([AfericaoDeRuido.concluirComAVoz]) libera o segundo sem liberar o
  /// primeiro.
  microfoneMudo,

  /// O ambiente está mais barulhento que o limite. Não bloqueia: o
  /// profissional decide, sabendo disso.
  ruidoAlto,

  /// Nada impede a gravação.
  semRestricao,
}

/// Em que pé está a conferência do microfone com a voz.
enum ConferenciaComAVoz {
  /// Não foi feita: a aferição mediu a sala e concluiu sozinha.
  naoFeita,

  /// A sala ficou em silêncio digital, e a voz chegou: o microfone capta, e
  /// a sala está abaixo do que ele mede.
  captou,

  /// Nem a voz chegou. O microfone não capta.
  naoCaptou,
}

/// Resultado da aferição: a conclusão e o nível típico medido.
class ResultadoDaAfericao {
  const ResultadoDaAfericao({
    required this.conclusao,
    this.nivelTipico,
    this.voz = ConferenciaComAVoz.naoFeita,
  });

  final ConclusaoDaAfericao conclusao;

  /// Mediana das leituras, em dBFS. Nula quando não houve leitura válida —
  /// inclusive na sala abaixo do que o microfone mede.
  final double? nivelTipico;

  final ConferenciaComAVoz voz;
}

/// Regras da aferição de ruído ambiente.
abstract final class AfericaoDeRuido {
  /// Quanto tempo o microfone fica aberto medindo a sala.
  static const duracao = Duration(seconds: 5);

  /// De quanto em quanto tempo o nível é lido.
  static const intervalo = Duration(milliseconds: 100);

  /// Ruído ambiente típico acima disto é [ConclusaoDaAfericao.ruidoAlto].
  ///
  /// TODO(calibração): valor de partida, NÃO validado. O quanto de ruído a
  /// análise tolera depende do microfone, da distância e das medidas — é
  /// decisão a tomar com quem mantém a API de análise e com a orientação
  /// clínica, e deve virar configuração, não constante.
  static const limiteDeRuido = -50.0;

  /// Por quanto tempo, no máximo, a conferência com a voz escuta. Termina
  /// antes, assim que a voz chega ([vozChegou]).
  static const duracaoDaConferencia = Duration(seconds: 6);

  /// As leituras da conferência com a voz já provam que o microfone capta?
  ///
  /// A mesma regra da gravação ([microfoneMudo]): leituras válidas que
  /// bastem, e que variem. Um número fixo — o de uma plataforma sem
  /// amplitude, o −160 de um microfone bloqueado — não passa.
  static bool vozChegou(List<double> leituras) => !microfoneMudo(leituras);

  /// Conclui a conferência com a voz, feita depois de [concluir] dar
  /// [ConclusaoDaAfericao.microfoneMudo].
  ///
  /// Com voz, a sala estava abaixo do que o microfone mede — e isso é sala
  /// adequada, não ruído alto: libera. Sem voz, continua mudo, agora com a
  /// certeza de que não é a sala.
  static ResultadoDaAfericao concluirComAVoz(List<double> leituras) =>
      vozChegou(leituras)
      ? const ResultadoDaAfericao(
          conclusao: ConclusaoDaAfericao.semRestricao,
          voz: ConferenciaComAVoz.captou,
        )
      : const ResultadoDaAfericao(
          conclusao: ConclusaoDaAfericao.microfoneMudo,
          voz: ConferenciaComAVoz.naoCaptou,
        );

  /// Conclui a partir das leituras colhidas durante [duracao]. A regra do
  /// microfone mudo é a de [microfoneMudo], a mesma da gravação.
  static ResultadoDaAfericao concluir(List<double> leituras) {
    if (microfoneMudo(leituras)) {
      return const ResultadoDaAfericao(
        conclusao: ConclusaoDaAfericao.microfoneMudo,
      );
    }

    final validas = [
      for (final l in leituras)
        if (zonaDe(l) != ZonaDeNivel.semSinal) l,
    ]..sort();
    final mediana = validas[validas.length ~/ 2];
    return ResultadoDaAfericao(
      conclusao: mediana > limiteDeRuido
          ? ConclusaoDaAfericao.ruidoAlto
          : ConclusaoDaAfericao.semRestricao,
      nivelTipico: mediana,
    );
  }
}
