import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:fonar_app/features/captura/data/repositorio_amostras_local.dart';
import 'package:fonar_app/features/captura/domain/afericao_de_ruido.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/fonte_de_nivel.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/captura/presentation/pages/captura_page.dart';
import 'package:fonar_app/features/fila/data/envio_de_analise_api.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import 'wav_de_teste.dart';

import '../../apoio/repositorios_em_memoria.dart';

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
  var inicios = 0;

  @override
  Future<bool> pedirPermissao() async => true;

  @override
  Future<Stream<double>> iniciar(String caminho, Duration intervalo) async {
    inicios++;
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

  /// Nenhuma sessão anterior: estes testes começam sempre do zero.
  @override
  Future<List<Amostra>> ultimaSessao(String pacienteId) async => const [];

  @override
  Future<List<Amostra>> doPaciente(String pacienteId) async => const [];

  @override
  Future<void> descartarSessao(String sessaoId) async {}

  @override
  Future<bool> estaNumEnvio(String sessaoId) async => false;
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

  // Aferição que libera a gravação, e "Continuar" até a primeira tarefa.
  await tester.ensureVisible(find.text(AppStrings.afericaoMedir));
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.afericaoMedir));
  await tester.pump();
  await tester.pump(
    AfericaoDeRuido.duracao + const Duration(milliseconds: 200),
  );
  await tester.pumpAndSettle();
  await _tocar(tester, find.text(AppStrings.capturaContinuar));
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

/// Grava a tarefa da etapa atual por [duracao]: "Iniciar gravação" na
/// primeira vez, "Regravar" depois.
Future<void> _gravar(
  WidgetTester tester, {
  Duration duracao = const Duration(seconds: 3),
  String rotulo = AppStrings.capturaIniciarGravacao,
}) async {
  await _tocar(tester, find.text(rotulo));
  // Uma leitura a mais por causa do primeiro intervalo.
  await tester.pump(duracao + const Duration(milliseconds: 50));
  await _tocar(tester, find.text(AppStrings.tarefaParar), gravando: true);
  await tester.pumpAndSettle();
}

/// Segue para a próxima etapa, ou para a revisão depois da última.
Future<void> _seguir(WidgetTester tester, {bool ultima = false}) async {
  await _tocar(
    tester,
    find.text(
      ultima
          ? AppStrings.capturaConcluirERevisar
          : AppStrings.capturaProximaEtapa,
    ),
  );
  await tester.pumpAndSettle();
}

AppBotao _botao(WidgetTester tester, String rotulo) => tester.widget<AppBotao>(
  find.ancestor(of: find.text(rotulo), matching: find.byType(AppBotao)).first,
);

/// A etapa, como o leitor de tela a lê: "Vogal /a/, concluída".
Finder _etapa(String nome, String situacao) =>
    find.bySemanticsLabel('$nome, $situacao');

