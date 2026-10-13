import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/conexao.dart';
import '../../auth/data/sessao.dart';
import '../domain/sincronizavel.dart';

/// Sobe algo para o servidor sem ninguém olhando, como a fila faz com as
/// gravações — a CAPE-V e os laudos emitidos.
///
/// Não é `autoDispose` de propósito: quem acorda cada sincronização na
/// abertura do app, e a mantém viva, é o `FonarApp`. Tenta na abertura,
/// quando a conexão volta, quando alguém entra e sempre que alguém pede
/// ([pedir]) — logo depois de um registro, por exemplo. Sem rede ou sem
/// sessão, nada. Falha não se repete sozinha: o que não subiu está guardado
/// no aparelho, e a próxima ocasião tenta de novo.
abstract class SincronizacaoEmSegundoPlano extends Notifier<void> {
  var _rodando = false;
  var _deNovo = false;

  /// Quem sobe, ou `null` quando não há para onde (modo de exemplo).
  Sincronizavel? get alvo;

  @override
  void build() {
    ref.listen(conexaoOnlineProvider, (antes, online) {
      if (online && antes != true) pedir();
    });
    ref.listen(sessaoProvider, (antes, conta) {
      if (conta != null && antes?.uid != conta.uid) pedir();
    });
    // Depois de o provider existir: o que ficou de antes sobe já.
    Future.microtask(pedir);
  }

  /// Pede uma sincronização. Pedida durante outra, roda de novo no fim —
  /// o registro feito no meio não espera a próxima ocasião.
  void pedir() => unawaited(_rodar());

  Future<void> _rodar() async {
    if (_rodando) {
      _deNovo = true;
      return;
    }
    _rodando = true;
    try {
      do {
        _deNovo = false;
        if (!ref.mounted) return;
        final alvo = this.alvo;
        // A sessão é lida na fonte, e não pelo `sessaoAbertaProvider`: o
        // pedido de quem acabou de entrar roda dentro do ouvinte da
        // `sessaoProvider`, quando o derivado ainda tem o valor de antes.
        if (alvo == null ||
            !ref.read(conexaoOnlineProvider) ||
            ref.read(sessaoProvider) == null) {
          return;
        }
        try {
          await alvo.sincronizar();
        } catch (_) {
          // O contrato é lançar só AppException, e nenhuma delas perde nada:
          // o que não subiu continua no aparelho e sobe na próxima ocasião.
        }
      } while (_deNovo);
    } finally {
      _rodando = false;
    }
  }
}
