import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'cifra_do_banco.dart';

/// A chave que cifra o banco local no aparelho (US44), guardada no cofre do
/// sistema — o mesmo da credencial: Keystore no Android, Gerenciador de
/// Credenciais no Windows, keychain no macOS. Só este app, deste usuário, a
/// lê.
///
/// Gerada uma vez, aleatória (32 bytes, em hexadecimal), na primeira
/// abertura depois da US44. Nunca sai do aparelho: o que está no Firebase
/// desce de novo para um banco novo, se um dia ela se perder.
class ChaveDoBanco {
  ChaveDoBanco(this._cofre, {Random? aleatorio})
    : _aleatorio = aleatorio ?? Random.secure();

  final FlutterSecureStorage _cofre;
  final Random _aleatorio;

  static const chave = 'fonar.chave-do-banco';

  /// A chave do banco em [caminho], criando-a se for a primeira vez.
  ///
  /// [aoPerderOBanco] é chamado quando há um banco cifrado e nenhuma chave
  /// no cofre — o cofre foi apagado, o aparelho foi restaurado de outro. Sem
  /// a chave, aquele arquivo não se lê mais; quem chama o tira do caminho
  /// (sem apagar), e o app recomeça com um banco novo.
  ///
  /// Falha ao LER o cofre não vira chave nova: lança. Uma chave nova por um
  /// erro passageiro tiraria do caminho um banco perfeitamente legível.
  Future<String> obter(
    String caminho, {
    required Future<void> Function() aoPerderOBanco,
  }) async {
    final guardada = await _cofre.read(key: chave);
    if (guardada != null && guardada.length == 64) return guardada;

    if (await estadoDoArquivoDoBanco(caminho) ==
        EstadoDoArquivoDoBanco.cifrado) {
      await aoPerderOBanco();
    }
    final nova = [
      for (var i = 0; i < 32; i++)
        _aleatorio.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    await _cofre.write(key: chave, value: nova);
    return nova;
  }
}
