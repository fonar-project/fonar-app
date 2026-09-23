import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../domain/laudo.dart';

final repositorioLaudosProvider = Provider<RepositorioLaudos>(
  (ref) => RepositorioLaudosLocal(ref.watch(bancoLocalProvider)),
);

/// Os laudos de um paciente, para o perfil dele.
final laudosDoPacienteProvider = FutureProvider.autoDispose
    .family<List<Laudo>, String>(
      (ref, pacienteId) =>
          ref.watch(repositorioLaudosProvider).doPaciente(pacienteId),
    );

/// Os laudos, no banco local — com o PDF como foi gerado.
class RepositorioLaudosLocal implements RepositorioLaudos {
  RepositorioLaudosLocal(this._banco);

  final BancoLocal _banco;

  @override
  Future<Laudo?> daAnalise(String analiseId) async {
    final linha = await (_banco.select(
      _banco.laudos,
    )..where((l) => l.analiseId.equals(analiseId))).getSingleOrNull();
    return linha == null ? null : _laudo(linha);
  }

  @override
  Future<void> registrar(Laudo laudo) => _banco
      .into(_banco.laudos)
      .insertOnConflictUpdate(
        LaudosCompanion.insert(
          analiseId: laudo.analiseId,
          pacienteId: laudo.pacienteId,
          conclusao: laudo.conclusao,
          geradoEm: laudo.geradoEm,
          pdf: laudo.pdf,
        ),
      );

  @override
  Future<List<Laudo>> doPaciente(String pacienteId) async {
    final linhas = await (_banco.select(
      _banco.laudos,
    )..where((l) => l.pacienteId.equals(pacienteId))).get();
    return [for (final l in linhas) _laudo(l)];
  }

  Laudo _laudo(LinhaDoLaudo l) => Laudo(
    analiseId: l.analiseId,
    pacienteId: l.pacienteId,
    conclusao: l.conclusao,
    geradoEm: l.geradoEm,
    pdf: l.pdf,
  );
}
