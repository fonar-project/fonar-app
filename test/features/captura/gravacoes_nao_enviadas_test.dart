import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';
import 'package:fonar_app/features/captura/data/repositorio_amostras_local.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/captura/domain/sessao_nao_enviada.dart';
import 'package:fonar_app/features/captura/domain/verificacao_da_amostra.dart';
import 'package:fonar_app/features/captura/presentation/pages/gravacoes_nao_enviadas_page.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/reproducao/data/reprodutor_just_audio.dart';
import 'package:fonar_app/features/reproducao/domain/reprodutor.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';

final _agora = DateTime(2026, 9, 24, 15);
final _ontem = DateTime(2026, 9, 23, 10, 15);

Amostra _amostra(
  String sessaoId,
  TarefaDeGravacao tarefa, {
  DateTime? em,
  List<ProblemaNaAmostra> problemas = const [],
}) => Amostra(
  id: '$sessaoId-${tarefa.name}',
  pacienteId: 'p1',
  sessaoId: sessaoId,
  tarefa: tarefa,
  caminho: '/amostras/p1/$sessaoId-${tarefa.name}.wav',
  gravadaEm: em ?? _ontem,
  duracao: const Duration(seconds: 4),
  taxaDeAmostragem: 44100,
  canais: 1,
  problemas: problemas,
);

List<Amostra> _completa(String sessaoId, {DateTime? em}) => [
  for (final t in TarefaDeGravacao.values) _amostra(sessaoId, t, em: em),
];

class _Disco implements ArquivosDeAmostra {
  final apagados = <String>[];
  var falhar = false;

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao t) async =>
      '/x.wav';

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async =>
      (inicio: Uint8List(44), tamanho: 44);

  @override
  Future<void> apagar(String caminho) async {
    if (falhar) throw Exception('disco ocupado');
    apagados.add(caminho);
  }
}

class _ReprodutorQuieto implements Reprodutor {
  @override
  Future<Duration?> abrir(String caminho) async => null;
  @override
  Future<void> tocar() async {}
  @override
  Future<void> pausar() async {}
  @override
  Future<void> irPara(Duration posicao) async {}
  @override
  Stream<Duration> get posicoes => const Stream.empty();
  @override
  Stream<void> get terminou => const Stream.empty();
  @override
  Future<void> fechar() async {}
}

class _Cena {
  _Cena(this.roteador, this.amostras, this.disco, this.fila);
  final GoRouter roteador;
  final RepositorioAmostrasPlaceholder amostras;
  final _Disco disco;
  final RepositorioFilaEmMemoria fila;
}

