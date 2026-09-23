import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/amostra.dart';
import '../domain/gravador.dart';

/// TODO(US06): trocar pelo repositório do banco local, com fila de
/// sincronização.
final repositorioAmostrasProvider = Provider<RepositorioAmostras>(
  (ref) => RepositorioAmostrasPlaceholder(),
);

/// PLACEHOLDER — o REGISTRO fica só em memória e some ao fechar o app. Os
/// arquivos WAV, esses, ficam no disco de verdade.
class RepositorioAmostrasPlaceholder implements RepositorioAmostras {
  RepositorioAmostrasPlaceholder();

  final _amostras = <Amostra>[];

  @override
  Future<List<Amostra>> daSessao(String sessaoId) async => [
    for (final a in _amostras)
      if (a.sessaoId == sessaoId) a,
  ];

  @override
  Future<void> guardar(Amostra amostra) async {
    _amostras
      ..removeWhere(
        (a) => a.sessaoId == amostra.sessaoId && a.tarefa == amostra.tarefa,
      )
      ..add(amostra);
  }
}
