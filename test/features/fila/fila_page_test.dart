import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_botao.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/fila/data/envio_de_analise_api.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/fila/presentation/pages/fila_page.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/repositorios_em_memoria.dart';

final _agora = DateTime(2026, 9, 23, 10);

class _EnvioQueDaCerto implements EnvioDeAnalise {
  final recebidos = <String>[];
  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) async {
    recebidos.add(item.id);
    return 'analise-nova';
  }
}

ItemDaFila _item(
  String sessao,
  String nome,
  SituacaoDoEnvio situacao, {
  String? falha,
  String? analiseId,
}) => ItemDaFila(
  id: 'envio-$sessao',
  pacienteId: 'p-$sessao',
  nomeDoPaciente: nome,
  sessaoId: sessao,
  amostras: [
    Amostra(
      id: 'a-$sessao',
      pacienteId: 'p-$sessao',
      sessaoId: sessao,
      tarefa: TarefaDeGravacao.vogalSustentada,
      caminho: '/x.wav',
      gravadaEm: _agora,
      duracao: const Duration(seconds: 3),
      taxaDeAmostragem: 44100,
      canais: 1,
      problemas: const [],
    ),
  ],
  criadoEm: _agora,
  situacao: situacao,
  tentativas: situacao == SituacaoDoEnvio.naFila ? 0 : 1,
  ultimaFalha: falha,
  analiseId: analiseId,
  // Espera longa: nada sobe sozinho durante o teste.
  proximaTentativa: situacao == SituacaoDoEnvio.aguardandoNovaTentativa
      ? _agora.add(const Duration(minutes: 5))
      : null,
);

