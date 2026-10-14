import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/captura/data/configuracao_de_captura.dart';
import 'package:fonar_app/features/captura/domain/ajuste_de_configuracao.dart';
import 'package:fonar_app/features/captura/domain/processamento_automatico.dart';
import 'package:record/record.dart';

const _ganho = ProcessamentoAutomatico.ganhoAutomatico;
const _ruido = ProcessamentoAutomatico.supressaoDeRuido;
const _eco = ProcessamentoAutomatico.cancelamentoDeEco;

void main() {
  // US42: a trava da versão no navegador. O que conta é o que o navegador
  // RELATA da faixa de áudio, não o que foi pedido.
  group('naoConfirmadosDesligados', () {
    test('os três relatados desligados: nada bloqueia', () {
      expect(
        naoConfirmadosDesligados(ganho: false, ruido: false, eco: false),
        isEmpty,
      );
    });

    test('cada um relatado ligado bloqueia', () {
      expect(naoConfirmadosDesligados(ganho: true, ruido: false, eco: false), {
        _ganho,
      });
      expect(naoConfirmadosDesligados(ganho: false, ruido: true, eco: false), {
        _ruido,
      });
      expect(naoConfirmadosDesligados(ganho: false, ruido: false, eco: true), {
        _eco,
      });
    });

    test('cancelamento de eco não relatado é falta de evidência: bloqueia', () {
      expect(naoConfirmadosDesligados(ganho: false, ruido: false, eco: null), {
        _eco,
      });
      expect(naoConfirmadosDesligados(ganho: null, ruido: null, eco: null), {
        _eco,
      });
    });

    // O Safari relata só o cancelamento de eco: ganho e supressão fazem
    // parte do mesmo processamento de voz que ele liga e desliga.
    test('como o Safari relata: só o eco, desligado, libera', () {
      expect(
        naoConfirmadosDesligados(ganho: null, ruido: null, eco: false),
        isEmpty,
      );
    });
  });

  group('o aviso do record no tipo do domínio', () {
    test('o que o pacote repassa como pedido não acusa processamento', () {
      final ajuste = ConfiguracaoDeCaptura.ajusteDe(
        ConfiguracaoDeCaptura.para(ConfiguracaoDeCaptura.formatoDaGravacao)
            .copyWith(sampleRate: 48000),
      );
      expect(ajuste.taxaDeAmostragem, 48000);
      expect(ajuste.canais, 1);
      expect(ajuste.manteveProcessamento, isFalse);
    });

    test('o que o navegador relatou ligado vira processamento ligado', () {
      final ajuste = ConfiguracaoDeCaptura.ajusteDe(
        const RecordConfig(
          sampleRate: 44100,
          numChannels: 1,
          autoGain: true,
          noiseSuppress: true,
        ),
      );
      expect(ajuste.processamentoLigado, {_ganho, _ruido});
      expect(
        ajuste.confere(taxaPedida: 44100, canaisPedidos: 1),
        isTrue,
        reason: 'o formato é o pedido; só o processamento mudou',
      );
    });
  });

  group('AjusteDeConfiguracao.juntar', () {
    test('sem nada do navegador, fica o aviso do gravador', () {
      const doGravador = AjusteDeConfiguracao(
        taxaDeAmostragem: 48000,
        canais: 1,
      );
      expect(
        AjusteDeConfiguracao.juntar(
          doGravador,
          const {},
          taxaPedida: 44100,
          canaisPedidos: 1,
        ),
        same(doGravador),
      );
      expect(
        AjusteDeConfiguracao.juntar(
          null,
          const {},
          taxaPedida: 44100,
          canaisPedidos: 1,
        ),
        isNull,
      );
    });

    test('o navegador sozinho: formato pedido, processamento dele', () {
      final junto = AjusteDeConfiguracao.juntar(
        null,
        {_eco},
        taxaPedida: 44100,
        canaisPedidos: 1,
      )!;
      expect(junto.taxaDeAmostragem, 44100);
      expect(junto.canais, 1);
      expect(junto.processamentoLigado, {_eco});
    });

    test('os dois: o formato do gravador e o processamento dos dois', () {
      final junto = AjusteDeConfiguracao.juntar(
        const AjusteDeConfiguracao(
          taxaDeAmostragem: 48000,
          canais: 1,
          processamentoLigado: {_ganho},
        ),
        {_eco},
        taxaPedida: 44100,
        canaisPedidos: 1,
      )!;
      expect(junto.taxaDeAmostragem, 48000);
      expect(junto.processamentoLigado, {_ganho, _eco});
    });
  });
}
