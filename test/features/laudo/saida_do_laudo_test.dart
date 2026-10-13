import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/laudo/data/saida_do_laudo.dart';
import 'package:fonar_app/l10n/app_strings.dart';

void main() {
  test('apaga só os PDFs de laudo que o compartilhamento deixou', () async {
    final pasta = await Directory.systemTemp.createTemp('fonar-saida-');
    addTearDown(() => pasta.delete(recursive: true));
    final compartilhados = Directory('${pasta.path}/shared')..createSync();

    final nome = AppStrings.laudoNomeDoArquivo(
      DateTime(2026, 10, 13),
      'ABCD1234',
    );
    final doLaudo = File('${pasta.path}/$nome')..writeAsStringSync('%PDF-');
    final noShared = File('${compartilhados.path}/$nome')
      ..writeAsStringSync('%PDF-');
    // De outro aplicativo, ou que não é PDF: fica.
    final alheio = File('${pasta.path}/relatorio.pdf')
      ..writeAsStringSync('%PDF-');
    final parecido = File('${pasta.path}/laudo-fonar-anotacoes.txt')
      ..writeAsStringSync('texto');

    expect(await limparPdfsCompartilhados(pasta: pasta), 2);

    expect(doLaudo.existsSync(), isFalse);
    expect(noShared.existsSync(), isFalse);
    expect(alheio.existsSync(), isTrue);
    expect(parecido.existsSync(), isTrue);
  });

  test('pasta que não existe não é erro', () async {
    expect(
      await limparPdfsCompartilhados(
        pasta: Directory('${Directory.systemTemp.path}/fonar-nao-existe-x'),
      ),
      0,
    );
  });
}
