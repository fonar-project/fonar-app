import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bloqueio_por_inatividade.dart';
import '../pages/tela_de_bloqueio.dart';

/// Envolve o app inteiro: anota cada toque, tecla e rolagem como atividade,
/// e, bloqueado, põe a [TelaDeBloqueio] por cima de tudo.
///
/// Por cima, e não no lugar: a tela de baixo continua viva — o cadastro pela
/// metade, a gravação retomada —, só escondida do olho, do leitor de tela e
/// do teclado até o desbloqueio.
class VigiaDeInatividade extends ConsumerStatefulWidget {
  const VigiaDeInatividade({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<VigiaDeInatividade> createState() => _VigiaDeInatividadeState();
}

class _VigiaDeInatividadeState extends ConsumerState<VigiaDeInatividade> {
  late final AppLifecycleListener _ciclo;

  void _atividade() =>
      ref.read(bloqueioPorInatividadeProvider.notifier).registrarAtividade();

  bool _tecla(KeyEvent _) {
    _atividade();
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_tecla);
    // Voltando do segundo plano: o relógio pode não ter rodado enquanto o
    // sistema segurava o app.
    _ciclo = AppLifecycleListener(
      onResume: () =>
          ref.read(bloqueioPorInatividadeProvider.notifier).conferir(),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_tecla);
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = ref.watch(bloqueioPorInatividadeProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _atividade(),
      onPointerMove: (_) => _atividade(),
      onPointerSignal: (_) => _atividade(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeFocus(
            excluding: bloqueado,
            child: ExcludeSemantics(
              excluding: bloqueado,
              child: IgnorePointer(ignoring: bloqueado, child: widget.child),
            ),
          ),
          // Campo de texto precisa de um Overlay acima dele — o do Navigator
          // fica embaixo, no app. O `wrap` cuida da entrada dele sozinho.
          if (bloqueado) Overlay.wrap(child: const TelaDeBloqueio()),
        ],
      ),
    );
  }
}
