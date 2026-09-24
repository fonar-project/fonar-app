import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Para onde o PDF do laudo vai depois de gerado.
abstract interface class SaidaDoLaudo {
  /// Folha de compartilhamento do sistema no Android; no Windows, abre o PDF
  /// no visualizador padrão, de onde ele é salvo ou enviado.
  Future<void> compartilhar(Uint8List pdf, {required String nomeDoArquivo});

  /// Diálogo de impressão do sistema — que nas duas plataformas também salva
  /// em PDF.
  Future<void> imprimir(Uint8List pdf, {required String nomeDoArquivo});
}

final saidaDoLaudoProvider = Provider<SaidaDoLaudo>(
  (ref) => const SaidaDoLaudoPrinting(),
);

/// Pelo pacote `printing`, que cobre Android e Windows com o mesmo código.
///
/// TODO(jurídico): para compartilhar, o pacote grava o PDF numa pasta
/// temporária — no Windows, a TEMP do usuário, onde o arquivo fica depois de
/// aberto. O laudo tem dado pessoal sensível (LGPD). Avaliar se é preciso
/// apagar o arquivo depois ou trocar por salvar direto onde o profissional
/// escolher.
class SaidaDoLaudoPrinting implements SaidaDoLaudo {
  const SaidaDoLaudoPrinting();

  @override
  Future<void> compartilhar(Uint8List pdf, {required String nomeDoArquivo}) =>
      Printing.sharePdf(bytes: pdf, filename: nomeDoArquivo);

  @override
  Future<void> imprimir(Uint8List pdf, {required String nomeDoArquivo}) =>
      Printing.layoutPdf(onLayout: (_) async => pdf, name: nomeDoArquivo);
}
