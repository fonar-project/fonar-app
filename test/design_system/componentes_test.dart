import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praatico_app/design_system/theme/app_theme.dart';
import 'package:praatico_app/design_system/tokens/app_movimento.dart';
import 'package:praatico_app/design_system/tokens/app_colors.dart';
import 'package:praatico_app/design_system/widgets/app_botao.dart';
import 'package:praatico_app/design_system/widgets/app_campo_texto.dart';
import 'package:praatico_app/design_system/widgets/app_estado.dart';
import 'package:praatico_app/design_system/widgets/app_fundo.dart';
import 'package:praatico_app/design_system/widgets/app_icone.dart';
import 'package:praatico_app/design_system/widgets/app_indicador_conexao.dart';
import 'package:praatico_app/design_system/widgets/app_status_medida.dart';
import 'package:praatico_app/l10n/app_strings.dart';

Widget _tela(Widget filho) => MaterialApp(
  theme: AppTheme.claro,
  home: Scaffold(body: Center(child: filho)),
);

/// A mesma tela, com a preferência de movimento reduzido do sistema ligada.
///
/// O `MediaQuery` vai DENTRO do `MaterialApp`: o app monta o seu próprio a
/// partir da view, e um wrapper por fora seria sobrescrito.
Widget _telaSemMovimento(Widget filho) => MaterialApp(
  theme: AppTheme.claro,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: Scaffold(body: Center(child: filho)),
    ),
  ),
);

/// A mesma tela, declarando que o que está atrás do componente é lavanda —
/// card secundário, faixa de aviso, campo desabilitado.
Widget _telaSobreLavanda(Widget filho) => _tela(
  ColoredBox(
    color: AppColors.lavandaSuave,
    child: AppFundo(fundo: FundoDeTexto.lavanda, child: filho),
  ),
);

