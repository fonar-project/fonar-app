import 'package:fonar_app/core/auth/senha_sem_rede.dart';

/// A senha sem rede só na memória, sem derivação — para os testes de tela,
/// em que a derivação de verdade (numa isolate, com 100 mil voltas) não cabe
/// no relógio falso. A derivação é testada à parte, em
/// `test/core/senha_sem_rede_test.dart`.
class SenhaSemRedeEmMemoria implements SenhaSemRede {
  SenhaSemRedeEmMemoria([Map<String, String>? senhas])
    : senhas = senhas ?? <String, String>{};

  /// A senha guardada de cada conta.
  final Map<String, String> senhas;

  @override
  Future<void> lembrar(String uid, String senha) async {
    senhas
      ..clear()
      ..[uid] = senha;
  }

  @override
  Future<ConferenciaSemRede> conferir(String uid, String senha) async =>
      switch (senhas[uid]) {
        null => ConferenciaSemRede.semRegistro,
        final guardada when guardada == senha => ConferenciaSemRede.confere,
        _ => ConferenciaSemRede.naoConfere,
      };

  @override
  Future<void> esquecer() async => senhas.clear();
}
