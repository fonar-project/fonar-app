/// Todo texto exibido na interface vive aqui, em português do Brasil.
///
/// Regra do projeto: nenhum literal de texto visível ao usuário pode ficar
/// espalhado nos widgets. Isso mantém a revisão de linguagem clínica em um
/// lugar só e prepara o caminho para internacionalização, se um dia houver.
///
/// Registro: formal e técnico, com frases completas e sem ambiguidade — ver
/// "Redação" no CLAUDE.md (US64).
///
/// Linguagem: o sistema é ferramenta de APOIO à decisão clínica. Nenhum texto
/// pode afirmar, sugerir ou insinuar diagnóstico. Prefira "medida", "índice",
/// "resultado da análise"; evite "normal", "alterado", "patológico".
abstract final class AppStrings {
  // ---------------------------------------------------------------- geral --
  /// Nome exibido ao usuário.
  static const appTitle = 'FONAR';

  // ------------------------------------------------------- rota de erro --
  static const rotaNaoEncontradaTitulo = 'Página não encontrada';
  static const rotaNaoEncontradaTexto =
      'O endereço solicitado não existe, ou o conteúdo correspondente não está '
      'mais disponível neste aparelho.';
  static const rotaVoltarAoInicio = 'Voltar aos pacientes';

  // ------------------------------------------------------ campo de texto --
  /// O olho do campo de senha (US46): diz o que o toque faz.
  static const campoMostrarSenha = 'Mostrar senha';
  static const campoOcultarSenha = 'Ocultar senha';

  // ------------------------------------------------------------- conexão --
  static const conexaoOnline = 'Online';
  static const conexaoOffline = 'Sem conexão';

  /// Há rede, mas a última chamada não chegou ao servidor — Wi-Fi com portal
  /// cativo, por exemplo (US06).
  static const conexaoSemServidor = 'Sem acesso ao servidor';

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
  static const capturaTitulo = 'Nova avaliação';
  static const analiseResultadoTitulo = 'Resultado da análise';

  // Pílulas de situação no cabeçalho das telas de tarefa, no desktop.
  static const situacaoApoioADecisao = 'Apoio à decisão — não é diagnóstico';
  static const situacaoCapeV = 'Registro perceptivo — não é diagnóstico';
  static const situacaoLaudo =
      'Apoio à decisão — o laudo é de responsabilidade do profissional';
  static const situacaoConsentimentoRegistrado = 'Consentimento registrado';
  static const situacaoFila =
      'Dados salvos no aparelho — preservados mesmo sem conexão';
  static const historicoTitulo = 'Histórico';
  static const historicoDescricao =
      'Avaliações realizadas neste aparelho, da mais recente para a mais '
      'antiga.';
  static const historicoBuscaDica = 'Buscar por paciente ou queixa';
  static const historicoVazioTitulo = 'Nenhuma avaliação ainda';
  static const historicoVazioTexto =
      'As avaliações serão exibidas aqui após o envio da primeira gravação.';
  static String historicoSemResultado(String termo) =>
      'Nenhuma avaliação de paciente com "$termo".';
  static const historicoLimparBusca = 'Limpar busca';
  static const historicoErroCarregar = 'Não foi possível carregar o histórico.';
  static const historicoSemData = 'Data a confirmar';
  static const historicoProcessando = 'Em análise no servidor';
  static const historicoFalhou = 'A análise falhou';
  static const historicoAvqiNaoCalculado = 'AVQI não calculado';
  static const historicoLaudoGerado = 'Laudo gerado';
  static String historicoAbrir(String paciente, String data) =>
      'Abrir a avaliação de $paciente, $data';
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
  static const navHistorico = 'Histórico';

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
      'Tendência: comparação do AVQI entre as duas sessões mais recentes. A '
      'seta indica o sentido da variação do valor; no AVQI, a redução do valor '
      'corresponde a melhora. Informação de apoio à decisão, sem caráter '
      'diagnóstico.';
  static const pacientesVaziaTitulo = 'Nenhum paciente ainda';
  static const pacientesVaziaTexto =
      'Cadastre o primeiro paciente para iniciar uma avaliação. Os dados são '
      'salvos neste aparelho e sincronizados com o servidor quando houver '
      'conexão.';
  static const pacientesCadastrar = 'Cadastrar paciente';
  static String pacientesSemResultado(String termo) =>
      'Nenhum resultado para “$termo”';
  static const pacientesSemResultadoDica =
      'Pesquise por parte do nome ou da queixa (por exemplo, “rouquidão”).';
  static const pacientesLimparBusca = 'Limpar busca';
  static const pacientesErroCarregar =
      'Não foi possível abrir a lista de pacientes deste aparelho.';
  static const tentarNovamente = 'Tentar novamente';

  // ------------------------------------------------ cadastro de paciente --
  static const cadastroTitulo = 'Novo paciente';
  static const cadastroDescricao =
      'Preencha os dados do paciente para iniciar a avaliação. As etapas '
      'seguintes são o registro do consentimento e a gravação.';
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
      'Informação utilizada exclusivamente para selecionar a faixa de '
      'referência das medidas. Sem ela, as medidas são exibidas sem '
      'classificação.';
  static const cadastroCampoQueixa = 'Queixa principal';
  static const cadastroQueixaDica = 'por exemplo: rouquidão ao final do dia';
  static const cadastroSalvar = 'Salvar e continuar';
  static const cadastroSalvando = 'Salvando…';
  static const cadastroCancelar = 'Cancelar';
  static const cadastroSalvoNoAparelho =
      'O cadastro é salvo neste aparelho e sincronizado com o servidor quando '
      'houver conexão.';

  // Erros de campo: dizem o que fazer, não só o que está errado.
  static const cadastroInformeNome = 'Informe o nome do paciente.';
  static const cadastroInformeNascimento =
      'Informe a data de nascimento: dia, mês e ano.';
  static const cadastroNascimentoInvalido =
      'Data inexistente. Verifique o dia, o mês e o ano (por exemplo, '
      '02/07/1985).';
  static const cadastroNascimentoNoFuturo =
      'A data de nascimento informada é posterior à data atual. Verifique o '
      'ano.';
  static String cadastroNascimentoImplausivel(int anos) =>
      'A data informada corresponde a mais de $anos anos de idade. Verifique '
      'o ano.';
  static const cadastroEscolhaSexo =
      'Selecione uma opção. Caso o paciente prefira não responder, selecione '
      '“Não informar”.';
  static const cadastroInformeQueixa = 'Informe a queixa principal.';

  // ------------------------------------------------ sair sem salvar --
  static const saidaTitulo = 'Sair sem salvar?';
  static const saidaTexto =
      'As informações preenchidas nesta tela ainda não foram salvas e serão '
      'perdidas.';
  static const saidaDescartar = 'Sair e descartar';
  static const saidaContinuar = 'Continuar preenchendo';

  // ------------------------------------------------ paciente duplicado --
  static const duplicadoTitulo =
      'Já existe um paciente com este nome e data de nascimento';
  static String duplicadoTexto(String nome, String nascimento) =>
      '$nome, com nascimento em $nascimento. Se for a mesma pessoa, abra o '
      'cadastro existente: manter dois cadastros divide o histórico do '
      'paciente.';
  static const duplicadoAbrirExistente = 'Abrir o cadastro existente';
  static const duplicadoSalvarMesmoAssim = 'Salvar como outro paciente';

  // ---------------------------------------------- edição dos dados --
  static const edicaoTitulo = 'Editar dados do paciente';
  static const edicaoSalvar = 'Salvar alterações';
  static const edicaoAvisoTitulo =
      'O sexo e a data de nascimento determinam a faixa de referência';
  static const edicaoAvisoTexto =
      'A alteração destes dados modifica a classificação das medidas em todas '
      'as sessões deste paciente. Os laudos já emitidos permanecem '
      'inalterados.';
  static const edicaoExemplo =
      'Paciente de exemplo: os dados não podem ser editados.';

  // --------------------------------------------------------- consentimento --
  static const voltar = 'Voltar';
  static String consentimentoPaciente(String nome) => 'Paciente: $nome';
  static const consentimentoMostreAoPaciente =
      'Apresente esta tela ao paciente ou leia o termo em voz alta.';

  // O termo de consentimento (US43), escrito sobre a LGPD: consentimento
  // específico e em destaque para dado de saúde (art. 11, I) e para a
  // transferência internacional (art. 33, VIII), com finalidade, guarda,
  // direitos e retirada. Ao mudar qualquer palavra, mude também
  // `versaoAtualDoTermo` (repositório de consentimento): cada registro diz
  // com qual texto a pessoa concordou. Revisão jurídica recomendada antes
  // do uso com pacientes (PENDENCIAS.md).
  static const consentimentoTermoTitulo = 'Termo de consentimento';
  static const consentimentoTermoItens = [
    'O que será gravado: a sua voz, durante esta consulta, por meio de uma '
        'vogal sustentada e de uma fala curta. Também serão registrados os '
        'seus dados cadastrais (nome, data de nascimento, sexo e queixa), as '
        'medidas calculadas a partir da gravação e a avaliação realizada pelo '
        'profissional.',
    'Finalidade: avaliar a sua voz e acompanhar a sua evolução nas consultas '
        'seguintes. As medidas servem de apoio ao julgamento do profissional '
        'responsável pelo seu atendimento; o sistema não realiza diagnóstico.',
    'Responsável pelos dados: o profissional que realiza o seu atendimento. '
        'O FONAR é a ferramenta utilizada por ele e trata os dados '
        'exclusivamente para essa finalidade, em nome do profissional. Os '
        'dados não são vendidos nem utilizados para qualquer outra finalidade.',
    'Local de armazenamento: a gravação é enviada, por conexão cifrada, a '
        'servidores do Google Cloud, onde as medidas são calculadas. O '
        'cadastro e as medidas ficam armazenados no Brasil (São Paulo); o '
        'arquivo da gravação fica armazenado nos Estados Unidos. A '
        'concordância com este termo inclui essa transferência internacional '
        'de dados.',
    'Prazo de guarda: os dados serão mantidos enquanto forem necessários ao '
        'seu atendimento e pelo prazo em que o profissional tem o dever de '
        'guardar o registro do atendimento (prontuário).',
    'Seus direitos: você pode solicitar ao profissional o acesso, a correção '
        'ou a eliminação dos seus dados, bem como informações sobre com quem '
        'eles são compartilhados (LGPD, art. 18). A voz vinculada à sua '
        'identidade é dado pessoal sensível.',
    'Retirada do consentimento: você pode retirar este consentimento a '
        'qualquer momento, mediante solicitação ao profissional. A partir da '
        'retirada, nenhuma nova gravação ou análise será realizada; o que já '
        'tiver sido feito permanece no registro do atendimento, salvo se você '
        'solicitar a eliminação.',
    'Recusa: a recusa em consentir não impede o atendimento; apenas a '
        'gravação e as medidas acústicas deixam de ser realizadas. Quem '
        'autoriza na condição de responsável legal declara possuir essa '
        'responsabilidade pelo paciente.',
  ];

