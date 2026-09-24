import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/auth/data/repositorio_autenticacao_placeholder.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/domain/repositorio_autenticacao.dart';
import 'package:fonar_app/features/auth/presentation/login_controlador.dart';

class _Aceita implements RepositorioAutenticacao {
  @override
  Future<void> entrar({required String email, required String senha}) async {}
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [repositorioAutenticacaoProvider.overrideWithValue(_Aceita())],
  );
  addTearDown(container.dispose);
  container.listen(loginControladorProvider, (_, _) {});
  return container;
}

void main() {
  test('começa fechada: sem login, a fila não envia', () {
    expect(_container().read(sessaoAbertaProvider), isFalse);
  });

  test('entrar abre a sessão', () async {
    final container = _container();
    final entrou = await container
        .read(loginControladorProvider.notifier)
        .entrar(email: 'fono@exemplo.com', senha: 'senha');

    expect(entrou, isTrue);
    expect(container.read(sessaoAbertaProvider), isTrue);
  });

  test('campos vazios não abrem a sessão', () async {
    final container = _container();
    await container
        .read(loginControladorProvider.notifier)
        .entrar(email: '', senha: '');

    expect(container.read(sessaoAbertaProvider), isFalse);
  });

  test('entrar em modo offline também abre', () {
    final container = _container();
    container.read(loginControladorProvider.notifier).entrarOffline();

    expect(container.read(sessaoAbertaProvider), isTrue);
  });
}
