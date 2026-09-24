import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';

import '../../apoio/repositorios_em_memoria.dart';

PedidoDeConsentimento _pedido(ResultadoDoConsentimento r) {
  expect(r, isA<ConsentimentoValido>());
  return (r as ConsentimentoValido).pedido;
}

ConsentimentoInvalido _invalido(ResultadoDoConsentimento r) {
  expect(r, isA<ConsentimentoInvalido>());
  return r as ConsentimentoInvalido;
}

void main() {
  group('validarConsentimento', () {
    test('o próprio paciente, com concordância, é válido e sem nome', () {
      final pedido = _pedido(
        validarConsentimento(
          quemAutoriza: QuemAutoriza.paciente,
          nomeDoResponsavel: '',
          concordou: true,
        ),
      );

      expect(pedido.quemAutoriza, QuemAutoriza.paciente);
      expect(pedido.nomeDoResponsavel, isNull);
    });

    test('responsável legal exige o nome, já sem espaço sobrando', () {
      final pedido = _pedido(
        validarConsentimento(
          quemAutoriza: QuemAutoriza.responsavelLegal,
          nomeDoResponsavel: '  Maria   de Teste ',
          concordou: true,
        ),
      );

      expect(pedido.nomeDoResponsavel, 'Maria de Teste');
    });

    test('responsável sem nome é recusado', () {
      final r = _invalido(
        validarConsentimento(
          quemAutoriza: QuemAutoriza.responsavelLegal,
          nomeDoResponsavel: '  ',
          concordou: true,
        ),
      );

      expect(
        r.nomeDoResponsavel,
        ProblemaNoConsentimento.nomeDoResponsavelVazio,
      );
      expect(r.quemAutoriza, isNull);
      expect(r.concordancia, isNull);
    });

    test('nome digitado e depois trocado para o paciente é descartado', () {
      // Dado pessoal de quem não participou do registro não se guarda.
      final pedido = _pedido(
        validarConsentimento(
          quemAutoriza: QuemAutoriza.paciente,
          nomeDoResponsavel: 'Maria de Teste',
          concordou: true,
        ),
      );

      expect(pedido.nomeDoResponsavel, isNull);
    });

    test('sem concordância não registra, mesmo com o resto preenchido', () {
      final r = _invalido(
        validarConsentimento(
          quemAutoriza: QuemAutoriza.paciente,
          nomeDoResponsavel: '',
          concordou: false,
        ),
      );

      expect(r.concordancia, ProblemaNoConsentimento.concordanciaNaoMarcada);
    });

    test('nada preenchido aponta quem autoriza e a concordância', () {
      final r = _invalido(
        validarConsentimento(
          quemAutoriza: null,
          nomeDoResponsavel: '',
          concordou: false,
        ),
      );

      expect(r.quemAutoriza, ProblemaNoConsentimento.quemAutorizaNaoEscolhido);
      // Sem saber quem autoriza, ainda não dá para exigir o nome.
      expect(r.nomeDoResponsavel, isNull);
      expect(r.concordancia, ProblemaNoConsentimento.concordanciaNaoMarcada);
    });
  });

  group('RepositorioConsentimentoPlaceholder', () {
    test('registra com a versão atual do termo e passa a encontrar', () async {
      final repositorio = RepositorioConsentimentoPlaceholder();
      expect(await repositorio.buscar('novo'), isNull);

      final pedido = _pedido(
        validarConsentimento(
          quemAutoriza: QuemAutoriza.responsavelLegal,
          nomeDoResponsavel: 'Maria de Teste',
          concordou: true,
        ),
      );
      await repositorio.registrar('novo', pedido);

      final achado = await repositorio.buscar('novo');
      expect(achado, isNotNull);
      expect(achado!.versaoDoTermo, versaoAtualDoTermo);
      expect(achado.quemAutoriza, QuemAutoriza.responsavelLegal);
      expect(achado.nomeDoResponsavel, 'Maria de Teste');
    });

    test('o paciente de exemplo E chega sem consentimento', () async {
      final repositorio = RepositorioConsentimentoPlaceholder();

      expect(await repositorio.buscar('exemplo-a'), isNotNull);
      expect(await repositorio.buscar('exemplo-e'), isNull);
    });
  });
}
