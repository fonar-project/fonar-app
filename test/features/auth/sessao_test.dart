import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/auth/senha_sem_rede.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_firebase.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:fonar_app/features/auth/presentation/login_controlador.dart';
import 'package:fonar_app/features/cadastro/presentation/entrada.dart';

import '../../apoio/senha_sem_rede_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

(ProviderContainer, AutenticacaoFalsa) _container({
  AutenticacaoFalsa? autenticacao,
  SenhaSemRedeEmMemoria? senhas,
}) {
  final falsa = autenticacao ?? AutenticacaoFalsa();
  final container = ProviderContainer(
    overrides: [
      repositorioAutenticacaoProvider.overrideWithValue(falsa),
      senhaSemRedeProvider.overrideWithValue(senhas ?? SenhaSemRedeEmMemoria()),
    ],
  );
  addTearDown(container.dispose);
  container.listen(loginControladorProvider, (_, _) {});
  return (container, falsa);
}

void main() {
  test('começa fechada: sem login, a fila não envia', () {
    final (container, _) = _container();
    expect(container.read(sessaoAbertaProvider), isFalse);
    expect(container.read(sessaoProvider), isNull);
  });

  test('entrar abre a sessão com a conta que o Firebase devolveu', () async {
    final (container, _) = _container();
    final entrou = await container
        .read(loginControladorProvider.notifier)
        .entrar(email: 'fono@exemplo.com', senha: 'senha');

    // No modo de exemplo (o dos testes), não há cadastro a conferir: entra
    // direto.
    expect(entrou, isA<EntrarNoApp>());
    expect(container.read(sessaoAbertaProvider), isTrue);
    expect(container.read(sessaoProvider), contaDeTeste);
  });

  test('campos vazios não abrem a sessão', () async {
    final (container, falsa) = _container();
    await container
        .read(loginControladorProvider.notifier)
        .entrar(email: '', senha: '');

    expect(container.read(sessaoAbertaProvider), isFalse);
    expect(falsa.entradas, isEmpty);
  });

  test('senha recusada não abre a sessão', () async {
    final (container, _) = _container(
      autenticacao: AutenticacaoFalsa(recusar: true),
    );
    final entrou = await container
        .read(loginControladorProvider.notifier)
        .entrar(email: 'fono@exemplo.com', senha: 'errada');

    expect(entrou, isNull);
    expect(container.read(sessaoAbertaProvider), isFalse);
  });

  test('modo offline entra com a conta da última entrada com senha', () async {
    final (container, _) = _container(
      autenticacao: AutenticacaoFalsa(guardada: outraConta),
      senhas: SenhaSemRedeEmMemoria({outraConta.uid: 'certa'}),
    );
    final entrou = await container
        .read(loginControladorProvider.notifier)
        .entrarOffline('certa');

    expect(entrou, isTrue);
    expect(container.read(sessaoProvider), outraConta);
  });

  // US43: antes, o modo offline entrava sem senha nenhuma.
  test('modo offline com a senha errada não abre', () async {
    final (container, _) = _container(
      autenticacao: AutenticacaoFalsa(guardada: outraConta),
      senhas: SenhaSemRedeEmMemoria({outraConta.uid: 'certa'}),
    );
    final controlador = container.read(loginControladorProvider.notifier);

    expect(await controlador.entrarOffline('errada'), isFalse);
    expect(
      container.read(loginControladorProvider).erroSemRede,
      AppStrings.loginSemRedeSenhaNaoConfere,
    );
    expect(await controlador.entrarOffline(''), isFalse);
    expect(
      container.read(loginControladorProvider).erroSemRede,
      AppStrings.loginInformeSenha,
    );
    expect(container.read(sessaoAbertaProvider), isFalse);
  });

  test('sem senha guardada desta conta, o modo offline não abre', () async {
    final (container, _) = _container(
      autenticacao: AutenticacaoFalsa(guardada: outraConta),
      senhas: SenhaSemRedeEmMemoria({contaDeTeste.uid: 'certa'}),
    );
    expect(
      await container
          .read(loginControladorProvider.notifier)
          .entrarOffline('certa'),
      isFalse,
    );
    expect(
      container.read(loginControladorProvider).erroSemRede,
      AppStrings.loginSemRedeSemSenhaGuardada,
    );
  });

  test('entrar com rede guarda a senha para a entrada sem rede', () async {
    final senhas = SenhaSemRedeEmMemoria();
    final (container, _) = _container(senhas: senhas);
    await container
        .read(loginControladorProvider.notifier)
        .entrar(email: 'fono@exemplo.com', senha: 'senha');
    await Future<void>.delayed(Duration.zero);

    expect(senhas.senhas, {contaDeTeste.uid: 'senha'});
  });

  test('sem conta guardada, o modo offline não abre', () async {
    final (container, _) = _container();
    final entrou = await container
        .read(loginControladorProvider.notifier)
        .entrarOffline('qualquer');

    expect(entrou, isFalse);
    expect(container.read(sessaoAbertaProvider), isFalse);
  });
}
