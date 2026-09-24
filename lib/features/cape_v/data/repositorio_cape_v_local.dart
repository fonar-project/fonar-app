import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/banco/conversao.dart';
import '../domain/avaliacao_cape_v.dart';

final repositorioCapeVProvider = Provider<RepositorioCapeV>(
  (ref) => RepositorioCapeVLocal(ref.watch(bancoLocalProvider)),
);

/// A avaliação CAPE-V registrada para uma análise, ou `null`.
final capeVDaAnaliseProvider = FutureProvider.autoDispose
    .family<AvaliacaoCapeV?, String>(
      (ref, analiseId) =>
          ref.watch(repositorioCapeVProvider).daAnalise(analiseId),
    );

/// As avaliações CAPE-V, no banco local.
class RepositorioCapeVLocal implements RepositorioCapeV {
  RepositorioCapeVLocal(this._banco);

  final BancoLocal _banco;

  @override
  Future<AvaliacaoCapeV?> daAnalise(String analiseId) =>
      _banco.transaction(() async {
        final avaliacao = await (_banco.select(
          _banco.avaliacoesCapeV,
        )..where((a) => a.analiseId.equals(analiseId))).getSingleOrNull();
        if (avaliacao == null) return null;

        final notas = await (_banco.select(
          _banco.notasCapeV,
        )..where((n) => n.analiseId.equals(analiseId))).get();
        return AvaliacaoCapeV(
          analiseId: avaliacao.analiseId,
          pacienteId: avaliacao.pacienteId,
          registradaEm: avaliacao.registradaEm,
          comentarios: avaliacao.comentarios,
          notas: {
            for (final n in notas)
              ParametroCapeV.values.byName(n.parametro): NotaCapeV(
                valor: n.valor,
                consistencia: enumOuNulo(Consistencia.values, n.consistencia),
                direcao: enumOuNulo(DirecaoDoDesvio.values, n.direcao),
              ),
          },
        );
      });

  @override
  Future<void> registrar(AvaliacaoCapeV avaliacao) =>
      _banco.transaction(() async {
        // Substitui por inteiro: apagar a avaliação leva as notas junto.
        await (_banco.delete(
          _banco.avaliacoesCapeV,
        )..where((a) => a.analiseId.equals(avaliacao.analiseId))).go();
        await _banco
            .into(_banco.avaliacoesCapeV)
            .insert(
              AvaliacoesCapeVCompanion.insert(
                analiseId: avaliacao.analiseId,
                pacienteId: avaliacao.pacienteId,
                registradaEm: avaliacao.registradaEm,
                comentarios: avaliacao.comentarios,
              ),
            );
        for (final MapEntry(key: parametro, value: nota)
            in avaliacao.notas.entries) {
          await _banco
              .into(_banco.notasCapeV)
              .insert(
                NotasCapeVCompanion.insert(
                  analiseId: avaliacao.analiseId,
                  parametro: parametro.name,
                  valor: Value(nota.valor),
                  consistencia: Value(nota.consistencia?.name),
                  direcao: Value(nota.direcao?.name),
                ),
              );
        }
      });
}
