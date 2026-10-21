import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app_estrutura.dart';

/// Como uma tela leva a outra (US60).
///
/// A regra é a do voltar: o voltar — o da tela e o do sistema — leva sempre
/// à tela de onde se veio, uma de cada vez. Por isso a ida comum EMPILHA
/// ([abrir]) em vez de montar a pilha pela hierarquia das rotas, como o `go`
/// faz: quem abre a avaliação pelo Histórico, e dela a CAPE-V, volta da CAPE-V
/// para a avaliação e da avaliação para o Histórico — e não para o perfil do
/// paciente, que nunca esteve no caminho.
///
/// | Verbo | Quando | O voltar de lá |
/// |---|---|---|
/// | [abrir] | a ida comum: tocar num item, num botão, numa aba | esta tela |
/// | [substituir] | o fim de uma tarefa: o cadastro salvo, o consentimento registrado, a gravação enviada | a tela de antes da tarefa — o formulário concluído não volta |
/// | [voltarOu] | o voltar da tela, e o "salvar" que devolve à tela de baixo | a tela de baixo |
///
/// O `go` fica para RECOMEÇAR a pilha, quando o que estava nela deixou de
/// valer: entrar e sair da conta, o paciente eliminado, a rota que não
/// existe, a trilha do desktop.
extension Navegacao on BuildContext {
  /// Abre [nome] por cima da tela atual. O voltar traz esta tela de volta,
  /// como estava.
  void abrir(
    String nome, {
    Map<String, String> pathParameters = const {},
    Object? extra,
  }) {
    unawaited(pushNamed(nome, pathParameters: pathParameters, extra: extra));
  }

  /// Troca a tela atual por [nome]: o fim de uma tarefa. O voltar de [nome]
  /// leva à tela de antes desta.
  void substituir(
    String nome, {
    Map<String, String> pathParameters = const {},
    Object? extra,
  }) => pushReplacementNamed(
    nome,
    pathParameters: pathParameters,
    extra: extra,
  );

  /// Volta uma tela. Sem tela embaixo — aberta pelo endereço, na web —, vai
  /// para [nome], a tela de onde normalmente se chega a esta.
  void voltarOu(String nome, {Map<String, String> pathParameters = const {}}) {
    if (canPop()) {
      pop();
    } else {
      goNamed(nome, pathParameters: pathParameters);
    }
  }

  /// Vai a um destino da navegação principal — a barra lateral, as abas.
  ///
  /// Saindo de outro destino, empilha, como toda ida: o voltar do celular
  /// refaz o caminho pelas abas. Saindo de uma tela de tarefa (só no
  /// desktop a barra lateral aparece nelas), recomeça a pilha pelo destino:
  /// a gravação em andamento, embaixo, continuaria gravando escondida.
  /// No próprio destino, nada.
  void irAoDestino(DestinoPrincipal destino) {
    final atual = GoRouter.of(this).state.name;
    if (atual == destino.rota) return;
    final deOutroDestino = navegacaoDasRotas[atual]?.abas ?? false;
    if (deOutroDestino) {
      abrir(destino.rota);
    } else {
      goNamed(destino.rota);
    }
  }
}
