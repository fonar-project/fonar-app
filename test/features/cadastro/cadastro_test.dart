import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/cadastro/data/cadastro_api.dart';
import 'package:fonar_app/features/cadastro/domain/cadastro.dart';
import 'package:fonar_app/features/conta/domain/dados_do_profissional.dart';

import '../../apoio/http_falso.dart';

/// O cadastro como a API devolve.
const _perfil = {
  'id': 'uid-1',
  'email': 'fono@exemplo.com',
  'nome': 'Ana Souza',
  'crefono_regiao': 2,
  'crefono_inscricao': '12345',
  'registro_conselho': 'CRFa 2-12345',
  'credenciamento': 'pendente',
  'credenciamento_em': null,
  'credenciamento_observacao': null,
  'versao_termos': 'provisorio-2026-10-11',
  'termos_aceitos_em': '2026-10-11T12:00:00Z',
  'criado_em': '2026-10-11T12:00:00Z',
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
  crefonoInscricao: '12345',
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
      expect(dados.crefonoInscricao, '12.345-6');
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
        ('-123', false),
        ('12a45', false),
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
    });

    test('sem a região, ou com texto, não é registro', () {
      for (final texto in ['12345', 'CRFa 12345', 'CRFa 0-123', 'CRFa 2-12a']) {
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

    test('recusado: o motivo vem junto', () async {
      final m = _montar([
        RespostaFalsa(200, {
          ..._perfil,
          'credenciamento': 'recusado',
          'credenciamento_observacao': 'inscrição não encontrada',
        }),
      ]);
      final perfil = ((await m.api.situacao()) as Cadastrado).perfil;
      expect(perfil.credenciamento, Credenciamento.recusado);
      expect(perfil.observacao, 'inscrição não encontrada');
    });

    test('cadastro antigo, do convite, está incompleto', () async {
      final m = _montar([
        const RespostaFalsa(200, {
          'id': 'uid-1',
          'email': 'fono@exemplo.com',
          'registro_conselho': 'CRFa 123456',
          'credenciamento': 'pendente',
        }),
      ]);
      final perfil = ((await m.api.situacao()) as Cadastrado).perfil;
      expect(perfil.completo, isFalse);
    });

    test('rede fora: a falha sobe', () async {
      final m = _montar([const RespostaFalsa.semRede()]);
      await expectLater(m.api.situacao(), throwsA(isA<FalhaDeConexao>()));
    });

    test('cadastrar manda nome, inscrição e o aceite dos termos', () async {
      final m = _montar([const RespostaFalsa(201, _perfil)]);
      await m.api.cadastrar(_dados);
      final pedido = m.servidor.feitas.single;
      expect(pedido.opcoes.method, 'POST');
      expect(pedido.json, {
        'nome': 'Ana Souza',
        'crefono_regiao': 2,
        'crefono_inscricao': '12345',
        'versao_termos': versaoDosTermos,
        'aceita_termos': true,
      });
      expect(pedido.json.containsKey('email'), isFalse);
    });

    test('cadastro que já existe: devolve o que existe', () async {
      final m = _montar([
        _recusa(409, 'profissional_ja_cadastrado'),
        const RespostaFalsa(200, _perfil),
      ]);
      final perfil = await m.api.cadastrar(_dados);
      expect(perfil.registro, 'CRFa 2-12345');
      expect(m.servidor.feitas.map((f) => f.opcoes.method), ['POST', 'GET']);
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
        'crefono_inscricao': '12345',
      });
    });

    test('a recusa do credenciamento tem tipo próprio', () async {
      final m = _montar([_recusa(403, 'credencial_recusada')]);
      await expectLater(
        m.api.atualizar(_dados),
        throwsA(isA<CredencialRecusada>()),
      );
    });
  });
}