  static const consentimentoCampoQuem = 'Quem autoriza';
  static const consentimentoQuemPaciente = 'O próprio paciente';
  static const consentimentoQuemResponsavel = 'Responsável legal';
  static const consentimentoQuemApoio =
      'Quando o paciente não puder autorizar por si — por exemplo, no caso de '
      'uma criança —, a autorização deve ser dada pelo responsável legal.';
  // US43: eliminação dos dados, a pedido do paciente (LGPD, art. 18, VI).
  static const perfilEliminarTitulo = 'Eliminar os dados do paciente';
  static const perfilEliminarTexto =
      'Procedimento realizado a pedido do paciente (LGPD, art. 18). Exclui '
      'definitivamente, deste aparelho e do servidor, o cadastro, os '
      'consentimentos, as gravações, as análises, a CAPE-V, os laudos e as '
      'anotações.';
  static const perfilEliminarAcao = 'Eliminar os dados';
  static String perfilEliminarConfirmarTitulo(String nome) =>
      'Eliminar os dados de $nome?';
  static const perfilEliminarConfirmarTexto =
      'Esta ação não pode ser desfeita: nenhum dado poderá ser recuperado, '
      'inclusive no servidor. Antes de prosseguir, considere o dever de '
      'guarda do registro do atendimento (prontuário).';
  static const perfilEliminarConfirmar = 'Eliminar';
  static const perfilEliminarCancelar = 'Manter os dados';
  static const perfilEliminando = 'Eliminando…';
  static const perfilEliminarExigeConexao =
      'A eliminação exige conexão com a internet, pois os dados também são '
      'excluídos do servidor.';

  static const consentimentoQuemApoioMenor =
      'Paciente menor de 18 anos: quem autoriza é o responsável legal.';
  static const consentimentoMenorExigeResponsavel =
      'Paciente menor de 18 anos: a autorização é do responsável legal.';
  static const consentimentoCampoResponsavel = 'Nome do responsável legal';
  static const consentimentoConcordancia =
      'A pessoa que autoriza leu ou ouviu o termo e concorda com a gravação da '
      'voz e com o envio para análise.';
  static const consentimentoRegistrar = 'Registrar consentimento';
  static const consentimentoRegistrando = 'Registrando…';

  static const consentimentoNaoRegistrado = 'Consentimento não registrado';
  static const consentimentoNaoRegistradoTexto =
      'A gravação permanece bloqueada até que o consentimento seja '
      'registrado.';
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
      'Marque a declaração de concordância para registrar o consentimento. '
      'Sem ela, a gravação permanece bloqueada.';

  // ------------------------------------------- retirada do consentimento --
  static const retiradaTitulo = 'Retirar consentimento';
  static const retiradaAcao = 'Retirar consentimento';
  static const retiradaOQueAcontece = 'O que acontece';
  static const retiradaEfeitos = [
    'A gravação deste paciente permanece bloqueada até o registro de um novo '
        'consentimento.',
    'As gravações deste paciente que ainda estão na fila são interrompidas e '
        'não são enviadas para análise.',
    'O consentimento e a sua retirada permanecem registrados, com data e '
        'hora.',
    'As gravações, as análises e os laudos já realizados permanecem neste '
        'aparelho.',
  ];
  static const retiradaCampoQuem = 'Quem pede a retirada';
  static const retiradaQuemApoio =
      'A retirada pode ser solicitada por quem autorizou: o próprio paciente '
      'ou o responsável legal.';
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
      'Em $data, às $hora, a pedido $quem. A gravação permanece bloqueada até '
      'o registro de um novo consentimento.';
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
      'Antes da gravação, o FONAR mede o ruído ambiente durante 5 segundos. '
      'Solicite silêncio no ambiente e posicione o aparelho no local em que '
      'será feita a gravação.';
  static const afericaoMedir = 'Medir ruído ambiente';
  static const afericaoMedirDeNovo = 'Medir novamente';
  static const afericaoLiberandoMicrofone = 'Liberando o microfone…';
  static const afericaoMicrofoneDemorando =
      'O microfone ainda não foi liberado';
  static const afericaoMicrofoneDemorandoTexto =
      'A nova medição e a gravação permanecem bloqueadas até que o microfone '
      'seja liberado. Se a situação persistir, saia desta tela e abra-a '
      'novamente.';
  static const afericaoEsperaGravacao =
      'Conclua a gravação em andamento para realizar uma nova medição.';

  static const afericaoSemPermissao = 'Sem permissão de microfone';
  static const afericaoSemPermissaoTexto =
      'Autorize o uso do microfone pelo FONAR nas configurações do aparelho e '
      'tente novamente.';
  static const afericaoFalhou = 'Não foi possível abrir o microfone';
  static const afericaoFalhouTexto =
      'Verifique se outro aplicativo está utilizando o microfone e tente '
      'novamente.';

  static const afericaoMudo = 'O microfone não está captando som';

  /// Diz o que fazer nas duas plataformas, sem perguntar qual é: o texto é o
  /// mesmo em qualquer aparelho, e quem está num lê a sua parte.
  ///
  /// Aparece depois da conferência com a voz: nem a voz chegou.
  static const afericaoMudoTexto =
      'O microfone não captou nem mesmo a voz, e a gravação permanece '
      'bloqueada até que ele capte som. Se houver mais de um microfone, '
      'selecione outro nesta tela. No Windows, abra Configurações > '
      'Privacidade e segurança > Microfone e ative o acesso ao microfone, '
      'inclusive para aplicativos da área de trabalho. No Android, verifique a '
      'permissão de microfone do FONAR. Em seguida, realize uma nova medição.';

  /// A sala deu silêncio digital — sala silenciosa de verdade com um
  /// microfone que zera o sinal, ou microfone que não capta. Só a voz
  /// separa os dois (`AfericaoDeRuido.concluirComAVoz`).
  static const afericaoSilencio = 'Nenhum som foi captado';
  static const afericaoSilencioTexto =
      'Isso pode indicar silêncio absoluto no ambiente ou falha na captação '
      'do microfone. Toque em “Conferir com a voz” e fale algumas palavras '
      'próximo ao microfone.';
  static const afericaoConferirComAVoz = 'Conferir com a voz';
  static const afericaoSalaSilenciosa = 'Sala silenciosa e microfone captando';
  static const afericaoSalaSilenciosaTexto =
      'O ruído ambiente ficou abaixo do limite de detecção do microfone, e a '
      'voz foi captada corretamente.';

  // Teste de homologação de 18/10/2026: sem escolher o microfone, o FONAR
  // gravava do padrão do sistema — no Windows com DroidCam, um virtual mudo.
  static const microfoneRotulo = 'Microfone';
  static const microfonePadrao = 'Padrão do sistema';
  static const microfoneApoio =
      'A troca de microfone exige uma nova medição do ruído ambiente.';
  static const microfoneApoioAntesDeMedir =
      'O ruído ambiente será medido com este microfone.';
  static String microfoneAusente(String nome) =>
      'O microfone selecionado ($nome) não está conectado. O FONAR está '
      'utilizando o microfone padrão do sistema.';
  static const microfoneEmbutido = 'Microfone do aparelho';
  static const microfoneFoneComFio = 'Fone com fio';
  static const microfoneUsb = 'Microfone USB';
  static const microfoneEntradaDeLinha = 'Entrada de linha';
  static const microfoneSemNome = 'Microfone';
  static const afericaoRuidoAlto = 'Ruído ambiente acima do limite';
  static String afericaoRuidoAltoTexto(String nivel, String limite) =>
      'Nível típico do ambiente: $nivel (limite: $limite). Feche portas e '
      'janelas, desligue ventiladores ou ar-condicionado e realize uma nova '
      'medição.';
  static const afericaoSemRestricao = 'Ruído ambiente dentro do limite';
  static String afericaoSemRestricaoTexto(String nivel) =>
      'Nível típico do ambiente: $nivel.';

  static const afericaoAjusteTitulo = 'O aparelho alterou o formato da captura';
  static String afericaoAjusteTexto({
    required int taxaUsada,
    required int canaisUsados,
    required int taxaPedida,
    required int canaisPedidos,
  }) =>
      'Solicitado: $taxaPedida Hz, $canaisPedidos '
      '${canaisPedidos == 1 ? 'canal' : 'canais'}. Utilizado: $taxaUsada Hz, '
      '$canaisUsados ${canaisUsados == 1 ? 'canal' : 'canais'}. Comunique a '
      'equipe do FONAR antes de utilizar este aparelho em atendimentos.';

  static const capturaIniciarGravacao = 'Iniciar gravação';
  static const capturaBloqueadaMicrofone =
      'A gravação permanece bloqueada até que o microfone capte som.';

  // US42: no navegador, o processamento automático pode ficar ligado.
  static const capturaProcessamentoLigado =
      'O processamento automático do microfone permaneceu ativado';

  /// [ligados]: os nomes de [processamentoGanhoAutomatico] e afins, na
  /// ordem em que aparecem.
  static String capturaProcessamentoLigadoTexto(List<String> ligados) =>
      'Este aparelho manteve ativado, ou não confirmou ter desativado: '
      '${_lista(ligados)}. Esse ajuste automático altera as características '
      'do sinal que a análise acústica mede; por isso, a gravação permanece '
      'bloqueada neste navegador. Utilize o FONAR instalado no computador ou '
      'no Android, ou tente outro navegador.';
  static const processamentoGanhoAutomatico = 'ganho automático';
  static const processamentoSupressaoDeRuido = 'supressão de ruído';
  static const processamentoCancelamentoDeEco = 'cancelamento de eco';

  static const capturaSemArmazenamento =
      'Este navegador não permite armazenar os dados';
  static const capturaSemArmazenamentoTexto =
      'O navegador não concedeu ao FONAR espaço para armazenar os dados (o que '
      'ocorre em algumas janelas privativas), e a gravação seria perdida ao '
      'fechar a página. Abra o FONAR em uma janela comum ou pelo ícone na Tela '
      'de Início.';

  /// "a", "a e b", "a, b e c".
  static String _lista(List<String> itens) => switch (itens) {
    [] => '',
    [final unico] => unico,
    [...final inicio, final ultimo] => '${inicio.join(', ')} e $ultimo',
  };

  // --------------------------------------------------- gravação guiada --
  // Uma etapa por vez, como no protótipo: o ruído da sala e depois cada
  // tarefa, com a instrução grande para o paciente ler de longe.
  static String etapaDe(int numero, int total, String nome) =>
      'Etapa $numero de $total — $nome';
  static const etapaConcluida = 'concluída';
  static const etapaEmAndamento = 'em andamento';
  static const etapaPendente = 'pendente';
  static const etapaRuidoCurta = 'Ruído';
  static const etapaRuidoNome = 'Aferição de ruído';
  static const tarefaVogalCurta = 'Vogal /a/';
  static const tarefaFalaCurta = 'Fala';

