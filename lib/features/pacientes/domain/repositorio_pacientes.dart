import 'novo_paciente.dart';
import 'paciente.dart';

/// Fonte da lista de pacientes.
///
/// A implementação real lê do banco local (Drift) — a lista precisa abrir sem
/// conexão, que é o caso comum em consultório.
abstract interface class RepositorioPacientes {
  /// Pacientes do profissional, com a sessão mais recente primeiro.
  Future<List<Paciente>> listar();

  /// Salva o paciente NESTE APARELHO e devolve como ele passa a aparecer na
  /// lista.
  ///
  /// Não exige conexão: o cadastro entra na fila de sincronização e sobe
  /// quando a rede voltar. Um consultório sem sinal não pode impedir o
  /// profissional de começar a avaliação.
  ///
  /// Lança só `AppException`.
  Future<Paciente> cadastrar(NovoPaciente novo);
}
