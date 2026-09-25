import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/analise/data/repositorio_analises_placeholder.dart';
import 'package:fonar_app/features/analise/domain/resultado_da_analise.dart';
import 'package:fonar_app/features/cape_v/data/repositorio_cape_v_local.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/cape_v/presentation/pages/cape_v_page.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/domain/repositorio_consentimento.dart';
import 'package:fonar_app/features/consentimento/presentation/pages/consentimento_page.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/laudo/data/repositorio_laudos_local.dart';
import 'package:fonar_app/features/laudo/data/saida_do_laudo.dart';
import 'package:fonar_app/features/laudo/domain/conteudo_do_laudo.dart';
import 'package:fonar_app/features/laudo/domain/laudo.dart';
import 'package:fonar_app/features/laudo/presentation/laudo_controlador.dart';
import 'package:fonar_app/features/laudo/presentation/pages/laudo_page.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/repositorios_em_memoria.dart';

class _Analises implements RepositorioAnalises {
  _Analises({this.falha = false, this.dono = 'p1'});
  final bool falha;

  /// O paciente a quem a análise pertence.
  final String dono;

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async {
    if (falha) throw const FalhaDeConexao();
    return ResultadoDaAnalise(
      id: analiseId,
      pacienteId: dono,
      situacao: SituacaoDaAnalise.concluida,
      realizadaEm: DateTime(2026, 7, 2, 9, 30),
      medidas: const [
        MedidaCalculada(medida: MedidaAcustica.avqi, valor: 3.12),
      ],
      qualidade: const {
        TarefaDeGravacao.vogalSustentada: QualidadeDaAmostra(adequada: true),
      },
    );
  }

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async => [];
}

class _Consentimentos implements RepositorioConsentimento {
  _Consentimentos({required this.tem});
  final bool tem;

