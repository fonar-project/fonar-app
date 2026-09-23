import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/item_da_fila.dart';
import '../domain/repositorio_fila.dart';

/// TODO(drift): trocar pelo repositório do banco local.
final repositorioFilaProvider = Provider<RepositorioFila>(
  (ref) => RepositorioFilaEmMemoria(),
);

/// PLACEHOLDER — a fila some ao fechar o app. Os WAV continuam no disco, mas
/// sem o registro ninguém os envia. É a limitação que o Drift resolve.
class RepositorioFilaEmMemoria implements RepositorioFila {
  RepositorioFilaEmMemoria();

  final _itens = <ItemDaFila>[];

  @override
  Future<List<ItemDaFila>> listar() async => List.unmodifiable(_itens);

  @override
  Future<void> adicionar(ItemDaFila item) async => _itens.add(item);

  @override
  Future<void> atualizar(ItemDaFila item) async {
    final i = _itens.indexWhere((x) => x.id == item.id);
    if (i >= 0) _itens[i] = item;
  }
}
