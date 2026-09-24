import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/captura/domain/afericao_de_ruido.dart';
import 'package:fonar_app/features/captura/domain/nivel_de_audio.dart';

/// 50 leituras de ruído de sala: oscilam em volta de [base].
List<double> _sala(double base) => [
  for (var i = 0; i < 50; i++) base + (i % 5) - 2,
];

void main() {
  group('zonaDe', () {
    test('cada faixa cai na sua zona', () {
      expect(zonaDe(-120), ZonaDeNivel.semSinal);
      expect(zonaDe(-55), ZonaDeNivel.baixo);
      expect(zonaDe(-20), ZonaDeNivel.adequado);
      expect(zonaDe(-6), ZonaDeNivel.alto);
      expect(zonaDe(-0.5), ZonaDeNivel.saturando);
      expect(zonaDe(0), ZonaDeNivel.saturando);
    });

    test('leitura não finita é sem sinal, nunca saturação', () {
      // No Windows, amostras todas zeradas viram 20·log10(0) = −∞.
      expect(zonaDe(double.negativeInfinity), ZonaDeNivel.semSinal);
      expect(zonaDe(double.nan), ZonaDeNivel.semSinal);
      expect(zonaDe(-160), ZonaDeNivel.semSinal);
    });
  });

  group('fracaoDoMedidor', () {
    test('vai de vazio a cheio entre o mínimo do medidor e 0 dBFS', () {
      expect(fracaoDoMedidor(LimitesDeNivel.minimoDoMedidor), 0);
      expect(fracaoDoMedidor(-30), closeTo(0.5, 1e-9));
      expect(fracaoDoMedidor(0), 1);
      expect(fracaoDoMedidor(-120), 0);
      expect(fracaoDoMedidor(double.negativeInfinity), 0);
    });
  });

  group('AfericaoDeRuido.concluir', () {
    test('sala silenciosa de verdade não restringe', () {
      final r = AfericaoDeRuido.concluir(_sala(-65));

      expect(r.conclusao, ConclusaoDaAfericao.semRestricao);
      expect(r.nivelTipico, closeTo(-65, 2));
    });

    test('sala barulhenta avisa, com o nível típico', () {
      final r = AfericaoDeRuido.concluir(_sala(-40));

      expect(r.conclusao, ConclusaoDaAfericao.ruidoAlto);
      expect(r.nivelTipico, closeTo(-40, 2));
    });

    // O risco documentado em microphone_permission.dart: microfone bloqueado
    // grava silêncio sem erro. Silêncio absoluto é falha, não sala quieta.
    for (final (motivo, leituras) in [
      (
        'menos infinito (Windows, amostras zeradas)',
        [for (var i = 0; i < 50; i++) double.negativeInfinity],
      ),
      ('−160 dBFS parado', [for (var i = 0; i < 50; i++) -160.0]),
      (
        'zero fixo (plataforma sem suporte a amplitude)',
        [for (var i = 0; i < 50; i++) 0.0],
      ),
      (
        'qualquer valor fixo, sem oscilar',
        [for (var i = 0; i < 50; i++) -70.0],
      ),
      ('nenhuma leitura', <double>[]),
      ('leituras válidas de menos', _sala(-65).take(5).toList()),
    ]) {
      test('microfone mudo: $motivo', () {
        expect(
          AfericaoDeRuido.concluir(leituras).conclusao,
          ConclusaoDaAfericao.microfoneMudo,
        );
      });
    }

    test('silêncio só no começo, antes do primeiro trecho, não é mudo', () {
      final leituras = [for (var i = 0; i < 3; i++) -160.0, ..._sala(-65)];

      expect(
        AfericaoDeRuido.concluir(leituras).conclusao,
        ConclusaoDaAfericao.semRestricao,
      );
    });
  });
}
