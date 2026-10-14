import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uma operação de cada vez por chave — aqui, por sessão de gravação.
///
/// Descartar uma sessão e pô-la na fila são duas operações de várias etapas
/// (conferir, apagar arquivo, apagar registro; conferir, gravar o envio). Sem
/// trava, um envio criado entre a conferência e o descarte perderia o WAV.
/// As duas passam por aqui com a mesma chave, e uma espera a outra
/// terminar. É uma trava deste aparelho, em memória: as duas rodam no mesmo
/// processo.
class TravaPorChave {
  final _emCurso = <String, Future<void>>{};

  /// Roda [acao] quando nenhuma outra com a mesma [chave] estiver rodando.
  Future<T> executar<T>(String chave, Future<T> Function() acao) async {
    for (
      var anterior = _emCurso[chave];
      anterior != null;
      anterior = _emCurso[chave]
    ) {
      await anterior;
    }
    final fim = Completer<void>();
    _emCurso[chave] = fim.future;
    try {
      return await acao();
    } finally {
      _emCurso.remove(chave);
      fim.complete();
    }
  }
}

/// A trava das sessões de gravação, uma só no app.
final travaDasSessoesProvider = Provider<TravaPorChave>(
  (ref) => TravaPorChave(),
);
