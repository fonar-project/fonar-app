import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/captura/presentation/pages/captura_page.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/domain/repositorio_consentimento.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_placeholder.dart';
import 'package:fonar_app/features/consentimento/presentation/pages/consentimento_page.dart';

/// Consentimento de um paciente só, controlável pelo teste.
class _Repositorio implements RepositorioConsentimento {
  _Repositorio({this.com = const {}, this.falha = false});

  final Set<String> com;
  final bool falha;

  @override
  Future<Consentimento?> buscar(String pacienteId) async {
    if (falha) throw const FalhaDeConexao();
    return com.contains(pacienteId)
        ? Consentimento(
            pacienteId: pacienteId,
            registradoEm: DateTime(2026, 9, 1),
            versaoDoTermo: 'teste',
            quemAutoriza: QuemAutoriza.paciente,
          )
        : null;
  }

  @override
  Future<Consentimento> registrar(String id, PedidoDeConsentimento p) =>
      throw UnimplementedError();
}

/// Sobe o app com o ROTEADOR DE VERDADE e navega até a gravação.
///
/// É o roteador real, e não um montado no teste, de propósito: o que se
/// testa aqui é justamente a regra que mora nele.
Future<GoRouter> _irParaGravacao(
  WidgetTester tester,
  _Repositorio repositorio,
  String pacienteId,
) async {
  final container = ProviderContainer(
    // O Riverpod 3 tenta de novo sozinho quando um provider falha; aqui a
    // falha precisa ficar na tela, e o timer da nova tentativa sobraria.
    retry: (_, _) => null,
    overrides: [
      repositorioConsentimentoProvider.overrideWithValue(repositorio),
      conexaoOnlineProvider.overrideWithValue(true),
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
    AppRoutes.capturaNome,
    pathParameters: {AppRoutes.paramPacienteId: pacienteId},
  );
  await tester.pumpAndSettle();
  return roteador;
}

String _caminho(GoRouter r) =>
    r.routerDelegate.currentConfiguration.uri.toString();

void main() {
  // Regra de LGPD do CLAUDE.md: a captura fica bloqueada enquanto não houver
  // consentimento registrado, e o bloqueio é técnico — no roteador.
  testWidgets('sem consentimento, a gravação vira o consentimento', (
    tester,
  ) async {
    final r = await _irParaGravacao(tester, _Repositorio(), 'exemplo-e');

    expect(_caminho(r), '/pacientes/exemplo-e/consentimento');
    expect(find.byType(ConsentimentoPage), findsOneWidget);
    expect(find.byType(CapturaPage), findsNothing);
  });

  testWidgets('com consentimento, a gravação abre', (tester) async {
    final r = await _irParaGravacao(
      tester,
      _Repositorio(com: {'exemplo-a'}),
      'exemplo-a',
    );

    expect(_caminho(r), '/pacientes/exemplo-a/captura');
    expect(find.byType(CapturaPage), findsOneWidget);
  });

  testWidgets('o consentimento de um paciente não libera outro', (
    tester,
  ) async {
    final r = await _irParaGravacao(
      tester,
      _Repositorio(com: {'exemplo-a'}),
      'exemplo-b',
    );

    expect(_caminho(r), '/pacientes/exemplo-b/consentimento');
  });

  testWidgets('falha ao consultar bloqueia: na dúvida, não grava', (
    tester,
  ) async {
    final r = await _irParaGravacao(
      tester,
      _Repositorio(com: {'exemplo-a'}, falha: true),
      'exemplo-a',
    );

    expect(_caminho(r), '/pacientes/exemplo-a/consentimento');
    expect(find.byType(CapturaPage), findsNothing);
  });
}
