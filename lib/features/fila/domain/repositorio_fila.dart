import 'item_da_fila.dart';

/// Onde a fila fica guardada.
///
/// TODO(drift): a implementação real grava no banco local, para a fila
/// sobreviver ao app fechado e ao aparelho reiniciado. Hoje é placeholder em
/// memória — decisão registrada: a fila veio antes, o Drift entra numa US
/// própria trocando só esta implementação.
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
  /// Lança só `AppException`. Precisa ser idempotente pelo `item.id`: a
  /// mesma sessão enviada duas vezes (a resposta da primeira se perdeu) tem
  /// de resultar numa análise só.
  Future<String> enviar(ItemDaFila item);
}
