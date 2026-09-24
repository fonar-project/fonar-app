import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/design_system/widgets/app_botao.dart';
import 'package:fonar_app/features/captura/data/fonte_de_nivel_record.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';
import 'package:fonar_app/features/captura/data/repositorio_amostras_placeholder.dart';
import 'package:fonar_app/features/captura/domain/afericao_de_ruido.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/fonte_de_nivel.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/captura/presentation/pages/captura_page.dart';
import 'package:fonar_app/features/fila/data/envio_de_analise_api.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_em_memoria.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_placeholder.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import 'wav_de_teste.dart';

/// Sala silenciosa: a aferição sempre libera.
class _SalaQuieta implements FonteDeNivel {
  @override
  AjusteDeConfiguracao? get ajuste => null;
  @override
  Future<bool> pedirPermissao() async => true;
  @override
  Future<Stream<double>> abrir(Duration intervalo) async =>
      Stream.periodic(intervalo, (i) => -65.0 + (i % 5));
  @override
  Future<void> fechar() async {}
}

/// Disco de mentira.
class _Arquivos implements ArquivosDeAmostra {
  final conteudo = <String, Uint8List>{};
  var _n = 0;

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao t) async =>
      '/amostras/$pacienteId/${t.name}-${_n++}.wav';

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async {
    final bytes = conteudo[caminho];
    if (bytes == null) return null;
    return (inicio: bytes, tamanho: bytes.length);
  }

  /// Arquivos que o disco se recusa a apagar — em uso, por exemplo.
  final presos = <String>{};

  @override
  Future<void> apagar(String caminho) async {
    if (presos.contains(caminho)) throw StateError('arquivo em uso');
    conteudo.remove(caminho);
  }
}

/// Microfone e gravador de mentira: emite [niveis] em ciclo e, ao parar,
/// escreve no [_Arquivos] o WAV que [arquivo] montar para a duração gravada.
class _Gravador implements Gravador {
  _Gravador(this.disco);

  final _Arquivos disco;
  List<double> niveis = const [-22, -18, -20, -16, -21];
  Uint8List Function(Duration duracao) arquivo = (d) => wavDeTeste(duracao: d);

  String? _caminho;
  var _emitidas = 0;
  var descartes = 0;

  @override
  Future<bool> pedirPermissao() async => true;

  @override
  Future<Stream<double>> iniciar(String caminho, Duration intervalo) async {
    _caminho = caminho;
    _emitidas = 0;
    return Stream.periodic(intervalo, (i) {
      _emitidas++;
      return niveis[i % niveis.length];
    });
  }

  @override
  Future<void> parar() async {
    disco.conteudo[_caminho!] = arquivo(AfericaoDeRuido.intervalo * _emitidas);
    _caminho = null;
  }

  @override
  Future<void> descartar() async => descartes++;
}

/// Registro de mentira: guarda tudo o que recebeu, na ordem.
class _Repositorio implements RepositorioAmostras {
  final guardadas = <Amostra>[];

  @override
  Future<List<Amostra>> daSessao(String sessaoId) async => [
    for (final a in guardadas)
      if (a.sessaoId == sessaoId) a,
  ];

  @override
  Future<void> guardar(Amostra amostra) async => guardadas.add(amostra);
}

/// Envio que nunca responde: o item fica em "enviando", e o teste olha só
/// o que a tela de gravação fez.
class _EnvioQueSegura implements EnvioDeAnalise {
  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) =>
      Completer<String>().future;
}

class _Cenario {
  _Cenario(this.disco, this.gravador, this.repositorio, this.fila);

  final _Arquivos disco;
  final _Gravador gravador;
  final _Repositorio repositorio;
  final RepositorioFilaEmMemoria fila;
}

