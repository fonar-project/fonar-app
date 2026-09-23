import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_placeholder.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/domain/repositorio_consentimento.dart';
import 'package:fonar_app/features/consentimento/presentation/registro_consentimento_controlador.dart';

/// Segura o registro até o teste soltar.
class _RepositorioLento implements RepositorioConsentimento {
  final espera = Completer<void>();
  Consentimento? _registrado;

  @override
  Future<Consentimento?> buscar(String pacienteId) async => _registrado;

  @override
  Future<Consentimento> registrar(
    String pacienteId,
    PedidoDeConsentimento pedido,
  ) async {
    await espera.future;
    return _registrado = Consentimento(
      pacienteId: pacienteId,
      registradoEm: DateTime(2026, 9, 23),
      versaoDoTermo: 'teste',
      quemAutoriza: pedido.quemAutoriza,
    );
  }
}

void main() {
  test(
    'tela fechada no meio do registro: sem erro, e o bloqueio cai',
    () async {
      // Achado da revisão de 23/09: a invalidação usava o `ref` já descartado.
      final repositorio = _RepositorioLento();
      final container = ProviderContainer(
        overrides: [
          repositorioConsentimentoProvider.overrideWithValue(repositorio),
        ],
      );
      addTearDown(container.dispose);
      container.listen(consentimentoProvider('p1'), (_, _) {});
      expect(await container.read(consentimentoProvider('p1').future), isNull);

      final tela = container.listen(
        registroConsentimentoProvider('p1'),
        (_, _) {},
      );
      final registrando = container
          .read(registroConsentimentoProvider('p1').notifier)
          .registrar(
            quemAutoriza: QuemAutoriza.paciente,
            nomeDoResponsavel: '',
            concordou: true,
          );
      tela.close();
      await container.pump();

      repositorio.espera.complete();
      await expectLater(registrando, completion(isFalse));
      expect(
        await container.read(consentimentoProvider('p1').future),
        isNotNull,
      );
    },
  );
}
