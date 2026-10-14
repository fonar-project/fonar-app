import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../navegador/navegador.dart';
import '../storage/token_storage.dart';

/// A senha conferida sem rede (US43).
///
/// Sem conexão, o Firebase não tem como conferir a senha — e o app abria os
/// dados de saúde do aparelho para quem tocasse em "Entrar em modo offline"
/// ou "Continuar" no bloqueio. Agora, a cada entrada com senha conferida
/// pelo Firebase, o aparelho guarda um VERIFICADOR dela: não a senha, mas o
/// resultado de uma derivação lenta e com sal (PBKDF2-HMAC-SHA256), do qual
/// não se volta à senha. Sem rede, a senha digitada passa pela mesma
/// derivação e é comparada com o verificador.
///
/// Um verificador só, o da última conta que entrou com senha — a mesma que o
/// modo offline usa. Sair da conta o apaga junto com a credencial.
abstract interface class SenhaSemRede {
  /// Guarda o verificador de [senha], que o Firebase acabou de conferir para
  /// a conta [uid]. Nunca falha: sem ele, só não há entrada sem rede.
  Future<void> lembrar(String uid, String senha);

  /// Confere [senha] contra o verificador guardado para [uid].
  Future<ConferenciaSemRede> conferir(String uid, String senha);

  /// Apaga o verificador.
  Future<void> esquecer();
}

enum ConferenciaSemRede {
  confere,
  naoConfere,

  /// Não há verificador desta conta no aparelho: ela não entrou com senha
  /// desde que o FONAR passou a guardá-lo. Sem ele, sem rede não se entra.
  semRegistro,
}

/// Quantas vezes a derivação se repete. É o que torna caro tentar senhas a
/// esmo contra um verificador copiado do aparelho; o custo de quem sabe a
/// senha é uma derivação, uma vez.
const iteracoesDaSenhaSemRede = 100000;

final senhaSemRedeProvider = Provider<SenhaSemRede>(
  (ref) => SenhaSemRedeNoCofre(cofreDoSistema),
);

/// O verificador no cofre do sistema, ao lado da credencial (o mesmo
/// `FlutterSecureStorage` do token).
class SenhaSemRedeNoCofre implements SenhaSemRede {
  SenhaSemRedeNoCofre(
    this._cofre, {
    this.iteracoes = iteracoesDaSenhaSemRede,
    Random? aleatorio,
    Future<Uint8List> Function(String senha, List<int> sal, int iteracoes)?
    derivar,
  }) : _aleatorio = aleatorio ?? Random.secure(),
       _derivar = derivar ?? derivarDaSenha;

  final FlutterSecureStorage _cofre;
  final int iteracoes;
  final Random _aleatorio;
  final Future<Uint8List> Function(String, List<int>, int) _derivar;

  static const chave = 'fonar.senha-sem-rede';

  @override
  Future<void> lembrar(String uid, String senha) async {
    try {
      final sal = [for (var i = 0; i < 16; i++) _aleatorio.nextInt(256)];
      final derivada = await _derivar(senha, sal, iteracoes);
      await _cofre.write(
        key: chave,
        value: jsonEncode({
          'uid': uid,
          'sal': base64Encode(sal),
          'iteracoes': iteracoes,
          'derivada': base64Encode(derivada),
        }),
      );
    } catch (_) {
      // Sem verificador, a entrada sem rede fica indisponível — o que é o
      // lado seguro. A entrada com rede segue.
    }
  }

  @override
  Future<ConferenciaSemRede> conferir(String uid, String senha) async {
    final Map<String, Object?> guardado;
    try {
      final texto = await _cofre.read(key: chave);
      if (texto == null) return ConferenciaSemRede.semRegistro;
      guardado = jsonDecode(texto) as Map<String, Object?>;
    } catch (_) {
      return ConferenciaSemRede.semRegistro;
    }
    if (guardado
        case {
          'uid': final String dono,
          'sal': final String sal,
          'iteracoes': final int vezes,
          'derivada': final String derivada,
        }
        when dono == uid) {
      final calculada = await _derivar(senha, base64Decode(sal), vezes);
      return iguaisEmTempoConstante(calculada, base64Decode(derivada))
          ? ConferenciaSemRede.confere
          : ConferenciaSemRede.naoConfere;
    }
    return ConferenciaSemRede.semRegistro;
  }

  @override
  Future<void> esquecer() async {
    try {
      await _cofre.delete(key: chave);
    } catch (_) {}
  }
}

/// A derivação da senha: no navegador, a do próprio navegador (WebCrypto),
/// que é nativa; no aparelho, [pbkdf2HmacSha256] numa isolate à parte, para
/// a tela não travar enquanto ela roda.
Future<Uint8List> derivarDaSenha(
  String senha,
  List<int> sal,
  int iteracoes,
) async {
  if (kIsWeb) {
    return pbkdf2NoNavegador(utf8.encode(senha), sal, iteracoes, 32);
  }
  return compute(_derivarIsolado, (
    senha: senha,
    sal: sal,
    iteracoes: iteracoes,
  ));
}

Uint8List _derivarIsolado(
  ({String senha, List<int> sal, int iteracoes}) pedido,
) => pbkdf2HmacSha256(
  utf8.encode(pedido.senha),
  pedido.sal,
  pedido.iteracoes,
  32,
);

/// PBKDF2 com HMAC-SHA256 (RFC 8018, seção 5.2), sobre o HMAC do pacote
/// `crypto` do time do Dart. Não é criptografia própria: é a composição que
/// a RFC define, conferida contra os vetores publicados
/// (`senha_sem_rede_test.dart`).
Uint8List pbkdf2HmacSha256(
  List<int> senha,
  List<int> sal,
  int iteracoes,
  int tamanho,
) {
  final hmac = Hmac(sha256, senha);
  final saida = BytesBuilder(copy: false);
  for (var bloco = 1; saida.length < tamanho; bloco++) {
    var u = hmac.convert([
      ...sal,
      (bloco >> 24) & 0xff,
      (bloco >> 16) & 0xff,
      (bloco >> 8) & 0xff,
      bloco & 0xff,
    ]).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iteracoes; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    saida.add(t);
  }
  return Uint8List.sublistView(saida.takeBytes(), 0, tamanho);
}

/// Compara sem parar no primeiro byte diferente: o tempo da comparação não
/// diz quantos bytes acertaram.
bool iguaisEmTempoConstante(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diferenca = 0;
  for (var i = 0; i < a.length; i++) {
    diferenca |= a[i] ^ b[i];
  }
  return diferenca == 0;
}
