import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analise/data/repositorio_analises_placeholder.dart';
import '../../laudo/data/repositorio_laudos_local.dart';
import '../../pacientes/data/repositorio_pacientes_local.dart';
import '../domain/entrada_do_historico.dart';

/// Todas as avaliações de todos os pacientes deste aparelho, na ordem do
/// histórico — ver [montarHistorico].
///
/// Pergunta paciente por paciente, em paralelo.
/// TODO(backend): com a API, uma consulta só (`GET /analises`, paginada).
final historicoProvider = FutureProvider.autoDispose<List<EntradaDoHistorico>>((
  ref,
) async {
  final pacientes = await ref.watch(pacientesProvider.future);
  final analises = ref.watch(repositorioAnalisesProvider);
  final laudos = ref.watch(repositorioLaudosProvider);

  // As duas levas em paralelo, e cada uma paciente por paciente também.
  final (analisesDe, laudosDe) = await (
    Future.wait([for (final p in pacientes) analises.doPaciente(p.id)]),
    Future.wait([for (final p in pacientes) laudos.doPaciente(p.id)]),
  ).wait;

  return montarHistorico([
    for (final (i, paciente) in pacientes.indexed)
      for (final analise in analisesDe[i])
        EntradaDoHistorico(
          paciente: paciente,
          analise: analise,
          temLaudo: laudosDe[i].any((l) => l.analiseId == analise.id),
        ),
  ]);
});

/// O que está digitado na busca do histórico.
class BuscaDoHistorico extends Notifier<String> {
  @override
  String build() => '';

  void digitar(String termo) => state = termo;
}

final buscaDoHistoricoProvider =
    NotifierProvider.autoDispose<BuscaDoHistorico, String>(
      BuscaDoHistorico.new,
    );
