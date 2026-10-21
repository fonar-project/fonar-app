import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// O voltar do sistema — o botão de voltar do Android e o gesto de voltar —
/// numa tela que não tem outra embaixo dela na pilha (US60).
///
/// O app navega pelo `go`, que monta a pilha pela hierarquia das rotas: as
/// telas de tarefa ficam em cima da tela de onde se chega a elas, e o voltar
/// do sistema as desempilha, como o voltar da própria tela. Mas as abas
/// (Fila, Histórico, Conta) e a criação de conta abrem sozinhas na pilha, e
/// o voltar do Android fechava o app no meio do uso.
///
/// Aqui o voltar leva a [para], a tela de onde se chega a esta, e só fecha o
/// app em [naRaiz] — a lista de pacientes, depois de entrar, e a entrada,
/// antes.
///
/// Também é o que segura o voltar no Android 16 (o app mira a API 36): lá o
/// sistema só entrega o voltar ao app quando o app diz que tem para onde
/// voltar, e o `PopScope` com `canPop: false` é esse aviso. Sem ele, o
/// sistema fechava o app em vez de entregar o voltar.
class VoltarDoSistema extends StatelessWidget {
  const VoltarDoSistema({
    required this.para,
    required this.child,
    this.naRaiz = false,
    super.key,
  });

  /// O nome da rota aonde o voltar leva quando não há tela embaixo.
  final String para;

  /// A primeira tela da área: aqui o voltar fecha o app, como em todo app
  /// Android.
  final bool naRaiz;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Com outra tela embaixo — a recuperação de senha empurrada sobre a
    // entrada, por exemplo —, o voltar é o de sempre: desempilha.
    final temEmbaixo = ModalRoute.canPopOf(context) ?? false;
    return PopScope<Object?>(
      canPop: naRaiz || temEmbaixo,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) GoRouter.of(context).goNamed(para);
      },
      child: child,
    );
  }
}
