import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';

void main() {
  late Directory pasta;
  final agora = DateTime(2026, 10, 13, 20);
  final sep = Platform.pathSeparator;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('fonar-amostras-');
    addTearDown(() => pasta.delete(recursive: true));
  });

  // O separador é o da plataforma, como em produção e como a listagem da
  // pasta devolve. Montar com '/' no Windows gera um caminho misturado que
  // não existe em lugar nenhum do app.
  File wav(String nome, {Duration idade = const Duration(hours: 1)}) {
    final arquivo = File('${pasta.path}${sep}p1$sep$nome')
      ..createSync(recursive: true)
      ..writeAsStringSync('RIFF');
    arquivo.setLastModifiedSync(agora.subtract(idade));
    return arquivo;
  }

  test('apaga o WAV que nenhum registro aponta, e só ele', () async {
    final registrado = wav('vogal-1.wav');
    final orfao = wav('fala-velha.wav');
    final outroArquivo = File('${pasta.path}${sep}p1${sep}anotacao.txt')
      ..writeAsStringSync('x');

    final apagados = await apagarWavsSemRegistro(
      {registrado.path},
      pasta: pasta,
      agora: agora,
    );

    expect(apagados, 1);
    expect(registrado.existsSync(), isTrue);
    expect(orfao.existsSync(), isFalse);
    expect(outroArquivo.existsSync(), isTrue);
  });

  test('o recém-gravado ainda não tem registro, e fica', () async {
    final gravandoAgora = wav(
      'vogal-agora.wav',
      idade: const Duration(minutes: 1),
    );

    expect(
      await apagarWavsSemRegistro(const {}, pasta: pasta, agora: agora),
      0,
    );
    expect(gravandoAgora.existsSync(), isTrue);
  });

  test('sem a pasta, nada a fazer', () async {
    expect(
      await apagarWavsSemRegistro(
        const {},
        pasta: Directory('${pasta.path}${sep}nao-existe'),
        agora: agora,
      ),
      0,
    );
  });

  test(
    'o registro escrito de outro jeito ainda aponta o mesmo arquivo',
    () async {
      final registrado = wav('vogal-1.wav');
      // Como o caminho poderia ter sido gravado no banco por outro trecho
      // do app: barra normal e outra caixa. No Windows é o MESMO arquivo.
      final outraGrafia = registrado.path.replaceAll(r'\', '/').toUpperCase();

      final apagados = await apagarWavsSemRegistro(
        {outraGrafia},
        pasta: pasta,
        agora: agora,
      );

      expect(apagados, 0, reason: 'voz de paciente registrada não se apaga');
      expect(registrado.existsSync(), isTrue);
    },
    skip: Platform.isWindows
        ? null
        : 'separador e caixa só se equivalem no Windows',
  );

  group('chaveDeCaminho', () {
    test('no Windows, barra e caixa não separam dois caminhos', () {
      expect(
        chaveDeCaminho(r'C:\Amostras\P1\Vogal-1.WAV', windows: true),
        chaveDeCaminho('C:/amostras/p1/vogal-1.wav', windows: true),
      );
    });

    test('no Windows, arquivos diferentes seguem diferentes', () {
      expect(
        chaveDeCaminho(r'C:\amostras\p1\vogal-1.wav', windows: true),
        isNot(chaveDeCaminho(r'C:\amostras\p1\vogal-2.wav', windows: true)),
      );
    });

    test('fora do Windows, barra e caixa fazem parte do nome', () {
      const caminho = '/amostras/p1/Vogal.wav';
      expect(chaveDeCaminho(caminho, windows: false), caminho);
      expect(
        chaveDeCaminho('/amostras/p1/vogal.wav', windows: false),
        isNot(chaveDeCaminho(caminho, windows: false)),
      );
    });
  });
}
