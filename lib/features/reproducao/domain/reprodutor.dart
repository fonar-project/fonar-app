/// Toca uma gravação guardada no aparelho.
///
/// Só REPRODUZ: não analisa, não mede, não desenha forma de onda. Toda
/// medida vem do servidor — ver a regra de processamento de áudio no
/// CLAUDE.md.
abstract interface class Reprodutor {
  /// Carrega [caminho] e devolve a duração, se o aparelho souber dizer.
  Future<Duration?> abrir(String caminho);

  Future<void> tocar();
  Future<void> pausar();
  Future<void> irPara(Duration posicao);

  /// A posição enquanto toca.
  Stream<Duration> get posicoes;

  /// Emite quando a gravação chega ao fim.
  Stream<void> get terminou;

  Future<void> fechar();
}
