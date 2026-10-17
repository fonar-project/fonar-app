import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/navegador/navegador.dart';
import '../domain/ajuste_de_configuracao.dart';
import '../domain/amostra.dart';
import '../domain/gravador.dart';
import 'arquivos_de_amostra_no_navegador.dart';
import 'configuracao_de_captura.dart';

/// Um gravador novo a cada tela; sair dela descarta o que estiver no meio.
final gravadorProvider = Provider.autoDispose<Gravador>((ref) {
  final arquivos = ref.watch(arquivosDeAmostraProvider);
  final gravador = GravadorRecord(
    // No navegador o `record` não escreve arquivo: entrega um endereço
    // `blob:` com o WAV, e é daqui que ele vai para o banco local.
    guardarSaida: arquivos is ArquivosDeAmostraNoNavegador
        ? (caminho, saida) async =>
              arquivos.guardar(caminho, await lerEnderecoTemporario(saida))
        : null,
  );
  // Sair no meio de uma gravação não pode deixar o microfone aberto nem um
  // arquivo pela metade para trás — nem deixar o gravador ser reaberto por
  // uma inicialização que termine depois.
  ref.onDispose(gravador.encerrar);
  return gravador;
});

/// No aparelho, arquivos na área privada do app; no navegador (US42), o
/// banco local.
final arquivosDeAmostraProvider = Provider<ArquivosDeAmostra>(
  (ref) => kIsWeb
      ? ArquivosDeAmostraNoNavegador(ref.watch(bancoLocalProvider))
      : const ArquivosDeAmostraLocais(),
);

/// Na abertura do app, os WAV que nenhum registro aponta saem (US39) — ver
/// [apagarWavsSemRegistro]. Quem acorda é o `FonarApp`.
final limpezaDeWavSemRegistroProvider = FutureProvider<int>((ref) async {
  try {
    final banco = ref.read(bancoLocalProvider);
    final registrados = {
      for (final a in await banco.select(banco.amostras).get()) a.caminho,
    };
    final arquivos = ref.read(arquivosDeAmostraProvider);
    if (arquivos is ArquivosDeAmostraNoNavegador) {
      return await arquivos.apagarSemRegistro(registrados);
    }
    return await apagarWavsSemRegistro(registrados);
  } catch (_) {
    // Limpar é cuidado, não condição para abrir: fica para a próxima vez.
    return 0;
  }
});

/// Chave de comparação entre o caminho que o registro guarda e o que a
/// listagem da pasta devolve.
///
/// O mesmo arquivo pode estar escrito de duas formas: o banco guarda o
/// caminho como quem gravou o escreveu, e [Directory.list] devolve sempre o
/// separador da plataforma. No Windows as duas diferenças possíveis são o
/// separador (`/` no lugar de `\`) e a caixa, que o sistema de arquivos
/// ignora. Comparar a string crua faz um WAV registrado passar por órfão —
/// e voz de paciente some.
///
/// A normalização só erra para o lado seguro: dois caminhos que viram a
/// mesma chave fazem o arquivo ser POUPADO, nunca apagado.
///
/// O `Platform.isWindows` aqui não decide LAYOUT — decide semântica de
/// sistema de arquivos, que é mesmo diferente entre os sistemas. A regra
/// do projeto que proíbe `Platform.is*` vale para a interface, e segue
/// valendo. O parâmetro [windows] existe para o teste provar os dois
/// comportamentos em qualquer máquina.
@visibleForTesting
String chaveDeCaminho(String caminho, {bool? windows}) {
  if (!(windows ?? Platform.isWindows)) return caminho;
  return caminho.replaceAll('/', r'\').toLowerCase();
}

/// Apaga da pasta de amostras os WAV que nenhum registro aponta, e devolve
/// quantos.
///
/// Sobram de uma regravação ou de um descarte em que apagar o arquivo
/// falhou, ou de uma gravação que o sistema interrompeu antes de virar
/// amostra. É voz de paciente sem ninguém que saiba dela: sai.
///
/// Só os com mais de [idadeMinima]: um WAV sendo gravado agora ainda não
/// tem registro.
Future<int> apagarWavsSemRegistro(
  Set<String> registrados, {
  Directory? pasta,
  DateTime? agora,
  Duration idadeMinima = const Duration(minutes: 10),
}) async {
  final raiz =
      pasta ??
      Directory(
        '${(await getApplicationSupportDirectory()).path}'
        '${Platform.pathSeparator}amostras',
      );
  if (!await raiz.exists()) return 0;
  final limite = (agora ?? DateTime.now()).subtract(idadeMinima);
  final registradosPorChave = {
    for (final caminho in registrados) chaveDeCaminho(caminho),
  };
  var apagados = 0;
  await for (final item in raiz.list(recursive: true, followLinks: false)) {
    if (item is! File || !item.path.toLowerCase().endsWith('.wav')) continue;
    if (registradosPorChave.contains(chaveDeCaminho(item.path))) continue;
    try {
      if ((await item.lastModified()).isAfter(limite)) continue;
      await item.delete();
      apagados++;
    } catch (_) {
      // Em uso ou sem permissão: a próxima abertura tenta de novo.
    }
  }
  return apagados;
}

/// Grava pelo pacote `record`, em WAV PCM, com a configuração de
/// [ConfiguracaoDeCaptura].
///
/// NÃO VERIFICADO EM APARELHO REAL — mesma ressalva da aferição. O que sai
/// daqui não é confiado: o controlador lê o arquivo de volta e confere o
/// cabeçalho (`VerificacaoDaAmostra.verificar`).
class GravadorRecord implements Gravador {
  GravadorRecord({this.guardarSaida});

  /// Quem guarda o que o `record` entregou ao parar, quando ele não escreve
  /// o arquivo sozinho — no navegador, um endereço `blob:` (US42). Nulo no
  /// aparelho, onde o WAV já está no caminho pedido quando o `stop` volta.
  ///
  /// [parar] só volta depois de guardar: quem para em seguida lê o caminho
  /// para conferir o que saiu.
  final Future<void> Function(String caminho, String saida)? guardarSaida;

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
    await gravador.setOnConfigChanged(
      (usada) => _ajuste = ConfiguracaoDeCaptura.ajusteDe(usada),
    );
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
    final caminho = _caminho;
    _caminho = null;
    // O ajuste NÃO é limpo aqui: quem acabou de parar é justamente quem vai
    // conferir o que saiu.
    final saida = await _gravador?.stop();
    final guardar = guardarSaida;
    if (guardar != null && caminho != null && saida != null) {
      await guardar(caminho, saida);
    }
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
/// Decisão (US44): o WAV não é cifrado no aparelho — ele fica aqui só até
/// subir. Chegou ao servidor, sai (`FilaControlador`), e ouvir de novo vem
/// da API; o que fica é o registro, no banco, que é cifrado. Entre a
/// gravação e o envio, a área privada do app o separa dos outros
/// aplicativos. Cifrar o arquivo também exigiria decifrá-lo para conferir,
/// enviar e tocar, e a cópia decifrada é justamente o que não se quer no
/// disco; o mínimo necessário (LGPD, art. 6º, III) protege mais.
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
