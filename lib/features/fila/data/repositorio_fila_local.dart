import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../captura/data/repositorio_amostras_local.dart';
import '../../captura/domain/amostra.dart';
import '../domain/item_da_fila.dart';
import '../domain/repositorio_fila.dart';

final repositorioFilaProvider = Provider<RepositorioFila>(
  (ref) => RepositorioFilaLocal(ref.watch(bancoLocalProvider)),
);

/// A fila de envio, no banco local: sobrevive ao app fechado e ao aparelho
/// reiniciado, e a gravação feita sem rede sobe quando ela voltar.
class RepositorioFilaLocal implements RepositorioFila {
  RepositorioFilaLocal(this._banco);

  final BancoLocal _banco;

  @override
  Future<List<ItemDaFila>> listar() => _banco.transaction(() async {
    final envios = await (_banco.select(
      _banco.envios,
    )..orderBy([(e) => OrderingTerm.asc(e.posicao)])).get();

    final ligacoes = await (_banco.select(_banco.amostrasDoEnvio).join([
      innerJoin(
        _banco.amostras,
        _banco.amostras.id.equalsExp(_banco.amostrasDoEnvio.amostraId),
      ),
    ])..orderBy([OrderingTerm.asc(_banco.amostrasDoEnvio.ordem)])).get();

    final amostrasPorEnvio = <String, List<Amostra>>{};
    for (final l in ligacoes) {
      final envioId = l.readTable(_banco.amostrasDoEnvio).envioId;
      (amostrasPorEnvio[envioId] ??= []).add(
        amostraDaLinha(l.readTable(_banco.amostras)),
      );
    }

    return [
      for (final e in envios)
        ItemDaFila(
          id: e.id,
          pacienteId: e.pacienteId,
          nomeDoPaciente: e.nomeDoPaciente,
          sessaoId: e.sessaoId,
          amostras: amostrasPorEnvio[e.id] ?? const [],
          criadoEm: e.criadoEm,
          situacao: SituacaoDoEnvio.values.byName(e.situacao),
          tentativas: e.tentativas,
          proximaTentativa: e.proximaTentativa,
          ultimaFalha: e.ultimaFalha,
          analiseId: e.analiseId,
        ),
    ];
  });

  @override
  Future<void> adicionar(ItemDaFila item) => _banco.transaction(() async {
    await _banco
        .into(_banco.envios)
        .insert(
          EnviosCompanion.insert(
            id: item.id,
            pacienteId: item.pacienteId,
            nomeDoPaciente: item.nomeDoPaciente,
            sessaoId: item.sessaoId,
            criadoEm: item.criadoEm,
            situacao: item.situacao.name,
            tentativas: item.tentativas,
            proximaTentativa: Value(item.proximaTentativa),
            ultimaFalha: Value(item.ultimaFalha),
            analiseId: Value(item.analiseId),
          ),
        );
    for (final (ordem, amostra) in item.amostras.indexed) {
      // A amostra costuma já estar no banco, guardada ao ser gravada; o que
      // vale é o que o envio leva.
      await _banco
          .into(_banco.amostras)
          .insertOnConflictUpdate(linhaDaAmostra(amostra));
      await _banco
          .into(_banco.amostrasDoEnvio)
          .insert(
            AmostrasDoEnvioCompanion.insert(
              envioId: item.id,
              amostraId: amostra.id,
              ordem: ordem,
            ),
          );
    }
  });

  /// Só a situação do envio muda; as amostras de um envio são as mesmas do
  /// começo ao fim.
  @override
  Future<void> atualizar(ItemDaFila item) =>
      (_banco.update(_banco.envios)..where((e) => e.id.equals(item.id))).write(
        EnviosCompanion(
          situacao: Value(item.situacao.name),
          tentativas: Value(item.tentativas),
          proximaTentativa: Value(item.proximaTentativa),
          ultimaFalha: Value(item.ultimaFalha),
          analiseId: Value(item.analiseId),
        ),
      );
}
