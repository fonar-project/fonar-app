import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/pacientes/domain/repositorio_pacientes.dart';
import 'package:fonar_app/features/pacientes/presentation/cadastro_paciente_controlador.dart';

/// Segura o cadastro até o teste soltar, e lista o que já foi cadastrado.
class _RepositorioLento implements RepositorioPacientes {
  final espera = Completer<void>();
  final _cadastrados = <Paciente>[];

  @override
  Future<List<Paciente>> listar() async => List.of(_cadastrados);

  @override
  Future<Paciente> cadastrar(NovoPaciente novo) async {
    await espera.future;
    final p = Paciente(
      id: 'p-novo',
      nome: novo.nome,
      queixa: novo.queixa,
      direcaoAvqi: DirecaoDaMedida.semComparacao,
    );
    _cadastrados.add(p);
    return p;
  }
}

void main() {
  test(
    'tela fechada no meio do salvamento: sem erro, e a lista atualiza',
    () async {
      // Achado da revisão de 23/09: a invalidação da lista usava o `ref` do
      // controlador já descartado e lançava.
      final repositorio = _RepositorioLento();
      final container = ProviderContainer(
        overrides: [
          repositorioPacientesProvider.overrideWithValue(repositorio),
        ],
      );
      addTearDown(container.dispose);
      // A lista já carregada, como estaria na tela de pacientes.
      container.listen(pacientesProvider, (_, _) {});
      expect(await container.read(pacientesProvider.future), isEmpty);

      final tela = container.listen(
        cadastroPacienteControladorProvider,
        (_, _) {},
      );
      final salvando = container
          .read(cadastroPacienteControladorProvider.notifier)
          .salvar(
            nome: 'Ana de Teste',
            nascimento: '01/01/1990',
            sexo: SexoDeReferencia.feminino,
            queixa: 'rouquidão',
          );
      // O profissional sai da tela antes de o salvamento terminar.
      tela.close();
      await container.pump();

      repositorio.espera.complete();
      await expectLater(salvando, completion(isNull));
      expect(
        (await container.read(pacientesProvider.future)).map((p) => p.nome),
        ['Ana de Teste'],
      );
    },
  );
}
