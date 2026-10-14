import 'package:flutter/foundation.dart';

/// Configuração de ambiente.
///
/// Sem nenhum `--dart-define`, o app é o FONAR de verdade: o login e o
/// "Criar conta" no Firebase do projeto `fonar-763db`, e o cadastro, a
/// análise e os resultados na API do Cloud Run. Nada disso é segredo — a URL
/// é pública, e a chave Web API o Firebase põe dentro de todo app cliente;
/// quem protege os dados são as regras do Firestore e a API, que conferem o
/// token de quem está na sessão.
///
/// Para desenvolver, o build ainda troca cada um:
///
/// ```
/// flutter run --dart-define=FONAR_API_BASE_URL=http://localhost:8080
/// flutter run --dart-define=FONAR_EXEMPLO=true
/// ```
///
/// O primeiro aponta para a API rodando na máquina (`uvicorn web.main:app`,
/// no `fonar-api`). O segundo é o [exemplo]: sem rede nenhuma, com o login,
/// os pacientes e os resultados de exemplo, avisados na tela.
abstract final class AppConfig {
  /// A API no Cloud Run (ver o README do `fonar-api`).
  static const _urlDeProducao =
      'https://fonar-api-97444293253.southamerica-east1.run.app';

  /// A API rodando na máquina — o destino da fila no [exemplo].
  static const _urlLocal = 'http://localhost:8080';

  static const _urlDoBuild = String.fromEnvironment('FONAR_API_BASE_URL');

  /// A "Chave de API da Web" do projeto `fonar-763db` (console do Firebase →
  /// Configurações do projeto → Geral). Deve ficar restrita, no Google Cloud
  /// Console, às APIs Identity Toolkit e Token Service (README, "Conectar ao
  /// Firebase", passo 5): é só para entrar, criar conta e renovar o token.
  static const _chaveDeProducao = 'AIzaSyDk0OOaEALIO16TwrJ3kKoTFENltlUcCY0';

  static const _chaveDoBuild = String.fromEnvironment(
    'FONAR_FIREBASE_API_KEY',
    defaultValue: _chaveDeProducao,
  );

  static bool _exemplo = const bool.fromEnvironment('FONAR_EXEMPLO');

  /// O modo de exemplo (`--dart-define=FONAR_EXEMPLO=true`): o login aceita
  /// qualquer e-mail e senha, e os pacientes e os resultados são os de
  /// exemplo — tudo avisado na tela. Serve para olhar as telas sem rede, e é
  /// como os testes rodam (`test/flutter_test_config.dart`). Um build de
  /// distribuição nesse modo se recusa a abrir (`main.dart`).
  static bool get exemplo => _exemplo;

  /// Só os testes mudam o modo depois de aberto.
  @visibleForTesting
  static void mudarModoDeExemplo({required bool ligado}) => _exemplo = ligado;

  /// A base da API: a do build, se veio; senão a de produção — ou a local,
  /// no [exemplo], que não deve mandar nada para a produção.
  static String get baseUrl => _urlDoBuild.isNotEmpty
      ? _urlDoBuild
      : (exemplo ? _urlLocal : _urlDeProducao);

  /// O app fala com uma API de verdade? Sempre, fora do [exemplo]: os
  /// resultados vêm dela, o cadastro é conferido nela, e os pacientes de
  /// exemplo somem.
  static bool get apiConfigurada => !exemplo;

  /// O projeto do Firebase: o mesmo da autenticação, do banco (Cloud
  /// Firestore) e da API. Não é segredo.
  static const firebaseProjectId = String.fromEnvironment(
    'FONAR_FIREBASE_PROJECT_ID',
    defaultValue: 'fonar-763db',
  );

  /// A chave Web API do Firebase, ou vazia no [exemplo] — aí o login é o de
  /// exemplo (ver `firebaseAuthRestProvider`).
  static String get firebaseApiKey => exemplo ? '' : _chaveDoBuild;

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
  /// Decisão da equipe (US39): cinco minutos. O caso em que esse tempo
  /// atrapalhava — a gravação longa, sem toque — não bloqueia mais: gravando,
  /// o app conta como em uso (`gravacaoEmAndamentoProvider`).
  static const tempoDeInatividade = Duration(minutes: 5);

  /// Tempo para abrir a conexão.
  static const timeoutConexao = Duration(seconds: 15);

  /// Tempo para receber a resposta. Generoso porque a análise acústica roda no
  /// servidor (parselmouth/Praat) e não é instantânea.
  static const timeoutRecebimento = Duration(seconds: 60);

  /// Tempo para enviar. Generoso porque o corpo é um WAV PCM sem compressão,
  /// possivelmente em rede de consultório.
  ///
  /// A conta: a gravação mais longa que a API aceita é de 60 s; em 44,1 kHz,
  /// 16 bits e mono são ~5,3 MB, que sobem em 5 minutos a partir de
  /// ~150 kbit/s — um 3G fraco. Abaixo disso, a fila tenta de novo depois, e
  /// nada se perde.
  static const timeoutEnvio = Duration(minutes: 5);
}
