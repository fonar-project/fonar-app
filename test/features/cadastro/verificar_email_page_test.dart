import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/presentation/login_controlador.dart';
import 'package:fonar_app/features/cadastro/presentation/cadastro_controlador.dart';
import 'package:fonar_app/features/cadastro/presentation/pages/verificar_email_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/sessao_de_teste.dart';

/// A verificação parada num estado, sem Firebase nem API.
class _VerificacaoParada extends VerificacaoControlador {
  _VerificacaoParada(this._estado);

  final EstadoDoCadastro _estado;

  @override
  EstadoDoCadastro build() => _estado;
}

Future<void> _abrir(
  WidgetTester tester, {
  required EstadoDoCadastro estado,
  bool online = true,
  Size tamanho = const Size(1440, 900),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        verificacaoControladorProvider.overrideWith(
          () => _VerificacaoParada(estado),
        ),
        conexaoOnlineProvider.overrideWithValue(online),
        contaGuardadaProvider.overrideWith((ref) async => contaDeTeste),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const VerificarEmailPage(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final (nome, tamanho) in [
    ('desktop', const Size(1440, 900)),
    ('celular', const Size(390, 844)),
  ]) {
    testWidgets('$nome: conferindo, um só "Conferindo…" na tela', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _abrir(
        tester,
        estado: const EstadoDoCadastro(enviando: true),
        tamanho: tamanho,
      );

      expect(find.text(AppStrings.verificarEmailConferindo), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Os dois botões parados, e o leitor de tela diz por quê em cada um.
      for (final botao in [
        find.byType(FilledButton),
        find.byType(OutlinedButton),
      ]) {
        final no = tester.getSemantics(botao).getSemanticsData();
        expect(no.hint, AppStrings.verificarEmailConferindo);
        expect(no.flagsCollection.isEnabled, Tristate.isFalse);
      }
      semantica.dispose();
    });
  }

  testWidgets('sem conexão: o motivo aparece uma vez, sob o primeiro botão', (
    tester,
  ) async {
    await _abrir(tester, estado: const EstadoDoCadastro(), online: false);

    expect(find.text(AppStrings.loginEntrarExigeConexao), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(AppStrings.loginEntrarExigeConexao)).dy,
      lessThan(tester.getTopLeft(find.byType(OutlinedButton)).dy),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('desktop: a rolagem ocupa o painel até a borda da janela', (
    tester,
  ) async {
    await _abrir(tester, estado: const EstadoDoCadastro());

    // A barra de rolagem fica na borda direita da janela, e não colada nos
    // campos: a área que rola vai até ela.
    final rolagem = find.byType(SingleChildScrollView).last;
    expect(tester.getTopRight(rolagem).dx, 1440);
    // O formulário, no meio dela, com a largura que a janela pede.
    final largura = tester.getSize(find.byType(FilledButton)).width;
    expect(largura, greaterThan(440));
    expect(largura, lessThanOrEqualTo(640));
  });
}
