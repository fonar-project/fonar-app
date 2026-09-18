import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:praatico_app/app/router/app_routes.dart';
import 'package:praatico_app/design_system/theme/app_theme.dart';
import 'package:praatico_app/design_system/tokens/app_colors.dart';
import 'package:praatico_app/design_system/widgets/app_icone.dart';
import 'package:praatico_app/features/pacientes/data/repositorio_pacientes_placeholder.dart';
import 'package:praatico_app/features/pacientes/domain/paciente.dart';
import 'package:praatico_app/features/pacientes/presentation/pages/pacientes_list_page.dart';
import 'package:praatico_app/l10n/app_strings.dart';

const _celular = Size(390, 844);
const _desktop = Size(1440, 900);

final _lista = [
  Paciente(
    id: 'a',
    nome: 'Ana de Teste',
    queixa: 'rouquidão',
    ultimaSessao: DateTime(2026, 7, 2),
    tendencia: TendenciaAvqi.melhorando,
  ),
  Paciente(
    id: 'b',
    nome: 'Bruno de Teste',
    queixa: 'soprosidade',
    ultimaSessao: DateTime(2026, 6, 25),
    tendencia: TendenciaAvqi.piorando,
  ),
  const Paciente(
    id: 'c',
    nome: 'Clara de Teste',
    queixa: 'fadiga vocal',
    tendencia: TendenciaAvqi.semComparacao,
  ),
];

/// Página de destino genérica: mostra o caminho a que se chegou.
Widget _destino(GoRouterState estado) =>
    Scaffold(body: Text('destino ${estado.uri.path}'));

Future<void> _abrir(
  WidgetTester tester, {
  Size tamanho = _celular,
  Future<List<Paciente>> Function()? pacientes,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

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

    testWidgets('paciente sem sessão não recebe tendência', (tester) async {
      await _abrir(tester);
      expect(find.text(AppStrings.tendenciaSemComparacao), findsOneWidget);
      expect(find.text(AppStrings.pacientesNenhumaSessao), findsOneWidget);
    });

    testWidgets('tendência não usa cor de status de medida', (tester) async {
      // Verde e vermelho são reservados a status de normalidade de medida e
      // saturação de áudio. O protótipo pinta a tendência com eles; aqui não.
      final reservadas = {AppColors.sucesso, AppColors.atencao, AppColors.erro};
      await _abrir(tester, tamanho: _desktop);

      final cores = [
        ...tester.widgetList<AppIcone>(find.byType(AppIcone)).map((i) => i.cor),
        ...tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.style?.color),
      ];
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
