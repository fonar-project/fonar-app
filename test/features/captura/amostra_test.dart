import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/captura/domain/cabecalho_wav.dart';
import 'package:fonar_app/features/captura/domain/verificacao_da_amostra.dart';

import 'wav_de_teste.dart';

/// Leituras de voz: oscilam em volta de −20 dBFS.
final _voz = [for (var i = 0; i < 30; i++) -20.0 + (i % 5)];

List<ProblemaNaAmostra> _verificar(
  Uint8List arquivo, {
  List<double>? leituras,
  int? tamanho,
}) => VerificacaoDaAmostra.verificar(
  cabecalho: lerCabecalhoWav(arquivo),
  inicioDoArquivo: arquivo,
  tamanhoDoArquivo: tamanho ?? arquivo.length,
  leituras: leituras ?? _voz,
  taxaPedida: 44100,
  canaisPedidos: 1,
  bitsPedidos: 16,
);

void main() {
  group('lerCabecalhoWav', () {
    test('lê formato, canais, taxa, bits e duração', () {
      final c = lerCabecalhoWav(
        wavDeTeste(duracao: const Duration(seconds: 3)),
      )!;

      expect(c.ehPcm, isTrue);
      expect(c.canais, 1);
      expect(c.taxaDeAmostragem, 44100);
      expect(c.bitsPorAmostra, 16);
      expect(c.duracao, const Duration(seconds: 3));
    });

    test('acha o bloco data mesmo com um LIST no meio', () {
      final c = lerCabecalhoWav(
        wavDeTeste(duracao: const Duration(seconds: 2), comList: true),
      )!;

      expect(c.duracao, const Duration(seconds: 2));
      expect(c.inicioDoAudio, greaterThan(44));
    });

    test('formato extensível com subformato PCM conta como PCM', () {
      final c = lerCabecalhoWav(
        wavDeTeste(duracao: const Duration(seconds: 1), extensivel: true),
      )!;

      expect(c.formato, CabecalhoWav.formatoExtensivel);
      expect(c.ehPcm, isTrue);
    });

    test('recusa o que não é WAV', () {
      expect(
        lerCabecalhoWav(Uint8List.fromList('ID3 mp3...'.codeUnits)),
        isNull,
      );
      expect(lerCabecalhoWav(Uint8List(0)), isNull);
    });
  });

  group('VerificacaoDaAmostra', () {
    test('WAV PCM 16 bits mono 44,1 kHz com voz passa sem ressalva', () {
      expect(
        _verificar(wavDeTeste(duracao: const Duration(seconds: 3))),
        isEmpty,
      );
    });

    test('arquivo ilegível invalida', () {
      final p = VerificacaoDaAmostra.verificar(
        cabecalho: null,
        inicioDoArquivo: null,
        tamanhoDoArquivo: 0,
        leituras: _voz,
        taxaPedida: 44100,
        canaisPedidos: 1,
        bitsPedidos: 16,
      );
      expect(p, [ProblemaNaAmostra.arquivoIlegivel]);
      expect(p.single.invalida, isTrue);
    });

    for (final (motivo, arquivo, esperado) in [
      (
        'formato comprimido',
        wavDeTeste(duracao: const Duration(seconds: 3), formato: 85),
        ProblemaNaAmostra.naoEPcm,
      ),
      (
        '24 bits',
        wavDeTeste(duracao: const Duration(seconds: 3), bits: 24),
        ProblemaNaAmostra.bitsDiferentes,
      ),
      (
        'menos de 1 segundo',
        wavDeTeste(duracao: const Duration(milliseconds: 600)),
        ProblemaNaAmostra.curtaDemais,
      ),
    ]) {
      test('invalida: $motivo', () {
        final p = _verificar(arquivo);
        expect(p, contains(esperado));
        expect(esperado.invalida, isTrue);
      });
    }

    test('curta demais não acusa microfone mudo junto', () {
      final p = _verificar(
        wavDeTeste(duracao: const Duration(milliseconds: 400)),
        leituras: _voz.take(4).toList(),
      );
      expect(p, [ProblemaNaAmostra.curtaDemais]);
    });

    test('invalida: cabeçalho promete mais áudio do que o arquivo tem', () {
      final arquivo = wavDeTeste(duracao: const Duration(seconds: 3));
      // Gravação interrompida: o arquivo acabou antes do que o cabeçalho diz.
      final p = _verificar(arquivo, tamanho: arquivo.length ~/ 2);
      expect(p, contains(ProblemaNaAmostra.incompleto));
    });

    test('invalida: o medidor não viu som durante a gravação', () {
      final p = _verificar(
        wavDeTeste(duracao: const Duration(seconds: 3)),
        leituras: [for (var i = 0; i < 30; i++) double.negativeInfinity],
      );
      expect(p, contains(ProblemaNaAmostra.semSinal));
    });

    test('saturação é ressalva, não invalida', () {
      final p = _verificar(
        wavDeTeste(duracao: const Duration(seconds: 3)),
        leituras: [..._voz, -0.1],
      );
      expect(p, [ProblemaNaAmostra.saturou]);
      expect(ProblemaNaAmostra.saturou.invalida, isFalse);
    });

    test('taxa ou canais trocados pelo aparelho é ressalva', () {
      final p = _verificar(
        wavDeTeste(duracao: const Duration(seconds: 3), taxa: 48000, canais: 2),
      );
      expect(p, [ProblemaNaAmostra.formatoAjustado]);
      expect(ProblemaNaAmostra.formatoAjustado.invalida, isFalse);
    });
  });

  // Achado 7.1 da revisão de 24/09: o silêncio era conferido só pelas
  // leituras que o PLUGIN entrega. A falha silenciosa do Windows pode
  // entregar amplitude plausível e gravar zeros.
  group('silêncio conferido no arquivo', () {
    test('invalida mesmo com o medidor vendo sinal a gravação toda', () {
      final p = _verificar(
        wavDeTeste(duracao: const Duration(seconds: 3), audioZerado: true),
        leituras: _voz,
      );

      expect(p, contains(ProblemaNaAmostra.semSinal));
      expect(ProblemaNaAmostra.semSinal.invalida, isTrue);
    });

    test('arquivo com bytes de áudio passa', () {
      expect(
        _verificar(wavDeTeste(duracao: const Duration(seconds: 3))),
        isEmpty,
      );
    });

    test('um byte diferente de zero na janela já basta para não acusar', () {
      final arquivo = wavDeTeste(
        duracao: const Duration(seconds: 3),
        audioZerado: true,
      );
      final cabecalho = lerCabecalhoWav(arquivo)!;
      arquivo[cabecalho.inicioDoAudio + 1000] = 7;

      expect(_verificar(arquivo), isEmpty);
    });

    test('janela curta demais para julgar não acusa', () {
      final arquivo = wavDeTeste(
        duracao: const Duration(seconds: 3),
        audioZerado: true,
      );
      final cabecalho = lerCabecalhoWav(arquivo)!;
      // Janela que alcança o áudio, mas com menos bytes que o mínimo: não se
      // sabe se é o driver mudo ou o primeiro buffer ainda vazio.
      final janela = Uint8List.sublistView(
        arquivo,
        0,
        cabecalho.inicioDoAudio +
            VerificacaoDaAmostra.bytesMinimosParaJulgarSilencio -
            1,
      );

      expect(VerificacaoDaAmostra.audioTodoEmZero(janela, cabecalho), isFalse);
    });

    test('janela que não alcança o áudio não acusa', () {
      final arquivo = wavDeTeste(
        duracao: const Duration(seconds: 3),
        audioZerado: true,
      );
      final cabecalho = lerCabecalhoWav(arquivo)!;
      final janela = Uint8List.sublistView(arquivo, 0, cabecalho.inicioDoAudio);

      expect(VerificacaoDaAmostra.audioTodoEmZero(janela, cabecalho), isFalse);
    });

    test('a janela de 4 KB do gravador é o bastante para acusar', () {
      final arquivo = wavDeTeste(
        duracao: const Duration(seconds: 3),
        audioZerado: true,
      );
      final cabecalho = lerCabecalhoWav(arquivo)!;
      // O mesmo tamanho que `ArquivosDeAmostraLocais` lê do disco.
      final janela = Uint8List.sublistView(arquivo, 0, 4096);

      expect(VerificacaoDaAmostra.audioTodoEmZero(janela, cabecalho), isTrue);
    });
  });
}
