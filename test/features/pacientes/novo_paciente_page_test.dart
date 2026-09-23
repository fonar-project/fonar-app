import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_campo_texto.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_placeholder.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/pacientes/domain/repositorio_pacientes.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/novo_paciente_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

/// Repositório controlável pelo teste.
class _RepositorioFalso implements RepositorioPacientes {
  _RepositorioFalso({this.erro});

  /// Lançado em [cadastrar], se preenchido.
  final AppException? erro;

  final cadastrados = <NovoPaciente>[];

  @override
  Future<List<Paciente>> listar() async => const [];

  @override
  Future<Paciente> cadastrar(NovoPaciente novo) async {
    if (erro case final erro?) throw erro;
    cadastrados.add(novo);
    return Paciente(
      id: 'novo-1',
      nome: novo.nome,
      queixa: novo.queixa,
      direcaoAvqi: DirecaoDaMedida.semComparacao,
    );
  }
}

const _celular = Size(390, 844);
const _desktop = Size(1440, 900);

/// Página de destino genérica: mostra o caminho a que se chegou.
Widget _destino(GoRouterState estado) =>
    Scaffold(body: Text('destino ${estado.uri.path}'));

Future<_RepositorioFalso> _abrir(
  WidgetTester tester, {
  Size tamanho = _celular,
  double escala = 1,
  bool online = true,
  _RepositorioFalso? repositorio,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final repo = repositorio ?? _RepositorioFalso();
  final roteador = GoRouter(
    initialLocation: AppRoutes.novaAvaliacaoCaminhoCompleto,
    routes: [
      GoRoute(
        name: AppRoutes.pacientesNome,
        path: AppRoutes.pacientesCaminho,
        builder: (_, estado) => _destino(estado),
        routes: [
          GoRoute(
            name: AppRoutes.novaAvaliacaoNome,
            path: AppRoutes.novaAvaliacaoCaminho,
            builder: (_, _) => const NovoPacientePage(),
          ),
          GoRoute(
            name: AppRoutes.pacienteDetalheNome,
            path: AppRoutes.pacienteDetalheCaminho,
            builder: (_, estado) => _destino(estado),
            routes: [
              GoRoute(
                name: AppRoutes.consentimentoNome,
                path: AppRoutes.consentimentoCaminho,
                builder: (_, estado) => _destino(estado),
              ),
            ],
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
      overrides: [
        repositorioPacientesProvider.overrideWithValue(repo),
        // Sem isto o indicador de conexão chama o plugin, que não existe no
        // ambiente de teste.
        conexaoOnlineProvider.overrideWithValue(online),
      ],
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Finder _campo(String rotulo) => find.descendant(
  of: find.widgetWithText(AppCampoTexto, rotulo),
  matching: find.byType(TextField),
);

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _preencher(
  WidgetTester tester, {
  String nome = 'Ana de Teste',
  String nascimento = '02071985',
  String? sexo = AppStrings.cadastroSexoFeminino,
  String queixa = 'rouquidão',
}) async {
  await tester.enterText(_campo(AppStrings.cadastroCampoNome), nome);
  await tester.enterText(
    _campo(AppStrings.cadastroCampoNascimento),
    nascimento,
  );
  if (sexo != null) await _tocar(tester, find.text(sexo));
  await tester.enterText(_campo(AppStrings.cadastroCampoQueixa), queixa);
  await tester.pumpAndSettle();
}

Future<void> _salvar(WidgetTester tester) =>
    _tocar(tester, find.text(AppStrings.cadastroSalvar));

void main() {
  for (final (nome, tamanho) in [
    ('celular', _celular),
    ('desktop', _desktop),
  ]) {
    testWidgets('$nome mostra o formulário inteiro', (tester) async {
      await _abrir(tester, tamanho: tamanho);

      expect(find.text(AppStrings.cadastroTitulo), findsOneWidget);
      for (final rotulo in [
        AppStrings.cadastroCampoNome,
        AppStrings.cadastroCampoNascimento,
        AppStrings.cadastroCampoSexo,
        AppStrings.cadastroCampoQueixa,
      ]) {
        expect(find.text(rotulo), findsOneWidget, reason: rotulo);
      }
      expect(find.text(AppStrings.cadastroSexoApoio), findsOneWidget);
      expect(find.text(AppStrings.cadastroSalvar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nome não estoura com o texto do sistema em 200%', (
      tester,
    ) async {
      await _abrir(tester, tamanho: tamanho, escala: 2);
      await _salvar(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.cadastroInformeNome), findsOneWidget);
    });
  }

  testWidgets('a data ganha as barras enquanto se digita', (tester) async {
    await _abrir(tester);

    await tester.enterText(
      _campo(AppStrings.cadastroCampoNascimento),
      '02071985',
    );
    await tester.pump();

    expect(find.text('02/07/1985'), findsOneWidget);
  });

  testWidgets('salvar vazio aponta cada campo, com texto, e não salva', (
    tester,
  ) async {
    final repo = await _abrir(tester);

    await _salvar(tester);

    for (final erro in [
      AppStrings.cadastroInformeNome,
      AppStrings.cadastroInformeNascimento,
      AppStrings.cadastroEscolhaSexo,
      AppStrings.cadastroInformeQueixa,
    ]) {
      expect(find.text(erro), findsOneWidget, reason: erro);
    }
    // O erro do sexo substitui o texto de apoio, não se soma a ele.
    expect(find.text(AppStrings.cadastroSexoApoio), findsNothing);
    expect(repo.cadastrados, isEmpty);
  });

  testWidgets('corrigir um campo tira o erro só dele', (tester) async {
    await _abrir(tester);
    await _salvar(tester);

    await tester.enterText(_campo(AppStrings.cadastroCampoNome), 'A');
    await _tocar(tester, find.text(AppStrings.cadastroSexoFeminino));

    expect(find.text(AppStrings.cadastroInformeNome), findsNothing);
    expect(find.text(AppStrings.cadastroEscolhaSexo), findsNothing);
    // O apoio volta quando o erro sai.
    expect(find.text(AppStrings.cadastroSexoApoio), findsOneWidget);
    // Os outros continuam apontados até serem corrigidos.
    expect(find.text(AppStrings.cadastroInformeNascimento), findsOneWidget);
    expect(find.text(AppStrings.cadastroInformeQueixa), findsOneWidget);
  });

  testWidgets('erro de campo leva o foco ao primeiro campo com problema', (
    tester,
  ) async {
    await _abrir(tester);
    await _preencher(tester, nome: '', nascimento: '31021990');

    await _salvar(tester);

    final nome = tester.widget<TextField>(_campo(AppStrings.cadastroCampoNome));
    expect(nome.focusNode!.hasFocus, isTrue);
    expect(find.text(AppStrings.cadastroNascimentoInvalido), findsOneWidget);
  });

  testWidgets('dados completos salvam e seguem para o consentimento', (
    tester,
  ) async {
    final repo = await _abrir(tester);
    await _preencher(tester, sexo: AppStrings.cadastroSexoNaoInformado);

    await _salvar(tester);

    expect(repo.cadastrados, hasLength(1));
    final salvo = repo.cadastrados.single;
    expect(salvo.nome, 'Ana de Teste');
    expect(salvo.dataDeNascimento, DateTime(1985, 7, 2));
    expect(salvo.sexo, SexoDeReferencia.naoInformado);
    expect(salvo.queixa, 'rouquidão');
    expect(
      find.text('destino /pacientes/novo-1/consentimento'),
      findsOneWidget,
    );
  });

  testWidgets('sem conexão também salva: o cadastro fica no aparelho', (
    tester,
  ) async {
    final repo = await _abrir(tester, online: false);
    await _preencher(tester);
    expect(find.text(AppStrings.conexaoOffline), findsOneWidget);

    await _salvar(tester);

    expect(repo.cadastrados, hasLength(1));
    expect(
      find.text('destino /pacientes/novo-1/consentimento'),
      findsOneWidget,
    );
  });

  testWidgets('falha ao salvar fica na tela, com mensagem', (tester) async {
    final repo = await _abrir(
      tester,
      repositorio: _RepositorioFalso(erro: const FalhaDeConexao()),
    );
    await _preencher(tester);

    await _salvar(tester);

    expect(find.text(AppStrings.erroConexao), findsOneWidget);
    expect(find.byType(NovoPacientePage), findsOneWidget);
    expect(repo.cadastrados, isEmpty);
  });

  testWidgets('cancelar volta para a lista sem salvar', (tester) async {
    final repo = await _abrir(tester);
    await _preencher(tester);

    await _tocar(tester, find.text(AppStrings.cadastroCancelar));

    expect(find.text('destino /pacientes'), findsOneWidget);
    expect(repo.cadastrados, isEmpty);
  });

  testWidgets('leitor de tela anuncia a opção escolhida como marcada', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _abrir(tester);

    await _tocar(tester, find.text(AppStrings.cadastroSexoMasculino));

    expect(
      tester.getSemantics(find.text(AppStrings.cadastroSexoMasculino)),
      isSemantics(
        label: AppStrings.cadastroSexoMasculino,
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: true,
      ),
    );
    expect(
      tester.getSemantics(find.text(AppStrings.cadastroSexoFeminino)),
      isSemantics(
        label: AppStrings.cadastroSexoFeminino,
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: false,
      ),
    );
    semantica.dispose();
  });
}
