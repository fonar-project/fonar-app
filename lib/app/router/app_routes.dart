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

  // /pacientes
  static const pacientesNome = 'pacientes';
  static const pacientesCaminho = '/pacientes';

  // /pacientes/novo — declarada ANTES de :pacienteId, senão "novo" seria lido
  // como id de paciente.
  static const novaAvaliacaoNome = 'novaAvaliacao';
  static const novaAvaliacaoCaminho = 'novo';

  // /pacientes/:pacienteId
  static const pacienteDetalheNome = 'pacienteDetalhe';
  static const pacienteDetalheCaminho = ':$paramPacienteId';

  // /pacientes/:pacienteId/consentimento
  static const consentimentoNome = 'consentimento';
  static const consentimentoCaminho = 'consentimento';

  // /pacientes/:pacienteId/captura
  static const capturaNome = 'captura';
  static const capturaCaminho = 'captura';

  // /pacientes/:pacienteId/analise/:analiseId
  static const analiseResultadoNome = 'analiseResultado';
  static const analiseResultadoCaminho = 'analise/:$paramAnaliseId';

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
