import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_campo_texto.dart';
import 'package:fonar_app/features/anotacoes/data/repositorio_anotacoes_local.dart';
import 'package:fonar_app/features/anotacoes/presentation/widgets/aviso_de_lembrete.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/domain/repositorio_consentimento.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/eliminacao_do_paciente.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';
import '../../apoio/sessao_de_teste.dart';

/// O consentimento do paciente: com ou sem. A anotação não depende dele.
class _Consentimentos implements RepositorioConsentimento {
  _Consentimentos({required this.tem});
  final bool tem;

  @override
  Future<Consentimento?> buscar(String pacienteId) async => tem
      ? Consentimento(
          pacienteId: pacienteId,
          registradoEm: DateTime(2026, 9, 1, 9),
          versaoDoTermo: 'teste-1',
          quemAutoriza: QuemAutoriza.paciente,
        )
      : null;

  @override
  Future<Consentimento> registrar(String id, PedidoDeConsentimento p) =>
      throw UnimplementedError();

  @override
  Future<RetiradaDeConsentimento?> retiradaEmVigor(String pacienteId) async =>
      null;

  @override
  Future<RetiradaDeConsentimento> retirar(String id, PedidoDeRetirada p) =>
      throw UnimplementedError();
}

class _Arquivos implements ArquivosDeAmostra {
  @override
  Future<void> apagar(String caminho) async {}

  @override
  Future<Uint8List?> lerTudo(String caminho) async => null;

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async => null;

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao tarefa) =>
      throw UnimplementedError();
}

const _pid = 'p1';
final _hoje = DateTime(2026, 10, 15, 10);

Paciente _paciente({bool exemplo = false}) => Paciente(
  id: _pid,
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
  sexo: SexoDeReferencia.feminino,
  dataDeNascimento: DateTime(1985, 7, 2),
  exemplo: exemplo,
);

Future<BancoLocal> _abrir(
  WidgetTester tester, {
  String rota = AppRoutes.pacienteDetalheNome,
  bool consentimento = true,
  bool exemplo = false,
  Size tamanho = const Size(390, 2400),
  Future<void> Function(RepositorioAnotacoesLocal)? antes,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final banco = bancoEmMemoria();
  addTearDown(banco.close);
  if (antes != null) await antes(RepositorioAnotacoesLocal(banco));

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoLocalProvider.overrideWithValue(banco),
      sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
      conexaoOnlineProvider.overrideWithValue(false),
      relogioProvider.overrideWithValue(() => _hoje),
      pacientesProvider.overrideWith(
        (ref) async => [_paciente(exemplo: exemplo)],
      ),
      repositorioConsentimentoProvider.overrideWithValue(
        _Consentimentos(tem: consentimento),
      ),
      repositorioFilaProvider.overrideWithValue(RepositorioFilaEmMemoria()),
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
    pathParameters: {
      if (rota != AppRoutes.pacientesNome) AppRoutes.paramPacienteId: _pid,
    },
  );
  await _assentar(tester);
  return banco;
}

/// `pump` limitado: o medidor da gravação não assenta.
Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await _assentar(tester);
  await tester.tap(alvo);
  await _assentar(tester);
}

Future<void> _lembrete(
  RepositorioAnotacoesLocal r, {
  required DateTime em,
  String texto = 'Rever a hidratação (teste).',
}) => r.escrever(
  pacienteId: _pid,
  profissionalId: contaDeTeste.uid,
  texto: texto,
  lembrarNaProxima: true,
  agora: em,
);

/// O campo de texto do `AppCampoTexto` de [rotulo].
Finder _campo(String rotulo) => find.descendant(
  of: find.widgetWithText(AppCampoTexto, rotulo),
  matching: find.byType(TextField),
);

Finder _noAviso(Finder f) =>
    find.descendant(of: find.byType(AvisoDeLembrete), matching: f);

