import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/credencial.dart';
import '../domain/conta_autenticada.dart';
import 'sessao.dart';

/// "Manter conectado neste aparelho" (US59): a sessão que abre sozinha
/// quando o app abre.
///
/// Quem abre é a credencial que já ficava no cofre do sistema — a mesma da
/// renovação do token e do modo offline —, com a marca de
/// [Credencial.manterConectado]. A senha nunca é guardada. Sair da conta
/// apaga a credencial, e a marca vai junto; quando o Firebase deixa de
/// renovar (senha trocada em outro aparelho, conta desativada), a
/// `FonteDeToken` também a apaga, e a próxima abertura pede a senha.
class SessaoMantida {
  const SessaoMantida(this._cofre);

  final CofreDeCredencial _cofre;

  /// Marca a credencial guardada de [uid] para abrir sozinha. Se a guardada
  /// for de outra conta, ou não houver nenhuma, não marca nada.
  ///
  /// Lança só `AppException`.
  Future<void> manter(String uid) async {
    final guardada = await _cofre.ler();
    if (guardada == null || guardada.uid != uid) return;
    if (guardada.manterConectado) return;
    await _cofre.guardar(guardada.comManterConectado(true));
  }

  /// A conta a abrir quando o app abre, ou `null` — sem credencial, ou com a
  /// de quem não marcou "Manter conectado".
  Future<ContaAutenticada?> contaAAbrir() async {
    final guardada = await _cofre.ler();
    if (guardada == null || !guardada.manterConectado) return null;
    return ContaAutenticada(uid: guardada.uid, email: guardada.email);
  }
}

final sessaoMantidaProvider = Provider<SessaoMantida>(
  (ref) => SessaoMantida(ref.watch(cofreDeCredencialProvider)),
);

/// Na abertura do app, antes da primeira tela: abre a sessão mantida, se
/// houver. Aberta antes, o roteador já começa nos pacientes, sem a tela de
/// entrada aparecer e sumir.
///
/// O cofre que falha, ou que não responde em [limite], não segura o app:
/// ele abre na entrada, como se ninguém tivesse marcado.
Future<void> abrirSessaoMantida(
  ProviderContainer container, {
  Duration limite = const Duration(seconds: 3),
}) async {
  try {
    final conta = await container
        .read(sessaoMantidaProvider)
        .contaAAbrir()
        .timeout(limite);
    if (conta != null) container.read(sessaoProvider.notifier).abrir(conta);
  } catch (erro) {
    debugPrint('Sessão mantida indisponível: $erro');
  }
}
