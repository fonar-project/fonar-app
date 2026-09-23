import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/fila/data/envio_de_analise_api.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_em_memoria.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/fila/presentation/fila_controlador.dart';

/// Rede ligável e desligável pelo teste.
class _Rede extends Notifier<bool> {
  _Rede(this._inicial);
  final bool _inicial;
  @override
  bool build() => _inicial;
  void ligar(bool online) => state = online;
}

/// Envio controlável: cada chamada consome o próximo comportamento da lista;
/// lista vazia é sucesso.
class _Envio implements EnvioDeAnalise {
  final comportamentos = <Future<String> Function()>[];
  final recebidos = <String>[];
  Cancelamento? _cancelamento;

  void falharCom(AppException falha) =>
      comportamentos.add(() => Future.error(falha));

  /// O próximo envio fica no ar até ser cancelado.
  void segurarAteCancelar() => comportamentos.add(() async {
    await _cancelamento!.quandoPedido;
    throw const EnvioCancelado();
  });

  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) {
    recebidos.add(item.id);
    _cancelamento = cancelamento;
    if (comportamentos.isEmpty) {
      return Future.value('analise-${recebidos.length}');
    }
    return comportamentos.removeAt(0)();
  }
}

final _amostra = Amostra(
  id: 'a1',
  pacienteId: 'p1',
  sessaoId: 's1',
  tarefa: TarefaDeGravacao.vogalSustentada,
  caminho: '/amostras/p1/a1.wav',
  gravadaEm: DateTime(2026, 9, 23, 9, 50),
  duracao: const Duration(seconds: 3),
  taxaDeAmostragem: 44100,
  canais: 1,
  problemas: const [],
);

class _Fila {
  _Fila(this.container, this.envio, this.rede);

  final ProviderContainer container;
  final _Envio envio;
  final NotifierProvider<_Rede, bool> rede;
  var agora = DateTime(2026, 9, 23, 10);

  FilaControlador get controlador =>
      container.read(filaControladorProvider.notifier);
  List<ItemDaFila> get itens => container.read(filaControladorProvider).value!;
  ItemDaFila get item => itens.single;

  /// Liga ou desliga a rede. A leitura logo em seguida é o que faz a mudança
  /// chegar a quem escuta: num ProviderContainer solto, sem a árvore de
  /// widgets, o Riverpod só propaga quando alguém lê. No app, dentro do
  /// ProviderScope, a propagação acontece sozinha.
  void ligarRede(bool online) {
    container.read(rede.notifier).ligar(online);
    container.read(conexaoOnlineProvider);
  }

  Future<ItemDaFila> enfileirar({String sessaoId = 's1'}) =>
      controlador.enfileirar(
        pacienteId: 'p1',
        nomeDoPaciente: 'Ana de Teste',
        sessaoId: sessaoId,
        amostras: [_amostra],
      );
}

Future<_Fila> _montar(WidgetTester tester, {bool online = true}) async {
  final envio = _Envio();
  final rede = NotifierProvider<_Rede, bool>(() => _Rede(online));
  late _Fila fila;
  final container = ProviderContainer(
    overrides: [
      envioDeAnaliseProvider.overrideWithValue(envio),
      // Profissional com a sessão aberta: sem ela a fila não envia.
      sessaoAbertaProvider.overrideWith(() => Sessao(true)),
      repositorioFilaProvider.overrideWithValue(RepositorioFilaEmMemoria()),
      conexaoOnlineProvider.overrideWith((ref) => ref.watch(rede)),
      relogioProvider.overrideWithValue(() => fila.agora),
    ],
  );
  fila = _Fila(container, envio, rede);
  // Mantém a fila viva, como o FonarApp faz.
  container.listen(filaControladorProvider, (_, _) {});
  await container.read(filaControladorProvider.future);
  return fila;
}

