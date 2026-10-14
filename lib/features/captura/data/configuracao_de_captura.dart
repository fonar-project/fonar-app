import 'package:record/record.dart';

import '../domain/ajuste_de_configuracao.dart';
import '../domain/processamento_automatico.dart';

/// A configuração de captura do projeto, fixada em UM lugar.
///
/// Regra da captura no CLAUDE.md: desligar todo processamento automático e
/// fixar formato. Ganho automático, supressão de ruído e cancelamento de eco
/// alteram exatamente as propriedades do sinal que a análise mede — é o
/// requisito que justifica o app nativo em vez de web. A versão no navegador
/// (US42) só grava se o navegador relatar os três desligados
/// (`naoConfirmadosDesligados`).
///
/// Pedir não garante receber. O que o aparelho de fato usou é conferido pelo
/// `setOnConfigChanged` do recorder — nas DUAS capturas, a da aferição
/// (`FonteDeNivelRecord.ajuste`) e a da gravação (`GravadorRecord.ajuste`) —
/// e, na gravação, conferido de novo no cabeçalho do WAV que saiu
/// (`VerificacaoDaAmostra`).
///
/// A API de análise aceita WAV PCM mono de 16, 24 ou 32 bits, de 8 a
/// 192 kHz, até 60 s e 20 MB, e confere taxa e canais declarados contra o
/// cabeçalho (`domain/audio.py`, no repositório `fonar-api`). 44,1 kHz mono
/// está dentro.
abstract final class ConfiguracaoDeCaptura {
  static const taxaDeAmostragem = 44100;
  static const canais = 1;

  /// PCM sem compressão com perdas. `wav` no `record` é PCM de 16 bits.
  static const formatoDaGravacao = AudioEncoder.wav;

  /// O mesmo PCM de 16 bits, sem cabeçalho — para a aferição, em que só o
  /// nível interessa e nada é salvo.
  static const formatoDaAfericao = AudioEncoder.pcm16bits;

  /// Profundidade de bits que estes dois formatos implicam.
  ///
  /// **É SUPOSIÇÃO, e é a mais frágil das três.** O `RecordConfig` do
  /// `record` tem `sampleRate` e `numChannels`, mas NÃO tem parâmetro de
  /// profundidade de bits: ela vem embutida na escolha do encoder — `wav` e
  /// `pcm16bits` valem 16 —, e o `setOnConfigChanged` também não fala dela.
  /// Ou seja: taxa e canais podem ser pedidos e o aparelho avisa quando muda;
  /// os bits nunca são pedidos e ninguém avisa.
  ///
  /// Por isso este número não é usado para configurar nada — ele existe para
  /// ser CONFERIDO. A única evidência de que saíram 16 bits é o cabeçalho do
  /// WAV gravado, e é daqui que a conferência tira o valor esperado
  /// (`VerificacaoDaAmostra.verificar`, parâmetro `bitsPedidos`). Trocar o
  /// encoder obriga a trocar este número no mesmo commit.
  static const bitsPorAmostra = 16;

  /// O que o `setOnConfigChanged` avisou, no tipo do domínio.
  ///
  /// No navegador, o `record_web` lê a faixa de áudio aberta
  /// (`getSettings()`) e devolve ganho, supressão de ruído e cancelamento de
  /// eco como o navegador os relata — é por aqui que se descobre o
  /// processamento que ficou ligado. Propriedade não relatada volta como foi
  /// pedida (desligada), e por isso a aferição no navegador confere também
  /// por conta própria (`naoConfirmadosDesligados`).
  static AjusteDeConfiguracao ajusteDe(RecordConfig usada) =>
      AjusteDeConfiguracao(
        taxaDeAmostragem: usada.sampleRate,
        canais: usada.numChannels,
        processamentoLigado: {
          if (usada.autoGain) ProcessamentoAutomatico.ganhoAutomatico,
          if (usada.noiseSuppress) ProcessamentoAutomatico.supressaoDeRuido,
          if (usada.echoCancel) ProcessamentoAutomatico.cancelamentoDeEco,
        },
      );

  static RecordConfig para(AudioEncoder formato) => RecordConfig(
    encoder: formato,
    sampleRate: taxaDeAmostragem,
    numChannels: canais,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
    androidConfig: const AndroidRecordConfig(
      // A fonte VOICE_RECOGNITION é a que a definição de compatibilidade do
      // Android exige que chegue SEM ganho automático e sem redução de ruído.
      // A fonte padrão pode vir processada conforme o fabricante; a
      // UNPROCESSED seria a ideal, mas não existe em todo aparelho, e pedir
      // uma fonte inexistente faz a captura falhar.
      audioSource: AndroidAudioSource.voiceRecognition,
      // Não trocar sozinho para o microfone de um fone Bluetooth: o áudio
      // chegaria comprimido e de outro microfone, sem ninguém perceber.
      manageBluetooth: false,
    ),
  );
}
