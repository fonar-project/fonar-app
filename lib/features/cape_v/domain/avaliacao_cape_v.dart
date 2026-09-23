/// Avaliação perceptivo-auditiva pela escala CAPE-V.
///
/// É o JULGAMENTO DO PROFISSIONAL, que ele registra depois de ouvir o
/// paciente. O aplicativo não sugere, não calcula e não corrige nota
/// nenhuma: guarda o que foi marcado, como foi marcado.
///
/// TODO(clínico): os nomes dos parâmetros e das opções seguem a forma usual
/// em português, mas precisam ser conferidos pela orientação com a versão da
/// escala adotada pelo projeto.
library;

/// Os parâmetros da escala, na ordem da folha de registro.
enum ParametroCapeV {
  grauGeral,
  rugosidade,
  soprosidade,
  tensao,
  pitch,
  loudness;

  /// Pitch e loudness pedem também o SENTIDO do desvio: uma nota 40 em pitch
  /// não diz se a voz está grave ou aguda demais.
  bool get temDirecao => this == pitch || this == loudness;
}

/// Consistência do desvio ao longo das tarefas.
enum Consistencia { consistente, intermitente }

/// Sentido do desvio, em pitch e loudness.
enum DirecaoDoDesvio { abaixo, acima }

/// A marca de um parâmetro.
class NotaCapeV {
  const NotaCapeV({this.valor, this.consistencia, this.direcao});

  /// De 0 (sem desvio) a 100 (desvio extremo). Nulo: não marcado — o que é
  /// diferente de zero.
  final int? valor;
  final Consistencia? consistencia;
  final DirecaoDoDesvio? direcao;

  static const minimo = 0;
  static const maximo = 100;

  /// Há desvio marcado: a nota passa a pedir consistência (e direção, onde
  /// houver).
  bool get temDesvio => (valor ?? 0) > 0;

  NotaCapeV comValor(int valor) => NotaCapeV(
    valor: valor.clamp(minimo, maximo),
    // Sem desvio, consistência e direção não se aplicam, e não ficam
    // guardadas de uma marcação anterior.
    consistencia: valor > 0 ? consistencia : null,
    direcao: valor > 0 ? direcao : null,
  );

  NotaCapeV comConsistencia(Consistencia c) =>
      NotaCapeV(valor: valor, consistencia: c, direcao: direcao);

  NotaCapeV comDirecao(DirecaoDoDesvio d) =>
      NotaCapeV(valor: valor, consistencia: consistencia, direcao: d);
}

/// Uma avaliação registrada.
class AvaliacaoCapeV {
  const AvaliacaoCapeV({
    required this.analiseId,
    required this.pacienteId,
    required this.notas,
    required this.registradaEm,
    this.comentarios = '',
  });

  /// A análise (e portanto a sessão) a que a avaliação se refere.
  final String analiseId;
  final String pacienteId;
  final Map<ParametroCapeV, NotaCapeV> notas;
  final DateTime registradaEm;
  final String comentarios;
}

/// O que falta numa nota para a avaliação ser registrada.
enum ProblemaNaNota {
  naoMarcada,
  semConsistencia,

  /// TODO(clínico): exigir o sentido do desvio em pitch e loudness foi
  /// decisão de implementação — sem ele a nota fica ambígua. Confirmar.
  semDirecao,
}

/// Confere as notas. Devolve os problemas por parâmetro; vazio é tudo certo.
///
/// Os seis parâmetros precisam estar marcados — zero é resposta, ausência
/// não. Com desvio, a consistência é obrigatória; em pitch e loudness, também
/// o sentido.
Map<ParametroCapeV, ProblemaNaNota> conferirNotas(
  Map<ParametroCapeV, NotaCapeV> notas,
) => {for (final p in ParametroCapeV.values) p: ?_problema(p, notas[p])};

ProblemaNaNota? _problema(ParametroCapeV parametro, NotaCapeV? nota) {
  if (nota?.valor == null) return ProblemaNaNota.naoMarcada;
  if (!nota!.temDesvio) return null;
  if (nota.consistencia == null) return ProblemaNaNota.semConsistencia;
  if (parametro.temDirecao && nota.direcao == null) {
    return ProblemaNaNota.semDirecao;
  }
  return null;
}

/// Onde as avaliações ficam.
///
/// TODO(drift): banco local e fila de sincronização, como o resto.
abstract interface class RepositorioCapeV {
  /// A avaliação desta análise, ou `null` se ainda não houver.
  Future<AvaliacaoCapeV?> daAnalise(String analiseId);

  /// Registra, substituindo a anterior da mesma análise.
  Future<void> registrar(AvaliacaoCapeV avaliacao);
}
