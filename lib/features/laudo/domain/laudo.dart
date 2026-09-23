import 'dart:typed_data';

import '../../analise/domain/resultado_da_analise.dart';
import '../../cape_v/domain/avaliacao_cape_v.dart';

/// O laudo de uma sessão, como o profissional o gerou.
///
/// O aplicativo reúne o que o servidor mediu e o que o profissional
/// registrou; a CONCLUSÃO é escrita por ele, com as palavras dele. O FONAR não
/// emite diagnóstico, e não há texto automático nenhum no laudo que pareça
/// um.
class Laudo {
  const Laudo({
    required this.analiseId,
    required this.pacienteId,
    required this.conclusao,
    required this.geradoEm,
    required this.pdf,
  });

  /// A análise — e portanto a sessão — a que o laudo se refere.
  final String analiseId;
  final String pacienteId;

  /// Texto do profissional.
  final String conclusao;

  final DateTime geradoEm;

  /// O documento como foi gerado. Compartilhar e imprimir usam ESTE arquivo,
  /// e não um novo montado na hora: se a CAPE-V ou o cadastro mudarem
  /// depois, o laudo que já saiu não muda junto sem ninguém gerar de novo.
  final Uint8List pdf;
}

/// TODO(jurídico): gerar de novo SUBSTITUI o laudo anterior da sessão. Se um
/// laudo já entregue ao paciente precisar ficar guardado como foi, este
/// repositório passa a guardar as versões — e a tela, a mostrar qual é a
/// vigente.
abstract interface class RepositorioLaudos {
  /// O último laudo gerado para esta análise, ou `null`.
  Future<Laudo?> daAnalise(String analiseId);

  /// Registra, substituindo o anterior da mesma análise.
  Future<void> registrar(Laudo laudo);
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
  });
}
