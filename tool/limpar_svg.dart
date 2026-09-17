// Remove metadados de SVG exportado do Claude Design — o bloco C2PA de
// procedência, que vem com ~8 KB por arquivo e não desenha nada.
//
// Rode da raiz do projeto, antes de commitar ícone novo:
//
//     dart run tool/limpar_svg.dart assets/icons/nome-do-icone.svg
//
// Sem argumento, varre todos os SVG de `assets/icons/`:
//
//     dart run tool/limpar_svg.dart
//
// O que sai: elementos `<metadata>…</metadata>` e comentários XML. Nada mais —
// path, viewBox e `currentColor` ficam intactos. Reescreve o arquivo só quando
// há algo a remover, e imprime quantos bytes saíram, para dar para conferir.
//
// Confira depois: um ícone limpo tem algumas centenas de bytes, e
// `grep -i c2pa assets/icons/*.svg` não retorna nada.

import 'dart:io';

const _pastaOrigem = 'assets/icons';

final _metadata = RegExp(r'<metadata\b[^>]*>.*?</metadata>', dotAll: true);
final _metadataVazio = RegExp(r'<metadata\b[^>]*/>');
final _comentario = RegExp(r'<!--.*?-->', dotAll: true);

void main(List<String> argumentos) {
  final arquivos = argumentos.isNotEmpty
      ? argumentos.map(File.new).toList()
      : _todosOsSvg();

  if (arquivos.isEmpty) {
    stderr.writeln('Nenhum SVG encontrado em $_pastaOrigem.');
    exit(1);
  }

  var totalRemovido = 0;

  for (final arquivo in arquivos) {
    if (!arquivo.existsSync()) {
      stderr.writeln('Arquivo não encontrado: ${arquivo.path}');
      exit(1);
    }

    final original = arquivo.readAsStringSync();
    final limpo = original
        .replaceAll(_metadata, '')
        .replaceAll(_metadataVazio, '')
        .replaceAll(_comentario, '')
        .trim();

    final removido = original.length - limpo.length;
    if (removido == 0) {
      continue;
    }

    arquivo.writeAsStringSync(limpo);
    totalRemovido += removido;
    stdout.writeln('${arquivo.path}: $removido byte(s) removido(s)');
  }

  if (totalRemovido == 0) {
    stdout.writeln(
      'Nada a remover — ${arquivos.length} arquivo(s) já limpo(s).',
    );
    return;
  }

  stdout.writeln('Total: $totalRemovido byte(s) removido(s).');
  stdout.writeln('Recompile os binários: dart run tool/compilar_icones.dart');
}

List<File> _todosOsSvg() {
  final pasta = Directory(_pastaOrigem);
  if (!pasta.existsSync()) {
    return const [];
  }
  return pasta
      .listSync()
      .whereType<File>()
      .where((arquivo) => arquivo.path.endsWith('.svg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}
