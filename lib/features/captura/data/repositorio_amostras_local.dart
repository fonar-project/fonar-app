import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/banco/conversao.dart';
import '../domain/amostra.dart';
import '../domain/gravador.dart';
import '../domain/verificacao_da_amostra.dart';

final repositorioAmostrasProvider = Provider<RepositorioAmostras>(
  (ref) => RepositorioAmostrasLocal(ref.watch(bancoLocalProvider)),
);

/// O registro das gravações, no banco local. Os arquivos WAV ficam no disco,
/// na área privada do aplicativo; aqui fica onde cada um está.
class RepositorioAmostrasLocal implements RepositorioAmostras {
  RepositorioAmostrasLocal(this._banco);

  final BancoLocal _banco;

  @override
  Future<List<Amostra>> daSessao(String sessaoId) async {
    final linhas =
        await (_banco.select(_banco.amostras)
              ..where((a) => a.sessaoId.equals(sessaoId))
              ..orderBy([(a) => OrderingTerm.asc(a.gravadaEm)]))
            .get();
    return [for (final l in linhas) amostraDaLinha(l)];
  }

  @override
  Future<List<Amostra>> ultimaSessao(String pacienteId) async {
    final maisNova =
        await (_banco.select(_banco.amostras)
              ..where((a) => a.pacienteId.equals(pacienteId))
              ..orderBy([(a) => OrderingTerm.desc(a.gravadaEm)])
              ..limit(1))
            .getSingleOrNull();
    return maisNova == null ? const [] : daSessao(maisNova.sessaoId);
  }

  @override
  Future<List<Amostra>> doPaciente(String pacienteId) async {
    final linhas =
        await (_banco.select(_banco.amostras)
              ..where((a) => a.pacienteId.equals(pacienteId))
              ..orderBy([(a) => OrderingTerm.asc(a.gravadaEm)]))
            .get();
    return [for (final l in linhas) amostraDaLinha(l)];
  }

  @override
  Future<bool> estaNumEnvio(String sessaoId) async {
    final noEnvio =
        await (_banco.select(_banco.amostrasDoEnvio).join([
                innerJoin(
                  _banco.amostras,
                  _banco.amostras.id.equalsExp(
                    _banco.amostrasDoEnvio.amostraId,
                  ),
                ),
              ])
              ..where(_banco.amostras.sessaoId.equals(sessaoId))
              ..limit(1))
            .getSingleOrNull();
    return noEnvio != null;
  }

  /// A chave estrangeira de `AmostrasDoEnvio` recusa apagar gravação que já
  /// está num envio — e a transação desfaz o resto da sessão junto.
  @override
  Future<void> descartarSessao(String sessaoId) => _banco.transaction(
    () => (_banco.delete(
      _banco.amostras,
    )..where((a) => a.sessaoId.equals(sessaoId))).go(),
  );

  @override
  Future<void> guardar(Amostra amostra) => _banco.transaction(() async {
    await (_banco.delete(_banco.amostras)..where(
          (a) =>
              a.sessaoId.equals(amostra.sessaoId) &
              a.tarefa.equals(amostra.tarefa.name) &
              a.id.equals(amostra.id).not(),
        ))
        .go();
    await _banco
        .into(_banco.amostras)
        .insertOnConflictUpdate(linhaDaAmostra(amostra));
  });
}

/// A amostra como ela vai para o banco.
AmostrasCompanion linhaDaAmostra(Amostra a) => AmostrasCompanion.insert(
  id: a.id,
  pacienteId: a.pacienteId,
  sessaoId: a.sessaoId,
  tarefa: a.tarefa.name,
  caminho: a.caminho,
  gravadaEm: a.gravadaEm,
  duracaoEmMs: a.duracao.inMilliseconds,
  taxaDeAmostragem: a.taxaDeAmostragem,
  canais: a.canais,
  problemas: [for (final p in a.problemas) p.name].join(','),
);

/// A amostra como ela volta do banco.
///
/// Um problema de nome desconhecido (removido numa versão nova do app) é
/// deixado de fora — mas a amostra que o tinha continua na lista.
Amostra amostraDaLinha(LinhaDaAmostra l) => Amostra(
  id: l.id,
  pacienteId: l.pacienteId,
  sessaoId: l.sessaoId,
  tarefa: TarefaDeGravacao.values.byName(l.tarefa),
  caminho: l.caminho,
  gravadaEm: l.gravadaEm,
  duracao: Duration(milliseconds: l.duracaoEmMs),
  taxaDeAmostragem: l.taxaDeAmostragem,
  canais: l.canais,
  problemas: [
    for (final nome in l.problemas.split(','))
      ?enumOuNulo(ProblemaNaAmostra.values, nome),
  ],
);
