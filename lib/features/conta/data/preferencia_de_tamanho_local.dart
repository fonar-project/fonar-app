import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../design_system/escala_da_interface.dart';

/// Onde o tamanho da interface (US48) fica guardado: no banco local, na
/// tabela de preferências do aparelho, como o tema.
class PreferenciaDeTamanhoLocal {
  PreferenciaDeTamanhoLocal(this._banco);

  final BancoLocal _banco;

  static const _chave = 'tamanhoDaInterface';

  /// O tamanho guardado, ou [TamanhoDaInterface.automatico] se não houver —
  /// ou se o valor gravado não for um tamanho conhecido.
  Future<TamanhoDaInterface> ler() async {
    final linha = await (_banco.select(
      _banco.preferencias,
    )..where((p) => p.chave.equals(_chave))).getSingleOrNull();
    return TamanhoDaInterface.values.asNameMap()[linha?.valor] ??
        TamanhoDaInterface.automatico;
  }

  Future<void> guardar(TamanhoDaInterface tamanho) => _banco
      .into(_banco.preferencias)
      .insertOnConflictUpdate(
        PreferenciasCompanion.insert(chave: _chave, valor: tamanho.name),
      );
}

final preferenciaDeTamanhoProvider = Provider<PreferenciaDeTamanhoLocal>(
  (ref) => PreferenciaDeTamanhoLocal(ref.watch(bancoLocalProvider)),
);

/// O tamanho da interface escolhido, carregado do aparelho.
///
/// Enquanto carrega — e se o banco falhar —, vale o automático: a escolha é
/// conforto, e nunca deve impedir o aplicativo de abrir.
class TamanhoDaInterfaceControlador extends AsyncNotifier<TamanhoDaInterface> {
  @override
  Future<TamanhoDaInterface> build() async {
    try {
      return await ref.read(preferenciaDeTamanhoProvider).ler();
    } catch (erro) {
      debugPrint('Preferência de tamanho indisponível: $erro');
      return TamanhoDaInterface.automatico;
    }
  }

  /// Aplica na hora e guarda. Se guardar falhar, a escolha vale até o app
  /// fechar.
  Future<void> escolher(TamanhoDaInterface tamanho) async {
    state = AsyncData(tamanho);
    try {
      await ref.read(preferenciaDeTamanhoProvider).guardar(tamanho);
    } catch (erro) {
      debugPrint('Não foi possível guardar o tamanho: $erro');
    }
  }
}

final tamanhoDaInterfaceProvider =
    AsyncNotifierProvider<TamanhoDaInterfaceControlador, TamanhoDaInterface>(
      TamanhoDaInterfaceControlador.new,
    );
