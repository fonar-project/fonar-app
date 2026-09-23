/// Configuração de ambiente.
///
/// Valores entram por `--dart-define` para não versionarmos endpoint de
/// produção no repositório:
///
/// ```
/// flutter run --dart-define=FONAR_API_BASE_URL=https://...
/// ```
///
/// TODO: apontar para a API Python no Cloud Run quando ela subir. O valor
/// padrão abaixo é placeholder de desenvolvimento local.
abstract final class AppConfig {
  static const baseUrl = String.fromEnvironment(
    'FONAR_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Versão exibida na tela de conta. Entra no build de distribuição por
  /// `--dart-define=FONAR_VERSAO=...`; sem ela, a tela diz que é versão de
  /// desenvolvimento — e não um número que ninguém conferiu.
  static const versao = String.fromEnvironment(
    'FONAR_VERSAO',
    defaultValue: 'desenvolvimento',
  );

  /// Tempo para abrir a conexão.
  static const timeoutConexao = Duration(seconds: 15);

  /// Tempo para receber a resposta. Generoso porque a análise acústica roda no
  /// servidor (parselmouth/Praat) e não é instantânea.
  static const timeoutRecebimento = Duration(seconds: 60);

  /// Tempo para enviar. Generoso porque o corpo é um WAV PCM sem compressão,
  /// possivelmente em rede de consultório.
  /// TODO: medir com arquivo real antes de fixar esse número.
  static const timeoutEnvio = Duration(minutes: 5);
}
