import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../captura/data/arquivos_de_amostra_no_navegador.dart';
import '../../captura/data/gravador_record.dart';
import '../domain/reprodutor.dart';
import 'gravacoes_para_ouvir.dart';

/// Um reprodutor por tela; sair dela solta o áudio.
final reprodutorProvider = Provider.autoDispose<Reprodutor>((ref) {
  final arquivos = ref.watch(arquivosDeAmostraProvider);
  final dio = AppConfig.apiConfigurada ? ref.watch(dioProvider) : null;
  final reprodutor = ReprodutorAudioplayers(
    // No navegador (US42), a gravação está no banco local.
    lerDoNavegador: arquivos is ArquivosDeAmostraNoNavegador
        ? arquivos.lerTudo
        : null,
    // A gravação feita em outro aparelho vem da API, com o token (US40).
    baixarDaApi: dio == null ? null : (rota) => baixarAudioDaApi(dio, rota),
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
  ReprodutorAudioplayers({this.lerDoNavegador, this.baixarDaApi}) {
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

  /// O WAV de uma gravação que só está no servidor ([prefixoDaApi]). Nulo no
  /// modo de exemplo, sem API.
  final Future<Uint8List> Function(String rota)? baixarDaApi;

  /// A cópia temporária da gravação baixada, no aparelho: sai quando outra
  /// gravação abre ou o reprodutor fecha. É voz de paciente; não fica.
  File? _baixada;

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
    await _apagarBaixada();
    if (caminho.startsWith(prefixoDaApi)) {
      final baixar = baixarDaApi;
      if (baixar == null) throw StateError('Sem API para buscar a gravação.');
      final wav = await baixar(caminho.substring(prefixoDaApi.length));
      if (kIsWeb) {
        await _player.setSourceBytes(wav, mimeType: 'audio/wav');
      } else {
        // O reprodutor do Windows não toca bytes da memória: vai por um
        // arquivo temporário, que sai com a próxima gravação ou no fechar.
        final arquivo = await _arquivoTemporario();
        await arquivo.writeAsBytes(wav, flush: true);
        _baixada = arquivo;
        await _player.setSourceDeviceFile(arquivo.path);
      }
    } else if (lerDoNavegador case final ler?) {
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
    await _apagarBaixada();
  }

  Future<File> _arquivoTemporario() async {
    final pasta = await pastaDasGravacoesBaixadas();
    await pasta.create(recursive: true);
    return File(
      '${pasta.path}${Platform.pathSeparator}'
      '${DateTime.now().microsecondsSinceEpoch}.wav',
    );
  }

  Future<void> _apagarBaixada() async {
    final arquivo = _baixada;
    _baixada = null;
    try {
      if (arquivo != null && await arquivo.exists()) await arquivo.delete();
    } catch (_) {
      // Em uso: a limpeza da abertura seguinte apaga.
    }
  }
}

/// O WAV de [rota] na API, com o token da sessão. Lança só `AppException`.
Future<Uint8List> baixarAudioDaApi(Dio dio, String rota) async {
  try {
    final resposta = await dio.get<List<int>>(
      rota,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resposta.data ?? const []);
  } on DioException catch (e) {
    final falha = e.error;
    throw falha is AppException ? falha : FalhaDesconhecida(causa: e);
  }
}

/// Onde ficam, por instantes, as gravações baixadas para ouvir.
Future<Directory> pastaDasGravacoesBaixadas() async => Directory(
  '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}'
  'fonar-ouvir',
);

/// Apaga as gravações baixadas que ficaram de uma abertura anterior (o app
/// fechado no meio da reprodução). Roda na abertura; nunca falha.
Future<void> limparGravacoesBaixadas() async {
  if (kIsWeb) return;
  try {
    final pasta = await pastaDasGravacoesBaixadas();
    if (await pasta.exists()) await pasta.delete(recursive: true);
  } catch (_) {
    // Fica para a próxima abertura.
  }
}
