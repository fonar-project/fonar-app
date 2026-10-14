import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../captura/data/arquivos_de_amostra_no_navegador.dart';
import '../../captura/data/gravador_record.dart';
import '../domain/reprodutor.dart';

/// Um reprodutor por tela; sair dela solta o áudio.
final reprodutorProvider = Provider.autoDispose<Reprodutor>((ref) {
  final arquivos = ref.watch(arquivosDeAmostraProvider);
  final reprodutor = ReprodutorAudioplayers(
    // No navegador (US42), a gravação está no banco local.
    lerDoNavegador: arquivos is ArquivosDeAmostraNoNavegador
        ? arquivos.lerTudo
        : null,
  );
  ref.onDispose(reprodutor.fechar);
  return reprodutor;
});

/// Pelo `audioplayers`, que toca pelo reprodutor de cada sistema — o
/// `audioplayers_android` no Android e o `audioplayers_windows` no Windows,
/// os dois endossados pelo pacote principal.
///
/// Só REPRODUZ: não analisa, não mede. Ver a regra de processamento de áudio
/// no CLAUDE.md.
class ReprodutorAudioplayers implements Reprodutor {
  ReprodutorAudioplayers({this.lerDoNavegador}) {
    // Erro no meio da reprodução chega como erro do fluxo de eventos: o
    // pacote repassa para cá o que a camada nativa mandou.
    _eventos = _player.eventStream.listen(
      null,
      onError: (Object erro, StackTrace _) => _avisarFalha(erro),
    );
  }

  /// No navegador (US42), onde a gravação não é arquivo: os bytes do WAV
  /// guardado no banco local. Nulo no aparelho, que toca do disco.
  final Future<Uint8List?> Function(String caminho)? lerDoNavegador;

  final _player = AudioPlayer();
  final _falhas = StreamController<Object>.broadcast();
  late final StreamSubscription<AudioEvent> _eventos;

  /// O modo padrão é o `release`, que SOLTA o arquivo ao terminar de tocar —
  /// e aí ouvir de novo exigiria abrir outra vez. O controlador mantém a
  /// gravação carregada depois do fim, então o modo tem que ser o `stop`,
  /// que para e guarda o que já foi lido.
  late final Future<void> _configurado = _player.setReleaseMode(
    ReleaseMode.stop,
  );

  void _avisarFalha(Object erro) {
    if (!_falhas.isClosed) _falhas.add(erro);
  }

  @override
  Future<Duration?> abrir(String caminho) async {
    await _configurado;
    // `setSource...` só volta depois de o áudio estar preparado, e é por
    // isso que a duração já pode ser perguntada aqui. Arquivo ilegível
    // levanta erro daqui mesmo, antes de qualquer tentativa de tocar.
    if (lerDoNavegador case final ler?) {
      final wav = await ler(caminho);
      if (wav == null) throw StateError('Gravação não encontrada.');
      await _player.setSourceBytes(wav, mimeType: 'audio/wav');
    } else {
      await _player.setSourceDeviceFile(caminho);
    }
    return _player.getDuration();
  }

  @override
  Future<void> tocar() => _player.resume();

  @override
  Future<void> pausar() => _player.pause();

  @override
  Future<void> irPara(Duration posicao) => _player.seek(posicao);

  @override
  Stream<Duration> get posicoes => _player.onPositionChanged;

  @override
  Stream<void> get terminou => _player.onPlayerComplete;

  @override
  Stream<Object> get falhas => _falhas.stream;

  @override
  Future<void> fechar() async {
    await _eventos.cancel();
    await _falhas.close();
    await _player.dispose();
  }
}
