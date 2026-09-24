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

  /// Ruído ambiente típico acima disto é [ConclusaoDaAfericao.ruidoAlto].
  ///
  /// TODO(calibração): valor de partida, NÃO validado. O quanto de ruído a
  /// análise tolera depende do microfone, da distância e das medidas — é
  /// decisão a tomar com quem mantém a API de análise e com a orientação
  /// clínica, e deve virar configuração, não constante.
  static const limiteDeRuido = -50.0;

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
