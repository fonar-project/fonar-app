import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../domain/tema_escolhido.dart';

/// Onde a escolha do tema fica guardada: no banco local, na tabela de
/// preferências do aparelho.
class PreferenciaDeTemaLocal {
  PreferenciaDeTemaLocal(this._banco);

  final BancoLocal _banco;

  static const _chave = 'tema';

  /// A escolha guardada, ou [TemaEscolhido.sistema] se não houver — ou se o
  /// valor gravado não for um tema conhecido.
  Future<TemaEscolhido> ler() async {
    final linha = await (_banco.select(
      _banco.preferencias,
    )..where((p) => p.chave.equals(_chave))).getSingleOrNull();
    return TemaEscolhido.values.asNameMap()[linha?.valor] ??
        TemaEscolhido.sistema;
  }

  Future<void> guardar(TemaEscolhido tema) => _banco
      .into(_banco.preferencias)
      .insertOnConflictUpdate(
        PreferenciasCompanion.insert(chave: _chave, valor: tema.name),
      );
}

final preferenciaDeTemaProvider = Provider<PreferenciaDeTemaLocal>(
  (ref) => PreferenciaDeTemaLocal(ref.watch(bancoLocalProvider)),
);

/// O tema escolhido, carregado do aparelho.
///
/// Enquanto carrega — e se o banco falhar —, vale o do sistema: a escolha é
/// conforto, e nunca deve impedir o aplicativo de abrir.
class TemaEscolhidoControlador extends AsyncNotifier<TemaEscolhido> {
  @override
  Future<TemaEscolhido> build() async {
    try {
      return await ref.read(preferenciaDeTemaProvider).ler();
    } catch (erro) {
      debugPrint('Preferência de tema indisponível: $erro');
      return TemaEscolhido.sistema;
    }
  }

  /// Aplica na hora e guarda. Se guardar falhar, a escolha vale até o app
  /// fechar.
  Future<void> escolher(TemaEscolhido tema) async {
    state = AsyncData(tema);
    try {
      await ref.read(preferenciaDeTemaProvider).guardar(tema);
    } catch (erro) {
      debugPrint('Não foi possível guardar o tema: $erro');
    }
  }
}

final temaEscolhidoProvider =
    AsyncNotifierProvider<TemaEscolhidoControlador, TemaEscolhido>(
      TemaEscolhidoControlador.new,
    );
