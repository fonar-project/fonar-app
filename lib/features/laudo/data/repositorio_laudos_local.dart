import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../domain/laudo.dart';

final repositorioLaudosProvider = Provider<RepositorioLaudos>(
  (ref) => RepositorioLaudosLocal(ref.watch(bancoLocalProvider)),
);

/// Os laudos vigentes de um paciente, para o perfil dele.
final laudosDoPacienteProvider = FutureProvider.autoDispose
    .family<List<Laudo>, String>(
      (ref, pacienteId) =>
          ref.watch(repositorioLaudosProvider).doPaciente(pacienteId),
    );

/// Os laudos, no banco local — com o PDF como foi gerado.
///
/// Só se acrescenta (US38, ADR-018 da API): [registrar] é uma inserção
/// simples, e código repetido falha no banco em vez de sobrescrever. O
/// único dado que muda depois é a hora em que a cópia chegou à API
/// ([marcarEnviado]) — que não é o documento.
class RepositorioLaudosLocal implements RepositorioLaudos {
  RepositorioLaudosLocal(this._banco);

  final BancoLocal _banco;

  SimpleSelectStatement<$LaudosTable, LinhaDoLaudo> _daAnalise(
    String analiseId,
  ) => _banco.select(_banco.laudos)
    ..where((l) => l.analiseId.equals(analiseId))
    // O mais recente primeiro; o id desempata duas emissões no mesmo instante.
    ..orderBy([
      (l) => OrderingTerm.desc(l.geradoEm),
      (l) => OrderingTerm.desc(l.id),
    ]);

  @override
  Future<Laudo?> daAnalise(String analiseId) async {
    final linha = await (_daAnalise(analiseId)..limit(1)).getSingleOrNull();
    return linha == null ? null : _laudo(linha);
  }

  @override
  Future<List<Laudo>> emitidosDaAnalise(String analiseId) async => [
    for (final l in await _daAnalise(analiseId).get()) _laudo(l),
  ];

  @override
  Future<void> registrar(Laudo laudo) => _banco
      .into(_banco.laudos)
      .insert(
        LaudosCompanion.insert(
          id: laudo.id,
          analiseId: laudo.analiseId,
          pacienteId: laudo.pacienteId,
          conclusao: laudo.conclusao,
          geradoEm: laudo.geradoEm,
          pdf: laudo.pdf,
          substitui: Value(laudo.substitui),
          enviadoEm: Value(laudo.enviadoEm),
        ),
      );

  @override
  Future<List<Laudo>> doPaciente(String pacienteId) async {
    final linhas =
        await (_banco.select(_banco.laudos)
              ..where((l) => l.pacienteId.equals(pacienteId))
              ..orderBy([
                (l) => OrderingTerm.asc(l.geradoEm),
                (l) => OrderingTerm.asc(l.id),
              ]))
            .get();
    // Do mais antigo ao mais recente: o último de cada análise fica.
    final vigentes = <String, Laudo>{};
    for (final l in linhas) {
      vigentes[l.analiseId] = _laudo(l);
    }
    return vigentes.values.toList();
  }

  /// Registra que a cópia do laudo [id] chegou à API.
  Future<void> marcarEnviado(String id, DateTime em) =>
      (_banco.update(_banco.laudos)..where((l) => l.id.equals(id))).write(
        LaudosCompanion(enviadoEm: Value(em)),
      );

  static Laudo _laudo(LinhaDoLaudo l) => Laudo(
    id: l.id,
    analiseId: l.analiseId,
    pacienteId: l.pacienteId,
    conclusao: l.conclusao,
    geradoEm: l.geradoEm,
    pdf: l.pdf,
    substitui: l.substitui,
    enviadoEm: l.enviadoEm,
  );
}
