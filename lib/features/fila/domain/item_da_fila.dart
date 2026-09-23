import '../../../core/error/app_exception.dart';
import '../../captura/domain/amostra.dart';

/// Em que pé está um envio.
enum SituacaoDoEnvio {
  /// Esperando a vez — ou a conexão.
  naFila,
  enviando,

  /// Falhou por motivo passageiro (rede, servidor). Tenta de novo sozinho em
  /// [ItemDaFila.proximaTentativa].
  aguardandoNovaTentativa,

  /// A sessão do profissional expirou. Não adianta tentar sem entrar de novo.
  aguardandoLogin,

  /// A API recusou o envio. Tentar de novo sozinho repetiria a recusa; precisa
  /// de alguém olhar.
  recusado,

  /// Chegou. A análise foi aceita pelo servidor.
  enviado,
}

/// Uma sessão de gravação esperando para subir para a análise.
///
/// A unidade da fila é a SESSÃO, não a gravação avulsa: a análise precisa das
/// tarefas juntas (o AVQI combina vogal sustentada e fala encadeada).
class ItemDaFila {
  const ItemDaFila({
    required this.id,
    required this.pacienteId,
    required this.nomeDoPaciente,
    required this.sessaoId,
    required this.amostras,
    required this.criadoEm,
    this.situacao = SituacaoDoEnvio.naFila,
    this.tentativas = 0,
    this.proximaTentativa,
    this.ultimaFalha,
    this.analiseId,
  });

  /// Também é a chave de idempotência do envio: repetir o envio de um item
  /// cuja resposta se perdeu no caminho não pode gerar duas análises.
  final String id;
  final String pacienteId;

  /// Guardado junto, e não buscado depois: a fila precisa se explicar mesmo
  /// sem conseguir abrir o cadastro.
  final String nomeDoPaciente;
  final String sessaoId;
  final List<Amostra> amostras;
  final DateTime criadoEm;

  final SituacaoDoEnvio situacao;

  /// Quantas vezes já se tentou enviar.
  final int tentativas;
  final DateTime? proximaTentativa;

  /// Mensagem da última falha, pronta para exibição.
  final String? ultimaFalha;

  /// Preenchido quando [SituacaoDoEnvio.enviado].
  final String? analiseId;

  /// A fila pode tentar este item agora, sozinha?
  bool prontoEm(DateTime agora) => switch (situacao) {
    SituacaoDoEnvio.naFila => true,
    SituacaoDoEnvio.aguardandoNovaTentativa =>
      proximaTentativa == null || !proximaTentativa!.isAfter(agora),
    _ => false,
  };

  /// Ainda não chegou ao servidor.
  bool get pendente => situacao != SituacaoDoEnvio.enviado;

  ItemDaFila copiar({
    SituacaoDoEnvio? situacao,
    int? tentativas,
    DateTime? Function()? proximaTentativa,
    String? Function()? ultimaFalha,
    String? analiseId,
  }) => ItemDaFila(
    id: id,
    pacienteId: pacienteId,
    nomeDoPaciente: nomeDoPaciente,
    sessaoId: sessaoId,
    amostras: amostras,
    criadoEm: criadoEm,
    situacao: situacao ?? this.situacao,
    tentativas: tentativas ?? this.tentativas,
    proximaTentativa: proximaTentativa != null
        ? proximaTentativa()
        : this.proximaTentativa,
    ultimaFalha: ultimaFalha != null ? ultimaFalha() : this.ultimaFalha,
    analiseId: analiseId ?? this.analiseId,
  );
}

/// Regras de quando e se tentar de novo.
abstract final class PoliticaDeReenvio {
  static const esperaInicial = Duration(seconds: 30);
  static const esperaMaxima = Duration(minutes: 30);

  /// Espera antes da próxima tentativa, depois de [tentativas] falhas:
  /// 30 s, 1 min, 2 min, 4 min… até 30 min.
  ///
  /// Dobra a cada falha para não martelar um servidor fora do ar — nem a
  /// bateria e o plano de dados do celular do profissional.
  static Duration esperaApos(int tentativas) {
    if (tentativas <= 1) return esperaInicial;
    final segundos = esperaInicial.inSeconds << (tentativas - 1).clamp(0, 20);
    return segundos >= esperaMaxima.inSeconds
        ? esperaMaxima
        : Duration(seconds: segundos);
  }

  /// Para onde vai o item depois de falhar com [falha].
  ///
  /// `switch` sobre a classe selada: um tipo novo de [AppException] vira erro
  /// de compilação aqui até alguém decidir o que a fila faz com ele.
  static SituacaoDoEnvio depoisDe(AppException falha) => switch (falha) {
    FalhaDeConexao() ||
    TempoEsgotado() ||
    FalhaNoServidor() ||
    EnvioCancelado() ||
    FalhaDesconhecida() => SituacaoDoEnvio.aguardandoNovaTentativa,
    NaoAutorizado() || CredencialInvalida() => SituacaoDoEnvio.aguardandoLogin,
    FalhaDeValidacao() ||
    Proibido() ||
    NaoEncontrado() => SituacaoDoEnvio.recusado,
  };
}
