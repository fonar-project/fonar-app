import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/passo_do_guia.dart';

/// Onde está, na tela, cada elemento que o guia aponta.
///
/// Cada elemento se registra pelo PAPEL ([AlvoDoGuia]), e o guia pergunta
/// [onde] ele está na hora de desenhar o recorte. Assim o guia não sabe se a
/// fila é item de barra lateral ou aba embaixo, nem em que tela de que
/// largura está.
class AlvosDoGuia {
  final _registrados = <PapelNoGuia, List<BuildContext>>{};

  void _registrar(PapelNoGuia papel, BuildContext contexto) =>
      (_registrados[papel] ??= []).add(contexto);

  void _retirar(PapelNoGuia papel, BuildContext contexto) =>
      _registrados[papel]?.remove(contexto);

  /// O retângulo do elemento de [papel] nas coordenadas de [referencia], ou
  /// nulo se ele não está desenhado dentro dela.
  ///
  /// Pela transformação de pintura, e não pela posição no layout: vale com a
  /// escala da interface (US48) e com a tela ainda entrando.
  Rect? onde(PapelNoGuia papel, RenderBox referencia) {
    // O mais recente primeiro: numa troca de largura, o elemento novo entra
    // antes de o antigo sair.
    for (final contexto in (_registrados[papel] ?? const []).reversed) {
      final caixa = contexto.findRenderObject();
      if (caixa is! RenderBox ||
          !caixa.attached ||
          !caixa.hasSize ||
          caixa.size.isEmpty) {
        continue;
      }
      final retangulo = MatrixUtils.transformRect(
        caixa.getTransformTo(referencia),
        Offset.zero & caixa.size,
      );
      final visivel = retangulo.intersect(Offset.zero & referencia.size);
      if (visivel.width <= 0 || visivel.height <= 0) continue;
      return retangulo;
    }
    return null;
  }
}

final alvosDoGuiaProvider = Provider<AlvosDoGuia>((ref) => AlvosDoGuia());

/// O guia abre sozinho para quem ainda não o viu neste aparelho? Sim, fora
/// dos testes — ver [AppConfig.guiaAbreSozinho].
final guiaAbreSozinhoProvider = Provider<bool>(
  (ref) => AppConfig.guiaAbreSozinho,
);

/// Alguém pediu "Rever o guia". A tela inicial atende quando estiver na
/// frente — quem pede pode estar em outra tela.
class PedidoDoGuia extends Notifier<bool> {
  @override
  bool build() => false;

  void pedir() => state = true;

  void atender() => state = false;
}

final pedidoDoGuiaProvider = NotifierProvider<PedidoDoGuia, bool>(
  PedidoDoGuia.new,
);

/// Declara [child] como o elemento de [papel] para o guia.
///
/// Não muda nada no layout nem na semântica: só registra onde o elemento
/// está enquanto ele estiver montado.
class AlvoDoGuia extends ConsumerStatefulWidget {
  const AlvoDoGuia({required this.papel, required this.child, super.key});

  final PapelNoGuia papel;
  final Widget child;

  @override
  ConsumerState<AlvoDoGuia> createState() => _AlvoDoGuiaState();
}

class _AlvoDoGuiaState extends ConsumerState<AlvoDoGuia> {
  late final AlvosDoGuia _alvos = ref.read(alvosDoGuiaProvider);

  @override
  void initState() {
    super.initState();
    _alvos._registrar(widget.papel, context);
  }

  @override
  void didUpdateWidget(AlvoDoGuia antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.papel != widget.papel) {
      _alvos
        .._retirar(antigo.papel, context)
        .._registrar(widget.papel, context);
    }
  }

  @override
  void dispose() {
    _alvos._retirar(widget.papel, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
