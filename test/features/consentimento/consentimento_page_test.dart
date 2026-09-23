import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_campo_texto.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/domain/repositorio_consentimento.dart';
import 'package:fonar_app/features/consentimento/presentation/pages/consentimento_page.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

/// Repositório controlável pelo teste.
class _RepositorioFalso implements RepositorioConsentimento {
  _RepositorioFalso({this.existente, this.erroAoRegistrar});

  Consentimento? existente;
  final AppException? erroAoRegistrar;
  final registrados = <PedidoDeConsentimento>[];

  @override
  Future<Consentimento?> buscar(String pacienteId) async => existente;

  @override
  Future<Consentimento> registrar(
    String pacienteId,
    PedidoDeConsentimento pedido,
  ) async {
    if (erroAoRegistrar case final erro?) throw erro;
    registrados.add(pedido);
    return existente = Consentimento(
      pacienteId: pacienteId,
      registradoEm: DateTime(2026, 9, 23, 10, 5),
      versaoDoTermo: 'teste-1',
      quemAutoriza: pedido.quemAutoriza,
      nomeDoResponsavel: pedido.nomeDoResponsavel,
    );
  }
}

const _celular = Size(390, 844);
const _desktop = Size(1440, 900);
const _paciente = Paciente(
  id: 'p1',
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
);

Widget _destino(GoRouterState estado) =>
    Scaffold(body: Text('destino ${estado.uri.path}'));

