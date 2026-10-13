import 'amostra.dart';

/// As gravações da sessão que dá para retomar ao voltar para a gravação, por
/// tarefa — ou `null`, e começa-se uma sessão nova.
///
/// [ultimaSessao] são as gravações da sessão mais recente do paciente. Ela é
/// retomada se:
///
/// - ainda não foi para a fila ([sessoesNaFila]) — a enviada já virou análise;
/// - é do MESMO DIA de [agora]. A voz muda de um dia para o outro, e a
///   análise combina as tarefas: juntar a vogal de ontem com a fala de hoje
///   daria uma medida de voz nenhuma.
///
/// "Mesmo dia" é decisão da equipe, confirmada na US39: é a unidade que
/// separa uma consulta da outra no consultório, e a que garante que a vogal
/// e a fala combinadas na análise (o AVQI) são da mesma voz.
Map<TarefaDeGravacao, Amostra>? sessaoARetomar({
  required List<Amostra> ultimaSessao,
  required Set<String> sessoesNaFila,
  required DateTime agora,
}) {
  if (ultimaSessao.isEmpty) return null;
  final sessaoId = ultimaSessao.first.sessaoId;
  if (sessoesNaFila.contains(sessaoId)) return null;
  // TODAS do mesmo dia, e não só a última: uma sessão começada ontem não
  // vira de hoje porque uma tarefa foi regravada hoje.
  if (!ultimaSessao.every((a) => _mesmoDia(a.gravadaEm, agora))) return null;

  return {
    for (final a in ultimaSessao)
      if (a.sessaoId == sessaoId && a.valida) a.tarefa: a,
  };
}

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
