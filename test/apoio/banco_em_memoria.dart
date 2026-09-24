import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fonar_app/core/banco/banco_local.dart';

/// Banco local novo, vazio e só na memória — fechado no fim do teste.
BancoLocal bancoEmMemoria() => BancoLocal(
  // Fechar as consultas na hora: sem isto, o teste de widget acusa timer
  // pendente ao terminar.
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Para o `overrides` de quem monta o app ou um `ProviderContainer`: o
/// arquivo do aparelho não existe no teste.
Override bancoDeTeste() => bancoLocalProvider.overrideWith((ref) {
  final banco = bancoEmMemoria();
  ref.onDispose(banco.close);
  return banco;
});
