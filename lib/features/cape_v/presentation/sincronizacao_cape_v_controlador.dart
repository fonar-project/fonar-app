import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/conexao.dart';
import '../../auth/data/sessao.dart';
import '../data/cape_v_no_firestore.dart';

/// Sobe a CAPE-V para o Firebase sem ninguém olhando, como a fila faz com as
/// gravações.
///
/// Não é `autoDispose` de propósito: quem o acorda na abertura do app, e o
/// mantém vivo, é o `FonarApp`. Tenta na abertura, quando a conexão volta,
/// quando alguém entra e depois de cada avaliação registrada ([pedir]). Sem
/// rede ou sem sessão, nada. Falha não se repete sozinha: a avaliação está
/// guardada no aparelho, e a próxima ocasião tenta de novo.
class SincronizacaoCapeVControlador extends Notifier<void> {
  var _rodando = false;
  var _deNovo = false;

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
  /// a avaliação registrada no meio não espera a próxima ocasião.
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
        final sincronizacao = ref.read(sincronizacaoDaCapeVProvider);
        if (sincronizacao == null ||
            !ref.read(conexaoOnlineProvider) ||
            !ref.read(sessaoAbertaProvider)) {
          return;
        }
        try {
          await sincronizacao.sincronizar();
        } catch (_) {
          // O contrato é lançar só AppException, e nenhuma delas perde nada:
          // a avaliação continua no aparelho e sobe na próxima ocasião.
        }
      } while (_deNovo);
    } finally {
      _rodando = false;
    }
  }
}

final sincronizacaoCapeVControladorProvider =
    NotifierProvider<SincronizacaoCapeVControlador, void>(
      SincronizacaoCapeVControlador.new,
    );
