import 'amostra.dart';
import 'retomada.dart';

/// Uma sessão gravada que não foi para a análise e já não é retomada.
///
/// Fica no aparelho — o WAV no disco, o registro no banco — sem uso: a tela
/// de gravação só retoma a sessão de hoje (ver [sessaoARetomar]). É voz de
/// paciente, dado sensível pela LGPD, e não pode ficar esquecida: o
/// profissional vê, ouve, manda para a análise se estiver completa, ou
/// descarta.
class SessaoNaoEnviada {
  const SessaoNaoEnviada({required this.sessaoId, required this.amostras});

  final String sessaoId;

  /// A gravação guardada de cada tarefa.
  final Map<TarefaDeGravacao, Amostra> amostras;

  /// A primeira gravação da sessão.
  DateTime get gravadaEm => amostras.values
      .map((a) => a.gravadaEm)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  /// Todas as tarefas do protocolo, e todas válidas: dá para mandar para a
  /// análise do jeito que está.
  bool get completa =>
      TarefaDeGravacao.values.every((t) => amostras[t]?.valida ?? false);
}

/// As sessões de [amostrasDoPaciente] que não foram para a fila e não são
/// mais retomadas, da mais recente para a mais antiga.
///
/// A sessão que a gravação retomaria hoje fica de fora: ela ainda está em
/// andamento, e é na tela de gravação que se continua.
List<SessaoNaoEnviada> sessoesNaoEnviadas({
  required List<Amostra> amostrasDoPaciente,
  required Set<String> sessoesNaFila,
  required DateTime agora,
}) {
  final porSessao = <String, List<Amostra>>{};
  for (final a in amostrasDoPaciente) {
    if (sessoesNaFila.contains(a.sessaoId)) continue;
    (porSessao[a.sessaoId] ??= []).add(a);
  }
  if (porSessao.isEmpty) return const [];

  // A mais recente é a candidata a retomada; se for retomada, sai da lista.
  DateTime maisNova(List<Amostra> l) =>
      l.map((a) => a.gravadaEm).reduce((a, b) => a.isAfter(b) ? a : b);
  final ultima = porSessao.entries.reduce(
    (a, b) => maisNova(a.value).isAfter(maisNova(b.value)) ? a : b,
  );
  if (sessaoARetomar(
        ultimaSessao: ultima.value,
        sessoesNaFila: sessoesNaFila,
        agora: agora,
      ) !=
      null) {
    porSessao.remove(ultima.key);
  }

  return [
    for (final MapEntry(key: id, value: amostras) in porSessao.entries)
      SessaoNaoEnviada(
        sessaoId: id,
        amostras: {
          // Uma por tarefa: a mais nova, se houver mais de uma.
          for (final a in [
            ...amostras,
          ]..sort((x, y) => x.gravadaEm.compareTo(y.gravadaEm)))
            a.tarefa: a,
        },
      ),
  ]..sort((a, b) => b.gravadaEm.compareTo(a.gravadaEm));
}