Future<_Cenario> _abrir(
  WidgetTester tester, {
  Size tamanho = const Size(390, 844),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final disco = _Arquivos();
  final gravador = _Gravador(disco);
  final repositorio = _Repositorio();
  final fila = RepositorioFilaEmMemoria();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fonteDeNivelProvider.overrideWithValue(_SalaQuieta()),
        gravadorProvider.overrideWithValue(gravador),
        arquivosDeAmostraProvider.overrideWithValue(disco),
        repositorioAmostrasProvider.overrideWithValue(repositorio),
        conexaoOnlineProvider.overrideWithValue(true),
        repositorioFilaProvider.overrideWithValue(fila),
        envioDeAnaliseProvider.overrideWithValue(_EnvioQueSegura()),
        // Profissional com a sessão aberta: sem ela a fila não envia.
        sessaoAbertaProvider.overrideWith(() => Sessao(true)),
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
      ],
      child: MaterialApp.router(
        theme: AppTheme.claro,
        routerConfig: GoRouter(
          initialLocation: '/captura',
          routes: [
            GoRoute(
              path: '/captura',
              builder: (_, _) => const CapturaPage(pacienteId: 'p1'),
            ),
            GoRoute(
              name: AppRoutes.filaNome,
              path: AppRoutes.filaCaminho,
              builder: (_, _) => const Scaffold(body: Text('tela da fila')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Aferição que libera a gravação.
  await tester.ensureVisible(find.text(AppStrings.afericaoMedir));
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.afericaoMedir));
  await tester.pump();
  await tester.pump(
    AfericaoDeRuido.duracao + const Duration(milliseconds: 200),
  );
  await tester.pumpAndSettle();
  return _Cenario(disco, gravador, repositorio, fila);
}

/// Toca em [alvo]. Durante a gravação o medidor redesenha a cada leitura e
/// a tela nunca "assenta" — é o comportamento certo —, então ali se usa
/// `pump` simples no lugar de `pumpAndSettle`.
Future<void> _tocar(
  WidgetTester tester,
  Finder alvo, {
  bool gravando = false,
}) async {
  await tester.ensureVisible(alvo);
  if (gravando) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
  await tester.tap(alvo);
  await tester.pump();
}

/// Grava a primeira tarefa com botão "Gravar"/"Gravar de novo" disponível
/// por [duracao].
Future<void> _gravar(
  WidgetTester tester, {
  Duration duracao = const Duration(seconds: 3),
  String rotulo = AppStrings.tarefaGravar,
}) async {
  await _tocar(tester, find.text(rotulo).first);
  // Uma leitura a mais por causa do primeiro intervalo.
  await tester.pump(duracao + const Duration(milliseconds: 50));
  await _tocar(tester, find.text(AppStrings.tarefaParar), gravando: true);
  await tester.pumpAndSettle();
}

AppBotao _botao(WidgetTester tester, String rotulo) => tester.widget<AppBotao>(
  find.ancestor(of: find.text(rotulo), matching: find.byType(AppBotao)).first,
);

void main() {
  testWidgets('aferição liberada mostra as tarefas; só a próxima em destaque', (
    tester,
  ) async {
    await _abrir(tester);

    expect(find.text(AppStrings.tarefaVogalTitulo), findsOneWidget);
    expect(find.text(AppStrings.tarefaFalaTitulo), findsOneWidget);
    final gravar = tester.widgetList<AppBotao>(
      find.ancestor(
        of: find.text(AppStrings.tarefaGravar),
        matching: find.byType(AppBotao),
      ),
    );
    // Um primário por tela: o da primeira tarefa.
    expect(gravar.map((b) => b.variante), [
      VarianteBotao.primario,
      VarianteBotao.secundario,
    ]);
  });

  testWidgets('gravação boa: conferida, guardada e com a duração do arquivo', (
    tester,
  ) async {
    final c = await _abrir(tester);

    await _gravar(tester);

    expect(find.text(AppStrings.tarefaGravada('3,0 s')), findsOneWidget);
    final amostra = c.repositorio.guardadas.single;
    expect(amostra.pacienteId, 'p1');
    expect(amostra.tarefa, TarefaDeGravacao.vogalSustentada);
    // O formato guardado é o LIDO do arquivo, não o pedido.
    expect(amostra.duracao, const Duration(seconds: 3));
    expect(amostra.taxaDeAmostragem, 44100);
    expect(amostra.canais, 1);
    expect(amostra.problemas, isEmpty);
    expect(c.disco.conteudo.keys, [amostra.caminho]);
  });

  testWidgets('durante a gravação: medidor de voz, e o resto espera', (
    tester,
  ) async {
    await _abrir(tester);

    await _tocar(tester, find.text(AppStrings.tarefaGravar).first);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.tarefaGravando('0,2 s')), findsOneWidget);
    expect(find.text(AppStrings.medidorAdequado), findsOneWidget);
    expect(_botao(tester, AppStrings.tarefaGravar).aoTocar, isNull);
    expect(_botao(tester, AppStrings.afericaoMedirDeNovo).aoTocar, isNull);

    await _tocar(tester, find.text(AppStrings.tarefaParar), gravando: true);
    await tester.pumpAndSettle();
  });

  testWidgets('microfone mudo na gravação: descarta e diz o que fazer', (
    tester,
  ) async {
    final c = await _abrir(tester);
    c.gravador.niveis = [double.negativeInfinity];

    await _gravar(tester);

    expect(find.text(AppStrings.tarefaDescartada), findsOneWidget);
    expect(find.text(AppStrings.problemaSemSinal), findsOneWidget);
    // O arquivo mudo não fica no disco.
    expect(c.disco.conteudo, isEmpty);
  });

  testWidgets('regravação ruim NÃO apaga a gravação boa anterior', (
    tester,
  ) async {
    final c = await _abrir(tester);
    await _gravar(tester);
    final boa = c.disco.conteudo.keys.single;

    c.gravador.niveis = [double.negativeInfinity];
    await _gravar(tester, rotulo: AppStrings.tarefaGravarDeNovo);

    expect(find.text(AppStrings.tarefaGravada('3,0 s')), findsOneWidget);
    expect(find.text(AppStrings.tarefaDescartada), findsOneWidget);
    expect(
      find.text(
        '${AppStrings.problemaSemSinal} ${AppStrings.tarefaDescartadaMantida}',
      ),
      findsOneWidget,
    );
    expect(c.disco.conteudo.keys, [boa]);
  });

  testWidgets('regravação boa substitui e apaga o arquivo anterior', (
    tester,
  ) async {
    final c = await _abrir(tester);
    await _gravar(tester);
    final primeira = c.disco.conteudo.keys.single;

    await _gravar(
      tester,
      rotulo: AppStrings.tarefaGravarDeNovo,
      duracao: const Duration(seconds: 4),
    );

    expect(find.text(AppStrings.tarefaGravada('4,0 s')), findsOneWidget);
    expect(c.disco.conteudo.keys, isNot(contains(primeira)));
    expect(c.disco.conteudo, hasLength(1));
  });

  testWidgets('regravação boa fica, mesmo se o arquivo anterior não sair', (
    tester,
  ) async {
    // Revisão de 24/09: a falha ao apagar o arquivo antigo caía no mesmo
    // tratamento de erro da gravação e apagava o NOVO, já registrado.
    final c = await _abrir(tester);
    await _gravar(tester);
    final primeira = c.disco.conteudo.keys.single;
    c.disco.presos.add(primeira);

    await _gravar(
      tester,
      rotulo: AppStrings.tarefaGravarDeNovo,
      duracao: const Duration(seconds: 4),
    );

    final nova = c.repositorio.guardadas.last;
    expect(nova.caminho, isNot(primeira));
    expect(c.disco.conteudo.keys, contains(nova.caminho));
    expect(find.text(AppStrings.tarefaGravada('4,0 s')), findsOneWidget);
    expect(find.text(AppStrings.tarefaFalhaFinalizar), findsNothing);
  });

  testWidgets('arquivo que não é PCM é recusado, mesmo com som', (
    tester,
  ) async {
    final c = await _abrir(tester);
    c.gravador.arquivo = (d) => wavDeTeste(duracao: d, formato: 85);

    await _gravar(tester);

    expect(find.text(AppStrings.tarefaDescartada), findsOneWidget);
    expect(find.text(AppStrings.problemaNaoEPcm), findsOneWidget);
  });

  testWidgets('toque acidental em parar: curta demais, descartada', (
    tester,
  ) async {
    await _abrir(tester);

    await _gravar(tester, duracao: const Duration(milliseconds: 400));

    expect(find.text(AppStrings.problemaCurtaDemais), findsOneWidget);
  });

  testWidgets('saturação: guardada com ressalva, e diz por quê', (
    tester,
  ) async {
    final c = await _abrir(tester);
    c.gravador.niveis = [-22, -18, -0.1, -20, -16];

    await _gravar(tester);

    expect(
      find.text(AppStrings.tarefaGravadaComRessalva('3,0 s')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.problemaSaturou), findsOneWidget);
    expect(c.disco.conteudo, hasLength(1));
  });

  testWidgets('todas gravadas: enviar põe a sessão na fila e abre a fila', (
    tester,
  ) async {
    final c = await _abrir(tester);
    expect(find.text(AppStrings.capturaEnviarFaltaTarefa), findsOneWidget);
    expect(_botao(tester, AppStrings.capturaEnviar).aoTocar, isNull);

    await _gravar(tester);
    await _gravar(tester);

    expect(
      _botao(tester, AppStrings.capturaEnviar).variante,
      VarianteBotao.primario,
    );
    expect(find.text(AppStrings.capturaEnviarApoio), findsOneWidget);

    await _tocar(tester, find.text(AppStrings.capturaEnviar));
    await tester.pumpAndSettle();

    expect(find.text('tela da fila'), findsOneWidget);
    final itens = await c.fila.listar();
    expect(itens, hasLength(1));
    expect(itens.single.pacienteId, 'p1');
    expect(itens.single.nomeDoPaciente, 'Ana de Teste');
    expect(itens.single.amostras.map((a) => a.tarefa), TarefaDeGravacao.values);
  });

  testWidgets('não estoura com o texto do sistema em 200%', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await _abrir(tester);
    c.gravador.niveis = [double.negativeInfinity];

    await _gravar(tester);

    expect(tester.takeException(), isNull);
  });
}
