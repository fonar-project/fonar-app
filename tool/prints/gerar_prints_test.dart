/// As prints do capítulo 4 ("Interfaces do Sistema") da documentação do TCC,
/// tiradas do próprio aplicativo, no modo de exemplo.
///
///     flutter test --update-goldens tool/prints/gerar_prints_test.dart
///
/// Cada print é um teste: monta o app inteiro pelo roteador de verdade, como
/// a matriz de layout (`test/app/matriz_de_layout_test.dart`), leva até a
/// tela e salva a imagem em `build/prints/`, com o número da figura da
/// documentação no nome. Uma tela que não abrir não impede as outras. É o
/// `--update-goldens` que grava os arquivos: sem ele, o teste compararia com
/// imagens que não existem.
///
/// Ficam de fora, para tirar à mão: a revisão das gravações (exige gravar de
/// verdade), a landing page e o FONAR na Tela de Início do iPhone. A
/// pré-visualização A4 do laudo é rasterizada pelo plugin `printing`, que não
/// roda em teste: na print do laudo, a folha fica vazia.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/app/app.dart';
import 'package:fonar_app/app/router/app_router.dart';
import 'package:fonar_app/app/router/app_routes.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/features/auth/data/profissional_atual.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';
import 'package:fonar_app/features/cadastro/domain/cadastro.dart';
import 'package:fonar_app/features/captura/data/fonte_de_nivel_record.dart';
import 'package:fonar_app/features/captura/data/microfones_record.dart';
import 'package:fonar_app/features/captura/domain/afericao_de_ruido.dart';
import 'package:fonar_app/features/captura/domain/ajuste_de_configuracao.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/fonte_de_nivel.dart';
import 'package:fonar_app/features/captura/domain/microfone.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/guia/presentation/alvos_do_guia.dart';
import 'package:fonar_app/features/guia/presentation/widgets/botao_de_ajuda.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

import '../../test/apoio/banco_em_memoria.dart';
import '../../test/apoio/sessao_de_teste.dart';

const _desktop = Size(1440, 900);
const _celular = Size(390, 844);
const _deitado = Size(844, 390);

const _p = AppRoutes.paramPacienteId;
const _a = AppRoutes.paramAnaliseId;

/// O paciente e a análise de exemplo, os mesmos da matriz de layout.
const _paciente = 'exemplo-a';
const _analise = 'exemplo-a-4';

/// Quem assina: fictício, e com nome que diz isso.
const _profissional = Profissional(
  nome: 'Fonoaudióloga de Exemplo',
  registro: 'CRFa 2-00000',
  email: 'fono@exemplo.com',
  credenciamento: Credenciamento.credenciado,
);

/// O microfone de mentira: emite [niveis] em ciclo, um por intervalo. O
/// padrão é o de uma sala silenciosa.
class _Microfone implements FonteDeNivel {
  const _Microfone([this.niveis = const [-62, -60, -61, -59, -63]]);

  final List<double> niveis;

  @override
  AjusteDeConfiguracao? get ajuste => null;

  @override
  Future<bool> pedirPermissao() async => true;

  @override
  Future<Stream<double>> abrir(
    Duration intervalo, {
    String? microfone,
  }) async {
    return Stream.periodic(intervalo, (i) => niveis[i % niveis.length]);
  }

  @override
  Future<void> fechar() async {}
}

/// Dois microfones ligados, para o menu ter o que mostrar.
class _Microfones implements ListaDeMicrofones {
  const _Microfones();

  @override
  Future<List<Microfone>> listar() async => const [
    Microfone(id: 'mic-1', nome: 'Microfone embutido'),
    Microfone(id: 'mic-2', nome: 'Microfone USB de exemplo'),
  ];
}

