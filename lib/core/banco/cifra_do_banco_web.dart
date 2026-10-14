/// No navegador, não há arquivo do banco para cifrar. Ver
/// `cifra_do_banco.dart`.
library;

/// Nada a fazer: ver [cifrarBancoDeAntes] em `cifra_do_banco_nativa.dart`.
Future<void> cifrarBancoDeAntes(String caminho, String chave) async {}

/// No navegador, nunca há arquivo.
Future<EstadoDoArquivoDoBanco> estadoDoArquivoDoBanco(String caminho) async =>
    EstadoDoArquivoDoBanco.naoExiste;

/// Como está o arquivo do banco no disco.
enum EstadoDoArquivoDoBanco { naoExiste, semCifra, cifrado }
