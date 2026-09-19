import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profissional.dart';

/// PLACEHOLDER — profissional fictício, marcado "(exemplo)".
///
/// TODO(auth): vir da sessão do Firebase Auth.
final profissionalAtualProvider = Provider<Profissional>(
  (ref) => const Profissional(
    nome: 'Fon.ª Exemplo da Silva',
    registro: 'CRFa 0-00000 (exemplo)',
  ),
);
