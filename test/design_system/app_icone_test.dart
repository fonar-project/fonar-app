// Paridade entre o enum de ícones e o que existe em disco, NAS DUAS DIREÇÕES.
//
// Direção 1: todo valor de `NomeIcone` tem SVG correspondente. Sem isso o
// ícone só falha quando a tela abre, em runtime.
//
// Direção 2: todo SVG em `assets/icons/` tem entrada no enum. Arquivo órfão
// TAMBÉM é erro: ou alguém adicionou o ícone e esqueceu de registrar, e ele
// nunca vai aparecer, ou o ícone saiu de uso e o arquivo ficou pesando no
// repositório — e, como a pasta é espelhada com a landing page, divergindo do
// outro repositório em silêncio.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/tokens/app_colors.dart';
import 'package:fonar_app/design_system/widgets/app_icone.dart';

void main() {
  final pastaOrigem = Directory(NomeIcone.pastaOrigem);
  final pastaCompilada = Directory(NomeIcone.pastaCompilada);

  setUpAll(() {
    // Os testes leem caminhos relativos à raiz do pacote, que é o diretório de
    // trabalho do `flutter test`. Se a pasta não existe, o problema é outro e
    // não faz sentido reportar 19 falhas de ícone.
    expect(
      pastaOrigem.existsSync(),
      isTrue,
      reason: 'pasta ${NomeIcone.pastaOrigem} não encontrada',
    );
    expect(
      pastaCompilada.existsSync(),
      isTrue,
      reason:
          'pasta ${NomeIcone.pastaCompilada} não encontrada — rode '
          '`dart run tool/compilar_icones.dart`',
    );
  });

  group('enum NomeIcone e arquivos em disco', () {
    test('todo ícone do enum tem SVG correspondente', () {
      final semArquivo = NomeIcone.values
          .where((icone) => !File(icone.caminhoOrigem).existsSync())
          .map((icone) => '${icone.name} -> ${icone.caminhoOrigem}')
          .toList();

      expect(
        semArquivo,
        isEmpty,
        reason: 'ícone do enum sem arquivo em disco:\n${semArquivo.join('\n')}',
      );
    });

    test('todo SVG em disco tem entrada no enum', () {
      final registrados = NomeIcone.values.map((i) => i.arquivo).toSet();
      final emDisco = _nomesDeArquivo(pastaOrigem, NomeIcone.extensaoOrigem);
      final orfaos = emDisco.difference(registrados).toList()..sort();

      expect(
        orfaos,
        isEmpty,
        reason:
            'SVG em ${NomeIcone.pastaOrigem} sem entrada no enum '
            'NomeIcone: ${orfaos.join(', ')}.\n'
            'Registre no enum ou apague o arquivo (e o espelho na landing '
            'page). Ícone que não está no enum nunca é desenhado.',
      );
    });

    test('nome de arquivo bate com a convenção kebab-case do enum', () {
      final foraDaConvencao = NomeIcone.values
          .where(
            (icone) => !RegExp(r'^[a-z]+(-[a-z]+)*$').hasMatch(icone.arquivo),
          )
          .map((icone) => icone.arquivo)
          .toList();

      expect(
        foraDaConvencao,
        isEmpty,
        reason: 'arquivo fora do kebab-case: ${foraDaConvencao.join(', ')}',
      );
    });
  });

  group('binários pré-compilados', () {
    // O Flutter não tem gancho de pré-build no canal estável, então a
    // compilação é um comando manual. Estes testes são a rede que impede
    // esquecer de rodar `dart run tool/compilar_icones.dart`.
    test('todo ícone do enum tem .vec correspondente', () {
      final semBinario = NomeIcone.values
          .where((icone) => !File(icone.caminhoCompilado).existsSync())
          .map((icone) => icone.caminhoCompilado)
          .toList();

      expect(
        semBinario,
        isEmpty,
        reason:
            'ícone sem binário pré-compilado — rode '
            '`dart run tool/compilar_icones.dart`:\n${semBinario.join('\n')}',
      );
    });

    test('nenhum .vec órfão', () {
      final registrados = NomeIcone.values.map((i) => i.arquivo).toSet();
      final emDisco = _nomesDeArquivo(
        pastaCompilada,
        NomeIcone.extensaoCompilada,
      );
      final orfaos = emDisco.difference(registrados).toList()..sort();

      expect(
        orfaos,
        isEmpty,
        reason:
            'binário sem ícone correspondente no enum: '
            '${orfaos.join(', ')}.\n'
            'Como ${NomeIcone.pastaCompilada} é declarada inteira no '
            'pubspec.yaml, arquivo órfão entra no bundle sem ninguém usar. '
            'Rode `dart run tool/compilar_icones.dart`, que remove órfãos.',
      );
    });

    test('nenhum .vec vazio', () {
      final vazios = NomeIcone.values
          .map((icone) => File(icone.caminhoCompilado))
          .where((arquivo) => arquivo.existsSync() && arquivo.lengthSync() == 0)
          .map((arquivo) => arquivo.path)
          .toList();

      expect(vazios, isEmpty, reason: 'binário vazio: ${vazios.join(', ')}');
    });
  });

  group('carregamento pelo bundle', () {
    // Paridade em disco não garante que o asset foi declarado no
    // `pubspec.yaml` nem que o binário decodifica. Estes dois passam pelo
    // caminho real: bundle -> AssetBytesLoader -> desenho.
    testWidgets('todo ícone do enum decodifica e desenha', (tester) async {
      for (final icone in NomeIcone.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(child: AppIcone(nome: icone)),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'falha ao carregar ${icone.caminhoCompilado}',
        );
      }
    });

    testWidgets('herda cor e tamanho do IconTheme em volta', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IconTheme(
            data: IconThemeData(color: AppColors.cinzaChumbo, size: 32),
            child: Center(child: AppIcone(nome: NomeIcone.gravar)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(AppIcone)), const Size(32, 32));
    });

    testWidgets('sem rótulo semântico o ícone é decorativo', (tester) async {
      final semantica = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: AppIcone(nome: NomeIcone.avancar)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('avançar'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AppIcone(
              nome: NomeIcone.avancar,
              rotuloSemantico: 'avançar',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('avançar'), findsOneWidget);

      semantica.dispose();
    });
  });

  group('contrato de ponto único de carregamento', () {
    test('só o componente de ícone importa biblioteca de SVG', () {
      const componente = 'lib/design_system/widgets/app_icone.dart';
      final bibliotecas = RegExp(r'''package:(flutter_svg|vector_graphics)''');

      final infratores =
          Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((arquivo) => arquivo.path.endsWith('.dart'))
              .map((arquivo) => arquivo.path.replaceAll(r'\', '/'))
              .where((caminho) => caminho != componente)
              .where(
                (caminho) =>
                    bibliotecas.hasMatch(File(caminho).readAsStringSync()),
              )
              .toList()
            ..sort();

      expect(
        infratores,
        isEmpty,
        reason:
            'SVG deve ser carregado só por $componente, via AppIcone. '
            'Importam biblioteca de SVG direto:\n${infratores.join('\n')}',
      );
    });

    test('nenhum arquivo em lib/ referencia caminho de ícone como string', () {
      final caminhoSolto = RegExp(
        '${NomeIcone.pastaOrigem}/|${NomeIcone.pastaCompilada}/',
      );

      final infratores =
          Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((arquivo) => arquivo.path.endsWith('.dart'))
              .map((arquivo) => arquivo.path.replaceAll(r'\', '/'))
              .where((caminho) {
                // No componente, o caminho aparece só dentro do enum e em
                // comentário — é lá que ele deve morar.
                if (caminho == 'lib/design_system/widgets/app_icone.dart') {
                  return false;
                }
                return caminhoSolto.hasMatch(File(caminho).readAsStringSync());
              })
              .toList()
            ..sort();

      expect(
        infratores,
        isEmpty,
        reason:
            'caminho de ícone escrito como string solta. Use '
            'NomeIcone:\n${infratores.join('\n')}',
      );
    });
  });
}

/// Nomes de arquivo, sem extensão, dos arquivos de [pasta] que terminam em
/// [extensao]. Ignora o que não é ícone, como o README.
Set<String> _nomesDeArquivo(Directory pasta, String extensao) {
  return pasta
      .listSync()
      .whereType<File>()
      .map((arquivo) => arquivo.uri.pathSegments.last)
      .where((nome) => nome.endsWith(extensao))
      .map((nome) => nome.substring(0, nome.length - extensao.length))
      .toSet();
}