Future<_RepositorioFalso> _abrir(
  WidgetTester tester, {
  Size tamanho = _celular,
  double escala = 1,
  String pacienteId = 'p1',
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
    initialLocation: '/pacientes/$pacienteId/consentimento',
    routes: [
      GoRoute(
        name: AppRoutes.pacientesNome,
        path: AppRoutes.pacientesCaminho,
        builder: (_, estado) => _destino(estado),
        routes: [
          GoRoute(
            name: AppRoutes.pacienteDetalheNome,
            path: AppRoutes.pacienteDetalheCaminho,
            builder: (_, estado) => _destino(estado),
            routes: [
              GoRoute(
                name: AppRoutes.consentimentoNome,
                path: AppRoutes.consentimentoCaminho,
                builder: (_, estado) => ConsentimentoPage(
                  pacienteId: estado.pathParameters[AppRoutes.paramPacienteId]!,
                ),
              ),
              GoRoute(
                name: AppRoutes.capturaNome,
                path: AppRoutes.capturaCaminho,
                builder: (_, estado) => _destino(estado),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositorioConsentimentoProvider.overrideWithValue(repo),
        pacientesProvider.overrideWith((ref) async => [_paciente]),
        conexaoOnlineProvider.overrideWithValue(true),
      ],
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _registrar(WidgetTester tester) =>
    _tocar(tester, find.text(AppStrings.consentimentoRegistrar));

Finder get _campoResponsavel => find.descendant(
  of: find.widgetWithText(
    AppCampoTexto,
    AppStrings.consentimentoCampoResponsavel,
  ),
  matching: find.byType(TextField),
);

void main() {
  for (final (nome, tamanho) in [
    ('celular', _celular),
    ('desktop', _desktop),
  ]) {
    testWidgets('$nome sem registro mostra o termo e o formulário', (
      tester,
    ) async {
      await _abrir(tester, tamanho: tamanho);

      expect(
        find.text(AppStrings.consentimentoPaciente('Ana de Teste')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.consentimentoNaoRegistrado), findsOneWidget);
      expect(find.text(AppStrings.consentimentoTermoTitulo), findsOneWidget);
      for (final item in AppStrings.consentimentoTermoItens) {
        expect(find.text(item), findsOneWidget);
      }
      expect(find.text(AppStrings.consentimentoRegistrar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nome não estoura com o texto do sistema em 200%', (
      tester,
    ) async {
      await _abrir(tester, tamanho: tamanho, escala: 2);
      await _registrar(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.consentimentoEscolhaQuem), findsOneWidget);
    });
  }

  testWidgets('registrar vazio aponta o que falta e não registra', (
    tester,
  ) async {
    final repo = await _abrir(tester);

    await _registrar(tester);

    expect(find.text(AppStrings.consentimentoEscolhaQuem), findsOneWidget);
    expect(
      find.text(AppStrings.consentimentoMarqueConcordancia),
      findsOneWidget,
    );
    expect(repo.registrados, isEmpty);
  });

  testWidgets('o campo do responsável só aparece quando é ele quem autoriza', (
    tester,
  ) async {
    await _abrir(tester);
    expect(_campoResponsavel, findsNothing);

    await _tocar(tester, find.text(AppStrings.consentimentoQuemResponsavel));
    expect(_campoResponsavel, findsOneWidget);

    await _tocar(tester, find.text(AppStrings.consentimentoQuemPaciente));
    expect(_campoResponsavel, findsNothing);
  });

  testWidgets('responsável sem nome não registra e ganha o foco', (
    tester,
  ) async {
    final repo = await _abrir(tester);
    await _tocar(tester, find.text(AppStrings.consentimentoQuemResponsavel));
    await _tocar(tester, find.text(AppStrings.consentimentoConcordancia));

    await _registrar(tester);

    expect(
      find.text(AppStrings.consentimentoInformeResponsavel),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(_campoResponsavel).focusNode!.hasFocus,
      isTrue,
    );
    expect(repo.registrados, isEmpty);
  });

  testWidgets('registrado pelo paciente, segue para a gravação', (
    tester,
  ) async {
    final repo = await _abrir(tester);
    await _tocar(tester, find.text(AppStrings.consentimentoQuemPaciente));
    await _tocar(tester, find.text(AppStrings.consentimentoConcordancia));

    await _registrar(tester);

    expect(repo.registrados.single.quemAutoriza, QuemAutoriza.paciente);
    expect(find.text('destino /pacientes/p1/captura'), findsOneWidget);
  });

  testWidgets('registrado pelo responsável, guarda o nome', (tester) async {
    final repo = await _abrir(tester);
    await _tocar(tester, find.text(AppStrings.consentimentoQuemResponsavel));
    await tester.enterText(_campoResponsavel, 'Maria de Teste');
    await _tocar(tester, find.text(AppStrings.consentimentoConcordancia));

    await _registrar(tester);

    final pedido = repo.registrados.single;
    expect(pedido.quemAutoriza, QuemAutoriza.responsavelLegal);
    expect(pedido.nomeDoResponsavel, 'Maria de Teste');
  });

  testWidgets('falha ao registrar fica na tela, com mensagem', (tester) async {
    final repo = await _abrir(
      tester,
      repositorio: _RepositorioFalso(erroAoRegistrar: const FalhaDeConexao()),
    );
    await _tocar(tester, find.text(AppStrings.consentimentoQuemPaciente));
    await _tocar(tester, find.text(AppStrings.consentimentoConcordancia));

    await _registrar(tester);

    expect(find.text(AppStrings.erroConexao), findsOneWidget);
    expect(find.byType(ConsentimentoPage), findsOneWidget);
    expect(repo.registrados, isEmpty);
  });

  testWidgets('já registrado mostra quando, por quem e a versão do termo', (
    tester,
  ) async {
    await _abrir(
      tester,
      repositorio: _RepositorioFalso(
        existente: Consentimento(
          pacienteId: 'p1',
          registradoEm: DateTime(2026, 9, 1, 9, 5),
          versaoDoTermo: 'teste-1',
          quemAutoriza: QuemAutoriza.responsavelLegal,
          nomeDoResponsavel: 'Maria de Teste',
        ),
      ),
    );

    expect(find.text(AppStrings.consentimentoRegistrado), findsOneWidget);
    expect(
      find.text(
        AppStrings.consentimentoRegistradoTexto(
          data: '01 set 2026',
          hora: '09:05',
          quem: AppStrings.consentimentoPeloResponsavel('Maria de Teste'),
          versao: 'teste-1',
        ),
      ),
      findsOneWidget,
    );
    // Nada de formulário quando já está registrado.
    expect(find.text(AppStrings.consentimentoRegistrar), findsNothing);

    await _tocar(tester, find.text(AppStrings.consentimentoIniciarGravacao));
    expect(find.text('destino /pacientes/p1/captura'), findsOneWidget);
  });

  testWidgets('paciente que não está no aparelho não abre o formulário', (
    tester,
  ) async {
    await _abrir(tester, pacienteId: 'inexistente');

    expect(
      find.text(AppStrings.consentimentoPacienteNaoEncontrado),
      findsOneWidget,
    );
    expect(find.text(AppStrings.consentimentoRegistrar), findsNothing);
  });

  testWidgets('leitor de tela anuncia a concordância como caixa marcada', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _abrir(tester);

    final caixa = find.text(AppStrings.consentimentoConcordancia);
    expect(
      tester.getSemantics(caixa),
      isSemantics(hasCheckedState: true, isChecked: false, isButton: true),
    );

    await _tocar(tester, caixa);
    expect(
      tester.getSemantics(caixa),
      isSemantics(hasCheckedState: true, isChecked: true, isButton: true),
    );
    semantica.dispose();
  });
}