Future<_Cena> _abrir(
  WidgetTester tester, {
  List<Amostra> gravadas = const [],
  bool comConsentimento = true,
  String rota = AppRoutes.gravacoesNaoEnviadasNome,
  Size tamanho = const Size(390, 1600),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final amostras = RepositorioAmostrasPlaceholder();
  for (final a in gravadas) {
    await amostras.guardar(a);
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
  }
  final disco = _Disco();
  final fila = RepositorioFilaEmMemoria();

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      // Sem rede: o que for para a fila fica lá.
      conexaoOnlineProvider.overrideWithValue(false),
      relogioProvider.overrideWithValue(() => _agora),
      pacientesProvider.overrideWith(
        (ref) async => const [
          Paciente(
            id: 'p1',
            nome: 'Ana de Teste',
            queixa: 'rouquidão',
            direcaoAvqi: DirecaoDaMedida.semComparacao,
          ),
        ],
      ),
      repositorioAmostrasProvider.overrideWithValue(amostras),
      arquivosDeAmostraProvider.overrideWithValue(disco),
      repositorioFilaProvider.overrideWithValue(fila),
      repositorioConsentimentoProvider.overrideWithValue(consentimentos),
      reprodutorProvider.overrideWithValue(_ReprodutorQuieto()),
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
  roteador.goNamed(rota, pathParameters: {AppRoutes.paramPacienteId: 'p1'});
  await tester.pumpAndSettle();
  return _Cena(roteador, amostras, disco, fila);
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto).first;
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

bool _habilitado(WidgetTester tester, String rotulo) {
  final botao = find.ancestor(
    of: find.text(rotulo),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(botao.first).onPressed != null;
}

void main() {
  group('sessoesNaoEnviadas', () {
    test('a de outro dia, fora da fila, aparece — por tarefa', () {
      final sessoes = sessoesNaoEnviadas(
        amostrasDoPaciente: _completa('s-ontem'),
        sessoesNaFila: {},
        agora: _agora,
      );

      expect(sessoes.single.sessaoId, 's-ontem');
      expect(sessoes.single.amostras.keys, TarefaDeGravacao.values);
      expect(sessoes.single.completa, isTrue);
      expect(sessoes.single.gravadaEm, _ontem);
    });

    test('a que foi para a fila não aparece', () {
      expect(
        sessoesNaoEnviadas(
          amostrasDoPaciente: _completa('s-ontem'),
          sessoesNaFila: {'s-ontem'},
          agora: _agora,
        ),
        isEmpty,
      );
    });

    test('a de hoje, que a gravação retomaria, não aparece — mas uma '
        'anterior de hoje, sim', () {
      final manha = DateTime(2026, 9, 24, 9);
      final tarde = DateTime(2026, 9, 24, 14);

      final sessoes = sessoesNaoEnviadas(
        amostrasDoPaciente: [
          _amostra('s-manha', TarefaDeGravacao.vogalSustentada, em: manha),
          _amostra('s-tarde', TarefaDeGravacao.vogalSustentada, em: tarde),
        ],
        sessoesNaFila: {},
        agora: _agora,
      );

      expect([for (final s in sessoes) s.sessaoId], ['s-manha']);
    });

    test('mais recente primeiro; incompleta ou inválida não está completa', () {
      final sessoes = sessoesNaoEnviadas(
        amostrasDoPaciente: [
          _amostra(
            's-antiga',
            TarefaDeGravacao.vogalSustentada,
            em: DateTime(2026, 9, 10),
          ),
          ..._completa('s-ontem').map(
            (a) => a.tarefa == TarefaDeGravacao.falaEncadeada
                ? _amostra(
                    's-ontem',
                    a.tarefa,
                    problemas: [ProblemaNaAmostra.semSinal],
                  )
                : a,
          ),
        ],
        sessoesNaFila: {},
        agora: _agora,
      );

      expect([for (final s in sessoes) s.sessaoId], ['s-ontem', 's-antiga']);
      expect(sessoes.every((s) => !s.completa), isTrue);
    });
  });

  group('no banco local', () {
    test('lista as do paciente e descarta a sessão inteira', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repositorio = RepositorioAmostrasLocal(banco);
      for (final a in [..._completa('s1'), ..._completa('s2')]) {
        await repositorio.guardar(a);
      }

      expect(await repositorio.doPaciente('p1'), hasLength(4));
      await repositorio.descartarSessao('s1');

      expect(
        {for (final a in await repositorio.doPaciente('p1')) a.sessaoId},
        {'s2'},
      );
    });

    test('sessão que já está num envio não se descarta', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repositorio = RepositorioAmostrasLocal(banco);
      final amostras = _completa('s1');
      for (final a in amostras) {
        await repositorio.guardar(a);
      }
      await RepositorioFilaLocal(banco).adicionar(
        ItemDaFila(
          id: 'envio-s1',
          pacienteId: 'p1',
          nomeDoPaciente: 'Ana de Teste',
          sessaoId: 's1',
          amostras: amostras,
          criadoEm: _ontem,
        ),
      );

      await expectLater(repositorio.descartarSessao('s1'), throwsA(anything));
      expect(await repositorio.doPaciente('p1'), hasLength(2));
    });
  });

  group('tela', () {
    testWidgets('o perfil avisa e leva às gravações não enviadas', (
      tester,
    ) async {
      await _abrir(
        tester,
        gravadas: _completa('s-ontem'),
        rota: AppRoutes.pacienteDetalheNome,
      );

      expect(find.text(AppStrings.perfilNaoEnviadas(1)), findsOneWidget);
      await _tocar(tester, AppStrings.perfilRevisarGravacoes);

      expect(find.byType(GravacoesNaoEnviadasPage), findsOneWidget);
      expect(
        find.text(AppStrings.naoEnviadasSessao('23 set 2026', '10:15')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.naoEnviadasTarefas(2, 2)), findsOneWidget);
    });

    testWidgets('sem nada parado, o perfil não avisa', (tester) async {
      await _abrir(tester, rota: AppRoutes.pacienteDetalheNome);

      expect(find.text(AppStrings.perfilRevisarGravacoes), findsNothing);
    });

    testWidgets('descartar pede confirmação; "Manter" não apaga nada', (
      tester,
    ) async {
      final c = await _abrir(tester, gravadas: _completa('s-ontem'));

      await _tocar(tester, AppStrings.naoEnviadasDescartar);
      expect(find.text(AppStrings.naoEnviadasConfirmar(2)), findsOneWidget);

      await _tocar(tester, AppStrings.naoEnviadasManter);
      expect(find.text(AppStrings.naoEnviadasConfirmar(2)), findsNothing);
      expect(c.disco.apagados, isEmpty);
      expect(await c.amostras.doPaciente('p1'), hasLength(2));
    });

    testWidgets('descartar de vez apaga os arquivos e o registro', (
      tester,
    ) async {
      final c = await _abrir(tester, gravadas: _completa('s-ontem'));

      await _tocar(tester, AppStrings.naoEnviadasDescartar);
      await _tocar(tester, AppStrings.naoEnviadasDescartarDeVez);

      expect(c.disco.apagados, {
        for (final a in _completa('s-ontem')) a.caminho,
      });
      expect(await c.amostras.doPaciente('p1'), isEmpty);
      expect(find.text(AppStrings.naoEnviadasVazia), findsOneWidget);
    });

    testWidgets('arquivo que não sai: a sessão fica, e diz por quê', (
      tester,
    ) async {
      final c = await _abrir(tester, gravadas: _completa('s-ontem'));
      c.disco.falhar = true;

      await _tocar(tester, AppStrings.naoEnviadasDescartar);
      await _tocar(tester, AppStrings.naoEnviadasDescartarDeVez);

      expect(find.text(AppStrings.naoEnviadasErroDescartar), findsOneWidget);
      // O registro continua: o WAV não ficou no disco sem ninguém saber.
      expect(await c.amostras.doPaciente('p1'), hasLength(2));
    });

    testWidgets('a completa vai para a fila e sai da lista', (tester) async {
      final c = await _abrir(tester, gravadas: _completa('s-ontem'));

      await _tocar(tester, AppStrings.naoEnviadasEnviar);

      final envio = (await c.fila.listar()).single;
      expect(envio.sessaoId, 's-ontem');
      expect(envio.nomeDoPaciente, 'Ana de Teste');
      expect([
        for (final a in envio.amostras) a.tarefa,
      ], TarefaDeGravacao.values);
      expect(find.text(AppStrings.naoEnviadasVazia), findsOneWidget);
    });

    testWidgets('incompleta não se envia, e diz por quê', (tester) async {
      await _abrir(
        tester,
        gravadas: [_amostra('s-ontem', TarefaDeGravacao.vogalSustentada)],
      );

      expect(_habilitado(tester, AppStrings.naoEnviadasEnviar), isFalse);
      expect(find.text(AppStrings.naoEnviadasIncompleta), findsOneWidget);
    });

    testWidgets('sem consentimento em vigor não se envia — mas se descarta', (
      tester,
    ) async {
      await _abrir(
        tester,
        gravadas: _completa('s-ontem'),
        comConsentimento: false,
      );

      expect(_habilitado(tester, AppStrings.naoEnviadasEnviar), isFalse);
      expect(find.text(AppStrings.naoEnviadasSemConsentimento), findsOneWidget);
      expect(_habilitado(tester, AppStrings.naoEnviadasDescartar), isTrue);
    });

    for (final (nome, tamanho) in [
      ('celular', const Size(390, 844)),
      ('desktop', const Size(1440, 900)),
    ]) {
      testWidgets('$nome em 200% não estoura', (tester) async {
        await _abrir(
          tester,
          gravadas: _completa('s-ontem'),
          tamanho: tamanho,
          escala: 2,
        );
        await _tocar(tester, AppStrings.naoEnviadasDescartar);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
