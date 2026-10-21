/// Um microfone ligado ao aparelho, que o profissional pode escolher para
/// gravar.
///
/// Existe por causa do teste de homologação de 18/10/2026: no Windows, o
/// FONAR gravava sempre do microfone padrão, e com o DroidCam instalado o
/// padrão era o microfone virtual dele, que entrega silêncio. A aferição
/// acusava, com razão, "o microfone não está captando som" — e não havia o
/// que fazer dentro do app. Vale para todas as plataformas: qualquer
/// aparelho com mais de um microfone (notebook com headset, celular com fone
/// com fio, computador com microfone USB) pode ter o padrão errado.
class Microfone {
  const Microfone({required this.id, required this.nome});

  /// O identificador do sistema. Só serve para pedir este microfone de novo
  /// — não é para mostrar.
  final String id;

  /// O nome que o profissional lê.
  final String nome;

  @override
  bool operator ==(Object other) => other is Microfone && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Os microfones que o aparelho oferece agora.
///
/// Contrato para a tela e o controlador serem testados sem microfone; a
/// implementação real está em `data/microfones_record.dart`.
abstract interface class ListaDeMicrofones {
  /// Os microfones que servem para gravar, na ordem do sistema. Vazia se o
  /// sistema não listar — e aí vale o padrão dele.
  Future<List<Microfone>> listar();
}

/// O que a tela mostra da escolha de microfone.
class EscolhaDoMicrofone {
  const EscolhaDoMicrofone({
    this.disponiveis = const [],
    this.escolhido,
    this.ausente,
  });

  /// Os microfones ligados agora.
  final List<Microfone> disponiveis;

  /// O escolhido, se estiver ligado. Nulo é o padrão do sistema.
  final Microfone? escolhido;

  /// O escolhido antes, que agora não aparece — desconectado, ou com outro
  /// identificador depois de reiniciar. Enquanto não voltar, vale o padrão,
  /// e a tela diz isso: gravar de outro microfone sem avisar é justamente o
  /// que a escolha veio evitar.
  final Microfone? ausente;

  /// Há o que escolher? Com um microfone só, o padrão é ele.
  bool get temEscolha => disponiveis.length > 1 || ausente != null;
}

/// O que vale entre o [salvo] e os [disponiveis] agora.
EscolhaDoMicrofone resolverEscolha({
  required List<Microfone> disponiveis,
  required Microfone? salvo,
}) {
  if (salvo == null) return EscolhaDoMicrofone(disponiveis: disponiveis);
  for (final m in disponiveis) {
    // O nome atual, e não o guardado: o sistema pode tê-lo renomeado.
    if (m.id == salvo.id) {
      return EscolhaDoMicrofone(disponiveis: disponiveis, escolhido: m);
    }
  }
  return EscolhaDoMicrofone(disponiveis: disponiveis, ausente: salvo);
}