void main() {
  group('escrever e editar', () {
    testWidgets('a anotação nova aparece com a data, sem rede', (tester) async {
      final banco = await _abrir(tester);

      await tester.enterText(
        _campo(AppStrings.anotacoesCampo),
        'Retorno em 15 dias (teste).',
      );
      await _tocar(tester, find.text(AppStrings.anotacoesSalvar));

      expect(find.text('Retorno em 15 dias (teste).'), findsOneWidget);
      expect(find.text(AppStrings.data(_hoje)), findsOneWidget);
      final anotacoes = await RepositorioAnotacoesLocal(banco).doPaciente(_pid);
      expect(anotacoes.single.texto, 'Retorno em 15 dias (teste).');
    });

    testWidgets('sem texto, diz o que corrigir', (tester) async {
      await _abrir(tester);

      await _tocar(tester, find.text(AppStrings.anotacoesSalvar));

      expect(find.text(AppStrings.anotacoesTextoObrigatorio), findsOneWidget);
      expect(find.text(AppStrings.anotacoesVazio), findsOneWidget);
    });

    testWidgets('editar guarda a versão de antes, que dá para ver', (
      tester,
    ) async {
      await _abrir(
        tester,
        antes: (r) => r.escrever(
          pacienteId: _pid,
          profissionalId: contaDeTeste.uid,
          texto: 'Primeira versão (teste).',
          lembrarNaProxima: false,
          agora: DateTime(2026, 10, 12, 9),
        ),
      );

      await _tocar(tester, find.text(AppStrings.anotacoesEditar));
      await tester.enterText(
        _campo(AppStrings.anotacoesCampoEdicao),
        'Segunda versão (teste).',
      );
      await _tocar(tester, find.text(AppStrings.anotacoesSalvarEdicao));

      expect(find.text('Segunda versão (teste).'), findsOneWidget);
      expect(find.text('Primeira versão (teste).'), findsNothing);
      expect(
        find.textContaining(
          AppStrings.anotacoesEditadaEm(AppStrings.data(_hoje)),
        ),
        findsOneWidget,
      );

      await _tocar(tester, find.text(AppStrings.anotacoesVerAnteriores(1)));
      expect(find.text('Primeira versão (teste).'), findsOneWidget);
      expect(
        find.text(
          AppStrings.anotacoesVersaoDe(AppStrings.data(DateTime(2026, 10, 12))),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem consentimento também se anota', (tester) async {
      await _abrir(tester, consentimento: false);

      await tester.enterText(
        _campo(AppStrings.anotacoesCampo),
        'Paciente preferiu não gravar hoje (teste).',
      );
      await _tocar(tester, find.text(AppStrings.anotacoesSalvar));

      expect(
        find.text('Paciente preferiu não gravar hoje (teste).'),
        findsOneWidget,
      );
    });

    testWidgets('paciente de exemplo: diz por que não se anota', (
      tester,
    ) async {
      await _abrir(tester, exemplo: true);

      expect(find.text(AppStrings.anotacoesExemplo), findsOneWidget);
      expect(_campo(AppStrings.anotacoesCampo), findsNothing);
    });
  });

  group('lembrete', () {
    testWidgets('num dia seguinte: discreto, e o texto só ao tocar', (
      tester,
    ) async {
      await _abrir(
        tester,
        antes: (r) => _lembrete(r, em: DateTime(2026, 10, 12, 9)),
      );

      expect(
        _noAviso(find.text(AppStrings.lembreteUm('12/10'))),
        findsOneWidget,
      );
      expect(_noAviso(find.text('Rever a hidratação (teste).')), findsNothing);
      expect(_noAviso(find.text(AppStrings.lembreteVi)), findsNothing);

      await _tocar(tester, _noAviso(find.text(AppStrings.lembreteMostrar)));

      expect(
        _noAviso(find.text('Rever a hidratação (teste).')),
        findsOneWidget,
      );
    });

    testWidgets('"Ok, vi" grava o visto, e o aviso some', (tester) async {
      final banco = await _abrir(
        tester,
        antes: (r) => _lembrete(r, em: DateTime(2026, 10, 12, 9)),
      );

      await _tocar(tester, _noAviso(find.text(AppStrings.lembreteMostrar)));
      await _tocar(tester, _noAviso(find.text(AppStrings.lembreteVi)));

      expect(find.byType(AvisoDeLembrete), findsOneWidget);
      expect(_noAviso(find.textContaining('lembrete')), findsNothing);
      final versao = (await RepositorioAnotacoesLocal(banco).doPaciente(_pid))
          .single
          .vigente;
      expect(versao.lembreteVistoEm, _hoje);
    });

    testWidgets('no mesmo dia, não: é a mesma consulta', (tester) async {
      await _abrir(
        tester,
        antes: (r) =>
            _lembrete(r, em: _hoje.subtract(const Duration(hours: 1))),
      );

      expect(_noAviso(find.textContaining('lembrete')), findsNothing);
      expect(find.text(AppStrings.anotacoesComLembrete), findsOneWidget);
    });

    testWidgets('vários: diz quantos, e mostra cada um com a consulta', (
      tester,
    ) async {
      await _abrir(
        tester,
        antes: (r) async {
          await _lembrete(r, em: DateTime(2026, 10, 1, 9), texto: 'um');
          await _lembrete(r, em: DateTime(2026, 10, 8, 9), texto: 'dois');
        },
      );

      expect(_noAviso(find.text(AppStrings.lembreteVarios(2))), findsOneWidget);
      await _tocar(tester, _noAviso(find.text(AppStrings.lembreteMostrar)));
      expect(
        _noAviso(find.text(AppStrings.lembreteDaConsulta('01/10'))),
        findsOneWidget,
      );
      expect(_noAviso(find.text('dois')), findsOneWidget);
    });

    testWidgets('no início da gravação também', (tester) async {
      await _abrir(
        tester,
        rota: AppRoutes.capturaNome,
        tamanho: const Size(1440, 900),
        antes: (r) => _lembrete(r, em: DateTime(2026, 10, 12, 9)),
      );

      expect(
        _noAviso(find.text(AppStrings.lembreteUm('12/10'))),
        findsOneWidget,
      );
      expect(_noAviso(find.text('Rever a hidratação (teste).')), findsNothing);
    });

    testWidgets('o selo "Lembrete" na lista de pacientes', (tester) async {
      await _abrir(
        tester,
        rota: AppRoutes.pacientesNome,
        antes: (r) => _lembrete(r, em: DateTime(2026, 10, 12, 9)),
      );

      expect(find.text(AppStrings.lembreteSelo), findsOneWidget);
      // O texto do lembrete não aparece na lista.
      expect(find.text('Rever a hidratação (teste).'), findsNothing);
    });

    testWidgets('sem lembrete pendente, sem selo', (tester) async {
      await _abrir(
        tester,
        rota: AppRoutes.pacientesNome,
        antes: (r) => _lembrete(r, em: _hoje),
      );

      expect(find.text(AppStrings.lembreteSelo), findsNothing);
    });
  });

  test('eliminar o paciente apaga as anotações, todas as versões', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final repositorio = RepositorioAnotacoesLocal(banco);
    final primeira = await repositorio.escrever(
      pacienteId: _pid,
      profissionalId: contaDeTeste.uid,
      texto: 'a',
      lembrarNaProxima: false,
      agora: DateTime(2026, 10, 12),
    );
    await repositorio.escrever(
      pacienteId: _pid,
      profissionalId: contaDeTeste.uid,
      texto: 'b',
      lembrarNaProxima: false,
      agora: DateTime(2026, 10, 13),
      substitui: primeira.id,
    );
    await repositorio.escrever(
      pacienteId: 'outro',
      profissionalId: contaDeTeste.uid,
      texto: 'de outro paciente',
      lembrarNaProxima: false,
      agora: DateTime(2026, 10, 13),
    );

    await EliminacaoDoPaciente(banco, _Arquivos()).eliminar(_pid);

    expect(await repositorio.doPaciente(_pid), isEmpty);
    expect(await repositorio.doPaciente('outro'), hasLength(1));
  });

  test('o texto da eliminação cita as anotações', () {
    expect(AppStrings.perfilEliminarTexto, contains('e as anotações'));
  });
}
