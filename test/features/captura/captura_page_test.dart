import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/captura/data/fonte_de_nivel_record.dart';
import 'package:fonar_app/features/captura/domain/afericao_de_ruido.dart';
import 'package:fonar_app/features/captura/domain/fonte_de_nivel.dart';
import 'package:fonar_app/features/captura/presentation/pages/captura_page.dart';
import 'package:fonar_app/features/captura/presentation/widgets/medidor_de_nivel.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_placeholder.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/l10n/app_strings.dart';

/// Microfone de mentira: emite [niveis] em ciclo, um por intervalo.
class _FonteFalsa implements FonteDeNivel {
  _FonteFalsa({
    this.niveis = const [-66, -64, -65, -63, -67],
    this.permitido = true,
    this.falhaAoAbrir = false,
    this.ajuste,
  });

  final List<double> niveis;
  final bool permitido;
  final bool falhaAoAbrir;

  @override
  final AjusteDeConfiguracao? ajuste;

  var aberturas = 0;
  var fechamentos = 0;

  @override
  Future<bool> pedirPermissao() async => permitido;

  @override
  Future<Stream<double>> abrir(Duration intervalo) async {
    if (falhaAoAbrir) throw Exception('microfone ocupado');
    aberturas++;
    return Stream.periodic(intervalo, (i) => niveis[i % niveis.length]);
  }

  @override
  Future<void> fechar() async => fechamentos++;
}

const _celular = Size(390, 844);
const _desktop = Size(1440, 900);

