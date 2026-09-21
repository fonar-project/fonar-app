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
  /// Nome exibido ao usuário. O repositório, o pacote e o projeto Firebase
  /// ainda dizem "praatico" — é legado e o rename está pendente. O que aparece
  /// na tela já é FONAR.
  static const appTitle = 'FONAR';

  // ------------------------------------------------------------- conexão --
  static const conexaoOnline = 'Online';
  static const conexaoOffline = 'Sem conexão';

  // ---------------------------------------------------- status de medida --
  // O vocabulário descreve a MEDIDA comparada à faixa de referência, nunca o
  // paciente. "Alterado" e "patológico" são leitura clínica, e o sistema não
  // faz leitura clínica — ver as restrições de produto no CLAUDE.md.
  static const statusDentroDaFaixa = 'Dentro da faixa';
  static const statusLimitrofe = 'No limite da faixa';
  static const statusForaDaFaixa = 'Fora da faixa';

  /// Não existe faixa validada para este perfil de paciente e equipamento.
  /// A medida aparece; a classificação, não.
  static const statusSemReferencia = 'Sem faixa de referência';

  /// Explicação de apoio para [statusSemReferencia], em tooltip ou nota.
  static const semReferenciaExplicacao =
      'Não há faixa de referência validada para este perfil. A medida é '
      'exibida sem classificação.';

  // ----------------------------------------------------------------- telas --
  static const loginTitulo = 'Entrar';
  static const pacientesTitulo = 'Pacientes';
  static const pacienteDetalheTitulo = 'Paciente';
  static const consentimentoTitulo = 'Consentimento';
  static const capturaTitulo = 'Gravação';
  static const analiseResultadoTitulo = 'Resultado da análise';
  static const historicoTitulo = 'Histórico';
  static const novaAvaliacaoTitulo = 'Nova avaliação';
  static const filaTitulo = 'Fila de sincronização';
  static const contaTitulo = 'Conta';

  // ---------------------------------------------------------- navegação --
  // O rótulo curto é o da barra inferior do celular, onde cabem quatro abas
  // de texto sem quebrar linha.
  static const navPacientes = 'Pacientes';
  static const navNovaAvaliacao = 'Nova avaliação';
  static const navNovaAvaliacaoCurto = 'Nova';
  static const navFila = 'Fila de sincronização';
  static const navFilaCurto = 'Fila';
  static const navConta = 'Conta';

  // ------------------------------------------------------------ pacientes --
  static const pacientesBuscaDica = 'Buscar por nome ou queixa';
  static String pacientesQuantidade(int n) =>
      n == 1 ? '1 paciente' : '$n pacientes';
  static const pacientesColunaPaciente = 'Paciente · queixa';
  static const pacientesColunaUltimaSessao = 'Última sessão';
  static const pacientesColunaTendencia = 'Tendência AVQI';
  static String pacientesUltimaSessao(String data) => 'última sessão $data';
  static const pacientesNenhumaSessao = 'nenhuma sessão';
  static const pacientesNotaTendencia =
      'Tendência = comparação do AVQI nas duas últimas sessões. A seta mostra '
      'para onde o valor foi — no AVQI, descer é melhorar. Apoio à decisão; '
      'não é diagnóstico.';
  static const pacientesVaziaTitulo = 'Nenhum paciente ainda';
  static const pacientesVaziaTexto =
      'Cadastre o primeiro paciente para iniciar uma avaliação. Os dados ficam '
      'salvos neste aparelho e sincronizam quando houver conexão.';
  static const pacientesCadastrar = 'Cadastrar paciente';
  static String pacientesSemResultado(String termo) =>
      'Nenhum resultado para “$termo”';
  static const pacientesSemResultadoDica =
      'Procure por parte do nome ou da queixa — ex.: “rouquidão”.';
  static const pacientesLimparBusca = 'Limpar busca';
  static const pacientesErroCarregar =
      'Não foi possível abrir a lista de pacientes deste aparelho.';
  static const tentarNovamente = 'Tentar novamente';

  // ----------------------------------------------------- tendência AVQI --
  // TODO(clínico): "melhorando" e "piorando" vêm do protótipo e aguardam
  // revisão — é leitura da evolução, e o limiar do que conta como mudança
  // ainda não foi definido.
  static const tendenciaMelhorando = 'melhorando';
  static const tendenciaEstavel = 'estável';
  static const tendenciaPiorando = 'piorando';
  static const tendenciaSemComparacao = 'sem comparação';

  /// Rótulo do chip de tendência para leitor de tela.
  ///
  /// O chip mostra seta e palavra; o leitor de tela recebe a coluna junto,
  /// porque fora da tabela "melhorando" sozinho não diz melhorando O QUÊ.
  static String pacientesTendencia(String leitura) =>
      '$pacientesColunaTendencia: $leitura';

  // --------------------------------------------------------------- datas --
  static const _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  /// "02 jul 2026". Dia com dois dígitos para as datas alinharem em coluna.
  static String data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_meses[d.month - 1]} ${d.year}';

  // --------------------------------------------------------------- login --
  static const loginSubtitulo = 'Avaliação vocal clínica';
  static const loginDescricao =
      'Gravação guiada, medidas acústicas e evolução do paciente — como apoio à '
      'decisão do profissional. O FONAR não emite diagnóstico.';
  static const loginCampoEmail = 'E-mail';
  static const loginCampoSenha = 'Senha';
  static const loginInformeEmail = 'Informe o e-mail.';
  static const loginInformeSenha = 'Informe a senha.';
  static const loginBotaoEntrar = 'Entrar';
  static const loginBotaoEntrando = 'Entrando…';
  static const loginEntrarExigeConexao =
      'Entrar com e-mail e senha exige conexão.';
  static const loginEsqueciSenha = 'Esqueci a senha';

  /// TODO(auth): remover quando a recuperação de senha do Firebase existir.
  static const loginRecuperacaoIndisponivel =
      'Recuperação de senha ainda não disponível nesta versão (placeholder).';

  static const loginOfflineComCacheTitulo =
      'Sem conexão — dados locais disponíveis';
  static String loginOfflineComCacheTexto(int pacientes) =>
      'Este aparelho tem $pacientes '
      '${pacientes == 1 ? 'paciente salvo' : 'pacientes salvos'}. Dá para '
      'gravar e revisar; o envio para análise aguarda a conexão voltar.';
  static const loginEntrarOffline = 'Entrar em modo offline';

  static const loginOfflineSemCacheTitulo = 'Sem conexão e sem dados locais';
  static const loginOfflineSemCacheTexto =
      'Este aparelho ainda não tem pacientes salvos. Conecte-se ao menos uma '
      'vez para baixar seus pacientes e habilitar o modo offline.';
  static const loginOfflineIndisponivel = 'Modo offline indisponível';

  /// Rodapé de toda tela de entrada. O sistema é apoio à decisão e nenhum
  /// texto pode sugerir o contrário — este diz isso antes do primeiro uso.
  static const avisoApoioDecisao =
      'Ferramenta de apoio à decisão — não substitui a avaliação do '
      'profissional.';

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
  static const erroCredencialInvalida =
      'E-mail ou senha incorretos. Confira e tente novamente.';
  static const erroProibido = 'Você não tem acesso a este recurso.';
  static const erroNaoEncontrado = 'Não encontramos o que você procurava.';
  static const erroValidacao = 'Confira os dados informados e tente novamente.';
  static const erroServidor =
      'Houve uma falha no servidor. Tente novamente em alguns instantes.';
  static const erroEnvioCancelado = 'O envio foi cancelado.';
  static const erroDesconhecido =
      'Algo não saiu como esperado. Tente novamente.';
}
