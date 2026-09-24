import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Há um profissional com a sessão aberta neste aparelho?
///
/// Abre quando ele entra — com a senha ou em modo offline — e fecha quando
/// sai da conta. A fila de sincronização só envia com a sessão aberta: sair
/// pausa os envios, e o que estiver subindo é interrompido (achado da
/// revisão de 23/09 — antes, sair limpava o token e a fila seguia tentando).
///
/// TODO(auth): nascer do estado do Firebase Auth. E cada envio da fila
/// precisa levar o id do profissional que gravou, para nunca subir na
/// sessão de outro — hoje o placeholder não tem esse id.
class Sessao extends Notifier<bool> {
  Sessao([this._aberta = false]);

  final bool _aberta;

  @override
  bool build() => _aberta;

  void abrir() => state = true;

  void encerrar() => state = false;
}

final sessaoAbertaProvider = NotifierProvider<Sessao, bool>(Sessao.new);
