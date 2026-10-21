/// Varredura de layout: TODA rota do aplicativo, em cada largura-alvo e em
/// cada escala de texto do sistema, conferindo que nada estoura.
///
/// ## O que esta matriz cobre, e o que NÃO cobre
///
/// Cobre o ESTADO PADRÃO de cada rota — a tela como ela abre, com os dados de
/// exemplo. É uma varredura larga e rasa: muitas telas, um estado cada.
///
/// **Não cobre estado cheio, nem estado de erro, nem nada que dependa de
/// interação.** A lista de pacientes com o nome mais longo que cabe, a fila
/// com um item em cada situação, o laudo com a conferência toda pendente, o
/// medidor de nível durante a medição — nada disso aparece aqui, porque
/// chegar nesses estados exige montar dados e tocar em coisas. Isso é
/// responsabilidade do teste de CADA TELA, que é estreito e fundo: uma tela,
/// muitos estados.
///
/// As duas são necessárias e nenhuma substitui a outra:
///
/// - sem esta, uma tela inteira pode não ter teste de largura nenhum, e
///   ninguém nota — foi assim que o estouro do medidor de nível em 390px
///   passou;
/// - sem as de cada tela, o estado que estoura é justamente o que a varredura
///   nunca monta.
///
/// Ao acrescentar uma tela, ela entra em [_rotas] — e o estado cheio dela
/// continua sendo trabalho do teste da própria tela.
///
/// ## Por que pelo roteador de verdade
///
/// Montar cada página à mão aqui provaria que os widgets funcionam, não que o
/// aplicativo as usa assim. Pelo roteador, um bloqueio de rota desviaria a
/// navegação em silêncio — e é por isso que o teste confere que chegou em
/// cada rota, além de conferir que não estourou. Sem essa conferência, uma
/// varredura inteira desviada para o login passaria de graça.
///
/// Hoje o único desvio que existe é o do consentimento, na captura: o
/// paciente de exemplo tem consentimento registrado, e é por isso que a
/// captura é alcançada. O redirect de autenticação ainda não existe
/// (TODO(auth) em `app_router.dart`); quando existir, esta conferência é o
/// que vai acusar se a varredura parar de ver as telas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/design_system/escala_da_interface.dart';
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';

import '../apoio/banco_em_memoria.dart';
import '../apoio/sessao_de_teste.dart';

const _p = AppRoutes.paramPacienteId;
const _a = AppRoutes.paramAnaliseId;

/// Paciente e análise de exemplo — ver `pacientes_de_exemplo.dart`. Saem
/// quando a API de análise responder de verdade; aí esta lista passa a usar
/// dados montados no banco de teste.
const _paciente = 'exemplo-a';
const _analise = 'exemplo-a-4';

/// Toda rota do `AppRoutes`. Acrescentar uma tela é acrescentar uma linha.
final _rotas = <(String, Map<String, String>)>[
  (AppRoutes.loginNome, {}),
  (AppRoutes.criarContaNome, {}),
  (AppRoutes.verificarEmailNome, {}),
  (AppRoutes.completarCadastroNome, {}),
  (AppRoutes.recuperarSenhaNome, {}),
  (AppRoutes.pacientesNome, {}),
  (AppRoutes.novaAvaliacaoNome, {}),
  (AppRoutes.pacienteDetalheNome, {_p: _paciente}),
  (AppRoutes.edicaoPacienteNome, {_p: _paciente}),
  (AppRoutes.consentimentoNome, {_p: _paciente}),
  (AppRoutes.retiradaConsentimentoNome, {_p: _paciente}),
  (AppRoutes.gravacoesNaoEnviadasNome, {_p: _paciente}),
  (AppRoutes.capturaNome, {_p: _paciente}),
  (AppRoutes.analiseResultadoNome, {_p: _paciente, _a: _analise}),
  (AppRoutes.espectrogramaNome, {_p: _paciente, _a: _analise}),
  (AppRoutes.capeVNome, {_p: _paciente, _a: _analise}),
  (AppRoutes.laudoNome, {_p: _paciente, _a: _analise}),
  (AppRoutes.evolucaoNome, {_p: _paciente}),
  (AppRoutes.modoPacienteNome, {_p: _paciente}),
  (AppRoutes.filaNome, {}),
  (AppRoutes.contaNome, {}),
  (AppRoutes.historicoNome, {}),
];

/// As rotas que só abrem SEM sessão (`AppRoutes.caminhosDeEntrada`).
const _daEntrada = {
  AppRoutes.loginNome,
  AppRoutes.criarContaNome,
  AppRoutes.verificarEmailNome,
  AppRoutes.completarCadastroNome,
  AppRoutes.recuperarSenhaNome,
};

/// Os dois alvos de design do projeto, o celular deitado (espectrograma e
/// gráfico de evolução), a janela estreita de desktop — e as duas pontas: o
/// celular pequeno, comum entre os Android de entrada, e o monitor Full HD.
const _larguras = <(String, Size)>[
  ('360x640', Size(360, 640)),
  ('390x844', Size(390, 844)),
  ('844x390 deitado', Size(844, 390)),
  ('1024x768', Size(1024, 768)),
  ('1440x900', Size(1440, 900)),
  ('1920x1080', Size(1920, 1080)),
];

