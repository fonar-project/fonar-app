import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/banco/conversao.dart';
import '../../../core/banco/novo_id.dart';
import '../../../core/relogio.dart';
import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/novo_paciente.dart';
import '../domain/paciente.dart';
import '../domain/repositorio_pacientes.dart';
import 'pacientes_de_exemplo.dart';

final repositorioPacientesProvider = Provider<RepositorioPacientes>(
  (ref) => RepositorioPacientesLocal(
    ref.watch(bancoLocalProvider),
    agora: ref.watch(relogioProvider),
    exemplos: pacientesDeExemplo,
  ),
);

/// Lista de pacientes da tela, já carregada.
final pacientesProvider = FutureProvider<List<Paciente>>(
  (ref) => ref.watch(repositorioPacientesProvider).listar(),
);

/// Um paciente pelo id, ou `null` se ele não estiver neste aparelho.
///
/// Deriva da lista: com dezenas de pacientes por profissional, procurar na
/// lista já carregada custa menos que uma consulta própria, e cadastrar um
/// paciente novo atualiza os dois de uma vez.
final pacienteProvider = FutureProvider.family<Paciente?, String>((
  ref,
  pacienteId,
) async {
  final todos = await ref.watch(pacientesProvider.future);
  for (final paciente in todos) {
    if (paciente.id == pacienteId) return paciente;
  }
  return null;
});

/// Os pacientes cadastrados neste aparelho, no banco local.
///
/// TODO(backend): subir o cadastro pela fila de sincronização quando o
/// Firebase entrar. Hoje ele fica só no aparelho.
class RepositorioPacientesLocal implements RepositorioPacientes {
  RepositorioPacientesLocal(
    this._banco, {
    required this._agora,
    this.exemplos = const [],
  });

  final BancoLocal _banco;
  final DateTime Function() _agora;

  /// Mostrados depois dos cadastrados, e nunca gravados no banco.
  final List<Paciente> exemplos;

  @override
  Future<List<Paciente>> listar() async {
    final linhas =
        await (_banco.select(_banco.pacientes)..orderBy([
              (p) => OrderingTerm.desc(p.cadastradoEm),
              (p) => OrderingTerm.desc(p.rowId),
            ]))
            .get();
    return [
      // Recém-cadastrado ainda não tem sessão, e mesmo assim vai no topo: é
      // quem o profissional acabou de atender e vai procurar em seguida.
      for (final l in linhas)
        Paciente(
          id: l.id,
          nome: l.nome,
          queixa: l.queixa,
          direcaoAvqi: DirecaoDaMedida.semComparacao,
          sexo: enumOuNulo(SexoDeReferencia.values, l.sexo),
          dataDeNascimento: l.dataDeNascimento,
        ),
      ...exemplos,
    ];
  }

  @override
  Future<Paciente> cadastrar(NovoPaciente novo) async {
    final paciente = Paciente(
      // Gerado no aparelho, para não colidir na sincronização.
      id: novoId(),
      nome: novo.nome,
      queixa: novo.queixa,
      direcaoAvqi: DirecaoDaMedida.semComparacao,
      sexo: novo.sexo,
      dataDeNascimento: novo.dataDeNascimento,
    );
    await _banco
        .into(_banco.pacientes)
        .insert(
          PacientesCompanion.insert(
            id: paciente.id,
            nome: paciente.nome,
            queixa: paciente.queixa,
            sexo: Value(novo.sexo.name),
            dataDeNascimento: Value(novo.dataDeNascimento),
            cadastradoEm: _agora(),
          ),
        );
    return paciente;
  }
}
