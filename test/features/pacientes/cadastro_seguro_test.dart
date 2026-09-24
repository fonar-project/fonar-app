import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_campo_texto.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/pacientes_de_exemplo.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/duplicidade.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/editar_paciente_page.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/novo_paciente_page.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/paciente_detalhe_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';

NovoPaciente _dados({
  String nome = 'Ana de Teste',
  String nascimento = '14/03/1990',
}) => (validarCadastro(
  nome: nome,
  nascimento: nascimento,
  sexo: SexoDeReferencia.feminino,
  queixa: 'rouquidão (teste)',
  hoje: DateTime(2026, 9, 24),
) as CadastroValido).paciente;

Paciente _paciente(String id, String nome, DateTime? nascimento) => Paciente(
  id: id,
  nome: nome,
  queixa: 'q',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
  dataDeNascimento: nascimento,
);

class _Cena {
  _Cena(this.roteador, this.pacientes, this.ana, this.bia);
  final GoRouter roteador;
  final RepositorioPacientesPlaceholder pacientes;
  final Paciente ana;
  final Paciente bia;

  String get caminho =>
      roteador.routerDelegate.currentConfiguration.uri.toString();
  Future<int> get cadastrados async =>
      (await pacientes.listar()).where((p) => !p.exemplo).length;
}

Future<_Cena> _abrir(
  WidgetTester tester, {
  String rota = AppRoutes.novaAvaliacaoNome,
  bool daBia = false,
  Size tamanho = const Size(390, 1600),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final pacientes = RepositorioPacientesPlaceholder();
  final ana = await pacientes.cadastrar(_dados());
  final bia = await pacientes.cadastrar(
    _dados(nome: 'Bia de Teste', nascimento: '01/01/2000'),
  );

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      conexaoOnlineProvider.overrideWithValue(false),
      relogioProvider.overrideWithValue(() => DateTime(2026, 9, 24)),
      repositorioPacientesProvider.overrideWithValue(pacientes),
      repositorioConsentimentoProvider.overrideWithValue(
        RepositorioConsentimentoPlaceholder(),
      ),
    ],
  );
  addTearDown(container.dispose);
  final roteador = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.claro, routerConfig: roteador),
    ),
  );
  roteador.goNamed(
    AppRoutes.pacienteDetalheNome,
    pathParameters: {AppRoutes.paramPacienteId: daBia ? bia.id : ana.id},
  );
  await tester.pumpAndSettle();
  if (rota == AppRoutes.novaAvaliacaoNome) {
    roteador.goNamed(rota);
  } else if (rota == AppRoutes.edicaoPacienteNome) {
    roteador.pushNamed(
      rota,
      pathParameters: {AppRoutes.paramPacienteId: daBia ? bia.id : ana.id},
    );
  }
  await tester.pumpAndSettle();
  return _Cena(roteador, pacientes, ana, bia);
}

Finder _campo(String rotulo) => find.descendant(
  of: find.widgetWithText(AppCampoTexto, rotulo),
  matching: find.byType(TextField),
);

Future<void> _tocar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto).last;
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _preencher(
  WidgetTester tester, {
  required String nome,
  required String nascimento,
}) async {
  await tester.enterText(_campo(AppStrings.cadastroCampoNome), nome);
  await tester.enterText(
    _campo(AppStrings.cadastroCampoNascimento),
    nascimento,
  );
  await _tocar(tester, AppStrings.cadastroSexoFeminino);
  await tester.enterText(_campo(AppStrings.cadastroCampoQueixa), 'rouquidão');
}

