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
  const SessaoNaoEnviada({
    required this.sessaoId,
    required this.amostras,
    this.semArquivo = const {},
  });

  final String sessaoId;

  /// A gravação guardada de cada tarefa.
  final Map<TarefaDeGravacao, Amostra> amostras;

  /// Tarefas cujo registro existe mas o WAV não está mais no disco — um
  /// descarte que apagou parte dos arquivos e falhou no meio, por exemplo.
  final Set<TarefaDeGravacao> semArquivo;

  SessaoNaoEnviada comArquivosFaltando(Set<TarefaDeGravacao> faltando) =>
      SessaoNaoEnviada(
        sessaoId: sessaoId,
        amostras: amostras,
        semArquivo: faltando,
      );

  /// A primeira gravação da sessão.
  DateTime get gravadaEm => amostras.values
      .map((a) => a.gravadaEm)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  /// Todas as tarefas do protocolo, todas válidas e com o arquivo no disco:
  /// dá para mandar para a análise do jeito que está.
  bool get completa => TarefaDeGravacao.values.every(
    (t) => (amostras[t]?.valida ?? false) && !semArquivo.contains(t),
  );
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
  if (amostrasDoPaciente.isEmpty) return const [];

  // A candidata a retomada é escolhida como a gravação escolhe (ver
  // `RepositorioAmostras.ultimaSessao`): a sessão da gravação mais nova,
  // ENTRE TODAS — inclusive as que já foram para a fila. Escolher só entre
  // as não enviadas escondia daqui uma sessão que a gravação não retoma, e
  // ela não aparecia em lugar nenhum (revisão de 24/09).
  final maisNova = amostrasDoPaciente.reduce(
    (a, b) => b.gravadaEm.isAfter(a.gravadaEm) ? b : a,
  );
  final retomada =
      sessaoARetomar(
            ultimaSessao: [
              for (final a in amostrasDoPaciente)
                if (a.sessaoId == maisNova.sessaoId) a,
            ],
            sessoesNaFila: sessoesNaFila,
            agora: agora,
          ) ==
          null
      ? null
      : maisNova.sessaoId;

  final porSessao = <String, List<Amostra>>{};
  for (final a in amostrasDoPaciente) {
    if (sessoesNaFila.contains(a.sessaoId) || a.sessaoId == retomada) {
      continue;
    }
    (porSessao[a.sessaoId] ??= []).add(a);
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
