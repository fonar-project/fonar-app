import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../l10n/app_strings.dart';

/// Para onde o PDF do laudo vai depois de gerado.
abstract interface class SaidaDoLaudo {
  /// No desktop, "Salvar como": o profissional escolhe onde o PDF fica. No
  /// celular, a folha de compartilhamento do sistema.
  Future<void> compartilhar(Uint8List pdf, {required String nomeDoArquivo});

  /// Diálogo de impressão do sistema — que nas duas plataformas também salva
  /// em PDF.
  Future<void> imprimir(Uint8List pdf, {required String nomeDoArquivo});
}

final saidaDoLaudoProvider = Provider<SaidaDoLaudo>(
  (ref) => const SaidaDoLaudoDoSistema(),
);

/// Pelos diálogos do sistema.
///
/// O laudo tem dado pessoal sensível (LGPD), e a cópia que sai do app não
/// pode ficar largada numa pasta temporária:
///
/// - **Desktop:** "Salvar como" ([getSaveLocation]): o arquivo vai direto
///   para onde o profissional escolher, e nenhuma cópia fica na TEMP.
/// - **Celular:** a folha de compartilhar precisa de um arquivo para entregar
///   ao app de destino; o `printing` o grava no cache do aplicativo, e
///   [limparPdfsCompartilhados] apaga na abertura seguinte.
///
/// É o mesmo recurso nas duas plataformas — levar o PDF para fora —, com o
/// caminho que cada sistema oferece. Não decide layout.
class SaidaDoLaudoDoSistema implements SaidaDoLaudo {
  const SaidaDoLaudoDoSistema();

  static bool get _salvarComDialogo =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.windows ||
        TargetPlatform.macOS ||
        TargetPlatform.linux => true,
        _ => false,
      };

  @override
  Future<void> compartilhar(
    Uint8List pdf, {
    required String nomeDoArquivo,
  }) async {
    if (!_salvarComDialogo) {
      await Printing.sharePdf(bytes: pdf, filename: nomeDoArquivo);
      return;
    }
    final local = await getSaveLocation(
      suggestedName: nomeDoArquivo,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
          mimeTypes: ['application/pdf'],
          uniformTypeIdentifiers: ['com.adobe.pdf'],
        ),
      ],
    );
    // Cancelado no diálogo: nada a fazer.
    if (local == null) return;
    await XFile.fromData(
      pdf,
      mimeType: 'application/pdf',
      name: nomeDoArquivo,
    ).saveTo(local.path);
  }

  @override
  Future<void> imprimir(Uint8List pdf, {required String nomeDoArquivo}) =>
      Printing.layoutPdf(onLayout: (_) async => pdf, name: nomeDoArquivo);
}

/// Apaga os PDFs de laudo que o compartilhamento deixou na pasta temporária
/// do aplicativo — no celular, o cache; no desktop, sobra de versões
/// anteriores ao "Salvar como".
///
/// Roda na abertura do app: o app de destino já leu o arquivo há muito.
/// Procura só os nomes que o FONAR dá ([AppStrings.laudoNomeDoArquivo]), na
/// pasta temporária e na `shared` dela, onde o `printing` os grava. Nunca
/// falha: limpar é cuidado, não condição para abrir.
Future<int> limparPdfsCompartilhados({Directory? pasta}) async {
  if (kIsWeb) return 0;
  var apagados = 0;
  try {
    final raiz = pasta ?? await getTemporaryDirectory();
    for (final dir in [raiz, Directory('${raiz.path}/shared')]) {
      if (!await dir.exists()) continue;
      await for (final item in dir.list(followLinks: false)) {
        final nome = item.uri.pathSegments.last;
        if (item is File &&
            nome.startsWith(AppStrings.laudoPrefixoDoArquivo) &&
            nome.endsWith('.pdf')) {
          await item.delete();
          apagados++;
        }
      }
    }
  } catch (_) {
    // Pasta indisponível ou arquivo em uso: fica para a próxima abertura.
  }
  return apagados;
}
