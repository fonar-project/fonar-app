/// Todo texto exibido na interface vive aqui, em português do Brasil.
///
/// Regra do projeto: nenhum literal de texto visível ao usuário pode ficar
/// espalhado nos widgets. Isso mantém a revisão de linguagem clínica em um
/// lugar só e prepara o caminho para internacionalização, se um dia houver.
///
/// Linguagem: o sistema é ferramenta de APOIO à decisão clínica. Nenhum texto
/// pode afirmar, sugerir ou insinuar diagnóstico. Prefira "medida", "índice",
/// "resultado da análise"; evite "normal", "alterado", "patológico".
abstract final class AppStrings {
  // ---------------------------------------------------------------- geral --
  static const appTitle = 'Praatico';

  // ----------------------------------------------------------------- telas --
  static const loginTitulo = 'Entrar';
  static const pacientesTitulo = 'Pacientes';
  static const pacienteDetalheTitulo = 'Paciente';
  static const consentimentoTitulo = 'Consentimento';
  static const capturaTitulo = 'Gravação';
  static const analiseResultadoTitulo = 'Resultado da análise';
  static const historicoTitulo = 'Histórico';

  // ---------------------------------------------------- health check / teste --
  static const healthCheckTitulo = 'Teste de conexão';
  static const healthCheckVerificando = 'Verificando conexão com o servidor…';
  static const healthCheckOnline = 'Servidor disponível';
  static const healthCheckOffline = 'Servidor indisponível';
  static const healthCheckDescricaoOnline =
      'A API está respondendo normalmente.';
  static const healthCheckDescricaoOffline =
      'Não foi possível alcançar o servidor. Verifique a rede e tente novamente.';
  static const healthCheckTempo = 'Tempo de resposta:';
  static const healthCheckVersaoApi = 'Versão da API:';
  static const healthCheckTentarNovamente = 'Verificar novamente';

  // ----------------------------------------------------------- placeholder --
  /// TODO: remover junto com [TelaPlaceholder] quando as telas reais existirem.
  static const telaEmConstrucao = 'Tela ainda não implementada.';

  // ---------------------------------------------------------------- erros --
  // Mensagens voltadas ao fonoaudiólogo: dizem o que aconteceu e o que fazer,
  // sem jargão de rede e sem código de status.
  static const erroConexao =
      'Não foi possível conectar. Verifique a rede e tente novamente.';
  static const erroTempoEsgotado =
      'O servidor demorou para responder. Tente novamente.';
  static const erroNaoAutorizado =
      'Sua sessão expirou. Entre novamente para continuar.';
  static const erroProibido = 'Você não tem acesso a este recurso.';
  static const erroNaoEncontrado = 'Não encontramos o que você procurava.';
  static const erroValidacao = 'Confira os dados informados e tente novamente.';
  static const erroServidor =
      'Houve uma falha no servidor. Tente novamente em alguns instantes.';
  static const erroEnvioCancelado = 'O envio foi cancelado.';
  static const erroDesconhecido =
      'Algo não saiu como esperado. Tente novamente.';
}
