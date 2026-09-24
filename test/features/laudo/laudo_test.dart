import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/analise/data/catalogo_de_referencias_vazio.dart';
import 'package:fonar_app/features/analise/domain/faixa_de_referencia.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/laudo/domain/conteudo_do_laudo.dart';
import 'package:fonar_app/features/laudo/domain/laudo.dart';
import 'package:fonar_app/features/laudo/presentation/pdf_do_laudo.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';

ResultadoDaAnalise _resultado({
  SituacaoDaAnalise situacao = SituacaoDaAnalise.concluida,
  bool amostraRuim = false,
  bool exemplo = false,
}) => ResultadoDaAnalise(
  id: 'an-1',
  pacienteId: 'p1',
  situacao: situacao,
  realizadaEm: DateTime(2026, 7, 2, 9, 30),
  exemplo: exemplo,
  medidas: const [
    MedidaCalculada(medida: MedidaAcustica.avqi, valor: 3.12),
    MedidaCalculada(medida: MedidaAcustica.cpps, valor: 12.4),
    MedidaCalculada(medida: MedidaAcustica.f0, valor: null),
  ],
  qualidade: {
    TarefaDeGravacao.vogalSustentada: const QualidadeDaAmostra(adequada: true),
    TarefaDeGravacao.falaEncadeada: QualidadeDaAmostra(
      adequada: !amostraRuim,
      motivo: amostraRuim ? 'Ruído de fundo (teste).' : null,
    ),
  },
);

final _capeV = AvaliacaoCapeV(
  analiseId: 'an-1',
  pacienteId: 'p1',
  registradaEm: DateTime(2026, 7, 2, 10),
  comentarios: 'Comentário de teste.',
  notas: {
    for (final p in ParametroCapeV.values) p: const NotaCapeV(valor: 0),
    ParametroCapeV.pitch: const NotaCapeV(
      valor: 30,
      consistencia: Consistencia.intermitente,
      direcao: DirecaoDoDesvio.abaixo,
    ),
  },
);

/// Faixa de TESTE, sem valor clínico nenhum.
class _Catalogo implements CatalogoDeReferencias {
  @override
  FaixaDeReferencia? faixa(MedidaAcustica medida, PerfilDeReferencia perfil) =>
      medida == MedidaAcustica.avqi
      ? const FaixaDeReferencia(maximo: 3, procedencia: 'Fonte de teste')
      : null;
}

final _paciente = Paciente(
  id: 'p1',
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
  sexo: SexoDeReferencia.feminino,
  dataDeNascimento: DateTime(1985, 7, 2),
);

