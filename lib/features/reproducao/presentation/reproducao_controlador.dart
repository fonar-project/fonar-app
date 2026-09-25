import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reprodutor_audioplayers.dart';
import '../domain/reprodutor.dart';

/// O que está tocando na tela — uma gravação por vez.
class EstadoDaReproducao {
  const EstadoDaReproducao({
    this.caminho,
    this.tocando = false,
    this.posicao = Duration.zero,
    this.duracao,
    this.falhou = false,
  });

  /// A gravação carregada, se houver.
  final String? caminho;
  final bool tocando;
  final Duration posicao;
  final Duration? duracao;

  /// [caminho] não pôde ser aberto ou tocado.
  final bool falhou;

  bool eDe(String outro) => caminho == outro;
}

/// Toca as gravações de uma tela, uma por vez.
///
/// Tocar outra para a atual. E gravar ou medir o ruído para tudo — ver
/// [parar]: o som do alto-falante entraria no microfone e contaminaria
/// exatamente o que a análise mede.
class ReproducaoControlador extends Notifier<EstadoDaReproducao> {
  late Reprodutor _reprodutor;
  final _inscricoes = <StreamSubscription<Object?>>[];

  /// Cresce a cada `abrir` e a cada [parar]: uma abertura que termina depois
  /// de outra ter começado, ou depois de pedirem para parar, não toca.
  var _vez = 0;

  /// Uma gravação está sendo aberta e ainda não tocou.
  var _abrindo = false;

  @override
  EstadoDaReproducao build() {
    _reprodutor = ref.watch(reprodutorProvider);
    _inscricoes
      ..add(
        _reprodutor.posicoes.listen((p) {
          if (ref.mounted && state.tocando) {
            state = _com(posicao: p);
          }
        }),
      )
      ..add(_reprodutor.terminou.listen((_) => _aoTerminar()))
      // Falha que chega depois de começar a tocar (o aparelho perdeu a saída
      // de som, o arquivo não decodificou no meio): sem isto, a tela seguia
      // mostrando "tocando" (revisão de 24/09).
      ..add(_reprodutor.falhas.listen((_) => _aoFalhar()));
    ref.onDispose(() {
      for (final i in _inscricoes) {
        unawaited(i.cancel());
      }
    });
    return const EstadoDaReproducao();
  }

  /// Chegou ao fim: volta ao começo, pronto para ouvir de novo.
  void _aoTerminar() {
    if (!ref.mounted || state.caminho == null) return;
    state = _com(tocando: false, posicao: Duration.zero);
    unawaited(
      _tentar(() async {
        await _reprodutor.pausar();
        await _reprodutor.irPara(Duration.zero);
      }),
    );
  }

  void _aoFalhar() {
    if (!ref.mounted || state.caminho == null) return;
    state = _com(tocando: false, falhou: true);
  }

  EstadoDaReproducao _com({
    bool? tocando,
    Duration? posicao,
    Duration? duracao,
    bool? falhou,
  }) => EstadoDaReproducao(
    caminho: state.caminho,
    tocando: tocando ?? state.tocando,
    posicao: posicao ?? state.posicao,
    duracao: duracao ?? state.duracao,
    falhou: falhou ?? state.falhou,
  );

  /// Toca [caminho]; se já está tocando, pausa; se estava pausado, continua.
  Future<void> alternar(String caminho) async {
    if (state.eDe(caminho) && !state.falhou) {
      if (state.tocando) {
        state = _com(tocando: false);
        await _tentar(_reprodutor.pausar);
      } else {
        state = _com(tocando: true);
        await _tentar(_reprodutor.tocar);
      }
      return;
    }

    final vez = ++_vez;
    _abrindo = true;
    state = EstadoDaReproducao(caminho: caminho);
    try {
      await _reprodutor.pausar();
      final duracao = await _reprodutor.abrir(caminho);
      if (!ref.mounted || vez != _vez) return;
      _abrindo = false;
      state = EstadoDaReproducao(
        caminho: caminho,
        duracao: duracao,
        tocando: true,
      );
      await _reprodutor.tocar();
    } catch (_) {
      if (ref.mounted && vez == _vez) {
        _abrindo = false;
        state = EstadoDaReproducao(caminho: caminho, falhou: true);
      }
    }
  }

  /// Leva a gravação atual a [posicao].
  Future<void> irPara(String caminho, Duration posicao) async {
    if (!state.eDe(caminho) || state.falhou) return;
    state = _com(posicao: posicao);
    await _tentar(() => _reprodutor.irPara(posicao));
  }

  /// Para o que estiver tocando. Chamado antes de gravar e de medir.
  ///
  /// Também desiste de uma gravação que ainda está abrindo: sem isso, ela
  /// terminava de abrir já com o microfone ligado e tocava por cima da coleta
  /// (revisão de 24/09).
  Future<void> parar() async {
    _vez++;
    if (_abrindo) {
      _abrindo = false;
      state = const EstadoDaReproducao();
      return;
    }
    if (!state.tocando) return;
    state = _com(tocando: false);
    await _tentar(_reprodutor.pausar);
  }

  Future<void> _tentar(Future<void> Function() acao) async {
    try {
      await acao();
    } catch (_) {
      if (ref.mounted) state = _com(tocando: false, falhou: true);
    }
  }
}

final reproducaoControladorProvider =
    NotifierProvider.autoDispose<ReproducaoControlador, EstadoDaReproducao>(
      ReproducaoControlador.new,
    );
