import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/features/captura/data/arquivos_de_amostra_no_navegador.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';

import '../../apoio/banco_em_memoria.dart';
import 'wav_de_teste.dart';

void main() {
  // US42: no navegador não há pasta de arquivos, e o WAV mora no banco
  // local. O contrato é o mesmo dos arquivos do aparelho.
  late BancoLocal banco;
  late DateTime agora;
  late ArquivosDeAmostraNoNavegador arquivos;

  setUp(() {
    banco = bancoEmMemoria();
    agora = DateTime(2026, 10, 14, 9);
    arquivos = ArquivosDeAmostraNoNavegador(banco, relogio: () => agora);
  });
  tearDown(() => banco.close());

  test('o caminho tem o formato do aparelho, sem pasta de verdade', () async {
    final caminho = await arquivos.novoCaminho(
      'p1',
      TarefaDeGravacao.vogalSustentada,
    );
    expect(
      caminho,
      'amostras/p1/vogalSustentada-${agora.microsecondsSinceEpoch}.wav',
    );
  });

  test('guarda e lê o começo e o tamanho, como do disco', () async {
    final wav = wavDeTeste(duracao: const Duration(seconds: 3));
    await arquivos.guardar('amostras/p1/a.wav', wav);

    final lido = (await arquivos.ler('amostras/p1/a.wav'))!;
    expect(lido.tamanho, wav.length);
    // O mesmo tamanho que `ArquivosDeAmostraLocais` lê do disco.
    expect(lido.inicio, wav.sublist(0, 4096));
    expect(await arquivos.lerTudo('amostras/p1/a.wav'), wav);
  });

  test('arquivo pequeno vem inteiro no começo', () async {
    final wav = Uint8List.fromList(List.generate(100, (i) => i));
    await arquivos.guardar('amostras/p1/b.wav', wav);

    final lido = (await arquivos.ler('amostras/p1/b.wav'))!;
    expect(lido.inicio, wav);
    expect(lido.tamanho, 100);
  });

  test('o que não existe volta nulo, e apagar é idempotente', () async {
    expect(await arquivos.ler('amostras/p1/nada.wav'), isNull);
    expect(await arquivos.lerTudo('amostras/p1/nada.wav'), isNull);

    await arquivos.guardar('amostras/p1/c.wav', Uint8List(10));
    await arquivos.apagar('amostras/p1/c.wav');
    await arquivos.apagar('amostras/p1/c.wav');
    expect(await arquivos.ler('amostras/p1/c.wav'), isNull);
  });

  test('sem registro e antigo sai; registrado ou recente fica', () async {
    await arquivos.guardar('amostras/p1/registrado.wav', Uint8List(10));
    await arquivos.guardar('amostras/p1/orfao.wav', Uint8List(10));
    agora = agora.add(const Duration(minutes: 30));
    await arquivos.guardar('amostras/p1/recente.wav', Uint8List(10));

    final apagados = await arquivos.apagarSemRegistro({
      'amostras/p1/registrado.wav',
    });

    expect(apagados, 1);
    expect(await arquivos.ler('amostras/p1/orfao.wav'), isNull);
    expect(await arquivos.ler('amostras/p1/registrado.wav'), isNotNull);
    expect(await arquivos.ler('amostras/p1/recente.wav'), isNotNull);
  });
}
