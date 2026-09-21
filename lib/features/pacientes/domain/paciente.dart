import '../../historico/domain/evolucao_da_medida.dart';

/// Paciente como aparece na lista.
class Paciente {
  const Paciente({
    required this.id,
    required this.nome,
    required this.queixa,
    required this.direcaoAvqi,
    this.ultimaSessao,
  });

  final String id;
  final String nome;

  /// Queixa principal, nas palavras do registro clínico.
  final String queixa;

  /// Nula enquanto o paciente não tiver nenhuma sessão gravada.
  final DateTime? ultimaSessao;

  /// Para onde o AVQI foi entre as duas últimas sessões.
  ///
  /// DIREÇÃO, não leitura: o campo diz que o número subiu ou desceu, e nada
  /// mais. Quem transforma isso em "melhorando" é [lerEvolucao] — no AVQI,
  /// descer é melhorar.
  ///
  /// Chega pronta da camada de dados; a tela não calcula. Qual diferença conta
  /// como mudança real é pendência clínica aberta: o AVQI varia entre medições
  /// do mesmo paciente, e chamar de mudança uma diferença dentro dessa
  /// variação seria enganoso.
  final DirecaoDaMedida direcaoAvqi;

  /// O paciente aparece numa busca por [termo]?
  ///
  /// Procura no nome e na queixa, sem diferenciar maiúscula nem acento: quem
  /// digita "rouquidao" com pressa, no teclado do celular, precisa achar
  /// "rouquidão". Termo vazio ou só com espaço corresponde a todos.
  bool correspondeA(String termo) {
    final procurado = _normalizar(termo.trim());
    if (procurado.isEmpty) return true;
    return _normalizar('$nome $queixa').contains(procurado);
  }
}

const _semAcento = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

// ponytail: tabela fixa do português, não Unicode completo. Nome estrangeiro
// com diacrítico de fora da tabela só casa digitado com o acento.
String _normalizar(String texto) => texto
    .toLowerCase()
    .split('')
    .map((letra) => _semAcento[letra] ?? letra)
    .join();
