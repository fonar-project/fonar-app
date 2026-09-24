/// Contrato de permissão de microfone. Mesmo contrato nas duas plataformas.
///
/// Sem implementação ainda — esqueleto. A implementação provavelmente vai se
/// apoiar em `record` (`AudioRecorder.hasPermission()`), que já resolve o
/// pedido nativo no Android.
///
/// ---------------------------------------------------------------------------
/// TODO(RISCO ALTO — Windows): falha silenciosa com áudio mudo.
/// ---------------------------------------------------------------------------
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
/// Por isso, o módulo de captura OBRIGATORIAMENTE precisará:
///
///  1. Verificar amplitude durante a aferição de ruído ambiente, ANTES de
///     liberar a gravação de fato. A aferição já lê amplitude em tempo real
///     (única exceção permitida ao processamento local) — é o ponto natural
///     para essa checagem, e ela custa zero.
///  2. Tratar silêncio absoluto como FALHA, não como "sala silenciosa".
///     Ruído ambiente real nunca é exatamente zero: um piso de amplitude
///     idêntico a zero por alguns segundos significa microfone mudo, não
///     acústica boa. Definir o limiar empiricamente.
///  3. Avisar explicitamente e BLOQUEAR a gravação, com texto que diga o que
///     fazer — no Windows, o caminho das configurações de privacidade.
///     Nunca deixar seguir com um aviso discreto.
///  4. Verificar o que de fato saiu, e não confiar na configuração pedida.
///     Vale para taxa de amostragem, canais e profundidade de bits também.
///
/// Ver a regra de captura no CLAUDE.md: "VERIFICAR empiricamente o que saiu,
/// não confiar na configuração solicitada".
///
/// SITUAÇÃO (US04): os itens 1 a 3 estão na aferição de ruído —
/// `features/captura/domain/afericao_de_ruido.dart` e a tela de gravação. O
/// limiar de silêncio ainda é valor de partida, NÃO definido empiricamente.
/// O item 4 está pela metade: a troca de taxa e de canais pelo aparelho é
/// detectada e mostrada; conferir o cabeçalho do WAV gravado fica para a
/// gravação das tarefas. Nada disso foi verificado em aparelho real ainda.
abstract interface class MicrophonePermission {
  /// Já temos permissão, sem perguntar nada ao usuário?
  Future<bool> temPermissao();

  /// Pede a permissão ao sistema. No Windows tende a ser no-op: não há diálogo
  /// a exibir, o resultado depende das configurações de privacidade.
  Future<bool> solicitar();

  /// Permissão negada de forma permanente — o app não consegue mais exibir o
  /// diálogo e o usuário precisa ir às configurações do sistema.
  Future<bool> negadaPermanentemente();
}
