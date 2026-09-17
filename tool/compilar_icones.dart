// Pré-compila os SVG de `assets/icons/` para o formato binário `.svg.vec`,
// em `assets/icons_vec/`.
//
// Rode da raiz do projeto, depois de adicionar, remover ou alterar um SVG:
//
//     dart run tool/compilar_icones.dart
//
// Por que existe: quem entra no bundle é o `.vec`, não o XML. O parse do SVG
// sai do runtime e vai para o build — sem custo no primeiro frame de cada
// ícone. O `pubspec.yaml` declara apenas `assets/icons_vec/`.
//
// Os `.vec` são versionados junto do código, porque o Flutter não tem gancho
// de pré-build no canal estável: sem eles no repositório, um clone novo não
// compila. O teste `test/design_system/app_icone_test.dart` falha se algum
// `.vec` estiver faltando ou sobrando, o que evita esquecer de rodar isto.
//
// Limitação conhecida: o teste detecta arquivo faltando ou órfão, não `.vec`
// DESATUALIZADO. Alterou o desenho de um SVG? Rode este comando.

import 'dart:io';

const _pastaOrigem = 'assets/icons';
const _pastaDestino = 'assets/icons_vec';
const _extensaoOrigem = '.svg';
const _extensaoDestino = '.svg.vec';

Future<void> main() async {
  final origem = Directory(_pastaOrigem);
  if (!origem.existsSync()) {
    stderr.writeln(
      'Pasta $_pastaOrigem não encontrada. Rode da raiz do projeto.',
    );
    exit(1);
  }

  final destino = Directory(_pastaDestino);
  if (!destino.existsSync()) {
    destino.createSync(recursive: true);
  }

  final resultado = await Process.run('dart', [
    'run',
    'vector_graphics_compiler',
    '--input-dir',
    _pastaOrigem,
    '--out-dir',
    _pastaDestino,
  ], runInShell: true);

  if (resultado.exitCode != 0) {
    stderr
      ..writeln('Falha ao compilar os ícones:')
      ..writeln(resultado.stdout)
      ..writeln(resultado.stderr);
    exit(resultado.exitCode);
  }

  final compilados = _nomes(origem, _extensaoOrigem);
  final orfaos = _nomes(destino, _extensaoDestino).difference(compilados);

  // SVG apagado deixa o .vec para trás. Remover aqui evita asset morto no
  // bundle e mantém o teste de paridade verde por motivo certo.
  for (final orfao in orfaos) {
    File('$_pastaDestino/$orfao$_extensaoDestino').deleteSync();
  }

  stdout.writeln(
    '${compilados.length} ícone(s) compilado(s) em $_pastaDestino',
  );
  if (orfaos.isNotEmpty) {
    stdout.writeln(
      '${orfaos.length} órfão(s) removido(s): '
      '${(orfaos.toList()..sort()).join(', ')}',
    );
  }
}

/// Nomes de arquivo, sem extensão, dos arquivos de [pasta] que terminam em
/// [extensao].
Set<String> _nomes(Directory pasta, String extensao) {
  return pasta
      .listSync()
      .whereType<File>()
      .map((arquivo) => arquivo.uri.pathSegments.last)
      .where((nome) => nome.endsWith(extensao))
      .map((nome) => nome.substring(0, nome.length - extensao.length))
      .toSet();
}
