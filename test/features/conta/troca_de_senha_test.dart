import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/auth/credencial.dart';
import 'package:fonar_app/core/auth/firebase_auth_rest.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/domain/conta_autenticada.dart';
import 'package:fonar_app/features/conta/data/troca_de_senha_firebase.dart';
import 'package:fonar_app/features/conta/domain/troca_de_senha.dart';
import 'package:fonar_app/features/conta/presentation/troca_de_senha_controlador.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/http_falso.dart';
import '../../apoio/repositorios_em_memoria.dart';
import '../../apoio/senha_sem_rede_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

final _agora = DateTime.utc(2026, 10, 14, 9);

final _guardada = Credencial(
  uid: 'uid-de-teste',
  email: 'fono@exemplo.com',
  idToken: 'token-antigo',
  refreshToken: 'renova-antigo',
  expiraEm: _agora,
);

const _entrou = RespostaFalsa(200, {
  'localId': 'uid-de-teste',
  'email': 'fono@exemplo.com',
  'idToken': 'token-recente',
  'refreshToken': 'renova-recente',
  'expiresIn': '3600',
});

const _trocou = RespostaFalsa(200, {
  'localId': 'uid-de-teste',
  'email': 'fono@exemplo.com',
  'idToken': 'token-novo',
  'refreshToken': 'renova-novo',
  'expiresIn': '3600',
});

/// A troca que só anota o pedido, ou lança [falha].
class _TrocaFalsa implements TrocaDeSenha {
  _TrocaFalsa([this.falha]);

  final Object? falha;
  final pedidos = <(String, String, String)>[];

  @override
  Future<void> trocar({
    required ContaAutenticada conta,
    required String atual,
    required String nova,
  }) async {
    pedidos.add((conta.uid, atual, nova));
    if (falha case final falha?) throw falha;
  }
}

