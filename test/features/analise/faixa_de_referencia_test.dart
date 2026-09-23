import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/analise/data/catalogo_de_referencias_vazio.dart';
import 'package:fonar_app/features/analise/domain/faixa_de_referencia.dart';
import 'package:fonar_app/features/analise/domain/leitura_do_resultado.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';

// Faixas de TESTE. Os números não vêm de referência nenhuma e não valem
// para nada fora deste arquivo.
const _faixaEntre = FaixaDeReferencia(
  minimo: 100,
  maximo: 200,
  procedencia: 'teste',
);
const _faixaAte = FaixaDeReferencia(maximo: 10, procedencia: 'teste');
const _faixaAPartir = FaixaDeReferencia(minimo: 10, procedencia: 'teste');
const _comMargem = FaixaDeReferencia(
  minimo: 100,
  maximo: 200,
  margemLimitrofe: 10,
  procedencia: 'teste',
);

/// Catálogo de teste: devolve a mesma faixa para tudo, e registra o perfil
/// que recebeu.
class _Catalogo implements CatalogoDeReferencias {
  _Catalogo(this.faixaFixa);
  final FaixaDeReferencia? faixaFixa;
  PerfilDeReferencia? perfilRecebido;

  @override
  FaixaDeReferencia? faixa(MedidaAcustica medida, PerfilDeReferencia perfil) {
    perfilRecebido = perfil;
    return faixaFixa;
  }
}

ResultadoDaAnalise _resultado(List<MedidaCalculada> medidas) =>
    ResultadoDaAnalise(
      id: 'a',
      pacienteId: 'p',
      situacao: SituacaoDaAnalise.concluida,
      realizadaEm: DateTime(2026, 7, 2),
      medidas: medidas,
    );