void main() {
  group('possivelDuplicado', () {
    final existentes = [
      _paciente('a', 'Ana Luísa de Teste', DateTime(1990, 3, 14)),
      _paciente('e', 'Paciente A. de Exemplo', null),
    ];

    test('mesmo nome — sem ligar para acento, maiúscula ou espaço — e mesmo '
        'nascimento', () {
      expect(
        possivelDuplicado(
          _dados(nome: '  ana  LUISA de teste ', nascimento: '14/03/1990'),
          existentes,
        )?.id,
        'a',
      );
    });

    test('nascimento diferente, ou nome diferente: não é o mesmo', () {
      expect(
        possivelDuplicado(
          _dados(nome: 'Ana Luísa de Teste', nascimento: '15/03/1990'),
          existentes,
        ),
        isNull,
      );
      expect(
        possivelDuplicado(
          _dados(nome: 'Ana Lúcia de Teste', nascimento: '14/03/1990'),
          existentes,
        ),
        isNull,
      );
    });

    test('na correção, o próprio paciente não conta', () {
      expect(
        possivelDuplicado(
          _dados(nome: 'Ana Luísa de Teste', nascimento: '14/03/1990'),
          existentes,
          ignorarId: 'a',
        ),
        isNull,
      );
    });

    test('sem nascimento no cadastro, não há como comparar', () {
      expect(
        possivelDuplicado(
          _dados(nome: pacientesDeExemplo.first.nome),
          pacientesDeExemplo,
        ),
        isNull,
      );
    });
  });

  group('cadastro', () {
    testWidgets('duplicado: não salva, avisa, e abre o que já existe', (
      tester,
    ) async {
      final c = await _abrir(tester);
      await _preencher(tester, nome: 'ana de teste', nascimento: '14/03/1990');

      await _tocar(tester, AppStrings.cadastroSalvar);

      expect(find.text(AppStrings.duplicadoTitulo), findsOneWidget);
      expect(await c.cadastrados, 2);

      await _tocar(tester, AppStrings.duplicadoAbrirExistente);
      // Escolheu o existente: sai sem perguntar nada.
      expect(find.text(AppStrings.saidaTitulo), findsNothing);
      expect(c.caminho, '/pacientes/${c.ana.id}');
      expect(find.byType(PacienteDetalhePage), findsOneWidget);
    });

    testWidgets('"É outra pessoa": salva assim mesmo e segue', (tester) async {
      final c = await _abrir(tester);
      await _preencher(tester, nome: 'Ana de Teste', nascimento: '14/03/1990');
      await _tocar(tester, AppStrings.cadastroSalvar);

      await _tocar(tester, AppStrings.duplicadoSalvarMesmoAssim);

      expect(await c.cadastrados, 3);
      expect(c.caminho, endsWith('/consentimento'));
    });

    testWidgets('mexer no nome tira o aviso', (tester) async {
      await _abrir(tester);
      await _preencher(tester, nome: 'Ana de Teste', nascimento: '14/03/1990');
      await _tocar(tester, AppStrings.cadastroSalvar);

      await tester.enterText(
        _campo(AppStrings.cadastroCampoNome),
        'Ana Maria de Teste',
      );
      await tester.pump();

      expect(find.text(AppStrings.duplicadoTitulo), findsNothing);
    });

    testWidgets('sair com dados preenchidos pergunta; "Continuar" fica', (
      tester,
    ) async {
      final c = await _abrir(tester);
      await tester.enterText(_campo(AppStrings.cadastroCampoNome), 'Caio');

      await _tocar(tester, AppStrings.cadastroCancelar);
      expect(find.text(AppStrings.saidaTitulo), findsOneWidget);

      await _tocar(tester, AppStrings.saidaContinuar);
      expect(find.byType(NovoPacientePage), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_campo(AppStrings.cadastroCampoNome))
            .controller!
            .text,
        'Caio',
      );

      await _tocar(tester, AppStrings.cadastroCancelar);
      await _tocar(tester, AppStrings.saidaDescartar);
      expect(c.caminho, AppRoutes.pacientesCaminho);
    });

    testWidgets('tocar fora da pergunta não descarta', (tester) async {
      await _abrir(tester);
      await tester.enterText(_campo(AppStrings.cadastroCampoNome), 'Caio');
      await _tocar(tester, AppStrings.cadastroCancelar);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.saidaTitulo), findsNothing);
      expect(find.byType(NovoPacientePage), findsOneWidget);
    });

    testWidgets('sem nada preenchido, sai sem perguntar', (tester) async {
      final c = await _abrir(tester);

      await _tocar(tester, AppStrings.cadastroCancelar);

      expect(find.text(AppStrings.saidaTitulo), findsNothing);
      expect(c.caminho, AppRoutes.pacientesCaminho);
    });

    testWidgets('pela navegação principal também pergunta', (tester) async {
      final c = await _abrir(tester, tamanho: const Size(1440, 1000));
      await tester.enterText(_campo(AppStrings.cadastroCampoNome), 'Caio');

      await _tocar(tester, AppStrings.navPacientes);

      expect(find.text(AppStrings.saidaTitulo), findsOneWidget);
      await _tocar(tester, AppStrings.saidaDescartar);
      expect(c.caminho, AppRoutes.pacientesCaminho);
    });
  });

  group('edição', () {
    testWidgets('sem mudar nada, volta sem perguntar', (tester) async {
      await _abrir(tester, rota: AppRoutes.edicaoPacienteNome);

      await tester.tap(find.bySemanticsLabel(AppStrings.voltar).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.saidaTitulo), findsNothing);
      expect(find.byType(EditarPacientePage), findsNothing);
    });

    testWidgets('com mudança, pergunta; salvar volta sem perguntar', (
      tester,
    ) async {
      final c = await _abrir(tester, rota: AppRoutes.edicaoPacienteNome);
      await tester.enterText(
        _campo(AppStrings.cadastroCampoQueixa),
        'soprosidade',
      );

      await tester.tap(find.bySemanticsLabel(AppStrings.voltar).first);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.saidaTitulo), findsOneWidget);
      await _tocar(tester, AppStrings.saidaContinuar);

      await _tocar(tester, AppStrings.edicaoSalvar);
      expect(find.text(AppStrings.saidaTitulo), findsNothing);
      expect(find.byType(EditarPacientePage), findsNothing);
      final salvo = (await c.pacientes.listar()).firstWhere(
        (p) => p.id == c.ana.id,
      );
      expect(salvo.queixa, 'soprosidade');
    });

    testWidgets('corrigir para os dados de outro paciente avisa', (
      tester,
    ) async {
      final c = await _abrir(
        tester,
        rota: AppRoutes.edicaoPacienteNome,
        daBia: true,
      );
      await tester.enterText(
        _campo(AppStrings.cadastroCampoNome),
        'Ana de Teste',
      );
      await tester.enterText(
        _campo(AppStrings.cadastroCampoNascimento),
        '14/03/1990',
      );

      await _tocar(tester, AppStrings.edicaoSalvar);
      expect(find.text(AppStrings.duplicadoTitulo), findsOneWidget);
      final bia = (await c.pacientes.listar()).firstWhere(
        (p) => p.id == c.bia.id,
      );
      expect(bia.nome, 'Bia de Teste');

      await _tocar(tester, AppStrings.duplicadoSalvarMesmoAssim);
      final corrigida = (await c.pacientes.listar()).firstWhere(
        (p) => p.id == c.bia.id,
      );
      expect(corrigida.nome, 'Ana de Teste');
    });
  });

  testWidgets('pergunta em 200% não estoura', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _abrir(tester, tamanho: const Size(390, 844));
    await tester.enterText(_campo(AppStrings.cadastroCampoNome), 'Caio');

    // Com o campo em foco, a tela volta ao cursor a cada quadro: como o
    // profissional, fecha o teclado antes de ir até o botão.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tocar(tester, AppStrings.cadastroCancelar);

    expect(find.text(AppStrings.saidaTitulo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