const _profissional = Profissional(nome: 'Fon. Teste', registro: 'CRFa teste');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('conferirLaudo', () {
    test('tudo certo: pode gerar', () {
      final c = conferirLaudo(
        temConsentimento: true,
        resultado: _resultado(),
        capeV: _capeV,
        conclusao: 'Texto do profissional.',
      );
      expect(c.itens.values.toSet(), {SituacaoDoItem.ok});
      expect(c.podeGerar, isTrue);
    });

    test('conclusão em branco impede — espaço não conta', () {
      final c = conferirLaudo(
        temConsentimento: true,
        resultado: _resultado(),
        capeV: _capeV,
        conclusao: '   \n ',
      );
      expect(c.itens[ItemDaConferencia.conclusao], SituacaoDoItem.pendente);
      expect(c.podeGerar, isFalse);
    });

    test('sem consentimento ou com análise em curso, não gera', () {
      expect(
        conferirLaudo(
          temConsentimento: false,
          resultado: _resultado(),
          capeV: _capeV,
          conclusao: 'x',
        ).podeGerar,
        isFalse,
      );
      expect(
        conferirLaudo(
          temConsentimento: true,
          resultado: _resultado(situacao: SituacaoDaAnalise.processando),
          capeV: _capeV,
          conclusao: 'x',
        ).podeGerar,
        isFalse,
      );
    });

    test('sem CAPE-V e com amostra ruim: avisa, mas gera', () {
      final c = conferirLaudo(
        temConsentimento: true,
        resultado: _resultado(amostraRuim: true),
        capeV: null,
        conclusao: 'x',
      );
      expect(c.itens[ItemDaConferencia.capeV], SituacaoDoItem.aviso);
      expect(
        c.itens[ItemDaConferencia.qualidadeDasAmostras],
        SituacaoDoItem.aviso,
      );
      expect(c.podeGerar, isTrue);
    });
  });

  group('montarConteudo', () {
    test('classifica com o perfil na data da gravação e apara a conclusão', () {
      final c = montarConteudo(
        resultado: _resultado(),
        paciente: _paciente,
        capeV: _capeV,
        conclusao: '  Texto.  ',
        profissional: _profissional,
        catalogo: _Catalogo(),
        geradoEm: null,
      );
      expect(c.conclusao, 'Texto.');
      expect(c.rascunho, isTrue);
      expect(
        c.medidas.firstWhere((m) => m.medida == MedidaAcustica.avqi).faixa,
        isNotNull,
      );
    });

    test('análise de outro paciente não vira laudo', () {
      // Achado da revisão de 23/09: o laudo juntava o cadastro de um paciente
      // com as medidas de outro.
      expect(
        () => montarConteudo(
          resultado: _resultado(),
          paciente: Paciente(
            id: 'outro-paciente',
            nome: 'Outra Pessoa',
            queixa: 'x',
            direcaoAvqi: DirecaoDaMedida.semComparacao,
          ),
          capeV: null,
          conclusao: 'x',
          profissional: _profissional,
          catalogo: const CatalogoDeReferenciasVazio(),
          geradoEm: null,
        ),
        throwsA(isA<AnaliseDeOutroPaciente>()),
      );
    });

    test('o laudo leva o nome do cadastro', () {
      final c = montarConteudo(
        resultado: _resultado(),
        paciente: _paciente,
        capeV: null,
        conclusao: 'x',
        profissional: _profissional,
        catalogo: const CatalogoDeReferenciasVazio(),
        geradoEm: null,
      );
      expect(c.pacienteId, 'p1');
      expect(c.nomeDoPaciente, 'Ana de Teste');
    });

    test('dado de exemplo marca o documento inteiro', () {
      final c = montarConteudo(
        resultado: _resultado(exemplo: true),
        paciente: _paciente,
        capeV: null,
        conclusao: 'x',
        profissional: _profissional,
        catalogo: const CatalogoDeReferenciasVazio(),
        geradoEm: DateTime(2026, 7, 2),
      );
      expect(c.exemplo, isTrue);
      expect(c.rascunho, isFalse);
    });
  });

  group('PDF', () {
    ConteudoDoLaudo conteudo({
      AvaliacaoCapeV? capeV,
      String conclusao = 'Conclusão de teste.',
      Paciente? paciente,
      bool exemplo = false,
    }) => montarConteudo(
      resultado: _resultado(amostraRuim: true, exemplo: exemplo),
      // Sem sexo nem nascimento: o cadastro mínimo.
      paciente:
          paciente ??
          const Paciente(
            id: 'p1',
            nome: 'Ana de Teste',
            queixa: 'rouquidão',
            direcaoAvqi: DirecaoDaMedida.semComparacao,
          ),
      capeV: capeV,
      conclusao: conclusao,
      profissional: _profissional,
      catalogo: _Catalogo(),
      geradoEm: DateTime(2026, 7, 2, 11),
    );

    bool ehPdf(List<int> bytes) =>
        ascii.decode(bytes.take(5).toList()) == '%PDF-';

    test('completo, com faixa, CAPE-V e amostra com problema', () async {
      final pdf = await gerarPdfDoLaudo(
        conteudo(capeV: _capeV, paciente: _paciente),
      );
      expect(ehPdf(pdf), isTrue);
    });

    test('mínimo: sem cadastro completo, sem CAPE-V, de exemplo', () async {
      final pdf = await gerarPdfDoLaudo(conteudo(exemplo: true));
      expect(ehPdf(pdf), isTrue);
    });

    test('conclusão longa passa de página sem erro', () async {
      final longa = List.filled(
        40,
        'Parágrafo de teste com texto suficiente para ocupar algumas linhas '
        'da página e forçar a quebra do documento.',
      ).join('\n\n');
      final pdf = await gerarPdfDoLaudo(conteudo(conclusao: longa));
      expect(ehPdf(pdf), isTrue);
      // Mais de uma página no documento.
      expect(
        RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(pdf)).length,
        greaterThan(1),
      );
    });
  });
}