  @override
  Future<Consentimento?> buscar(String pacienteId) async => tem
      ? Consentimento(
          pacienteId: pacienteId,
          registradoEm: DateTime(2026, 7, 1),
          versaoDoTermo: 'teste',
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

class _Saida implements SaidaDoLaudo {
  _Saida({this.falha = false});
  final bool falha;
  final chamadas = <(String, Uint8List, String)>[];

  @override
  Future<void> compartilhar(Uint8List pdf, {required String nomeDoArquivo}) =>
      _registrar('compartilhar', pdf, nomeDoArquivo);

  @override
  Future<void> imprimir(Uint8List pdf, {required String nomeDoArquivo}) =>
      _registrar('imprimir', pdf, nomeDoArquivo);

  Future<void> _registrar(String o, Uint8List pdf, String nome) async {
    if (falha) throw Exception('sem visualizador');
    chamadas.add((o, pdf, nome));
  }
}

/// Registra cada conteúdo mandado para o PDF e devolve bytes marcados com a
/// conclusão — o PDF de verdade tem teste próprio.
class _Gerador {
  _Gerador({this.falha = false});
  final bool falha;
  final conteudos = <ConteudoDoLaudo>[];

  Future<Uint8List> call(ConteudoDoLaudo c) async {
    if (falha) throw Exception('falhou');
    conteudos.add(c);
    return Uint8List.fromList(utf8.encode('%PDF-teste ${c.conclusao}'));
  }
}

/// As funções de geração que a prévia recebeu. Cada função nova é uma
/// rasterização nova do A4 — reconstruir a tela com a mesma função não conta.
class _Previas {
  final funcoes = <Object>{};
}

const _paciente = Paciente(
  id: 'p1',
  nome: 'Ana de Teste',
  queixa: 'rouquidão',
  direcaoAvqi: DirecaoDaMedida.semComparacao,
);

class _Montagem {
  _Montagem(this.roteador, this.saida, this.gerador, this.previas, this.laudos);
  final GoRouter roteador;
  final _Saida saida;
  final _Gerador gerador;
  final _Previas previas;
  final RepositorioLaudosEmMemoria laudos;
}

Future<_Montagem> _abrir(
  WidgetTester tester, {
  bool consentimento = true,
  AvaliacaoCapeV? capeV,
  Laudo? laudoExistente,
  bool falhaAoCarregar = false,
  String donoDaAnalise = 'p1',
  bool semCadastro = false,
  _Saida? saida,
  _Gerador? gerador,
  Size tamanho = const Size(390, 2000),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final capes = RepositorioCapeVEmMemoria();
  if (capeV != null) await capes.registrar(capeV);
  final laudos = RepositorioLaudosEmMemoria();
  if (laudoExistente != null) await laudos.registrar(laudoExistente);
  final s = saida ?? _Saida();
  final g = gerador ?? _Gerador();
  final previas = _Previas();

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      conexaoOnlineProvider.overrideWithValue(true),
      relogioProvider.overrideWithValue(() => DateTime(2026, 7, 2, 11, 5)),
      repositorioAnalisesProvider.overrideWithValue(
        _Analises(falha: falhaAoCarregar, dono: donoDaAnalise),
      ),
      repositorioConsentimentoProvider.overrideWithValue(
        _Consentimentos(tem: consentimento),
      ),
      repositorioCapeVProvider.overrideWithValue(capes),
      repositorioLaudosProvider.overrideWithValue(laudos),
      pacientesProvider.overrideWith(
        (ref) async => semCadastro ? const <Paciente>[] : [_paciente],
      ),
      saidaDoLaudoProvider.overrideWithValue(s),
      geradorDePdfProvider.overrideWithValue(g.call),
      previaDoPdfProvider.overrideWithValue((gerar) {
        previas.funcoes.add(gerar);
        return const Center(child: Text('prévia A4'));
      }),
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
    AppRoutes.laudoNome,
    pathParameters: {
      AppRoutes.paramPacienteId: 'p1',
      AppRoutes.paramAnaliseId: 'an-1',
    },
  );
  await tester.pumpAndSettle();
  return _Montagem(roteador, s, g, previas, laudos);
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _escrever(WidgetTester tester, String texto) async {
  final campo = find.byType(TextField);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pumpAndSettle();
}

final _capeV = AvaliacaoCapeV(
  analiseId: 'an-1',
  pacienteId: 'p1',
  registradaEm: DateTime(2026, 7, 2, 10),
  notas: {for (final p in ParametroCapeV.values) p: const NotaCapeV(valor: 0)},
);

bool _habilitado(WidgetTester tester, String rotulo) {
  final botao = find.ancestor(
    of: find.text(rotulo),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(botao.first).onPressed != null;
}

void main() {
  testWidgets('sem conclusão, não gera — e a conferência diz o porquê', (
    tester,
  ) async {
    await _abrir(tester, capeV: _capeV);

    expect(find.byType(LaudoPage), findsOneWidget);
    expect(find.text(AppStrings.laudoItemConclusaoFalta), findsOneWidget);
    expect(find.text(AppStrings.laudoConferenciaPendente), findsOneWidget);
    expect(_habilitado(tester, AppStrings.laudoGerar), isFalse);
    expect(find.text(AppStrings.laudoGerarBloqueado), findsOneWidget);
  });

  testWidgets('escrever a conclusão libera; gerar registra e oferece o PDF', (
    tester,
  ) async {
    final m = await _abrir(tester, capeV: _capeV);

    await _escrever(tester, '  Conclusão de teste.  ');
    expect(_habilitado(tester, AppStrings.laudoGerar), isTrue);

    await _tocar(tester, find.text(AppStrings.laudoGerar));

    expect(
      find.text(AppStrings.laudoGeradoEm('02 jul 2026', '11:05')),
      findsOneWidget,
    );
    final gerado = m.gerador.conteudos.last;
    expect(gerado.conclusao, 'Conclusão de teste.');
    expect(gerado.geradoEm, DateTime(2026, 7, 2, 11, 5));
    expect(gerado.capeV, isNotNull);
    expect(
      (await m.laudos.daAnalise('an-1'))?.conclusao,
      'Conclusão de teste.',
    );

    await _tocar(tester, find.text(AppStrings.laudoCompartilhar));
    await _tocar(tester, find.text(AppStrings.laudoImprimir));
    expect(m.saida.chamadas.map((c) => c.$1), ['compartilhar', 'imprimir']);
    // O arquivo que sai é o que foi gerado — e o nome não leva o paciente.
    expect(
      utf8.decode(m.saida.chamadas.first.$2),
      '%PDF-teste Conclusão de teste.',
    );
    expect(m.saida.chamadas.first.$3, 'laudo-fonar-2026-07-02.pdf');
  });

  testWidgets('mudar a conclusão depois de gerar avisa para gerar de novo', (
    tester,
  ) async {
    await _abrir(tester, capeV: _capeV);
    await _escrever(tester, 'Primeira versão.');
    await _tocar(tester, find.text(AppStrings.laudoGerar));
    expect(find.text(AppStrings.laudoTextoMudou), findsNothing);

    await _escrever(tester, 'Segunda versão.');

    expect(find.text(AppStrings.laudoTextoMudou), findsOneWidget);
  });

  // Achado 5.2 da revisão de 24/09: gerar de novo sobrescrevia o PDF anterior
  // sem perguntar nada. O laudo tem UMA versão só (ver `PENDENCIAS.md`), então
  // substituir é destrutivo — e usa o mesmo diálogo do resto do aplicativo.
  group('gerar de novo substitui o anterior', () {
    testWidgets('a primeira geração não pergunta nada', (tester) async {
      final m = await _abrir(tester, capeV: _capeV);
      await _escrever(tester, 'Primeira versão.');

      await _tocar(tester, find.text(AppStrings.laudoGerar));

      expect(find.text(AppStrings.laudoSubstituirTitulo), findsNothing);
      expect(m.gerador.conteudos, hasLength(1));
    });

    testWidgets('a segunda pergunta, e "Manter o atual" não substitui', (
      tester,
    ) async {
      final m = await _abrir(tester, capeV: _capeV);
      await _escrever(tester, 'Primeira versão.');
      await _tocar(tester, find.text(AppStrings.laudoGerar));
      await _escrever(tester, 'Segunda versão.');

      await _tocar(tester, find.text(AppStrings.laudoGerar));
      expect(find.text(AppStrings.laudoSubstituirTitulo), findsOneWidget);
      expect(find.text(AppStrings.laudoSubstituirTexto), findsOneWidget);

      await _tocar(tester, find.text(AppStrings.laudoManterOAtual));

      expect(m.gerador.conteudos, hasLength(1));
      expect((await m.laudos.daAnalise('an-1'))?.conclusao, 'Primeira versão.');
      // O aviso continua: a conclusão na tela ainda não está no PDF.
      expect(find.text(AppStrings.laudoTextoMudou), findsOneWidget);
    });

    testWidgets('Esc também mantém o laudo atual', (tester) async {
      final m = await _abrir(tester, capeV: _capeV);
      await _escrever(tester, 'Primeira versão.');
      await _tocar(tester, find.text(AppStrings.laudoGerar));
      await _escrever(tester, 'Segunda versão.');

      await _tocar(tester, find.text(AppStrings.laudoGerar));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.laudoSubstituirTitulo), findsNothing);
      expect(m.gerador.conteudos, hasLength(1));
    });

    testWidgets('confirmado, o PDF novo toma o lugar do anterior', (
      tester,
    ) async {
      final m = await _abrir(tester, capeV: _capeV);
      await _escrever(tester, 'Primeira versão.');
      await _tocar(tester, find.text(AppStrings.laudoGerar));
      await _escrever(tester, 'Segunda versão.');

      await _tocar(tester, find.text(AppStrings.laudoGerar));
      await _tocar(tester, find.text(AppStrings.laudoSubstituir));

      expect(m.gerador.conteudos, hasLength(2));
      expect(m.gerador.conteudos.last.conclusao, 'Segunda versão.');
      expect((await m.laudos.daAnalise('an-1'))?.conclusao, 'Segunda versão.');
      expect(find.text(AppStrings.laudoTextoMudou), findsNothing);
    });
  });

  testWidgets('laudo já gerado volta com a conclusão e as ações', (
    tester,
  ) async {
    await _abrir(
      tester,
      capeV: _capeV,
      laudoExistente: Laudo(
        analiseId: 'an-1',
        pacienteId: 'p1',
        conclusao: 'Texto salvo.',
        geradoEm: DateTime(2026, 7, 2, 10, 40),
        pdf: Uint8List.fromList(utf8.encode('%PDF-salvo')),
      ),
    );

    expect(find.text('Texto salvo.'), findsWidgets);
    expect(find.text(AppStrings.laudoCompartilhar), findsOneWidget);
  });

  testWidgets('sem consentimento: pendente, com o caminho para registrar', (
    tester,
  ) async {
    await _abrir(tester, consentimento: false, capeV: _capeV);
    await _escrever(tester, 'Conclusão.');

    expect(find.text(AppStrings.laudoItemConsentimentoFalta), findsOneWidget);
    expect(_habilitado(tester, AppStrings.laudoGerar), isFalse);

    await _tocar(tester, find.text(AppStrings.laudoIrParaConsentimento));
    expect(find.byType(ConsentimentoPage), findsOneWidget);
  });

  testWidgets('sem CAPE-V: avisa, deixa gerar e leva à escala', (tester) async {
    await _abrir(tester);
    await _escrever(tester, 'Conclusão.');

    expect(find.text(AppStrings.laudoItemCapeVAviso), findsOneWidget);
    expect(find.text(AppStrings.laudoConferenciaAviso), findsOneWidget);
    expect(_habilitado(tester, AppStrings.laudoGerar), isTrue);

    await _tocar(tester, find.text(AppStrings.laudoIrParaCapeV));
    expect(find.byType(CapeVPage), findsOneWidget);
  });

  testWidgets('falha ao gerar é dita, e nada é registrado', (tester) async {
    final m = await _abrir(
      tester,
      capeV: _capeV,
      gerador: _Gerador(falha: true),
    );
    await _escrever(tester, 'Conclusão.');

    await _tocar(tester, find.text(AppStrings.laudoGerar));

    expect(find.text(AppStrings.laudoErroGerar), findsOneWidget);
    expect(await m.laudos.daAnalise('an-1'), isNull);
    expect(find.text(AppStrings.laudoCompartilhar), findsNothing);
  });

  testWidgets('falha ao abrir o PDF é dita', (tester) async {
    await _abrir(tester, capeV: _capeV, saida: _Saida(falha: true));
    await _escrever(tester, 'Conclusão.');
    await _tocar(tester, find.text(AppStrings.laudoGerar));

    await _tocar(tester, find.text(AppStrings.laudoCompartilhar));

    expect(find.text(AppStrings.laudoErroSaida), findsOneWidget);
  });

  group('identidade do paciente', () {
    // Achados da revisão de 23/09: o botão Gerar ficava habilitado com o
    // cadastro ausente (laudo sem nome) e com a análise de outro paciente.
    testWidgets('sem cadastro: não há laudo a gerar', (tester) async {
      await _abrir(tester, capeV: _capeV, semCadastro: true);

      expect(find.text(AppStrings.laudoSemPaciente), findsOneWidget);
      expect(find.text(AppStrings.laudoGerar), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('análise de outro paciente: nada do laudo aparece', (
      tester,
    ) async {
      await _abrir(tester, capeV: _capeV, donoDaAnalise: 'outro-paciente');

      expect(find.text(AppStrings.resultadoDeOutroPaciente), findsOneWidget);
      expect(find.text(AppStrings.laudoGerar), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  testWidgets('falha ao carregar deixa tentar de novo', (tester) async {
    await _abrir(tester, falhaAoCarregar: true);

    expect(find.text(AppStrings.laudoErroCarregar), findsOneWidget);
    expect(find.text(AppStrings.tentarNovamente), findsOneWidget);
  });

  group('por largura', () {
    testWidgets('celular: resumo no lugar da prévia A4', (tester) async {
      final m = await _abrir(tester, capeV: _capeV);

      expect(find.text(AppStrings.laudoResumoTitulo), findsOneWidget);
      expect(find.text('prévia A4'), findsNothing);
      expect(m.previas.funcoes, isEmpty);
    });

    testWidgets('desktop: prévia A4, refeita só depois do respiro', (
      tester,
    ) async {
      final m = await _abrir(
        tester,
        capeV: _capeV,
        tamanho: const Size(1440, 1200),
      );
      expect(find.text('prévia A4'), findsOneWidget);
      expect(find.text(AppStrings.laudoResumoTitulo), findsNothing);
      expect(m.previas.funcoes, hasLength(1));

      // Digitando: a prévia fica como estava — nada de remontar o A4 a cada
      // tecla.
      await tester.enterText(find.byType(TextField), 'Conclus');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'Conclusão');
      await tester.pump(const Duration(milliseconds: 100));
      expect(m.previas.funcoes, hasLength(1));

      // Parou de digitar: uma prévia nova, com o texto novo.
      await tester.pump(const Duration(milliseconds: 700));
      expect(m.previas.funcoes, hasLength(2));
      final gerar = m.previas.funcoes.last as Future<Uint8List> Function();
      await tester.runAsync(gerar);
      expect(m.gerador.conteudos.last.conclusao, 'Conclusão');
      expect(m.gerador.conteudos.last.rascunho, isTrue);
    });

    for (final (nome, tamanho) in [
      ('390', const Size(390, 844)),
      ('1440', const Size(1440, 900)),
      ('1024', const Size(1024, 768)),
    ]) {
      for (final escala in [1.0, 2.0]) {
        testWidgets('$nome, texto ${escala}x: sem estouro', (tester) async {
          await _abrir(tester, tamanho: tamanho, escala: escala);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('o resultado leva ao laudo', (tester) async {
    final m = await _abrir(tester, capeV: _capeV);
    m.roteador.goNamed(
      AppRoutes.analiseResultadoNome,
      pathParameters: {
        AppRoutes.paramPacienteId: 'p1',
        AppRoutes.paramAnaliseId: 'an-1',
      },
    );
    await tester.pumpAndSettle();

    await _tocar(tester, find.text(AppStrings.resultadoPrepararLaudo));

    expect(find.byType(LaudoPage), findsOneWidget);
  });
}