/// As fontes do app, para o texto sair na Urbanist, e não na fonte de blocos
/// que o teste usa quando nenhuma foi carregada. Lê o mesmo FontManifest que
/// o app empacota: os ícones do Material entram junto.
Future<void> _carregarFontes() async {
  final manifesto =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final familia in manifesto.cast<Map<String, dynamic>>()) {
    final carregador = FontLoader(familia['family'] as String);
    final fontes = (familia['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final fonte in fontes) {
      carregador.addFont(rootBundle.load(fonte['asset'] as String));
    }
    await carregador.load();
  }
}

/// Deixa a tela desenhar e carregar as imagens, que no teste só decodificam
/// em tempo real (`runAsync`). `pump` limitado, como na matriz de layout: o
/// medidor de nível e a prévia do laudo nunca assentam.
Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  await tester.runAsync(() async {
    for (final elemento in find.byType(Image).evaluate()) {
      await precacheImage((elemento.widget as Image).image, elemento);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// O app inteiro, pelo roteador de verdade, numa tela de [tamanho] lógico
/// com o dobro da densidade, com a sessão aberta e quem assina preenchido.
Future<(ProviderContainer, GoRouter)> _abrir(
  WidgetTester tester,
  Size tamanho, {
  List<Override> extras = const [],
  bool online = true,
}) async {
  tester.view.physicalSize = tamanho * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      bancoDeTeste(),
      conexaoOnlineProvider.overrideWithValue(online),
      sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
      ...extras,
    ],
  );
  addTearDown(container.dispose);
  container.read(profissionalAtualProvider.notifier).definir(_profissional);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const FonarApp()),
  );
  await _assentar(tester);
  return (container, container.read(routerProvider));
}

/// Vai à tela [nome] e espera ela desenhar.
Future<void> _ir(
  WidgetTester tester,
  GoRouter roteador,
  String nome, [
  Map<String, String> parametros = const {},
]) async {
  roteador.goNamed(nome, pathParameters: parametros);
  await _assentar(tester);
}

/// Uma tela da entrada, que só existe sem sessão.
Future<void> _entrada(WidgetTester tester, Size tamanho, String nome) async {
  final (container, roteador) = await _abrir(tester, tamanho);
  container.read(sessaoProvider.notifier).encerrar();
  await _ir(tester, roteador, nome);
}

/// Uma tela com sessão, sem nada além de abrir.
Future<void> _tela(
  WidgetTester tester,
  Size tamanho,
  String nome, [
  Map<String, String> parametros = const {},
]) async {
  final (_, roteador) = await _abrir(tester, tamanho);
  await _ir(tester, roteador, nome, parametros);
}

/// A captura do paciente de exemplo, com o microfone de mentira.
Future<void> _captura(
  WidgetTester tester, [
  _Microfone microfone = const _Microfone(),
]) async {
  final (_, roteador) = await _abrir(
    tester,
    _desktop,
    extras: [
      fonteDeNivelProvider.overrideWithValue(microfone),
      listaDeMicrofonesProvider.overrideWithValue(const _Microfones()),
    ],
  );
  await _ir(tester, roteador, AppRoutes.capturaNome, {_p: _paciente});
}

/// Toca em [alvo] e espera a tela responder.
Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await tester.pump();
}

/// Toca em "Medir ruído ambiente" e deixa passar [quanto] da aferição.
Future<void> _medir(WidgetTester tester, Duration quanto) async {
  await _tocar(tester, find.text(AppStrings.afericaoMedir));
  await tester.pump(quanto);
}

/// Mede a sala inteira e segue para a primeira tarefa, a vogal.
Future<void> _irParaAVogal(WidgetTester tester) async {
  await _captura(tester);
  await _medir(tester, AfericaoDeRuido.duracao + const Duration(seconds: 1));
  await _assentar(tester);
  await _tocar(tester, find.text(AppStrings.capturaContinuar));
  await _assentar(tester);
}

