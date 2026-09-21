/// Profissional autenticado.
class Profissional {
  const Profissional({required this.nome, required this.registro});

  final String nome;

  /// Registro no conselho, ex.: "CRFa 2-12345".
  final String registro;
}
