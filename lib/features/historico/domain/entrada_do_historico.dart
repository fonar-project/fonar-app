import '../../analise/domain/resultado_da_analise.dart';
import '../../pacientes/domain/paciente.dart';

/// Uma avaliação no histórico geral: de quem é, o resultado, e se já tem
/// laudo.
class EntradaDoHistorico {
  const EntradaDoHistorico({
    required this.paciente,
    required this.analise,
    required this.temLaudo,
  });

  final Paciente paciente;
  final ResultadoDaAnalise analise;
  final bool temLaudo;
}

/// As avaliações de todos os pacientes, da mais recente para a mais antiga,
/// só as de quem corresponde a [termo] (ver [Paciente.correspondeA]).
///
/// Análise ainda sem data — a que o servidor está processando — vem no topo:
/// é a mais nova de todas, e a que o profissional está esperando.
List<EntradaDoHistorico> montarHistorico(
  Iterable<EntradaDoHistorico> entradas, {
  String termo = '',
}) =>
    [
      for (final e in entradas)
        if (e.paciente.correspondeA(termo)) e,
    ]..sort((a, b) {
      final da = a.analise.realizadaEm;
      final db = b.analise.realizadaEm;
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return db.compareTo(da);
    });
