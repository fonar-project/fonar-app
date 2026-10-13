import 'dart:typed_data';

import '../../analise/domain/resultado_da_analise.dart';
import '../../cape_v/domain/avaliacao_cape_v.dart';

/// Um laudo EMITIDO, como o profissional o gerou (US38).
///
/// O aplicativo reúne o que o servidor mediu e o que o profissional
/// registrou; a CONCLUSÃO é escrita por ele, com as palavras dele. O FONAR não
/// emite diagnóstico, e não há texto automático nenhum no laudo que pareça
/// um.
///
/// Um laudo emitido não muda nem some (ADR-018 da API): emitir de novo cria
/// outro, com código próprio, que diz qual substitui — no registro e no
/// próprio documento. O anterior continua guardado, como foi entregue.
class Laudo {
  const Laudo({
    required this.id,
    required this.analiseId,
    required this.pacienteId,
    required this.conclusao,
    required this.geradoEm,
    required this.pdf,
    this.substitui,
    this.enviadoEm,
  });

  /// O código do documento (UUID), gerado na emissão. Os oito primeiros
  /// caracteres vão impressos ([codigo]).
  final String id;

  /// A análise — e portanto a sessão — a que o laudo se refere.
  final String analiseId;
  final String pacienteId;

  /// Texto do profissional.
  final String conclusao;

  final DateTime geradoEm;

  /// O documento como foi gerado. Compartilhar e imprimir usam ESTE arquivo,
  /// e não um novo montado na hora: se a CAPE-V ou o cadastro mudarem
  /// depois, o laudo que já saiu não muda junto.
  final Uint8List pdf;

  /// O código ([id]) do laudo desta análise que este substitui, se houver.
  final String? substitui;

  /// Quando a cópia chegou à API. Nulo: por enquanto, só neste aparelho.
  final DateTime? enviadoEm;

  /// O que vai impresso no documento e aparece na tela.
  String get codigo => codigoDoDocumento(id);
}

/// Os oito primeiros caracteres do código, em maiúsculas — o que o PDF
/// imprime (ADR-018 da API). O código inteiro fica no registro.
String codigoDoDocumento(String id) => id.substring(0, 8).toUpperCase();

/// Onde os laudos ficam.
///
/// Só se acrescenta: [registrar] nunca substitui um laudo, e não há como
/// alterar nem apagar um. Quem leva os laudos de um paciente é a eliminação
/// dele, pela API.
abstract interface class RepositorioLaudos {
  /// O vigente desta análise — o emitido por último —, ou `null`.
  Future<Laudo?> daAnalise(String analiseId);

  /// Todos os emitidos para esta análise, do mais recente ao mais antigo.
  Future<List<Laudo>> emitidosDaAnalise(String analiseId);

  /// Acrescenta um laudo emitido. Código repetido é erro, nunca sobrescrita.
  Future<void> registrar(Laudo laudo);

  /// O vigente de cada análise de [pacienteId], em qualquer ordem.
  Future<List<Laudo>> doPaciente(String pacienteId);
}

/// O que se confere antes de gerar o laudo.
///
/// TODO(clínico): quais itens IMPEDEM a geração e quais só avisam. Hoje
/// impedem consentimento, análise concluída e conclusão escrita; amostra com
/// problema e CAPE-V não registrada só avisam — e o laudo diz isso no texto.
enum ItemDaConferencia {
  consentimento,
  analiseConcluida,
  qualidadeDasAmostras,
  capeV,
  conclusao,

  /// Nome e registro de quem assina. Desde a US32 vêm do perfil da conta,
  /// que começa vazio: laudo sem quem assina não serve.
  assinatura,
}

enum SituacaoDoItem {
  /// Resolvido.
  ok,

  /// Impede gerar o laudo.
  pendente,

  /// Não impede, mas o profissional precisa saber: vai estar no laudo.
  aviso,
}

class ConferenciaDoLaudo {
  const ConferenciaDoLaudo(this.itens);

  /// Todos os itens, na ordem de [ItemDaConferencia].
  final Map<ItemDaConferencia, SituacaoDoItem> itens;

  bool get podeGerar => !itens.values.contains(SituacaoDoItem.pendente);
}

ConferenciaDoLaudo conferirLaudo({
  required bool temConsentimento,
  required ResultadoDaAnalise resultado,
  required AvaliacaoCapeV? capeV,
  required String conclusao,
  required bool temAssinatura,
}) {
  final amostrasComProblema = resultado.qualidade.values.any(
    (q) => !q.adequada,
  );
  return ConferenciaDoLaudo({
    // A gravação já é bloqueada sem consentimento; conferir de novo aqui é
    // de propósito. O laudo é o documento que sai do aplicativo, e um
    // consentimento retirado depois da gravação não pode passar batido.
    ItemDaConferencia.consentimento: temConsentimento
        ? SituacaoDoItem.ok
        : SituacaoDoItem.pendente,
    ItemDaConferencia.analiseConcluida:
        resultado.situacao == SituacaoDaAnalise.concluida
        ? SituacaoDoItem.ok
        : SituacaoDoItem.pendente,
    ItemDaConferencia.qualidadeDasAmostras: amostrasComProblema
        ? SituacaoDoItem.aviso
        : SituacaoDoItem.ok,
    ItemDaConferencia.capeV: capeV == null
        ? SituacaoDoItem.aviso
        : SituacaoDoItem.ok,
    ItemDaConferencia.conclusao: conclusao.trim().isEmpty
        ? SituacaoDoItem.pendente
        : SituacaoDoItem.ok,
    ItemDaConferencia.assinatura: temAssinatura
        ? SituacaoDoItem.ok
        : SituacaoDoItem.pendente,
  });
}
