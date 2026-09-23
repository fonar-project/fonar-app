/// Profissional autenticado.
class Profissional {
  const Profissional({
    required this.nome,
    required this.registro,
    this.email = '',
  });

  /// Como assina — vai impresso no laudo.
  final String nome;

  /// Registro no conselho, ex.: "CRFa 2-12345". Também vai no laudo.
  final String registro;

  /// O e-mail da conta. Vem da autenticação e não se edita aqui.
  final String email;
}