  static const instrucaoRuidoPronto =
      'Medição do ruído ambiente. Permaneça em silêncio por alguns segundos.';
  static const instrucaoRuidoMedindo = 'Medindo o ruído ambiente…';
  static const instrucaoRuidoOk = 'Ambiente adequado para gravar.';
  static const instrucaoRuidoAlto = 'O ruído ambiente está acima do limite.';
  static const instrucaoRuidoMudo = 'O microfone não está captando som.';
  static const instrucaoRuidoSilencio = 'Nenhum som foi captado.';
  static const instrucaoRuidoConferindoVoz =
      'Fale algumas palavras próximo ao microfone.';
  static const instrucaoRuidoSemMicrofone =
      'Não foi possível usar o microfone.';

  // TODO(clínico): instruções PROVISÓRIAS, escritas para o fluxo funcionar.
  // As tarefas, a ordem e o texto dito ao paciente são do protocolo clínico e
  // precisam de revisão da orientação.
  //
  // A fala encadeada é a contagem de 1 a 20 porque foi o material da validação
  // brasileira do AVQI v03.01 (Englert et al., J Voice 2021), de onde vem o
  // corte candidato: com outra fala, o número não se compara com aquele corte.
  // É a resposta provisória do item 7 de `docs/pendencias-clinicas.md` do
  // fonar-api; o texto exato dito ao paciente continua por validar.
  static const instrucaoVogalPronto =
      'Respire fundo e sustente o som “aaaa” em tom confortável.';
  static const instrucaoVogalGravando = 'Continue sustentando o som “aaaa”.';
  static const instrucaoFalaPronto = 'Conte de 1 a 20, com a sua voz habitual.';
  static const instrucaoFalaGravando = 'Continue contando até 20.';
  static const instrucaoProvisoria =
      'Instrução provisória — pendente de validação pela orientação clínica.';
  static const instrucaoConferindo = 'Verificando a gravação…';
  static const instrucaoAmostraBoa = 'Amostra registrada.';
  static const instrucaoAmostraRessalva = 'Amostra registrada, com ressalva.';
  static const instrucaoAmostraRecusada =
      'A gravação não atendeu aos critérios de qualidade. Realize uma nova '
      'gravação.';

  static const gravandoRotulo = 'Gravando';
  static const capturaContinuar = 'Continuar';
  static const capturaProximaEtapa = 'Próxima etapa';
  static const capturaConcluirERevisar = 'Concluir e revisar';
  static const capturaRegravar = 'Regravar';
  static const capturaAtalhos =
      'Barra de espaço: iniciar e parar · Tecla R: regravar';
  static const capturaEsperaTerminar =
      'Conclua a gravação em andamento para mudar de etapa.';

  static const revisaoTitulo = 'Revisão das amostras';
  static const revisaoInstrucao =
      'Todas as tarefas foram gravadas. Ouça as amostras antes de enviá-las.';
  static String revisaoResumo(int gravadas, int total) =>
      '$gravadas de $total tarefas gravadas.';
  static const revisaoVoltar = 'Voltar à gravação';

  // ------------------------------------------------ gravações não enviadas --
  static const naoEnviadasTitulo = 'Gravações não enviadas';
  static const naoEnviadasExplicacao =
      'Sessões de dias anteriores que ficaram incompletas ou não foram '
      'enviadas para análise. Elas estão armazenadas somente neste aparelho. '
      'Ouça as gravações, envie as sessões completas para análise ou descarte '
      'as que não serão utilizadas.';
  static const naoEnviadasVazia =
      'Não há gravações pendentes de envio neste aparelho.';
  static String naoEnviadasSessao(String data, String hora) =>
      'Gravada em $data, às $hora';
  static String naoEnviadasTarefas(int gravadas, int total) =>
      '$gravadas de $total tarefas gravadas';
  static const naoEnviadasEnviar = 'Enviar para análise';
  static const naoEnviadasIncompleta =
      'Sessão incompleta: para a análise, é necessário gravar a sessão '
      'novamente.';
  static const naoEnviadasSemConsentimento =
      'Não há consentimento em vigor: registre um novo consentimento para '
      'enviar.';
  static const naoEnviadasDescartar = 'Descartar';

  /// Título e texto do diálogo de confirmação — ver `appConfirmar`.
  static String naoEnviadasDescartarTitulo(int n) =>
      'Descartar ${n == 1 ? 'a gravação' : 'as $n gravações'} desta sessão?';
  static const naoEnviadasDescartarTexto =
      'O áudio será excluído deste aparelho. Esta ação não pode ser desfeita.';
  static const naoEnviadasDescartarDeVez = 'Descartar definitivamente';
  static const naoEnviadasManter = 'Manter';
  static const naoEnviadasDescartando = 'Descartando…';
  static const naoEnviadasOcupada =
      'Aguarde a conclusão da operação na outra sessão.';
  static const naoEnviadasErroDescartar =
      'Não foi possível excluir todos os arquivos. A sessão permanece neste '
      'aparelho; tente novamente.';
  static const naoEnviadasSemArquivo = 'Arquivo não encontrado neste aparelho.';
  static const naoEnviadasFaltaArquivo =
      'Há arquivo de gravação ausente: descarte a sessão e grave novamente.';
  static const naoEnviadasJaNaFila =
      'Esta sessão já foi incluída na fila de envio e não pode ser descartada '
      'nesta tela.';
  static const naoEnviadasErroEnviar =
      'Não foi possível incluir a sessão na fila de envio. Tente novamente.';
  static const naoEnviadasErroCarregar =
      'Não foi possível ler as gravações deste aparelho.';
  static const capturaRetomadaTitulo = 'Sessão de hoje retomada';
  static String capturaRetomadaTexto(String hora, int gravadas, int total) =>
      'Iniciada às $hora. Tarefas já gravadas: $gravadas de $total, que '
      'permanecem válidas. Regravar uma tarefa substitui a gravação anterior.';

  static const tarefaVogalTitulo = 'Vogal sustentada /a/';
  static const tarefaFalaTitulo = 'Fala encadeada';

  static const tarefaParar = 'Parar';
  static String tarefaGravando(String duracao) => 'Gravando… $duracao';
  static const tarefaOutraEmAndamento =
      'Conclua a gravação em andamento antes de gravar esta tarefa.';

  static String tarefaGravada(String duracao) => 'Gravada — $duracao';
  static const tarefaGravadaTexto =
      'Arquivo verificado: WAV PCM, sem ressalvas.';
  static String tarefaGravadaComRessalva(String duracao) =>
      'Gravada com ressalva — $duracao';
  static const tarefaDescartada = 'Última gravação descartada';
  static const tarefaDescartadaMantida =
      'A gravação anterior desta tarefa permanece armazenada.';

  static const tarefaFalhaTitulo = 'A gravação não foi realizada';
  static const tarefaFalhaPermissao =
      'Sem permissão de uso do microfone. Autorize o uso do microfone pelo '
      'FONAR nas configurações do aparelho e tente novamente.';
  static const tarefaFalhaIniciar =
      'Não foi possível iniciar a gravação. Verifique se outro aplicativo '
      'está utilizando o microfone e tente novamente.';
  static const tarefaFalhaFinalizar =
      'A gravação não pôde ser finalizada e foi descartada. Grave novamente.';
  static const tarefaFalhaInterrompida =
      'O microfone deixou de responder durante a gravação, que foi '
      'descartada. Grave novamente.';

  // O que a conferência encontrou. Diz o que fazer, não só o que houve.
  static const problemaArquivoIlegivel =
      'O arquivo gravado não pôde ser lido. Grave novamente.';
  static const problemaNaoEPcm =
      'O aparelho gravou em formato comprimido, e não em WAV PCM. Comunique a '
      'equipe do FONAR antes de utilizar este aparelho em atendimentos.';
  static const problemaBitsDiferentes =
      'O aparelho gravou com resolução diferente de 16 bits. Comunique a '
      'equipe do FONAR antes de utilizar este aparelho em atendimentos.';
  static const problemaIncompleto =
      'A gravação foi interrompida e o arquivo ficou incompleto. Grave '
      'novamente.';
  static const problemaCurtaDemais =
      'A gravação tem duração inferior a 1 segundo. Grave novamente.';
  static const problemaSemSinal =
      'O microfone não captou som durante a gravação. Verifique o acesso ao '
      'microfone, realize uma nova medição do ruído e grave novamente.';
  static const problemaSaturou =
      'Houve saturação: a intensidade da voz excedeu o limite do microfone. '
      'Se possível, afaste ligeiramente o microfone e grave novamente.';
  static const problemaProcessamentoLigado =
      'O aparelho manteve ativado o processamento automático do microfone '
      '(ganho, supressão de ruído ou cancelamento de eco), que altera as '
      'características do sinal medidas pela análise. Esta gravação não pode '
      'ser utilizada; grave com o FONAR instalado no computador ou no '
      'Android.';
  static const problemaFormatoForaDoAceito =
      'O aparelho gravou em um formato não aceito pela análise (mais de um '
      'canal ou taxa de amostragem fora do intervalo). Grave novamente; se o '
      'problema persistir, comunique a equipe do FONAR antes de utilizar este '
      'aparelho em atendimentos.';
  static const problemaFormatoAjustado =
      'O aparelho gravou com taxa de amostragem ou número de canais diferentes '
      'dos solicitados. Comunique a equipe do FONAR antes de utilizar este '
      'aparelho em atendimentos.';

  static const capturaEnviar = 'Enviar para análise';
  static const capturaEnviando = 'Incluindo na fila de envio…';
  static const capturaEnviarFaltaTarefa =
      'Grave todas as tarefas para enviar a sessão.';
  static const capturaEnviarApoio =
      'O envio funciona sem conexão: a gravação permanece na fila e é enviada '
      'quando a conexão for restabelecida.';

  // ---------------------------------------------- fila de sincronização --
  static const filaVaziaTitulo = 'Não há envios na fila';
  static const filaVaziaTexto =
      'As gravações enviadas para análise são exibidas aqui até serem '
      'recebidas pelo servidor.';
  static const filaIrParaPacientes = 'Ir para pacientes';
  static String filaResumo(int pendentes) => pendentes == 0
      ? 'Todos os envios foram concluídos'
      : pendentes == 1
      ? '1 envio pendente'
      : '$pendentes envios pendentes';
  static const filaSemConexaoTitulo =
      'Envios suspensos até o restabelecimento da conexão';
  static const filaSemConexaoTexto =
      'Os envios serão retomados automaticamente quando a conexão for '
      'restabelecida. As gravações estão armazenadas neste aparelho.';
  static String filaGravacoes(int n, String data) =>
      '${n == 1 ? '1 gravação' : '$n gravações'} · $data';

