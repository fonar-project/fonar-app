import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/laudo.dart';

/// TODO(drift): trocar pelo banco local.
final repositorioLaudosProvider = Provider<RepositorioLaudos>(
  (ref) => RepositorioLaudosEmMemoria(),
);

/// Os laudos de um paciente, para o perfil dele.
final laudosDoPacienteProvider = FutureProvider.autoDispose
    .family<List<Laudo>, String>(
      (ref, pacienteId) =>
          ref.watch(repositorioLaudosProvider).doPaciente(pacienteId),
    );

/// PLACEHOLDER — some ao fechar o app.
class RepositorioLaudosEmMemoria implements RepositorioLaudos {
  RepositorioLaudosEmMemoria();

  final _porAnalise = <String, Laudo>{};

  @override
  Future<Laudo?> daAnalise(String analiseId) async => _porAnalise[analiseId];

  @override
  Future<void> registrar(Laudo laudo) async =>
      _porAnalise[laudo.analiseId] = laudo;

  @override
  Future<List<Laudo>> doPaciente(String pacienteId) async => [
    for (final l in _porAnalise.values)
      if (l.pacienteId == pacienteId) l,
  ];
}
