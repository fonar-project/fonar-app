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

  // ------------------------------------------- retirada do consentimento --
  static const retiradaTitulo = 'Retirar consentimento';
  static const retiradaAcao = 'Retirar consentimento';
  static const retiradaOQueAcontece = 'O que acontece';
  static const retiradaEfeitos = [
    'A gravação deste paciente fica bloqueada até um novo consentimento.',
    'Gravações dele que ainda estão na fila param e não sobem para a '
        'análise.',
    'O consentimento e esta retirada ficam registrados, com data e hora.',
    'Gravações, análises e laudos já feitos continuam neste aparelho.',
  ];
  static const retiradaCampoQuem = 'Quem pede a retirada';
  static const retiradaQuemApoio =
      'Quem autorizou pode retirar: o próprio paciente ou o responsável '
      'legal.';
  static const retiradaEscolhaQuem =
      'Escolha quem pede a retirada: o próprio paciente ou o responsável '
      'legal.';
  static const retiradaRegistrar = 'Registrar retirada';
  static const retiradaRegistrando = 'Registrando…';
  static const retiradaNadaARetirar =
      'Não há consentimento em vigor para retirar';
  static const retiradaVoltarAoPaciente = 'Voltar para o paciente';

  static const consentimentoRetirado = 'Consentimento retirado';
  static String consentimentoRetiradoTexto({
    required String data,
    required String hora,
    required String quem,
  }) =>
      'Em $data, às $hora, a pedido $quem. A gravação fica bloqueada até um '
      'novo consentimento.';
  static const retiradaPeloPaciente = 'do próprio paciente';
  static String retiradaPeloResponsavel(String nome) =>
      'de $nome (responsável legal)';

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
  static const afericaoLiberandoMicrofone = 'Liberando o microfone…';
  static const afericaoMicrofoneDemorando =
      'O microfone ainda não foi liberado';
  static const afericaoMicrofoneDemorandoTexto =
      'Medir de novo e gravar ficam travados até ele ser liberado. Se '
      'continuar assim, saia desta tela e entre de novo.';
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
  static const capturaRetomadaTitulo = 'Sessão de hoje retomada';
  static String capturaRetomadaTexto(String hora, int gravadas, int total) =>
      'Começada às $hora. Já gravadas: $gravadas de $total tarefas — '
      'continuam valendo. Regravar uma tarefa substitui a gravação dela.';

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
  static const tarefaFalhaInterrompida =
      'O microfone parou de responder no meio da gravação. Ela foi '
      'descartada — grave de novo.';

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
  static const filaSemConsentimento = 'Parado: consentimento retirado';
  static const filaSemConsentimentoTexto =
      'O consentimento deste paciente foi retirado, e a gravação não sobe. '
      'Só com um novo consentimento registrado dá para tentar de novo.';

  /// "4,2 s". Decimal com vírgula, como se escreve em português.
  static String segundos(Duration d) =>
      '${(d.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';

  // ------------------------------------------------ resultado da análise --
  static const resultadoExemploTitulo = 'Dados de exemplo';
  static const resultadoExemploTexto =
      'Valores fictícios, para desenvolvimento. Não correspondem a nenhum '
      'paciente.';
  static String resultadoGravadoEm(String data, String hora) =>
      'Gravado em $data, às $hora';
  static const resultadoQualidadeTitulo = 'Qualidade das amostras';
  static String resultadoAmostraAdequada(String tarefa) =>
      '$tarefa: adequada para análise';
  static String resultadoAmostraComProblema(String tarefa) =>
      '$tarefa: amostra com problema';
  static const resultadoAmostraSemMotivo = 'O servidor não detalhou o motivo.';
  static const resultadoMedidasTitulo = 'Medidas acústicas';
  static const resultadoEspectrogramaTitulo = 'Espectrograma';
  static const resultadoEspectrogramaIndisponivel =
      'Imagem ainda não disponível para esta análise.';
  static const resultadoEspectrogramaErro =
      'Não foi possível carregar a imagem. Confira a conexão.';
  static const resultadoEspectrogramaDescricao =
      'Espectrograma da gravação, gerado pelo servidor.';
  static const resultadoEspectrogramaTelaCheia = 'Ver em tela cheia';
  static const espectrogramaGireAparelho =
      'Gire o aparelho para ver o espectrograma maior.';
  static const espectrogramaAproximar = 'Aproximar';
  static const espectrogramaAjustar = 'Ajustar à tela';
  static const espectrogramaNoMaximo = 'Aproximação máxima.';
  static const espectrogramaNoTamanhoDaTela = 'Já está do tamanho da tela.';
  static const espectrogramaGestos =
      'Também dá para aproximar com dois dedos, com a roda do mouse ou com + '
      'e − no teclado, e percorrer arrastando ou com as setas.';
  static const espectrogramaAreaDica =
      'Setas percorrem; mais e menos aproximam e afastam; zero ajusta à tela.';

  static const resultadoNaoCalculada = 'Não calculada';
  static const resultadoNaoCalculadaTexto =
      'O servidor não conseguiu calcular esta medida nesta gravação.';
  static const resultadoPerfilIncompleto =
      'O cadastro do paciente não tem sexo ou data de nascimento, e a faixa '
      'depende dos dois.';
  static const resultadoSemFaixaValidada =
      'Não há faixa validada para o perfil deste paciente.';
  static String resultadoFaixa(String faixa) => 'Faixa: $faixa';
  static String resultadoProcedencia(String fonte) => 'Fonte: $fonte';

  static const resultadoProcessandoTitulo = 'Análise em processamento';
  static const resultadoProcessandoTexto =
      'O servidor ainda está calculando as medidas. Pode levar alguns '
      'minutos.';
  static const resultadoAtualizar = 'Atualizar';
  static const resultadoFalhouTitulo = 'A análise não pôde ser concluída';
  static const resultadoDeOutroPaciente = 'Esta análise não é deste paciente';
  static const resultadoDeOutroPacienteTexto =
      'O resultado aberto pertence a outro cadastro. Volte e abra a análise '
      'a partir do paciente certo.';
  static const resultadoErroCarregar =
      'Não foi possível abrir o resultado desta análise.';

  // Nome e unidade de cada medida. O valor chega pronto do servidor; aqui
  // só se decide como ele aparece.
  static const medidaAvqi = 'AVQI';
  static const medidaAvqiDescricao = 'Índice de qualidade vocal acústica';
  static const medidaCpps = 'CPPS';
  static const medidaCppsDescricao = 'Pico cepstral proeminente suavizado';
  static const medidaJitter = 'Jitter';
  static const medidaJitterDescricao = 'Perturbação da frequência';
  static const medidaShimmer = 'Shimmer';
  static const medidaShimmerDescricao = 'Perturbação da amplitude';
  static const medidaHnr = 'HNR';
  static const medidaHnrDescricao = 'Proporção harmônico-ruído';
  static const medidaF0 = 'f0';
  static const medidaF0Descricao = 'Frequência fundamental';

  /// Número em pt-BR, com vírgula decimal e sinal de menos tipográfico.
  static String numero(double valor, int casas) {
    final texto = valor.abs().toStringAsFixed(casas).replaceAll('.', ',');
    return valor < 0 ? '−$texto' : texto;
  }

  // ------------------------------------------------------------- CAPE-V --
  // TODO(clínico): nomes dos parâmetros e das opções a conferir com a versão
  // da escala adotada pelo projeto.
  static const capeVTitulo = 'Escala CAPE-V';
  static const capeVExplicacao =
      'Avaliação perceptivo-auditiva do profissional. Para cada parâmetro, '
      'marque na linha o grau do desvio: à esquerda, sem desvio; à direita, '
      'desvio extremo.';
  static const capeVGrauGeral = 'Grau geral';
  static const capeVRugosidade = 'Rugosidade';
  static const capeVSoprosidade = 'Soprosidade';
  static const capeVTensao = 'Tensão';
  static const capeVPitch = 'Pitch';
  static const capeVLoudness = 'Loudness';
  static const capeVSemDesvio = 'Sem desvio';
  static const capeVDesvioExtremo = 'Desvio extremo';
  static const capeVNaoMarcado = 'Não marcado';
  static const capeVConsistencia = 'Consistência';
  static const capeVConsistente = 'Consistente';
  static const capeVIntermitente = 'Intermitente';
  static const capeVSentido = 'Sentido do desvio';
  static const capeVPitchAbaixo = 'Mais grave';
  static const capeVPitchAcima = 'Mais agudo';
  static const capeVLoudnessAbaixo = 'Mais fraca';
  static const capeVLoudnessAcima = 'Mais forte';
  static const capeVComentarios = 'Comentários (opcional)';
  static const capeVRegistrar = 'Registrar CAPE-V';
  static const capeVRegistrando = 'Registrando…';
  static const capeVMarque = 'Marque na linha. Se não houver desvio, marque 0.';
  static const capeVEscolhaConsistencia =
      'Com desvio, escolha se é consistente ou intermitente.';
  static const capeVEscolhaSentido =
      'Com desvio, escolha o sentido: abaixo ou acima do esperado.';
  static const capeVErroCarregar =
      'Não foi possível abrir a avaliação CAPE-V desta análise.';

  // Na tela de resultado.
  static const capeVSecaoTitulo = 'Avaliação perceptivo-auditiva (CAPE-V)';
  static const capeVAindaNao = 'Ainda não registrada para esta análise.';
  static const capeVEditar = 'Editar CAPE-V';
  static String capeVRegistradaEm(String data, String hora) =>
      'Registrada em $data, às $hora.';

  // ------------------------------------------------------------ evolução --
  static const evolucaoTitulo = 'Evolução';
  static const resultadoVerEvolucao = 'Ver evolução do paciente';
  static String evolucaoSessoes(int n, String primeira, String ultima) => n == 1
      ? '1 sessão analisada, em $primeira.'
      : '$n sessões analisadas, de $primeira a $ultima.';
  static const evolucaoMedidaNoGrafico = 'Medida no gráfico';
  static String evolucaoUnidade(String unidade) => 'Valores em $unidade.';
  static const evolucaoVaziaTitulo = 'Nenhuma sessão analisada ainda';
  static const evolucaoVaziaTexto =
      'A evolução aparece depois da primeira análise concluída deste '
      'paciente. Gravação que está na fila entra quando o resultado chegar.';
  static const evolucaoErroCarregar =
      'Não foi possível abrir a evolução deste paciente.';

  static const evolucaoMaisRecente = 'Mais recente';
  static const evolucaoAnterior = 'Anterior';
  static const evolucaoUmValor =
      'Só uma sessão com esta medida calculada: ainda não há o que comparar.';
  static const evolucaoNenhumValor =
      'O servidor não calculou esta medida em nenhuma sessão.';

  /// Sem limiar de mudança validado, os valores ficam lado a lado e nenhuma
  /// frase diz que a medida subiu, desceu ou ficou estável.
  static const evolucaoSemLimiar =
      'Sem leitura de mudança: ainda não foi definido quanto uma diferença '
      'entre sessões precisa ter para contar como mudança.';
  static const evolucaoSubiu = 'subiu';
  static const evolucaoDesceu = 'desceu';
  static const evolucaoFicouEstavel = 'ficou estável';

  /// "AVQI desceu entre as duas sessões (melhorando)". A leitura entre
  /// parênteses só aparece quando a medida tem sentido de melhora.
  static String evolucaoDirecao(
    String medida,
    String direcao, {
    String? leitura,
  }) =>
      '$medida $direcao entre as duas sessões'
      '${leitura == null ? '' : ' ($leitura)'}.';

  static String evolucaoGraficoDescricao(
    String medida,
    int n,
    String primeira,
    String ultima,
  ) => n == 1
      ? 'Gráfico de $medida com uma sessão, em $primeira. O valor está na '
            'lista de sessões.'
      : 'Gráfico da evolução de $medida em $n sessões, de $primeira a '
            '$ultima. Os valores estão na lista de sessões.';
  static String evolucaoFaixaLegenda(String faixa) =>
      'Área sombreada: faixa de referência ($faixa), para o perfil do '
      'paciente na sessão mais recente.';
  static const evolucaoGireAparelho =
      'Gire o aparelho para ver o gráfico maior.';
  static const evolucaoSessoesTitulo = 'Sessões';
  static String evolucaoAbrirSessao(String data) =>
      'Abrir o resultado de $data';

  static const evolucaoMostrarAoPaciente = 'Mostrar ao paciente';

  // Modo paciente: a tela que o profissional vira para o paciente ver.
  // TODO(clínico): o que o paciente vê, e com que palavras. Hoje: o gráfico da
  // medida escolhida, as datas e os valores — sem classificação e sem leitura
  // de melhora, que são conversa do profissional com ele.
  static const modoPacienteTitulo = 'Evolução da sua voz';
  static const modoPacienteExplicacao =
      'Cada ponto é uma sessão de gravação. Quem interpreta estes números é '
      'o seu fonoaudiólogo.';
  static const modoPacienteSair = 'Voltar à tela do profissional';

  // ---------------------------------------------------- perfil do paciente --
  static const perfilErroCarregar =
      'Não foi possível abrir o perfil deste paciente.';
  static const perfilNaoEncontrado = 'Paciente não encontrado neste aparelho';
  static const perfilNaoEncontradoTexto =
      'O cadastro pode ter sido feito em outro aparelho e ainda não '
      'sincronizado.';
  static const perfilVoltarParaLista = 'Voltar para a lista';
  static String perfilQueixa(String queixa) => 'Queixa: $queixa';
  static String perfilNascimento(String data, int idade) =>
      'Nascimento: $data ($idade ${idade == 1 ? 'ano' : 'anos'})';
  static const perfilNascimentoNaoInformado = 'Nascimento: não informado';
  static String perfilSexo(String sexo) => 'Sexo: $sexo';
  static const perfilSexoNaoInformado = 'Sexo: não informado';
  static const perfilSemPerfilDeReferencia =
      'Sem sexo ou data de nascimento, as medidas aparecem sem classificação.';

  static const perfilNovaGravacao = 'Nova gravação';
  static const perfilGravacaoBloqueada =
      'Registre o consentimento para liberar a gravação.';
  static const perfilRegistrarConsentimento = 'Registrar consentimento';
  static const perfilVerEvolucao = 'Ver evolução';

  static const perfilSessoesTitulo = 'Sessões';
  static const perfilSemSessoes =
      'Nenhuma sessão analisada ainda. Depois da primeira gravação enviada, '
      'as análises aparecem aqui.';
  static String perfilNaFila(int n) => n == 1
      ? '1 gravação deste paciente aguarda envio na fila.'
      : '$n gravações deste paciente aguardam envio na fila.';
  static String perfilParadosNaFila(int n) => n == 1
      ? '1 gravação deste paciente está parada na fila: o consentimento foi '
            'retirado.'
      : '$n gravações deste paciente estão paradas na fila: o consentimento '
            'foi retirado.';
  static const perfilVerFila = 'Ver fila';
  static const perfilAnaliseProcessando = 'Em análise no servidor';
  static const perfilSemData = 'Sessão sem data';
  static const perfilAnaliseFalhou = 'Análise não concluída';
  static const perfilAmostrasAdequadas = 'Amostras adequadas';
  static const perfilAmostraComProblema = 'Amostra com problema';
  static String perfilLaudoGerado(String data) => 'Laudo gerado em $data';
  static String perfilAbrirSessao(String data) => 'Abrir o resultado de $data';

  // ------------------------------------------------------------ reprodução --
  static String reproducaoOuvir(String gravacao) => 'Ouvir: $gravacao';
  static String reproducaoPausar(String gravacao) => 'Pausar: $gravacao';
  static const reproducaoPosicao = 'Posição na gravação';
  static String reproducaoTempo(String atual, String total) =>
      '$atual / $total';
  static String reproducaoPosicaoDe(String atual, String total) =>
      '$atual de $total';
  static const reproducaoFalhou = 'Não foi possível tocar esta gravação.';

  /// O motivo do bloqueio precisa estar dito: um "ouvir" desabilitado sem
  /// explicação parece defeito.
  static const reproducaoBloqueadaGravando =
      'Para ouvir, espere a gravação terminar: o som do alto-falante entraria '
      'no microfone.';
  static const resultadoAudioIndisponivel =
      'O áudio desta análise não está neste aparelho.';

  /// "0:07", "1:23".
  static String minutosSegundos(Duration d) {
    final segundos = d.inSeconds;
    return '${segundos ~/ 60}:${(segundos % 60).toString().padLeft(2, '0')}';
  }

  // --------------------------------------------------------------- laudo --
  static const laudoTitulo = 'Laudo';
  static const resultadoPrepararLaudo = 'Preparar laudo';
  static const laudoErroCarregar =
      'Não foi possível abrir o laudo desta análise.';

  static const laudoSemPaciente = 'Paciente não encontrado neste aparelho';
  static const laudoSemPacienteTexto =
      'Sem o cadastro do paciente, o laudo sairia sem identificação. Volte e '
      'abra a análise a partir do paciente.';
  static const laudoConferenciaTitulo = 'Antes de gerar';
  static const laudoConferenciaOk = 'Resolvido';
  static const laudoConferenciaPendente = 'Pendente — impede gerar';
  static const laudoConferenciaAviso = 'Aviso — não impede gerar';

  // Cada item: o que é, e o que fazer quando não está resolvido.
  static const laudoItemConsentimento = 'Consentimento registrado';
  static const laudoItemConsentimentoFalta =
      'Não há consentimento registrado para este paciente. Registre antes de '
      'gerar o laudo.';
  static const laudoItemAnalise = 'Análise concluída';
  static const laudoItemAnaliseFalta =
      'A análise ainda não terminou no servidor.';
  static const laudoItemQualidade = 'Amostras adequadas para análise';
  static const laudoItemQualidadeAviso =
      'Alguma amostra teve problema. O laudo informa qual.';
  static const laudoItemCapeV = 'CAPE-V registrada';
  static const laudoItemCapeVAviso =
      'Sem CAPE-V, o laudo sai só com as medidas acústicas.';
  static const laudoItemConclusao = 'Conclusão do profissional';
  static const laudoItemConclusaoFalta = 'Escreva a conclusão abaixo.';

  static const laudoIrParaConsentimento = 'Registrar consentimento';
  static const laudoIrParaCapeV = 'Registrar CAPE-V';

  static const laudoCampoConclusao = 'Conclusão do profissional';
  static const laudoConclusaoApoio =
      'Escrita por você. O FONAR não escreve nem sugere conclusão.';

  static const laudoGerar = 'Gerar laudo';
  static const laudoGerando = 'Gerando…';
  static const laudoGerarBloqueado =
      'Resolva os itens pendentes da conferência para gerar.';
  static String laudoGeradoEm(String data, String hora) =>
      'Laudo gerado em $data, às $hora.';
  static const laudoTextoMudou =
      'A conclusão mudou depois da última geração. Gere de novo para o PDF '
      'incluir a mudança.';
  static const laudoCompartilhar = 'Abrir ou compartilhar o PDF';
  static const laudoImprimir = 'Imprimir ou salvar em PDF';
  static const laudoErroGerar =
      'Não foi possível gerar o laudo. Tente de novo.';
  static const laudoErroSaida =
      'Não foi possível abrir o PDF neste aparelho. Tente de novo.';

  static const laudoPreviaTitulo = 'Pré-visualização';
  static const laudoResumoTitulo = 'O que vai no laudo';
  static String laudoResumoMedidas(int n) =>
      n == 1 ? '1 medida acústica' : '$n medidas acústicas';
  static const laudoResumoComCapeV = 'Avaliação CAPE-V';
  static const laudoResumoSemCapeV = 'Sem avaliação CAPE-V';
  static const laudoResumoConclusao = 'Conclusão do profissional';
  static const laudoResumoSemConclusao = 'Conclusão ainda não escrita';

  // No documento.
  static const laudoDocTitulo = 'Laudo de avaliação vocal';
  static const laudoDocRascunho =
      'RASCUNHO — pré-visualização, ainda não gerado';
  static const laudoDocExemplo =
      'DADOS DE EXEMPLO — documento sem valor clínico';
  static const laudoDocIdentificacao = 'Identificação';
  static const laudoDocPaciente = 'Paciente';
  static const laudoDocNascimento = 'Data de nascimento';
  static const laudoDocSexo = 'Sexo';
  static const laudoDocNaoInformado = 'Não informado';
  static const laudoDocGravacao = 'Data da gravação';
  static const laudoDocMedidas = 'Medidas acústicas';
  static const laudoDocColunaMedida = 'Medida';
  static const laudoDocColunaValor = 'Valor';
  static const laudoDocColunaFaixa = 'Faixa de referência';
  static const laudoDocColunaSituacao = 'Situação';
  static const laudoDocSemFaixa = '—';
  static const laudoDocQualidade = 'Qualidade das amostras';
  static const laudoDocCapeV = 'Avaliação perceptivo-auditiva (CAPE-V)';
  static const laudoDocCapeVNaoRegistrada = 'Não registrada nesta sessão.';
  static const laudoDocColunaParametro = 'Parâmetro';
  static const laudoDocColunaNota = 'Nota (0–100)';
  static const laudoDocColunaConsistencia = 'Consistência';
  static const laudoDocColunaSentido = 'Sentido';
  static const laudoDocComentarios = 'Comentários';
  static const laudoDocConclusao = 'Conclusão do profissional';
  static String laudoDocGeradoEm(String data, String hora) =>
      'Gerado em $data, às $hora.';

  /// Rodapé de toda página: de onde vêm as medidas e de quem é a conclusão.
  static const laudoDocRodape =
      'Medidas acústicas calculadas no servidor com o motor do Praat. '
      'Ferramenta de apoio à decisão: a interpretação e a conclusão são do '
      'profissional que assina.';
  static String laudoDocPagina(int atual, int total) =>
      'Página $atual de $total';

  /// Sem o nome do paciente, de propósito: o nome do arquivo aparece em
  /// pasta, e-mail e histórico de compartilhamento.
  static String laudoNomeDoArquivo(DateTime d) =>
      'laudo-fonar-${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}.pdf';

  // --------------------------------------------------------------- conta --
  static const contaSeusDados = 'Seus dados';
  static const contaSeusDadosApoio =
      'Nome e registro vão impressos na assinatura dos laudos.';
  static const contaCampoNome = 'Nome, como assina';
  static const contaCampoRegistro = 'Registro no conselho';
  static const contaRegistroDica = 'ex.: CRFa 2-12345';
  static const contaCampoEmail = 'E-mail da conta';
  static const contaInformeNome = 'Informe o nome como deve sair no laudo.';
  static const contaInformeRegistro =
      'Informe o registro no conselho — ele vai no laudo.';
  static const contaSalvar = 'Salvar alterações';
  static const contaSalvando = 'Salvando…';
  static const contaNadaMudou = 'Nenhuma alteração para salvar.';
  static const contaSalvo = 'Dados salvos.';

  static const contaNesteAparelho = 'Neste aparelho';
  static String contaEnviosPendentes(int n) => switch (n) {
    0 => 'Nenhum envio aguardando na fila.',
    1 => '1 envio aguardando na fila.',
    _ => '$n envios aguardando na fila.',
  };
  static const contaVerFila = 'Ver fila';

  static const contaSobre = 'Sobre o FONAR';
  static const contaSobreTexto =
      'Ferramenta de apoio à decisão para avaliação vocal. O FONAR não emite '
      'diagnóstico: medidas, escalas e laudos são lidos e assinados pelo '
      'profissional.';
  static const contaSobrePraat =
      'As medidas acústicas são calculadas no servidor com o motor do Praat, '
      'por meio do parselmouth. Nenhuma análise acontece neste aparelho.';
  static String contaVersao(String versao) => 'Versão: $versao';
  static const contaLicencas = 'Licenças de software';

  static const contaSair = 'Sair da conta';
  static const contaSairPergunta = 'Sair da conta neste aparelho?';

  // TODO(jurídico): o que fica no aparelho depois de sair — hoje pacientes,
  // gravações e fila continuam guardados.
  // TODO(auth): "quando você entrar de novo" só é verdade de fato quando cada
  // envio levar o id de quem gravou; ver `Sessao`.
  static const contaSairTexto =
      'Pacientes, gravações e laudos continuam guardados neste aparelho.';
  static String contaSairComFila(int n) => n == 1
      ? 'Há 1 envio na fila. Ele pausa, fica neste aparelho e volta a subir '
            'quando você entrar de novo.'
      : 'Há $n envios na fila. Eles pausam, ficam neste aparelho e voltam a '
            'subir quando você entrar de novo.';
  static const contaConfirmarSair = 'Sair';
  static const contaCancelar = 'Cancelar';
  static const contaSaindo = 'Saindo…';

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

  /// "02 jul", ou "02 jul 26" com [comAno] — para eixo de gráfico, onde a
  /// data inteira não cabe.
  static String dataCurta(DateTime d, {bool comAno = false}) {
    final base = '${d.day.toString().padLeft(2, '0')} ${_meses[d.month - 1]}';
    return comAno ? '$base ${(d.year % 100).toString().padLeft(2, '0')}' : base;
  }

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
