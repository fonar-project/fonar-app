import '../../cadastro/domain/cadastro.dart';

/// Profissional autenticado.
class Profissional {
  const Profissional({
    required this.nome,
    required this.registro,
    this.email = '',
    this.credenciamento,
  });

  /// Como assina — vai impresso no laudo.
  final String nome;

  /// Registro no conselho, ex.: "CRFa 2-12345". Também vai no laudo.
  final String registro;

  /// O e-mail da conta. Vem da autenticação e não se edita aqui.
  final String email;

  /// Se a equipe já conferiu a inscrição no Crefono — vem do cadastro na API.
  /// `null` quando a API não respondeu ainda, ou não está configurada.
  final Credenciamento? credenciamento;

  /// Nome e registro preenchidos — o que o laudo precisa para sair. Na
  /// primeira entrada num aparelho, os dois começam vazios.
  bool get completo => nome.isNotEmpty && registro.isNotEmpty;

  /// Como chamar o profissional na tela: o nome, ou o e-mail enquanto ele
  /// não preencheu o nome.
  String get identificacao => nome.isNotEmpty ? nome : email;
}
