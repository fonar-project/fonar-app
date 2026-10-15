/// Uma versão de anotação do paciente (US51): o texto como foi escrito
/// naquela hora. Nunca muda — editar escreve outra versão, que diz em
/// [substitui] qual veio antes (ADR-019 da API). O que muda é só o lembrete
/// visto.
class VersaoDaAnotacao {
  const VersaoDaAnotacao({
    required this.id,
    required this.pacienteId,
    required this.texto,
    required this.escritaEm,
    required this.lembrarNaProxima,
    this.substitui,
    this.lembreteVistoEm,
  });

  final String id;
  final String pacienteId;
  final String texto;
  final DateTime escritaEm;
  final String? substitui;
  final bool lembrarNaProxima;
  final DateTime? lembreteVistoEm;
}

/// O tamanho máximo do texto — o mesmo das regras do Firestore
/// (`TAMANHO_MAXIMO_ANOTACAO`, na API).
const tamanhoMaximoDaAnotacao = 2000;

/// Uma anotação: a versão vigente e as que ela substituiu.
class Anotacao {
  Anotacao(this.versoes) : assert(versoes.isNotEmpty);

  /// Da primeira escrita à vigente.
  final List<VersaoDaAnotacao> versoes;

  VersaoDaAnotacao get vigente => versoes.last;

  /// O id da versão vigente: é ela que a próxima edição substitui.
  String get id => vigente.id;
  String get texto => vigente.texto;

  /// Quando a anotação foi feita — a primeira versão.
  DateTime get criadaEm => versoes.first.escritaEm;

  /// Quando foi editada pela última vez, ou nulo se nunca foi.
  DateTime? get editadaEm => versoes.length > 1 ? vigente.escritaEm : null;

  /// As versões de antes, da mais recente à primeira.
  List<VersaoDaAnotacao> get anteriores =>
      versoes.sublist(0, versoes.length - 1).reversed.toList();

  /// O lembrete desta anotação ainda espera ser visto, [hoje]? Só num dia
  /// posterior ao da escrita: no mesmo dia é a mesma consulta.
  bool lembretePendente(DateTime hoje) =>
      vigente.lembrarNaProxima &&
      vigente.lembreteVistoEm == null &&
      _dia(vigente.escritaEm).isBefore(_dia(hoje));
}

DateTime _dia(DateTime instante) {
  final local = instante.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Junta as versões em anotações, da mais recente à mais antiga (pela data
/// em que cada uma foi feita).
///
/// A vigente de cada anotação é a versão que nenhuma outra substitui. Duas
/// versões que substituem a mesma (editada em dois aparelhos sem rede) dão
/// duas anotações, cada uma com a mesma história: nada se perde.
List<Anotacao> montarAnotacoes(Iterable<VersaoDaAnotacao> versoes) {
  final porId = {for (final v in versoes) v.id: v};
  final substituidas = {for (final v in versoes) ?v.substitui};
  final anotacoes = <Anotacao>[];
  for (final vigente in versoes) {
    if (substituidas.contains(vigente.id)) continue;
    final cadeia = <VersaoDaAnotacao>[vigente];
    final vistas = {vigente.id};
    var atual = vigente;
    // A versão anterior que não está aqui (ainda não desceu) encerra a
    // história no que se tem.
    for (
      var antes = porId[atual.substitui];
      antes != null && vistas.add(antes.id);
      antes = porId[atual.substitui]
    ) {
      cadeia.insert(0, antes);
      atual = antes;
    }
    anotacoes.add(Anotacao(cadeia));
  }
  anotacoes.sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
  return anotacoes;
}

/// Os lembretes que esperam ser vistos [hoje], do mais antigo ao mais novo.
List<Anotacao> lembretesPendentes(List<Anotacao> anotacoes, DateTime hoje) => [
  for (final a in anotacoes)
    if (a.lembretePendente(hoje)) a,
]..sort((a, b) => a.vigente.escritaEm.compareTo(b.vigente.escritaEm));
