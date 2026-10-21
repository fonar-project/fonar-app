import 'package:drift/drift.dart';

import '../../../core/banco/banco_local.dart';
import '../domain/amostra.dart';
import '../domain/gravador.dart';

/// As amostras gravadas no navegador (US42), no banco local — onde não há
/// pasta de arquivos.
///
/// O caminho é só um nome, `amostras/<paciente>/<tarefa>-<carimbo>.wav`,
/// com o mesmo formato do caminho no aparelho: amostra, fila e retirada do
/// consentimento continuam falando de "caminho" sem saber que aqui ele é a
/// chave de uma linha (`AudiosDoNavegador`).
///
/// O WAV entra por [guardar], quando o gravador para; o resto do contrato é o
/// mesmo de `ArquivosDeAmostraLocais`.
class ArquivosDeAmostraNoNavegador implements ArquivosDeAmostra {
  ArquivosDeAmostraNoNavegador(this._banco, {DateTime Function()? relogio})
    : _relogio = relogio ?? DateTime.now;

  final BancoLocal _banco;
  final DateTime Function() _relogio;

  /// O mesmo tamanho que `ArquivosDeAmostraLocais` lê do disco.
  static const _bytesDoCabecalho = 4096;

  @override
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao tarefa) async {
    final carimbo = _relogio().microsecondsSinceEpoch;
    return 'amostras/$pacienteId/${tarefa.name}-$carimbo.wav';
  }

  /// Guarda o WAV que o gravador entregou em [caminho].
  Future<void> guardar(String caminho, Uint8List wav) => _banco
      .into(_banco.audiosDoNavegador)
      .insertOnConflictUpdate(
        AudiosDoNavegadorCompanion.insert(
          caminho: caminho,
          wav: wav,
          gravadoEm: _relogio(),
        ),
      );

  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async {
    // O começo e o tamanho saem do próprio SQLite: o WAV inteiro não
    // atravessa para a página só para se ler o cabeçalho.
    final linha = await _banco
        .customSelect(
          'SELECT substr(wav, 1, $_bytesDoCabecalho) AS inicio, '
          'length(wav) AS tamanho '
          'FROM audios_do_navegador WHERE caminho = ?',
          variables: [Variable.withString(caminho)],
          readsFrom: {_banco.audiosDoNavegador},
        )
        .getSingleOrNull();
    if (linha == null) return null;
    return (
      inicio: linha.read<Uint8List>('inicio'),
      tamanho: linha.read<int>('tamanho'),
    );
  }

  /// O WAV inteiro, para a conferência, o envio e para ouvir. Nulo se não
  /// existe.
  @override
  Future<Uint8List?> lerTudo(String caminho) async {
    final linha = await (_banco.select(
      _banco.audiosDoNavegador,
    )..where((a) => a.caminho.equals(caminho))).getSingleOrNull();
    return linha?.wav;
  }

  @override
  Future<void> apagar(String caminho) => (_banco.delete(
    _banco.audiosDoNavegador,
  )..where((a) => a.caminho.equals(caminho))).go();

  /// Apaga os WAV que nenhum registro aponta, e devolve quantos — o mesmo
  /// cuidado de `apagarWavsSemRegistro` no aparelho, e pelo mesmo motivo:
  /// voz de paciente sem ninguém que saiba dela sai.
  ///
  /// Só os com mais de [idadeMinima]: um WAV que acabou de ser guardado
  /// ainda está a caminho de virar amostra.
  Future<int> apagarSemRegistro(
    Set<String> registrados, {
    Duration idadeMinima = const Duration(minutes: 10),
  }) {
    final limite = _relogio().subtract(idadeMinima);
    return (_banco.delete(_banco.audiosDoNavegador)..where(
          (a) =>
              a.caminho.isNotIn(registrados) &
              a.gravadoEm.isSmallerThanValue(limite),
        ))
        .go();
  }
}