/// Escalas de texto do sistema. 200% é o teto do Android e do Windows.
const _escalas = [1.0, 1.3, 1.5, 2.0];

/// As barras do sistema de um Android de ponta a ponta — o padrão desde o
/// Android 15, quando o app passou a desenhar por baixo delas (US60). Em pé:
/// a barra de status em cima (48 com a câmera no recorte da tela) e a dos
/// três botões embaixo. Deitado, a dos botões vai para o lado.
const _androidEmPe = FakeViewPadding(top: 48, bottom: 48);
const _androidPequeno = FakeViewPadding(top: 24, bottom: 48);
const _androidDeitado = FakeViewPadding(top: 24, right: 48);

/// O que a tela deixa embaixo das barras do sistema, sem como trazer para a
/// vista (US60).
///
/// Confere cada texto e campo de texto da tela de cima:
/// - fora de rolagem, ele tem de estar inteiro na área livre das barras;
/// - numa rolagem vertical, com ela no começo nada pode estar embaixo da
///   barra de cima, e com ela no fim nada embaixo da de baixo — é o que nunca
///   aparece, role-se quanto se rolar;
/// - fora de rolagem horizontal, nada embaixo das barras dos lados.
///
/// Rola as rolagens até as pontas para conferir: chame por último.
Future<List<String>> _embaixoDasBarras(
  WidgetTester tester,
  String rota,
  FakeViewPadding barras,
) async {
  final tela = Offset.zero & tester.view.physicalSize;
  final livre = Rect.fromLTRB(
    barras.left,
    barras.top,
    tela.width - barras.right,
    tela.height - barras.bottom,
  );
  const folga = 0.5;
  final achados = <String>{};

  String nomeDe(Element e) {
    final w = e.widget;
    final texto = switch (w) {
      RichText(:final text) => text.toPlainText(),
      EditableText(:final controller) => 'campo "${controller.text}"',
      _ => w.runtimeType.toString(),
    };
    final curto = texto.length > 40 ? '${texto.substring(0, 40)}…' : texto;
    return '$rota: "${curto.replaceAll('\n', ' ')}"';
  }

  /// Onde o elemento está na tela, se está nela.
  Rect? ondeEsta(Element e) {
    final r = e.renderObject;
    if (r is! RenderBox || !r.attached || !r.hasSize) return null;
    final rect = MatrixUtils.transformRect(
      r.getTransformTo(null),
      Offset.zero & r.size,
    );
    final naTela = rect.intersect(tela);
    if (naTela.width <= 0 || naTela.height <= 0) return null;
    return rect;
  }

  /// A rolagem vertical mais próxima, e se há uma horizontal antes dela.
  (ScrollableState?, bool) rolagens(Element e) {
    ScrollableState? vertical;
    var horizontal = false;
    e.visitAncestorElements((acima) {
      if (acima is StatefulElement && acima.state is ScrollableState) {
        final rolagem = acima.state as ScrollableState;
        if (axisDirectionToAxis(rolagem.axisDirection) == Axis.vertical) {
          vertical = rolagem;
          return false;
        }
        horizontal = true;
      }
      return true;
    });
    return (vertical, horizontal);
  }

  List<Element> textos() => find
      .byWidgetPredicate((w) => w is RichText || w is EditableText)
      .evaluate()
      .toList();

  void lados(Element e, Rect rect, bool horizontal) {
    if (horizontal) return;
    if (rect.left < livre.left - folga || rect.right > livre.right + folga) {
      achados.add('${nomeDe(e)} embaixo da barra do lado');
    }
  }

  final rolaveis = <ScrollableState>{};
  for (final e in textos()) {
    final rect = ondeEsta(e);
    if (rect == null) continue;
    final (vertical, horizontal) = rolagens(e);
    lados(e, rect, horizontal);
    if (vertical != null) {
      rolaveis.add(vertical);
      continue;
    }
    if (rect.top < livre.top - folga) {
      achados.add('${nomeDe(e)} embaixo da barra de cima');
    }
    if (rect.bottom > livre.bottom + folga) {
      achados.add('${nomeDe(e)} embaixo da barra de baixo');
    }
  }

  for (final rolagem in rolaveis) {
    if (!rolagem.mounted) continue;
    final caixa = rolagem.context.findRenderObject();
    if (caixa is! RenderBox || !caixa.hasSize) continue;
    final janela = MatrixUtils.transformRect(
      caixa.getTransformTo(null),
      Offset.zero & caixa.size,
    ).intersect(tela);

    Future<void> levarA(double Function(ScrollPosition) ponta) async {
      // Duas vezes: numa lista preguiçosa, o fim só é conhecido depois de
      // chegar perto dele.
      for (var i = 0; i < 2; i++) {
        if (!rolagem.mounted) return;
        rolagem.position.jumpTo(ponta(rolagem.position));
        // O que entra ao aparecer termina antes de ser medido (≤ 250 ms).
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Iterable<(Element, Rect)> dela() sync* {
      for (final e in textos()) {
        final (vertical, _) = rolagens(e);
        if (vertical != rolagem) continue;
        final rect = ondeEsta(e);
        if (rect == null || !rect.overlaps(janela)) continue;
        yield (e, rect);
      }
    }

    await levarA((p) => p.minScrollExtent);
    for (final (e, rect) in dela()) {
      if (rect.top < livre.top - folga) {
        achados.add('${nomeDe(e)} embaixo da barra de cima, rolando');
      }
    }
    await levarA((p) => p.maxScrollExtent);
    for (final (e, rect) in dela()) {
      if (rect.bottom > livre.bottom + folga) {
        achados.add('${nomeDe(e)} embaixo da barra de baixo, rolando');
      }
    }
  }
  return achados.toList();
}

/// Quanto se deixa a tela desenhar antes de julgar.
///
/// `pump` limitado, e não `pumpAndSettle`: a prévia A4 do laudo e o medidor
/// de nível nunca "assentam" — é o comportamento certo deles —, e o
/// `pumpAndSettle` estoura o tempo em vez de acusar layout.
Future<void> _desenhar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  final passadas =
      <(String, Size, double, bool, TamanhoDaInterface?, FakeViewPadding?)>[
        for (final (nome, tamanho) in _larguras)
          for (final escala in _escalas)
            (nome, tamanho, escala, false, null, null),
        // Com as barras do sistema de um Android (US60): nada da tela fica
        // embaixo delas — ver [_embaixoDasBarras].
        for (final escala in [1.0, 2.0])
          (
            '390x844 Android',
            const Size(390, 844),
            escala,
            false,
            null,
            _androidEmPe,
          ),
        (
          '360x640 Android',
          const Size(360, 640),
          1.0,
          false,
          null,
          _androidPequeno,
        ),
        (
          '844x390 deitado Android',
          const Size(844, 390),
          1.0,
          false,
          null,
          _androidDeitado,
        ),
        // Uma passada inteira com o sistema pedindo menos movimento: é onde as
        // animações viram duração zero, e duração zero tem armadilhas próprias
        // (o `AnimatedSize` quebrava o layout) — ver `AppMovimento`.
        ('390x844 sem movimento', const Size(390, 844), 1.0, true, null, null),
        // O tamanho da interface (US48): Full HD no automático é 120%, e o app
        // vê 1600×900. Também com o texto do sistema em 200% por cima.
        for (final escala in [1.0, 2.0])
          (
            '1920x1080 interface 120%',
            const Size(1920, 1080),
            escala,
            false,
            TamanhoDaInterface.automatico,
            null,
          ),
      ];
  for (final (nomeDaLargura, tamanho, escala, semMovimento, interface, barras)
      in passadas) {
    testWidgets('$nomeDaLargura @ ${(escala * 100).round()}%', (tester) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      if (barras != null) {
        tester.view.padding = barras;
        tester.view.viewPadding = barras;
      }
      tester.platformDispatcher.textScaleFactorTestValue = escala;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          bancoDeTeste(),
          conexaoOnlineProvider.overrideWithValue(true),
          // Sessão aberta: sem ela, o redirect de autenticação leva toda
          // rota à entrada, e a varredura viraria 18 visitas ao login.
          sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
        ],
      );
      addTearDown(container.dispose);
      final roteador = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.claro,
            routerConfig: roteador,
            builder: (context, filho) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: semMovimento),
              child: interface == null
                  ? filho!
                  : EscalaDaInterface(tamanho: interface, child: filho!),
            ),
          ),
        ),
      );
      await _desenhar(tester);
      tester.takeException();

      final estouros = <String>[];
      final desviadas = <String>[];
      final embaixo = <String>[];
      final sessao = container.read(sessaoProvider.notifier);
      for (final (nome, params) in _rotas) {
        // As telas da entrada são o contrário: só existem sem sessão.
        final naEntrada = _daEntrada.contains(nome);
        if (naEntrada) sessao.encerrar();
        roteador.goNamed(nome, pathParameters: params);
        await _desenhar(tester);
        if (naEntrada) sessao.abrir(contaDeTeste);

        final erro = tester.takeException();
        if (erro != null) estouros.add('$nome: $erro');

        final onde = roteador.state.name;
        if (onde != nome) desviadas.add('$nome -> ${onde ?? '(sem nome)'}');

        if (barras != null && onde == nome) {
          embaixo.addAll(await _embaixoDasBarras(tester, nome, barras));
          final erroAoRolar = tester.takeException();
          if (erroAoRolar != null) {
            estouros.add('$nome, rolando: $erroAoRolar');
          }
        }
      }

      // Primeiro o desvio: varredura que não chegou na tela não diz nada
      // sobre o layout dela, e o erro precisa apontar para isso, não para
      // "nenhum estouro".
      expect(desviadas, isEmpty, reason: desviadas.join('\n'));
      expect(estouros, isEmpty, reason: estouros.join('\n'));
      expect(embaixo, isEmpty, reason: embaixo.join('\n'));
    });
  }
}
