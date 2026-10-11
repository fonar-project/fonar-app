import '../../fila/domain/item_da_fila.dart';

/// Leva para o Firebase o que a API de análise precisa encontrar lá antes
/// de receber as gravações de uma sessão: o paciente, o livro de
/// consentimentos e a sessão.
///
/// A API confere o consentimento no Firebase — não no aparelho — antes de
/// guardar qualquer áudio. Por isso a fila prepara o envio antes de mandar o
/// primeiro WAV.
abstract interface class Sincronizacao {
  /// Garante no Firebase o paciente, os consentimentos e a sessão de [item].
  ///
  /// Idempotente: chamar de novo depois de uma falha no meio grava só o que
  /// faltou. Lança só `AppException`.
  Future<void> prepararEnvio(ItemDaFila item);
}
