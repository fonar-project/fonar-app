import 'cabecalho_wav.dart';
import 'nivel_de_audio.dart';

/// O que pode estar errado numa gravação, conferido depois de ela sair.
enum ProblemaNaAmostra {
  // ---------------------------------------------- invalidam a amostra --

  /// O arquivo não existe, não é WAV ou não tem cabeçalho legível.
  arquivoIlegivel,

  /// É WAV, mas não é PCM sem compressão.
  naoEPcm,

  /// PCM, mas não de 16 bits.
  bitsDiferentes,

  /// O arquivo declara mais áudio do que tem — gravação interrompida no
  /// meio, cabeçalho nunca finalizado.
  incompleto,

  /// Menos que [VerificacaoDaAmostra.duracaoMinima]. Quase sempre um toque
  /// sem querer em "Parar".
  curtaDemais,

  /// O medidor não viu som durante a gravação: o microfone ficou mudo. É o
  /// risco documentado em `core/permissions/microphone_permission.dart`, que
  /// a aferição reduz mas não elimina — o acesso pode ser cortado entre a
  /// aferição e a gravação.
  semSinal,

  // ------------------------------------------ só avisam, não invalidam --

  /// Houve pico no máximo digital: a onda foi cortada, e o corte altera o
  /// que a análise mede. Não invalida sozinho — um pico isolado pode não
  /// importar —, mas o profissional precisa saber para decidir regravar.
  saturou,

  /// O aparelho gravou com outra taxa ou outro número de canais.
  ///
  /// TODO(backend): decidir com a API de análise se isto invalida.
  formatoAjustado;

  /// Com este problema a amostra não pode seguir para a análise.
  bool get invalida => switch (this) {
    saturou || formatoAjustado => false,
    _ => true,
  };
}

/// Regras da conferência de uma amostra gravada.
abstract final class VerificacaoDaAmostra {
  /// Abaixo disto a gravação é tida como toque acidental.
  ///
  /// Critério TÉCNICO, não clínico: quanto cada tarefa deve durar é decisão
  /// do protocolo clínico e não está codificada aqui.
  static const duracaoMinima = Duration(seconds: 1);

  static const bitsEsperados = 16;

  /// Confere o que saiu contra o que foi pedido.
  ///
  /// [cabecalho] é o lido do arquivo gravado (nulo se ilegível);
  /// [tamanhoDoArquivo], o tamanho real em bytes; [leituras], o que o medidor
  /// leu durante a gravação.
  ///
  /// Nenhuma amostra de áudio é analisada: só o cabeçalho, o tamanho do
  /// arquivo e as leituras do medidor — que são a exceção permitida de
  /// processamento local.
  static List<ProblemaNaAmostra> verificar({
    required CabecalhoWav? cabecalho,
    required int tamanhoDoArquivo,
    required List<double> leituras,
    required int taxaPedida,
    required int canaisPedidos,
  }) {
    if (cabecalho == null) return const [ProblemaNaAmostra.arquivoIlegivel];

    final curta = cabecalho.duracao < duracaoMinima;
    final problemas = <ProblemaNaAmostra>[
      if (!cabecalho.ehPcm) ProblemaNaAmostra.naoEPcm,
      if (cabecalho.bitsPorAmostra != bitsEsperados)
        ProblemaNaAmostra.bitsDiferentes,
      if (cabecalho.inicioDoAudio + cabecalho.bytesDeAudio > tamanhoDoArquivo)
        ProblemaNaAmostra.incompleto,
      if (curta) ProblemaNaAmostra.curtaDemais,
      // Gravação curta demais tem leituras de menos para julgar o sinal, e
      // dizer "o microfone não captou som" a quem só tocou em Parar cedo
      // mandaria o profissional investigar o microfone à toa.
      if (!curta && microfoneMudo(leituras)) ProblemaNaAmostra.semSinal,
      if (leituras.any((l) => zonaDe(l) == ZonaDeNivel.saturando))
        ProblemaNaAmostra.saturou,
      if (cabecalho.taxaDeAmostragem != taxaPedida ||
          cabecalho.canais != canaisPedidos)
        ProblemaNaAmostra.formatoAjustado,
    ];
    return problemas;
  }
}
