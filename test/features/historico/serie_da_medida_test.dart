import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/historico/data/limiares_de_mudanca_indefinidos.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/historico/domain/serie_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_placeholder.dart';

ResultadoDaAnalise _sessao(
  String id,
  DateTime? em, {
  double? avqi,
  SituacaoDaAnalise situacao = SituacaoDaAnalise.concluida,
}) => ResultadoDaAnalise(
  id: id,
  pacienteId: 'p1',
  situacao: situacao,
  realizadaEm: em,
  medidas: [
    if (avqi != null) MedidaCalculada(medida: MedidaAcustica.avqi, valor: avqi),
  ],
);

PontoDaSerie _ponto(String id, int dia, double? valor) => PontoDaSerie(
  analiseId: id,
  realizadaEm: DateTime(2026, 7, dia),
  valor: valor,
);

void main() {
  group('sessoesAnalisadas', () {
    test('só concluídas e com data, da mais antiga para a mais recente', () {
      final sessoes = sessoesAnalisadas([
        _sessao('c', DateTime(2026, 7, 20), avqi: 3),
        _sessao(
          'processando',
          DateTime(2026, 7, 25),
          situacao: SituacaoDaAnalise.processando,
        ),
        _sessao(
          'falhou',
          DateTime(2026, 7, 22),
          situacao: SituacaoDaAnalise.falhou,
        ),
        _sessao('sem-data', null, avqi: 3),
        _sessao('a', DateTime(2026, 6, 1), avqi: 4),
      ]);
      expect(sessoes.map((s) => s.id), ['a', 'c']);
    });
  });

  group('serieDe', () {
    test('medida que o servidor não mandou vira ponto sem valor, não zero', () {
      final serie = serieDe(MedidaAcustica.avqi, [
        _sessao('b', DateTime(2026, 7, 2)),
        _sessao('a', DateTime(2026, 6, 2), avqi: 4.1),
      ]);
      expect(serie.map((p) => p.analiseId), ['a', 'b']);
      expect(serie.map((p) => p.valor), [4.1, null]);
    });
  });

  group('compararUltimas', () {
    test('menos de dois valores: nada a comparar', () {
      expect(compararUltimas([], limiar: 0.1), isNull);
      expect(compararUltimas([_ponto('a', 1, 3)], limiar: 0.1), isNull);
      expect(
        compararUltimas([_ponto('a', 1, 3), _ponto('b', 2, null)], limiar: 0.1),
        isNull,
      );
    });

    test('pula a sessão sem valor — e diz quais foram comparadas', () {
      final c = compararUltimas([
        _ponto('a', 1, 4),
        _ponto('b', 2, 3.5),
        _ponto('c', 3, null),
      ], limiar: 0.1)!;
      expect(c.anterior.analiseId, 'a');
      expect(c.atual.analiseId, 'b');
      expect(c.direcao, DirecaoDaMedida.desceu);
    });

    test('sem limiar os valores vêm, a direção não', () {
      final c = compararUltimas([
        _ponto('a', 1, 4),
        _ponto('b', 2, 3),
      ], limiar: null)!;
      expect(c.atual.valor, 3);
      expect(c.direcao, DirecaoDaMedida.semComparacao);
    });
  });

  group('direcaoEntre', () {
    test('diferença menor que o limiar é estável', () {
      expect(direcaoEntre(3.12, 3.2, limiar: 0.1), DirecaoDaMedida.estavel);
      expect(direcaoEntre(3.2, 3.12, limiar: 0.1), DirecaoDaMedida.estavel);
    });

    test('do limiar para cima, mudou', () {
      expect(direcaoEntre(3, 3.5, limiar: 0.5), DirecaoDaMedida.subiu);
      expect(direcaoEntre(3.5, 3, limiar: 0.5), DirecaoDaMedida.desceu);
    });
  });

  test('nenhum limiar de mudança inventado', () {
    // Regra do CLAUDE.md, a mesma das faixas: sem valor validado, não há
    // valor. Quando os limiares chegarem, este teste muda junto — de
    // propósito.
    for (final m in MedidaAcustica.values) {
      expect(const LimiaresDeMudancaIndefinidos().limiar(m), isNull);
    }
  });

  group('histórico de exemplo', () {
    const repositorio = RepositorioAnalisesPlaceholder();

    test('bate com a lista: última sessão e direção do AVQI', () async {
      final pacientes = await RepositorioPacientesPlaceholder().listar();
      for (final paciente in pacientes) {
        final sessoes = sessoesAnalisadas(
          await repositorio.doPaciente(paciente.id),
        );
        expect(sessoes, isNotEmpty, reason: paciente.id);
        expect(sessoes.every((s) => s.exemplo), isTrue, reason: paciente.id);

        final ultima = sessoes.last.realizadaEm!;
        expect(
          DateTime(ultima.year, ultima.month, ultima.day),
          paciente.ultimaSessao,
          reason: paciente.id,
        );

        // Com qualquer limiar pequeno, a direção é a que a lista mostra.
        final c = compararUltimas(
          serieDe(MedidaAcustica.avqi, sessoes),
          limiar: 0.1,
        );
        expect(
          c?.direcao ?? DirecaoDaMedida.semComparacao,
          paciente.direcaoAvqi,
          reason: paciente.id,
        );
      }
    });

    test('paciente cadastrado no aparelho não tem análise', () async {
      expect(await repositorio.doPaciente('local-1'), isEmpty);
    });

    test('buscar acha a sessão do histórico pelo id', () async {
      final sessao = await repositorio.buscar('exemplo-d-2');
      expect(sessao.pacienteId, 'exemplo-d');
      expect(
        sessao.medidas.firstWhere((m) => m.medida == MedidaAcustica.f0).valor,
        isNull,
      );
    });
  });
}
