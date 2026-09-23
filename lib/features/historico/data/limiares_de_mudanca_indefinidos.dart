import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/evolucao_da_medida.dart';
import '../domain/serie_da_medida.dart';

/// TODO(clínico): trocar pelos limiares validados quando existirem.
final limiaresDeMudancaProvider = Provider<LimiaresDeMudanca>(
  (ref) => const LimiaresDeMudancaIndefinidos(),
);

/// Nenhum limiar de mudança — de propósito, como o catálogo de faixas vazio.
///
/// Qual diferença entre sessões conta como mudança real é pendência clínica
/// aberta, e nenhum valor foi validado. Até ele chegar, a evolução mostra os
/// valores e o gráfico, e não diz que a medida subiu, desceu ou ficou estável:
/// sem limiar, qualquer diferença de segunda casa decimal viraria "mudou".
class LimiaresDeMudancaIndefinidos implements LimiaresDeMudanca {
  const LimiaresDeMudancaIndefinidos();

  @override
  double? limiar(MedidaAcustica medida) => null;
}