  static const filaNaFila = 'Na fila';
  static const filaNaFilaTexto = 'Será enviado na ordem da fila.';
  static const filaAguardandoConexao = 'Aguardando conexão';
  static const filaAguardandoConexaoTexto =
      'Será enviado automaticamente quando a conexão for restabelecida.';
  static const filaEnviando = 'Enviando…';
  static const filaEnviandoTexto =
      'O aplicativo pode continuar sendo utilizado; o envio prossegue em '
      'segundo plano.';
  static const filaFalhou = 'O envio falhou';
  static String filaFalhouTexto(String motivo, String hora) =>
      '$motivo Nova tentativa automática às $hora.';
  static const filaSessaoExpirada = 'Sessão expirada';
  static const filaSessaoExpiradaTexto =
      'Entre novamente na conta para que o envio prossiga. A gravação permanece '
      'armazenada.';
  static const filaEntrarDeNovo = 'Entrar novamente';
  static const filaEntrarExigeConexao =
      'A entrada com senha exige conexão. A gravação permanece armazenada.';
  static const filaRecusado = 'A análise recusou o envio';
  static String filaRecusadoTexto(String motivo) =>
      '$motivo Uma nova tentativa tende a ser recusada pelo mesmo motivo; se '
      'a recusa persistir, comunique a equipe do FONAR.';
  static const filaEnviado = 'Enviado';
  static const filaEnviadoTexto = 'A análise foi recebida pelo servidor.';
  static const filaTentarAgora = 'Tentar agora';
  static const filaTentarDeNovo = 'Tentar novamente';
  static const filaTentarExigeConexao = 'Disponível quando houver conexão.';
  static const filaVerResultado = 'Ver resultado';
  static const filaSemConsentimento = 'Suspenso: consentimento retirado';
  static const filaSemConsentimentoTexto =
      'O consentimento sob o qual esta gravação foi realizada foi retirado, e '
      'ela não será mais enviada. Um novo consentimento vale somente para as '
      'gravações realizadas após o seu registro. A gravação permanece '
      'armazenada neste aparelho, como parte do registro do atendimento.';

  /// "4,2 s". Decimal com vírgula, como se escreve em português.
  static String segundos(Duration d) =>
      '${(d.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';

  // ------------------------------------------------ resultado da análise --
  static const resultadoExemploTitulo = 'Dados de exemplo';
  static const resultadoExemploTexto =
      'Valores fictícios, destinados ao desenvolvimento. Não correspondem a '
      'nenhum paciente.';
  static String resultadoGravadoEm(String data, String hora) =>
      'Gravado em $data, às $hora';
  static const resultadoQualidadeTitulo = 'Qualidade das amostras';
  static String resultadoAmostraAdequada(String tarefa) =>
      '$tarefa: adequada para análise';
  static String resultadoAmostraComProblema(String tarefa) =>
      '$tarefa: amostra com problema';
  static const resultadoAmostraSemMotivo = 'O servidor não detalhou o motivo.';
  static const resultadoMedidasTitulo = 'Medidas acústicas';
  static const resultadoRodape =
      'As faixas de referência provêm de um catálogo configurável (por sexo, '
      'idade e equipamento) e ainda estão pendentes de validação clínica.';
  static const resultadoEspectrogramaTitulo = 'Espectrograma';
  static const resultadoEspectrogramaIndisponivel =
      'A imagem ainda não está disponível para esta análise.';
  static const resultadoEspectrogramaErro =
      'Não foi possível carregar a imagem. Verifique a conexão.';
  static const resultadoEspectrogramaDescricao =
      'Espectrograma da gravação, gerado pelo servidor.';
  static const resultadoEspectrogramaTelaCheia = 'Ver em tela cheia';
  static const espectrogramaGireAparelho =
      'Gire o aparelho para ampliar o espectrograma.';
  static const espectrogramaAproximar = 'Aproximar';
  static const espectrogramaAjustar = 'Ajustar à tela';
  static const espectrogramaNoMaximo = 'Aproximação máxima.';
  static const espectrogramaNoTamanhoDaTela =
      'A imagem já está ajustada ao tamanho da tela.';
  static const espectrogramaGestos =
      'Também é possível aproximar com dois dedos, com a roda do mouse ou com '
      'as teclas + e −, e percorrer a imagem arrastando-a ou com as setas do '
      'teclado.';
  static const espectrogramaAreaDica =
      'Setas: percorrer a imagem · + e −: aproximar e afastar · 0: ajustar à '
      'tela.';

  static const resultadoAindaNaoDisponivel = 'Ainda não disponível';
  static const resultadoAindaNaoDisponivelTexto =
      'O FONAR ainda não calcula esta medida. As demais medidas não dependem '
      'dela.';
  static const resultadoNaoCalculada = 'Não calculada';
  static const resultadoNaoCalculadaTexto =
      'O servidor não conseguiu calcular esta medida nesta gravação.';
  static const resultadoPerfilIncompleto =
      'O cadastro do paciente não informa o sexo ou a data de nascimento, '
      'dados dos quais a faixa de referência depende.';
  static const resultadoSemFaixaValidada =
      'Não há faixa validada para o perfil deste paciente.';
  static String resultadoFaixa(String faixa) => 'Faixa: $faixa';
  static String resultadoProcedencia(String fonte) => 'Fonte: $fonte';

  static const resultadoProcessandoTitulo = 'Análise em processamento';
  static const resultadoProcessandoTexto =
      'O servidor ainda está calculando as medidas. O processamento pode '
      'levar alguns minutos.';
  static const resultadoAtualizar = 'Atualizar';
  static const resultadoFalhouTitulo = 'A análise não pôde ser concluída';
  static const resultadoDeOutroPaciente = 'Esta análise não é deste paciente';
  static const resultadoDeOutroPacienteTexto =
      'O resultado aberto pertence a outro cadastro. Retorne e abra a análise '
      'a partir do cadastro do paciente correto.';
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
      'Avaliação perceptivo-auditiva realizada pelo profissional. Para cada '
      'parâmetro, marque na linha o grau de desvio: na extremidade esquerda, '
      'ausência de desvio; na extremidade direita, desvio extremo.';
  static const capeVGrauGeral = 'Grau geral';
  static const capeVRugosidade = 'Rugosidade';
  static const capeVSoprosidade = 'Soprosidade';
  static const capeVTensao = 'Tensão';
  static const capeVPitch = 'Pitch';
  static const capeVLoudness = 'Loudness';
  static const capeVSemDesvio = 'Sem desvio';
  static const capeVDesvioExtremo = 'Desvio extremo';
  static const capeVNaoMarcado = 'Não marcado';

  /// O − e o + da escala visual: o nome para o leitor de tela e a dica para
  /// o mouse.
  static String escalaDiminuir(String rotulo) => 'Diminuir $rotulo em 1';
  static String escalaAumentar(String rotulo) => 'Aumentar $rotulo em 1';
  static const escalaMenosUm = 'Menos 1';
  static const escalaMaisUm = 'Mais 1';
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
  static const capeVAmostra = 'Amostra';
  static const capeVAbrirEscala = 'Abrir escala';
  static String capeVParametroDe(int n, int total) => 'CAPE-V · $n de $total';
  static const capeVAnterior = 'Anterior';
  static const capeVProximo = 'Próximo';
  static const capeVConcluir = 'Concluir';
  static const capeVGireAparelho =
      'Gire o aparelho para visualizar a escala em tamanho maior.';
  static const capeVRegistrando = 'Registrando…';
  static const capeVMarque =
      'Marque o grau na linha. Na ausência de desvio, marque 0.';
  static const capeVEscolhaConsistencia =
      'Havendo desvio, indique se ele é consistente ou intermitente.';
  static const capeVEscolhaSentido =
      'Havendo desvio, indique o sentido: abaixo ou acima do esperado.';
  static const capeVErroCarregar =
      'Não foi possível abrir a avaliação CAPE-V desta análise.';

  // Na tela de resultado.
  static const capeVSecaoTitulo = 'Avaliação perceptivo-auditiva (CAPE-V)';
  static const capeVAindaNao =
      'A CAPE-V ainda não foi registrada para esta '
      'análise.';
  static const capeVEditar = 'Editar CAPE-V';
  static String capeVRegistradaEm(String data, String hora) =>
      'Registrada em $data, às $hora.';

  // ------------------------------------------------------------ evolução --
  static const evolucaoTitulo = 'Evolução';
  static const resultadoVerEvolucao = 'Ver evolução';
  static String evolucaoSessoes(int n, String primeira, String ultima) => n == 1
      ? '1 sessão analisada, em $primeira.'
      : '$n sessões analisadas, de $primeira a $ultima.';
  static const evolucaoMedidaNoGrafico = 'Medida no gráfico';
  static String evolucaoUnidade(String unidade) => 'Valores em $unidade.';
  static const evolucaoVaziaTitulo = 'Ainda não há sessões analisadas';
  static const evolucaoVaziaTexto =
      'A evolução é exibida após a conclusão da primeira análise deste '
      'paciente. As gravações que estão na fila serão incluídas quando os '
      'respectivos resultados forem recebidos.';
  static const evolucaoErroCarregar =
      'Não foi possível abrir a evolução deste paciente.';

  static const evolucaoMaisRecente = 'Mais recente';
  static const evolucaoAnterior = 'Anterior';
  static const evolucaoUmValor =
      'Há somente uma sessão com esta medida calculada; ainda não é possível '
      'comparar.';
  static const evolucaoNenhumValor =
      'O servidor não calculou esta medida em nenhuma sessão.';

  /// Sem limiar de mudança validado, os valores ficam lado a lado e nenhuma
  /// frase diz que a medida subiu, desceu ou ficou estável.
  static const evolucaoSemLimiar =
      'Sem interpretação de mudança: ainda não foi definido o valor mínimo de '
      'diferença entre sessões que caracteriza uma mudança.';
  static const evolucaoSubiu = 'aumentou';
  static const evolucaoDesceu = 'diminuiu';
  static const evolucaoFicouEstavel = 'permaneceu estável';

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
      'Gire o aparelho para visualizar o gráfico em tamanho maior.';
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
      'Cada ponto representa uma sessão de gravação. A interpretação destes '
      'valores cabe ao seu fonoaudiólogo.';
  static const modoPacienteSair = 'Voltar à tela do profissional';

  // ---------------------------------------------------- perfil do paciente --
  static const perfilErroCarregar =
      'Não foi possível abrir o perfil deste paciente.';
  static const perfilNaoEncontrado = 'Paciente não encontrado neste aparelho';
  static const perfilNaoEncontradoTexto =
      'O cadastro pode ter sido realizado em outro aparelho e ainda não ter '
      'sido sincronizado.';
  static const perfilVoltarParaLista = 'Voltar para a lista';
  static String perfilQueixa(String queixa) => 'Queixa: $queixa';
  static String perfilNascimento(String data, int idade) =>
      'Nascimento: $data ($idade ${idade == 1 ? 'ano' : 'anos'})';
  static const perfilNascimentoNaoInformado = 'Nascimento: não informado';
  static String perfilSexo(String sexo) => 'Sexo: $sexo';
  static const perfilSexoNaoInformado = 'Sexo: não informado';
  static const perfilSemPerfilDeReferencia =
      'Sem o sexo ou a data de nascimento, as medidas são exibidas sem '
      'classificação.';

  static const perfilNovaGravacao = 'Nova gravação';
  static const perfilGravacaoBloqueada =
      'Registre o consentimento para liberar a gravação.';
  static const perfilRegistrarConsentimento = 'Registrar consentimento';
  static const perfilVerEvolucao = 'Ver evolução';