void main() {
  group('classificar', () {
    test('dentro e fora de uma faixa com os dois limites', () {
      expect(
        classificar(150, _faixaEntre),
        ClassificacaoDaMedida.dentroDaFaixa,
      );
      expect(
        classificar(100, _faixaEntre),
        ClassificacaoDaMedida.dentroDaFaixa,
      );
      expect(
        classificar(200, _faixaEntre),
        ClassificacaoDaMedida.dentroDaFaixa,
      );
      expect(classificar(99.9, _faixaEntre), ClassificacaoDaMedida.foraDaFaixa);
      expect(
        classificar(200.1, _faixaEntre),
        ClassificacaoDaMedida.foraDaFaixa,
      );
    });

    test('faixa só com máximo ou só com mínimo', () {
      expect(classificar(9, _faixaAte), ClassificacaoDaMedida.dentroDaFaixa);
      expect(classificar(11, _faixaAte), ClassificacaoDaMedida.foraDaFaixa);
      expect(
        classificar(11, _faixaAPartir),
        ClassificacaoDaMedida.dentroDaFaixa,
      );
      expect(classificar(9, _faixaAPartir), ClassificacaoDaMedida.foraDaFaixa);
    });

    test('limítrofe só existe quando o catálogo define a margem', () {
      expect(
        classificar(105, _faixaEntre),
        ClassificacaoDaMedida.dentroDaFaixa,
      );
      expect(classificar(105, _comMargem), ClassificacaoDaMedida.limitrofe);
      expect(classificar(195, _comMargem), ClassificacaoDaMedida.limitrofe);
      expect(classificar(150, _comMargem), ClassificacaoDaMedida.dentroDaFaixa);
    });

    test('sem faixa ou sem valor: sem referência, nunca palpite', () {
      expect(classificar(150, null), ClassificacaoDaMedida.semReferencia);
      expect(
        classificar(null, _faixaEntre),
        ClassificacaoDaMedida.semReferencia,
      );
      expect(
        classificar(double.nan, _faixaEntre),
        ClassificacaoDaMedida.semReferencia,
      );
    });
  });

  group('PerfilDeReferencia.de', () {
    test('sexo e nascimento dão o perfil, com a idade na data', () {
      final p = PerfilDeReferencia.de(
        sexo: SexoDeReferencia.feminino,
        dataDeNascimento: DateTime(1985, 7, 2),
        em: DateTime(2026, 7, 1),
      )!;
      expect(p.idade, 40);
    });

    test('"não informar" ou sem nascimento não têm perfil', () {
      expect(
        PerfilDeReferencia.de(
          sexo: SexoDeReferencia.naoInformado,
          dataDeNascimento: DateTime(1985),
          em: DateTime(2026),
        ),
        isNull,
      );
      expect(
        PerfilDeReferencia.de(
          sexo: SexoDeReferencia.masculino,
          dataDeNascimento: null,
          em: DateTime(2026),
        ),
        isNull,
      );
    });
  });

  group('lerMedidas', () {
    final medidas = [
      const MedidaCalculada(medida: MedidaAcustica.f0, valor: 150),
      const MedidaCalculada(medida: MedidaAcustica.cpps, valor: null),
    ];

    test('perfil completo e faixa no catálogo: classifica', () {
      final catalogo = _Catalogo(_faixaEntre);
      final lidas = lerMedidas(
        resultado: _resultado(medidas),
        sexo: SexoDeReferencia.feminino,
        dataDeNascimento: DateTime(1985, 7, 2),
        catalogo: catalogo,
      );

      expect(lidas.first.classificacao, ClassificacaoDaMedida.dentroDaFaixa);
      expect(lidas.first.faixa, same(_faixaEntre));
      // A idade é a da gravação (2026-07-02), não a de hoje.
      expect(catalogo.perfilRecebido!.idade, 41);
    });

    test('medida não calculada diz isso, e não "sem faixa"', () {
      final lidas = lerMedidas(
        resultado: _resultado(medidas),
        sexo: SexoDeReferencia.feminino,
        dataDeNascimento: DateTime(1985, 7, 2),
        catalogo: _Catalogo(_faixaEntre),
      );

      expect(lidas.last.valor, isNull);
      expect(
        lidas.last.semClassificacaoPorque,
        SemClassificacaoPorque.naoCalculada,
      );
    });

    test('perfil incompleto: nem pergunta ao catálogo', () {
      final catalogo = _Catalogo(_faixaEntre);
      final lidas = lerMedidas(
        resultado: _resultado(medidas),
        sexo: SexoDeReferencia.naoInformado,
        dataDeNascimento: DateTime(1985),
        catalogo: catalogo,
      );

      expect(lidas.first.classificacao, ClassificacaoDaMedida.semReferencia);
      expect(
        lidas.first.semClassificacaoPorque,
        SemClassificacaoPorque.perfilIncompleto,
      );
      expect(catalogo.perfilRecebido, isNull);
    });

    test('catálogo sem faixa para o perfil: sem faixa validada', () {
      final lidas = lerMedidas(
        resultado: _resultado(medidas),
        sexo: SexoDeReferencia.masculino,
        dataDeNascimento: DateTime(1990),
        catalogo: _Catalogo(null),
      );

      expect(
        lidas.first.semClassificacaoPorque,
        SemClassificacaoPorque.semFaixaValidada,
      );
    });
  });

  test('o catálogo do aplicativo não classifica nada até ser validado', () {
    // Os valores do protótipo NÃO foram validados. Até o catálogo validado
    // existir, nenhuma faixa pode sair daqui. Se este teste quebrar, alguém
    // pôs valor de corte no código — ver "Faixas de referência" no CLAUDE.md.
    const catalogo = CatalogoDeReferenciasVazio();
    for (final medida in MedidaAcustica.values) {
      for (final sexo in [
        SexoDeReferencia.feminino,
        SexoDeReferencia.masculino,
      ]) {
        expect(
          catalogo.faixa(medida, PerfilDeReferencia(sexo: sexo, idade: 40)),
          isNull,
          reason: '$medida $sexo',
        );
      }
    }
  });
}
