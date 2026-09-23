/// O valor de [valores] chamado [nome], ou `null` se não houver.
///
/// Para enum gravado como texto e opcional: um nome que o app não conhece
/// mais (valor removido numa versão nova) vira "não informado", e não trava a
/// leitura do registro inteiro.
T? enumOuNulo<T extends Enum>(Iterable<T> valores, String? nome) {
  if (nome == null) return null;
  for (final v in valores) {
    if (v.name == nome) return v;
  }
  return null;
}