  static const perfilSessoesTitulo = 'Sessões';
  static const perfilSemSessoes =
      'Ainda não há sessões analisadas. As análises serão exibidas aqui após '
      'o envio da primeira gravação.';
  static String perfilNaFila(int n) => n == 1
      ? '1 gravação deste paciente aguarda envio na fila.'
      : '$n gravações deste paciente aguardam envio na fila.';
  static String perfilParadosNaFila(int n) => n == 1
      ? '1 gravação deste paciente está suspensa na fila, pois o '
            'consentimento foi retirado.'
      : '$n gravações deste paciente estão suspensas na fila, pois o '
            'consentimento foi retirado.';
  static const perfilVerFila = 'Ver fila';
  static const perfilEditarDados = 'Editar dados';
  static String perfilNaoEnviadas(int n) => n == 1
      ? '1 sessão gravada neste aparelho não foi enviada para análise.'
      : '$n sessões gravadas neste aparelho não foram enviadas para análise.';
  static const perfilRevisarGravacoes = 'Revisar gravações';
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
  static const reproducaoFalhou = 'Não foi possível reproduzir esta gravação.';

  /// O motivo do bloqueio precisa estar dito: um "ouvir" desabilitado sem
  /// explicação parece defeito.
  static const reproducaoBloqueadaGravando =
      'Aguarde o término da gravação para ouvir: o som do alto-falante seria '
      'captado pelo microfone.';
  static const resultadoAudioIndisponivel =
      'O áudio desta análise não está disponível neste aparelho.';

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
      'Sem o cadastro do paciente, o laudo seria emitido sem identificação. '
      'Retorne e abra a análise a partir do cadastro do paciente.';
  static const laudoConferenciaTitulo = 'Verificação antes da emissão';
  static const laudoConferenciaOk = 'Concluído';
  static const laudoConferenciaPendente = 'Pendente — impede a emissão';
  static const laudoConferenciaAviso = 'Aviso — não impede a emissão';

  // Cada item: o que é, e o que fazer quando não está resolvido.
  static const laudoItemConsentimento = 'Consentimento registrado';
  static const laudoItemConsentimentoFalta =
      'Não há consentimento registrado para este paciente. Registre o '
      'consentimento antes de emitir o laudo.';
  static const laudoItemAnalise = 'Análise concluída';
  static const laudoItemAnaliseFalta =
      'A análise ainda não foi concluída pelo servidor.';
  static const laudoItemQualidade = 'Amostras adequadas para análise';
  static const laudoItemQualidadeAviso =
      'Ao menos uma amostra apresentou problema. O laudo identifica qual.';
  static const laudoItemCapeV = 'CAPE-V registrada';
  static const laudoItemCapeVAviso =
      'Sem a CAPE-V, o laudo será emitido somente com as medidas acústicas.';
  static const laudoItemConclusao = 'Conclusão do profissional';
  static const laudoItemConclusaoFalta = 'Redija a conclusão no campo abaixo.';

  static const laudoItemAssinatura = 'Nome e registro do profissional';
  static const laudoItemAssinaturaFalta =
      'Esses dados constam da assinatura do laudo. Preencha-os na tela Conta.';
  static const laudoItemCredenciamento =
      'Inscrição no conselho conferida pela equipe';
  static const laudoItemCredenciamentoFalta =
      'O laudo somente pode ser emitido depois que a equipe do FONAR conferir '
      'a sua inscrição no Conselho Regional de Fonoaudiologia. Essa '
      'conferência impede que laudos sejam emitidos em nome de profissionais '
      'não habilitados. Enquanto ela não for concluída, as demais funções do '
      'aplicativo permanecem disponíveis.';
  static const laudoVerSituacaoDoCadastro = 'Ver a situação do cadastro';
  static const laudoIrParaConta = 'Preencher na tela Conta';
  static const laudoIrParaConsentimento = 'Registrar consentimento';
  static const laudoIrParaCapeV = 'Registrar CAPE-V';

  static const laudoCampoConclusao = 'Conclusão do profissional';

  /// O mesmo limite da API (`TAMANHO_MAXIMO_CONCLUSAO`).
  static const laudoConclusaoMaximo = 10000;
  static const laudoConclusaoApoio =
      'Redigida exclusivamente pelo profissional. O FONAR não redige nem '
      'sugere conclusões.';

  static const laudoGerar = 'Emitir laudo';
  static const laudoGerando = 'Emitindo…';

  /// Gerar de novo emite OUTRO documento, e é o mesmo botão — por isso
  /// pergunta antes. O de agora não é apagado (US38, ADR-018 da API). Ver
  /// `appConfirmar`.
  static const laudoSubstituirTitulo = 'Emitir um novo laudo?';
  static const laudoSubstituirTexto =
      'O laudo atual permanece armazenado tal como foi emitido. O novo laudo '
      'recebe outro número e indica, no próprio documento, que substitui o '
      'anterior.';
  static const laudoSubstituir = 'Emitir novo laudo';
  static const laudoManterOAtual = 'Manter o atual';
  static const laudoGerarBloqueado =
      'Resolva os itens pendentes da verificação para emitir o laudo.';
  static String laudoGeradoEm(String codigo, String data, String hora) =>
      'Laudo nº $codigo emitido em $data, às $hora.';

  /// Onde está a cópia do laudo emitido (ADR-018 da API).
  static const laudoNoServidor = 'Cópia armazenada no servidor.';
  static const laudoSoNoAparelho =
      'No momento, armazenado somente neste aparelho. A cópia será enviada ao '
      'servidor quando houver conexão.';

  /// Os laudos que o vigente substituiu: continuam guardados e saem como
  /// foram emitidos.
  static const laudoAnterioresTitulo = 'Laudos anteriores desta sessão';
  static String laudoAnterior(String codigo, String data, String hora) =>
      'Nº $codigo — emitido em $data, às $hora';
  static const laudoAnteriorSubstituido = 'Substituído pelo laudo seguinte.';
  static const laudoTextoMudou =
      'A conclusão foi alterada após a última emissão. Emita um novo laudo '
      'para que o PDF inclua a alteração.';
  static const laudoCompartilhar = 'Salvar ou compartilhar o PDF';
  static const laudoImprimir = 'Imprimir ou salvar em PDF';
  static const laudoErroGerar =
      'Não foi possível emitir o laudo. Tente novamente.';
  static const laudoErroSaida =
      'Não foi possível abrir o PDF neste aparelho. Tente novamente.';

  static const laudoPreviaTitulo = 'Pré-visualização';
  static const laudoResumoTitulo = 'Conteúdo do laudo';
  static String laudoResumoMedidas(int n) =>
      n == 1 ? '1 medida acústica' : '$n medidas acústicas';
  static const laudoResumoComCapeV = 'Avaliação CAPE-V';
  static const laudoResumoSemCapeV = 'Sem avaliação CAPE-V';
  static const laudoResumoConclusao = 'Conclusão do profissional';
  static const laudoResumoSemConclusao = 'Conclusão ainda não redigida';

  // No documento.
  static const laudoDocTitulo = 'Laudo de avaliação vocal';
  static const laudoDocRascunho =
      'RASCUNHO — pré-visualização, documento ainda não emitido';
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
  static String laudoDocGeradoEm(String codigo, String data, String hora) =>
      'Documento nº $codigo, emitido em $data, às $hora.';
  static const laudoDocDocumento = 'Documento';
  static String laudoDocNumero(String codigo) => 'Nº $codigo';
  static const laudoDocSubstitui = 'Substitui';
  static String laudoDocSubstituiTexto(
    String codigo,
    String data,
    String hora,
  ) => 'O documento nº $codigo, emitido em $data, às $hora.';
  static const laudoDocAssinatura = 'Assinatura do profissional responsável';
  static const laudoDocEspectrograma = 'Espectrograma da vogal sustentada';
  static const laudoDocEspectrogramaLegenda =
      'Imagem gerada no servidor com o motor do Praat. Recurso visual de '
      'apoio, sem valor de medida clínica.';
  static const laudoDocEspectrogramaIndisponivel =
      'Não incluído: o servidor não respondeu no momento da emissão.';

  /// Rodapé de toda página: de onde vêm as medidas e de quem é a conclusão.
  static const laudoDocRodape =
      'Medidas acústicas calculadas no servidor com o motor do Praat. '
      'Ferramenta de apoio à decisão: a interpretação e a conclusão são de '
      'responsabilidade do profissional que assina.';
  static String laudoDocPagina(String? codigo, int atual, int total) =>
      codigo == null
      ? 'Página $atual de $total'
      : 'Documento nº $codigo · Página $atual de $total';

  /// Sem o nome do paciente, de propósito: o nome do arquivo aparece em
  /// pasta, e-mail e histórico de compartilhamento. Com o número do
  /// documento, para dois laudos da mesma sessão não se confundirem.
  static String laudoNomeDoArquivo(DateTime d, String codigo) =>
      '$laudoPrefixoDoArquivo${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}-$codigo.pdf';

  /// O começo do nome de todo PDF de laudo — é por ele que a limpeza da
  /// pasta temporária os reconhece.
  static const laudoPrefixoDoArquivo = 'laudo-fonar-';

  // --------------------------------------------------------------- conta --
  static const contaSeusDados = 'Seus dados';
  static const contaSeusDadosApoio =
      'O nome e o registro constam da assinatura dos laudos.';
  static const contaCampoNome = 'Nome, como deve constar na assinatura';
  static const contaCampoRegistro = 'Registro no conselho';
  static const contaRegistroDica = 'por exemplo: CRFa 2-12345';
  static const contaCampoEmail = 'E-mail da conta';
  static const contaInformeNome = 'Informe o nome como deve constar no laudo.';
  static const contaInformeRegistro =
      'Informe o registro no conselho, que constará do laudo.';
  static const contaSalvar = 'Salvar alterações';
  static const contaSalvando = 'Salvando…';
  static const contaNadaMudou = 'Nenhuma alteração para salvar.';
  static const contaSalvo = 'Dados salvos.';
  static const contaRegistroFormato =
      'Utilize o formato CRFa 2-12345: a região do Conselho Regional, um hífen '
      'e o número de inscrição.';
  static const contaRegistroTrocado =
      'A alteração da região ou do número de inscrição exige nova conferência '
      'pela equipe do FONAR.';
  static const contaCredenciamentoPendenteTitulo = 'Inscrição em conferência';
  static const contaCredenciamentoPendente =
      'A equipe do FONAR ainda não conferiu a sua inscrição na consulta '
      'pública do Conselho Regional de Fonoaudiologia. Até a conclusão dessa '
      'conferência, todas as funções do aplicativo estão disponíveis, exceto '
      'a emissão de laudos.';
  // Comprovante de inscrição (US63, ADR-021 da API).
  static const comprovanteTitulo = 'Comprovante de inscrição no conselho';
  static const comprovanteExplicacao =
      'Para concluir o credenciamento, envie uma fotografia legível ou um '
      'arquivo PDF da sua carteira de identidade profissional, emitida pelo '
      'Conselho Regional de Fonoaudiologia. A carteira deve mostrar a sua '
      'fotografia, o seu nome completo e o número de inscrição. A equipe do '
      'FONAR compara esses dados com os informados no cadastro e com a '
      'consulta pública do conselho. Formatos aceitos: JPEG, PNG ou PDF, com '
      'até 10 MB.';
  static const comprovantePrivacidade =
      'O arquivo é acessível somente à equipe responsável pela conferência e '
      'é excluído definitivamente assim que o credenciamento é concluído. '
      'Permanece registrada apenas a data da conferência.';
  static const comprovanteNaoEnviado =
      'Nenhum comprovante foi enviado até o momento.';
  static String comprovanteEnviadoEm(String data) =>
      'Comprovante enviado em $data. A conferência pela equipe está em '
      'andamento. Caso o arquivo esteja ilegível ou incorreto, envie um novo '
      'arquivo, que substituirá o anterior.';
  static const comprovanteEnviar = 'Enviar carteira profissional';
  static const comprovanteSubstituir = 'Enviar outro arquivo';
  static const comprovanteEnviando = 'Enviando o comprovante…';
  static const comprovanteEnviadoComSucesso =
      'Comprovante enviado. A equipe do FONAR fará a conferência.';
  static const comprovanteErroFormato =
      'O arquivo não foi aceito. Envie uma imagem JPEG ou PNG, ou um arquivo '
      'PDF, da carteira de identidade profissional.';
  static const comprovanteErroTamanho =
      'O arquivo excede o limite de 10 MB. Envie uma imagem de menor '
      'resolução ou um PDF menor.';
  static const comprovanteErroJaCredenciado =
      'A sua inscrição já foi conferida. Não é necessário enviar comprovante.';
  static const comprovanteErroCadastroIncompleto =
      'Complete o cadastro profissional antes de enviar o comprovante.';
  static const comprovanteErroSeletor =
      'Não foi possível abrir a seleção de arquivos neste aparelho.';

