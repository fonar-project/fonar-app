import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_firebase.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/presentation/desbloqueio_controlador.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:fonar_app/features/auth/presentation/login_controlador.dart';

import '../../apoio/sessao_de_teste.dart';

(ProviderContainer, AutenticacaoFalsa) _container({
  AutenticacaoFalsa? autenticacao,
}) {
  final falsa = autenticacao ?? AutenticacaoFalsa();
  final container = ProviderContainer(
    overrides: [repositorioAutenticacaoProvider.overrideWithValue(falsa)],
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

    expect(entrou, isTrue);
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

    expect(entrou, isFalse);
    expect(container.read(sessaoAbertaProvider), isFalse);
  });

  test('modo offline entra com a conta da última entrada com senha', () async {
    final (container, _) = _container(
      autenticacao: AutenticacaoFalsa(guardada: outraConta),
    );
    final entrou = await container
        .read(loginControladorProvider.notifier)
        .entrarOffline();

    expect(entrou, isTrue);
    expect(container.read(sessaoProvider), outraConta);
  });

  test('sem conta guardada, o modo offline não abre', () async {
    final (container, _) = _container();
    final entrou = await container
        .read(loginControladorProvider.notifier)
        .entrarOffline();

    expect(entrou, isFalse);
    expect(container.read(sessaoAbertaProvider), isFalse);
  });

  test('desbloquear com a senha de outra conta não desbloqueia', () async {
    // O e-mail enviado é o da sessão; se ainda assim o Firebase responder
    // com outra conta, a senha não é desta pessoa.
    final container = ProviderContainer(
      overrides: [
        conexaoOnlineProvider.overrideWithValue(true),
        sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
        repositorioAutenticacaoProvider.overrideWithValue(
          AutenticacaoFalsa(conta: outraConta),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(desbloqueioControladorProvider, (_, _) {});

    final desbloqueou = await container
        .read(desbloqueioControladorProvider.notifier)
        .desbloquear('senha');

    expect(desbloqueou, isFalse);
    expect(
      container.read(desbloqueioControladorProvider).erro,
      AppStrings.bloqueioSenhaNaoConfere,
    );
  });
}