void main() {
  group('o formulário', () {
    test('sem a atual, e a nova curta', () {
      expect(validarTrocaDeSenha(atual: '', nova: 'curta', confirmacao: ''), {
        CampoDaTrocaDeSenha.atual: ProblemaNaTrocaDeSenha.atualVazia,
        CampoDaTrocaDeSenha.nova: ProblemaNaTrocaDeSenha.novaCurta,
      });
    });

    test('a nova igual à atual não é troca', () {
      expect(
        validarTrocaDeSenha(
          atual: 'mesma-senha',
          nova: 'mesma-senha',
          confirmacao: 'mesma-senha',
        ),
        {CampoDaTrocaDeSenha.nova: ProblemaNaTrocaDeSenha.novaIgualAtual},
      );
    });

    test('a repetição tem de bater', () {
      expect(
        validarTrocaDeSenha(
          atual: 'antiga-senha',
          nova: 'nova-senha-1',
          confirmacao: 'nova-senha-2',
        ),
        {
          CampoDaTrocaDeSenha.confirmacao:
              ProblemaNaTrocaDeSenha.senhasDiferentes,
        },
      );
    });

    test('tudo certo', () {
      expect(
        validarTrocaDeSenha(
          atual: 'antiga-senha',
          nova: 'nova-senha-1',
          confirmacao: 'nova-senha-1',
        ),
        isEmpty,
      );
    });
  });

  group('no Firebase', () {
    late TokenStorageEmMemoria tokens;
    late CofreDeCredencial cofre;
    late SenhaSemRedeEmMemoria senhas;
    late AdaptadorFalso servidor;

    setUp(() async {
      tokens = TokenStorageEmMemoria();
      cofre = CofreDeCredencial(tokens);
      await cofre.guardar(_guardada);
      senhas = SenhaSemRedeEmMemoria({'uid-de-teste': 'antiga-senha'});
    });

    TrocaDeSenhaFirebase troca(List<RespostaFalsa> respostas) {
      servidor = AdaptadorFalso(respostas);
      final dio = Dio(BaseOptions(contentType: Headers.jsonContentType))
        ..httpClientAdapter = servidor
        ..interceptors.add(const ErrorInterceptor());
      return TrocaDeSenhaFirebase(
        FirebaseAuthRest(dio, chave: 'chave-de-teste', agora: () => _agora),
        cofre,
        senhas,
      );
    }

    test(
      'confere a atual, troca, e guarda a credencial e a senha sem rede',
      () async {
        await troca([_entrou, _trocou]).trocar(
          conta: contaDeTeste,
          atual: 'antiga-senha',
          nova: 'nova-senha-1',
        );

        expect(servidor.feitas, hasLength(2));
        expect(servidor.feitas.first.json, {
          'email': 'fono@exemplo.com',
          'password': 'antiga-senha',
          'returnSecureToken': true,
        });
        // A troca vai com o token da conferência, o recente.
        expect(servidor.feitas.last.json['idToken'], 'token-recente');
        expect(servidor.feitas.last.json['password'], 'nova-senha-1');

        final guardada = await cofre.ler();
        expect(guardada?.idToken, 'token-novo');
        expect(guardada?.refreshToken, 'renova-novo');
        expect(senhas.senhas, {'uid-de-teste': 'nova-senha-1'});
        // Quem não marcou "Manter conectado" continua sem (US59).
        expect(guardada?.manterConectado, isFalse);
      },
    );

    test('o "Manter conectado" continua depois da troca (US59)', () async {
      await cofre.guardar(_guardada.comManterConectado(true));

      await troca([_entrou, _trocou]).trocar(
        conta: contaDeTeste,
        atual: 'antiga-senha',
        nova: 'nova-senha-1',
      );

      final guardada = await cofre.ler();
      expect(guardada?.idToken, 'token-novo');
      expect(guardada?.manterConectado, isTrue);
    });

    test('a atual errada não troca nada', () async {
      await expectLater(
        troca([erroDoFirebase('INVALID_LOGIN_CREDENTIALS')])
            .trocar(conta: contaDeTeste, atual: 'errada', nova: 'nova-senha-1'),
        throwsA(isA<CredencialInvalida>()),
      );

      expect(servidor.feitas, hasLength(1));
      expect((await cofre.ler())?.idToken, 'token-antigo');
      expect(senhas.senhas, {'uid-de-teste': 'antiga-senha'});
    });

    test('a nova recusada pelo Firebase deixa tudo como estava', () async {
      await expectLater(
        troca([_entrou, erroDoFirebase('WEAK_PASSWORD')]).trocar(
          conta: contaDeTeste,
          atual: 'antiga-senha',
          nova: 'nova-senha-1',
        ),
        throwsA(isA<SenhaFraca>()),
      );

      expect((await cofre.ler())?.idToken, 'token-antigo');
      expect(senhas.senhas, {'uid-de-teste': 'antiga-senha'});
    });
  });

  group('o controlador', () {
    ProviderContainer abrir(TrocaDeSenha? troca) {
      final container = ProviderContainer(
        overrides: [
          sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
          trocaDeSenhaProvider.overrideWithValue(troca),
        ],
      );
      addTearDown(container.dispose);
      container.listen(trocaDeSenhaControladorProvider, (_, _) {});
      return container;
    }

    test('formulário com problema não chega ao Firebase', () async {
      final troca = _TrocaFalsa();
      final container = abrir(troca);

      final trocou = await container
          .read(trocaDeSenhaControladorProvider.notifier)
          .trocar(atual: '', nova: 'nova-senha-1', confirmacao: 'outra');

      expect(trocou, isFalse);
      expect(troca.pedidos, isEmpty);
      final estado = container.read(trocaDeSenhaControladorProvider);
      expect(estado.erroAtual, AppStrings.contaSenhaInformeAtual);
      expect(estado.erroConfirmacao, AppStrings.cadastroSenhasDiferentes);
    });

    test('troca com a conta da sessão', () async {
      final troca = _TrocaFalsa();
      final container = abrir(troca);

      final trocou = await container
          .read(trocaDeSenhaControladorProvider.notifier)
          .trocar(
            atual: 'antiga-senha',
            nova: 'nova-senha-1',
            confirmacao: 'nova-senha-1',
          );

      expect(trocou, isTrue);
      expect(troca.pedidos.single, (
        'uid-de-teste',
        'antiga-senha',
        'nova-senha-1',
      ));
      expect(container.read(trocaDeSenhaControladorProvider).trocada, isTrue);
    });

    test('a atual que não confere é dita no campo dela', () async {
      final container = abrir(_TrocaFalsa(const CredencialInvalida()));

      await container
          .read(trocaDeSenhaControladorProvider.notifier)
          .trocar(
            atual: 'errada',
            nova: 'nova-senha-1',
            confirmacao: 'nova-senha-1',
          );

      final estado = container.read(trocaDeSenhaControladorProvider);
      expect(estado.erroAtual, AppStrings.contaSenhaAtualNaoConfere);
      expect(estado.trocada, isFalse);
    });

    test('falha de rede é dita embaixo do formulário', () async {
      final container = abrir(_TrocaFalsa(const FalhaDeConexao()));

      await container
          .read(trocaDeSenhaControladorProvider.notifier)
          .trocar(
            atual: 'antiga-senha',
            nova: 'nova-senha-1',
            confirmacao: 'nova-senha-1',
          );

      final estado = container.read(trocaDeSenhaControladorProvider);
      expect(estado.erroGeral, const FalhaDeConexao().mensagem);
      expect(estado.erroAtual, isNull);
    });
  });
}
