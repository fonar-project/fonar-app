import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// PLACEHOLDER — sempre zero.
///
/// TODO(drift): contar os pacientes do banco local quando a persistência
/// existir.
final pacientesEmCacheProvider = Provider<int>((ref) => 0);
