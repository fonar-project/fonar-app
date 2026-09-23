import 'consentimento.dart';

/// Onde os consentimentos ficam registrados.
///
/// A implementação real grava no banco local (Drift) e sobe pela fila de
/// sincronização: o registro não pode depender de conexão, senão um
/// consultório sem sinal não conseguiria gravar ninguém.
abstract interface class RepositorioConsentimento {
  /// O consentimento em vigor para o paciente, ou `null` se não houver —
  /// nunca registrado, ou retirado.
  Future<Consentimento?> buscar(String pacienteId);

  /// A retirada que está valendo: a do último consentimento, se ele foi
  /// retirado. `null` quando há consentimento em vigor ou nunca houve um.
  Future<RetiradaDeConsentimento?> retiradaEmVigor(String pacienteId);

  /// Registra o consentimento com a data e a hora de agora e a versão atual
  /// do termo.
  ///
  /// Lança só `AppException`.
  Future<Consentimento> registrar(
    String pacienteId,
    PedidoDeConsentimento pedido,
  );

  /// Retira o consentimento em vigor, com a data e a hora de agora.
  ///
  /// Lança só `AppException` — `FalhaDeValidacao` se não houver
  /// consentimento em vigor para retirar.
  Future<RetiradaDeConsentimento> retirar(
    String pacienteId,
    PedidoDeRetirada pedido,
  );
}
