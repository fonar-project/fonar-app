/// Quem a autenticação reconheceu: o id da conta e o e-mail dela.
///
/// Só o que identifica. Os tokens ficam na camada de dados (`Credencial`):
/// tela nenhuma precisa deles.
class ContaAutenticada {
  const ContaAutenticada({required this.uid, required this.email});

  /// O id da conta no Firebase. Cada envio da fila leva o de quem gravou.
  final String uid;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is ContaAutenticada && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);

  @override
  String toString() => 'ContaAutenticada($uid, $email)';
}
