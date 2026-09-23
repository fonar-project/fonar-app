import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/novo_paciente.dart';
import '../domain/paciente.dart';
import '../domain/repositorio_pacientes.dart';

/// TODO(drift): trocar pelo repositório do banco local.
final repositorioPacientesProvider = Provider<RepositorioPacientes>(
  (ref) => RepositorioPacientesPlaceholder(),
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

/// PLACEHOLDER — pacientes fictícios, os mesmos do protótipo.
///
/// Todo nome termina em "de Exemplo" e toda queixa em "(exemplo)": dado de
/// desenvolvimento precisa ser reconhecível como tal em qualquer captura de
/// tela, inclusive nas que vão parar no texto do TCC.
///
/// O que se cadastra fica só na memória e some ao fechar o app. É o bastante
/// para percorrer o fluxo cadastro → lista; persistir de verdade é trabalho do
/// Drift.
class RepositorioPacientesPlaceholder implements RepositorioPacientes {
  RepositorioPacientesPlaceholder();

  final _cadastrados = <Paciente>[];

  @override
  Future<List<Paciente>> listar() async => [
    // Recém-cadastrado ainda não tem sessão, e mesmo assim vai no topo: é
    // quem o profissional acabou de atender e vai procurar em seguida.
    ..._cadastrados.reversed,
    Paciente(
      id: 'exemplo-a',
      nome: 'Paciente A. de Exemplo',
      queixa: 'rouquidão persistente (exemplo)',
      ultimaSessao: DateTime(2026, 7, 23),
      direcaoAvqi: DirecaoDaMedida.desceu,
    ),
    Paciente(
      id: 'exemplo-b',
      nome: 'Paciente B. de Exemplo',
      queixa: 'fadiga vocal ao fim do dia (exemplo)',
      ultimaSessao: DateTime(2026, 7, 18),
      direcaoAvqi: DirecaoDaMedida.estavel,
    ),
    Paciente(
      id: 'exemplo-c',
      nome: 'Paciente C. de Exemplo',
      queixa: 'soprosidade (exemplo)',
      ultimaSessao: DateTime(2026, 7, 10),
      direcaoAvqi: DirecaoDaMedida.subiu,
    ),
    Paciente(
      id: 'exemplo-d',
      nome: 'Paciente D. de Exemplo',
      queixa: 'pitch instável (exemplo)',
      ultimaSessao: DateTime(2026, 7, 2),
      direcaoAvqi: DirecaoDaMedida.desceu,
    ),
    Paciente(
      id: 'exemplo-e',
      nome: 'Paciente E. de Exemplo',
      queixa: 'tensão ao falar (exemplo)',
      ultimaSessao: DateTime(2026, 6, 25),
      direcaoAvqi: DirecaoDaMedida.semComparacao,
    ),
  ];

  @override
  Future<Paciente> cadastrar(NovoPaciente novo) async {
    final paciente = Paciente(
      // TODO(drift): o id definitivo vem do banco local (UUID gerado no
      // aparelho, para não colidir na sincronização).
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      nome: novo.nome,
      queixa: novo.queixa,
      direcaoAvqi: DirecaoDaMedida.semComparacao,
    );
    _cadastrados.add(paciente);
    return paciente;
  }
}
