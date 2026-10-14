/// O que sobe do aparelho para o servidor em segundo plano, sem ninguém
/// esperar na tela: a CAPE-V e os laudos emitidos (ver
/// `SincronizacaoEmSegundoPlano`).
abstract interface class Sincronizavel {
  /// Sobe o que ainda não está lá como está aqui. Devolve quantos subiram.
  ///
  /// Idempotente: chamar de novo depois de uma falha sobe só o que faltou.
  /// Uma falha não impede os outros itens; a primeira é lançada no fim.
  /// Lança só `AppException`.
  Future<int> sincronizar();
}
