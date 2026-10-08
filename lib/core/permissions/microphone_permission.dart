/// RISCO ALTO — Windows: a captura pode falhar EM SILÊNCIO, com áudio mudo.
///
/// Arquivo de documentação, sem código. Ele existe porque este é o modo de
/// falhar mais caro do projeto, e porque o que o contém está espalhado por
/// vários arquivos da captura — o texto junta tudo num lugar e aponta para
/// cada um. Os arquivos de `features/captura/` referenciam este caminho.
///
/// Não há contrato de permissão aqui. Houve um esqueleto
/// (`abstract interface class MicrophonePermission`), removido em 25/09/2026:
/// nunca teve implementação e o aplicativo nunca o chamou. Quem pergunta a
/// permissão é o próprio pacote de captura, `AudioRecorder.hasPermission()`,
/// por trás de `FonteDeNivel.pedirPermissao` e `Gravador.pedirPermissao` —
/// e, no Android, ele já resolve o pedido nativo. Uma camada a mais só
/// escondia isso.
///
/// ## O modo de falha
///
/// No Windows NÃO EXISTE declaração de permissão de microfone para um
/// executável Win32 desempacotado, que é o que `flutter build windows` gera.
/// `windows/runner/runner.exe.manifest` declara apenas DPI e compatibilidade
/// de SO; não há equivalente ao `<uses-permission>` do Android. O acesso é
/// decidido em tempo de execução pelo próprio Windows, em
/// Configurações > Privacidade e segurança > Microfone.
///
/// A declaração formal (`<DeviceCapability Name="microphone" />`) só existe se
/// o app for empacotado em MSIX. Isso é decisão de release e ficou para depois.
///
/// O modo de falha é o pior possível para este projeto: quando o acesso está
/// bloqueado por política ou pela chave "permitir que aplicativos de desktop
/// acessem o microfone", a captura frequentemente NÃO lança erro. Ela inicia,
/// roda e grava um arquivo WAV bem formado, com a duração correta, e
/// AMPLITUDE ZERO. Do ponto de vista do código, deu tudo certo.
///
/// Traduzido para o consultório: o fonoaudiólogo grava a consulta inteira, com
/// o paciente na frente dele, e só descobre que não há áudio depois — quando o
/// paciente já foi embora. A coleta não é repetível. É perda de dado clínico,
/// não um bug de interface.
///
/// ## O que o aplicativo faz, e onde
///
/// 1. **Verifica amplitude na aferição de ruído, antes de liberar a gravação.**
///    `features/captura/domain/afericao_de_ruido.dart` e `nivel_de_audio.dart`
///    (`microfoneMudo`): exige um mínimo de leituras válidas e uma variação
///    mínima entre elas — leitura parada no mesmo valor é microfone entregando
///    número fixo, não sala silenciosa.
/// 2. **Trata silêncio absoluto como FALHA, nunca como sala silenciosa.** Na
///    aferição, por (1). Na gravação, duas vezes: pelas leituras e pelos
///    BYTES do arquivo que saiu
///    (`VerificacaoDaAmostra.audioTodoEmZero`) — comparação de byte com zero,
///    não análise acústica. A segunda existe porque a primeira vem do plugin:
///    se ele informar amplitude plausível enquanto escreve zeros no disco, só
///    o arquivo denuncia.
/// 3. **Avisa e BLOQUEIA**, com texto que diz o que fazer — no Windows, o
///    caminho das configurações de privacidade: `l10n/app_strings.dart`
///    (`afericaoMudo`, `problemaSemSinal`) e a tela de gravação. A gravação
///    não abre sem aferição liberada.
/// 4. **Confere o que de fato saiu, e não a configuração pedida.** Taxa e
///    canais: pelo `setOnConfigChanged` nas DUAS capturas
///    (`FonteDeNivel.ajuste` e `Gravador.ajuste`) e pelo cabeçalho do WAV.
///    Formato e profundidade de bits: só pelo cabeçalho, porque o `record`
///    não tem parâmetro de bits nem avisa sobre ela — ver
///    `ConfiguracaoDeCaptura.bitsPorAmostra`.
///
/// Ver a regra de captura no CLAUDE.md: "VERIFICAR empiricamente o que saiu,
/// não confiar na configuração solicitada".
///
/// ## O que continua em aberto
///
/// - O LIMIAR de silêncio e as zonas do medidor são valores de partida, não
///   definidos empiricamente (`LimitesDeNivel`, `AfericaoDeRuido`).
/// - Nada disso foi exercitado com microfone de verdade: o ambiente em que o
///   código foi escrito não tem um. Em especial, não se sabe se o
///   `setOnConfigChanged` dispara, nem qual valor chega com o microfone
///   bloqueado pela privacidade do Windows.
/// - Desligar ganho automático, supressão de ruído e cancelamento de eco é
///   PEDIDO, e nada confirma que a plataforma obedeceu — o cabeçalho do WAV
///   cobre formato, não processamento.
///
/// As três estão no `PENDENCIAS.md`, em "Verificar em aparelho real".
library;
