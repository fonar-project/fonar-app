import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/sessao.dart';
import '../../data/preferencia_do_guia_local.dart';
import '../../domain/passo_do_guia.dart';
import '../alvos_do_guia.dart';
import 'guia_na_tela.dart';

/// Abre o guia sobre a tela inicial (US50): sozinho, na primeira vez desta
/// conta neste aparelho, e quando alguém pede "Rever o guia".
///
/// Espera a tela estar [pronta] (a lista carregada: o guia aponta para ela),
/// na frente (nada por cima, nem diálogo) e parada (a transição de entrada
/// terminou — senão o recorte sai no lugar de onde a tela vinha). Fechar, de
/// qualquer jeito, guarda que esta conta já viu: o guia não volta sozinho.
///
/// Só a lista de pacientes o usa, e por isso o guia nunca abre sobre a
/// gravação nem no modo paciente.
class AberturaDoGuia extends StatelessWidget {
  const AberturaDoGuia({required this.pronta, required this.child, super.key});

  final bool pronta;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Abertura(
    passos: passosDoGuiaDoInicio,
    chave: PreferenciaDoGuiaLocal.chaveDoInicio,
    atendePedido: true,
    pronta: pronta,
    child: child,
  );
}

/// Abre a dica de primeira vez de uma tela (US50): um balão, uma vez por
/// conta neste aparelho, sobre o elemento que mais pede explicação.
///
/// As mesmas esperas do [AberturaDoGuia]. A tela diz quando está [pronta] —
/// e na gravação isso inclui não haver nada em andamento: a dica aparece
/// antes de medir o ruído, nunca no meio de uma gravação.
class AberturaDaDica extends StatelessWidget {
  const AberturaDaDica({
    required this.dica,
    required this.pronta,
    required this.child,
    super.key,
  });

  final DicaDeTela dica;
  final bool pronta;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Abertura(
    passos: [dica.passo],
    chave: (uid) => PreferenciaDoGuiaLocal.chaveDaDica(dica, uid),
    atendePedido: false,
    pronta: pronta,
    child: child,
  );
}

class _Abertura extends ConsumerStatefulWidget {
  const _Abertura({
    required this.passos,
    required this.chave,
    required this.atendePedido,
    required this.pronta,
    required this.child,
  });

  final List<PassoDoGuia> passos;

  /// Onde fica guardado que uma conta já viu.
  final String Function(String uid) chave;

  /// Abre também quando alguém pede "Rever o guia".
  final bool atendePedido;
  final bool pronta;
  final Widget child;

  @override
  ConsumerState<_Abertura> createState() => _AberturaState();
}

class _AberturaState extends ConsumerState<_Abertura> {
  var _aberto = false;

  /// De quem é a resposta em [_primeiraVez].
  String? _uid;

  /// Ainda não foi visto por [_uid] neste aparelho? Nulo: ainda não se sabe.
  bool? _primeiraVez;

  /// A consulta ao banco em andamento: quem chega enquanto ela corre espera
  /// a mesma, e a resposta é escrita uma vez só.
  Future<void>? _conferindo;

  ModalRoute<Object?>? _rota;
  Animation<double>? _esperando;

  @override
  void dispose() {
    _esperando?.removeStatusListener(_aoTerminarEntrada);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _rota = ModalRoute.of(context);
    final uid = ref.watch(sessaoProvider)?.uid;
    if (uid != _uid) {
      _uid = uid;
      _primeiraVez = null;
    }
    if (widget.atendePedido) {
      ref.listen(pedidoDoGuiaProvider, (_, pedido) {
        if (pedido) _agendar();
      });
    }
    if (widget.pronta) _agendar();
    return widget.child;
  }

  void _agendar() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _tentar());

  Future<void> _tentar() async {
    final uid = _uid;
    if (!mounted || _aberto || !widget.pronta || uid == null) return;

    final pedido = widget.atendePedido && ref.read(pedidoDoGuiaProvider);
    if (!pedido) {
      if (!ref.read(guiaAbreSozinhoProvider)) return;
      if (_primeiraVez == null) {
        await (_conferindo ??= _conferirPrimeiraVez(uid)
            .whenComplete(() => _conferindo = null));
        return _tentar();
      }
      if (_primeiraVez != true) return;
    }
    if (!_livre()) return;

    _aberto = true;
    _primeiraVez = false;
    if (pedido) ref.read(pedidoDoGuiaProvider.notifier).atender();
    // Lida antes de abrir: se a tela sair enquanto o guia está aberto (a
    // sessão acabou), fechar ainda guarda.
    final preferencia = ref.read(preferenciaDoGuiaProvider);
    await mostrarGuia(context, passos: widget.passos);
    _aberto = false;
    try {
      await preferencia.marcarVisto(widget.chave(uid));
    } catch (erro) {
      // Sem guardar, volta na próxima abertura — incômodo, não falha.
      debugPrint('Não foi possível guardar que o guia foi visto: $erro');
    }
  }

  Future<void> _conferirPrimeiraVez(String uid) async {
    bool viu;
    try {
      viu = await ref.read(preferenciaDoGuiaProvider).jaViu(widget.chave(uid));
    } catch (erro) {
      // Banco indisponível: melhor não abrir que abrir toda vez.
      debugPrint('Preferência do guia indisponível: $erro');
      viu = true;
    }
    if (mounted && _uid == uid) _primeiraVez = !viu;
  }

  /// A tela está na frente e parada? Se ainda está entrando, tenta de novo
  /// quando terminar.
  bool _livre() {
    final rota = _rota;
    if (rota != null) {
      if (!rota.isCurrent) return false;
      final entrada = rota.animation;
      if (entrada != null && !entrada.isCompleted) {
        if (_esperando != entrada) {
          _esperando?.removeStatusListener(_aoTerminarEntrada);
          _esperando = entrada..addStatusListener(_aoTerminarEntrada);
        }
        return false;
      }
    }
    // Um diálogo ou o modo paciente por cima: depois.
    return !Navigator.of(context, rootNavigator: true).canPop();
  }

  void _aoTerminarEntrada(AnimationStatus status) {
    if (!status.isCompleted) return;
    _esperando?.removeStatusListener(_aoTerminarEntrada);
    _esperando = null;
    _tentar();
  }
}