  static const contaCredenciamentoCredenciado =
      'Inscrição conferida pela equipe do FONAR';

  static const contaNesteAparelho = 'Neste aparelho';
  static String contaEnviosPendentes(int n) => switch (n) {
    0 => 'Não há envios aguardando na fila.',
    1 => '1 envio aguardando na fila.',
    _ => '$n envios aguardando na fila.',
  };
  static const contaVerFila = 'Ver fila';

  static const contaAparencia = 'Aparência';
  static const contaTema = 'Tema';
  static const contaTemaSistema = 'Do sistema';
  static const contaTemaClaro = 'Claro';
  static const contaTemaEscuro = 'Escuro';
  static const contaTemaApoio =
      'A escolha vale para este aparelho. O laudo em PDF é sempre emitido com '
      'fundo branco.';
  static const contaTamanho = 'Tamanho da interface';
  static const contaTamanhoAutomatico = 'Automático';
  static const contaTamanho100 = '100%';
  static const contaTamanho115 = '115%';
  static const contaTamanho130 = '130%';
  static String contaTamanhoApoio(double fator) =>
      'Amplia os elementos da interface em telas largas, como a do '
      'computador. No celular, prevalece o tamanho de texto definido no '
      'sistema. Tamanho atual nesta janela: ${(fator * 100).round()}%.';
  static const contaFaixasTitulo = 'Faixas de referência';
  static const contaFaixasPendente = 'Validação clínica pendente';
  static const contaFaixasEmUso = 'Catálogo em uso';
  static const contaFaixasTexto =
      'As faixas que classificam cada medida provêm de um catálogo que varia '
      'conforme o sexo, a idade e o equipamento de captação. Sem faixa válida '
      'para o perfil do paciente, a medida é exibida com o valor e sem '
      'classificação.';
  static const contaFaixasVazio =
      'Atualmente, o catálogo está vazio: nenhuma faixa foi validada por '
      'profissional da área, e nenhuma medida é classificada.';
  static const contaFaixasSoLeitura =
      'O catálogo não pode ser editado neste aparelho.';
  static const contaSobre = 'Sobre o FONAR';
  static const contaSobreTexto =
      'Ferramenta de apoio à decisão para a avaliação vocal. O FONAR não emite '
      'diagnóstico: as medidas, as escalas e os laudos são interpretados e '
      'assinados pelo profissional.';
  static const contaSobrePraat =
      'As medidas acústicas são calculadas no servidor com o motor do Praat, '
      'por meio da biblioteca parselmouth. Nenhuma análise é realizada neste '
      'aparelho.';
  static String contaVersao(String versao) => 'Versão: $versao';
  static const contaLicencas = 'Licenças de software';

  /// Barra lateral, enquanto o perfil da conta está vazio (US32).
  static const contaPerfilIncompleto =
      'Preencha o nome e o registro na tela Conta';
  static const contaSair = 'Sair da conta';
  static const contaSairPergunta = 'Sair da conta neste aparelho?';

  // Decisão (US40): o que é da conta fica no aparelho depois de sair — a
  // fila tem gravação que ainda não subiu, e apagar perderia voz de paciente
  // que não se grava de novo —, mas só a mesma conta o vê ao entrar. Outra
  // conta neste aparelho não alcança nada dela.
  static const contaSairTexto =
      'Os pacientes, as gravações e os laudos permanecem armazenados neste '
      'aparelho e ficam visíveis somente para esta conta, quando ela entrar '
      'novamente.';
  static String contaSairComFila(int n) => n == 1
      ? 'Há 1 envio na fila. Ele será suspenso, permanecerá neste aparelho e '
            'será retomado quando você entrar novamente.'
      : 'Há $n envios na fila. Eles serão suspensos, permanecerão neste '
            'aparelho e serão retomados quando você entrar novamente.';
  static const contaConfirmarSair = 'Sair';
  static const contaCancelar = 'Cancelar';
  static const contaSaindo = 'Saindo…';

  // Troca de senha (US45).
  static const contaSenhaTitulo = 'Senha';
  static const contaSenhaApoio =
      'A nova senha vale para a entrada em qualquer aparelho e, neste, também '
      'sem conexão. Nos demais aparelhos, será solicitada uma nova entrada na '
      'conta.';
  static const contaSenhaTrocar = 'Alterar a senha';
  static const contaSenhaTrocando = 'Alterando…';
  static const contaSenhaCampoAtual = 'Senha atual';
  static const contaSenhaCampoNova = 'Senha nova';
  static const contaSenhaCampoConfirmacao = 'Repita a senha nova';
  static const contaSenhaInformeAtual = 'Informe a senha atual.';
  static const contaSenhaAtualNaoConfere =
      'A senha atual está incorreta. Verifique e tente novamente.';
  static const contaSenhaNovaIgual = 'A nova senha é igual à atual.';
  static const contaSenhaTrocada = 'Senha alterada.';
  static const contaSenhaPrecisaConexao =
      'A alteração da senha exige conexão com a internet.';
  static const contaSenhaExemplo =
      'No modo de exemplo, a entrada aceita qualquer senha; portanto, não há '
      'senha a ser alterada.';

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
  static const _mesesPorExtenso = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  /// "setembro de 2026".
  static String mesEAno(DateTime d) =>
      '${_mesesPorExtenso[d.month - 1]} de ${d.year}';

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
      'Gravação guiada, medidas acústicas e acompanhamento da evolução do '
      'paciente, como apoio à decisão do profissional. O FONAR não emite '
      'diagnóstico.';
  static const loginCampoEmail = 'E-mail';
  static const loginCampoSenha = 'Senha';
  static const loginManterConectado = 'Manter conectado neste aparelho';
  static const loginInformeEmail = 'Informe o e-mail.';
  static const loginInformeSenha = 'Informe a senha.';
  static const loginBotaoEntrar = 'Entrar';
  static const loginBotaoEntrando = 'Entrando…';
  static const loginEntrarExigeConexao =
      'A entrada com e-mail e senha exige conexão com a internet.';
  static const loginEsqueciSenha = 'Esqueci a senha';
  static const loginSemConta = 'Ainda não tem conta no FONAR?';
  static const loginCriarConta = 'Criar conta';

  // "Esqueci a senha" — a tela própria do pedido (US58).
  static const recuperarTitulo = 'Recuperar a senha';
  static const recuperarTexto =
      'Informe o e-mail da sua conta. Será enviado um link para a criação de '
      'uma nova senha.';
  static const recuperarInformeEmail = 'Informe o e-mail da conta.';
  static const recuperarEnviar = 'Enviar link';
  static const recuperarEnviando = 'Enviando…';
  static const recuperarExigeConexao =
      'A solicitação do link exige conexão com a internet.';
  static String recuperarPedidoPara(String email) =>
      'Solicitação registrada para $email.';
  static const recuperarEnviarDeNovo = 'Não recebeu? Enviar novamente';
  static const recuperarOutroEmail = 'Usar outro e-mail';
  static const recuperarVoltar = 'Voltar à tela de entrada';

  static const loginRecuperacaoEmailInvalido =
      'O e-mail informado não é um endereço válido. Verifique e corrija.';
  static const loginRecuperacaoEnviadaTitulo = 'Verifique o seu e-mail';

  /// Igual com ou sem conta para o e-mail: dizer "não há conta" seria dizer
  /// a qualquer um quem usa o FONAR.
  static const loginRecuperacaoEnviadaTexto =
      'Se houver uma conta FONAR com este e-mail, o link para a criação de uma '
      'nova senha será recebido em alguns minutos. Verifique também a pasta '
      'de spam.';
  static const loginRecuperacaoIndisponivel =
      'Recuperação de senha indisponível no login de exemplo';
  static const loginRecuperacaoIndisponivelTexto =
      'No modo de exemplo, o aplicativo não envia e-mail de redefinição.';

  /// PLACEHOLDER — o modo de exemplo (`AppConfig.exemplo`).
  static const loginExemploTitulo = 'Login de exemplo';
  static const loginExemploTexto =
      'Esta versão está no modo de exemplo: a entrada aceita qualquer e-mail '
      'e senha. Destina-se exclusivamente ao desenvolvimento.';

  static const loginOfflineComCacheTitulo =
      'Sem conexão — dados locais disponíveis';
  static String loginOfflineComCacheTexto(int pacientes) =>
      'Este aparelho tem $pacientes '
      '${pacientes == 1 ? 'paciente salvo' : 'pacientes salvos'}. É possível '
      'gravar e revisar; o envio para análise aguardará o restabelecimento da '
      'conexão.';
  static const loginEntrarOffline = 'Entrar em modo sem conexão';
  static String loginOfflineComo(String email) =>
      'A entrada será feita como $email, com a senha dessa conta.';
  static const loginSemRedeSenhaNaoConfere =
      'A senha não corresponde à utilizada na última entrada neste aparelho.';
  static const loginSemRedeSemSenhaGuardada =
      'Esta conta ainda não entrou com conexão desde que o FONAR passou a '
      'verificar a senha sem conexão. Conecte-se e entre uma vez para '
      'habilitar o recurso.';
  static const loginOfflineSemContaTexto =
      'O modo sem conexão utiliza a conta da última entrada com senha neste '
      'aparelho, e ainda não houve nenhuma. Conecte-se e entre uma vez para '
      'habilitá-lo.';

