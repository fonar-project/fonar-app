import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/tokens/app_colors.dart';
import 'package:fonar_app/design_system/widgets/app_icone.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/pacientes_list_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

const _celular = Size(390, 844);
const _desktop = Size(1440, 900);

final _lista = [
  Paciente(
    id: 'a',
    nome: 'Ana de Teste',
    queixa: 'rouquidão',
    ultimaSessao: DateTime(2026, 7, 2),
    direcaoAvqi: DirecaoDaMedida.desceu,
  ),
  Paciente(
    id: 'b',
    nome: 'Bruno de Teste',
    queixa: 'soprosidade',
    ultimaSessao: DateTime(2026, 6, 25),
    direcaoAvqi: DirecaoDaMedida.subiu,
  ),
  const Paciente(
    id: 'c',
    nome: 'Clara de Teste',
    queixa: 'fadiga vocal',
    direcaoAvqi: DirecaoDaMedida.semComparacao,
  ),
];

/// Página de destino genérica: mostra o caminho a que se chegou.
Widget _destino(GoRouterState estado) =>
    Scaffold(body: Text('destino ${estado.uri.path}'));

Future<void> _abrir(
  WidgetTester tester, {
  Size tamanho = _celular,
  Future<List<Paciente>> Function()? pacientes,
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final roteador = GoRouter(
    initialLocation: AppRoutes.pacientesCaminho,
    routes: [
      GoRoute(
        name: AppRoutes.pacientesNome,
        path: AppRoutes.pacientesCaminho,
        builder: (_, _) => const PacientesListPage(),
        routes: [
          GoRoute(
            name: AppRoutes.novaAvaliacaoNome,
            path: AppRoutes.novaAvaliacaoCaminho,
            builder: (_, estado) => _destino(estado),
          ),
          GoRoute(
            name: AppRoutes.pacienteDetalheNome,
            path: AppRoutes.pacienteDetalheCaminho,
            builder: (_, estado) => _destino(estado),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.filaNome,
        path: AppRoutes.filaCaminho,
        builder: (_, estado) => _destino(estado),
      ),
      GoRoute(
        name: AppRoutes.contaNome,
        path: AppRoutes.contaCaminho,
        builder: (_, estado) => _destino(estado),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      // O Riverpod 3 tenta de novo sozinho quando um provider falha. Aqui a
      // falha precisa chegar à tela, que é o que está sendo testado.
      retry: (_, _) => null,
      overrides: [
        pacientesProvider.overrideWith(
          (ref) => pacientes == null ? Future.value(_lista) : pacientes(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _buscar(WidgetTester tester, String termo) async {
  await tester.enterText(find.byType(TextField), termo);
  await tester.pumpAndSettle();
}

void main() {
  group('lista', () {
    for (final (nome, tamanho) in [
      ('celular', _celular),
      ('desktop', _desktop),
    ]) {
      testWidgets('$nome mostra todos os pacientes', (tester) async {
        await _abrir(tester, tamanho: tamanho);
        for (final p in _lista) {
          expect(find.text(p.nome), findsOneWidget);
        }
      });

      testWidgets('$nome avisa que tendência não é diagnóstico', (
        tester,
      ) async {
        await _abrir(tester, tamanho: tamanho);
        expect(find.text(AppStrings.pacientesNotaTendencia), findsOneWidget);
      });
    }

    testWidgets('desktop mostra contagem e cabeçalho da tabela', (
      tester,
    ) async {
      await _abrir(tester, tamanho: _desktop);
      expect(find.text(AppStrings.pacientesQuantidade(3)), findsOneWidget);
      expect(
        find.text(AppStrings.pacientesColunaTendencia.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('a seta mostra a direção do AVQI, não a leitura', (
      tester,
    ) async {
      // O defeito que originou `lerEvolucao`: a lista mostrava seta para cima
      // ao lado de "melhorando" para um AVQI que tinha caído, contradizendo o
      // número e o gráfico da tela de evolução. No AVQI menor é melhor, então
      // melhora vem com seta para BAIXO.
      await _abrir(tester, tamanho: _desktop);

      final setas = tester
          .widgetList<AppIcone>(find.byType(AppIcone))
          .map((i) => i.nome)
          .toSet();

      // Ana caiu (melhorando), Bruno subiu (piorando).
      expect(find.text(AppStrings.tendenciaMelhorando), findsOneWidget);
      expect(find.text(AppStrings.tendenciaPiorando), findsOneWidget);
      expect(setas, contains(NomeIcone.tendenciaDesce));
      expect(setas, contains(NomeIcone.tendenciaSobe));
    });

    testWidgets('paciente sem sessão não recebe tendência', (tester) async {
      await _abrir(tester);
      expect(find.text(AppStrings.tendenciaSemComparacao), findsOneWidget);
      expect(find.text(AppStrings.pacientesNenhumaSessao), findsOneWidget);
    });

    testWidgets('tendência não usa cor de status de medida', (tester) async {
      // Verde e vermelho são reservados a status de normalidade de medida e
      // saturação de áudio. O protótipo pinta a tendência com eles; aqui não.
      //
      // O chip é uma pílula: ele pinta ÍCONE, TEXTO, BORDA e — se algum dia
      // ganhar preenchimento — o fundo. Olhar só o ícone e o texto deixava a
      // borda livre para voltar a ser verde ou vermelha sem quebrar teste
      // nenhum, e a borda é o traço mais visível dessa pílula.
      final reservadas = {AppColors.sucesso, AppColors.atencao, AppColors.erro};
      await _abrir(tester, tamanho: _desktop);

      // Container com decoração constrói um DecoratedBox: um finder só cobre
      // as duas formas de pintar caixa que a tela usa.
      final cores = <Color?>[
        ...tester.widgetList<AppIcone>(find.byType(AppIcone)).map((i) => i.cor),
        ...tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.style?.color),
      ];
      for (final caixa in tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      )) {
        if (caixa.decoration case final BoxDecoration decoracao) {
          cores.add(decoracao.color);
          if (decoracao.border case final Border borda) {
            cores.addAll([
              borda.top.color,
              borda.right.color,
              borda.bottom.color,
              borda.left.color,
            ]);
          }
        }
      }

      expect(find.byType(DecoratedBox), findsWidgets, reason: 'há o que olhar');
      expect(cores.where(reservadas.contains), isEmpty);
    });

    testWidgets('tocar no paciente abre o perfil dele', (tester) async {
      await _abrir(tester);
      await tester.tap(find.text('Bruno de Teste'));
      await tester.pumpAndSettle();
      expect(find.text('destino /pacientes/b'), findsOneWidget);
    });

    testWidgets('"Nova avaliação" leva ao cadastro', (tester) async {
      await _abrir(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.navNovaAvaliacao),
      );
      await tester.pumpAndSettle();
      expect(find.text('destino /pacientes/novo'), findsOneWidget);
    });
  });

  group('busca', () {
    testWidgets('o leitor de tela anuncia o campo pelo nome', (tester) async {
      // O campo não tem rótulo visível: a dica faz esse papel na tela e SOME
      // quando se digita. Sem rótulo declarado, o campo passava a ser
      // anunciado como uma caixa de edição sem nome assim que tinha texto.
      final semantica = tester.ensureSemantics();
      await _abrir(tester);

      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(label: AppStrings.pacientesBuscaDica, isTextField: true),
        reason: 'campo vazio: o nome vem do rótulo, não da dica duplicada',
      );

      await _buscar(tester, 'rouquidao');
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(label: AppStrings.pacientesBuscaDica, isTextField: true),
        reason: 'com texto digitado o campo continua tendo nome',
      );
      semantica.dispose();
    });

    testWidgets('filtra por queixa, sem acento', (tester) async {
      await _abrir(tester);
      await _buscar(tester, 'rouquidao');

      expect(find.text('Ana de Teste'), findsOneWidget);
      expect(find.text('Bruno de Teste'), findsNothing);
    });

    testWidgets('sem resultado oferece limpar a busca', (tester) async {
      await _abrir(tester);
      await _buscar(tester, 'xyz');

      expect(
        find.text(AppStrings.pacientesSemResultado('xyz')),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.pacientesLimparBusca));
      await tester.pumpAndSettle();
      expect(find.text('Ana de Teste'), findsOneWidget);
    });
  });

  group('estados', () {
    testWidgets('primeiro uso convida a cadastrar', (tester) async {
      await _abrir(tester, pacientes: () async => []);
      expect(find.text(AppStrings.pacientesVaziaTitulo), findsOneWidget);
      expect(find.text(AppStrings.pacientesCadastrar), findsOneWidget);
      // Um primário só: o "Nova avaliação" fixo levaria ao mesmo lugar.
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('falha ao carregar oferece tentar de novo', (tester) async {
      var tentativas = 0;
      await _abrir(
        tester,
        pacientes: () async {
          tentativas++;
          if (tentativas == 1) throw Exception('banco local indisponível');
          return _lista;
        },
      );
      expect(find.text(AppStrings.pacientesErroCarregar), findsOneWidget);

      await tester.tap(find.text(AppStrings.tentarNovamente));
      await tester.pumpAndSettle();
      expect(find.text('Ana de Teste'), findsOneWidget);
    });
  });

  group('texto ampliado pelo sistema', () {
    for (final (nome, pacientes) in [
      ('lista', null),
      ('lista vazia', () async => <Paciente>[]),
    ]) {
      testWidgets('celular com $nome em 200% não estoura', (tester) async {
        await _abrir(tester, pacientes: pacientes, escala: 2);
        expect(tester.takeException(), isNull);
      });
    }

    // O desktop tinha a mesma exigência e nenhuma cobertura: a tabela estourava
    // à direita a partir de 1,3× (coluna presa em pixel, rótulo do chip sem
    // quebra) e a barra lateral estourava por baixo em 2×. 125% e 150% são
    // escalas comuns no Windows, não caso extremo.
    //
    // `esperaTabela` NÃO é decoração: em 1024 px de janela a tabela nem chega a
    // aparecer, porque o `LayoutBuilder` mede a área de conteúdo DEPOIS dos
    // 222 px da barra lateral — 1024 − 222 = 802, que ainda é faixa média, e o
    // layout cai para cards. Sem essa asserção o caso "desktop estreito"
    // passaria sem nunca exercitar a tabela. A tabela começa em 1246 px.
    for (final (largura, esperaTabela) in [
      (1024.0, false),
      (1280.0, true),
      (1440.0, true),
    ]) {
      for (final escala in [1.0, 1.3, 1.5, 2.0]) {
        testWidgets(
          'janela de ${largura.toInt()}px em ${escala}x não estoura',
          (tester) async {
            await _abrir(tester, tamanho: Size(largura, 900), escala: escala);

            expect(
              find.text(AppStrings.pacientesColunaTendencia.toUpperCase()),
              esperaTabela ? findsOneWidget : findsNothing,
              reason: esperaTabela
                  ? 'esta largura deve exercitar a TABELA'
                  : 'abaixo de 1246px o conteúdo cai para cards',
            );
            expect(find.text('Ana de Teste'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('navegação principal', () {
    for (final (nome, tamanho, rotulo) in [
      ('celular', _celular, AppStrings.navFilaCurto),
      ('desktop', _desktop, AppStrings.navFila),
    ]) {
      testWidgets('$nome leva à fila', (tester) async {
        await _abrir(tester, tamanho: tamanho);
        await tester.tap(find.text(rotulo));
        await tester.pumpAndSettle();
        expect(find.text('destino /fila'), findsOneWidget);
      });
    }

    testWidgets('marca a aba ativa para o leitor de tela', (tester) async {
      await _abrir(tester);
      expect(
        tester.getSemantics(find.text(AppStrings.navPacientes)),
        isSemantics(isSelected: true, isButton: true),
      );
    });
  });
}
