import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';

/// Quem já viu o guia da primeira vez (US50), neste aparelho.
///
/// Por aparelho e por conta, decisão do Matheus: no desktop a navegação é a
/// barra lateral, no celular são as abas, e vale ver o guia em cada um. Num
/// aparelho compartilhado, cada conta o vê uma vez. Nada vai ao servidor.
///
/// O `v1` na chave deixa mostrar um guia novo depois de uma atualização que
/// mude a tela inicial: o guia novo usa outra versão, e todos o veem.
class PreferenciaDoGuiaLocal {
  PreferenciaDoGuiaLocal(this._banco);

  final BancoLocal _banco;

  static String chave(String uid) => 'guia.inicio.v1.$uid';

  Future<bool> jaViu(String uid) async {
    final linha = await (_banco.select(
      _banco.preferencias,
    )..where((p) => p.chave.equals(chave(uid)))).getSingleOrNull();
    return linha != null;
  }

  /// Guarda quando foi: pular e concluir valem o mesmo.
  Future<void> marcarVisto(String uid, {DateTime? quando}) => _banco
      .into(_banco.preferencias)
      .insertOnConflictUpdate(
        PreferenciasCompanion.insert(
          chave: chave(uid),
          valor: (quando ?? DateTime.now()).toUtc().toIso8601String(),
        ),
      );
}

final preferenciaDoGuiaProvider = Provider<PreferenciaDoGuiaLocal>(
  (ref) => PreferenciaDoGuiaLocal(ref.watch(bancoLocalProvider)),
);
