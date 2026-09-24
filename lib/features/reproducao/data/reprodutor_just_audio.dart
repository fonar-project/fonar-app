import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/reprodutor.dart';

/// Um reprodutor por tela; sair dela solta o áudio.
final reprodutorProvider = Provider.autoDispose<Reprodutor>((ref) {
  final reprodutor = ReprodutorJustAudio();
  ref.onDispose(reprodutor.fechar);
  return reprodutor;
});

/// Pelo `just_audio` — no Windows, pelo `just_audio_windows`, que usa o
/// reprodutor do próprio sistema.
///
/// NÃO VERIFICADO EM APARELHO REAL: o ambiente em que foi escrito não tem
/// saída de som nem Windows.
class ReprodutorJustAudio implements Reprodutor {
  ReprodutorJustAudio() {
    // Erro no meio da reprodução chega pelo fluxo de eventos do player.
    _eventos = _player.playbackEventStream.listen(
      null,
      onError: (Object erro, StackTrace _) => _avisarFalha(erro),
    );
  }

  final _player = AudioPlayer();
  final _falhas = StreamController<Object>.broadcast();
  late final StreamSubscription<PlaybackEvent> _eventos;

  void _avisarFalha(Object erro) {
    if (!_falhas.isClosed) _falhas.add(erro);
  }

  @override
  Future<Duration?> abrir(String caminho) => _player.setFilePath(caminho);

  @override
  Future<void> tocar() async {
    // `play` só completa quando a reprodução termina ou pausa; a tela não
    // pode esperar por isso. Mas o erro dele não pode se perder: vai para
    // [falhas].
    unawaited(_player.play().catchError(_avisarFalha));
  }

  @override
  Future<void> pausar() => _player.pause();

  @override
  Future<void> irPara(Duration posicao) => _player.seek(posicao);

  @override
  Stream<Duration> get posicoes => _player.positionStream;

  @override
  Stream<void> get terminou => _player.processingStateStream
      .where((s) => s == ProcessingState.completed)
      .map((_) {});

  @override
  Stream<Object> get falhas => _falhas.stream;

  @override
  Future<void> fechar() async {
    await _eventos.cancel();
    await _falhas.close();
    await _player.dispose();
  }
}
