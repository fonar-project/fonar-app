/// Nomes e caminhos das rotas, em um lugar só.
///
/// Navegue sempre por NOME (`context.goNamed(AppRoutes.capturaNome, ...)`),
/// nunca por string literal: assim mudar uma URL não quebra a navegação
/// espalhada pelas telas.
abstract final class AppRoutes {
  // Parâmetros de caminho.
  static const paramPacienteId = 'pacienteId';
  static const paramAnaliseId = 'analiseId';

  // /login
  static const loginNome = 'login';
  static const loginCaminho = '/login';

  // /criar-conta — e-mail, senha e o cadastro do profissional (US34).
  static const criarContaNome = 'criarConta';
  static const criarContaCaminho = '/criar-conta';

  // /verificar-email — a conta existe, o e-mail ainda não foi confirmado.
  static const verificarEmailNome = 'verificarEmail';
  static const verificarEmailCaminho = '/verificar-email';

  // /completar-cadastro — e-mail confirmado, cadastro por preencher.
  static const completarCadastroNome = 'completarCadastro';
  static const completarCadastroCaminho = '/completar-cadastro';

  // /recuperar-senha — "Esqueci a senha": pedir o link de redefinição (US58).
  static const recuperarSenhaNome = 'recuperarSenha';
  static const recuperarSenhaCaminho = '/recuperar-senha';

  /// As telas de quem ainda não tem sessão: só elas abrem sem sessão, e com
  /// sessão nenhuma delas tem o que fazer.
  static const caminhosDeEntrada = {
    loginCaminho,
    criarContaCaminho,
    verificarEmailCaminho,
    completarCadastroCaminho,
    recuperarSenhaCaminho,
  };

  // /pacientes
  static const pacientesNome = 'pacientes';
  static const pacientesCaminho = '/pacientes';

  // /pacientes/novo — declarada ANTES de :pacienteId, senão "novo" seria lido
  // como id de paciente.
  static const novaAvaliacaoNome = 'novaAvaliacao';
  static const novaAvaliacaoCaminho = 'novo';

  /// O mesmo caminho visto de fora da rota pai. Por ser aninhada, a declaração
  /// acima é RELATIVA ('novo'); quem precisa exibir ou comparar a URL inteira
  /// usa esta, em vez de repetir '/pacientes/novo' como literal.
  static const novaAvaliacaoCaminhoCompleto =
      '$pacientesCaminho/$novaAvaliacaoCaminho';

  // /pacientes/:pacienteId
  static const pacienteDetalheNome = 'pacienteDetalhe';
  static const pacienteDetalheCaminho = ':$paramPacienteId';

  // /pacientes/:pacienteId/editar
  static const edicaoPacienteNome = 'edicaoPaciente';
  static const edicaoPacienteCaminho = 'editar';

  // /pacientes/:pacienteId/consentimento
  static const consentimentoNome = 'consentimento';
  static const consentimentoCaminho = 'consentimento';

  // /pacientes/:pacienteId/consentimento/retirar
  static const retiradaConsentimentoNome = 'retiradaConsentimento';
  static const retiradaConsentimentoCaminho = 'retirar';

  // /pacientes/:pacienteId/gravacoes-nao-enviadas
  static const gravacoesNaoEnviadasNome = 'gravacoesNaoEnviadas';
  static const gravacoesNaoEnviadasCaminho = 'gravacoes-nao-enviadas';

  // /pacientes/:pacienteId/captura
  static const capturaNome = 'captura';
  static const capturaCaminho = 'captura';

  // /pacientes/:pacienteId/analise/:analiseId
  static const analiseResultadoNome = 'analiseResultado';
  static const analiseResultadoCaminho = 'analise/:$paramAnaliseId';

  // /pacientes/:pacienteId/analise/:analiseId/espectrograma
  static const espectrogramaNome = 'espectrograma';
  static const espectrogramaCaminho = 'espectrograma';

  // /pacientes/:pacienteId/analise/:analiseId/cape-v
  static const capeVNome = 'capeV';
  static const capeVCaminho = 'cape-v';

  // /pacientes/:pacienteId/analise/:analiseId/laudo
  static const laudoNome = 'laudo';
  static const laudoCaminho = 'laudo';

  // /pacientes/:pacienteId/evolucao
  static const evolucaoNome = 'evolucao';
  static const evolucaoCaminho = 'evolucao';

  // /pacientes/:pacienteId/evolucao/modo-paciente
  static const modoPacienteNome = 'modoPaciente';
  static const modoPacienteCaminho = 'modo-paciente';

  // /fila
  static const filaNome = 'fila';
  static const filaCaminho = '/fila';

  // /conta
  static const contaNome = 'conta';
  static const contaCaminho = '/conta';

  // /historico
  static const historicoNome = 'historico';
  static const historicoCaminho = '/historico';
}
