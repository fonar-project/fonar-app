import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/conta_autenticada.dart';

/// Quem está com a sessão aberta neste aparelho, ou `null`.
///
/// Abre quando o profissional entra — com a senha, conferida pelo Firebase,
/// ou em modo offline, com a conta da última entrada — e fecha quando ele
/// sai. O roteador manda para a entrada quem não tem sessão, e a fila só
/// envia com a sessão aberta, e só o que a conta dela gravou: sair pausa os
/// envios, e o que estiver subindo é interrompido (revisão de 23/09).
class Sessao extends Notifier<ContaAutenticada?> {
  Sessao([this._inicial]);

  final ContaAutenticada? _inicial;

  @override
  ContaAutenticada? build() => _inicial;

  void abrir(ContaAutenticada conta) => state = conta;

  void encerrar() => state = null;
}

final sessaoProvider = NotifierProvider<Sessao, ContaAutenticada?>(Sessao.new);

/// Há alguém com a sessão aberta?
final sessaoAbertaProvider = Provider<bool>(
  (ref) => ref.watch(sessaoProvider) != null,
);
