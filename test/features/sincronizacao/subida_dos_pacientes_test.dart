import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/presentation/cadastro_paciente_controlador.dart';
import 'package:fonar_app/features/sincronizacao/domain/sincronizavel.dart';
import 'package:fonar_app/features/sincronizacao/presentation/subida_dos_pacientes_controlador.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

class _Contada implements Sincronizavel {
  var vezes = 0;

  @override
  Future<int> sincronizar() async {
    vezes++;
    return 0;
  }
}

Future<void> _esperar() => Future<void>.delayed(Duration.zero);

void main() {
  // Teste de homologação de 18/10/2026: o paciente só subia com o primeiro
  // envio para a análise, e não aparecia na versão web da mesma conta.
  test('o paciente cadastrado pede a subida na hora, sem envio', () async {
    final subida = _Contada();
    final container = ProviderContainer(
      overrides: [
        bancoDeTeste(),
        conexaoOnlineProvider.overrideWithValue(true),
        sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
        subidaDosPacientesProvider.overrideWithValue(subida),
      ],
    );
    addTearDown(container.dispose);
    // Acordada, como o `FonarApp` faz: sobe o que ficou de antes.
    container.listen(subidaDosPacientesControladorProvider, (_, _) {});
    await _esperar();
    expect(subida.vezes, 1);

    container.listen(cadastroPacienteControladorProvider, (_, _) {});
    final salvo = await container
        .read(cadastroPacienteControladorProvider.notifier)
        .salvar(
          nome: 'Paciente de Teste',
          nascimento: '15/06/1990',
          sexo: SexoDeReferencia.feminino,
          queixa: 'rouquidão (teste)',
        );
    await _esperar();

    expect(salvo, isNotNull);
    expect(subida.vezes, 2);
  });

  test('sem a subida acordada (tela isolada), cadastrar não a cria', () async {
    final container = ProviderContainer(
      overrides: [
        bancoDeTeste(),
        sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
        subidaDosPacientesProvider.overrideWithValue(_Contada()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(cadastroPacienteControladorProvider, (_, _) {});

    await container
        .read(cadastroPacienteControladorProvider.notifier)
        .salvar(
          nome: 'Paciente de Teste',
          nascimento: '15/06/1990',
          sexo: SexoDeReferencia.feminino,
          queixa: '',
        );

    expect(container.exists(subidaDosPacientesControladorProvider), isFalse);
  });
}
