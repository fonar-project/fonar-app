import 'package:flutter/material.dart';

/// Tokens de movimento.
///
/// ## Movimento funcional, nunca decorativo
///
/// Até a US31 o FONAR não tinha animação nenhuma além da cor de hover: a tela
/// é lida com pressa, às vezes com o paciente esperando, e movimento que só
/// enfeita atrasa a leitura. Continua valendo. O que mudou é o reconhecimento
/// de que trocar de estado SEM movimento também custa: quando a etapa da
/// gravação avança ou uma seção aparece de repente, o olho perde onde estava
/// e relê a tela inteira.
///
/// Então o movimento existe para dizer O QUE MUDOU, e obedece a quatro regras:
///
/// 1. **Curto.** [rapida] para estado de controle, [media] para troca de
///    conteúdo. Nada passa de 250 ms — o toque vira resposta antes de a
///    pessoa terminar de olhar.
/// 2. **Só entra; o que sai, sai na hora.** Na troca de conteúdo o estado
///    antigo some imediatamente e o novo aparece com um esmaecer e um
///    deslize de poucos pixels. Nunca há dois estados na tela ao mesmo tempo
///    — numa ferramenta clínica, um valor velho ainda visível durante a
///    transição pode ser lido como atual. Vale para a troca de tela, nos dois
///    sentidos (US57): ao abrir, a tela de baixo some e a nova entra; ao
///    voltar, a que sai some no primeiro quadro e a de baixo reaparece com a
///    mesma entrada. A barra lateral e as abas não fazem parte da troca —
///    ficam paradas (ver `AppEstrutura`).
/// 3. **Sem quique, zoom ou parallax.** Curvas de desaceleração simples.
/// 4. **Nada com movimento reduzido.** Com o sistema pedindo menos movimento,
///    toda duração vira zero ([duracao]) e as transições devolvem o estado
///    final direto — como pede o CLAUDE.md.
///
/// EXCEÇÃO PROPOSITAL: o medidor de nível (VU meter) continua respondendo ao
/// áudio mesmo com movimento reduzido. Ele não é decoração — é o feedback que
/// diz ao profissional se a captura está saturando. Reduza a suavização,
/// mantenha a resposta.
abstract final class AppMovimento {
  /// Transição de estado de controle (hover, pressionado, foco, seleção).
  static const rapida = Duration(milliseconds: 150);

  /// Mudança de conteúdo dentro de uma mesma tela, e troca de tela.
  static const media = Duration(milliseconds: 220);

  /// Desaceleração: começa rápido, assenta devagar. A de tudo que entra.
  static const curva = Curves.easeOutCubic;

  /// Quanto o conteúdo novo desliza ao entrar, em pixels lógicos. Pouco o
  /// bastante para não parecer que a tela "anda".
  static const deslize = 8.0;

  /// O usuário pediu menos movimento no sistema operacional?
  ///
  /// Chame antes de qualquer animação e devolva o estado final direto quando
  /// for `true`.
  static bool reduzido(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Duração já ajustada à preferência de movimento reduzido.
  static Duration duracao(BuildContext context, Duration padrao) =>
      reduzido(context) ? Duration.zero : padrao;

  /// Troca de página: a tela que aparece — a nova, ao abrir; a de baixo, ao
  /// voltar — esmaece e sobe [deslize] pixels, em [media]; a outra some na
  /// hora. Sem o deslizar lateral do Material, que no Windows parece defeito
  /// e no celular só adiciona espera.
  static const transicoesDePagina = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _TransicaoDePagina(),
      TargetPlatform.windows: _TransicaoDePagina(),
      TargetPlatform.linux: _TransicaoDePagina(),
      TargetPlatform.macOS: _TransicaoDePagina(),
      TargetPlatform.iOS: _TransicaoDePagina(),
    },
  );

  /// A entrada de um conteúdo novo: esmaecer e subir [deslize] pixels.
  static Widget entrada(Animation<double> animacao, Widget filho) {
    final curva = CurvedAnimation(parent: animacao, curve: AppMovimento.curva);
    return FadeTransition(
      opacity: curva,
      child: AnimatedBuilder(
        animation: curva,
        builder: (_, filho) => Transform.translate(
          offset: Offset(0, (1 - curva.value) * deslize),
          child: filho,
        ),
        child: filho,
      ),
    );
  }
}

class _TransicaoDePagina extends PageTransitionsBuilder {
  const _TransicaoDePagina();

  @override
  Duration get transitionDuration => AppMovimento.media;

  /// A volta dura o mesmo que a ida: é nela que a tela de baixo reaparece
  /// com a entrada curta. A que sai não espera — some no primeiro quadro.
  @override
  Duration get reverseTransitionDuration => AppMovimento.media;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => TelaEmTroca(
    animacao: animation,
    animacaoDeCima: secondaryAnimation,
    reduzido: AppMovimento.reduzido(context),
    child: child,
  );
}

