import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../domain/ajuste_de_configuracao.dart';
import '../domain/amostra.dart';
import '../domain/gravador.dart';
import 'configuracao_de_captura.dart';

/// Um gravador novo a cada tela; sair dela descarta o que estiver no meio.
final gravadorProvider = Provider.autoDispose<Gravador>((ref) {
  final gravador = GravadorRecord();
  // Sair no meio de uma gravação não pode deixar o microfone aberto nem um
  // arquivo pela metade para trás — nem deixar o gravador ser reaberto por
  // uma inicialização que termine depois.
  ref.onDispose(gravador.encerrar);
  return gravador;
});

final arquivosDeAmostraProvider = Provider<ArquivosDeAmostra>(
  (ref) => const ArquivosDeAmostraLocais(),
);

/// Grava pelo pacote `record`, em WAV PCM, com a configuração de
/// [ConfiguracaoDeCaptura].
///
/// NÃO VERIFICADO EM APARELHO REAL — mesma ressalva da aferição. O que sai
/// daqui não é confiado: o controlador lê o arquivo de volta e confere o
/// cabeçalho (`VerificacaoDaAmostra.verificar`).
class GravadorRecord implements Gravador {
  GravadorRecord();

  AudioRecorder? _gravador;
  String? _caminho;
  AjusteDeConfiguracao? _ajuste;

  /// Depois de [encerrar], nada reabre o microfone por aqui.
  var _encerrado = false;

  @override
  AjusteDeConfiguracao? get ajuste => _ajuste;

  AudioRecorder get _aberto {
    if (_encerrado) throw StateError('Gravador encerrado.');
    return _gravador ??= AudioRecorder();
  }

  @override
  Future<bool> pedirPermissao() => _aberto.hasPermission();

  @override
  Future<Stream<double>> iniciar(String caminho, Duration intervalo) async {
    final gravador = _aberto;
    _caminho = caminho;
    // Registrado ANTES do `start`, senão o aviso do aparelho chega quando
    // ninguém está mais ouvindo. Até a US05 isto existia só na aferição, e a
    // gravação dependia só do cabeçalho do WAV para saber o que saiu.
    _ajuste = null;
    await gravador.setOnConfigChanged((usada) {
      _ajuste = AjusteDeConfiguracao(
        taxaDeAmostragem: usada.sampleRate,
        canais: usada.numChannels,
      );
    });
    await gravador.start(
      ConfiguracaoDeCaptura.para(ConfiguracaoDeCaptura.formatoDaGravacao),
      path: caminho,
    );
    // Encerrado durante o `start`: o `encerrar` já cancelou e liberou este
    // gravador; o que abriu não pode ser devolvido como se valesse.
    if (_encerrado) throw StateError('Gravador encerrado.');
    return gravador.onAmplitudeChanged(intervalo).map((a) => a.current);
  }

  @override
  Future<void> parar() async {
    _caminho = null;
    // O ajuste NÃO é limpo aqui: quem acabou de parar é justamente quem vai
    // conferir o que saiu.
    await _gravador?.stop();
  }

  /// Descarta e não deixa mais abrir. É o fim da vida deste gravador — o
  /// provider chama ao sair da tela.
  Future<void> encerrar() {
    _encerrado = true;
    return descartar();
  }

  @override
  Future<void> descartar() async {
    final gravador = _gravador;
    final caminho = _caminho;
    _gravador = null;
    _caminho = null;
    _ajuste = null;
    if (gravador == null) return;
    try {
      // `cancel` para e apaga o arquivo em andamento.
      if (caminho != null) await gravador.cancel();
    } finally {
      await gravador.dispose();
    }
  }
}

/// As amostras ficam em `<área privada do app>/amostras/<paciente>/`.
///
/// TODO(LGPD): o WAV fica sem criptografia na área privada. A área privada
/// protege de outros aplicativos, não de quem tem o aparelho desbloqueado ou
/// o disco do computador. Decidir se precisa cifrar em repouso.
class ArquivosDeAmostraLocais implements ArquivosDeAmostra {
  const ArquivosDeAmostraLocais();

  /// O bastante para o cabeçalho, com folga para blocos `LIST` e afins.
  static const _bytesDoCabecalho = 4096;

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao tarefa) async {
    final base = await getApplicationSupportDirectory();
    final pasta = Directory(
      '${base.path}${Platform.pathSeparator}amostras'
      '${Platform.pathSeparator}$pacienteId',
    );
    await pasta.create(recursive: true);
    final carimbo = DateTime.now().microsecondsSinceEpoch;
    return '${pasta.path}${Platform.pathSeparator}${tarefa.name}-$carimbo.wav';
  }

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async {
    final arquivo = File(caminho);
    if (!await arquivo.exists()) return null;
    final tamanho = await arquivo.length();
    final leitor = await arquivo.open();
    try {
      final inicio = await leitor.read(
        tamanho < _bytesDoCabecalho ? tamanho : _bytesDoCabecalho,
      );
      return (inicio: inicio, tamanho: tamanho);
    } finally {
      await leitor.close();
    }
  }

  @override
  Future<void> apagar(String caminho) async {
    final arquivo = File(caminho);
    if (await arquivo.exists()) await arquivo.delete();
  }
}
