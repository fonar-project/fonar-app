import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositorio_pacientes_placeholder.dart';
import '../domain/paciente.dart';

/// Termo digitado na busca da lista de pacientes.
///
/// Mora fora do widget pelo mesmo motivo do `LoginControlador`: a tela guardava
/// o termo no `State` e reconstruía a página inteira a cada tecla — cabeçalho,
/// barra de navegação, indicador de conexão e o próprio campo de busca, que é o
/// que tem foco de teclado. Com o estado aqui, quem observa o termo é só quem
/// depende dele.
///
/// O controlador NÃO sabe o que é correspondência. Quem sabe é o domínio, em
/// [Paciente.correspondeA] — é lá que mora a regra de ignorar acento e
/// maiúscula, e é lá que ela continua testável sem widget nenhum.
class BuscaPacientesControlador extends Notifier<String> {
  @override
  String build() => '';

  void digitar(String termo) {
    // Teclas que não mudam o texto — seta, Shift solto — não precisam derrubar
    // quem observa.
    if (termo != state) state = termo;
  }

  void limpar() => digitar('');
}

final buscaPacientesProvider =
    NotifierProvider.autoDispose<BuscaPacientesControlador, String>(
      BuscaPacientesControlador.new,
    );

/// Os pacientes que correspondem ao termo buscado.
///
/// Deriva de [pacientesProvider], então carregamento e falha continuam sendo
/// os mesmos da lista inteira — a busca não inventa estado novo.
final pacientesFiltradosProvider =
    Provider.autoDispose<AsyncValue<List<Paciente>>>((ref) {
      final termo = ref.watch(buscaPacientesProvider);
      return ref
          .watch(pacientesProvider)
          .whenData(
            (todos) => todos.where((p) => p.correspondeA(termo)).toList(),
          );
    });