Future<_EnvioQueDaCerto> _abrir(
  WidgetTester tester, {
  List<ItemDaFila> itens = const [],
  bool online = true,
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

  final repositorio = RepositorioFilaEmMemoria();
  for (final i in itens) {
    await repositorio.adicionar(i);
  }
  final envio = _EnvioQueDaCerto();

  Widget destino(GoRouterState s) =>
      Scaffold(body: Text('destino ${s.uri.path}'));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositorioFilaProvider.overrideWithValue(repositorio),
        repositorioConsentimentoProvider.overrideWithValue(
          RepositorioConsentimentoPlaceholder(),
        ),
        envioDeAnaliseProvider.overrideWithValue(envio),
        // Profissional com a sessão aberta: sem ela a fila não envia.
        sessaoAbertaProvider.overrideWith(() => Sessao(true)),
        conexaoOnlineProvider.overrideWithValue(online),
        relogioProvider.overrideWithValue(() => _agora),
      ],
      child: MaterialApp.router(
        theme: AppTheme.claro,
        routerConfig: GoRouter(
          initialLocation: AppRoutes.filaCaminho,
          routes: [
            GoRoute(
              name: AppRoutes.filaNome,
              path: AppRoutes.filaCaminho,
              builder: (_, _) => const FilaPage(),
            ),
            GoRoute(
              name: AppRoutes.pacientesNome,
              path: AppRoutes.pacientesCaminho,
              builder: (_, s) => destino(s),
              routes: [
                GoRoute(
                  name: AppRoutes.novaAvaliacaoNome,
                  path: AppRoutes.novaAvaliacaoCaminho,
                  builder: (_, s) => destino(s),
                ),
                GoRoute(
                  name: AppRoutes.pacienteDetalheNome,
                  path: AppRoutes.pacienteDetalheCaminho,
                  builder: (_, s) => destino(s),
                  routes: [
                    GoRoute(
                      name: AppRoutes.analiseResultadoNome,
                      path: AppRoutes.analiseResultadoCaminho,
                      builder: (_, s) => destino(s),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              name: AppRoutes.contaNome,
              path: AppRoutes.contaCaminho,
              builder: (_, s) => destino(s),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return envio;
}

Future<void> _tocar(WidgetTester tester, String rotulo) async {
  final alvo = find.text(rotulo).first;
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

final _variados = [
  _item(
    's1',
    'Paciente Um de Teste',
    SituacaoDoEnvio.enviado,
    analiseId: 'an-1',
  ),
  _item(
    's2',
    'Paciente Dois de Teste',
    SituacaoDoEnvio.aguardandoNovaTentativa,
    falha: 'Não foi possível conectar.',
  ),
  _item(
    's3',
    'Paciente Três de Teste',
    SituacaoDoEnvio.recusado,
    falha: 'Confira os dados.',
  ),
  _item('s4', 'Paciente Quatro de Teste', SituacaoDoEnvio.aguardandoLogin),
];

void main() {
  testWidgets('fila vazia explica e leva aos pacientes', (tester) async {
    await _abrir(tester);

    expect(find.text(AppStrings.filaVaziaTitulo), findsOneWidget);
    await _tocar(tester, AppStrings.filaIrParaPacientes);
    expect(find.text('destino /pacientes'), findsOneWidget);
  });

  testWidgets('cada envio diz a situação por escrito', (tester) async {
    await _abrir(tester, itens: _variados);

    expect(find.text(AppStrings.filaResumo(3)), findsOneWidget);
    expect(find.text(AppStrings.filaEnviado), findsOneWidget);
    expect(find.text(AppStrings.filaFalhou), findsOneWidget);
    expect(
      find.text(
        AppStrings.filaFalhouTexto('Não foi possível conectar.', '10:05'),
      ),
      findsOneWidget,
    );
    expect(find.text(AppStrings.filaRecusado), findsOneWidget);
    expect(find.text(AppStrings.filaSessaoExpirada), findsOneWidget);
    // O mais novo em cima.
    expect(
      tester.getTopLeft(find.text('Paciente Quatro de Teste')).dy,
      lessThan(tester.getTopLeft(find.text('Paciente Um de Teste')).dy),
    );
  });

  testWidgets('sem conexão: aviso no topo e tentar desabilitado com motivo', (
    tester,
  ) async {
    await _abrir(
      tester,
      online: false,
      itens: [_item('s1', 'Paciente Um de Teste', SituacaoDoEnvio.naFila)],
    );

    expect(find.text(AppStrings.filaSemConexaoTitulo), findsOneWidget);
    expect(find.text(AppStrings.filaAguardandoConexao), findsOneWidget);
  });

  testWidgets('tentar de novo, offline, fica desabilitado e diz por quê', (
    tester,
  ) async {
    await _abrir(
      tester,
      online: false,
      itens: [
        _item(
          's3',
          'Paciente Três de Teste',
          SituacaoDoEnvio.recusado,
          falha: 'Confira os dados.',
        ),
      ],
    );

    final botao = tester.widget<AppBotao>(
      find.ancestor(
        of: find.text(AppStrings.filaTentarDeNovo),
        matching: find.byType(AppBotao),
      ),
    );
    expect(botao.aoTocar, isNull);
    expect(find.text(AppStrings.filaTentarExigeConexao), findsOneWidget);
  });

  testWidgets('tentar de novo reenvia e o envio passa a enviado', (
    tester,
  ) async {
    final envio = await _abrir(
      tester,
      itens: [
        _item(
          's3',
          'Paciente Três de Teste',
          SituacaoDoEnvio.recusado,
          falha: 'Confira os dados.',
        ),
      ],
    );

    await _tocar(tester, AppStrings.filaTentarDeNovo);

    expect(envio.recebidos, ['envio-s3']);
    expect(find.text(AppStrings.filaEnviado), findsOneWidget);
  });

  testWidgets('parado por consentimento retirado diz por quê', (tester) async {
    await _abrir(
      tester,
      itens: [
        _item(
          's5',
          'Paciente Cinco de Teste',
          SituacaoDoEnvio.semConsentimento,
        ),
      ],
    );

    expect(find.text(AppStrings.filaSemConsentimento), findsOneWidget);
    expect(find.text(AppStrings.filaSemConsentimentoTexto), findsOneWidget);
    // Continua pendente: conta no resumo.
    expect(find.text(AppStrings.filaResumo(1)), findsOneWidget);
    expect(find.text(AppStrings.filaTentarDeNovo), findsOneWidget);
  });

  testWidgets('enviado leva ao resultado da análise', (tester) async {
    await _abrir(tester, itens: _variados);

    await _tocar(tester, AppStrings.filaVerResultado);

    expect(find.text('destino /pacientes/p-s1/analise/an-1'), findsOneWidget);
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(390, 844)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('$nome não estoura com o texto do sistema em 200%', (
      tester,
    ) async {
      await _abrir(tester, itens: _variados, tamanho: tamanho, escala: 2);

      expect(tester.takeException(), isNull);
    });
  }
}
