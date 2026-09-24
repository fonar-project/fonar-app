import 'novo_paciente.dart';
import 'paciente.dart';

/// Um paciente de [existentes] que parece ser a mesma pessoa de [dados]:
/// mesmo nome — sem diferença de maiúscula, acento ou espaço — e mesma data
/// de nascimento. `null` se não houver.
///
/// Dois cadastros da mesma pessoa partem o histórico em dois: a evolução de
/// cada um mostra metade das sessões, e nenhum laudo compara tudo. Mas
/// homônimo nascido no mesmo dia existe, então o aviso não impede — pede
/// confirmação.
///
/// [ignorarId]: na correção dos dados, o próprio paciente não conta.
Paciente? possivelDuplicado(
  NovoPaciente dados,
  Iterable<Paciente> existentes, {
  String? ignorarId,
}) {
  final nome = paraComparar(dados.nome);
  final nascimento = dados.dataDeNascimento;
  for (final p in existentes) {
    if (p.id == ignorarId) continue;
    final dataDele = p.dataDeNascimento;
    if (dataDele == null) continue;
    if (dataDele.year == nascimento.year &&
        dataDele.month == nascimento.month &&
        dataDele.day == nascimento.day &&
        paraComparar(p.nome) == nome) {
      return p;
    }
  }
  return null;
}
