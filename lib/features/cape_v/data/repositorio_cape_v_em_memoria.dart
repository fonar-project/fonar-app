import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/avaliacao_cape_v.dart';

/// TODO(drift): trocar pelo banco local.
final repositorioCapeVProvider = Provider<RepositorioCapeV>(
  (ref) => RepositorioCapeVEmMemoria(),
);

/// A avaliação CAPE-V registrada para uma análise, ou `null`.
final capeVDaAnaliseProvider = FutureProvider.autoDispose
    .family<AvaliacaoCapeV?, String>(
      (ref, analiseId) =>
          ref.watch(repositorioCapeVProvider).daAnalise(analiseId),
    );

/// PLACEHOLDER — some ao fechar o app.
class RepositorioCapeVEmMemoria implements RepositorioCapeV {
  RepositorioCapeVEmMemoria();

  final _porAnalise = <String, AvaliacaoCapeV>{};

  @override
  Future<AvaliacaoCapeV?> daAnalise(String analiseId) async =>
      _porAnalise[analiseId];

  @override
  Future<void> registrar(AvaliacaoCapeV avaliacao) async =>
      _porAnalise[avaliacao.analiseId] = avaliacao;
}
