import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:praatico_app/features/pacientes/domain/paciente.dart';

void main() {
  const paciente = Paciente(
    id: '1',
    nome: 'Conceição Araújo',
    queixa: 'rouquidão persistente',
    direcaoAvqi: DirecaoDaMedida.estavel,
  );

  group('busca de paciente', () {
    test('ignora acento, nos dois sentidos', () {
      // Quem digita com pressa no celular não põe til; quem cadastrou, pôs.
      expect(paciente.correspondeA('rouquidao'), isTrue);
      expect(paciente.correspondeA('conceicao'), isTrue);
      expect(paciente.correspondeA('araujo'), isTrue);
      expect(paciente.correspondeA('ROUQUIDÃO'), isTrue);
    });

    test('procura no nome e na queixa', () {
      expect(paciente.correspondeA('conce'), isTrue);
      expect(paciente.correspondeA('persist'), isTrue);
    });

    test('termo vazio ou só espaço traz todos', () {
      expect(paciente.correspondeA(''), isTrue);
      expect(paciente.correspondeA('   '), isTrue);
    });

    test('termo com espaço nas pontas ainda encontra', () {
      expect(paciente.correspondeA('  rouquidao '), isTrue);
    });

    test('termo que não aparece não encontra', () {
      expect(paciente.correspondeA('soprosidade'), isFalse);
    });
  });
}
