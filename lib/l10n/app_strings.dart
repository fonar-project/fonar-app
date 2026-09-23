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
  /// Nome exibido ao usuário.
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

  // ------------------------------------------------ cadastro de paciente --
  static const cadastroTitulo = 'Novo paciente';
  static const cadastroDescricao =
      'Preencha o perfil para iniciar a avaliação. Em seguida vêm o registro '
      'do consentimento e a gravação.';
  static const cadastroCampoNome = 'Nome completo';
  static const cadastroCampoNascimento = 'Data de nascimento';
  static const cadastroNascimentoDica = 'dd/mm/aaaa';
  static const cadastroCampoSexo = 'Sexo';
  static const cadastroSexoFeminino = 'Feminino';
  static const cadastroSexoMasculino = 'Masculino';
  static const cadastroSexoNaoInformado = 'Não informar';

  /// Diz para que serve a pergunta, e o que acontece sem resposta — a
  /// consequência de "Não informar" precisa estar dita antes da escolha.
  static const cadastroSexoApoio =
      'Usado só para escolher a faixa de referência das medidas. Sem esta '
      'informação, as medidas aparecem sem classificação.';
  static const cadastroCampoQueixa = 'Queixa principal';
  static const cadastroQueixaDica = 'ex.: rouquidão ao fim do dia';
  static const cadastroSalvar = 'Salvar e continuar';
  static const cadastroSalvando = 'Salvando…';
  static const cadastroCancelar = 'Cancelar';
  static const cadastroSalvoNoAparelho =
      'O cadastro fica salvo neste aparelho e sincroniza quando houver '
      'conexão.';

  // Erros de campo: dizem o que fazer, não só o que está errado.
  static const cadastroInformeNome = 'Informe o nome do paciente.';
  static const cadastroInformeNascimento =
      'Informe a data de nascimento: dia, mês e ano.';
  static const cadastroNascimentoInvalido =
      'Data inexistente. Confira dia, mês e ano — ex.: 02/07/1985.';
  static const cadastroNascimentoNoFuturo =
      'A data de nascimento está no futuro. Confira o ano.';
  static String cadastroNascimentoImplausivel(int anos) =>
      'A data indica mais de $anos anos. Confira o ano.';
  static const cadastroEscolhaSexo =
      'Escolha uma opção. Se o paciente preferir, use “Não informar”.';
  static const cadastroInformeQueixa = 'Informe a queixa principal.';

  // --------------------------------------------------------- consentimento --
  static const voltar = 'Voltar';
  static String consentimentoPaciente(String nome) => 'Paciente: $nome';
  static const consentimentoMostreAoPaciente =
      'Mostre esta tela ao paciente, ou leia o termo em voz alta.';

  // TODO(jurídico): TEXTO PROVISÓRIO do termo, escrito para o fluxo funcionar
  // — não foi revisado juridicamente e não deve ir para produção assim. Ao
  // trocar, mude também `versaoAtualDoTermo` no repositório de consentimento.
  static const consentimentoTermoTitulo =
      'Termo de consentimento (texto provisório)';
  static const consentimentoTermoItens = [
    'Sua voz será gravada durante esta consulta.',
    'A gravação é enviada a um servidor, que calcula medidas acústicas da '
        'voz. O profissional usa essas medidas como apoio à avaliação; o '
        'sistema não emite diagnóstico.',
    'A gravação e as medidas ficam vinculadas ao seu cadastro. Voz é dado '
        'pessoal sensível e é tratada conforme a LGPD.',
    'Você pode retirar este consentimento a qualquer momento, pedindo ao '
        'profissional.',
  ];

  static const consentimentoCampoQuem = 'Quem autoriza';
  static const consentimentoQuemPaciente = 'O próprio paciente';
  static const consentimentoQuemResponsavel = 'Responsável legal';
  static const consentimentoQuemApoio =
      'Quando o paciente não pode autorizar sozinho — por exemplo, uma '
      'criança —, quem autoriza é o responsável legal.';
  static const consentimentoCampoResponsavel = 'Nome do responsável legal';
  static const consentimentoConcordancia =
      'Quem autoriza leu ou ouviu o termo e concorda com a gravação e com o '
      'envio para análise.';
  static const consentimentoRegistrar = 'Registrar consentimento';
  static const consentimentoRegistrando = 'Registrando…';

  static const consentimentoNaoRegistrado = 'Consentimento não registrado';
  static const consentimentoNaoRegistradoTexto =
      'A gravação fica bloqueada até o consentimento ser registrado.';
  static const consentimentoRegistrado = 'Consentimento registrado';
  static String consentimentoRegistradoTexto({
    required String data,
    required String hora,
    required String quem,
    required String versao,
  }) => 'Em $data, às $hora, $quem. Versão do termo: $versao.';
  static const consentimentoPeloPaciente = 'pelo próprio paciente';
  static String consentimentoPeloResponsavel(String nome) =>
      'por $nome (responsável legal)';
  static const consentimentoIniciarGravacao = 'Iniciar gravação';

  static const consentimentoErroCarregar =
      'Não foi possível verificar o consentimento deste paciente.';
  static const consentimentoPacienteNaoEncontrado =
      'Paciente não encontrado neste aparelho';
  static const consentimentoVoltarParaLista = 'Voltar para a lista';

  static const consentimentoEscolhaQuem =
      'Escolha quem autoriza: o próprio paciente ou o responsável legal.';
  static const consentimentoInformeResponsavel =
      'Informe o nome do responsável legal.';
  static const consentimentoMarqueConcordancia =
      'Marque a concordância para registrar. Sem ela, a gravação continua '
      'bloqueada.';

  // -------------------------------------------------- captura / medidor --
  static const medidorRotulo = 'Nível do microfone';
  static const medidorSemSinal = 'Sem sinal';
  static const medidorBaixo = 'Baixo';
  static const medidorAdequado = 'Sinal adequado';
  static const medidorAlto = 'Alto';
  static const medidorSaturando = 'Saturando';

  /// Na aferição de ruído: diz o que é o número, sem julgar a sala — quem
  /// julga é a conclusão, ao fim dos 5 segundos.
  static const medidorAmbiente = 'Ruído da sala';

  /// "−42 dBFS". Sinal de menos tipográfico, que não quebra do número.
  static String nivelDbfs(double dbfs) => dbfs.isFinite
      ? '${dbfs < -0.5 ? '−' : ''}${dbfs.abs().round()} dBFS'
      : '— dBFS';

  static const afericaoTitulo = 'Ruído ambiente';
  static const afericaoExplicacao =
      'Antes de gravar, o FONAR mede o ruído da sala por 5 segundos. Peça '
      'silêncio e deixe o aparelho na posição em que vai gravar.';
  static const afericaoMedir = 'Medir ruído ambiente';
  static const afericaoMedirDeNovo = 'Medir de novo';
  static const afericaoMedindo = 'Medindo… mantenha silêncio.';
  static const afericaoEsperaGravacao =
      'Termine a gravação em andamento para medir de novo.';

  static const afericaoSemPermissao = 'Sem permissão de microfone';
  static const afericaoSemPermissaoTexto =
      'Permita o uso do microfone pelo FONAR nas configurações do aparelho e '
      'tente de novo.';
  static const afericaoFalhou = 'Não foi possível abrir o microfone';
  static const afericaoFalhouTexto =
      'Confira se outro aplicativo está usando o microfone e tente de novo.';

  static const afericaoMudo = 'O microfone não está captando som';

  /// Diz o que fazer nas duas plataformas, sem perguntar qual é: o texto é o
  /// mesmo em qualquer aparelho, e quem está num lê a sua parte.
  static const afericaoMudoTexto =
      'A gravação fica bloqueada até o microfone captar som. No Windows, abra '
      'Configurações > Privacidade e segurança > Microfone e ative o acesso '
      'ao microfone, inclusive para aplicativos da área de trabalho. No '
      'Android, confira a permissão de microfone do FONAR. Depois, meça de '
      'novo.';
  static const afericaoRuidoAlto = 'Ruído ambiente acima do limite';
  static String afericaoRuidoAltoTexto(String nivel, String limite) =>
      'Nível típico da sala: $nivel (limite: $limite). Feche portas e '
      'janelas, desligue ventilador ou ar-condicionado e meça de novo.';
  static const afericaoSemRestricao = 'Ruído ambiente dentro do limite';
  static String afericaoSemRestricaoTexto(String nivel) =>
      'Nível típico da sala: $nivel.';

  static const afericaoAjusteTitulo = 'O aparelho mudou o formato da captura';
  static String afericaoAjusteTexto({
    required int taxaUsada,
    required int canaisUsados,
    required int taxaPedida,
    required int canaisPedidos,
  }) =>
      'Pedido: $taxaPedida Hz, $canaisPedidos '
      '${canaisPedidos == 1 ? 'canal' : 'canais'}. Usado: $taxaUsada Hz, '
      '$canaisUsados ${canaisUsados == 1 ? 'canal' : 'canais'}. Avise o '
      'suporte antes de usar este aparelho em consulta.';

  static const capturaIniciarGravacao = 'Iniciar gravação';
  static const capturaBloqueadaMicrofone =
      'Bloqueada: o microfone não está captando som.';
  static const capturaBloqueadaSemAfericao =
      'Meça o ruído ambiente antes de gravar.';

  // --------------------------------------------------- gravação das tarefas --
  static const tarefasTitulo = 'Tarefas';

  // TODO(clínico): instruções PROVISÓRIAS, escritas para o fluxo funcionar.
  // As tarefas, a ordem e o texto dito ao paciente são do protocolo clínico e
  // precisam de revisão da orientação.
  static const tarefaVogalTitulo = 'Vogal sustentada /a/';
  static const tarefaVogalInstrucao =
      'Peça ao paciente para sustentar a vogal /a/, em altura e intensidade '
      'confortáveis, pelo tempo que conseguir. (instrução provisória)';
  static const tarefaFalaTitulo = 'Fala encadeada';
  static const tarefaFalaInstrucao =
      'Peça ao paciente para falar de forma encadeada, conforme o protocolo '
      'da clínica. (instrução provisória)';

  static const tarefaGravar = 'Gravar';
  static const tarefaGravarDeNovo = 'Gravar de novo';
  static const tarefaParar = 'Parar';
  static String tarefaGravando(String duracao) => 'Gravando… $duracao';
  static const tarefaConferindo = 'Conferindo o arquivo gravado…';
  static const tarefaOutraEmAndamento =
      'Termine a gravação em andamento para gravar esta.';

  static String tarefaGravada(String duracao) => 'Gravada — $duracao';
  static const tarefaGravadaTexto = 'Arquivo conferido: WAV PCM, sem ressalva.';
  static String tarefaGravadaComRessalva(String duracao) =>
      'Gravada com ressalva — $duracao';
  static const tarefaDescartada = 'Última gravação descartada';
  static const tarefaDescartadaMantida =
      'A gravação anterior desta tarefa continua guardada.';

  static const tarefaFalhaTitulo = 'A gravação não aconteceu';
  static const tarefaFalhaPermissao =
      'Sem permissão de microfone. Permita o uso do microfone pelo FONAR nas '
      'configurações do aparelho e tente de novo.';
  static const tarefaFalhaIniciar =
      'Não foi possível começar a gravar. Confira se outro aplicativo está '
      'usando o microfone e tente de novo.';
  static const tarefaFalhaFinalizar =
      'A gravação não pôde ser finalizada e foi descartada. Grave de novo.';

  // O que a conferência encontrou. Diz o que fazer, não só o que houve.
  static const problemaArquivoIlegivel =
      'O arquivo gravado não pôde ser lido. Grave de novo.';
  static const problemaNaoEPcm =
      'O aparelho gravou em formato comprimido, e não em WAV PCM. Avise o '
      'suporte antes de usar este aparelho em consulta.';
  static const problemaBitsDiferentes =
      'O aparelho gravou com resolução diferente de 16 bits. Avise o suporte '
      'antes de usar este aparelho em consulta.';
  static const problemaIncompleto =
      'A gravação foi interrompida e o arquivo ficou incompleto. Grave de '
      'novo.';
  static const problemaCurtaDemais =
      'A gravação ficou com menos de 1 segundo. Grave de novo.';
  static const problemaSemSinal =
      'O microfone não captou som durante a gravação. Confira o acesso ao '
      'microfone, meça o ruído de novo e grave outra vez.';
  static const problemaSaturou =
      'Houve saturação: a voz passou do máximo do microfone. Se possível, '
      'afaste um pouco o microfone e grave de novo.';
  static const problemaFormatoAjustado =
      'O aparelho gravou com taxa ou canais diferentes dos pedidos. Avise o '
      'suporte antes de usar este aparelho em consulta.';

  static const capturaEnviar = 'Enviar para análise';
  static const capturaEnviando = 'Pondo na fila…';
  static const capturaEnviarFaltaTarefa = 'Grave todas as tarefas para enviar.';
  static const capturaEnviarApoio =
      'Funciona sem conexão: a gravação fica na fila e sobe quando a rede '
      'voltar.';

  // ---------------------------------------------- fila de sincronização --
  static const filaVaziaTitulo = 'Nada na fila';
  static const filaVaziaTexto =
      'Gravações mandadas para análise aparecem aqui até chegarem ao '
      'servidor.';
  static const filaIrParaPacientes = 'Ir para pacientes';
  static String filaResumo(int pendentes) => pendentes == 0
      ? 'Tudo enviado'
      : pendentes == 1
      ? '1 envio pendente'
      : '$pendentes envios pendentes';
  static const filaSemConexaoTitulo = 'Envios parados até a rede voltar';
  static const filaSemConexaoTexto =
      'Os envios seguem sozinhos quando a rede voltar. As gravações estão '
      'guardadas neste aparelho.';
  static String filaGravacoes(int n, String data) =>
      '${n == 1 ? '1 gravação' : '$n gravações'} · $data';

  static const filaNaFila = 'Na fila';
  static const filaNaFilaTexto = 'Sobe assim que chegar a vez.';
  static const filaAguardandoConexao = 'Aguardando conexão';
  static const filaAguardandoConexaoTexto =
      'Sobe sozinho quando a rede voltar.';
  static const filaEnviando = 'Enviando…';
  static const filaEnviandoTexto =
      'Pode continuar usando o app; o envio segue em segundo plano.';
  static const filaFalhou = 'O envio falhou';
  static String filaFalhouTexto(String motivo, String hora) =>
      '$motivo Nova tentativa automática às $hora.';
  static const filaSessaoExpirada = 'Sessão expirada';
  static const filaSessaoExpiradaTexto =
      'Entre novamente para o envio continuar. A gravação continua guardada.';
  static const filaRecusado = 'A análise recusou o envio';
  static String filaRecusadoTexto(String motivo) =>
      '$motivo A gravação continua guardada neste aparelho. Se tentar de novo '
      'não resolver, avise o suporte.';
  static const filaEnviado = 'Enviado';
  static const filaEnviadoTexto = 'A análise foi recebida pelo servidor.';
  static const filaTentarAgora = 'Tentar agora';
  static const filaTentarDeNovo = 'Tentar de novo';
  static const filaTentarExigeConexao = 'Disponível quando houver conexão.';
  static const filaVerResultado = 'Ver resultado';

  /// "4,2 s". Decimal com vírgula, como se escreve em português.
  static String segundos(Duration d) =>
      '${(d.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';

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

  /// "09:05".
  static String hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

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
