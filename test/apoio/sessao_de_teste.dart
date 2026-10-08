// Sessão e autenticação para os testes.

import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/features/auth/domain/conta_autenticada.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';
import 'package:fonar_app/features/auth/domain/repositorio_autenticacao.dart';
import 'package:fonar_app/features/conta/domain/dados_do_profissional.dart';

/// A conta com que os testes entram.
const contaDeTeste = ContaAutenticada(
  uid: 'uid-de-teste',
  email: 'fono@exemplo.com',
);

/// Outra conta, no mesmo aparelho.
const outraConta = ContaAutenticada(
  uid: 'uid-de-outra',
  email: 'outra@exemplo.com',
);

/// Aceita qualquer senha, e responde como [conta]; com [recusar], recusa
/// todas. Anota o que pediram.
class AutenticacaoFalsa implements RepositorioAutenticacao {
  AutenticacaoFalsa({
    this.conta = contaDeTeste,
    this.guardada,
    this.recusar = false,
  });

  ContaAutenticada conta;
  ContaAutenticada? guardada;
  bool recusar;
  final entradas = <String>[];
  final redefinicoes = <String>[];
  var saidas = 0;

  @override
  Future<ContaAutenticada> entrar({
    required String email,
    required String senha,
  }) async {
    entradas.add(email);
    if (recusar) throw const CredencialInvalida();
    return guardada = conta;
  }

  @override
  Future<ContaAutenticada?> contaGuardada() async => guardada;

  @override
  Future<void> pedirRedefinicaoDeSenha(String email) async =>
      redefinicoes.add(email);

  @override
  Future<void> sair() async {
    saidas++;
    guardada = null;
  }
}

/// O perfil de quem assina, preenchido.
const perfilDeTeste = Profissional(
  nome: 'Fon.ª Teste',
  registro: 'CRFa 0-00000 (teste)',
);

/// Perfis em memória, por conta. Começa com [perfilDeTeste] na
/// [contaDeTeste]; `vazio` para a primeira entrada no aparelho.
class PerfilEmMemoria implements RepositorioDaConta {
  PerfilEmMemoria({bool vazio = false})
    : perfis = {if (!vazio) contaDeTeste.uid: perfilDeTeste};

  final Map<String, Profissional> perfis;

  @override
  Future<Profissional?> perfil(String uid) async => perfis[uid];

  @override
  Future<void> salvar(String uid, Profissional profissional) async =>
      perfis[uid] = profissional;
}
