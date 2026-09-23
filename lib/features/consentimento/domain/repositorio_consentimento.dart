import 'consentimento.dart';

/// Onde os consentimentos ficam registrados.
///
/// A implementação real grava no banco local (Drift) e sobe pela fila de
/// sincronização: o registro não pode depender de conexão, senão um
/// consultório sem sinal não conseguiria gravar ninguém.
abstract interface class RepositorioConsentimento {
  /// O consentimento em vigor para o paciente, ou `null` se não houver.
  Future<Consentimento?> buscar(String pacienteId);

  /// Registra o consentimento com a data e a hora de agora e a versão atual
  /// do termo.
  ///
  /// Lança só `AppException`.
  Future<Consentimento> registrar(
    String pacienteId,
    PedidoDeConsentimento pedido,
  );
}