void main() {
  testWidgets('primeira tarefa: instrução grande e um só botão em destaque', (
    tester,
  ) async {
    await _abrir(tester);

    expect(
      find.text(
        AppStrings.etapaDe(2, 3, AppStrings.tarefaVogalTitulo).toUpperCase(),
      ),
      findsOneWidget,
    );
    expect(find.text(AppStrings.instrucaoVogalPronto), findsOneWidget);
    final botoes = tester.widgetList<AppBotao>(find.byType(AppBotao));
    expect(botoes.map((b) => b.rotulo), [AppStrings.capturaIniciarGravacao]);
    expect(botoes.single.variante, VarianteBotao.primario);
  });

  testWidgets('gravação boa: conferida, guardada e com a duração do arquivo', (
    tester,
  ) async {
    final c = await _abrir(tester);

    await _gravar(tester);

    expect(find.text(AppStrings.instrucaoAmostraBoa), findsOneWidget);
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
    // Boa: o próximo passo é seguir, e regravar fica em segundo plano.
    expect(
      _botao(tester, AppStrings.capturaProximaEtapa).variante,
      VarianteBotao.primario,
    );
    expect(
      _botao(tester, AppStrings.capturaRegravar).variante,
      VarianteBotao.secundario,
    );
  });

  testWidgets('durante a gravação: medidor de voz, e não se muda de etapa', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _abrir(tester);

    await _tocar(tester, find.text(AppStrings.capturaIniciarGravacao));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.instrucaoVogalGravando), findsOneWidget);
    expect(
      find.bySemanticsLabel(AppStrings.tarefaGravando('0,2 s')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.medidorAdequado), findsOneWidget);
    // Trocar de etapa deixaria a gravação órfã na tela.
    await tester.tap(find.text(AppStrings.etapaRuidoCurta));
    await tester.pump();
    expect(find.text(AppStrings.instrucaoVogalGravando), findsOneWidget);

    await _tocar(tester, find.text(AppStrings.tarefaParar), gravando: true);
    await tester.pumpAndSettle();
    semantica.dispose();
  });

  testWidgets('microfone mudo na gravação: descarta e diz o que fazer', (
    tester,
  ) async {
    final c = await _abrir(tester);
    c.gravador.niveis = [double.negativeInfinity];

    await _gravar(tester);

    expect(find.text(AppStrings.instrucaoAmostraRecusada), findsOneWidget);
    expect(find.text(AppStrings.tarefaDescartada), findsOneWidget);
    expect(find.text(AppStrings.problemaSemSinal), findsOneWidget);
    // Sem amostra, não se segue: só regravar, em destaque.
    expect(find.text(AppStrings.capturaProximaEtapa), findsNothing);
    expect(
      _botao(tester, AppStrings.capturaRegravar).variante,
      VarianteBotao.primario,
    );
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
    await _gravar(tester, rotulo: AppStrings.capturaRegravar);

    expect(find.text(AppStrings.tarefaGravada('3,0 s')), findsOneWidget);
    expect(find.text(AppStrings.tarefaDescartada), findsOneWidget);
    expect(
      find.text(
        '${AppStrings.problemaSemSinal} ${AppStrings.tarefaDescartadaMantida}',
      ),
      findsOneWidget,
    );
    expect(c.disco.conteudo.keys, [boa]);
    // A anterior vale: dá para seguir, mas regravar vem em destaque.
    expect(
      _botao(tester, AppStrings.capturaRegravar).variante,
      VarianteBotao.primario,
    );
    expect(find.text(AppStrings.capturaProximaEtapa), findsOneWidget);
  });

  testWidgets('regravação boa substitui e apaga o arquivo anterior', (
    tester,
  ) async {
    final c = await _abrir(tester);
    await _gravar(tester);
    final primeira = c.disco.conteudo.keys.single;

    await _gravar(
      tester,
      rotulo: AppStrings.capturaRegravar,
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
      rotulo: AppStrings.capturaRegravar,
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

    expect(find.text(AppStrings.instrucaoAmostraRessalva), findsOneWidget);
    expect(
      find.text(AppStrings.tarefaGravadaComRessalva('3,0 s')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.problemaSaturou), findsOneWidget);
    expect(c.disco.conteudo, hasLength(1));
    // Com ressalva, regravar vem em destaque — mas seguir é permitido.
    expect(
      _botao(tester, AppStrings.capturaRegravar).variante,
      VarianteBotao.primario,
    );
    expect(
      _botao(tester, AppStrings.capturaProximaEtapa).variante,
      VarianteBotao.secundario,
    );
  });

  testWidgets('etapas: a gravada fica concluída, e se volta a ela', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _abrir(tester);
    await _gravar(tester);
    await _seguir(tester);

    expect(
      find.text(
        AppStrings.etapaDe(3, 3, AppStrings.tarefaFalaTitulo).toUpperCase(),
      ),
      findsOneWidget,
    );
    expect(find.text(AppStrings.instrucaoFalaPronto), findsOneWidget);
    expect(
      _etapa(AppStrings.etapaRuidoCurta, AppStrings.etapaConcluida),
      findsOneWidget,
    );
    expect(
      _etapa(AppStrings.tarefaVogalCurta, AppStrings.etapaConcluida),
      findsOneWidget,
    );
    expect(
      _etapa(AppStrings.tarefaFalaCurta, AppStrings.etapaEmAndamento),
      findsOneWidget,
    );

    await _tocar(tester, find.text(AppStrings.tarefaVogalCurta));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tarefaGravada('3,0 s')), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('todas gravadas: revisão, e enviar põe na fila e abre a fila', (
    tester,
  ) async {
    final c = await _abrir(tester);

    await _gravar(tester);
    await _seguir(tester);
    await _gravar(tester);
    await _seguir(tester, ultima: true);

    expect(find.text(AppStrings.revisaoInstrucao), findsOneWidget);
    expect(find.text(AppStrings.tarefaVogalTitulo), findsOneWidget);
    expect(find.text(AppStrings.tarefaFalaTitulo), findsOneWidget);
    expect(find.text(AppStrings.tarefaGravada('3,0 s')), findsNWidgets(2));
    expect(find.text(AppStrings.afericaoSemRestricao), findsOneWidget);
    expect(
      _botao(tester, AppStrings.capturaEnviar).variante,
      VarianteBotao.primario,
    );

    await _tocar(tester, find.text(AppStrings.capturaEnviar));
    await tester.pumpAndSettle();

    expect(find.text('tela da fila'), findsOneWidget);
    final itens = await c.fila.listar();
    expect(itens, hasLength(1));
    expect(itens.single.pacienteId, 'p1');
    expect(itens.single.nomeDoPaciente, 'Ana de Teste');
    expect(itens.single.amostras.map((a) => a.tarefa), TarefaDeGravacao.values);
  });

  testWidgets('revisão com tarefa faltando não envia, e leva de volta a ela', (
    tester,
  ) async {
    final c = await _abrir(tester);
    // Pula a vogal e grava só a fala.
    await _tocar(tester, find.text(AppStrings.tarefaFalaCurta));
    await tester.pumpAndSettle();
    await _gravar(tester);
    await _seguir(tester, ultima: true);

    expect(find.text(AppStrings.capturaEnviarFaltaTarefa), findsWidgets);
    expect(_botao(tester, AppStrings.capturaEnviar).aoTocar, isNull);

    // "Regravar" da vogal, na revisão, volta à etapa dela.
    await _tocar(tester, find.text(AppStrings.capturaRegravar).first);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.instrucaoVogalPronto), findsOneWidget);
    expect(await c.fila.listar(), isEmpty);
  });

  testWidgets('no desktop, Espaço inicia e para; R regrava', (tester) async {
    final c = await _abrir(tester, tamanho: const Size(1440, 900));

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3, milliseconds: 50));
    expect(find.text(AppStrings.instrucaoVogalGravando), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tarefaGravada('3,0 s')), findsOneWidget);

    // Com amostra boa, Espaço não regrava por engano: isso é o R.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.text(AppStrings.instrucaoVogalGravando), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4, milliseconds: 50));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tarefaGravada('4,0 s')), findsOneWidget);
    expect(c.repositorio.guardadas, hasLength(2));
  });

  testWidgets('Espaço num controle focado é do controle, não do atalho', (
    tester,
  ) async {
    final c = await _abrir(tester, tamanho: const Size(1440, 900));

    // Foco (pelo Tab) no passo "Ruído", e Espaço: volta ao ruído, e a
    // gravação da vogal NÃO começa por baixo.
    Focus.of(tester.element(find.text(AppStrings.etapaRuidoCurta)))
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.instrucaoRuidoOk), findsOneWidget);
    expect(c.gravador.inicios, 0);
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(390, 844)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('$nome não estoura com o texto do sistema em 200%', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await _abrir(tester, tamanho: tamanho);
      c.gravador.niveis = [double.negativeInfinity];
      await _gravar(tester);
      expect(tester.takeException(), isNull);

      c.gravador.niveis = [-22, -18, -20];
      await _gravar(tester, rotulo: AppStrings.capturaRegravar);
      await _seguir(tester);
      await _gravar(tester);
      await _seguir(tester, ultima: true);

      expect(find.text(AppStrings.revisaoInstrucao), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
