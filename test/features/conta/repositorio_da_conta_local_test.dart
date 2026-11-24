import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';
import 'package:fonar_app/features/cadastro/domain/cadastro.dart';
import 'package:fonar_app/features/conta/data/repositorio_da_conta_local.dart';

import '../../apoio/banco_em_memoria.dart';

/// A cópia do perfil no aparelho guarda também a situação do credenciamento
/// (US62): é ela que deixa o profissional credenciado emitir laudo sem rede.
void main() {
  test('guarda e devolve a situação do credenciamento', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final repositorio = RepositorioDaContaLocal(banco);

    await repositorio.salvar(
      'uid-1',
      const Profissional(
        nome: 'Ana Souza',
        registro: 'CRFa 2-12345',
        credenciamento: Credenciamento.credenciado,
      ),
    );

    final lido = await repositorio.perfil('uid-1');
    expect(lido?.nome, 'Ana Souza');
    expect(lido?.registro, 'CRFa 2-12345');
    expect(lido?.credenciamento, Credenciamento.credenciado);
  });

  test('sem situação conhecida, devolve nula — ninguém conferiu', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final repositorio = RepositorioDaContaLocal(banco);

    await repositorio.salvar(
      'uid-1',
      const Profissional(nome: 'Ana Souza', registro: 'CRFa 2-12345'),
    );

    expect((await repositorio.perfil('uid-1'))?.credenciamento, isNull);
  });
}
