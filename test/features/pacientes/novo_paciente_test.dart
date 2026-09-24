import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';

import '../../apoio/repositorios_em_memoria.dart';

final _hoje = DateTime(2026, 9, 23);

ResultadoDoCadastro _validar({
  String nome = 'Ana de Teste',
  String nascimento = '02/07/1985',
  SexoDeReferencia? sexo = SexoDeReferencia.feminino,
  String queixa = 'rouquidão',
}) => validarCadastro(
  nome: nome,
  nascimento: nascimento,
  sexo: sexo,
  queixa: queixa,
  hoje: _hoje,
);

CadastroInvalido _invalido(ResultadoDoCadastro r) {
  expect(r, isA<CadastroInvalido>());
  return r as CadastroInvalido;
}

void main() {
  group('validarCadastro', () {
    test('dados completos viram um NovoPaciente', () {
      final r = _validar();

      expect(r, isA<CadastroValido>());
      final p = (r as CadastroValido).paciente;
      expect(p.nome, 'Ana de Teste');
      expect(p.dataDeNascimento, DateTime(1985, 7, 2));
      expect(p.sexo, SexoDeReferencia.feminino);
      expect(p.queixa, 'rouquidão');
    });

    test('tira espaço das pontas e o espaço duplo do meio do nome', () {
      final r = _validar(nome: '  Ana   de  Teste ', queixa: '  rouquidão  ');

      final p = (r as CadastroValido).paciente;
      expect(p.nome, 'Ana de Teste');
      expect(p.queixa, 'rouquidão');
    });

    test('"Não informar" é resposta válida', () {
      expect(
        _validar(sexo: SexoDeReferencia.naoInformado),
        isA<CadastroValido>(),
      );
    });

    test('formulário vazio aponta um problema em cada campo', () {
      final r = _invalido(
        _validar(nome: ' ', nascimento: '', sexo: null, queixa: ''),
      );

      expect(r.nome, ProblemaNoCadastro.nomeVazio);
      expect(r.nascimento, ProblemaNoCadastro.nascimentoVazio);
      expect(r.sexo, ProblemaNoCadastro.sexoNaoEscolhido);
      expect(r.queixa, ProblemaNoCadastro.queixaVazia);
    });

    test('só o campo com problema é apontado', () {
      final r = _invalido(_validar(queixa: ''));

      expect(r.nome, isNull);
      expect(r.nascimento, isNull);
      expect(r.sexo, isNull);
      expect(r.queixa, ProblemaNoCadastro.queixaVazia);
    });

    for (final (texto, motivo) in [
      ('31/02/1990', 'dia que não existe no mês'),
      ('29/02/2023', '29 de fevereiro fora de ano bissexto'),
      ('00/01/1990', 'dia zero'),
      ('10/13/1990', 'mês 13'),
      ('1/7/1985', 'sem os zeros à esquerda'),
      ('02/07/85', 'ano com dois dígitos'),
      ('02/07', 'incompleta'),
    ]) {
      test('recusa data inválida: $motivo', () {
        expect(
          _invalido(_validar(nascimento: texto)).nascimento,
          ProblemaNoCadastro.nascimentoInvalido,
        );
      });
    }

    test('aceita 29 de fevereiro em ano bissexto', () {
      expect(_validar(nascimento: '29/02/2024'), isA<CadastroValido>());
    });

    test('aceita nascido hoje', () {
      expect(_validar(nascimento: '23/09/2026'), isA<CadastroValido>());
    });

    test('recusa data no futuro', () {
      expect(
        _invalido(_validar(nascimento: '24/09/2026')).nascimento,
        ProblemaNoCadastro.nascimentoNoFuturo,
      );
    });

    test('recusa mais de 120 anos, aceita exatamente 120', () {
      expect(
        _invalido(_validar(nascimento: '22/09/1905')).nascimento,
        ProblemaNoCadastro.nascimentoImplausivel,
      );
      expect(_validar(nascimento: '23/09/1906'), isA<CadastroValido>());
    });
  });

  group('idadeEntre', () {
    test('conta anos completos, virando no dia do aniversário', () {
      final nascimento = DateTime(1985, 7, 2);

      expect(idadeEntre(nascimento, DateTime(2026, 7, 1)), 40);
      expect(idadeEntre(nascimento, DateTime(2026, 7, 2)), 41);
      expect(idadeEntre(nascimento, DateTime(2026, 12, 31)), 41);
    });
  });

  group('RepositorioPacientesPlaceholder', () {
    test('o cadastrado aparece no topo da lista, sem sessão', () async {
      final repositorio = RepositorioPacientesPlaceholder();
      final novo = (_validar() as CadastroValido).paciente;

      final salvo = await repositorio.cadastrar(novo);
      final lista = await repositorio.listar();

      expect(lista.first.id, salvo.id);
      expect(lista.first.nome, 'Ana de Teste');
      expect(lista.first.ultimaSessao, isNull);
      expect(lista.first.direcaoAvqi, DirecaoDaMedida.semComparacao);
    });

    test('cadastros seguidos têm ids diferentes', () async {
      final repositorio = RepositorioPacientesPlaceholder();
      final novo = (_validar() as CadastroValido).paciente;

      // Todos no mesmo instante, como Ana e Bia no teste de duplicidade.
      final salvos = await Future.wait([
        for (var i = 0; i < 2000; i++) repositorio.cadastrar(novo),
      ]);
      final ids = salvos.map((p) => p.id);

      expect(ids.toSet(), hasLength(2000));
    });
  });
}
