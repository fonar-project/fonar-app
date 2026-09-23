import 'verificacao_da_amostra.dart';

/// Uma tarefa do protocolo de gravação.
///
/// TODO(clínico): as tarefas, a ordem e as instruções ao paciente são do
/// protocolo clínico e precisam ser confirmadas pela orientação. As duas de
/// hoje são as que o AVQI combina — vogal sustentada e fala encadeada —, com
/// instruções PROVISÓRIAS em `app_strings.dart`.
enum TarefaDeGravacao { vogalSustentada, falaEncadeada }

/// Uma gravação conferida e guardada no aparelho.
///
/// Áudio de voz vinculado a paciente é dado pessoal sensível (LGPD): o
/// arquivo fica na área privada do aplicativo, e só sai dela pela fila de
/// sincronização.
class Amostra {
  const Amostra({
    required this.id,
    required this.pacienteId,
    required this.sessaoId,
    required this.tarefa,
    required this.caminho,
    required this.gravadaEm,
    required this.duracao,
    required this.taxaDeAmostragem,
    required this.canais,
    required this.problemas,
  });

  final String id;
  final String pacienteId;

  /// A consulta em que foi gravada. O paciente volta em outras consultas e
  /// grava as mesmas tarefas; é a sessão que separa uma da outra — e é ela que
  /// o histórico compara.
  final String sessaoId;
  final TarefaDeGravacao tarefa;

  /// Arquivo WAV no aparelho.
  final String caminho;
  final DateTime gravadaEm;

  /// O formato CONFERIDO no arquivo, não o pedido.
  final Duration duracao;
  final int taxaDeAmostragem;
  final int canais;

  /// O que a conferência encontrou. Vazio é amostra sem ressalva.
  final List<ProblemaNaAmostra> problemas;

  bool get valida => !problemas.any((p) => p.invalida);
}
