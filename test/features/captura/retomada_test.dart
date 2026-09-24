import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';
import 'package:fonar_app/features/captura/data/repositorio_amostras_local.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/captura/domain/retomada.dart';
import 'package:fonar_app/features/captura/domain/verificacao_da_amostra.dart';
import 'package:fonar_app/features/captura/presentation/gravacao_controlador.dart';
import 'package:fonar_app/features/captura/presentation/widgets/tarefas_de_gravacao.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';

final _agora = DateTime(2026, 9, 23, 15);

Amostra _amostra(
  TarefaDeGravacao tarefa, {
  String sessaoId = 's-hoje',
  String pacienteId = 'p1',
  DateTime? gravadaEm,
  List<ProblemaNaAmostra> problemas = const [],
}) => Amostra(
  id: '$sessaoId-${tarefa.name}',
  pacienteId: pacienteId,
  sessaoId: sessaoId,
  tarefa: tarefa,
  caminho: '/amostras/$pacienteId/$sessaoId-${tarefa.name}.wav',
  gravadaEm: gravadaEm ?? DateTime(2026, 9, 23, 10, 15),
  duracao: const Duration(seconds: 4),
  taxaDeAmostragem: 44100,
  canais: 1,
  problemas: problemas,
);

class _Gravador implements Gravador {
  var inicios = 0;
  final niveis = StreamController<double>();

  @override
  Future<bool> pedirPermissao() async => true;

  @override
  Future<Stream<double>> iniciar(String caminho, Duration intervalo) async {
    inicios++;
    return niveis.stream;
  }

  @override
  Future<void> parar() async {}

  @override
  Future<void> descartar() async {}
}

/// Disco com os arquivos dados; os outros "sumiram".
class _Disco implements ArquivosDeAmostra {
  _Disco(this.existentes);
  final Set<String> existentes;

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao t) async =>
      '/amostras/$pacienteId/nova-${t.name}.wav';

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async =>
      existentes.contains(caminho)
      ? (inicio: Uint8List(44), tamanho: 44)
      : null;

  @override
  Future<void> apagar(String caminho) async => existentes.remove(caminho);
}

class _AmostrasQuebradas extends RepositorioAmostrasPlaceholder {
  @override
  Future<List<Amostra>> ultimaSessao(String pacienteId) =>
      Future.error(StateError('banco indisponível'));
}

/// Monta o controlador de gravação de p1 com as [gravadas] no banco.
Future<ProviderContainer> _montar({
  List<Amostra> gravadas = const [],
  Set<String>? noDisco,
  List<String> sessoesNaFila = const [],
  RepositorioAmostras? repositorio,
  _Gravador? gravador,
}) async {
  final amostras = RepositorioAmostrasPlaceholder();
  for (final a in gravadas) {
    await amostras.guardar(a);
  }
  final fila = RepositorioFilaEmMemoria();
  for (final s in sessoesNaFila) {
    await fila.adicionar(
      ItemDaFila(
        id: 'envio-$s',
        pacienteId: 'p1',
        nomeDoPaciente: 'Ana de Teste',
        sessaoId: s,
        amostras: const [],
        criadoEm: _agora,
      ),
    );
  }
  final container = ProviderContainer(
    overrides: [
      gravadorProvider.overrideWithValue(gravador ?? _Gravador()),
      arquivosDeAmostraProvider.overrideWithValue(
        _Disco(noDisco ?? {for (final a in gravadas) a.caminho}),
      ),
      repositorioAmostrasProvider.overrideWithValue(repositorio ?? amostras),
      repositorioFilaProvider.overrideWithValue(fila),
      relogioProvider.overrideWithValue(() => _agora),
    ],
  );
  addTearDown(container.dispose);
  container.listen(gravacaoControladorProvider('p1'), (_, _) {});
  return container;
}

Future<EstadoDaGravacao> _depoisDeAbrir(ProviderContainer c) async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return c.read(gravacaoControladorProvider('p1'));
}

