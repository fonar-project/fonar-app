import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/relogio.dart';
import 'sessao.dart';

/// Quanto tempo sem uso até bloquear — ver [AppConfig.tempoDeInatividade].
final limiteDeInatividadeProvider = Provider<Duration>(
  (ref) => AppConfig.tempoDeInatividade,
);

/// O app está bloqueado por inatividade?
///
/// Só conta com a sessão aberta: na tela de login não há o que proteger.
/// Bloquear não é sair — a sessão continua, a fila continua subindo, e a
/// tela que estava aberta volta como estava depois do desbloqueio. Só o que
/// está na tela fica escondido até a senha.
///
/// Um relógio só, armado para o fim do prazo: tocar na tela só anota a hora,
/// e quando o relógio dispara ele confere se o prazo venceu mesmo ou se
/// precisa esperar mais. Assim ninguém rearma um relógio a cada movimento do
/// mouse.
class BloqueioPorInatividade extends Notifier<bool> {
  Timer? _relogio;
  late DateTime _ultimaAtividade;

  DateTime _agora() => ref.read(relogioProvider)();
  Duration get _limite => ref.read(limiteDeInatividadeProvider);

  @override
  bool build() {
    ref.onDispose(() => _relogio?.cancel());
    final estavaBloqueado = stateOrNull ?? false;
    _relogio?.cancel();
    _relogio = null;
    // `watch`: abrir a sessão arma o relógio e desbloqueia; fechar desarma.
    if (!ref.watch(sessaoAbertaProvider)) {
      // Fechou com o app bloqueado — "Sair da conta" na tela de bloqueio: a
      // cobertura fica até quem saiu chegar ao login ([liberar]). Soltar
      // aqui mostrava a tela de baixo, com os dados do paciente, durante
      // toda a espera da saída (revisão de 24/09).
      return estavaBloqueado;
    }
    _ultimaAtividade = _agora();
    _armar();
    return false;
  }

  /// Houve toque, tecla ou rolagem. Bloqueado, não conta: só a senha
  /// desbloqueia.
  void registrarAtividade() {
    if (state || _relogio == null) return;
    _ultimaAtividade = _agora();
  }

  /// Confere o prazo agora — na volta do app ao primeiro plano, onde o
  /// relógio pode não ter rodado enquanto o sistema segurava o app.
  void conferir() {
    if (state || _relogio == null) return;
    final passou = _agora().difference(_ultimaAtividade);
    if (passou >= _limite) {
      _relogio?.cancel();
      _relogio = null;
      state = true;
    } else {
      _armar();
    }
  }

  /// A senha conferiu: libera e volta a contar do zero.
  void desbloquear() {
    if (!state) return;
    _ultimaAtividade = _agora();
    state = false;
    _armar();
  }

  /// Saiu da conta com o app bloqueado e já está no login: tira a
  /// cobertura. Com a sessão aberta, não faz nada — aí só a senha libera.
  void liberar() {
    if (ref.read(sessaoAbertaProvider)) return;
    state = false;
  }

  void _armar() {
    _relogio?.cancel();
    final resta = _limite - _agora().difference(_ultimaAtividade);
    _relogio = Timer(resta.isNegative ? Duration.zero : resta, conferir);
  }
}

final bloqueioPorInatividadeProvider =
    NotifierProvider<BloqueioPorInatividade, bool>(BloqueioPorInatividade.new);
