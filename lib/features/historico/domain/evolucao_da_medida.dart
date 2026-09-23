/// Como se lê a variação de uma medida acústica entre duas sessões.
///
/// A separação que este arquivo existe para manter: **direção não é leitura**.
/// O número subiu ou desceu — isso é um fato, e é o que a seta desenha. Se
/// subir é melhorar ou piorar depende de QUAL medida é, e isso é leitura
/// clínica, que só o texto diz.
///
/// Misturar as duas coisas foi um defeito real: a lista mostrava seta para
/// cima ao lado da palavra "melhorando" para um AVQI que tinha CAÍDO. A seta
/// contradizia o gráfico da tela de evolução, onde a linha descia.
library;

/// Para onde o valor foi entre as duas últimas sessões.
///
/// Só a direção. Nenhum juízo sobre ela — ver [LeituraDaEvolucao].
enum DirecaoDaMedida {
  subiu,
  estavel,
  desceu,

  /// Sem base para comparar: menos de duas sessões, ou nenhum limiar de
  /// mudança definido para a medida (ver `LimiaresDeMudanca`). Estado de
  /// primeira classe, pelo mesmo princípio de "sem faixa de referência" — sem
  /// base, a tela não classifica.
  semComparacao,
}

/// Em que sentido a medida melhora.
enum SentidoDeMelhora {
  /// Índices de severidade e de perturbação: AVQI, jitter, shimmer.
  menorEhMelhor,

  /// Medidas de qualidade do sinal: CPPS, HNR.
  maiorEhMelhor,

  /// A medida não tem sentido de melhora. A f0 é o caso: ela é comparada à
  /// faixa esperada para o perfil do paciente, e subir não é nem bom nem ruim
  /// fora desse contexto.
  semSentido,
}

/// Medida acústica acompanhada ao longo das sessões.
///
/// O valor de cada medida vem calculado do servidor — o aplicativo não faz
/// análise acústica. Aqui mora apenas o sentido de leitura de cada uma.
enum MedidaAcustica {
  avqi(SentidoDeMelhora.menorEhMelhor),
  cpps(SentidoDeMelhora.maiorEhMelhor),
  jitter(SentidoDeMelhora.menorEhMelhor),
  shimmer(SentidoDeMelhora.menorEhMelhor),
  hnr(SentidoDeMelhora.maiorEhMelhor),
  f0(SentidoDeMelhora.semSentido);

  const MedidaAcustica(this.sentidoDeMelhora);

  /// Se, para esta medida, o valor maior ou o menor é o melhor.
  final SentidoDeMelhora sentidoDeMelhora;
}

/// O que a variação significa para o paciente.
enum LeituraDaEvolucao {
  melhora,
  estavel,
  piora,

  /// Não há leitura a fazer: ou faltam sessões para comparar, ou a medida
  /// variou sem ter sentido de melhora definido. Como em toda a interface, sem
  /// base para afirmar, não se afirma.
  semLeitura,
}

/// A leitura de [direcao] para [medida].
///
/// É aqui, e só aqui, que "desceu" vira "melhorando". Nenhuma tela deve
/// deduzir isso da direção por conta própria, e nenhum ícone carrega essa
/// informação.
LeituraDaEvolucao lerEvolucao({
  required MedidaAcustica medida,
  required DirecaoDaMedida direcao,
}) {
  if (direcao == DirecaoDaMedida.semComparacao) {
    return LeituraDaEvolucao.semLeitura;
  }
  // Antes do sentido de melhora, e de propósito: "estável" não afirma que a
  // medida está melhor nem pior, então vale até para a f0, que não tem sentido
  // de melhora definido.
  if (direcao == DirecaoDaMedida.estavel) return LeituraDaEvolucao.estavel;

  return switch (medida.sentidoDeMelhora) {
    SentidoDeMelhora.semSentido => LeituraDaEvolucao.semLeitura,
    SentidoDeMelhora.menorEhMelhor =>
      direcao == DirecaoDaMedida.desceu
          ? LeituraDaEvolucao.melhora
          : LeituraDaEvolucao.piora,
    SentidoDeMelhora.maiorEhMelhor =>
      direcao == DirecaoDaMedida.subiu
          ? LeituraDaEvolucao.melhora
          : LeituraDaEvolucao.piora,
  };
}
