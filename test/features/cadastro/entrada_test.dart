import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_firebase.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/domain/conta_autenticada.dart';
import 'package:fonar_app/features/auth/presentation/login_controlador.dart';
import 'package:fonar_app/features/cadastro/data/cadastro_api.dart';
import 'package:fonar_app/features/cadastro/data/criacao_de_conta.dart';
import 'package:fonar_app/features/cadastro/domain/cadastro.dart';
import 'package:fonar_app/features/cadastro/presentation/cadastro_controlador.dart';
import 'package:fonar_app/features/cadastro/presentation/entrada.dart';
import 'package:fonar_app/features/conta/data/repositorio_da_conta_local.dart';
import 'package:fonar_app/features/conta/domain/dados_do_profissional.dart';
import 'package:fonar_app/features/conta/presentation/conta_controlador.dart';
import 'package:fonar_app/features/auth/data/profissional_atual.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';

import '../../apoio/http_falso.dart';
import '../../apoio/sessao_de_teste.dart';

Map<String, Object?> _perfil({
  String situacao = 'pendente',
  bool completo = true,
}) => {
  'id': contaDeTeste.uid,
  'email': contaDeTeste.email,
  'nome': completo ? 'Ana Souza' : null,
  'crefono_regiao': completo ? 2 : null,
  'crefono_numero': completo ? '12345' : null,
  'registro_conselho': completo ? 'CRFa 2-12345' : 'CRFa 123456',
  'situacao': situacao,
  'credenciado_em': null,
  'versao_termos': completo ? 'provisorio-2026-10-11' : null,
  'cadastro_completo': completo,
};

RespostaFalsa _recusa(int status, String codigo) => RespostaFalsa(status, {
  'detail': {'codigo': codigo, 'mensagem': 'x'},
});

/// A criação de conta sem o Firebase: anota o que pediram.
class _CriacaoFalsa implements CriacaoDeConta {
  _CriacaoFalsa(this._autenticacao);

  final AutenticacaoFalsa _autenticacao;
  AppException? recusar;
  final criadas = <String>[];
  var reenvios = 0;
  var atualizacoes = 0;

  @override
  Future<ContaAutenticada> criarConta({
    required String email,
    required String senha,
  }) async {
    if (recusar case final falha?) throw falha;
    criadas.add(email);
    return _autenticacao.guardada = contaDeTeste;
  }

  @override
  Future<void> reenviarVerificacao() async => reenvios++;

  @override
  Future<void> atualizarVerificacao() async => atualizacoes++;
}

class _Montagem {
  _Montagem(List<RespostaFalsa> respostas, {ContaAutenticada? guardada})
    : servidor = AdaptadorFalso(respostas),
      autenticacao = AutenticacaoFalsa(guardada: guardada) {
    criacao = _CriacaoFalsa(autenticacao);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = servidor
      ..interceptors.add(const ErrorInterceptor());
    container = ProviderContainer(
      overrides: [
        repositorioAutenticacaoProvider.overrideWithValue(autenticacao),
        cadastroApiProvider.overrideWithValue(CadastroApi(dio)),
        criacaoDeContaProvider.overrideWithValue(criacao),
      ],
    );
    addTearDown(container.dispose);
    // Os controladores são autoDispose: alguém tem de estar ouvindo.
    container.listen(loginControladorProvider, (_, _) {});
    container.listen(criarContaControladorProvider, (_, _) {});
    container.listen(verificacaoControladorProvider, (_, _) {});
    container.listen(completarCadastroControladorProvider, (_, _) {});
  }

  final AdaptadorFalso servidor;
  final AutenticacaoFalsa autenticacao;
  late final _CriacaoFalsa criacao;
  late final ProviderContainer container;

  bool get sessaoAberta => container.read(sessaoAbertaProvider);

  Future<DestinoDaEntrada?> entrar() => container
      .read(loginControladorProvider.notifier)
      .entrar(email: 'fono@exemplo.com', senha: 'senha');
}

/// O perfil já carregado, sem ir ao banco nem à API ao abrir.
class _ProfissionalFixo extends ProfissionalAtual {
  @override
  Profissional build() => const Profissional(
    nome: 'Ana Souza',
    registro: 'CRFa 2-12345',
    email: 'fono@exemplo.com',
    credenciamento: Credenciamento.credenciado,
  );
}

class _ContaEmMemoria implements RepositorioDaConta {
  final salvos = <Profissional>[];

  @override
  Future<Profissional?> perfil(String uid) async => null;

  @override
  Future<void> salvar(String uid, Profissional profissional) async =>
      salvos.add(profissional);
}

const _dados = DadosDoCadastro(
  nome: 'Ana Souza',
  crefonoRegiao: 2,
  crefonoNumero: '12345',
);

