/// No aparelho. Ver `cifra_do_banco.dart`.
library;

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Como está o arquivo do banco no disco.
enum EstadoDoArquivoDoBanco { naoExiste, semCifra, cifrado }

/// O cabeçalho de todo arquivo do SQLite sem cifra. Cifrado, o começo do
/// arquivo é indistinguível de ruído.
const _cabecalhoSemCifra = 'SQLite format 3\u0000';

Future<EstadoDoArquivoDoBanco> estadoDoArquivoDoBanco(String caminho) async {
  final arquivo = File(caminho);
  if (!await arquivo.exists() || await arquivo.length() == 0) {
    return EstadoDoArquivoDoBanco.naoExiste;
  }
  final inicio = await arquivo
      .openRead(0, _cabecalhoSemCifra.length)
      .fold<List<int>>([], (bytes, parte) => bytes..addAll(parte));
  return String.fromCharCodes(inicio) == _cabecalhoSemCifra
      ? EstadoDoArquivoDoBanco.semCifra
      : EstadoDoArquivoDoBanco.cifrado;
}

/// Cifra com [chave], no lugar, o banco que ficou de antes da US44 — sem
/// cifra. Banco que não existe ou já cifrado fica como está.
///
/// É o `PRAGMA rekey` do SQLite3 Multiple Ciphers, que cifra um banco sem
/// cifra página a página, numa transação: se o app fechar no meio, o
/// journal desfaz, e a próxima abertura tenta de novo. Depois, confere
/// abrindo com a chave — e lança se não abrir, em vez de seguir com um
/// banco que o app não lê.
Future<void> cifrarBancoDeAntes(String caminho, String chave) async {
  if (await estadoDoArquivoDoBanco(caminho) !=
      EstadoDoArquivoDoBanco.semCifra) {
    return;
  }
  final semCifra = sqlite3.open(caminho);
  try {
    semCifra.execute("PRAGMA rekey = '$chave'");
  } finally {
    semCifra.close();
  }
  final cifrado = sqlite3.open(caminho);
  try {
    cifrado.execute("PRAGMA key = '$chave'");
    cifrado.select('SELECT count(*) FROM sqlite_master');
  } finally {
    cifrado.close();
  }
  if (await estadoDoArquivoDoBanco(caminho) != EstadoDoArquivoDoBanco.cifrado) {
    throw StateError('O banco não ficou cifrado.');
  }
}
