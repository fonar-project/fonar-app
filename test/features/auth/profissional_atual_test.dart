import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/auth/data/profissional_atual.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/cadastro/data/cadastro_api.dart';
import 'package:fonar_app/features/cadastro/domain/cadastro.dart';
import 'package:fonar_app/features/conta/data/repositorio_da_conta_local.dart';

import '../../apoio/sessao_de_teste.dart';

/// A equipe credencia por fora, com o app aberto (US62): consultar a API de
/// novo libera o laudo sem fechar e abrir o app.
void main() {
  test('credenciado com o app aberto: atualizar libera o laudo', () async {
    final api = _ApiFalsa();
    final perfis = PerfilEmMemoria();
    final container = ProviderContainer(
      overrides: [
        sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
        cadastroApiProvider.overrideWithValue(api),
        repositorioDaContaProvider.overrideWithValue(perfis),
      ],
    );
    addTearDown(container.dispose);

    container.read(profissionalAtualProvider);
    await container.read(profissionalAtualProvider.notifier).atualizarDaApi();
    expect(container.read(inscricaoConferidaProvider), isFalse);

    api.credenciamento = Credenciamento.credenciado;
    await container.read(profissionalAtualProvider.notifier).atualizarDaApi();

    expect(container.read(inscricaoConferidaProvider), isTrue);
    // E fica no aparelho, para o laudo sair sem rede.
    expect(
      perfis.perfis[contaDeTeste.uid]?.credenciamento,
      Credenciamento.credenciado,
    );
  });

  test('sem sessão, atualizar não consulta a API', () async {
    final api = _ApiFalsa();
    final container = ProviderContainer(
      overrides: [
        cadastroApiProvider.overrideWithValue(api),
        repositorioDaContaProvider.overrideWithValue(PerfilEmMemoria()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(profissionalAtualProvider.notifier).atualizarDaApi();

    expect(api.consultas, 0);
  });
}

/// A API do cadastro, respondendo com a situação que o teste escolher.
class _ApiFalsa extends CadastroApi {
  _ApiFalsa() : super(Dio());

  var credenciamento = Credenciamento.pendente;
  var consultas = 0;

  @override
  Future<SituacaoDoCadastro> situacao() async {
    consultas++;
    return Cadastrado(
      PerfilProfissional(
        email: contaDeTeste.email,
        credenciamento: credenciamento,
        completo: true,
        nome: 'Fon.ª Teste',
        registro: 'CRFa 2-12345',
      ),
    );
  }
}
