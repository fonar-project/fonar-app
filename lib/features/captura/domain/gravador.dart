import 'dart:typed_data';

import 'amostra.dart';

/// Grava uma tarefa em WAV e devolve o arquivo para conferência.
///
/// Contrato para testar a gravação sem microfone. A implementação real está
/// em `data/gravador_record.dart`.
abstract interface class Gravador {
  Future<bool> pedirPermissao();

  /// Começa a gravar em [caminho] e emite o nível, em dBFS, a cada
  /// [intervalo] — para o medidor e para a conferência de sinal.
  Future<Stream<double>> iniciar(String caminho, Duration intervalo);

  /// Para e finaliza o arquivo.
  Future<void> parar();

  /// Para, se estiver gravando, e apaga o que foi gravado. Seguro de chamar
  /// sem ter iniciado.
  Future<void> descartar();
}

/// Onde as amostras ficam no aparelho, e a leitura de volta do que foi
/// gravado.
abstract interface class ArquivosDeAmostra {
  /// Caminho para um arquivo novo desta tarefa, na área privada do app.
  Future<String> novoCaminho(String pacienteId, TarefaDeGravacao tarefa);

  /// Os primeiros bytes do arquivo — o bastante para o cabeçalho — e o
  /// tamanho total. `null` se o arquivo não existir.
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho);

  Future<void> apagar(String caminho);
}

/// Onde as amostras conferidas ficam registradas.
///
/// TODO(US06): a implementação real grava no banco local (Drift) e põe a
/// amostra na fila de sincronização.
abstract interface class RepositorioAmostras {
  Future<List<Amostra>> daSessao(String sessaoId);

  /// Guarda [amostra] no lugar da anterior da mesma tarefa NA MESMA SESSÃO,
  /// se houver — regravar substitui, não acumula. Sessões anteriores do
  /// paciente não são tocadas.
  Future<void> guardar(Amostra amostra);
}
