import 'paciente.dart';

/// Fonte da lista de pacientes.
///
/// A implementação real lê do banco local (Drift) — a lista precisa abrir sem
/// conexão, que é o caso comum em consultório.
abstract interface class RepositorioPacientes {
  /// Pacientes do profissional, com a sessão mais recente primeiro.
  Future<List<Paciente>> listar();
}
