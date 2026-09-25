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
import 'package:fonar_app/design_system/theme/app_theme.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';

import '../apoio/banco_em_memoria.dart';

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

/// Os dois alvos de design do projeto, o celular deitado (espectrograma e
/// gráfico de evolução) e a janela estreita de desktop.
const _larguras = <(String, Size)>[
  ('390x844', Size(390, 844)),
  ('844x390 deitado', Size(844, 390)),
  ('1024x768', Size(1024, 768)),
  ('1440x900', Size(1440, 900)),
];

/// Escalas de texto do sistema. 200% é o teto do Android e do Windows.
const _escalas = [1.0, 1.3, 1.5, 2.0];

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
  for (final (nomeDaLargura, tamanho) in _larguras) {
    for (final escala in _escalas) {
      testWidgets('$nomeDaLargura @ ${(escala * 100).round()}%', (
        tester,
      ) async {
        tester.view.physicalSize = tamanho;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final container = ProviderContainer(
          retry: (_, _) => null,
          overrides: [
            bancoDeTeste(),
            conexaoOnlineProvider.overrideWithValue(true),
            // Sessão aberta: não muda o roteamento — o redirect de
            // autenticação ainda não existe (TODO(auth) em `app_router.dart`)
            // —, mas é o estado em que as telas são usadas de verdade: com a
            // sessão fechada a fila fica pausada e a tela dela mostra outra
            // coisa. Quando o redirect existir, é isto que impede a varredura
            // de virar 18 visitas ao login.
            sessaoAbertaProvider.overrideWith(() => Sessao(true)),
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
            ),
          ),
        );
        await _desenhar(tester);
        tester.takeException();

        final estouros = <String>[];
        final desviadas = <String>[];
        for (final (nome, params) in _rotas) {
          roteador.goNamed(nome, pathParameters: params);
          await _desenhar(tester);

          final erro = tester.takeException();
          if (erro != null) estouros.add('$nome: $erro');

          final onde = roteador.state.name;
          if (onde != nome) desviadas.add('$nome -> ${onde ?? '(sem nome)'}');
        }

        // Primeiro o desvio: varredura que não chegou na tela não diz nada
        // sobre o layout dela, e o erro precisa apontar para isso, não para
        // "nenhum estouro".
        expect(desviadas, isEmpty, reason: desviadas.join('\n'));
        expect(estouros, isEmpty, reason: estouros.join('\n'));
      });
    }
  }
}