void main() {
  group('AppBotao', () {
    testWidgets('chama o callback ao ser tocado', (tester) async {
      var tocou = false;
      await tester.pumpWidget(
        _tela(AppBotao.primario(rotulo: 'Entrar', aoTocar: () => tocou = true)),
      );

      await tester.tap(find.text('Entrar'));
      expect(tocou, isTrue);
    });

    test('recusa ser desabilitado sem explicação', () {
      // A regra do design system — desabilitado nunca é só cor apagada — vira
      // erro de construção, não item de checklist de revisão.
      //
      // O rótulo vem de uma função de propósito: com literais, a chamada seria
      // uma expressão constante, o analisador avaliaria o assert em tempo de
      // compilação e o teste deixaria de compilar em vez de falhar aqui.
      String rotulo() => 'Baixar';

      expect(
        () => AppBotao.primario(rotulo: rotulo(), aoTocar: null),
        throwsAssertionError,
      );
    });

    test('recusa motivo vazio', () {
      String motivo() => '';
      expect(
        () => AppBotao.primario(
          rotulo: 'Baixar',
          aoTocar: null,
          motivoDesabilitado: motivo(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('desabilitado mostra o motivo em texto', (tester) async {
      await tester.pumpWidget(
        _tela(
          const AppBotao.primario(
            rotulo: 'Gravar',
            aoTocar: null,
            motivoDesabilitado: 'Registre o consentimento para gravar',
          ),
        ),
      );

      expect(find.text('Registre o consentimento para gravar'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('respeita o alvo mínimo de toque', (tester) async {
      await tester.pumpWidget(
        _tela(AppBotao.primario(rotulo: 'Entrar', aoTocar: () {})),
      );

      // 48dp: o app é usado com pressa e às vezes com luva.
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48.0),
      );
    });
  });

  group('movimento reduzido', () {
    // `AppMovimento.duracao` existia e não era chamada em lugar nenhum: o
    // token sabia respeitar a preferência do sistema e o componente não
    // perguntava. Estes testes são o que faz a pergunta acontecer.
    testWidgets('a transição do botão passa a durar zero', (tester) async {
      await tester.pumpWidget(
        _telaSemMovimento(AppBotao.primario(rotulo: 'Entrar', aoTocar: () {})),
      );

      final botao = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(botao.style?.animationDuration, Duration.zero);
    });

    testWidgets('o botão secundário também', (tester) async {
      await tester.pumpWidget(
        _telaSemMovimento(
          AppBotao.secundario(rotulo: 'Entrar offline', aoTocar: () {}),
        ),
      );

      final botao = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(botao.style?.animationDuration, Duration.zero);
    });

    testWidgets('sem a preferência, a transição continua', (tester) async {
      // O contrapeso: "duração zero em todo lugar" passaria no teste de cima.
      await tester.pumpWidget(
        _tela(AppBotao.primario(rotulo: 'Entrar', aoTocar: () {})),
      );

      final botao = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(botao.style?.animationDuration, AppMovimento.rapida);
      expect(AppMovimento.rapida, isNot(Duration.zero));
    });
  });

  group('texto secundário segue o fundo real', () {
    // O par de tokens existe porque o tom claro reprova em AA sobre a lavanda
    // (4,48:1 dentro de aviso — ver app_colors_test.dart). De nada adianta ter
    // os dois se o componente escolhe sempre o mesmo.
    Color? corDoRotuloDesabilitado(WidgetTester tester) => tester
        .widget<OutlinedButton>(find.byType(OutlinedButton))
        .style
        ?.foregroundColor
        ?.resolve({WidgetState.disabled});

    testWidgets('botão secundário desabilitado sobre creme', (tester) async {
      await tester.pumpWidget(
        _tela(
          const AppBotao.secundario(
            rotulo: 'Entrar offline',
            aoTocar: null,
            motivoDesabilitado: 'Nenhum paciente salvo neste aparelho',
          ),
        ),
      );

      expect(corDoRotuloDesabilitado(tester), AppColors.secundarioSobreCreme);
    });

    testWidgets('botão secundário desabilitado sobre lavanda', (tester) async {
      // O caso real: a ação do aviso offline do login, dentro de uma faixa
      // lavanda.
      await tester.pumpWidget(
        _telaSobreLavanda(
          const AppBotao.secundario(
            rotulo: 'Entrar offline',
            aoTocar: null,
            motivoDesabilitado: 'Nenhum paciente salvo neste aparelho',
          ),
        ),
      );

      expect(corDoRotuloDesabilitado(tester), AppColors.secundarioSobreLavanda);
    });

    testWidgets('o motivo do botão acompanha o fundo', (tester) async {
      for (final (montar, esperado) in [
        (_tela, AppColors.secundarioSobreCreme),
        (_telaSobreLavanda, AppColors.secundarioSobreLavanda),
      ]) {
        await tester.pumpWidget(
          montar(
            const AppBotao.primario(
              rotulo: 'Gravar',
              aoTocar: null,
              motivoDesabilitado: 'Registre o consentimento para gravar',
            ),
          ),
        );

        final motivo = tester.widget<Text>(
          find.text('Registre o consentimento para gravar'),
        );
        expect(motivo.style?.color, esperado);
      }
    });

    testWidgets('a dica do campo desabilitado usa o tom da lavanda', (
      tester,
    ) async {
      // O campo desabilitado se pinta de `lavandaSuave`: o fundo muda dentro
      // do próprio componente, sem ninguém declarar nada em volta.
      await tester.pumpWidget(
        _tela(
          const AppCampoTexto(
            rotulo: 'E-mail',
            dica: 'nome@dominio.com.br',
            habilitado: false,
          ),
        ),
      );

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(
        campo.decoration?.hintStyle?.color,
        AppColors.secundarioSobreLavanda,
      );
    });

    testWidgets('habilitado sobre creme, a dica usa o tom do creme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tela(
          const AppCampoTexto(rotulo: 'E-mail', dica: 'nome@dominio.com.br'),
        ),
      );

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(
        campo.decoration?.hintStyle?.color,
        AppColors.secundarioSobreCreme,
      );
    });

    testWidgets('habilitado dentro de card lavanda, a dica acompanha', (
      tester,
    ) async {
      await tester.pumpWidget(
        _telaSobreLavanda(
          const AppCampoTexto(
            rotulo: 'E-mail',
            dica: 'nome@dominio.com.br',
            apoio: 'Usamos para enviar o laudo',
          ),
        ),
      );

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(
        campo.decoration?.hintStyle?.color,
        AppColors.secundarioSobreLavanda,
      );
      expect(
        tester
            .widget<Text>(find.text('Usamos para enviar o laudo'))
            .style
            ?.color,
        AppColors.secundarioSobreLavanda,
      );
    });
  });

  group('StatusMedida', () {
    test('cada status tem ícone próprio', () {
      // O contrato de acessibilidade do projeto: informação crítica nunca é
      // comunicada só por cor. Dois status com o mesmo ícone dependeriam da
      // cor para se distinguir.
      final icones = StatusMedida.values.map((s) => s.icone).toSet();
      expect(icones.length, StatusMedida.values.length);
    });

    test('cada status tem rótulo próprio e não vazio', () {
      final rotulos = StatusMedida.values.map((s) => s.rotulo).toSet();
      expect(rotulos.length, StatusMedida.values.length);
      expect(rotulos.any((r) => r.trim().isEmpty), isFalse);
    });

    test('existe o estado de faixa indisponível', () {
      // Classificar sem referência válida é pior que não classificar. Se
      // alguém remover este estado, a medida passa a ser exibida como se
      // tivesse faixa — e não tem.
      expect(StatusMedida.values, contains(StatusMedida.semReferencia));
    });

    testWidgets('desenha texto junto do ícone', (tester) async {
      // "Junto do ícone" é metade do contrato: quem não distingue o verde do
      // vermelho depende do ícone, e quem usa leitor de tela depende do texto.
      // Conferir só o texto deixava passar um selo que perdesse o ícone.
      for (final status in StatusMedida.values) {
        await tester.pumpWidget(_tela(AppStatusMedida(status: status)));

        expect(find.text(status.rotulo), findsOneWidget);
        expect(find.byType(AppIcone), findsOneWidget);
        expect(
          tester.widget<AppIcone>(find.byType(AppIcone)).nome,
          status.icone,
          reason: 'cada status desenha o ícone que é dele',
        );
      }
    });
  });

  group('AppEstado', () {
    // _AvisoOffline (login) e _EstadoCentral (lista de pacientes) resolviam
    // este mesmo contrato duas vezes, com aparência diferente, porque foram
    // escritos em paralelo.
    const acaoDesabilitada = AppBotao.secundario(
      rotulo: 'Entrar em modo offline',
      aoTocar: null,
      motivoDesabilitado: 'Nenhum paciente salvo neste aparelho',
    );

    for (final (nome, montar) in <(String, AppEstado Function())>[
      (
        'faixa',
        () => const AppEstado.faixa(
          titulo: 'Sem conexão',
          texto: 'Dá para gravar; o envio aguarda a conexão voltar.',
          acao: acaoDesabilitada,
        ),
      ),
      (
        'central',
        () => const AppEstado.central(
          titulo: 'Nenhum paciente ainda',
          texto: 'Cadastre o primeiro paciente para iniciar uma avaliação.',
          acao: acaoDesabilitada,
        ),
      ),
    ]) {
      testWidgets('$nome mostra título, texto e ação', (tester) async {
        await tester.pumpWidget(_tela(montar()));

        expect(find.text(montar().titulo), findsOneWidget);
        expect(find.text(montar().texto!), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
        // Desabilitado nunca é só cor apagada, nem aqui dentro.
        expect(
          find.text('Nenhum paciente salvo neste aparelho'),
          findsOneWidget,
        );
      });

      testWidgets('$nome declara o próprio fundo lavanda', (tester) async {
        // O componente PINTA lavanda. Se não declarar isso, tudo o que estiver
        // dentro dele escolhe o tom de texto secundário do creme, que sobre
        // lavanda cai para 3,62:1 e reprova em AA — ver app_colors_test.dart.
        await tester.pumpWidget(_tela(montar()));

        expect(
          tester
              .widget<OutlinedButton>(find.byType(OutlinedButton))
              .style
              ?.foregroundColor
              ?.resolve({WidgetState.disabled}),
          AppColors.secundarioSobreLavanda,
        );
        expect(
          tester
              .widget<Text>(find.text('Nenhum paciente salvo neste aparelho'))
              .style
              ?.color,
          AppColors.secundarioSobreLavanda,
        );
      });

      testWidgets('$nome dispensa o texto quando o título basta', (
        tester,
      ) async {
        await tester.pumpWidget(
          _tela(
            nome == 'faixa'
                ? const AppEstado.faixa(
                    titulo: 'Sem conexão e sem dados locais',
                    acao: acaoDesabilitada,
                  )
                : const AppEstado.central(
                    titulo: 'Sem conexão e sem dados locais',
                    acao: acaoDesabilitada,
                  ),
          ),
        );

        expect(find.text('Sem conexão e sem dados locais'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppCampoTexto', () {
    testWidgets('mostra o rótulo acima, sempre visível', (tester) async {
      await tester.pumpWidget(
        _tela(const AppCampoTexto(rotulo: 'Nome completo')),
      );
      expect(find.text('Nome completo'), findsOneWidget);
    });

    testWidgets('leitor de tela anuncia o campo pelo rótulo', (tester) async {
      // O rótulo é um Text separado, em cima do campo. Sem fundir os dois na
      // árvore de acessibilidade, o campo era anunciado sem nome nenhum.
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(_tela(const AppCampoTexto(rotulo: 'E-mail')));

      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(label: 'E-mail', isTextField: true),
      );
      semantica.dispose();
    });

    testWidgets('erro aparece como mensagem de texto', (tester) async {
      await tester.pumpWidget(
        _tela(
          const AppCampoTexto(
            rotulo: 'E-mail',
            erro: 'Informe um e-mail válido (ex.: nome@dominio.com.br)',
          ),
        ),
      );

      expect(
        find.text('Informe um e-mail válido (ex.: nome@dominio.com.br)'),
        findsOneWidget,
      );
    });

    testWidgets('erro substitui o texto de apoio', (tester) async {
      await tester.pumpWidget(
        _tela(
          const AppCampoTexto(
            rotulo: 'E-mail',
            apoio: 'Usamos para enviar o laudo',
            erro: 'Informe um e-mail válido',
          ),
        ),
      );

      expect(find.text('Usamos para enviar o laudo'), findsNothing);
      expect(find.text('Informe um e-mail válido'), findsOneWidget);
    });
  });

  group('AppIndicadorConexao', () {
    testWidgets('diz em texto qual é o estado', (tester) async {
      await tester.pumpWidget(_tela(const AppIndicadorConexao(online: true)));
      expect(find.text(AppStrings.conexaoOnline), findsOneWidget);

      await tester.pumpWidget(_tela(const AppIndicadorConexao(online: false)));
      expect(find.text(AppStrings.conexaoOffline), findsOneWidget);
    });

    testWidgets('nunca usa cor de status de medida', (tester) async {
      // Verde, amarelo e vermelho são exclusivos de status de medida e
      // saturação de áudio. Um "online" verde ao lado de uma medida "dentro da
      // faixa" verde diria que as duas coisas são da mesma natureza.
      final reservadas = {AppColors.sucesso, AppColors.atencao, AppColors.erro};

      for (final online in [true, false]) {
        for (final escuro in [true, false]) {
          await tester.pumpWidget(
            _tela(
              AppIndicadorConexao(online: online, sobreFundoEscuro: escuro),
            ),
          );
          final cores = [
            ...tester
                .widgetList<AppIcone>(find.byType(AppIcone))
                .map((i) => i.cor),
            ...tester
                .widgetList<Text>(find.byType(Text))
                .map((t) => t.style?.color),
          ];
          expect(cores.where(reservadas.contains), isEmpty);
        }
      }
    });
  });
}
