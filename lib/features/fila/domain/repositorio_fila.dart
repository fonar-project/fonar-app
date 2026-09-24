import 'dart:async';

import 'item_da_fila.dart';

/// Onde a fila fica guardada.
///
/// No banco local, para a fila sobreviver ao app fechado e ao aparelho
/// reiniciado.
abstract interface class RepositorioFila {
  /// Do mais antigo para o mais novo: a ordem em que devem subir.
  Future<List<ItemDaFila>> listar();

  Future<void> adicionar(ItemDaFila item);

  /// Substitui o item de mesmo id.
  Future<void> atualizar(ItemDaFila item);
}

/// Manda uma sessão para a análise.
abstract interface class EnvioDeAnalise {
  /// Envia as amostras de [item] e devolve o id da análise criada.
  ///
  /// Lança só `AppException` — `EnvioCancelado` quando [cancelamento] é
  /// pedido no meio. Precisa ser idempotente pelo `item.id`: a mesma sessão
  /// enviada duas vezes (a resposta da primeira se perdeu) tem de resultar
  /// numa análise só.
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento});
}

/// Pedido para interromper um envio em andamento — ao sair da conta, por
/// exemplo. Quem envia decide como interromper; a fila só pede.
class Cancelamento {
  final _pedido = Completer<void>();

  bool get pedido => _pedido.isCompleted;

  /// Completa quando o cancelamento é pedido.
  Future<void> get quandoPedido => _pedido.future;

  void pedir() {
    if (!_pedido.isCompleted) _pedido.complete();
  }
}