void main() {
  group('sessaoARetomar', () {
    test('sem gravação anterior, sessão nova', () {
      expect(
        sessaoARetomar(
          ultimaSessao: const [],
          sessoesNaFila: {},
          agora: _agora,
        ),
        isNull,
      );
    });

    test('a de hoje, fora da fila, é retomada — por tarefa', () {
      final sessao = sessaoARetomar(
        ultimaSessao: [
          _amostra(TarefaDeGravacao.vogalSustentada),
          _amostra(TarefaDeGravacao.falaEncadeada),
        ],
        sessoesNaFila: {'outra'},
        agora: _agora,
      );

      expect(sessao?.keys, TarefaDeGravacao.values);
    });

    test('a que já foi para a fila não é retomada', () {
      expect(
        sessaoARetomar(
          ultimaSessao: [_amostra(TarefaDeGravacao.vogalSustentada)],
          sessoesNaFila: {'s-hoje'},
          agora: _agora,
        ),
        isNull,
      );
    });

    test('a de ontem não é retomada, nem com uma tarefa regravada hoje', () {
      final ontem = DateTime(2026, 9, 22, 18);

      expect(
        sessaoARetomar(
          ultimaSessao: [
            _amostra(TarefaDeGravacao.vogalSustentada, gravadaEm: ontem),
          ],
          sessoesNaFila: {},
          agora: _agora,
        ),
        isNull,
      );
      expect(
        sessaoARetomar(
          ultimaSessao: [
            _amostra(TarefaDeGravacao.vogalSustentada, gravadaEm: ontem),
            _amostra(TarefaDeGravacao.falaEncadeada),
          ],
          sessoesNaFila: {},
          agora: _agora,
        ),
        isNull,
      );
    });

    test('amostra inválida não volta como gravada', () {
      final sessao = sessaoARetomar(
        ultimaSessao: [
          _amostra(TarefaDeGravacao.vogalSustentada),
          _amostra(
            TarefaDeGravacao.falaEncadeada,
            problemas: [ProblemaNaAmostra.semSinal],
          ),
        ],
        sessoesNaFila: {},
        agora: _agora,
      );

      expect(sessao?.keys, [TarefaDeGravacao.vogalSustentada]);
    });
  });

  group('no banco local', () {
    test('a última sessão é a da gravação mais nova, só do paciente', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repositorio = RepositorioAmostrasLocal(banco);
      await repositorio.guardar(
        _amostra(
          TarefaDeGravacao.vogalSustentada,
          sessaoId: 's-manha',
          gravadaEm: DateTime(2026, 9, 23, 9),
        ),
      );
      await repositorio.guardar(
        _amostra(
          TarefaDeGravacao.vogalSustentada,
          sessaoId: 's-tarde',
          gravadaEm: DateTime(2026, 9, 23, 14),
        ),
      );
      await repositorio.guardar(
        _amostra(
          TarefaDeGravacao.falaEncadeada,
          sessaoId: 's-tarde',
          gravadaEm: DateTime(2026, 9, 23, 14, 5),
        ),
      );
      await repositorio.guardar(
        _amostra(
          TarefaDeGravacao.vogalSustentada,
          sessaoId: 's-outro',
          pacienteId: 'p2',
          gravadaEm: DateTime(2026, 9, 23, 16),
        ),
      );

      final ultima = await repositorio.ultimaSessao('p1');
      expect({for (final a in ultima) a.sessaoId}, {'s-tarde'});
      expect(ultima, hasLength(2));
      expect(await repositorio.ultimaSessao('p3'), isEmpty);
    });
  });

  group('controlador', () {
    test(
      'ao abrir, continua a sessão de hoje com o que já foi gravado',
      () async {
        final c = await _montar(
          gravadas: [
            _amostra(
              TarefaDeGravacao.vogalSustentada,
              gravadaEm: DateTime(2026, 9, 23, 10, 15),
            ),
            _amostra(
              TarefaDeGravacao.falaEncadeada,
              gravadaEm: DateTime(2026, 9, 23, 10, 20),
            ),
          ],
        );

        final estado = await _depoisDeAbrir(c);

        expect(estado.retomando, isFalse);
        expect(estado.sessaoId, 's-hoje');
        expect(estado.amostras.keys, TarefaDeGravacao.values);
        expect(estado.retomadaDe, DateTime(2026, 9, 23, 10, 15));
        // Pronta para enviar, sem regravar nada.
        expect(estado.completa, isTrue);
      },
    );

    test('tarefa cujo arquivo sumiu volta a "por gravar"', () async {
      final vogal = _amostra(TarefaDeGravacao.vogalSustentada);
      final c = await _montar(
        gravadas: [vogal, _amostra(TarefaDeGravacao.falaEncadeada)],
        noDisco: {vogal.caminho},
      );

      final estado = await _depoisDeAbrir(c);

      expect(estado.sessaoId, 's-hoje');
      expect(estado.amostras.keys, [TarefaDeGravacao.vogalSustentada]);
      expect(estado.completa, isFalse);
    });

    test('a sessão já na fila não é retomada: começa outra', () async {
      final c = await _montar(
        gravadas: [_amostra(TarefaDeGravacao.vogalSustentada)],
        sessoesNaFila: ['s-hoje'],
      );

      final estado = await _depoisDeAbrir(c);

      expect(estado.sessaoId, isNot('s-hoje'));
      expect(estado.amostras, isEmpty);
      expect(estado.retomadaDe, isNull);
    });

    test('sem conseguir ler o banco, começa outra — e não trava', () async {
      final c = await _montar(repositorio: _AmostrasQuebradas());

      final estado = await _depoisDeAbrir(c);

      expect(estado.retomando, isFalse);
      expect(estado.amostras, isEmpty);
      expect(estado.retomadaDe, isNull);
    });

    test(
      'gravar logo ao abrir espera a busca, e grava na sessão retomada',
      () async {
        final gravador = _Gravador();
        final c = await _montar(
          gravadas: [_amostra(TarefaDeGravacao.vogalSustentada)],
          gravador: gravador,
        );

        // Antes de a busca terminar.
        expect(c.read(gravacaoControladorProvider('p1')).retomando, isTrue);
        await c
            .read(gravacaoControladorProvider('p1').notifier)
            .iniciar(TarefaDeGravacao.falaEncadeada);

        final estado = c.read(gravacaoControladorProvider('p1'));
        expect(gravador.inicios, 1);
        expect(estado.gravando, TarefaDeGravacao.falaEncadeada);
        expect(estado.sessaoId, 's-hoje');
        expect(estado.amostras.keys, [TarefaDeGravacao.vogalSustentada]);
        // O aviso continua enquanto grava.
        expect(estado.retomadaDe, isNotNull);
      },
    );
  });

  group('tela', () {
    Future<void> abrir(WidgetTester tester, List<Amostra> gravadas) async {
      final amostras = RepositorioAmostrasPlaceholder();
      for (final a in gravadas) {
        await amostras.guardar(a);
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gravadorProvider.overrideWithValue(_Gravador()),
            arquivosDeAmostraProvider.overrideWithValue(
              _Disco({for (final a in gravadas) a.caminho}),
            ),
            repositorioAmostrasProvider.overrideWithValue(amostras),
            repositorioFilaProvider.overrideWithValue(
              RepositorioFilaEmMemoria(),
            ),
            relogioProvider.overrideWithValue(() => _agora),
            bancoDeTeste(),
          ],
          child: MaterialApp(
            theme: AppTheme.claro,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: TarefasDeGravacao(pacienteId: 'p1'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sessão retomada diz desde quando e o que já vale', (
      tester,
    ) async {
      await abrir(tester, [_amostra(TarefaDeGravacao.vogalSustentada)]);

      expect(find.text(AppStrings.capturaRetomadaTitulo), findsOneWidget);
      expect(
        find.text(AppStrings.capturaRetomadaTexto('10:15', 1, 2)),
        findsOneWidget,
      );
    });

    testWidgets('sessão nova não mostra aviso nenhum', (tester) async {
      await abrir(tester, const []);

      expect(find.text(AppStrings.capturaRetomadaTitulo), findsNothing);
    });
  });
}
