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

  /// A "Web API key" do projeto `fonar-763db` no Firebase (Configurações do
  /// projeto → Geral). Não é segredo — o Firebase a põe dentro de todo app
  /// cliente, e quem protege os dados são as regras do projeto —, mas entra
  /// por aqui para cada build apontar para o projeto certo:
  ///
  /// ```
  /// flutter run --dart-define=FONAR_FIREBASE_API_KEY=AIza...
  /// ```
  ///
  /// Sem ela, o app roda com o login de EXEMPLO, que aceita qualquer e-mail e
  /// senha e avisa disso na tela de entrada. Só em desenvolvimento: o build
  /// de distribuição sem a chave se recusa a abrir a tela de entrada (ver
  /// `repositorioAutenticacaoProvider`).
  static const firebaseApiKey = String.fromEnvironment(
    'FONAR_FIREBASE_API_KEY',
  );

  /// Versão exibida na tela de conta. Entra no build de distribuição por
  /// `--dart-define=FONAR_VERSAO=...`; sem ela, a tela diz que é versão de
  /// desenvolvimento — e não um número que ninguém conferiu.
  static const versao = String.fromEnvironment(
    'FONAR_VERSAO',
    defaultValue: 'desenvolvimento',
  );

  /// Sem nenhum toque, tecla ou rolagem por este tempo, o app bloqueia e
  /// pede a senha: o aparelho fica na mesa do consultório, aberto em dado
  /// de paciente, enquanto o profissional atende.
  ///
  /// TODO(equipe): tempo escolhido sem medir a consulta. Curto demais trava
  /// no meio do atendimento; longo demais não protege.
  static const tempoDeInatividade = Duration(minutes: 5);

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
