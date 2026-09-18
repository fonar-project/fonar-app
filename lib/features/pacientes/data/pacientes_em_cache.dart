import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quantos pacientes estão salvos neste aparelho.
///
/// Decide se o modo offline está disponível: sem nenhum paciente em cache não
/// há com quem gravar, e entrar offline só levaria a uma lista vazia.
///
/// PLACEHOLDER — sempre zero.
///
/// TODO(drift): contar os pacientes do banco local quando a persistência
/// existir.
final pacientesEmCacheProvider = Provider<int>((ref) => 0);
