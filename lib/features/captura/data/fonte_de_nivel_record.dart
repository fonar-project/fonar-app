import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../domain/fonte_de_nivel.dart';
import 'configuracao_de_captura.dart';

/// Uma fonte nova a cada uso: cada aferição abre e fecha o próprio recorder.
final fonteDeNivelProvider = Provider.autoDispose<FonteDeNivel>((ref) {
  final fonte = FonteDeNivelRecord();
  // Sair da tela fecha o microfone. Microfone aberto sem ninguém olhando é
  // exatamente o que não pode acontecer com dado de saúde.
  ref.onDispose(fonte.fechar);
  return fonte;
});

/// Nível do microfone lido pelo pacote `record`.
///
/// A aferição abre uma captura em fluxo (nada é gravado em arquivo) e lê o
/// nível pelo `onAmplitudeChanged`. Os bytes de áudio chegam e são
/// descartados: o aplicativo não analisa áudio — só o nível, que é a exceção
/// permitida.
///
/// NÃO VERIFICADO EM APARELHO REAL. Escrito contra a API do `record` 7.1 e o
/// código do `record_windows` 2.3, sem microfone para testar. Conferir no
/// Android e no Windows antes de confiar, em especial: o valor que chega com
/// o microfone bloqueado pela privacidade do Windows, e se o
/// `setOnConfigChanged` dispara quando o aparelho troca a taxa.
class FonteDeNivelRecord implements FonteDeNivel {
  FonteDeNivelRecord();

  AudioRecorder? _gravador;
  StreamSubscription<List<int>>? _bytes;
  AjusteDeConfiguracao? _ajuste;

  @override
  AjusteDeConfiguracao? get ajuste => _ajuste;

  @override
  Future<bool> pedirPermissao() async {
    final gravador = _gravador ??= AudioRecorder();
    return gravador.hasPermission();
  }

  @override
  Future<Stream<double>> abrir(Duration intervalo) async {
    final gravador = _gravador ??= AudioRecorder();
    _ajuste = null;
    await gravador.setOnConfigChanged((usada) {
      _ajuste = AjusteDeConfiguracao(
        taxaDeAmostragem: usada.sampleRate,
        canais: usada.numChannels,
      );
    });

    final audio = await gravador.startStream(
      ConfiguracaoDeCaptura.para(ConfiguracaoDeCaptura.formatoDaAfericao),
    );
    // Consumir o fluxo é obrigatório — sem ouvinte, os trechos se acumulam
    // na memória. O conteúdo é descartado.
    _bytes = audio.listen((_) {});

    return gravador.onAmplitudeChanged(intervalo).map((a) => a.current);
  }

  @override
  Future<void> fechar() async {
    final gravador = _gravador;
    _gravador = null;
    await _bytes?.cancel();
    _bytes = null;
    if (gravador == null) return;
    try {
      await gravador.stop();
    } finally {
      await gravador.dispose();
    }
  }
}
