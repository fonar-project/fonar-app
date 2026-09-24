import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/captura/presentation/pages/captura_page.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/presentation/pages/consentimento_page.dart';
import 'package:fonar_app/features/consentimento/presentation/pages/retirada_consentimento_page.dart';
import 'package:fonar_app/features/consentimento/presentation/texto_da_retirada.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';

final _hora = DateTime(2026, 9, 23, 10, 15);

Paciente _paciente(String id, String nome) => Paciente(
  id: id,
  nome: nome,
  queixa: 'rouquidão (teste)',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
);

ItemDaFila _envio(String pacienteId, String sessaoId) => ItemDaFila(
  id: 'envio-$sessaoId',
  pacienteId: pacienteId,
  nomeDoPaciente: 'Paciente de Teste',
  sessaoId: sessaoId,
  amostras: const [],
  criadoEm: _hora,
);

class _Montagem {
  _Montagem(this.roteador, this.consentimentos, this.fila);

  final GoRouter roteador;
  final RepositorioConsentimentoPlaceholder consentimentos;
  final RepositorioFilaEmMemoria fila;

  String get caminho =>
      roteador.routerDelegate.currentConfiguration.uri.toString();
}

/// O app com o ROTEADOR DE VERDADE, aberto na rota [inicio] do paciente p1.
Future<_Montagem> _abrir(
  WidgetTester tester, {
  bool comConsentimento = true,
  String inicio = AppRoutes.pacienteDetalheNome,
  Size tamanho = const Size(390, 2000),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final consentimentos = RepositorioConsentimentoPlaceholder();
  if (comConsentimento) {
    await consentimentos.registrar(
      'p1',
      (validarConsentimento(
        quemAutoriza: QuemAutoriza.paciente,
        nomeDoResponsavel: '',
        concordou: true,
      ) as ConsentimentoValido).pedido,
    );
    await consentimentos.registrar(
      'p2',
      (validarConsentimento(
        quemAutoriza: QuemAutoriza.paciente,
        nomeDoResponsavel: '',
        concordou: true,
      ) as ConsentimentoValido).pedido,
    );
  }
  final fila = RepositorioFilaEmMemoria();
  await fila.adicionar(_envio('p1', 's1'));
  await fila.adicionar(_envio('p2', 's2'));

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      // Sem rede: a fila guarda e não envia.
      conexaoOnlineProvider.overrideWithValue(false),
      relogioProvider.overrideWithValue(() => _hora),
      pacientesProvider.overrideWith(
        (ref) async => [
          _paciente('p1', 'Ana de Teste'),
          _paciente('p2', 'Bia de Teste'),
        ],
      ),
      repositorioConsentimentoProvider.overrideWithValue(consentimentos),
      repositorioFilaProvider.overrideWithValue(fila),
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
  roteador.goNamed(inicio, pathParameters: {AppRoutes.paramPacienteId: 'p1'});
  await tester.pumpAndSettle();
  return _Montagem(roteador, consentimentos, fila);
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto).last;
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('do perfil, "Retirar consentimento" leva à retirada', (
    tester,
  ) async {
    final m = await _abrir(tester);

    await _tocar(tester, AppStrings.retiradaAcao);

    expect(m.caminho, '/pacientes/p1/consentimento/retirar');
    expect(find.byType(RetiradaConsentimentoPage), findsOneWidget);
    expect(
      find.text(AppStrings.consentimentoPaciente('Ana de Teste')),
      findsOneWidget,
    );
    // Diz o que acontece antes de registrar.
    for (final efeito in AppStrings.retiradaEfeitos) {
      expect(find.text(efeito), findsOneWidget);
    }
  });

  testWidgets('sem dizer quem pede, não retira e diz o que corrigir', (
    tester,
  ) async {
    final m = await _abrir(tester, inicio: AppRoutes.retiradaConsentimentoNome);

    await _tocar(tester, AppStrings.retiradaRegistrar);

    expect(find.text(AppStrings.retiradaEscolhaQuem), findsOneWidget);
    expect(m.caminho, '/pacientes/p1/consentimento/retirar');
    expect(await m.consentimentos.buscar('p1'), isNotNull);
  });

  testWidgets('responsável legal: pede o nome e guarda quem pediu', (
    tester,
  ) async {
    final m = await _abrir(tester, inicio: AppRoutes.retiradaConsentimentoNome);

    await _tocar(tester, AppStrings.consentimentoQuemResponsavel);
    await _tocar(tester, AppStrings.retiradaRegistrar);
    expect(
      find.text(AppStrings.consentimentoInformeResponsavel),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Rui de Teste');
    await _tocar(tester, AppStrings.retiradaRegistrar);

    final retirada = (await m.consentimentos.retiradaEmVigor('p1'))!;
    expect(retirada.quemPediu, QuemAutoriza.responsavelLegal);
    expect(retirada.nomeDoResponsavel, 'Rui de Teste');
  });

  testWidgets('retirado: volta ao perfil, que mostra a retirada e pede um '
      'consentimento novo', (tester) async {
    final m = await _abrir(tester, inicio: AppRoutes.retiradaConsentimentoNome);

    await _tocar(tester, AppStrings.consentimentoQuemPaciente);
    await _tocar(tester, AppStrings.retiradaRegistrar);

    expect(m.caminho, '/pacientes/p1');
    expect(find.text(AppStrings.consentimentoRetirado), findsOneWidget);
    final retirada = (await m.consentimentos.retiradaEmVigor('p1'))!;
    expect(find.text(textoDaRetirada(retirada)), findsOneWidget);
    expect(find.text(AppStrings.perfilRegistrarConsentimento), findsOneWidget);
    expect(find.text(AppStrings.retiradaAcao), findsNothing);
    // A gravação que esperava na fila não está mais "a caminho".
    expect(find.text(AppStrings.perfilParadosNaFila(1)), findsOneWidget);
    expect(find.text(AppStrings.perfilNaFila(1)), findsNothing);
  });

  testWidgets('retirado: a gravação volta a ficar bloqueada no roteador', (
    tester,
  ) async {
    final m = await _abrir(tester, inicio: AppRoutes.retiradaConsentimentoNome);
    await _tocar(tester, AppStrings.consentimentoQuemPaciente);
    await _tocar(tester, AppStrings.retiradaRegistrar);

    m.roteador.goNamed(
      AppRoutes.capturaNome,
      pathParameters: {AppRoutes.paramPacienteId: 'p1'},
    );
    await tester.pumpAndSettle();

    expect(m.caminho, '/pacientes/p1/consentimento');
    expect(find.byType(CapturaPage), findsNothing);
    expect(find.byType(ConsentimentoPage), findsOneWidget);
    // Não é "nunca registrado": diz que foi retirado.
    expect(find.text(AppStrings.consentimentoRetirado), findsOneWidget);
  });

  testWidgets('retirado: os envios do paciente param, os de outro não', (
    tester,
  ) async {
    final m = await _abrir(tester, inicio: AppRoutes.retiradaConsentimentoNome);
    await _tocar(tester, AppStrings.consentimentoQuemPaciente);
    await _tocar(tester, AppStrings.retiradaRegistrar);

    final itens = {for (final i in await m.fila.listar()) i.pacienteId: i};
    expect(itens['p1']!.situacao, SituacaoDoEnvio.semConsentimento);
    expect(itens['p2']!.situacao, SituacaoDoEnvio.naFila);
  });

  testWidgets('sem consentimento em vigor, não há o que retirar', (
    tester,
  ) async {
    await _abrir(
      tester,
      comConsentimento: false,
      inicio: AppRoutes.retiradaConsentimentoNome,
    );

    expect(find.text(AppStrings.retiradaNadaARetirar), findsOneWidget);
    expect(find.text(AppStrings.retiradaRegistrar), findsNothing);
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(390, 844)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('$nome em 200% não estoura', (tester) async {
      await _abrir(
        tester,
        inicio: AppRoutes.retiradaConsentimentoNome,
        tamanho: tamanho,
        escala: 2,
      );
      await _tocar(tester, AppStrings.consentimentoQuemResponsavel);

      expect(tester.takeException(), isNull);
    });
  }
}
