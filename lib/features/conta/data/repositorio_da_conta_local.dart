import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/domain/profissional.dart';
import '../domain/dados_do_profissional.dart';

/// O nome e o registro de cada profissional, no banco local, na tabela de
/// preferências do aparelho — uma linha por conta, pelo id do Firebase.
///
/// É a CÓPIA, para o laudo sair sem rede: a fonte é o cadastro na API
/// (`/v1/profissionais/eu`, US34), que a Conta corrige e que vale em todo
/// aparelho da conta (`ProfissionalAtual`). Sem a API (modo de exemplo),
/// é só o daqui.
class RepositorioDaContaLocal implements RepositorioDaConta {
  RepositorioDaContaLocal(this._banco);

  final BancoLocal _banco;

  static String _chave(String uid) => 'perfil:$uid';

  @override
  Future<Profissional?> perfil(String uid) async {
    final linha = await (_banco.select(
      _banco.preferencias,
    )..where((p) => p.chave.equals(_chave(uid)))).getSingleOrNull();
    if (linha == null) return null;
    try {
      final json = jsonDecode(linha.valor);
      if (json case {
        'nome': final String nome,
        'registro': final String registro,
      }) {
        return Profissional(nome: nome, registro: registro);
      }
    } on FormatException {
      // Ilegível: como se não houvesse — a Conta pede de novo.
    }
    return null;
  }

  @override
  Future<void> salvar(String uid, Profissional profissional) async {
    try {
      await _banco
          .into(_banco.preferencias)
          .insertOnConflictUpdate(
            PreferenciasCompanion.insert(
              chave: _chave(uid),
              valor: jsonEncode({
                'nome': profissional.nome,
                'registro': profissional.registro,
              }),
            ),
          );
    } catch (e) {
      throw FalhaDesconhecida(causa: e);
    }
  }
}

final repositorioDaContaProvider = Provider<RepositorioDaConta>(
  (ref) => RepositorioDaContaLocal(ref.watch(bancoLocalProvider)),
);
