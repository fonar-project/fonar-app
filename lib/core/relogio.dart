import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A hora de agora, trocável nos testes.
///
/// Quem agenda coisa no tempo — a fila, com as novas tentativas — pergunta a
/// hora por aqui, e não direto ao `DateTime.now`. Assim o teste avança o
/// relógio junto com os timers, sem esperar 30 segundos de verdade.
final relogioProvider = Provider<DateTime Function()>((ref) => DateTime.now);
