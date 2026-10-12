import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/cadastro/data/cadastro_api.dart';
import 'package:fonar_app/features/cadastro/domain/cadastro.dart';
import 'package:fonar_app/features/conta/domain/dados_do_profissional.dart';

import '../../apoio/http_falso.dart';

/// O cadastro como a API devolve (`ProfissionalResponse`, no `fonar-api`).
const _perfil = {
  'id': 'uid-1',
  'email': 'fono@exemplo.com',
  'nome': 'Ana Souza',
  'crefono_regiao': 2,
  'crefono_numero': '12345',
  'registro_conselho': 'CRFa 2-12345',
  'situacao': 'pendente',
  'credenciado_em': null,
  'versao_termos': 'provisorio-2026-10-11',
  'cadastro_completo': true,
};

RespostaFalsa _recusa(int status, String codigo) => RespostaFalsa(status, {
  'detail': {'codigo': codigo, 'mensagem': 'x'},
});

({CadastroApi api, AdaptadorFalso servidor}) _montar(
  List<RespostaFalsa> respostas,
) {
  final servidor = AdaptadorFalso(respostas);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = servidor
    ..interceptors.add(const ErrorInterceptor());
  return (api: CadastroApi(dio), servidor: servidor);
}

const _dados = DadosDoCadastro(
  nome: 'Ana Souza',
  crefonoRegiao: 2,
  crefonoNumero: '12345',
);