/// Uma tela durante a troca de telas: entrando, saindo, coberta pela que
/// abriu por cima ou reaparecendo quando a de cima volta.
///
/// [animacao] é a da própria tela (sobe ao abrir, desce ao voltar dela);
/// [animacaoDeCima] é a da tela aberta por cima desta. A regra é a do
/// [AppMovimento]: só entra; o que sai, sai na hora.
///
/// Pública para o teste. Na árvore, a estrutura é sempre a mesma — só os
/// valores mudam —, para a tela não perder o estado se uma volta for
/// cancelada no meio.
@visibleForTesting
class TelaEmTroca extends StatelessWidget {
  const TelaEmTroca({
    required this.animacao,
    required this.animacaoDeCima,
    required this.reduzido,
    required this.child,
    super.key,
  });

  final Animation<double> animacao;
  final Animation<double> animacaoDeCima;
  final bool reduzido;
  final Widget child;

  /// Quanto da entrada já aconteceu: 0 é escondida, 1 é no lugar.
  double get progresso {
    // Voltando desta tela: some na hora.
    if (animacao.status == AnimationStatus.reverse) return 0;
    // Outra abrindo por cima, ou já por cima: esta some na hora.
    if (animacaoDeCima.status == AnimationStatus.forward ||
        animacaoDeCima.status == AnimationStatus.completed) {
      return 0;
    }
    if (reduzido) return 1;
    // A de cima voltando: esta reaparece com a entrada.
    if (animacaoDeCima.status == AnimationStatus.reverse) {
      return AppMovimento.curva.transform(1 - animacaoDeCima.value);
    }
    // Abrindo (ou já aberta).
    return AppMovimento.curva.transform(animacao.value);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([animacao, animacaoDeCima]),
    builder: (context, filho) {
      final p = progresso;
      return Opacity(
        opacity: p,
        child: Transform.translate(
          offset: Offset(0, (1 - p) * AppMovimento.deslize),
          child: filho,
        ),
      );
    },
    child: child,
  );
}

/// Troca um conteúdo por outro com a entrada do [AppMovimento]: o antigo
/// some na hora, o novo esmaece e sobe uns pixels.
///
/// A [chave] diz QUANDO é outro conteúdo — a etapa da gravação, o parâmetro
/// da CAPE-V, carregando × pronto. Mudou a chave, anima; o mesmo conteúdo
/// reconstruído com dados novos não anima.
class AppTrocaAnimada extends StatelessWidget {
  const AppTrocaAnimada({
    required this.chave,
    required this.child,
    this.alinhamento = Alignment.topCenter,
    this.preencher = false,
    super.key,
  });

  final Object? chave;
  final Widget child;

  /// O conteúdo ocupa toda a área que recebe — use quando a troca está num
  /// `Expanded`, como o carregando → pronto de uma tela inteira.
  final bool preencher;

  /// Onde o conteúdo fica enquanto o tamanho muda.
  final AlignmentGeometry alinhamento;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMovimento.duracao(context, AppMovimento.media),
      // O que sai, sai na hora: nunca dois estados na tela ao mesmo tempo.
      // Quem garante é o `layoutBuilder`, que só monta o atual; a duração
      // zero só descarta o antigo sem esperar.
      reverseDuration: Duration.zero,
      transitionBuilder: (filho, animacao) =>
          AppMovimento.entrada(animacao, filho),
      layoutBuilder: (atual, anteriores) => Stack(
        alignment: alinhamento,
        fit: preencher ? StackFit.expand : StackFit.loose,
        children: [?atual],
      ),
      child: KeyedSubtree(key: ValueKey(chave), child: child),
    );
  }
}

/// O tamanho de [child] muda acompanhando, em vez de pular.
///
/// Com movimento reduzido, o `AnimatedSize` nem entra na árvore: com duração
/// zero ele termina a animação no meio do próprio layout e o Flutter acusa
/// erro — o que apareceria justamente para quem pediu menos movimento.
class AppTamanhoAnimado extends StatelessWidget {
  const AppTamanhoAnimado({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMovimento.reduzido(context)) return child;
    return AnimatedSize(
      duration: AppMovimento.media,
      curve: AppMovimento.curva,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// Mostra ou esconde [child] acompanhando a altura, para o que vem embaixo
/// descer ou subir junto em vez de pular — a consistência da CAPE-V que
/// aparece ao marcar desvio, a mensagem de erro de um campo.
class AppRevelar extends StatelessWidget {
  const AppRevelar({required this.visivel, required this.child, super.key});

  final bool visivel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const escondido = SizedBox(width: double.infinity);
    if (AppMovimento.reduzido(context)) return visivel ? child : escondido;
    return AppTamanhoAnimado(
      child: visivel
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppMovimento.media,
              curve: AppMovimento.curva,
              builder: (_, valor, filho) =>
                  Opacity(opacity: valor, child: filho),
              child: child,
            )
          : escondido,
    );
  }
}
