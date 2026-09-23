import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/reproducao/data/reprodutor_just_audio.dart';
import 'package:fonar_app/features/reproducao/domain/reprodutor.dart';
import 'package:fonar_app/features/reproducao/presentation/reproducao_controlador.dart';
import 'package:fonar_app/features/reproducao/presentation/widgets/player_de_amostra.dart';
import 'package:fonar_app/l10n/app_strings.dart';

/// Reprodutor de mentira: registra o que pediram e deixa o teste emitir a
/// posição e o fim.
class ReprodutorFalso implements Reprodutor {
  final chamadas = <String>[];
  final posicoesCtrl = StreamController<Duration>.broadcast();
  final terminouCtrl = StreamController<void>.broadcast();
  final falhaAoAbrir = <String>{};
  Completer<void>? segurarAbrir;

  @override
  Future<Duration?> abrir(String caminho) async {
    chamadas.add('abrir $caminho');
    await segurarAbrir?.future;
    if (falhaAoAbrir.contains(caminho)) throw Exception('arquivo ilegível');
    return const Duration(seconds: 5);
  }

  @override
  Future<void> tocar() async => chamadas.add('tocar');

  @override
  Future<void> pausar() async => chamadas.add('pausar');

  @override
  Future<void> irPara(Duration posicao) async =>
      chamadas.add('irPara ${posicao.inMilliseconds}');

  @override
  Stream<Duration> get posicoes => posicoesCtrl.stream;

  @override
  Stream<void> get terminou => terminouCtrl.stream;

  @override
  Future<void> fechar() async => chamadas.add('fechar');
}

(ProviderContainer, ReprodutorFalso) _montar() {
  final reprodutor = ReprodutorFalso();
  final container = ProviderContainer(
    overrides: [reprodutorProvider.overrideWithValue(reprodutor)],
  );
  addTearDown(container.dispose);
  container.listen(reproducaoControladorProvider, (_, _) {});
  return (container, reprodutor);
}

void main() {
  group('controlador', () {
    test('toca, pausa e continua sem abrir de novo', () async {
      final (c, r) = _montar();
      final controlador = c.read(reproducaoControladorProvider.notifier);

      await controlador.alternar('/a.wav');
      expect(c.read(reproducaoControladorProvider).tocando, isTrue);
      expect(c.read(reproducaoControladorProvider).duracao, 5.segundos);

      await controlador.alternar('/a.wav');
      expect(c.read(reproducaoControladorProvider).tocando, isFalse);

      await controlador.alternar('/a.wav');
      expect(c.read(reproducaoControladorProvider).tocando, isTrue);
      expect(r.chamadas.where((x) => x.startsWith('abrir')), ['abrir /a.wav']);
    });

    test('a posição acompanha, e o fim volta ao começo', () async {
      final (c, r) = _montar();
      await c.read(reproducaoControladorProvider.notifier).alternar('/a.wav');

      r.posicoesCtrl.add(2.segundos);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(reproducaoControladorProvider).posicao, 2.segundos);

      r.terminouCtrl.add(null);
      await Future<void>.delayed(Duration.zero);
      final estado = c.read(reproducaoControladorProvider);
      expect(estado.tocando, isFalse);
      expect(estado.posicao, Duration.zero);
      expect(estado.caminho, '/a.wav');
    });

    test('tocar outra gravação troca a que estava tocando', () async {
      final (c, r) = _montar();
      final controlador = c.read(reproducaoControladorProvider.notifier);
      await controlador.alternar('/a.wav');

      await controlador.alternar('/b.wav');

      final estado = c.read(reproducaoControladorProvider);
      expect(estado.caminho, '/b.wav');
      expect(estado.tocando, isTrue);
      expect(r.chamadas, containsAllInOrder(['pausar', 'abrir /b.wav']));
    });

    test('abertura atrasada não toma o lugar da mais nova', () async {
      final (c, r) = _montar();
      final controlador = c.read(reproducaoControladorProvider.notifier);
      r.segurarAbrir = Completer<void>();
      final primeira = controlador.alternar('/a.wav');
      await Future<void>.delayed(Duration.zero);
      final segunda = controlador.alternar('/b.wav');
      r.segurarAbrir!.complete();
      await Future.wait([primeira, segunda]);

      expect(c.read(reproducaoControladorProvider).caminho, '/b.wav');
    });

    test('arquivo que não abre: diz, e não fica "tocando"', () async {
      final (c, r) = _montar();
      r.falhaAoAbrir.add('/quebrado.wav');

      await c
          .read(reproducaoControladorProvider.notifier)
          .alternar('/quebrado.wav');

      final estado = c.read(reproducaoControladorProvider);
      expect(estado.falhou, isTrue);
      expect(estado.tocando, isFalse);
    });

    test('parar pausa o que estiver tocando', () async {
      final (c, _) = _montar();
      final controlador = c.read(reproducaoControladorProvider.notifier);
      await controlador.alternar('/a.wav');

      await controlador.parar();

      expect(c.read(reproducaoControladorProvider).tocando, isFalse);
    });
  });

  group('PlayerDeAmostra', () {
    Future<ReprodutorFalso> abrir(
      WidgetTester tester, {
      String? bloqueio,
    }) async {
      final reprodutor = ReprodutorFalso();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [reprodutorProvider.overrideWithValue(reprodutor)],
          child: MaterialApp(
            theme: AppTheme.claro,
            home: Scaffold(
              body: PlayerDeAmostra(
                caminho: '/a.wav',
                rotulo: 'Vogal',
                duracaoConhecida: 3.segundos,
                bloqueio: bloqueio,
              ),
            ),
          ),
        ),
      );
      return reprodutor;
    }

    testWidgets('tocar e pausar, com nome para o leitor de tela', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final reprodutor = await abrir(tester);
      expect(find.text('0:00 / 0:03'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel(AppStrings.reproducaoOuvir('Vogal')),
      );
      await tester.pump();
      expect(reprodutor.chamadas, contains('tocar'));
      expect(
        find.bySemanticsLabel(AppStrings.reproducaoPausar('Vogal')),
        findsOneWidget,
      );
      semantica.dispose();
    });

    testWidgets('bloqueado: não toca, e diz por quê', (tester) async {
      final semantica = tester.ensureSemantics();
      final reprodutor = await abrir(
        tester,
        bloqueio: AppStrings.reproducaoBloqueadaGravando,
      );

      expect(find.text(AppStrings.reproducaoBloqueadaGravando), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel(AppStrings.reproducaoOuvir('Vogal')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(reprodutor.chamadas, isEmpty);
      semantica.dispose();
    });
  });

  test('minutos e segundos', () {
    expect(AppStrings.minutosSegundos(7.segundos), '0:07');
    expect(AppStrings.minutosSegundos(83.segundos), '1:23');
  });
}

extension on int {
  Duration get segundos => Duration(seconds: this);
}
