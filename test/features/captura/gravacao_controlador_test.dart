import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/captura/data/fonte_de_nivel_record.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';
import 'package:fonar_app/features/captura/data/repositorio_amostras_local.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/fonte_de_nivel.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/captura/presentation/afericao_controlador.dart';
import 'package:fonar_app/features/captura/presentation/gravacao_controlador.dart';
import 'package:fonar_app/features/reproducao/data/reprodutor_audioplayers.dart';
import 'package:fonar_app/features/reproducao/domain/reprodutor.dart';
import 'package:fonar_app/features/reproducao/presentation/reproducao_controlador.dart';

import '../../apoio/repositorios_em_memoria.dart';

// Achados da revisão de 23/09: a gravação podia começar depois de a tela
// fechar, e erro ou fim do fluxo de nível não encerravam a gravação.

/// Gravador cujo fluxo de nível o teste controla.
class _Gravador implements Gravador {
  final niveis = StreamController<double>();
  var inicios = 0;
  var descartes = 0;

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
  Future<void> descartar() async => descartes++;
}

/// Disco que pode segurar a criação do caminho.
class _Arquivos implements ArquivosDeAmostra {
  Completer<void>? segurar;
  final apagados = <String>[];

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao t) async {
    await segurar?.future;
    return '/amostras/$pacienteId/${t.name}.wav';
  }

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async => null;

  @override
  Future<void> apagar(String caminho) async => apagados.add(caminho);
}

