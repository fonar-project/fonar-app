/// Configuração de ambiente.
///
/// Valores entram por `--dart-define` para não versionarmos endpoint de
/// produção no repositório:
///
/// ```
/// flutter run --dart-define=FONAR_API_BASE_URL=https://...
/// ```
///
/// A API está no Cloud Run, em
/// `https://fonar-api-97444293253.southamerica-east1.run.app` (ver o README).
/// O valor padrão abaixo é o de desenvolvimento local
/// (`uvicorn web.main:app` no repositório `fonar-api`).
abstract final class AppConfig {
  static const baseUrl = String.fromEnvironment(
    'FONAR_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// O build aponta para uma API de verdade? Sem a URL, o app roda com os
  /// resultados e os pacientes de EXEMPLO, avisados na tela; com ela, os
  /// resultados vêm da API, e os exemplos somem.
  static const apiConfigurada = bool.hasEnvironment('FONAR_API_BASE_URL');

  /// O projeto do Firebase: o mesmo da autenticação, do banco (Cloud
  /// Firestore) e da API. Não é segredo.
  static const firebaseProjectId = String.fromEnvironment(
    'FONAR_FIREBASE_PROJECT_ID',
    defaultValue: 'fonar-763db',
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
