import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_campo_texto.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/pacientes/data/pacientes_de_exemplo.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/pacientes/presentation/edicao_paciente_controlador.dart';
import 'package:fonar_app/features/pacientes/presentation/pages/editar_paciente_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';

NovoPaciente _dados({
  String nome = 'Ana de Teste',
  String nascimento = '14/03/1990',
  SexoDeReferencia sexo = SexoDeReferencia.feminino,
}) => (validarCadastro(
  nome: nome,
  nascimento: nascimento,
  sexo: sexo,
  queixa: 'rouquidão (teste)',
  hoje: DateTime(2026, 9, 24),
) as CadastroValido).paciente;

Future<(GoRouter, RepositorioPacientesPlaceholder, String)> _abrir(
  WidgetTester tester, {
  String? pacienteId,
  String rota = AppRoutes.pacienteDetalheNome,
  Size tamanho = const Size(390, 1400),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final pacientes = RepositorioPacientesPlaceholder();
  final ana = await pacientes.cadastrar(_dados());

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
    rota,
    pathParameters: {AppRoutes.paramPacienteId: pacienteId ?? ana.id},
  );
  await tester.pumpAndSettle();
  return (roteador, pacientes, ana.id);
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto).first;
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Finder _campo(String rotulo) => find.descendant(
  of: find.widgetWithText(AppCampoTexto, rotulo),
  matching: find.byType(TextField),
);

String _texto(WidgetTester tester, String rotulo) =>
    tester.widget<TextField>(_campo(rotulo)).controller!.text;

bool _habilitado(WidgetTester tester, String rotulo) {
  final botao = find.ancestor(
    of: find.text(rotulo),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(botao.first).onPressed != null;
}

/// Atualiza só quando o teste deixar.
class _PacientesLentos extends RepositorioPacientesPlaceholder {
  final espera = Completer<void>();

  @override
  Future<Paciente> atualizar(String id, NovoPaciente dados) async {
    await espera.future;
    return super.atualizar(id, dados);
  }
}

void main() {
  group('no banco local', () {
    test('corrige os dados, e a lista mostra a correção', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repositorio = RepositorioPacientesLocal(
        banco,
        agora: () => DateTime(2026, 9, 24),
      );
      final ana = await repositorio.cadastrar(_dados());

      final corrigida = await repositorio.atualizar(
        ana.id,
        _dados(
          nome: 'Ana Maria de Teste',
          nascimento: '14/03/1980',
          sexo: SexoDeReferencia.naoInformado,
        ),
      );

      expect(corrigida.id, ana.id);
      final lida = (await repositorio.listar()).single;
      expect(lida.nome, 'Ana Maria de Teste');
      expect(lida.dataDeNascimento, DateTime(1980, 3, 14));
      expect(lida.sexo, SexoDeReferencia.naoInformado);
    });

    test('quem não está no banco não se corrige', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repositorio = RepositorioPacientesLocal(
        banco,
        agora: DateTime.now,
        exemplos: pacientesDeExemplo,
      );

      await expectLater(
        repositorio.atualizar('exemplo-a', _dados()),
        throwsA(isA<NaoEncontrado>()),
      );
      await expectLater(
        repositorio.atualizar('nao-existe', _dados()),
        throwsA(isA<NaoEncontrado>()),
      );
    });
  });

  testWidgets('do perfil, "Editar dados" abre o formulário já preenchido', (
    tester,
  ) async {
    await _abrir(tester);

    await _tocar(tester, AppStrings.perfilEditarDados);

    expect(find.byType(EditarPacientePage), findsOneWidget);
    expect(_texto(tester, AppStrings.cadastroCampoNome), 'Ana de Teste');
    expect(_texto(tester, AppStrings.cadastroCampoNascimento), '14/03/1990');
    expect(_texto(tester, AppStrings.cadastroCampoQueixa), 'rouquidão (teste)');
    expect(find.text(AppStrings.edicaoAvisoTitulo), findsOneWidget);
  });

  testWidgets('salvar corrige e volta ao perfil, que mostra a correção', (
    tester,
  ) async {
    final (_, pacientes, id) = await _abrir(tester);
    await _tocar(tester, AppStrings.perfilEditarDados);

    await tester.enterText(
      _campo(AppStrings.cadastroCampoNascimento),
      '14/03/1980',
    );
    await _tocar(tester, AppStrings.edicaoSalvar);

    expect(find.byType(EditarPacientePage), findsNothing);
    expect(
      find.text(AppStrings.perfilNascimento('14 mar 1980', 46)),
      findsOneWidget,
    );
    final salvo = (await pacientes.listar()).firstWhere((p) => p.id == id);
    expect(salvo.dataDeNascimento, DateTime(1980, 3, 14));
  });

  testWidgets('dado errado não salva, e diz o que corrigir', (tester) async {
    final (_, pacientes, id) = await _abrir(
      tester,
      rota: AppRoutes.edicaoPacienteNome,
    );

    await tester.enterText(_campo(AppStrings.cadastroCampoNome), '   ');
    await tester.enterText(
      _campo(AppStrings.cadastroCampoNascimento),
      '31/02/1990',
    );
    await _tocar(tester, AppStrings.edicaoSalvar);

    expect(find.byType(EditarPacientePage), findsOneWidget);
    expect(find.text(AppStrings.cadastroInformeNome), findsOneWidget);
    expect(find.text(AppStrings.cadastroNascimentoInvalido), findsOneWidget);
    final salvo = (await pacientes.listar()).firstWhere((p) => p.id == id);
    expect(salvo.nome, 'Ana de Teste');
  });

  testWidgets('paciente de exemplo: não se edita, e diz por quê', (
    tester,
  ) async {
    await _abrir(tester, pacienteId: 'exemplo-a');

    expect(_habilitado(tester, AppStrings.perfilEditarDados), isFalse);
    expect(find.text(AppStrings.edicaoExemplo), findsOneWidget);
  });

  testWidgets('pelo endereço direto também não', (tester) async {
    await _abrir(
      tester,
      pacienteId: 'exemplo-a',
      rota: AppRoutes.edicaoPacienteNome,
    );

    expect(find.text(AppStrings.edicaoExemplo), findsOneWidget);
    expect(find.text(AppStrings.edicaoSalvar), findsNothing);
  });

  test('tela fechada no meio: a lista mostra a correção mesmo assim', () async {
    final pacientes = _PacientesLentos();
    final ana = await pacientes.cadastrar(_dados());
    final container = ProviderContainer(
      overrides: [repositorioPacientesProvider.overrideWithValue(pacientes)],
    );
    addTearDown(container.dispose);
    container.listen(pacientesProvider, (_, _) {});
    await container.read(pacientesProvider.future);
    final tela = container.listen(
      edicaoPacienteControladorProvider(ana.id),
      (_, _) {},
    );

    final salvando = container
        .read(edicaoPacienteControladorProvider(ana.id).notifier)
        .salvar(
          nome: 'Ana Maria de Teste',
          nascimento: '14/03/1990',
          sexo: SexoDeReferencia.feminino,
          queixa: 'rouquidão (teste)',
        );
    tela.close();
    await Future<void>.delayed(Duration.zero);
    pacientes.espera.complete();
    await salvando;

    final lista = await container.read(pacientesProvider.future);
    expect(lista.firstWhere((p) => p.id == ana.id).nome, 'Ana Maria de Teste');
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(390, 844)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('$nome em 200% não estoura', (tester) async {
      await _abrir(
        tester,
        rota: AppRoutes.edicaoPacienteNome,
        tamanho: tamanho,
        escala: 2,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
