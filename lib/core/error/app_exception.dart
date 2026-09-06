import '../../l10n/app_strings.dart';

/// Erros do aplicativo, já traduzidos para algo que o usuário entende.
///
/// A camada de rede converte `DioException` nestes tipos (ver
/// `ErrorInterceptor`), de modo que nenhuma camada acima precise conhecer o
/// Dio nem código de status HTTP.
///
/// Como é `sealed`, um `switch` sobre [AppException] é verificado pelo
/// analisador: ao adicionar um caso novo, todo tratamento incompleto vira erro
/// de compilação em vez de bug silencioso.
sealed class AppException implements Exception {
  const AppException(this.mensagem, {this.causa});

  /// Texto pronto para exibição, em pt-BR. Vem do [AppStrings].
  final String mensagem;

  /// Erro original, para log. NUNCA exibir ao usuário.
  final Object? causa;

  @override
  String toString() => '$runtimeType: $mensagem${causa == null ? '' : ' ($causa)'}';
}

/// Sem rede, DNS falhou, servidor inalcançável.
final class FalhaDeConexao extends AppException {
  const FalhaDeConexao({super.causa}) : super(AppStrings.erroConexao);
}

/// Conexão, envio ou recebimento estourou o tempo.
final class TempoEsgotado extends AppException {
  const TempoEsgotado({super.causa}) : super(AppStrings.erroTempoEsgotado);
}

/// 401 — sessão expirada ou credencial inválida.
final class NaoAutorizado extends AppException {
  const NaoAutorizado({super.causa}) : super(AppStrings.erroNaoAutorizado);
}

/// 403 — autenticado, mas sem acesso ao recurso.
final class Proibido extends AppException {
  const Proibido({super.causa}) : super(AppStrings.erroProibido);
}

/// 404.
final class NaoEncontrado extends AppException {
  const NaoEncontrado({super.causa}) : super(AppStrings.erroNaoEncontrado);
}

/// 400 e 422 — dados recusados pela API.
final class FalhaDeValidacao extends AppException {
  const FalhaDeValidacao({this.camposComErro = const {}, super.causa})
      : super(AppStrings.erroValidacao);

  /// Campo -> motivo, quando a API detalha. Usado para marcar o formulário.
  /// TODO: preencher quando o contrato de erro da API estiver definido.
  final Map<String, String> camposComErro;
}

/// 5xx.
final class FalhaNoServidor extends AppException {
  const FalhaNoServidor({this.statusCode, super.causa})
      : super(AppStrings.erroServidor);

  final int? statusCode;
}

/// Requisição cancelada pelo app (usuário saiu da tela, por exemplo).
final class EnvioCancelado extends AppException {
  const EnvioCancelado({super.causa}) : super(AppStrings.erroEnvioCancelado);
}

/// Não soubemos classificar. Se aparecer com frequência no log, virou caso
/// conhecido e merece um tipo próprio.
final class FalhaDesconhecida extends AppException {
  const FalhaDesconhecida({super.causa}) : super(AppStrings.erroDesconhecido);
}
