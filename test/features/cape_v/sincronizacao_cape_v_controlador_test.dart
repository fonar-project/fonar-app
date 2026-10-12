import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/cape_v/data/cape_v_no_firestore.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/cape_v/presentation/sincronizacao_cape_v_controlador.dart';

import '../../apoio/sessao_de_teste.dart';

/// Rede ligável e desligável pelo teste.
class _Rede extends Notifier<bool> {
  _Rede(this._inicial);
  final bool _inicial;
  @override
  bool build() => _inicial;
  void ligar(bool online) => state = online;
}

/// Conta as vezes que foi chamada; [segurar] deixa a chamada no ar.
class _Contada implements SincronizacaoDaCapeV {
  var vezes = 0;
  Completer<void>? segurar;
  AppException? falha;

  @override
  Future<int> sincronizar() async {
    vezes++;
    if (segurar case final espera?) await espera.future;
    if (falha case final f?) throw f;
    return 0;
  }
}

class _Montagem {
  _Montagem(this.container, this.rede, this.sincronizacao);

  final ProviderContainer container;
  final NotifierProvider<_Rede, bool> rede;
  final _Contada sincronizacao;

  SincronizacaoCapeVControlador get controlador =>
      container.read(sincronizacaoCapeVControladorProvider.notifier);

  /// Liga ou desliga a rede; a leitura logo depois é o que avisa quem escuta.
  void ligar(bool online) {
    container.read(rede.notifier).ligar(online);
    container.read(conexaoOnlineProvider);
  }
}

/// O controlador acordado, como o `FonarApp` faz.
Future<_Montagem> _acordar({bool online = true, bool comSessao = true}) async {
  final rede = NotifierProvider<_Rede, bool>(() => _Rede(online));
  final sincronizacao = _Contada();
  final container = ProviderContainer(
    overrides: [
      conexaoOnlineProvider.overrideWith((ref) => ref.watch(rede)),
      sessaoProvider.overrideWith(
        () => Sessao(comSessao ? contaDeTeste : null),
      ),
      sincronizacaoDaCapeVProvider.overrideWithValue(sincronizacao),
    ],
  );
  addTearDown(container.dispose);
  container.listen(sincronizacaoCapeVControladorProvider, (_, _) {});
  await _esperar();
  return _Montagem(container, rede, sincronizacao);
}

Future<void> _esperar() => Future<void>.delayed(Duration.zero);

void main() {
  test('acordado com rede e sessão, sobe o que ficou de antes', () async {
    final m = await _acordar();
    expect(m.sincronizacao.vezes, 1);
  });

  test('sem rede, nada; a rede voltou, tenta', () async {
    final m = await _acordar(online: false);
    m.controlador.pedir();
    await _esperar();
    expect(m.sincronizacao.vezes, 0);

    m.ligar(true);
    await _esperar();
    expect(m.sincronizacao.vezes, 1);
  });

  test('sem sessão, nada; alguém entrou, tenta', () async {
    final m = await _acordar(comSessao: false);
    expect(m.sincronizacao.vezes, 0);

    m.container.read(sessaoProvider.notifier).abrir(contaDeTeste);
    await _esperar();
    expect(m.sincronizacao.vezes, 1);
  });

  test('pedida no meio de outra, roda de novo no fim — uma vez só', () async {
    final m = await _acordar();
    final espera = Completer<void>();
    m.sincronizacao.segurar = espera;
    m.controlador.pedir();
    await _esperar();
    expect(m.sincronizacao.vezes, 2);

    // Duas avaliações registradas enquanto a sincronização está no ar.
    m.controlador.pedir();
    m.controlador.pedir();
    m.sincronizacao.segurar = null;
    espera.complete();
    await _esperar();
    await _esperar();
    expect(m.sincronizacao.vezes, 3);
  });

  test('falha não escapa nem trava as próximas', () async {
    final m = await _acordar();
    m.sincronizacao.falha = const Proibido();
    m.controlador.pedir();
    await _esperar();
    expect(m.sincronizacao.vezes, 2);

    m.sincronizacao.falha = null;
    m.controlador.pedir();
    await _esperar();
    expect(m.sincronizacao.vezes, 3);
  });

  test('no modo de exemplo não há sincronização, e nada acontece', () async {
    final container = ProviderContainer(
      overrides: [
        conexaoOnlineProvider.overrideWithValue(true),
        sessaoProvider.overrideWith(() => Sessao(contaDeTeste)),
        sincronizacaoDaCapeVProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sincronizacaoCapeVControladorProvider, (_, _) {});
    container.read(sincronizacaoCapeVControladorProvider.notifier).pedir();
    await _esperar();
  });
}