void main() {
  group('validarRegistro', () {
    test('aceita e limpa', () {
      final resultado = validarRegistro(
        nome: '  Ana   Souza ',
        regiao: 9,
        inscricao: ' 12.345-6 ',
        aceitouTermos: true,
      );
      expect(resultado, isA<RegistroValido>());
      final dados = (resultado as RegistroValido).dados;
      expect(dados.nome, 'Ana Souza');
      expect(dados.crefonoRegiao, 9);
      expect(dados.crefonoNumero, '12.345-6');
    });

    test('um problema por campo, todos de uma vez', () {
      final resultado = validarRegistro(
        nome: ' ',
        regiao: null,
        inscricao: 'CRFa 2-12345',
        aceitouTermos: false,
      );
      expect((resultado as RegistroInvalido).problemas, {
        CampoDoRegistro.nome: ProblemaNoRegistro.nomeVazio,
        CampoDoRegistro.regiao: ProblemaNoRegistro.regiaoVazia,
        CampoDoRegistro.inscricao: ProblemaNoRegistro.inscricaoInvalida,
        CampoDoRegistro.termos: ProblemaNoRegistro.termosNaoAceitos,
      });
    });

    test('as mesmas regras da API para o número', () {
      for (final (inscricao, valida) in [
        ('12345', true),
        ('12.345', true),
        ('12345-6', true),
        ('12/345', true),
        ('12a45', true),
        (' 12 345 ', true),
        ('abc', false),
        ('CRFa 2-12345', false),
        ('12_345', false),
        ('1' * 21, false),
        ('', false),
      ]) {
        final resultado = validarRegistro(
          nome: 'Ana',
          regiao: 2,
          inscricao: inscricao,
          aceitouTermos: true,
        );
        expect(resultado is RegistroValido, valida, reason: inscricao);
      }
    });

    test('o número sai como a API grava: sem espaço, em maiúsculas', () {
      final resultado = validarRegistro(
        nome: 'Ana',
        regiao: 2,
        inscricao: ' 12a 45 ',
        aceitouTermos: true,
      );
      expect((resultado as RegistroValido).dados.crefonoNumero, '12A45');
    });

    test('região fora de 1 a 9', () {
      for (final regiao in [0, 10]) {
        final resultado = validarRegistro(
          nome: 'Ana',
          regiao: regiao,
          inscricao: '1',
          aceitouTermos: true,
        );
        expect(
          (resultado as RegistroInvalido).problemas[CampoDoRegistro.regiao],
          ProblemaNoRegistro.regiaoVazia,
        );
      }
    });
  });

  group('validarConta', () {
    test('e-mail, senha curta e repetição diferente', () {
      expect(validarConta(email: '', senha: '', confirmacao: ''), {
        CampoDoRegistro.email: ProblemaNoRegistro.emailVazio,
        CampoDoRegistro.senha: ProblemaNoRegistro.senhaCurta,
      });
      expect(
        validarConta(email: 'fono@', senha: '12345678', confirmacao: '1234567'),
        {
          CampoDoRegistro.email: ProblemaNoRegistro.emailInvalido,
          CampoDoRegistro.confirmacao: ProblemaNoRegistro.senhasDiferentes,
        },
      );
      expect(
        validarConta(
          email: ' fono@exemplo.com ',
          senha: 'senha boa',
          confirmacao: 'senha boa',
        ),
        isEmpty,
      );
    });
  });

  group('lerRegistro', () {
    test('lê região e número do jeito que se escreve', () {
      for (final texto in ['CRFa 2-12345', 'crfa 2 - 12345', '2-12345']) {
        expect(lerRegistro(texto), (regiao: 2, inscricao: '12345'));
      }
      expect(lerRegistro('CRFa 6-12.345-6'), (
        regiao: 6,
        inscricao: '12.345-6',
      ));
      // Letra no número existe (inscrição secundária), e vai em maiúsculas.
      expect(lerRegistro('CRFa 2-12a'), (regiao: 2, inscricao: '12A'));
    });

    test('sem a região, ou com texto, não é registro', () {
      for (final texto in ['12345', 'CRFa 12345', 'CRFa 0-123', 'CRFa 2-abc']) {
        expect(lerRegistro(texto), isNull, reason: texto);
      }
    });
  });

  group('CadastroApi', () {
    test('cadastro existente: o perfil, com o credenciamento', () async {
      final m = _montar([const RespostaFalsa(200, _perfil)]);
      final situacao = await m.api.situacao();
      expect(
        m.servidor.feitas.single.uri.toString(),
        'https://api.test/v1/profissionais/eu',
      );
      final perfil = (situacao as Cadastrado).perfil;
      expect(perfil.nome, 'Ana Souza');
      expect(perfil.registro, 'CRFa 2-12345');
      expect(perfil.credenciamento, Credenciamento.pendente);
      expect(perfil.completo, isTrue);
    });

    test('os dois 403 do primeiro acesso viram passos, não erros', () async {
      final m = _montar([
        _recusa(403, 'email_nao_verificado'),
        _recusa(403, 'profissional_nao_cadastrado'),
      ]);
      expect(await m.api.situacao(), isA<EmailPorVerificar>());
      expect(await m.api.situacao(), isA<SemCadastro>());
    });

    test('credenciado: a situação da API', () async {
      final m = _montar([
        RespostaFalsa(200, {..._perfil, 'situacao': 'credenciado'}),
      ]);
      final perfil = ((await m.api.situacao()) as Cadastrado).perfil;
      expect(perfil.credenciamento, Credenciamento.credenciado);
    });

    test('cadastro antigo, do convite, está incompleto', () async {
      final m = _montar([
        const RespostaFalsa(200, {
          'id': 'uid-1',
          'email': 'fono@exemplo.com',
          'nome': null,
          'crefono_regiao': null,
          'crefono_numero': null,
          'registro_conselho': 'CRFa 123456',
          'situacao': 'pendente',
          'cadastro_completo': false,
        }),
      ]);
      final perfil = ((await m.api.situacao()) as Cadastrado).perfil;
      expect(perfil.completo, isFalse);
      expect(perfil.registro, 'CRFa 123456');
    });

    test('rede fora: a falha sobe', () async {
      final m = _montar([const RespostaFalsa.semRede()]);
      await expectLater(m.api.situacao(), throwsA(isA<FalhaDeConexao>()));
    });

    test('cadastrar manda só os campos que a API pede', () async {
      // A API recusa campo que não conhece (`extra="forbid"`).
      final m = _montar([const RespostaFalsa(201, _perfil)]);
      await m.api.cadastrar(_dados);
      final pedido = m.servidor.feitas.single;
      expect(pedido.opcoes.method, 'POST');
      expect(pedido.json, {
        'nome': 'Ana Souza',
        'crefono_regiao': 2,
        'crefono_numero': '12345',
        'versao_termos': versaoDosTermos,
      });
    });

    test('cadastro que já existia: devolve o que existe', () async {
      final m = _montar([const RespostaFalsa(200, _perfil)]);
      final perfil = await m.api.cadastrar(_dados);
      expect(perfil.registro, 'CRFa 2-12345');
      expect(m.servidor.feitas, hasLength(1));
    });

    test('e-mail ainda não verificado é um passo, não uma falha', () async {
      final m = _montar([_recusa(403, 'email_nao_verificado')]);
      await expectLater(
        m.api.cadastrar(_dados),
        throwsA(isA<EmailAindaNaoVerificado>()),
      );
    });

    test('atualizar troca nome e inscrição pelo PATCH', () async {
      final m = _montar([const RespostaFalsa(200, _perfil)]);
      await m.api.atualizar(_dados);
      final pedido = m.servidor.feitas.single;
      expect(pedido.opcoes.method, 'PATCH');
      expect(pedido.json, {
        'nome': 'Ana Souza',
        'crefono_regiao': 2,
        'crefono_numero': '12345',
      });
    });
  });
}