  static const loginOfflineSemCacheTitulo = 'Sem conexão e sem dados locais';
  static const loginOfflineSemCacheTexto =
      'Este aparelho ainda não possui pacientes salvos. Conecte-se ao menos '
      'uma vez para obter os seus pacientes e habilitar o modo sem conexão.';
  static const loginOfflineIndisponivel = 'Modo sem conexão indisponível';

  /// Rodapé de toda tela de entrada. O sistema é apoio à decisão e nenhum
  /// texto pode sugerir o contrário — este diz isso antes do primeiro uso.
  static const avisoApoioDecisao =
      'Ferramenta de apoio à decisão — não substitui a avaliação do '
      'profissional.';

  // ------------------------------------------------------------ cadastro --
  // Criar conta, confirmar o e-mail e preencher o cadastro (US34). O cadastro
  // é aberto: a pessoa já usa o app enquanto a equipe confere a inscrição no
  // Crefono (ADR-015 da API).
  static const criarContaTitulo = 'Criar conta';
  static const criarContaApoio =
      'Crie a conta com o seu e-mail e informe a sua inscrição no Conselho '
      'Regional de Fonoaudiologia. A equipe do FONAR conferirá a inscrição e '
      'a carteira de identidade profissional, que poderá ser enviada após a '
      'criação da conta, na tela Conta. Até a conclusão dessa conferência, '
      'todas as funções estão disponíveis, exceto a emissão de laudos.';
  static const criarContaSecaoConta = 'Sua conta';
  static const criarContaSecaoRegistro = 'Registro profissional';
  static const criarContaCampoConfirmacao = 'Repita a senha';
  static const criarContaSenhaApoio = 'Mínimo de 8 caracteres.';
  static const criarContaBotao = 'Criar conta';
  static const criarContaCriando = 'Criando a conta…';
  static const criarContaJaTenho = 'Já tenho conta';

  static const registroCampoNome = 'Nome completo';
  static const cadastroNomeApoio = 'Nome que constará na assinatura do laudo.';
  static const cadastroCampoRegiao = 'Região do Conselho Regional (CRFa)';
  static String cadastroRegiao(int regiao, String estados) =>
      '$regiaoª · $estados';
  static const cadastroCampoInscricao = 'Número de inscrição';
  static const cadastroInscricaoDica = 'por exemplo: 12345';
  static const cadastroInscricaoApoio =
      'Informe somente o número, como publicado pelo conselho, sem “CRFa” e '
      'sem a região.';
  static const cadastroTermosRotulo =
      'Li e aceito os termos de uso e a política de privacidade do FONAR.';

  /// Os termos de uso e a política de privacidade (US43, reescritos em
  /// linguagem formal na US64), em cláusulas numeradas. Ao mudar qualquer
  /// palavra, mude também `versaoDosTermos` (`cadastro/domain/cadastro.dart`):
  /// a API grava a versão aceita, com a data. Revisão jurídica recomendada
  /// (PENDENCIAS.md).
  static const cadastroTermosTitulo = 'Termos de uso e política de privacidade';
  static const cadastroTermosIntroducao =
      'Leia com atenção os termos abaixo antes de concluir o cadastro. O '
      'aceite é registrado com a data e a versão destes termos e é condição '
      'para a utilização do FONAR.';
  static const cadastroTermosClausulas = <({String titulo, String texto})>[
    (
      titulo: '1. Objeto',
      texto:
          'O FONAR é um sistema de apoio à avaliação vocal clínica destinado '
          'exclusivamente a fonoaudiólogos regularmente inscritos em Conselho '
          'Regional de Fonoaudiologia. O sistema permite registrar pacientes '
          'e o consentimento deles, gravar amostras de voz, obter medidas '
          'acústicas, registrar a avaliação perceptivo-auditiva (CAPE-V), '
          'acompanhar a evolução do paciente e emitir laudo de avaliação '
          'vocal.',
    ),
    (
      titulo: '2. Natureza da ferramenta',
      texto:
          'O FONAR é ferramenta de apoio à decisão clínica e não emite '
          'diagnóstico. As medidas acústicas são calculadas pelo motor do '
          'Praat, software desenvolvido de forma independente na Universidade '
          'de Amsterdam, sem vínculo com o FONAR. A interpretação das medidas, '
          'a conclusão clínica e o conteúdo do laudo são de responsabilidade '
          'exclusiva do profissional que os assina. Uma medida somente é '
          'classificada em relação a uma faixa de referência quando existe '
          'faixa validada para o perfil do paciente; na ausência dela, o valor '
          'é apresentado sem classificação.',
    ),
    (
      titulo: '3. Cadastro e verificação profissional',
      texto:
          'O profissional declara que as informações prestadas no cadastro — '
          'nome completo, região do Conselho Regional de Fonoaudiologia e '
          'número de inscrição — são verdadeiras e pertencem a ele. Para '
          'concluir o credenciamento, o profissional deverá enviar uma imagem '
          'ou um arquivo PDF da sua carteira de identidade profissional. A '
          'equipe do FONAR conferirá esse documento e a consulta pública de '
          'inscritos do respectivo conselho. Enquanto o credenciamento não '
          'for concluído, a emissão de laudos permanece bloqueada. O '
          'credenciamento poderá ser revogado a qualquer tempo caso se '
          'constate informação falsa, inscrição cancelada ou suspensa, ou uso '
          'em desacordo com estes termos.',
    ),
    (
      titulo: '4. Uso proibido',
      texto:
          'É vedado: utilizar o FONAR em nome de outra pessoa ou com dados de '
          'inscrição de terceiros; emitir laudo sobre avaliação que não tenha '
          'sido realizada pelo próprio profissional; utilizar laudos ou '
          'medidas para fins diversos da atenção fonoaudiológica, inclusive '
          'para produzir documento falso; e compartilhar a senha de acesso. '
          'A falsidade de informações e o uso de documento falso podem '
          'configurar crime, nos termos da legislação penal, sem prejuízo das '
          'sanções éticas aplicáveis pelo conselho de classe.',
    ),
    (
      titulo:
          '5. Responsabilidades do profissional sobre os dados dos pacientes',
      texto:
          'Em relação aos dados dos pacientes, o profissional é o controlador, '
          'nos termos da Lei Geral de Proteção de Dados Pessoais (Lei nº '
          '13.709/2018), e o FONAR atua como operador, tratando esses dados '
          'exclusivamente em nome do profissional e para a prestação do '
          'serviço. Compete ao profissional: registrar o consentimento do '
          'paciente, ou de seu responsável legal, antes de qualquer gravação; '
          'atender às solicitações dos pacientes quanto aos seus dados; e '
          'manter o registro dos atendimentos conforme as normas do conselho '
          'profissional. A voz vinculada a um paciente identificado é dado '
          'pessoal sensível referente à saúde.',
    ),
    (
      titulo: '6. Dados do profissional',
      texto:
          'O FONAR trata o nome, o endereço de e-mail, a região e o número de '
          'inscrição do profissional, a versão e a data de aceite destes '
          'termos e, temporariamente, a imagem da carteira de identidade '
          'profissional. Esses dados são utilizados para identificar o '
          'profissional, conferir a sua inscrição e constar como assinatura '
          'nos laudos emitidos. A imagem da carteira é acessível somente à '
          'equipe responsável pela conferência e é excluída definitivamente '
          'após a conclusão do credenciamento, permanecendo registrada apenas '
          'a data da conferência. Não são coletados CPF, endereço, telefone '
          'ou outros dados além dos aqui descritos.',
    ),
    (
      titulo: '7. Armazenamento, transferência e segurança',
      texto:
          'Os dados são armazenados na infraestrutura do Google Cloud '
          '(Firebase). Os cadastros, as medidas e os laudos ficam em '
          'servidores localizados no Brasil (São Paulo); os arquivos de '
          'gravação de voz ficam em servidores localizados nos Estados '
          'Unidos, o que configura transferência internacional de dados. '
          'Todas as comunicações são cifradas, e cada conta tem acesso '
          'exclusivamente aos dados dos próprios pacientes.',
    ),
    (
      titulo: '8. Senha e segurança do acesso',
      texto:
          'A senha dá acesso a dados de saúde, inclusive quando o aparelho '
          'está sem conexão. O profissional deve mantê-la em sigilo, não a '
          'compartilhar e manter o aparelho protegido por bloqueio de tela. A '
          'opção "Manter conectado neste aparelho" deve ser utilizada somente '
          'em aparelho de uso pessoal.',
    ),
    (
      titulo: '9. Direitos do titular',
      texto:
          'O profissional pode, a qualquer tempo, solicitar a confirmação da '
          'existência de tratamento, o acesso, a correção, a anonimização ou a '
          'eliminação dos seus dados, além das demais medidas previstas no '
          'art. 18 da Lei Geral de Proteção de Dados Pessoais. Nome e '
          'inscrição podem ser corrigidos diretamente na tela Conta; a '
          'alteração da região ou do número de inscrição exige nova '
          'conferência.',
    ),
    (
      titulo: '10. Natureza acadêmica e disponibilidade',
      texto:
          'O FONAR é um projeto acadêmico, desenvolvido como Trabalho de '
          'Conclusão de Curso de Engenharia de Software da Pontifícia '
          'Universidade Católica de Campinas (PUC-Campinas). O serviço é '
          'oferecido sem garantia de disponibilidade contínua e pode ser '
          'interrompido ou encerrado. Recomenda-se que o profissional mantenha '
          'cópia dos laudos emitidos.',
    ),
    (
      titulo: '11. Alterações destes termos',
      texto:
          'Estes termos podem ser alterados. As alterações serão comunicadas '
          'aos profissionais cadastrados, e a versão aceita por cada '
          'profissional permanece registrada com a data do aceite.',
    ),
  ];
  static const registroInformeNome = 'Informe o nome completo.';
  static const cadastroNomeLongo = 'O nome excede o limite de 200 caracteres.';
  static const cadastroInformeRegiao =
      'Selecione a região do Conselho Regional em que você está inscrito(a).';
  static const cadastroInformeInscricao = 'Informe o número de inscrição.';
  static const cadastroInscricaoInvalida =
      'Informe somente o número: algarismos (e, em alguns casos, letra, '
      'ponto, barra ou hífen), com até 20 caracteres, sem “CRFa” e sem a '
      'região.';
  static const cadastroAceiteTermos =
      'Para concluir o cadastro, é necessário aceitar os termos.';
  static const cadastroInformeEmail = 'Informe o e-mail.';
  static const cadastroEmailInvalido =
      'O e-mail informado não é um endereço válido. Verifique e corrija.';
  static const cadastroSenhaCurta =
      'A senha deve conter no mínimo 8 caracteres.';
  static const cadastroSenhasDiferentes = 'As senhas informadas não coincidem.';

