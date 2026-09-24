import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../banco/banco_local.dart';

/// Quantos pacientes estão salvos neste aparelho.
///
/// A pergunta que ele responde é **"o modo offline está disponível?"**, e é
/// por isso que mora aqui e não na feature de pacientes: quem consome a
/// resposta é a tela de login, que decide se dá para entrar sem conexão. Sem
/// nenhum paciente em cache não há com quem gravar, e entrar offline só
/// levaria a uma lista vazia.
///
/// Anda junto de `core/network/conexao.dart`: um diz se a rede existe, o outro
/// diz se dá para trabalhar sem ela.
///
/// Conta só o banco local. Os pacientes de exemplo não contam: eles não são
/// de ninguém, e não justificam entrar sem conexão.
///
/// `autoDispose`: conta de novo cada vez que o login aparece. Quem cadastrou
/// pacientes durante a sessão e saiu sem conexão precisa ver a conta de
/// agora, não a da abertura do app.
final pacientesEmCacheProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(bancoLocalProvider).pacientes.count().getSingle(),
);