Future<_FonteFalsa> _abrir(
  WidgetTester tester, {
  _FonteFalsa? fonte,
  Size tamanho = _celular,
  double escala = 1,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final falsa = fonte ?? _FonteFalsa();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fonteDeNivelProvider.overrideWithValue(falsa),
        conexaoOnlineProvider.overrideWithValue(true),
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
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const CapturaPage(pacienteId: 'p1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return falsa;
}

/// Toca em "Medir" e deixa a aferição inteira passar.
Future<void> _medir(
  WidgetTester tester, {
  String rotulo = AppStrings.afericaoMedir,
}) async {
  final botao = find.text(rotulo);
  await tester.ensureVisible(botao);
  await tester.tap(botao);
  await tester.pump();
  await tester.pump(
    AfericaoDeRuido.duracao + const Duration(milliseconds: 200),
  );
  await tester.pumpAndSettle();
}

/// O motivo escrito embaixo de "Iniciar gravação".
Finder _motivo(String texto) => find.text(texto);

void main() {
  for (final (nome, tamanho) in [
    ('celular', _celular),
    ('desktop', _desktop),
  ]) {
    testWidgets('$nome explica a aferição e não deixa gravar antes dela', (
      tester,
    ) async {
      await _abrir(tester, tamanho: tamanho);

      expect(find.text('Paciente: Ana de Teste'), findsOneWidget);
      expect(find.text(AppStrings.afericaoExplicacao), findsOneWidget);
      expect(_motivo(AppStrings.capturaBloqueadaSemAfericao), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nome não estoura com o texto do sistema em 200%', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamanho: tamanho,
        escala: 2,
        fonte: _FonteFalsa(niveis: [double.negativeInfinity]),
      );
      await _medir(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.afericaoMudo), findsOneWidget);
    });
  }

  testWidgets('durante a medição mostra o medidor ao vivo', (tester) async {
    await _abrir(tester);

    await tester.tap(find.text(AppStrings.afericaoMedir));
    await tester.pump();
    // Leituras em 100 e 200 ms: a última é a segunda da lista.
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.afericaoMedindo), findsOneWidget);
    expect(find.byType(MedidorDeNivel), findsOneWidget);
    expect(find.text('−64 dBFS'), findsOneWidget);
    // Zona de VOZ não se aplica ao ruído da sala.
    expect(find.text(AppStrings.medidorAmbiente), findsOneWidget);
    expect(find.text(AppStrings.medidorBaixo), findsNothing);

    await tester.pump(AfericaoDeRuido.duracao);
    await tester.pumpAndSettle();
  });

  testWidgets('sala silenciosa: sem restrição, microfone fechado no fim', (
    tester,
  ) async {
    final fonte = await _abrir(tester);

    await _medir(tester);

    expect(find.text(AppStrings.afericaoSemRestricao), findsOneWidget);
    expect(find.byType(MedidorDeNivel), findsNothing);
    expect(fonte.aberturas, 1);
    expect(fonte.fechamentos, greaterThanOrEqualTo(1));
    // Liberada, a gravação dá lugar às tarefas.
    expect(find.text(AppStrings.tarefasTitulo), findsOneWidget);
    expect(find.text(AppStrings.capturaIniciarGravacao), findsNothing);
  });

  testWidgets('microfone mudo bloqueia a gravação e diz o que fazer', (
    tester,
  ) async {
    await _abrir(tester, fonte: _FonteFalsa(niveis: [double.negativeInfinity]));

    await _medir(tester);

    expect(find.text(AppStrings.afericaoMudo), findsOneWidget);
    expect(find.text(AppStrings.afericaoMudoTexto), findsOneWidget);
    expect(_motivo(AppStrings.capturaBloqueadaMicrofone), findsOneWidget);
  });

  testWidgets('sala barulhenta avisa com o nível e o limite', (tester) async {
    await _abrir(tester, fonte: _FonteFalsa(niveis: [-41, -39, -40, -42]));

    await _medir(tester);

    expect(find.text(AppStrings.afericaoRuidoAlto), findsOneWidget);
    expect(
      find.text(AppStrings.afericaoRuidoAltoTexto('−40 dBFS', '−50 dBFS')),
      findsOneWidget,
    );
  });

  testWidgets('medir de novo depois de corrigir a sala', (tester) async {
    final fonte = await _abrir(
      tester,
      fonte: _FonteFalsa(niveis: [double.negativeInfinity]),
    );
    await _medir(tester);

    await _medir(tester, rotulo: AppStrings.afericaoMedirDeNovo);

    expect(fonte.aberturas, 2);
  });

  testWidgets('sem permissão diz o que fazer e deixa tentar de novo', (
    tester,
  ) async {
    await _abrir(tester, fonte: _FonteFalsa(permitido: false));

    await _medir(tester);

    expect(find.text(AppStrings.afericaoSemPermissao), findsOneWidget);
    expect(find.text(AppStrings.tentarNovamente), findsOneWidget);
  });

  testWidgets('microfone que não abre vira falha, não medição eterna', (
    tester,
  ) async {
    final fonte = await _abrir(tester, fonte: _FonteFalsa(falhaAoAbrir: true));

    await _medir(tester);

    expect(find.text(AppStrings.afericaoFalhou), findsOneWidget);
    expect(fonte.fechamentos, greaterThanOrEqualTo(1));
  });

  testWidgets('formato trocado pelo aparelho aparece, com o pedido e o usado', (
    tester,
  ) async {
    await _abrir(
      tester,
      fonte: _FonteFalsa(
        ajuste: const AjusteDeConfiguracao(taxaDeAmostragem: 48000, canais: 2),
      ),
    );

    await _medir(tester);

    expect(find.text(AppStrings.afericaoAjusteTitulo), findsOneWidget);
    expect(
      find.text(
        AppStrings.afericaoAjusteTexto(
          taxaUsada: 48000,
          canaisUsados: 2,
          taxaPedida: 44100,
          canaisPedidos: 1,
        ),
      ),
      findsOneWidget,
    );
  });

  group('MedidorDeNivel', () {
    Future<void> medidor(WidgetTester tester, double? dbfs) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.claro,
            home: Scaffold(body: MedidorDeNivel(dbfs: dbfs)),
          ),
        );

    testWidgets('saturação vem escrita e com ícone, não só em vermelho', (
      tester,
    ) async {
      await medidor(tester, -0.2);

      expect(find.text(AppStrings.medidorSaturando), findsOneWidget);
      expect(find.text('0 dBFS'), findsOneWidget);
    });

    testWidgets('na aferição, sala alta não aparece como sinal adequado', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.claro,
          home: const Scaffold(body: MedidorDeNivel(dbfs: -24, ambiente: true)),
        ),
      );

      expect(find.text(AppStrings.medidorAmbiente), findsOneWidget);
      expect(find.text(AppStrings.medidorAdequado), findsNothing);
    });

    testWidgets('na aferição, saturação continua avisada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.claro,
          home: const Scaffold(
            body: MedidorDeNivel(dbfs: -0.2, ambiente: true),
          ),
        ),
      );

      expect(find.text(AppStrings.medidorSaturando), findsOneWidget);
    });

    testWidgets('silêncio digital aparece como sem sinal', (tester) async {
      await medidor(tester, double.negativeInfinity);

      expect(find.text(AppStrings.medidorSemSinal), findsOneWidget);
      expect(find.text('— dBFS'), findsOneWidget);
    });

    testWidgets('leitor de tela recebe a zona e o valor num nó só', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await medidor(tester, -20);

      expect(
        find.bySemanticsLabel(
          '${AppStrings.medidorRotulo}: ${AppStrings.medidorAdequado}',
        ),
        findsOneWidget,
      );
      semantica.dispose();
    });
  });
}
