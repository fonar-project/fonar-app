import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/laudo.dart';

/// TODO(drift): trocar pelo banco local.
final repositorioLaudosProvider = Provider<RepositorioLaudos>(
  (ref) => RepositorioLaudosEmMemoria(),
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
}