/// Um teste da fila. A fila é encerrada ao fim do corpo, e não num
/// `addTearDown`: o timer da próxima tentativa precisa ser cancelado antes de
/// o teste conferir que não sobrou timer pendente.
void _testarFila(
  String descricao,
  Future<void> Function(WidgetTester tester, _Fila fila) corpo, {
  bool online = true,
}) {
  testWidgets(descricao, (tester) async {
    final fila = await _montar(tester, online: online);
    try {
      await corpo(tester, fila);
    } finally {
      fila.container.dispose();
    }
  });
}

/// Deixa a fila terminar o que começou. Mudar a rede avisa a fila no meio de
/// um ciclo, e o que ela faz em seguida fica para os ciclos seguintes.
Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

/// Avança o relógio da fila e os timers juntos.
Future<void> _passar(WidgetTester tester, _Fila fila, Duration d) async {
  fila.agora = fila.agora.add(d);
  await tester.pump(d);
}

void main() {
  group('PoliticaDeReenvio', () {
    test('espera dobra a cada falha, até 30 minutos', () {
      expect(
        [for (var n = 1; n <= 8; n++) PoliticaDeReenvio.esperaApos(n)],
        const [
          Duration(seconds: 30),
          Duration(minutes: 1),
          Duration(minutes: 2),
          Duration(minutes: 4),
          Duration(minutes: 8),
          Duration(minutes: 16),
          Duration(minutes: 30),
          Duration(minutes: 30),
        ],
      );
      expect(PoliticaDeReenvio.esperaApos(500), PoliticaDeReenvio.esperaMaxima);
    });

    test('falha passageira tenta de novo; sessão e recusa não', () {
      for (final falha in const <AppException>[
        FalhaDeConexao(),
        TempoEsgotado(),
        FalhaNoServidor(statusCode: 503),
        FalhaDesconhecida(),
      ]) {
        expect(
          PoliticaDeReenvio.depoisDe(falha),
          SituacaoDoEnvio.aguardandoNovaTentativa,
          reason: '$falha',
        );
      }
      expect(
        PoliticaDeReenvio.depoisDe(const NaoAutorizado()),
        SituacaoDoEnvio.aguardandoLogin,
      );
      for (final falha in const <AppException>[
        FalhaDeValidacao(),
        Proibido(),
        NaoEncontrado(),
      ]) {
        expect(
          PoliticaDeReenvio.depoisDe(falha),
          SituacaoDoEnvio.recusado,
          reason: '$falha',
        );
      }
    });
  });

  group('FilaControlador', () {
    _testarFila('online: envia na hora e guarda o id da análise', (
      tester,
      fila,
    ) async {
      await fila.enfileirar();
      await tester.pump();

      expect(fila.item.situacao, SituacaoDoEnvio.enviado);
      expect(fila.item.analiseId, 'analise-1');
      expect(fila.item.tentativas, 1);
    });

    _testarFila('offline: fica na fila e sobe quando a rede volta', (
      tester,
      fila,
    ) async {
      await fila.enfileirar();
      await tester.pump();
      expect(fila.item.situacao, SituacaoDoEnvio.naFila);
      expect(fila.envio.recebidos, isEmpty);

      fila.ligarRede(true);
      await _assentar(tester);

      expect(fila.item.situacao, SituacaoDoEnvio.enviado);
    }, online: false);

    _testarFila('falha passageira: espera, tenta de novo com a MESMA chave', (
      tester,
      fila,
    ) async {
      fila.envio.falharCom(const FalhaDeConexao());

      final item = await fila.enfileirar();
      await tester.pump();

      expect(fila.item.situacao, SituacaoDoEnvio.aguardandoNovaTentativa);
      expect(fila.item.ultimaFalha, isNotNull);
      expect(
        fila.item.proximaTentativa,
        fila.agora.add(const Duration(seconds: 30)),
      );

      await _passar(tester, fila, const Duration(seconds: 29));
      expect(fila.envio.recebidos, hasLength(1));

      await _passar(tester, fila, const Duration(seconds: 1));
      expect(fila.item.situacao, SituacaoDoEnvio.enviado);
      // Idempotência: a nova tentativa é o mesmo envio, não um envio novo.
      expect(fila.envio.recebidos, [item.id, item.id]);
    });

    _testarFila('segunda falha espera o dobro', (tester, fila) async {
      fila.envio
        ..falharCom(const FalhaNoServidor(statusCode: 503))
        ..falharCom(const FalhaNoServidor(statusCode: 503));

      await fila.enfileirar();
      await tester.pump();
      await _passar(tester, fila, const Duration(seconds: 30));

      expect(fila.item.tentativas, 2);
      expect(
        fila.item.proximaTentativa,
        fila.agora.add(const Duration(minutes: 1)),
      );
    });

    _testarFila('recusa não se repete sozinha; tentar agora repete', (
      tester,
      fila,
    ) async {
      fila.envio.falharCom(const FalhaDeValidacao());

      await fila.enfileirar();
      await tester.pump();
      expect(fila.item.situacao, SituacaoDoEnvio.recusado);

      await _passar(tester, fila, const Duration(hours: 2));
      expect(fila.envio.recebidos, hasLength(1));

      await fila.controlador.tentarAgora(fila.item.id);
      await tester.pump();
      expect(fila.item.situacao, SituacaoDoEnvio.enviado);
    });

    _testarFila('sessão expirada espera novo login', (tester, fila) async {
      fila.envio.falharCom(const NaoAutorizado());

      await fila.enfileirar();
      await tester.pump();
      await _passar(tester, fila, const Duration(hours: 1));

      expect(fila.item.situacao, SituacaoDoEnvio.aguardandoLogin);
      expect(fila.envio.recebidos, hasLength(1));
    });

    _testarFila('conexão que volta não espera o fim da espera', (
      tester,
      fila,
    ) async {
      fila.envio.falharCom(const FalhaDeConexao());
      await fila.enfileirar();
      await tester.pump();
      expect(fila.item.situacao, SituacaoDoEnvio.aguardandoNovaTentativa);

      fila.ligarRede(false);
      await _assentar(tester);
      fila.ligarRede(true);
      await _assentar(tester);

      expect(fila.item.situacao, SituacaoDoEnvio.enviado);
    });

    _testarFila('prazo vencido sem rede: espera a rede, e envia uma vez só', (
      tester,
      fila,
    ) async {
      fila.envio.falharCom(const FalhaDeConexao());
      await fila.enfileirar();
      await _assentar(tester);
      expect(fila.item.situacao, SituacaoDoEnvio.aguardandoNovaTentativa);

      fila.ligarRede(false);
      await _assentar(tester);
      // Passa bem do prazo, sem rede: nada é tentado.
      await _passar(tester, fila, const Duration(minutes: 5));
      expect(fila.envio.recebidos, hasLength(1));

      fila.ligarRede(true);
      await _assentar(tester);
      expect(fila.envio.recebidos, hasLength(2));
      expect(fila.item.situacao, SituacaoDoEnvio.enviado);

      await _passar(tester, fila, const Duration(hours: 1));
      expect(fila.envio.recebidos, hasLength(2));
    });

    _testarFila('sair da conta interrompe o envio e pausa a fila', (
      tester,
      fila,
    ) async {
      // Achado da revisão de 23/09: sair limpava o token e a fila seguia.
      final sessao = fila.container.read(sessaoAbertaProvider.notifier);
      fila.envio.segurarAteCancelar();
      await fila.enfileirar();
      await _assentar(tester);
      expect(fila.item.situacao, SituacaoDoEnvio.enviando);

      sessao.encerrar();
      await _assentar(tester);
      // Volta para a fila como estava: sem contar tentativa, sem espera.
      expect(fila.item.situacao, SituacaoDoEnvio.naFila);
      expect(fila.item.tentativas, 0);

      // Sem sessão, nada sobe — nem com o tempo, nem com a rede voltando.
      await _passar(tester, fila, const Duration(hours: 1));
      fila.ligarRede(false);
      fila.ligarRede(true);
      await _assentar(tester);
      expect(fila.envio.recebidos, hasLength(1));

      sessao.abrir();
      await _assentar(tester);
      expect(fila.envio.recebidos, hasLength(2));
      expect(fila.item.situacao, SituacaoDoEnvio.enviado);
    });

    _testarFila('um envio por vez, do mais antigo para o mais novo', (
      tester,
      fila,
    ) async {
      final segura = Completer<String>();
      fila.envio.comportamentos.add(() => segura.future);

      final primeiro = await fila.enfileirar(sessaoId: 's1');
      final segundo = await fila.enfileirar(sessaoId: 's2');
      await tester.pump();

      expect(fila.envio.recebidos, [primeiro.id]);
      expect(fila.itens.map((i) => i.situacao), [
        SituacaoDoEnvio.enviando,
        SituacaoDoEnvio.naFila,
      ]);

      segura.complete('analise-x');
      await tester.pump();

      expect(fila.envio.recebidos, [primeiro.id, segundo.id]);
      expect(
        fila.itens.every((i) => i.situacao == SituacaoDoEnvio.enviado),
        isTrue,
      );
    });

    _testarFila('a mesma sessão não entra duas vezes', (tester, fila) async {
      final primeiro = await fila.enfileirar(sessaoId: 's1');
      final repetido = await fila.enfileirar(sessaoId: 's1');
      await tester.pump();

      expect(repetido.id, primeiro.id);
      expect(fila.itens, hasLength(1));
      expect(fila.envio.recebidos, [primeiro.id]);
    });

    _testarFila('sessões diferentes têm chaves diferentes, mesmo no mesmo '
        'instante', (tester, fila) async {
      final a = await fila.enfileirar(sessaoId: 's1');
      final b = await fila.enfileirar(sessaoId: 's2');

      expect(a.id, isNot(b.id));
    });

    _testarFila('erro fora do contrato não deixa o item preso em enviando', (
      tester,
      fila,
    ) async {
      fila.envio.comportamentos.add(() => Future.error(StateError('bug')));

      await fila.enfileirar();
      await tester.pump();

      expect(fila.item.situacao, SituacaoDoEnvio.aguardandoNovaTentativa);
    });
  });

  test('offline com prazo vencido não gira temporizador sem pausa', () async {
    // Reprodução da revisão de 23/09: com o prazo vencido e sem rede, a fila
    // se reagendava centenas de vezes em poucos milissegundos.
    final agora = DateTime(2026, 9, 23);
    final repositorio = RepositorioFilaEmMemoria();
    await repositorio.adicionar(
      ItemDaFila(
        id: 'envio-s',
        pacienteId: 'p1',
        nomeDoPaciente: 'Ana de Teste',
        sessaoId: 's',
        amostras: [_amostra],
        criadoEm: agora,
        situacao: SituacaoDoEnvio.aguardandoNovaTentativa,
        proximaTentativa: agora.subtract(const Duration(seconds: 1)),
      ),
    );
    var leiturasDoRelogio = 0;
    final container = ProviderContainer(
      overrides: [
        conexaoOnlineProvider.overrideWithValue(false),
        sessaoAbertaProvider.overrideWith(() => Sessao(true)),
        repositorioFilaProvider.overrideWithValue(repositorio),
        relogioProvider.overrideWithValue(() {
          leiturasDoRelogio++;
          return agora;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(filaControladorProvider, (_, _) {});
    await container.read(filaControladorProvider.future);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(leiturasDoRelogio, lessThan(5));
  });

  test('envio com cancelamento já pedido não chega à rede', () async {
    final cancelamento = Cancelamento()..pedir();
    await expectLater(
      EnvioDeAnaliseApi(Dio()).enviar(
        ItemDaFila(
          id: 'envio-s',
          pacienteId: 'p1',
          nomeDoPaciente: 'Ana de Teste',
          sessaoId: 's',
          amostras: [_amostra],
          criadoEm: DateTime(2026, 9, 23),
        ),
        cancelamento: cancelamento,
      ),
      throwsA(isA<EnvioCancelado>()),
    );
  });
}
