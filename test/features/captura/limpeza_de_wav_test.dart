import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';

void main() {
  late Directory pasta;
  final agora = DateTime(2026, 10, 13, 20);

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('fonar-amostras-');
    addTearDown(() => pasta.delete(recursive: true));
  });

  File wav(String nome, {Duration idade = const Duration(hours: 1)}) {
    final arquivo = File('${pasta.path}/p1/$nome')
      ..createSync(recursive: true)
      ..writeAsStringSync('RIFF');
    arquivo.setLastModifiedSync(agora.subtract(idade));
    return arquivo;
  }

  test('apaga o WAV que nenhum registro aponta, e só ele', () async {
    final registrado = wav('vogal-1.wav');
    final orfao = wav('fala-velha.wav');
    final outroArquivo = File('${pasta.path}/p1/anotacao.txt')
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
        pasta: Directory('${pasta.path}/nao-existe'),
        agora: agora,
      ),
      0,
    );
  });
}