/// Um envio da fila, com as duas gravações da sessão.
ItemDaFila _envio(String id, DateTime quando, SituacaoDoEnvio situacao) {
  final sessao = 'sessao-$id';
  return ItemDaFila(
    id: id,
    pacienteId: _paciente,
    nomeDoPaciente: 'Paciente de exemplo',
    sessaoId: sessao,
    amostras: [
      for (final tarefa in TarefaDeGravacao.values)
        Amostra(
          id: '$id-${tarefa.name}',
          pacienteId: _paciente,
          sessaoId: sessao,
          tarefa: tarefa,
          caminho: '/amostras/$id-${tarefa.name}.wav',
          gravadaEm: quando,
          duracao: const Duration(seconds: 5),
          taxaDeAmostragem: 44100,
          canais: 1,
          problemas: const [],
        ),
    ],
    criadoEm: quando,
    situacao: situacao,
    analiseId: situacao == SituacaoDoEnvio.enviado ? sessao : null,
    profissionalId: contaDeTeste.uid,
  );
}

/// Salva a tela inteira em `build/prints/[nome].png`.
Future<void> _salvar(String nome) => expectLater(
  find.byType(FonarApp),
  matchesGoldenFile('../../build/prints/$nome.png'),
);

/// Uma print por teste. Erro de uma tela (uma imagem que não carrega, um
/// plugin que não existe no teste) vira aviso no log, e a print sai assim
/// mesmo: o que importa aqui é a imagem, e quem confere é quem a usa.
void _print(String nome, Future<void> Function(WidgetTester tester) corpo) {
  testWidgets(nome, (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (detalhes) =>
        debugPrint('Aviso em $nome: ${detalhes.exceptionAsString()}');
    try {
      await corpo(tester);
      await _salvar(nome);
    } finally {
      FlutterError.onError = original;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!autoUpdateGoldenFiles) {
      throw StateError(
        'Rode com --update-goldens: é ele que grava as prints em build/prints.',
      );
    }
    await _carregarFontes();
  });

  // 4.1 Acesso e primeiro acesso
  _print(
    'f03-entrada',
    (tester) => _entrada(tester, _desktop, AppRoutes.loginNome),
  );
  _print(
    'f04-criar-conta',
    (tester) => _entrada(tester, _celular, AppRoutes.criarContaNome),
  );
  _print(
    'f05-confirmar-email',
    (tester) => _entrada(tester, _celular, AppRoutes.verificarEmailNome),
  );
  _print(
    'f06-cadastro-profissional',
    (tester) => _entrada(tester, _desktop, AppRoutes.completarCadastroNome),
  );
  _print(
    'f07-recuperar-senha',
    (tester) => _entrada(tester, _celular, AppRoutes.recuperarSenhaNome),
  );

  // 4.2 Pacientes
  _print('f08-lista-com-guia', (tester) async {
    final (_, roteador) = await _abrir(
      tester,
      _desktop,
      extras: [guiaAbreSozinhoProvider.overrideWithValue(true)],
    );
    await _ir(tester, roteador, AppRoutes.pacientesNome);
    await _assentar(tester);
  });
  _print(
    'f09-lista-no-celular',
    (tester) => _tela(tester, _celular, AppRoutes.pacientesNome),
  );
  _print(
    'f10-cadastro-de-paciente',
    (tester) => _tela(tester, _desktop, AppRoutes.novaAvaliacaoNome),
  );
  _print(
    'f11-perfil-do-paciente',
    (tester) => _tela(tester, _desktop, AppRoutes.pacienteDetalheNome, {
      _p: _paciente,
    }),
  );

  // 4.3 Consentimento
  _print(
    'f12-registro-do-consentimento',
    (tester) => _tela(tester, _desktop, AppRoutes.consentimentoNome, {
      _p: _paciente,
    }),
  );
  _print(
    'f13-retirada-do-consentimento',
    (tester) => _tela(tester, _celular, AppRoutes.retiradaConsentimentoNome, {
      _p: _paciente,
    }),
  );

  // 4.4 Aferição e gravação
  _print('f14-afericao-menu-do-microfone', (tester) async {
    await _captura(tester);
    await _tocar(tester, find.byType(DropdownButtonFormField<Microfone?>));
    await _assentar(tester);
  });
  _print('f15-medidor-de-nivel', (tester) async {
    await _captura(tester);
    await _medir(tester, const Duration(milliseconds: 1500));
    await _assentar(tester);
  });
  _print('f16-conferencia-com-a-voz', (tester) async {
    await _captura(tester, const _Microfone([double.negativeInfinity]));
    await _medir(tester, AfericaoDeRuido.duracao + const Duration(seconds: 1));
    await _assentar(tester);
  });
  _print('f17-gravacao-da-vogal', _irParaAVogal);
  _print('f18-gravacao-da-fala', (tester) async {
    await _irParaAVogal(tester);
    await _tocar(tester, find.text(AppStrings.tarefaFalaCurta).first);
    await _assentar(tester);
  });

  // 4.5 Fila e resultado
  _print('f20-fila-de-envio', (tester) async {
    final (container, roteador) = await _abrir(tester, _desktop, online: false);
    final fila = container.read(repositorioFilaProvider);
    final agora = DateTime.now();
    await tester.runAsync(() async {
      await fila.adicionar(_envio('envio-1', agora, SituacaoDoEnvio.naFila));
      await fila.adicionar(
        _envio(
          'envio-2',
          agora.subtract(const Duration(hours: 2)),
          SituacaoDoEnvio.enviado,
        ),
      );
    });
    await _ir(tester, roteador, AppRoutes.filaNome);
  });
  _print(
    'f21-resultado-da-analise',
    (tester) => _tela(tester, _desktop, AppRoutes.analiseResultadoNome, {
      _p: _paciente,
      _a: _analise,
    }),
  );
  _print(
    'f22-espectrograma',
    (tester) => _tela(tester, _deitado, AppRoutes.espectrogramaNome, {
      _p: _paciente,
      _a: _analise,
    }),
  );

  // 4.6 CAPE-V, evolução, laudo e histórico
  _print(
    'f23-cape-v-no-computador',
    (tester) => _tela(tester, _desktop, AppRoutes.capeVNome, {
      _p: _paciente,
      _a: _analise,
    }),
  );
  _print(
    'f24-cape-v-no-celular',
    (tester) => _tela(tester, _celular, AppRoutes.capeVNome, {
      _p: _paciente,
      _a: _analise,
    }),
  );
  _print(
    'f25-evolucao',
    (tester) => _tela(tester, _desktop, AppRoutes.evolucaoNome, {
      _p: _paciente,
    }),
  );
  _print(
    'f26-modo-paciente',
    (tester) => _tela(tester, _desktop, AppRoutes.modoPacienteNome, {
      _p: _paciente,
    }),
  );
  _print(
    'f27-laudo',
    (tester) => _tela(tester, _desktop, AppRoutes.laudoNome, {
      _p: _paciente,
      _a: _analise,
    }),
  );
  _print(
    'f28-historico',
    (tester) => _tela(tester, _desktop, AppRoutes.historicoNome),
  );

  // 4.7 Conta e ajuda
  _print(
    'f29-conta',
    (tester) => _tela(tester, _desktop, AppRoutes.contaNome),
  );
  _print('f30-envio-da-carteira', (tester) async {
    final (container, roteador) = await _abrir(tester, _celular);
    container
        .read(profissionalAtualProvider.notifier)
        .definir(
          const Profissional(
            nome: 'Fonoaudióloga de Exemplo',
            registro: 'CRFa 2-00000',
            email: 'fono@exemplo.com',
            credenciamento: Credenciamento.pendente,
          ),
        );
    await _ir(tester, roteador, AppRoutes.contaNome);
    await tester.ensureVisible(find.text(AppStrings.comprovanteTitulo));
    await _assentar(tester);
  });
  _print('f31-ajuda', (tester) async {
    final (_, roteador) = await _abrir(tester, _desktop);
    await _ir(tester, roteador, AppRoutes.pacientesNome);
    await _tocar(tester, find.byType(BotaoDeAjuda).first);
    await _assentar(tester);
  });
}
