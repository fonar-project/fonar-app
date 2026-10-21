import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/config/app_config.dart';
import '../../../core/firestore/firestore_rest.dart';
import '../../auth/data/sessao.dart';
import '../data/sincronizacao_firestore.dart';
import '../domain/sincronizavel.dart';
import 'sincronizacao_em_segundo_plano.dart';

/// A subida dos pacientes, ou `null` no modo de exemplo: sem a API de
/// verdade, não há Firebase para onde subir.
final subidaDosPacientesProvider = Provider<Sincronizavel?>((ref) {
  if (!AppConfig.apiConfigurada) return null;
  return SincronizacaoFirestore(
    ref.watch(firestoreRestProvider),
    ref.watch(bancoLocalProvider),
    uid: () => ref.read(sessaoProvider)?.uid,
  );
});

/// Sobe para o Firebase o cadastro e o livro de consentimentos dos pacientes
/// sem ninguém olhando — sem esperar o primeiro envio para a análise. O
/// quando é o de toda [SincronizacaoEmSegundoPlano]; o quê,
/// [SincronizacaoFirestore.sincronizar].
///
/// É o que faz o paciente cadastrado num aparelho aparecer nos outros da
/// mesma conta, a versão web inclusive, e a retirada do consentimento
/// bloquear a gravação neles (US40).
class SubidaDosPacientesControlador extends SincronizacaoEmSegundoPlano {
  @override
  Sincronizavel? get alvo => ref.read(subidaDosPacientesProvider);
}

final subidaDosPacientesControladorProvider =
    NotifierProvider<SubidaDosPacientesControlador, void>(
      SubidaDosPacientesControlador.new,
    );

/// Pede a subida logo depois de uma mudança num paciente — cadastro,
/// correção, consentimento ou retirada. Só se ela estiver de pé: quem a
/// acorda é o `FonarApp`, e sem ele (nos testes de uma tela só) não há o que
/// pedir; o que mudou sobe na próxima ocasião.
void pedirSubidaDosPacientes(ProviderContainer container) {
  if (container.exists(subidaDosPacientesControladorProvider)) {
    container.read(subidaDosPacientesControladorProvider.notifier).pedir();
  }
}
