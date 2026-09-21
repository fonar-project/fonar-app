// A regra que este arquivo protege: o significado da variação está na MEDIDA,
// não na direção. Subir é melhorar no CPPS e piorar no AVQI, e nenhuma seta
// consegue dizer as duas coisas.

import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/features/historico/domain/evolucao_da_medida.dart';

void main() {
  group('lerEvolucao', () {
    test('AVQI caindo é melhora — menor é melhor', () {
      expect(
        lerEvolucao(
          medida: MedidaAcustica.avqi,
          direcao: DirecaoDaMedida.desceu,
        ),
        LeituraDaEvolucao.melhora,
      );
    });

    test('AVQI subindo é piora', () {
      expect(
        lerEvolucao(
          medida: MedidaAcustica.avqi,
          direcao: DirecaoDaMedida.subiu,
        ),
        LeituraDaEvolucao.piora,
      );
    });

    test('CPPS subindo é melhora — maior é melhor', () {
      expect(
        lerEvolucao(
          medida: MedidaAcustica.cpps,
          direcao: DirecaoDaMedida.subiu,
        ),
        LeituraDaEvolucao.melhora,
      );
    });

    test('CPPS caindo é piora', () {
      expect(
        lerEvolucao(
          medida: MedidaAcustica.cpps,
          direcao: DirecaoDaMedida.desceu,
        ),
        LeituraDaEvolucao.piora,
      );
    });

    test('a mesma direção dá leituras opostas em AVQI e CPPS', () {
      // O defeito em uma linha: se algum dia as duas derem a mesma leitura
      // para a mesma direção, o sentido de melhora voltou a ser ignorado.
      for (final direcao in [DirecaoDaMedida.subiu, DirecaoDaMedida.desceu]) {
        expect(
          lerEvolucao(medida: MedidaAcustica.avqi, direcao: direcao),
          isNot(lerEvolucao(medida: MedidaAcustica.cpps, direcao: direcao)),
          reason: 'direção $direcao',
        );
      }
    });

    test('estável é estável em qualquer medida', () {
      // Inclusive na f0: "não mudou" é um fato sobre o número, não uma
      // afirmação de que está melhor ou pior.
      for (final medida in MedidaAcustica.values) {
        expect(
          lerEvolucao(medida: medida, direcao: DirecaoDaMedida.estavel),
          LeituraDaEvolucao.estavel,
          reason: medida.name,
        );
      }
    });

    test('sem sessão anterior não há leitura, em nenhuma medida', () {
      // Mesmo princípio de "faixa de referência indisponível": sem base para
      // comparar, o sistema não classifica.
      for (final medida in MedidaAcustica.values) {
        expect(
          lerEvolucao(medida: medida, direcao: DirecaoDaMedida.semComparacao),
          LeituraDaEvolucao.semLeitura,
          reason: medida.name,
        );
      }
    });

    test('f0 que varia não recebe leitura de melhora nem de piora', () {
      // Subir a frequência fundamental não é bom nem ruim por si só — ela é
      // comparada à faixa esperada para o perfil, não à sessão anterior.
      for (final direcao in [
        DirecaoDaMedida.subiu,
        DirecaoDaMedida.desceu,
        DirecaoDaMedida.semComparacao,
      ]) {
        expect(
          lerEvolucao(medida: MedidaAcustica.f0, direcao: direcao),
          LeituraDaEvolucao.semLeitura,
          reason: direcao.name,
        );
      }
    });
  });

  group('sentido de melhora das medidas', () {
    test('índices de perturbação melhoram caindo', () {
      for (final medida in [
        MedidaAcustica.avqi,
        MedidaAcustica.jitter,
        MedidaAcustica.shimmer,
      ]) {
        expect(
          medida.sentidoDeMelhora,
          SentidoDeMelhora.menorEhMelhor,
          reason: medida.name,
        );
      }
    });

    test('medidas de qualidade do sinal melhoram subindo', () {
      for (final medida in [MedidaAcustica.cpps, MedidaAcustica.hnr]) {
        expect(
          medida.sentidoDeMelhora,
          SentidoDeMelhora.maiorEhMelhor,
          reason: medida.name,
        );
      }
    });
  });
}
