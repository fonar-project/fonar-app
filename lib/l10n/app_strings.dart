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

  // ------------------------------------------------------- rota de erro --
  static const rotaNaoEncontradaTitulo = 'Esta tela não existe';
  static const rotaNaoEncontradaTexto =
      'O endereço pode ter mudado, ou o que ele mostrava não está mais neste '
      'aparelho.';
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
  static const situacaoLaudo = 'Apoio à decisão — o laudo é do profissional';
  static const situacaoConsentimentoRegistrado = 'Consentimento registrado';
  static const situacaoFila = 'Gravado no aparelho — nada se perde sem conexão';
  static const historicoTitulo = 'Histórico';
  static const historicoDescricao =
      'Todas as avaliações feitas neste aparelho, da mais recente para a mais '
      'antiga.';
  static const historicoBuscaDica = 'Buscar por paciente ou queixa';
  static const historicoVazioTitulo = 'Nenhuma avaliação ainda';
  static const historicoVazioTexto =
      'Depois da primeira gravação enviada, as avaliações aparecem aqui.';
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

  // ------------------------------------------------ sair sem salvar --
  static const saidaTitulo = 'Sair sem salvar?';
  static const saidaTexto =
      'O que foi preenchido aqui ainda não foi salvo e vai se perder.';
  static const saidaDescartar = 'Sair e descartar';
  static const saidaContinuar = 'Continuar preenchendo';

  // ------------------------------------------------ paciente duplicado --
  static const duplicadoTitulo =
      'Já existe um paciente com este nome e data de nascimento';
  static String duplicadoTexto(String nome, String nascimento) =>
      '$nome, nascimento em $nascimento. Se for a mesma pessoa, abra o '
      'cadastro que já existe: dois cadastros partem o histórico em dois.';
  static const duplicadoAbrirExistente = 'Abrir o cadastro existente';
  static const duplicadoSalvarMesmoAssim = 'É outra pessoa: salvar';

  // ---------------------------------------------- edição dos dados --
  static const edicaoTitulo = 'Editar dados do paciente';
  static const edicaoSalvar = 'Salvar alterações';
  static const edicaoAvisoTitulo =
      'Sexo e nascimento escolhem a faixa de referência';
  static const edicaoAvisoTexto =
      'Corrigir aqui muda a classificação das medidas em todas as sessões '
      'deste paciente. Laudos já gerados continuam como saíram.';
  static const edicaoExemplo = 'Paciente de exemplo: os dados não se editam.';

  // --------------------------------------------------------- consentimento --
  static const voltar = 'Voltar';
  static String consentimentoPaciente(String nome) => 'Paciente: $nome';
  static const consentimentoMostreAoPaciente =
      'Mostre esta tela ao paciente, ou leia o termo em voz alta.';

  // O termo de consentimento (US43), escrito sobre a LGPD: consentimento
  // específico e em destaque para dado de saúde (art. 11, I) e para a
  // transferência internacional (art. 33, VIII), com finalidade, guarda,
  // direitos e retirada. Ao mudar qualquer palavra, mude também
  // `versaoAtualDoTermo` (repositório de consentimento): cada registro diz
  // com qual texto a pessoa concordou. Revisão jurídica recomendada antes
  // do uso com pacientes (PENDENCIAS.md).
  static const consentimentoTermoTitulo = 'Termo de consentimento';
  static const consentimentoTermoItens = [
    'O que é gravado: a sua voz, durante esta consulta — uma vogal '
        'sustentada e uma fala curta. Junto ficam o seu cadastro (nome, data '
        'de nascimento, sexo e queixa), as medidas calculadas a partir da '
        'gravação e a avaliação do profissional.',
    'Para quê: avaliar a sua voz e acompanhar a evolução dela nas próximas '
        'consultas. As medidas apoiam o julgamento do profissional que '
        'atende você; o sistema não faz diagnóstico.',
    'Quem é responsável: o profissional que atende você. O FONAR é a '
        'ferramenta que ele usa, e trata os dados só para isso, em nome '
        'dele. Os dados não são vendidos nem usados para outra finalidade.',
    'Onde ficam: a gravação é enviada por conexão cifrada a servidores do '
        'Google Cloud, onde as medidas são calculadas. O cadastro e as '
        'medidas ficam no Brasil (São Paulo); o arquivo da gravação fica nos '
        'Estados Unidos. Concordar inclui essa transferência.',
    'Por quanto tempo: enquanto forem necessários ao seu atendimento e pelo '
        'tempo em que o profissional tem o dever de guardar o registro dele '
        '(prontuário).',
    'Seus direitos: pedir ao profissional para ver, corrigir ou eliminar os '
        'seus dados, e saber com quem eles são compartilhados (LGPD, art. '
        '18). Voz ligada a você é dado pessoal sensível.',
    'Você pode retirar este consentimento a qualquer momento, pedindo ao '
        'profissional. A partir daí nada novo é gravado ou analisado; o que '
        'já foi feito continua no registro do atendimento, a não ser que '
        'você peça a eliminação.',
    'Não concordar não impede o atendimento: só a gravação e as medidas '
        'acústicas deixam de ser feitas. Quem autoriza como responsável '
        'legal declara ter essa responsabilidade pelo paciente.',
  ];

  static const consentimentoCampoQuem = 'Quem autoriza';
  static const consentimentoQuemPaciente = 'O próprio paciente';
  static const consentimentoQuemResponsavel = 'Responsável legal';
  static const consentimentoQuemApoio =
      'Quando o paciente não pode autorizar sozinho — por exemplo, uma '
      'criança —, quem autoriza é o responsável legal.';
  // US43: eliminação dos dados, a pedido do paciente (LGPD, art. 18, VI).
  static const perfilEliminarTitulo = 'Eliminar os dados do paciente';
  static const perfilEliminarTexto =
      'A pedido do paciente (LGPD, art. 18). Apaga para sempre, neste '
      'aparelho e no servidor, o cadastro, os consentimentos, as gravações, '
      'as análises, a CAPE-V, os laudos e as anotações.';
  static const perfilEliminarAcao = 'Eliminar os dados';
  static String perfilEliminarConfirmarTitulo(String nome) =>
      'Eliminar os dados de $nome?';
  static const perfilEliminarConfirmarTexto =
      'Não dá para desfazer: nada volta, nem do servidor. Antes, pese o '
      'pedido contra o dever de guardar o registro do atendimento '
      '(prontuário).';
  static const perfilEliminarConfirmar = 'Eliminar';
  static const perfilEliminarCancelar = 'Manter os dados';
  static const perfilEliminando = 'Eliminando…';
  static const perfilEliminarExigeConexao =
      'A eliminação exige conexão: o que está no servidor sai junto.';

  static const consentimentoQuemApoioMenor =
      'Paciente menor de 18 anos: quem autoriza é o responsável legal.';
  static const consentimentoMenorExigeResponsavel =
      'Paciente menor de 18 anos: a autorização é do responsável legal.';
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
  ///
  /// Aparece depois da conferência com a voz: nem a voz chegou.
  static const afericaoMudoTexto =
      'Nem a voz chegou ao microfone, e a gravação fica bloqueada até ele '
      'captar som. Se houver mais de um microfone, escolha outro nesta tela. '
      'No Windows, abra Configurações > Privacidade e segurança > Microfone '
      'e ative o acesso ao microfone, inclusive para aplicativos da área de '
      'trabalho. No Android, confira a permissão de microfone do FONAR. '
      'Depois, meça de novo.';

  /// A sala deu silêncio digital — sala silenciosa de verdade com um
  /// microfone que zera o sinal, ou microfone que não capta. Só a voz
  /// separa os dois (`AfericaoDeRuido.concluirComAVoz`).
  static const afericaoSilencio = 'Não chegou som nenhum';
  static const afericaoSilencioTexto =
      'Pode ser a sala em silêncio total ou o microfone sem captar. Toque em '
      '"Conferir com a voz" e diga algumas palavras perto do microfone.';
  static const afericaoConferirComAVoz = 'Conferir com a voz';
  static const afericaoSalaSilenciosa = 'Sala silenciosa e microfone captando';
  static const afericaoSalaSilenciosaTexto =
      'O ruído da sala ficou abaixo do que o microfone mede, e a voz chegou.';

  // Teste de homologação de 18/10/2026: sem escolher o microfone, o FONAR
  // gravava do padrão do sistema — no Windows com DroidCam, um virtual mudo.
  static const microfoneRotulo = 'Microfone';
  static const microfonePadrao = 'Padrão do sistema';
  static const microfoneApoio =
      'Trocar o microfone mede o ruído da sala de novo.';
  static const microfoneApoioAntesDeMedir =
      'O ruído da sala é medido com este microfone.';
  static String microfoneAusente(String nome) =>
      'O microfone escolhido ($nome) não está conectado. O FONAR está usando '
      'o padrão do sistema.';
  static const microfoneEmbutido = 'Microfone do aparelho';
  static const microfoneFoneComFio = 'Fone com fio';
  static const microfoneUsb = 'Microfone USB';
  static const microfoneEntradaDeLinha = 'Entrada de linha';
  static const microfoneSemNome = 'Microfone';
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
      'A gravação fica bloqueada até o microfone captar som.';

  // US42: no navegador, o processamento automático pode ficar ligado.
  static const capturaProcessamentoLigado =
      'O processamento automático do microfone ficou ligado';

  /// [ligados]: os nomes de [processamentoGanhoAutomatico] e afins, na
  /// ordem em que aparecem.
  static String capturaProcessamentoLigadoTexto(List<String> ligados) =>
      'Este aparelho manteve ligado, ou não confirmou ter desligado: '
      '${_lista(ligados)}. Esse ajuste automático muda justamente o que a '
      'análise mede, e por isso a gravação fica bloqueada aqui. Use o FONAR '
      'instalado no computador ou no Android, ou tente outro navegador.';
  static const processamentoGanhoAutomatico = 'ganho automático';
  static const processamentoSupressaoDeRuido = 'supressão de ruído';
  static const processamentoCancelamentoDeEco = 'cancelamento de eco';

  static const capturaSemArmazenamento = 'Este navegador não guarda os dados';
  static const capturaSemArmazenamentoTexto =
      'O navegador não deu ao FONAR onde guardar os dados (acontece em '
      'algumas janelas privadas), e a gravação se perderia ao fechar a '
      'página. Abra o FONAR numa janela comum ou pelo ícone na tela de '
      'início.';

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
      'Vamos medir o ruído da sala. Fique em silêncio por alguns segundos.';
  static const instrucaoRuidoMedindo = 'Medindo o ruído da sala…';
  static const instrucaoRuidoOk = 'Ambiente adequado para gravar.';
  static const instrucaoRuidoAlto = 'A sala está ruidosa.';
  static const instrucaoRuidoMudo = 'O microfone não está captando som.';
  static const instrucaoRuidoSilencio = 'Não chegou som nenhum.';
  static const instrucaoRuidoConferindoVoz =
      'Diga algumas palavras perto do microfone.';
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
  static const instrucaoVogalGravando = 'Continue… sustente o “aaaa”.';
  static const instrucaoFalaPronto =
      'Conte de 1 a 20, com a sua voz de sempre.';
  static const instrucaoFalaGravando = 'Continue contando… até 20.';
  static const instrucaoProvisoria =
      'Instrução provisória — a validar com a orientação clínica.';
  static const instrucaoConferindo = 'Conferindo a gravação…';
  static const instrucaoAmostraBoa = 'Boa! Amostra registrada.';
  static const instrucaoAmostraRessalva = 'Amostra registrada, com ressalva.';
  static const instrucaoAmostraRecusada =
      'Essa gravação não serviu. Vamos gravar de novo.';

  static const gravandoRotulo = 'Gravando';
  static const capturaContinuar = 'Continuar';
  static const capturaProximaEtapa = 'Próxima etapa';
  static const capturaConcluirERevisar = 'Concluir e revisar';
  static const capturaRegravar = 'Regravar';
  static const capturaAtalhos = 'Espaço inicia e para · R regrava';
  static const capturaEsperaTerminar =
      'Termine a gravação em andamento para mudar de etapa.';

  static const revisaoTitulo = 'Revisão das amostras';
  static const revisaoInstrucao =
      'Tudo gravado. Ouça as amostras antes de enviar.';
  static String revisaoResumo(int gravadas, int total) =>
      '$gravadas de $total tarefas gravadas.';
  static const revisaoVoltar = 'Voltar à gravação';

  // ------------------------------------------------ gravações não enviadas --
  static const naoEnviadasTitulo = 'Gravações não enviadas';
  static const naoEnviadasExplicacao =
      'Sessões de outros dias que ficaram pela metade ou não foram para a '
      'análise. Estão só neste aparelho. Ouça, mande as completas para a '
      'análise ou descarte o que não serve.';
  static const naoEnviadasVazia = 'Nenhuma gravação parada neste aparelho.';
  static String naoEnviadasSessao(String data, String hora) =>
      'Gravada em $data, às $hora';
  static String naoEnviadasTarefas(int gravadas, int total) =>
      '$gravadas de $total tarefas gravadas';
  static const naoEnviadasEnviar = 'Enviar para análise';
  static const naoEnviadasIncompleta =
      'Incompleta: para a análise, é preciso gravar a sessão de novo.';
  static const naoEnviadasSemConsentimento =
      'Sem consentimento em vigor: registre um novo para enviar.';
  static const naoEnviadasDescartar = 'Descartar';

  /// Título e texto do diálogo de confirmação — ver `appConfirmar`.
  static String naoEnviadasDescartarTitulo(int n) =>
      'Descartar ${n == 1 ? 'a gravação' : 'as $n gravações'} desta sessão?';
  static const naoEnviadasDescartarTexto =
      'O áudio é apagado deste aparelho, e não dá para desfazer.';
  static const naoEnviadasDescartarDeVez = 'Descartar de vez';
  static const naoEnviadasManter = 'Manter';
  static const naoEnviadasDescartando = 'Descartando…';
  static const naoEnviadasOcupada = 'Espere a outra sessão terminar.';
  static const naoEnviadasErroDescartar =
      'Não foi possível apagar tudo. A sessão continua aqui; tente de novo.';
  static const naoEnviadasSemArquivo = 'Arquivo não encontrado neste aparelho.';
  static const naoEnviadasFaltaArquivo =
      'Falta arquivo de gravação: descarte a sessão e grave de novo.';
  static const naoEnviadasJaNaFila =
      'Esta sessão já foi para a fila de envio e não se descarta aqui.';
  static const naoEnviadasErroEnviar =
      'Não foi possível pôr a sessão na fila. Tente de novo.';
  static const naoEnviadasErroCarregar =
      'Não foi possível ler as gravações deste aparelho.';
  static const capturaRetomadaTitulo = 'Sessão de hoje retomada';
  static String capturaRetomadaTexto(String hora, int gravadas, int total) =>
      'Começada às $hora. Já gravadas: $gravadas de $total tarefas — '
      'continuam valendo. Regravar uma tarefa substitui a gravação dela.';

  static const tarefaVogalTitulo = 'Vogal sustentada /a/';
  static const tarefaFalaTitulo = 'Fala encadeada';

  static const tarefaParar = 'Parar';
  static String tarefaGravando(String duracao) => 'Gravando… $duracao';
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
  static const problemaProcessamentoLigado =
      'O aparelho manteve ligado o processamento automático do microfone '
      '(ganho, supressão de ruído ou cancelamento de eco), que muda o que a '
      'análise mede. Esta gravação não serve; grave no FONAR instalado no '
      'computador ou no Android.';
  static const problemaFormatoForaDoAceito =
      'O aparelho gravou num formato que a análise não aceita (mais de um '
      'canal, ou taxa fora do intervalo). Grave de novo; se repetir, avise o '
      'suporte antes de usar este aparelho em consulta.';
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
  static const filaEntrarDeNovo = 'Entrar de novo';
  static const filaEntrarExigeConexao =
      'Entrar com a senha exige conexão. A gravação continua guardada.';
  static const filaRecusado = 'A análise recusou o envio';
  static String filaRecusadoTexto(String motivo) =>
      '$motivo Tentar de novo costuma repetir a recusa; se repetir, avise o '
      'suporte.';
  static const filaEnviado = 'Enviado';
  static const filaEnviadoTexto = 'A análise foi recebida pelo servidor.';
  static const filaTentarAgora = 'Tentar agora';
  static const filaTentarDeNovo = 'Tentar de novo';
  static const filaTentarExigeConexao = 'Disponível quando houver conexão.';
  static const filaVerResultado = 'Ver resultado';
  static const filaSemConsentimento = 'Parado: consentimento retirado';
  static const filaSemConsentimentoTexto =
      'O consentimento sob o qual esta gravação foi feita foi retirado, e ela '
      'não sobe mais — um consentimento novo vale para o que for gravado '
      'depois dele. Ela fica guardada neste aparelho, como parte do registro '
      'do atendimento.';

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
  static const resultadoRodape =
      'As faixas de referência vêm de um catálogo configurável (sexo, idade, '
      'equipamento), ainda pendente de validação clínica.';
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

  static const resultadoAindaNaoDisponivel = 'Ainda não disponível';
  static const resultadoAindaNaoDisponivelTexto =
      'O FONAR ainda não calcula esta medida. As outras medidas não dependem '
      'dela.';
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
  static const capeVGireAparelho = 'Gire o aparelho para a escala ficar maior.';
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
  static const resultadoVerEvolucao = 'Ver evolução';
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
  static const perfilEditarDados = 'Editar dados';
  static String perfilNaoEnviadas(int n) => n == 1
      ? '1 sessão gravada neste aparelho não foi para a análise.'
      : '$n sessões gravadas neste aparelho não foram para a análise.';
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

  static const laudoItemAssinatura = 'Seu nome e registro';
  static const laudoItemAssinaturaFalta =
      'Vão na assinatura do laudo. Preencha na Conta.';
  static const laudoIrParaConta = 'Preencher na Conta';
  static const laudoIrParaConsentimento = 'Registrar consentimento';
  static const laudoIrParaCapeV = 'Registrar CAPE-V';

  static const laudoCampoConclusao = 'Conclusão do profissional';

  /// O mesmo limite da API (`TAMANHO_MAXIMO_CONCLUSAO`).
  static const laudoConclusaoMaximo = 10000;
  static const laudoConclusaoApoio =
      'Escrita por você. O FONAR não escreve nem sugere conclusão.';

  static const laudoGerar = 'Gerar laudo';
  static const laudoGerando = 'Gerando…';

  /// Gerar de novo emite OUTRO documento, e é o mesmo botão — por isso
  /// pergunta antes. O de agora não é apagado (US38, ADR-018 da API). Ver
  /// `appConfirmar`.
  static const laudoSubstituirTitulo = 'Emitir um novo laudo?';
  static const laudoSubstituirTexto =
      'O laudo de agora continua guardado como foi emitido. O novo recebe '
      'outro número e diz, no próprio documento, que substitui o anterior.';
  static const laudoSubstituir = 'Emitir novo laudo';
  static const laudoManterOAtual = 'Manter o atual';
  static const laudoGerarBloqueado =
      'Resolva os itens pendentes da conferência para gerar.';
  static String laudoGeradoEm(String codigo, String data, String hora) =>
      'Laudo nº $codigo emitido em $data, às $hora.';

  /// Onde está a cópia do laudo emitido (ADR-018 da API).
  static const laudoNoServidor = 'Cópia guardada no servidor.';
  static const laudoSoNoAparelho =
      'Por enquanto só neste aparelho. A cópia sobe para o servidor quando '
      'houver conexão.';

  /// Os laudos que o vigente substituiu: continuam guardados e saem como
  /// foram emitidos.
  static const laudoAnterioresTitulo = 'Laudos anteriores desta sessão';
  static String laudoAnterior(String codigo, String data, String hora) =>
      'Nº $codigo — emitido em $data, às $hora';
  static const laudoAnteriorSubstituido = 'Substituído pelo laudo seguinte.';
  static const laudoTextoMudou =
      'A conclusão mudou depois da última geração. Gere de novo para o PDF '
      'incluir a mudança.';
  static const laudoCompartilhar = 'Salvar ou compartilhar o PDF';
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
      'Imagem calculada no servidor com o motor do Praat. Apoio visual, não '
      'medida clínica.';
  static const laudoDocEspectrogramaIndisponivel =
      'Não incluído: o servidor não respondeu no momento da emissão.';

  /// Rodapé de toda página: de onde vêm as medidas e de quem é a conclusão.
  static const laudoDocRodape =
      'Medidas acústicas calculadas no servidor com o motor do Praat. '
      'Ferramenta de apoio à decisão: a interpretação e a conclusão são do '
      'profissional que assina.';
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
  static const contaRegistroFormato =
      'Use o formato CRFa 2-12345: a região do Crefono, um hífen e o número.';
  static const contaRegistroTrocado =
      'Trocar a região ou o número põe a inscrição em conferência de novo.';
  static const contaCredenciamentoPendenteTitulo = 'Inscrição em conferência';
  static const contaCredenciamentoPendente =
      'A equipe do FONAR ainda vai conferir sua inscrição na consulta pública '
      'do Crefono. Enquanto isso, você usa o aplicativo normalmente.';
  static const contaCredenciamentoCredenciado =
      'Inscrição conferida pela equipe do FONAR';

  static const contaNesteAparelho = 'Neste aparelho';
  static String contaEnviosPendentes(int n) => switch (n) {
    0 => 'Nenhum envio aguardando na fila.',
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
      'Vale para este aparelho. O laudo em PDF sai sempre em papel branco.';
  static const contaTamanho = 'Tamanho da interface';
  static const contaTamanhoAutomatico = 'Automático';
  static const contaTamanho100 = '100%';
  static const contaTamanho115 = '115%';
  static const contaTamanho130 = '130%';
  static String contaTamanhoApoio(double fator) =>
      'Deixa tudo maior em telas largas, como a do computador. No celular, '
      'quem manda é o tamanho de texto do sistema. Nesta janela, agora: '
      '${(fator * 100).round()}%.';
  static const contaFaixasTitulo = 'Faixas de referência';
  static const contaFaixasPendente = 'Validação clínica pendente';
  static const contaFaixasEmUso = 'Catálogo em uso';
  static const contaFaixasTexto =
      'As faixas que classificam cada medida vêm de um catálogo que varia com '
      'sexo, idade e equipamento de captação. Sem faixa válida para o perfil '
      'do paciente, a medida aparece com o valor e sem classificação.';
  static const contaFaixasVazio =
      'Hoje o catálogo está vazio: nenhuma faixa foi validada por profissional '
      'da área, e nenhuma medida é classificada.';
  static const contaFaixasSoLeitura = 'O catálogo não se edita neste aparelho.';
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

  /// Barra lateral, enquanto o perfil da conta está vazio (US32).
  static const contaPerfilIncompleto = 'Preencha nome e registro na Conta';
  static const contaSair = 'Sair da conta';
  static const contaSairPergunta = 'Sair da conta neste aparelho?';

  // Decisão (US40): o que é da conta fica no aparelho depois de sair — a
  // fila tem gravação que ainda não subiu, e apagar perderia voz de paciente
  // que não se grava de novo —, mas só a mesma conta o vê ao entrar. Outra
  // conta neste aparelho não alcança nada dela.
  static const contaSairTexto =
      'Pacientes, gravações e laudos continuam guardados neste aparelho, '
      'visíveis só para esta conta quando ela entrar de novo.';
  static String contaSairComFila(int n) => n == 1
      ? 'Há 1 envio na fila. Ele pausa, fica neste aparelho e volta a subir '
            'quando você entrar de novo.'
      : 'Há $n envios na fila. Eles pausam, ficam neste aparelho e voltam a '
            'subir quando você entrar de novo.';
  static const contaConfirmarSair = 'Sair';
  static const contaCancelar = 'Cancelar';
  static const contaSaindo = 'Saindo…';

  // Troca de senha (US45).
  static const contaSenhaTitulo = 'Senha';
  static const contaSenhaApoio =
      'A senha nova vale para entrar em qualquer aparelho e, neste, também '
      'sem conexão. Nos outros aparelhos, a conta pede para entrar de novo.';
  static const contaSenhaTrocar = 'Trocar a senha';
  static const contaSenhaTrocando = 'Trocando…';
  static const contaSenhaCampoAtual = 'Senha atual';
  static const contaSenhaCampoNova = 'Senha nova';
  static const contaSenhaCampoConfirmacao = 'Repita a senha nova';
  static const contaSenhaInformeAtual = 'Informe a senha atual.';
  static const contaSenhaAtualNaoConfere =
      'A senha atual não confere. Confira e tente de novo.';
  static const contaSenhaNovaIgual = 'A senha nova é igual à atual.';
  static const contaSenhaTrocada = 'Senha trocada.';
  static const contaSenhaPrecisaConexao = 'Trocar a senha precisa de conexão.';
  static const contaSenhaExemplo =
      'No modo de exemplo, a entrada aceita qualquer senha: não há senha '
      'para trocar.';

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
      'Gravação guiada, medidas acústicas e evolução do paciente — como apoio à '
      'decisão do profissional. O FONAR não emite diagnóstico.';
  static const loginCampoEmail = 'E-mail';
  static const loginCampoSenha = 'Senha';
  static const loginManterConectado = 'Manter conectado neste aparelho';
  static const loginInformeEmail = 'Informe o e-mail.';
  static const loginInformeSenha = 'Informe a senha.';
  static const loginBotaoEntrar = 'Entrar';
  static const loginBotaoEntrando = 'Entrando…';
  static const loginEntrarExigeConexao =
      'Entrar com e-mail e senha exige conexão.';
  static const loginEsqueciSenha = 'Esqueci a senha';
  static const loginSemConta = 'Ainda não tem conta no FONAR?';
  static const loginCriarConta = 'Criar conta';

  // "Esqueci a senha" — a tela própria do pedido (US58).
  static const recuperarTitulo = 'Recuperar a senha';
  static const recuperarTexto =
      'Informe o e-mail da sua conta. Mandamos um link para você criar uma '
      'senha nova.';
  static const recuperarInformeEmail = 'Informe o e-mail da conta.';
  static const recuperarEnviar = 'Enviar link';
  static const recuperarEnviando = 'Enviando…';
  static const recuperarExigeConexao = 'Pedir o link exige conexão.';
  static String recuperarPedidoPara(String email) =>
      'Pedido feito para $email.';
  static const recuperarEnviarDeNovo = 'Não chegou? Enviar de novo';
  static const recuperarOutroEmail = 'Usar outro e-mail';
  static const recuperarVoltar = 'Voltar para entrar';

  static const loginRecuperacaoEmailInvalido =
      'Confira o e-mail: ele não parece um endereço válido.';
  static const loginRecuperacaoEnviadaTitulo = 'Confira seu e-mail';

  /// Igual com ou sem conta para o e-mail: dizer "não há conta" seria dizer
  /// a qualquer um quem usa o FONAR.
  static const loginRecuperacaoEnviadaTexto =
      'Se houver uma conta FONAR com este e-mail, o link para criar uma senha '
      'nova chega em alguns minutos. Confira também a caixa de spam.';
  static const loginRecuperacaoIndisponivel =
      'Recuperação de senha indisponível no login de exemplo';
  static const loginRecuperacaoIndisponivelTexto =
      'No modo de exemplo, o aplicativo não envia e-mail de redefinição.';

  /// PLACEHOLDER — o modo de exemplo (`AppConfig.exemplo`).
  static const loginExemploTitulo = 'Login de exemplo';
  static const loginExemploTexto =
      'Este build está no modo de exemplo: o login aceita qualquer e-mail e '
      'senha. Serve só para desenvolvimento.';

  static const loginOfflineComCacheTitulo =
      'Sem conexão — dados locais disponíveis';
  static String loginOfflineComCacheTexto(int pacientes) =>
      'Este aparelho tem $pacientes '
      '${pacientes == 1 ? 'paciente salvo' : 'pacientes salvos'}. Dá para '
      'gravar e revisar; o envio para análise aguarda a conexão voltar.';
  static const loginEntrarOffline = 'Entrar em modo offline';
  static String loginOfflineComo(String email) =>
      'Entra como $email, com a senha dessa conta.';
  static const loginSemRedeSenhaNaoConfere =
      'A senha não confere com a da última entrada neste aparelho.';
  static const loginSemRedeSemSenhaGuardada =
      'Esta conta ainda não entrou com conexão desde que o FONAR passou a '
      'conferir a senha sem rede. Conecte-se e entre uma vez para habilitar.';
  static const loginOfflineSemContaTexto =
      'O modo offline entra com a conta da última entrada com senha neste '
      'aparelho, e ainda não houve nenhuma. Conecte-se e entre uma vez para '
      'habilitá-lo.';

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

  // ------------------------------------------------------------ cadastro --
  // Criar conta, confirmar o e-mail e preencher o cadastro (US34). O cadastro
  // é aberto: a pessoa já usa o app enquanto a equipe confere a inscrição no
  // Crefono (ADR-015 da API).
  static const criarContaTitulo = 'Criar conta';
  static const criarContaApoio =
      'Crie a conta com seu e-mail e informe sua inscrição no Crefono. A '
      'equipe do FONAR confere a inscrição na consulta pública do conselho — '
      'enquanto isso, você já pode usar o aplicativo.';
  static const criarContaSecaoConta = 'Sua conta';
  static const criarContaSecaoRegistro = 'Seu registro profissional';
  static const criarContaCampoConfirmacao = 'Repita a senha';
  static const criarContaSenhaApoio = 'Ao menos 8 caracteres.';
  static const criarContaBotao = 'Criar conta';
  static const criarContaCriando = 'Criando a conta…';
  static const criarContaJaTenho = 'Já tenho conta';

  static const registroCampoNome = 'Nome completo';
  static const cadastroNomeApoio = 'Como vai assinado no laudo.';
  static const cadastroCampoRegiao = 'Região do Crefono';
  static String cadastroRegiao(int regiao, String estados) =>
      '$regiaoª · $estados';
  static const cadastroCampoInscricao = 'Número de inscrição';
  static const cadastroInscricaoDica = 'ex.: 12345';
  static const cadastroInscricaoApoio =
      'Só o número, como o conselho publica, sem “CRFa” e sem a região.';
  static const cadastroTermosRotulo =
      'Li e aceito os termos de uso e a política de privacidade do FONAR.';

  /// Os termos de uso e a política de privacidade (US43), em itens, como o
  /// termo do paciente. Ao mudar qualquer palavra, mude também
  /// `versaoDosTermos` (`cadastro/domain/cadastro.dart`): a API grava a
  /// versão aceita, com a data. Revisão jurídica recomendada (PENDENCIAS.md).
  static const cadastroTermosTitulo = 'Termos de uso e política de privacidade';
  static const cadastroTermosItens = [
    'O FONAR é ferramenta de apoio à decisão clínica e não emite '
        'diagnóstico. As medidas acústicas vêm do motor do Praat, software '
        'independente da Universidade de Amsterdam; a interpretação é sua. '
        'Uma medida só aparece classificada quando há faixa de referência '
        'validada para ela.',
    'Os dados dos seus pacientes são de sua responsabilidade (você é o '
        'controlador, na LGPD): registrar o consentimento antes de gravar, '
        'atender os pedidos deles e guardar o registro do atendimento como o '
        'seu conselho exige. O FONAR trata esses dados em seu nome, só para '
        'o serviço.',
    'Os seus dados — nome, e-mail e inscrição no Crefono — servem para '
        'identificar você, para a equipe conferir a inscrição e para assinar '
        'os laudos.',
    'Onde ficam: no Google Cloud (Firebase). Cadastros, medidas e laudos no '
        'Brasil (São Paulo); os arquivos de gravação nos Estados Unidos. '
        'Tudo trafega cifrado, e cada conta só alcança os próprios '
        'pacientes.',
    'A sua senha protege dado de saúde, inclusive sem conexão: guarde-a em '
        'sigilo e mantenha o aparelho com bloqueio de tela.',
    'O FONAR é um projeto acadêmico (TCC de Engenharia de Software, '
        'PUC-Campinas), oferecido sem garantia de disponibilidade contínua. '
        'Se estes termos mudarem, o aplicativo pede um novo aceite.',
  ];
  static const registroInformeNome = 'Informe o nome completo.';
  static const cadastroNomeLongo = 'O nome passa de 200 caracteres.';
  static const cadastroInformeRegiao =
      'Escolha a região do Crefono em que você é inscrito(a).';
  static const cadastroInformeInscricao = 'Informe o número de inscrição.';
  static const cadastroInscricaoInvalida =
      'Use só o número: algarismos (e às vezes letra, ponto, barra ou hífen), '
      'até 20, sem “CRFa” e sem a região.';
  static const cadastroAceiteTermos =
      'Para criar o cadastro, é preciso aceitar os termos.';
  static const cadastroInformeEmail = 'Informe o e-mail.';
  static const cadastroEmailInvalido =
      'Confira o e-mail: ele não parece um endereço válido.';
  static const cadastroSenhaCurta = 'A senha precisa de ao menos 8 caracteres.';
  static const cadastroSenhasDiferentes = 'As duas senhas não são iguais.';

  static const verificarEmailTitulo = 'Confirme seu e-mail';
  static String verificarEmailTexto(String email) =>
      'Enviamos um link para $email. Abra o e-mail, toque no link e volte '
      'aqui. Confira também a caixa de spam.';
  static const verificarEmailSemConta =
      'Enviamos um link para o seu e-mail. Abra o e-mail, toque no link e '
      'volte aqui. Confira também a caixa de spam.';
  static const verificarEmailJaConfirmei = 'Já confirmei';
  static const verificarEmailConferindo = 'Conferindo…';
  static const verificarEmailAindaNaoTitulo = 'Ainda não confirmado';
  static const verificarEmailAindaNao =
      'O e-mail ainda não aparece como confirmado. Abra o link do e-mail e '
      'toque em “Já confirmei” de novo.';
  static const verificarEmailReenviar = 'Reenviar o e-mail';
  static const verificarEmailReenviadoTitulo = 'E-mail reenviado';
  static const verificarEmailReenviado =
      'O link novo chega em alguns minutos. O anterior deixa de valer.';
  static const verificarEmailOutraConta = 'Entrar com outra conta';

  static const completarCadastroTitulo = 'Complete seu cadastro';
  static const completarCadastroApoio =
      'Seu e-mail está confirmado. Falta o seu registro profissional: a '
      'equipe do FONAR confere a inscrição na consulta pública do Crefono.';
  static const completarCadastroBotao = 'Concluir cadastro';
  static const completarCadastroSalvando = 'Salvando…';

  // ------------------------------------------------ anotações (US51) --
  // Prontuário: nada se apaga, e editar guarda a versão de antes. Não
  // depende do consentimento — ele cobre a voz, não o atendimento.
  static const anotacoesTitulo = 'Anotações';
  static const anotacoesApoio =
      'O registro do atendimento. Nada se apaga: editar guarda a versão de '
      'antes.';
  static const anotacoesCampo = 'Nova anotação';
  static const anotacoesLembrar = 'Lembrar na próxima consulta';
  static const anotacoesSalvar = 'Salvar anotação';
  static const anotacoesSalvando = 'Salvando…';
  static const anotacoesVazio = 'Nenhuma anotação ainda.';
  static const anotacoesTextoObrigatorio =
      'Escreva a anotação antes de salvar.';
  static String anotacoesTextoLongo(int maximo) =>
      'A anotação passou de $maximo caracteres. Divida em duas.';
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
      'Não foi possível carregar as anotações. Feche e abra o perfil de novo.';
  static const anotacoesErroSalvar =
      'Não foi possível salvar a anotação. Tente de novo.';
  static const anotacoesExemplo =
      'Paciente de exemplo: as anotações são dos pacientes cadastrados.';

  // O lembrete da próxima consulta: discreto, e o texto só aparece ao
  // tocar — às vezes o paciente vê a tela.
  static String lembreteUm(String diaEMes) =>
      'Você deixou um lembrete na consulta de $diaEMes';
  static String lembreteVarios(int n) =>
      'Você deixou $n lembretes de consultas anteriores';
  static const lembreteMostrar = 'Mostrar';
  static const lembreteEsconder = 'Esconder';
  static const lembreteVi = 'Ok, vi';
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
      'Por este botão você cadastra o paciente, registra o consentimento e '
      'grava a voz. Quem já está na lista é avaliado de novo pelo perfil.';
  static const guiaListaTitulo = 'Seus pacientes';
  static const guiaListaTexto =
      'Cada paciente da lista abre o perfil: consentimento, sessões, '
      'resultados, CAPE-V, evolução e laudo.';
  static const guiaListaVaziaTexto =
      'Os pacientes que você cadastrar aparecem nesta tela. Cada um abre o '
      'perfil: consentimento, sessões, resultados, CAPE-V, evolução e laudo.';
  static const guiaFilaTitulo = navFila;
  static const guiaFilaTexto =
      'Cada gravação espera aqui até chegar à análise. Sem conexão nada se '
      'perde: o envio continua sozinho quando a conexão volta.';
  static const guiaContaTitulo = navConta;
  static const guiaContaTexto =
      'Seus dados profissionais, a troca de senha e a aparência: tema claro '
      'ou escuro e tamanho da interface.';
  static const guiaConexaoTitulo = 'Conexão';
  static const guiaConexaoTexto =
      'Diz se o aparelho está conectado. A gravação funciona sem conexão; a '
      'análise precisa dela.';
  static const guiaAjudaTitulo = ajuda;
  static const guiaAjudaTexto =
      'Para ver este guia de novo, ou os atalhos de teclado, é aqui.';

  // As dicas de primeira vez por tela (US50): uma vez cada, por conta, neste
  // aparelho.
  static const dicaRotulo = 'Dica';
  static const dicaEntendi = 'Entendi';
  static const dicaGravacaoTexto =
      'A gravação começa por aqui: 5 segundos de silêncio para medir a sala. '
      'Se o microfone não captar som, a gravação não abre. Depois, uma tarefa '
      'por vez, com a instrução grande para o paciente. No teclado, Espaço '
      'inicia e para, e R grava de novo.';
  static const dicaResultadoTexto =
      'As medidas são calculadas no servidor, a partir das gravações. Só '
      'aparecem classificadas quando há faixa de referência validada para o '
      'perfil do paciente; sem ela, o app mostra o valor e diz por quê. É '
      'apoio à decisão, não diagnóstico.';
  static const dicaCapeVTexto =
      'Ouça a amostra e marque cada parâmetro na escala: à esquerda, sem '
      'desvio; à direita, desvio extremo. A avaliação é o seu julgamento pelo '
      'ouvido — o app só registra.';
  static const dicaLaudoTexto =
      'O que falta para gerar o laudo aparece aqui: há itens que impedem e '
      'itens que só avisam. O laudo emitido não muda depois — emitir de novo '
      'cria outro documento, que diz qual substitui.';

  // Só os atalhos que existem: cada linha corresponde a uma tecla tratada
  // no código (gravação guiada e espectrograma).
  static const atalhosTitulo = 'Atalhos de teclado';
  static const atalhosFechar = 'Fechar';
  static const atalhosEmQualquerTela = 'Em qualquer tela';
  static const atalhosTab = 'Tab e Shift+Tab';
  static const atalhosTabTexto = 'Passa de um controle para o próximo.';
  static const atalhosAtivar = 'Enter ou Espaço';
  static const atalhosAtivarTexto = 'Aciona o controle em destaque.';
  static const atalhosEsc = 'Esc';
  static const atalhosEscTexto = 'Fecha a janela aberta, como esta.';
  static const atalhosNaGravacao = 'Na gravação';
  static const atalhosEspaco = 'Espaço';
  static const atalhosEspacoTexto =
      'Mede o ruído da sala, inicia ou para a gravação da etapa.';
  static const atalhosR = 'R';
  static const atalhosRTexto = 'Grava a etapa de novo.';
  static const atalhosNoEspectrograma = 'No espectrograma';
  static const atalhosSetas = 'Setas';
  static const atalhosSetasTexto = 'Percorrem a imagem ampliada.';
  static const atalhosMais = '+ e −';
  static const atalhosMaisTexto = 'Aproximam e afastam.';
  static const atalhosZero = '0';
  static const atalhosZeroTexto = 'Volta à imagem inteira.';

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
  static const erroMuitasTentativas =
      'Muitas tentativas seguidas. Por segurança, esta conta ficou pausada '
      'por alguns minutos. Aguarde e tente de novo, ou redefina a senha.';
  static const erroContaDesativada =
      'Esta conta foi desativada. Fale com o responsável pelo FONAR.';
  static const erroProibido = 'Você não tem acesso a este recurso.';
  static const erroEmailIndisponivel =
      'Não foi possível criar uma conta com este e-mail. Se você já tem conta '
      'no FONAR, entre com ela — ou use “Esqueci a senha”.';
  static const erroEmailInvalido =
      'Confira o e-mail: ele não parece um endereço válido.';
  static const erroSenhaFraca =
      'A senha é fraca demais. Use ao menos 8 caracteres, misturando letras e '
      'números.';
  static const erroNaoEncontrado = 'Não encontramos o que você procurava.';
  static const erroValidacao = 'Confira os dados informados e tente novamente.';
  static const erroServidor =
      'Houve uma falha no servidor. Tente novamente em alguns instantes.';
  static const erroEnvioCancelado = 'O envio foi cancelado.';
  static const erroSemConsentimentoNoServidor =
      'O servidor não encontrou consentimento em vigor para este paciente. '
      'Registre o consentimento de novo antes de enviar.';
  static const erroGravacaoNaoEncontrada =
      'O arquivo da gravação não está mais neste aparelho, e sem ele a '
      'análise não pode ser feita. Grave a sessão de novo.';
  static const erroDesconhecido =
      'Algo não saiu como esperado. Tente novamente.';
}
