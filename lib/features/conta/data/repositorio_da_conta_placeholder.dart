import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../../auth/domain/profissional.dart';
import '../domain/dados_do_profissional.dart';

/// TODO(auth): trocar pelo Firebase — salvar grava no perfil do profissional,
/// sair chama o `signOut` do Firebase Auth.
final repositorioDaContaProvider = Provider<RepositorioDaConta>(
  (ref) => RepositorioDaContaPlaceholder(ref.watch(tokenStorageProvider)),
);

/// PLACEHOLDER — salvar não grava em lugar nenhum além da sessão; sair só
/// apaga o token guardado.
class RepositorioDaContaPlaceholder implements RepositorioDaConta {
  RepositorioDaContaPlaceholder(this._tokens);

  final TokenStorage _tokens;

  @override
  Future<void> salvar(Profissional profissional) async {}

  @override
  Future<void> sair() => _tokens.limpar();
}