void main() {
  group('entrar com senha confere o cadastro', () {
    test('cadastrado e pendente: entra', () async {
      final m = _Montagem([RespostaFalsa(200, _perfil())]);
      expect(await m.entrar(), isA<EntrarNoApp>());
      expect(m.sessaoAberta, isTrue);
    });

    test('e-mail por verificar: vai confirmar, sem sessão', () async {
      final m = _Montagem([_recusa(403, 'email_nao_verificado')]);
      expect(await m.entrar(), isA<VerificarEmail>());
      expect(m.sessaoAberta, isFalse);
      // A credencial fica: é com ela que a confirmação pede o token novo.
      expect(m.autenticacao.saidas, 0);
    });

    test('sem cadastro: vai ao formulário, sem sessão', () async {
      final m = _Montagem([_recusa(403, 'profissional_nao_cadastrado')]);
      expect(await m.entrar(), isA<CompletarCadastro>());
      expect(m.sessaoAberta, isFalse);
    });

    test('credenciado entra do mesmo jeito', () async {
      final m = _Montagem([
        RespostaFalsa(200, _perfil(situacao: 'credenciado')),
      ]);
      expect(await m.entrar(), isA<EntrarNoApp>());
      expect(m.sessaoAberta, isTrue);
    });

    test('cadastro antigo, do convite: vai completar', () async {
      final m = _Montagem([RespostaFalsa(200, _perfil(completo: false))]);
      expect(await m.entrar(), isA<CompletarCadastro>());
      expect(m.sessaoAberta, isFalse);
    });

    test('API fora do ar: entra como sempre entrou', () async {
      final m = _Montagem([const RespostaFalsa.semRede()]);
      expect(await m.entrar(), isA<EntrarNoApp>());
      expect(m.sessaoAberta, isTrue);
    });
  });

  group('criar conta', () {
    Future<DestinoDaEntrada?> criar(
      _Montagem m, {
      String email = 'fono@exemplo.com',
      String senha = 'senha-boa',
      String? confirmacao,
      int? regiao = 2,
      bool termos = true,
    }) => m.container
        .read(criarContaControladorProvider.notifier)
        .criar(
          email: email,
          senha: senha,
          confirmacao: confirmacao ?? senha,
          nome: 'Ana Souza',
          regiao: regiao,
          inscricao: '12345',
          aceitouTermos: termos,
        );

    test('formulário com problema não cria nada', () async {
      final m = _Montagem([]);
      expect(
        await criar(m, senha: 'curta', regiao: null, termos: false),
        isNull,
      );
      final erros = m.container.read(criarContaControladorProvider).erros;
      expect(erros.keys, {
        CampoDoRegistro.senha,
        CampoDoRegistro.regiao,
        CampoDoRegistro.termos,
      });
      expect(m.criacao.criadas, isEmpty);
    });

    test('cria a conta e guarda o cadastro para depois do e-mail', () async {
      final m = _Montagem([]);
      expect(await criar(m), isA<VerificarEmail>());
      expect(m.criacao.criadas, ['fono@exemplo.com']);
      final pendente = m.container.read(cadastroPendenteProvider);
      expect(pendente?.crefonoNumero, '12345');
      // A API ainda não foi chamada: o e-mail não foi confirmado.
      expect(m.servidor.feitas, isEmpty);
    });

    test('e-mail já usado: o erro vai no campo do e-mail', () async {
      final m = _Montagem([])..criacao.recusar = const EmailIndisponivel();
      expect(await criar(m), isNull);
      expect(
        m.container
            .read(criarContaControladorProvider)
            .erroDe(CampoDoRegistro.email),
        isNotNull,
      );
    });
  });

  group('confirmar o e-mail', () {
    Future<DestinoDaEntrada?> confirmar(_Montagem m) =>
        m.container.read(verificacaoControladorProvider.notifier).confirmar();

    test('ainda não confirmado: avisa e fica', () async {
      final m = _Montagem([
        _recusa(403, 'email_nao_verificado'),
      ], guardada: contaDeTeste);
      expect(await confirmar(m), isNull);
      expect(m.criacao.atualizacoes, 1);
      expect(m.container.read(verificacaoControladorProvider).aviso, isNotNull);
      expect(m.sessaoAberta, isFalse);
    });

    test('confirmado, com o cadastro da criação: envia e entra', () async {
      final m = _Montagem([
        _recusa(403, 'profissional_nao_cadastrado'),
        RespostaFalsa(201, _perfil()),
      ], guardada: contaDeTeste);
      m.container.read(cadastroPendenteProvider.notifier).guardar(_dados);

      expect(await confirmar(m), isA<EntrarNoApp>());
      expect(m.servidor.feitas.map((f) => f.opcoes.method), ['GET', 'POST']);
      expect(m.sessaoAberta, isTrue);
      expect(m.container.read(cadastroPendenteProvider), isNull);
    });

    test('confirmado, sem o cadastro na memória: vai ao formulário', () async {
      final m = _Montagem([
        _recusa(403, 'profissional_nao_cadastrado'),
      ], guardada: contaDeTeste);
      expect(await confirmar(m), isA<CompletarCadastro>());
      expect(m.sessaoAberta, isFalse);
    });

    test('reenviar pede outro e-mail e avisa', () async {
      final m = _Montagem([], guardada: contaDeTeste);
      await m.container
          .read(verificacaoControladorProvider.notifier)
          .reenviar();
      expect(m.criacao.reenvios, 1);
      expect(m.container.read(verificacaoControladorProvider).aviso, isNotNull);
    });

    test(
      'outra conta: a credencial sai e o cadastro guardado também',
      () async {
        final m = _Montagem([], guardada: contaDeTeste);
        m.container.read(cadastroPendenteProvider.notifier).guardar(_dados);
        final saiu = await m.container
            .read(verificacaoControladorProvider.notifier)
            .trocarDeConta();
        expect(saiu, isTrue);
        expect(m.autenticacao.saidas, 1);
        expect(m.container.read(cadastroPendenteProvider), isNull);
      },
    );
  });

  group('completar o cadastro', () {
    test('envia e entra', () async {
      final m = _Montagem([
        RespostaFalsa(201, _perfil()),
      ], guardada: contaDeTeste);
      final destino = await m.container
          .read(completarCadastroControladorProvider.notifier)
          .concluir(
            nome: 'Ana Souza',
            regiao: 2,
            inscricao: '12345',
            aceitouTermos: true,
          );
      expect(destino, isA<EntrarNoApp>());
      expect(m.servidor.feitas.single.json['crefono_numero'], '12345');
      expect(m.sessaoAberta, isTrue);
    });

    test('sem aceitar os termos, nada vai à API', () async {
      final m = _Montagem([], guardada: contaDeTeste);
      final destino = await m.container
          .read(completarCadastroControladorProvider.notifier)
          .concluir(
            nome: 'Ana Souza',
            regiao: 2,
            inscricao: '12345',
            aceitouTermos: false,
          );
      expect(destino, isNull);
      expect(m.servidor.feitas, isEmpty);
      expect(
        m.container
            .read(completarCadastroControladorProvider)
            .erroDe(CampoDoRegistro.termos),
        isNotNull,
      );
    });
  });

  group('Conta com a API', () {
    ({
      ProviderContainer container,
      AdaptadorFalso servidor,
      _ContaEmMemoria local,
    })
    montar(List<RespostaFalsa> respostas) {
      final servidor = AdaptadorFalso(respostas);
      final local = _ContaEmMemoria();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = servidor
        ..interceptors.add(const ErrorInterceptor());
      final container = ProviderContainer(
        overrides: [
          cadastroApiProvider.overrideWithValue(CadastroApi(dio)),
          repositorioDaContaProvider.overrideWithValue(local),
          profissionalAtualProvider.overrideWith(_ProfissionalFixo.new),
          sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(contaControladorProvider, (_, _) {});
      return (container: container, servidor: servidor, local: local);
    }

    test(
      'salva pelo PATCH, com a região e o número lidos do registro',
      () async {
        final m = montar([
          RespostaFalsa(200, {
            ..._perfil(),
            'crefono_numero': '54321',
            'registro_conselho': 'CRFa 2-54321',
          }),
        ]);
        final salvou = await m.container
            .read(contaControladorProvider.notifier)
            .salvar(nome: 'Ana Souza', registro: 'CRFa 2-54321');

        expect(salvou, isTrue);
        final pedido = m.servidor.feitas.single;
        expect(pedido.opcoes.method, 'PATCH');
        expect(pedido.json, {
          'nome': 'Ana Souza',
          'crefono_regiao': 2,
          'crefono_numero': '54321',
        });
        // O que vale é o que a API devolveu: trocar o número voltou a pendente.
        final atual = m.container.read(profissionalAtualProvider);
        expect(atual.registro, 'CRFa 2-54321');
        expect(atual.credenciamento, Credenciamento.pendente);
        expect(m.local.salvos.single.registro, 'CRFa 2-54321');
      },
    );

    test('registro fora do formato: erro no campo, nada vai à API', () async {
      final m = montar([]);
      final salvou = await m.container
          .read(contaControladorProvider.notifier)
          .salvar(nome: 'Ana Souza', registro: '54321');

      expect(salvou, isFalse);
      expect(
        m.container.read(contaControladorProvider).erroRegistro,
        ProblemaNosDados.registroFormato,
      );
      expect(m.servidor.feitas, isEmpty);
      expect(m.local.salvos, isEmpty);
    });
  });
}
