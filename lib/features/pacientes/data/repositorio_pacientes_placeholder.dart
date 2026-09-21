import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/paciente.dart';
import '../domain/repositorio_pacientes.dart';

/// TODO(drift): trocar pelo repositório do banco local.
final repositorioPacientesProvider = Provider<RepositorioPacientes>(
  (ref) => const RepositorioPacientesPlaceholder(),
);

/// Lista de pacientes da tela, já carregada.
final pacientesProvider = FutureProvider<List<Paciente>>(
  (ref) => ref.watch(repositorioPacientesProvider).listar(),
);

/// PLACEHOLDER — pacientes fictícios, os mesmos do protótipo.
///
/// Todo nome termina em "de Exemplo" e toda queixa em "(exemplo)": dado de
/// desenvolvimento precisa ser reconhecível como tal em qualquer captura de
/// tela, inclusive nas que vão parar no texto do TCC.
class RepositorioPacientesPlaceholder implements RepositorioPacientes {
  const RepositorioPacientesPlaceholder();

  @override
  Future<List<Paciente>> listar() async => [
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
}
