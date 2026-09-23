import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';
import 'package:fonar_app/features/captura/data/repositorio_amostras_local.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/captura/presentation/gravacao_controlador.dart';
import 'package:fonar_app/features/reproducao/data/reprodutor_just_audio.dart';
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
}

class _ReprodutorQuieto implements Reprodutor {
  @override
  Future<Duration?> abrir(String caminho) async => const Duration(seconds: 3);
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
