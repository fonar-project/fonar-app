import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/consentimento.dart';
import '../domain/repositorio_consentimento.dart';

/// Versão do texto do termo que a tela apresenta hoje.
///
/// TODO(jurídico): o texto é PROVISÓRIO. Quando a versão revisada chegar,
/// troque o texto em `app_strings.dart` e mude esta versão junto — é ela que
/// diz, em cada registro, com qual texto a pessoa concordou.
const versaoAtualDoTermo = 'provisorio-1';

/// TODO(drift): trocar pelo repositório do banco local.
final repositorioConsentimentoProvider = Provider<RepositorioConsentimento>(
  (ref) => RepositorioConsentimentoPlaceholder(),
);

/// Consentimento em vigor para o paciente, ou `null`.
final consentimentoProvider = FutureProvider.family<Consentimento?, String>(
  (ref, pacienteId) =>
      ref.watch(repositorioConsentimentoProvider).buscar(pacienteId),
);

/// PLACEHOLDER — guarda em memória, some ao fechar o app.
///
/// Os pacientes de exemplo A a D já chegam com consentimento, para dar para
/// percorrer o fluxo até a gravação sem registrar toda vez; o E chega sem,
/// para dar para ver o bloqueio. A versão do termo deles é "exemplo", que
/// não existe de verdade: dado de desenvolvimento precisa ser reconhecível.
class RepositorioConsentimentoPlaceholder implements RepositorioConsentimento {
  RepositorioConsentimentoPlaceholder();

  final _registros = <String, Consentimento>{
    for (final id in ['exemplo-a', 'exemplo-b', 'exemplo-c', 'exemplo-d'])
      id: Consentimento(
        pacienteId: id,
        registradoEm: DateTime(2026, 6, 1, 9),
        versaoDoTermo: 'exemplo',
        quemAutoriza: QuemAutoriza.paciente,
      ),
  };

  @override
  Future<Consentimento?> buscar(String pacienteId) async =>
      _registros[pacienteId];

  @override
  Future<Consentimento> registrar(
    String pacienteId,
    PedidoDeConsentimento pedido,
  ) async {
    final consentimento = Consentimento(
      pacienteId: pacienteId,
      registradoEm: DateTime.now(),
      versaoDoTermo: versaoAtualDoTermo,
      quemAutoriza: pedido.quemAutoriza,
      nomeDoResponsavel: pedido.nomeDoResponsavel,
    );
    _registros[pacienteId] = consentimento;
    return consentimento;
  }
}
