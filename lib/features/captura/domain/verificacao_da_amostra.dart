import 'dart:math';
import 'dart:typed_data';

import 'ajuste_de_configuracao.dart';
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

  /// O microfone ficou mudo durante a gravação. É o risco documentado em
  /// `core/permissions/microphone_permission.dart`, que a aferição reduz mas
  /// não elimina — o acesso pode ser cortado entre a aferição e a gravação.
  ///
  /// Duas evidências independentes levam aqui: as leituras do medidor
  /// (`microfoneMudo`) e o próprio arquivo gravado
  /// (`VerificacaoDaAmostra.audioTodoEmZero`). A segunda existe porque a
  /// primeira vem do plugin: se ele informar amplitude plausível enquanto
  /// escreve zeros no disco, só o arquivo denuncia.
  semSinal,

  // ------------------------------------------ só avisam, não invalidam --

  /// Houve pico no máximo digital: a onda foi cortada, e o corte altera o
  /// que a análise mede. Não invalida sozinho — um pico isolado pode não
  /// importar —, mas o profissional precisa saber para decidir regravar.
  saturou,

  /// O aparelho gravou com outra taxa ou outro número de canais.
  ///
  /// Duas evidências levam aqui, e basta uma: o cabeçalho do WAV que saiu e o
  /// aviso do próprio aparelho durante a gravação (`Gravador.ajuste`). A
  /// segunda cobre o gravador que escreve no cabeçalho o que foi PEDIDO.
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

  /// Bytes de áudio que a janela precisa ter para o silêncio ser julgado.
  ///
  /// Cerca de 6 ms em 44,1 kHz, 16 bits, mono. Abaixo disto não se distingue
  /// "o driver está escrevendo zeros" de "o primeiro buffer da captura ainda
  /// não chegou".
  static const bytesMinimosParaJulgarSilencio = 512;

  /// O trecho de áudio já lido do arquivo está todo em zero absoluto?
  ///
  /// **Isto é comparação de byte com zero, não análise acústica.** Não há
  /// FFT, filtro, envelope nem medida: é um laço de `byte == 0` sobre os
  /// bytes que já estavam em memória para a leitura do cabeçalho, e a
  /// resposta é um booleano. Nada daqui vai para o laudo. A regra do
  /// CLAUDE.md continua valendo inteira — toda medida acústica (f0, jitter,
  /// shimmer, HNR, CPPS, AVQI) é do servidor, e esta função não é o começo de
  /// um caminho para trazer nenhuma delas para o cliente. Se algum dia for
  /// preciso saber QUANTO silêncio há, ou o nível do trecho, a pergunta é da
  /// API, não daqui.
  ///
  /// Zero absoluto não é sala silenciosa: um microfone ligado sempre entrega
  /// o ruído do próprio circuito, acima de [LimitesDeNivel.pisoDigital]. Uma
  /// sequência de zeros exatos é o driver preenchendo o buffer — o modo de
  /// falhar EM SILÊNCIO descrito em
  /// `core/permissions/microphone_permission.dart`: WAV válido, duração
  /// certa, amplitude zero, sem erro nenhum.
  ///
  /// [janela] é o começo do arquivo — os mesmos bytes que serviram ao
  /// cabeçalho, não o arquivo inteiro. Julga só o que está ali; se a janela
  /// não alcançar o áudio, ou alcançar pouco, responde `false`, porque não
  /// viu o bastante para acusar.
  static bool audioTodoEmZero(Uint8List janela, CabecalhoWav cabecalho) {
    final inicio = cabecalho.inicioDoAudio;
    // Não passar do fim do bloco `data`: o que vem depois pode ser metadado
    // (um `LIST` no rodapé), e metadado não é áudio.
    final fim = min(janela.length, inicio + cabecalho.bytesDeAudio);
    if (fim - inicio < bytesMinimosParaJulgarSilencio) return false;
    for (var i = inicio; i < fim; i++) {
      if (janela[i] != 0) return false;
    }
    return true;
  }

  /// Confere o que saiu contra o que foi pedido.
  ///
  /// [cabecalho] é o lido do arquivo gravado (nulo se ilegível);
  /// [inicioDoArquivo], a mesma janela de bytes de onde ele saiu (nula se o
  /// arquivo não pôde ser lido); [tamanhoDoArquivo], o tamanho real em bytes;
  /// [leituras], o que o medidor leu durante a gravação; [ajuste], o que o
  /// aparelho avisou ter mudado (nulo se não mudou nada, ou se não avisou).
  ///
  /// [bitsPedidos] vem de `ConfiguracaoDeCaptura.bitsPorAmostra`, e não de uma
  /// constante daqui: os bits são a única parte do formato que não se pede ao
  /// pacote de captura — saem da escolha do encoder. O valor esperado precisa
  /// morar junto do encoder que o determina, senão trocar um deixa o outro
  /// para trás.
  ///
  /// Nenhuma amostra de áudio é ANALISADA: só o cabeçalho, o tamanho do
  /// arquivo, as leituras do medidor — a exceção permitida de processamento
  /// local — e a comparação de bytes com zero de [audioTodoEmZero].
  static List<ProblemaNaAmostra> verificar({
    required CabecalhoWav? cabecalho,
    required Uint8List? inicioDoArquivo,
    required int tamanhoDoArquivo,
    required List<double> leituras,
    required int taxaPedida,
    required int canaisPedidos,
    required int bitsPedidos,
    AjusteDeConfiguracao? ajuste,
  }) {
    if (cabecalho == null) return const [ProblemaNaAmostra.arquivoIlegivel];

    final curta = cabecalho.duracao < duracaoMinima;
    // O aviso do aparelho vale por si: cabeçalho que repete o que foi PEDIDO
    // não desmente quem disse ter usado outra coisa. Sem aviso, só o
    // cabeçalho fala.
    final formatoTrocado =
        cabecalho.taxaDeAmostragem != taxaPedida ||
        cabecalho.canais != canaisPedidos ||
        !(ajuste?.confere(
              taxaPedida: taxaPedida,
              canaisPedidos: canaisPedidos,
            ) ??
            true);
    // Duas evidências de microfone mudo, cada uma de uma fonte: o plugin
    // (as leituras) e o disco (os bytes). Pedir as duas deixaria passar a
    // falha em que só uma acusa, e é justamente ela que preocupa.
    final mudo =
        microfoneMudo(leituras) ||
        (inicioDoArquivo != null &&
            audioTodoEmZero(inicioDoArquivo, cabecalho));
    final problemas = <ProblemaNaAmostra>[
      if (!cabecalho.ehPcm) ProblemaNaAmostra.naoEPcm,
      if (cabecalho.bitsPorAmostra != bitsPedidos)
        ProblemaNaAmostra.bitsDiferentes,
      if (cabecalho.inicioDoAudio + cabecalho.bytesDeAudio > tamanhoDoArquivo)
        ProblemaNaAmostra.incompleto,
      if (curta) ProblemaNaAmostra.curtaDemais,
      // Gravação curta demais tem leituras de menos para julgar o sinal, e
      // dizer "o microfone não captou som" a quem só tocou em Parar cedo
      // mandaria o profissional investigar o microfone à toa.
      if (!curta && mudo) ProblemaNaAmostra.semSinal,
      if (leituras.any((l) => zonaDe(l) == ZonaDeNivel.saturando))
        ProblemaNaAmostra.saturou,
      if (formatoTrocado) ProblemaNaAmostra.formatoAjustado,
    ];
    return problemas;
  }
}