  static const verificarEmailTitulo = 'Confirme o seu e-mail';
  static String verificarEmailTexto(String email) =>
      'Um link de confirmação foi enviado para $email. Abra a mensagem, toque '
      'no link e retorne a esta tela. Verifique também a pasta de spam.';
  static const verificarEmailSemConta =
      'Um link de confirmação foi enviado para o seu e-mail. Abra a mensagem, '
      'toque no link e retorne a esta tela. Verifique também a pasta de spam.';
  static const verificarEmailJaConfirmei = 'Já confirmei';
  static const verificarEmailConferindo = 'Verificando…';
  static const verificarEmailAindaNaoTitulo = 'Ainda não confirmado';
  static const verificarEmailAindaNao =
      'O e-mail ainda não consta como confirmado. Abra o link recebido por '
      'e-mail e toque novamente em “Já confirmei”.';
  static const verificarEmailReenviar = 'Reenviar o e-mail';
  static const verificarEmailReenviadoTitulo = 'E-mail reenviado';
  static const verificarEmailReenviado =
      'O novo link será recebido em alguns minutos. O link anterior deixa de '
      'ser válido.';
  static const verificarEmailOutraConta = 'Entrar com outra conta';

  static const completarCadastroTitulo = 'Complete o seu cadastro';
  static const completarCadastroApoio =
      'O seu e-mail foi confirmado. Falta informar o registro profissional, '
      'que será conferido pela equipe do FONAR na consulta pública do '
      'Conselho Regional de Fonoaudiologia.';
  static const completarCadastroBotao = 'Concluir cadastro';
  static const completarCadastroSalvando = 'Salvando…';

  // ------------------------------------------------ anotações (US51) --
  // Prontuário: nada se apaga, e editar guarda a versão de antes. Não
  // depende do consentimento — ele cobre a voz, não o atendimento.
  static const anotacoesTitulo = 'Anotações';
  static const anotacoesApoio =
      'Registro do atendimento. Nenhuma anotação é excluída: a edição '
      'preserva a versão anterior.';
  static const anotacoesCampo = 'Nova anotação';
  static const anotacoesLembrar = 'Lembrar na próxima consulta';
  static const anotacoesSalvar = 'Salvar anotação';
  static const anotacoesSalvando = 'Salvando…';
  static const anotacoesVazio = 'Ainda não há anotações.';
  static const anotacoesTextoObrigatorio = 'Redija a anotação antes de salvar.';
  static String anotacoesTextoLongo(int maximo) =>
      'A anotação excede o limite de $maximo caracteres. Divida o texto em '
      'duas anotações.';
  static const anotacoesEditar = 'Editar';
  static const anotacoesCampoEdicao = 'Editar a anotação';
  static const anotacoesSalvarEdicao = 'Salvar edição';
  static const anotacoesCancelar = 'Cancelar';
  static String anotacoesEditadaEm(String data) => 'editada em $data';
  static const anotacoesComLembrete = 'Com lembrete para a próxima consulta';
  static String anotacoesVerAnteriores(int n) =>
      n == 1 ? 'Ver a versão anterior' : 'Ver as $n versões anteriores';
  static const anotacoesEsconderAnteriores = 'Esconder as versões anteriores';
  static String anotacoesVersaoDe(String data) => 'Versão de $data';
  static const anotacoesErroCarregar =
      'Não foi possível carregar as anotações. Feche e abra o perfil '
      'novamente.';
  static const anotacoesErroSalvar =
      'Não foi possível salvar a anotação. Tente novamente.';
  static const anotacoesExemplo =
      'Paciente de exemplo: as anotações estão disponíveis somente para '
      'pacientes cadastrados.';

  // O lembrete da próxima consulta: discreto, e o texto só aparece ao
  // tocar — às vezes o paciente vê a tela.
  static String lembreteUm(String diaEMes) =>
      'Há um lembrete registrado na consulta de $diaEMes';
  static String lembreteVarios(int n) =>
      'Há $n lembretes registrados em consultas anteriores';
  static const lembreteMostrar = 'Mostrar';
  static const lembreteEsconder = 'Esconder';
  static const lembreteVi = 'Marcar como visto';
  static const lembreteSelo = 'Lembrete';
  static String lembreteSeloSemantica(String nome) =>
      '$nome tem lembrete para esta consulta';
  static String lembreteDaConsulta(String diaEMes) => 'Consulta de $diaEMes';

  /// "12/10" — o dia da consulta, como se fala no consultório.
  static String diaEMes(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------- guia e ajuda --
  // O guia da primeira vez (US50): um passo por elemento da tela inicial.
  // Cada título diz O QUE é o elemento, com o nome que ele tem na tela — o
  // recorte não é a única pista.
  static const ajuda = 'Ajuda';
  static const ajudaReverGuia = 'Rever o guia';
  static const ajudaAtalhos = 'Atalhos de teclado';

  static String guiaPasso(int atual, int total) => 'Passo $atual de $total';
  static const guiaRotulo = 'Guia do FONAR';
  static const guiaPular = 'Pular o guia';
  static const guiaAnterior = 'Anterior';
  static const guiaProximo = 'Próximo';
  static const guiaConcluir = 'Concluir';

  static const guiaNovaAvaliacaoTitulo = navNovaAvaliacao;
  static const guiaNovaAvaliacaoTexto =
      'Este botão inicia o cadastro do paciente, o registro do consentimento '
      'e a gravação da voz. Pacientes já cadastrados são reavaliados a partir '
      'do respectivo perfil.';
  static const guiaListaTitulo = 'Pacientes';
  static const guiaListaTexto =
      'Cada paciente da lista dá acesso ao respectivo perfil: consentimento, '
      'sessões, resultados, CAPE-V, evolução e laudo.';
  static const guiaListaVaziaTexto =
      'Os pacientes cadastrados são exibidos nesta tela. Cada um dá acesso ao '
      'respectivo perfil: consentimento, sessões, resultados, CAPE-V, '
      'evolução e laudo.';
  static const guiaFilaTitulo = navFila;
  static const guiaFilaTexto =
      'Cada gravação aguarda nesta fila até ser recebida pela análise. Sem '
      'conexão, nenhum dado é perdido: o envio é retomado automaticamente '
      'quando a conexão é restabelecida.';
  static const guiaContaTitulo = navConta;
  static const guiaContaTexto =
      'Dados profissionais, situação do credenciamento, alteração de senha e '
      'aparência (tema claro ou escuro e tamanho da interface).';
  static const guiaConexaoTitulo = 'Conexão';
  static const guiaConexaoTexto =
      'Indica se o aparelho está conectado. A gravação funciona sem conexão; '
      'a análise depende dela.';
  static const guiaAjudaTitulo = ajuda;
  static const guiaAjudaTexto =
      'Permite rever este guia e consultar os atalhos de teclado.';

  // As dicas de primeira vez por tela (US50): uma vez cada, por conta, neste
  // aparelho.
  static const dicaRotulo = 'Dica';
  static const dicaEntendi = 'Entendi';
  static const dicaGravacaoTexto =
      'A gravação inicia por esta etapa: 5 segundos de silêncio para medir o '
      'ruído ambiente. Se o microfone não captar som, a gravação não é '
      'liberada. Em seguida, as tarefas são apresentadas uma de cada vez, com '
      'a instrução em destaque para o paciente. No teclado, a barra de espaço '
      'inicia e interrompe a gravação, e a tecla R grava a etapa novamente.';
  static const dicaResultadoTexto =
      'As medidas são calculadas no servidor a partir das gravações. Elas '
      'somente são classificadas quando há faixa de referência validada para '
      'o perfil do paciente; sem ela, o aplicativo exibe o valor e informa o '
      'motivo. Trata-se de apoio à decisão, e não de diagnóstico.';
  static const dicaCapeVTexto =
      'Ouça a amostra e marque cada parâmetro na escala: na extremidade '
      'esquerda, ausência de desvio; na extremidade direita, desvio extremo. '
      'A avaliação corresponde ao julgamento perceptivo-auditivo do '
      'profissional; o aplicativo apenas a registra.';
  static const dicaLaudoTexto =
      'Esta área indica o que falta para emitir o laudo: há itens que impedem '
      'a emissão e itens que apenas geram aviso. O laudo emitido não é '
      'alterado posteriormente; uma nova emissão gera outro documento, que '
      'indica qual laudo substitui.';

  // Só os atalhos que existem: cada linha corresponde a uma tecla tratada
  // no código (gravação guiada e espectrograma).
  static const atalhosTitulo = 'Atalhos de teclado';
  static const atalhosFechar = 'Fechar';
  static const atalhosEmQualquerTela = 'Em qualquer tela';
  static const atalhosTab = 'Tab e Shift+Tab';
  static const atalhosTabTexto = 'Move o foco para o controle seguinte.';
  static const atalhosAtivar = 'Enter ou barra de espaço';
  static const atalhosAtivarTexto = 'Aciona o controle em destaque.';
  static const atalhosEsc = 'Esc';
  static const atalhosEscTexto = 'Fecha a janela aberta, como esta.';
  static const atalhosNaGravacao = 'Na gravação';
  static const atalhosEspaco = 'Barra de espaço';
  static const atalhosEspacoTexto =
      'Mede o ruído ambiente e inicia ou interrompe a gravação da etapa.';
  static const atalhosR = 'R';
  static const atalhosRTexto = 'Grava a etapa novamente.';
  static const atalhosNoEspectrograma = 'No espectrograma';
  static const atalhosSetas = 'Setas';
  static const atalhosSetasTexto = 'Percorrem a imagem ampliada.';
  static const atalhosMais = '+ e −';
  static const atalhosMaisTexto = 'Aproximam e afastam a imagem.';
  static const atalhosZero = '0';
  static const atalhosZeroTexto = 'Exibe a imagem inteira.';

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
      'E-mail ou senha incorretos. Verifique e tente novamente.';
  static const erroMuitasTentativas =
      'Foram realizadas muitas tentativas consecutivas. Por segurança, o '
      'acesso a esta conta foi suspenso por alguns minutos. Aguarde e tente '
      'novamente, ou redefina a senha.';
  static const erroContaDesativada =
      'Esta conta foi desativada. Entre em contato com a equipe do FONAR.';
  static const erroProibido = 'Você não tem acesso a este recurso.';
  static const erroEmailIndisponivel =
      'Não foi possível criar uma conta com este e-mail. Caso já possua conta '
      'no FONAR, entre com ela ou utilize a opção “Esqueci a senha”.';
  static const erroEmailInvalido =
      'O e-mail informado não é um endereço válido. Verifique e corrija.';
  static const erroSenhaFraca =
      'A senha não atende aos requisitos de segurança. Utilize no mínimo 8 '
      'caracteres, combinando letras e números.';
  static const erroNaoEncontrado = 'O conteúdo solicitado não foi encontrado.';
  static const erroValidacao =
      'Verifique os dados informados e tente novamente.';
  static const erroServidor =
      'Houve uma falha no servidor. Tente novamente em alguns instantes.';
  static const erroEnvioCancelado = 'O envio foi cancelado.';
  static const erroSemConsentimentoNoServidor =
      'O servidor não encontrou consentimento em vigor para este paciente. '
      'Registre novamente o consentimento antes de enviar.';
  static const erroGravacaoNaoEncontrada =
      'O arquivo da gravação não está mais disponível neste aparelho, e sem '
      'ele a análise não pode ser realizada. Grave a sessão novamente.';
  static const erroDesconhecido =
      'Ocorreu um erro inesperado. Tente novamente.';
}
