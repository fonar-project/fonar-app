import 'dart:math';

final _aleatorio = Random.secure();

/// Id novo, gerado no aparelho: UUID versão 4 (RFC 9562), aleatório.
///
/// Gerado aqui, e não por um contador do banco, porque o registro nasce
/// offline e sobe depois — dois aparelhos do mesmo profissional não podem
/// produzir o mesmo id.
String novoId() {
  final bytes = List<int>.generate(16, (_) => _aleatorio.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versão 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return [
    hex.sublist(0, 4).join(),
    hex.sublist(4, 6).join(),
    hex.sublist(6, 8).join(),
    hex.sublist(8, 10).join(),
    hex.sublist(10).join(),
  ].join('-');
}