(ProviderContainer, _Gravador, _Arquivos) _montar() {
  final gravador = _Gravador();
  final arquivos = _Arquivos();
  final container = ProviderContainer(
    overrides: [
      gravadorProvider.overrideWithValue(gravador),
      arquivosDeAmostraProvider.overrideWithValue(arquivos),
      repositorioAmostrasProvider.overrideWithValue(
        RepositorioAmostrasPlaceholder(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return (container, gravador, arquivos);
}

void main() {
  test(
    'tela fechada enquanto o caminho é criado: o microfone não abre',
    () async {
      final (container, gravador, arquivos) = _montar();
      arquivos.segurar = Completer<void>();
      final tela = container.listen(
        gravacaoControladorProvider('p1'),
        (_, _) {},
      );

      final iniciando = container
          .read(gravacaoControladorProvider('p1').notifier)
          .iniciar(TarefaDeGravacao.vogalSustentada);
      await Future<void>.delayed(Duration.zero);
      tela.close();
      await container.pump();

      arquivos.segurar!.complete();
      await iniciando;
      expect(gravador.inicios, 0);
    },
  );

  for (final (nome, derrubar) in [
    ('erro', (_Gravador g) => g.niveis.addError(Exception('microfone caiu'))),
    ('fim inesperado', (_Gravador g) => g.niveis.close()),
  ]) {
    test(
      '$nome do fluxo de nível: gravação descartada, com o motivo',
      () async {
        final (container, gravador, arquivos) = _montar();
        container.listen(gravacaoControladorProvider('p1'), (_, _) {});
        final controlador = container.read(
          gravacaoControladorProvider('p1').notifier,
        );

        await controlador.iniciar(TarefaDeGravacao.vogalSustentada);
        gravador.niveis.add(-20);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(gravacaoControladorProvider('p1')).gravando,
          TarefaDeGravacao.vogalSustentada,
        );

        derrubar(gravador);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final estado = container.read(gravacaoControladorProvider('p1'));
        expect(estado.gravando, isNull);
        expect(estado.amostras, isEmpty);
        expect(estado.falha?.motivo, FalhaDaGravacao.interrompida);
        expect(gravador.descartes, 1);
        expect(arquivos.apagados, ['/amostras/p1/vogalSustentada.wav']);
      },
    );
  }

  group('GravadorRecord encerrado', () {
    test('não reabre o microfone', () async {
      final gravador = GravadorRecord();
      await gravador.encerrar();

      expect(() => gravador.pedirPermissao(), throwsStateError);
      await expectLater(
        gravador.iniciar('/x.wav', const Duration(milliseconds: 100)),
        throwsStateError,
      );
    });
  });

  test('gravar para o que estiver tocando', () async {
    // O som do alto-falante entraria no microfone e na amostra.
    final gravador = _Gravador();
    final comReproducao = ProviderContainer(
      overrides: [
        gravadorProvider.overrideWithValue(gravador),
        arquivosDeAmostraProvider.overrideWithValue(_Arquivos()),
        repositorioAmostrasProvider.overrideWithValue(
          RepositorioAmostrasPlaceholder(),
        ),
        reprodutorProvider.overrideWithValue(_ReprodutorQuieto()),
      ],
    );
    addTearDown(comReproducao.dispose);
    comReproducao.listen(reproducaoControladorProvider, (_, _) {});
    comReproducao.listen(gravacaoControladorProvider('p1'), (_, _) {});
    await comReproducao
        .read(reproducaoControladorProvider.notifier)
        .alternar('/amostras/p1/antiga.wav');
    expect(comReproducao.read(reproducaoControladorProvider).tocando, isTrue);

    await comReproducao
        .read(gravacaoControladorProvider('p1').notifier)
        .iniciar(TarefaDeGravacao.falaEncadeada);

    expect(comReproducao.read(reproducaoControladorProvider).tocando, isFalse);
    expect(gravador.inicios, 1);
  });

  // Revisão de 24/09: a gravação que ainda abria não era parada, e tocava
  // depois, com o microfone já ligado.
  group('áudio ainda abrindo quando a coleta começa', () {
    late _ReprodutorQuieto reprodutor;
    late ProviderContainer c;
    late Future<void> abrindo;

    setUp(() async {
      reprodutor = _ReprodutorQuieto()..segurarAbrir = Completer<void>();
      c = ProviderContainer(
        overrides: [
          gravadorProvider.overrideWithValue(_Gravador()),
          arquivosDeAmostraProvider.overrideWithValue(_Arquivos()),
          repositorioAmostrasProvider.overrideWithValue(
            RepositorioAmostrasPlaceholder(),
          ),
          fonteDeNivelProvider.overrideWithValue(_FonteSemPermissao()),
          reprodutorProvider.overrideWithValue(reprodutor),
        ],
      );
      addTearDown(c.dispose);
      c.listen(reproducaoControladorProvider, (_, _) {});
      abrindo = c
          .read(reproducaoControladorProvider.notifier)
          .alternar('/amostras/p1/antiga.wav');
      await Future<void>.delayed(Duration.zero);
    });

    test('gravar: a gravação antiga não toca depois', () async {
      c.listen(gravacaoControladorProvider('p1'), (_, _) {});
      await c
          .read(gravacaoControladorProvider('p1').notifier)
          .iniciar(TarefaDeGravacao.falaEncadeada);
      reprodutor.segurarAbrir!.complete();
      await abrindo;

      expect(reprodutor.toques, 0);
      expect(c.read(reproducaoControladorProvider).tocando, isFalse);
    });

    test('aferir: a gravação antiga não toca depois', () async {
      c.listen(afericaoControladorProvider, (_, _) {});
      await c.read(afericaoControladorProvider.notifier).medir();
      reprodutor.segurarAbrir!.complete();
      await abrindo;

      expect(reprodutor.toques, 0);
      expect(c.read(reproducaoControladorProvider).tocando, isFalse);
    });
  });
}

class _ReprodutorQuieto implements Reprodutor {
  Completer<void>? segurarAbrir;
  var toques = 0;

  @override
  Future<Duration?> abrir(String caminho) async {
    await segurarAbrir?.future;
    return const Duration(seconds: 3);
  }

  @override
  Future<void> tocar() async => toques++;
  @override
  Future<void> pausar() async {}
  @override
  Future<void> irPara(Duration posicao) async {}
  @override
  Stream<Duration> get posicoes => const Stream.empty();
  @override
  Stream<void> get terminou => const Stream.empty();
  @override
  Stream<Object> get falhas => const Stream.empty();
  @override
  Future<void> fechar() async {}
}

/// Microfone sem permissão: a aferição para logo depois de parar o áudio.
class _FonteSemPermissao implements FonteDeNivel {
  @override
  AjusteDeConfiguracao? get ajuste => null;
  @override
  Future<bool> pedirPermissao() async => false;
  @override
  Future<Stream<double>> abrir(Duration intervalo) async =>
      const Stream.empty();
  @override
  Future<void> fechar() async {}
}
