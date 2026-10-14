import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/conexao.dart';
import '../../auth/data/sessao.dart';
import '../../cape_v/data/repositorio_cape_v_local.dart';
import '../../consentimento/data/repositorio_consentimento_local.dart';
import '../../laudo/data/repositorio_laudos_local.dart';
import '../../pacientes/data/repositorio_pacientes_local.dart';
import '../data/descida_firestore.dart';
import '../domain/sincronizavel.dart';
import 'sincronizacao_em_segundo_plano.dart';

/// Desce do Firebase os pacientes da conta e o livro de consentimentos de
/// cada um (US40) — na abertura do app, quando a conexão volta e quando
/// alguém entra, como as subidas ([SincronizacaoEmSegundoPlano]).
///
/// O que mudou aparece sem ninguém pedir: a lista de pacientes e os
/// consentimentos são lidos de novo. Uma retirada registrada noutro aparelho
/// passa a bloquear a gravação aqui também.
class DescidaDaContaControlador extends SincronizacaoEmSegundoPlano {
  @override
  Sincronizavel? get alvo {
    final descida = ref.read(descidaProvider);
    if (descida == null) return null;
    return _Descer(() async {
      final conta = ref.read(sessaoProvider)?.uid;
      if (conta == null) return 0;
      final mudaram = await descida.descerConta(conta);
      if (mudaram > 0 && ref.mounted) {
        ref.invalidate(pacientesProvider);
        ref.invalidate(consentimentoProvider);
        ref.invalidate(retiradaEmVigorProvider);
      }
      return mudaram;
    });
  }
}

final descidaDaContaControladorProvider =
    NotifierProvider<DescidaDaContaControlador, void>(
      DescidaDaContaControlador.new,
    );

/// Desce as CAPE-V e os laudos de um paciente (US40), uma vez a cada vez que
/// o perfil dele abre. Nunca falha: sem rede, sem sessão ou com o servidor
/// fora, fica o que já está no aparelho, e devolve zero.
final descidaDoPacienteProvider = FutureProvider.autoDispose
    .family<int, String>((ref, pacienteId) async {
      final descida = ref.read(descidaProvider);
      final conta = ref.read(sessaoProvider)?.uid;
      if (descida == null ||
          conta == null ||
          !ref.read(conexaoOnlineProvider)) {
        return 0;
      }
      try {
        final mudaram = await descida.descerPaciente(conta, pacienteId);
        if (mudaram > 0 && ref.mounted) {
          ref.invalidate(laudosDoPacienteProvider(pacienteId));
          ref.invalidate(capeVDaAnaliseProvider);
        }
        return mudaram;
      } catch (_) {
        return 0;
      }
    });

class _Descer implements Sincronizavel {
  _Descer(this._descer);

  final Future<int> Function() _descer;

  @override
  Future<int> sincronizar() => _descer();
}
