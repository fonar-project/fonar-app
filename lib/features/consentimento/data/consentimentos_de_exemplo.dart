import '../domain/consentimento.dart';

/// PLACEHOLDER — os pacientes de exemplo A a D já chegam com consentimento,
/// para dar para percorrer o fluxo até a gravação sem registrar toda vez; o E
/// chega sem, para dar para ver o bloqueio.
///
/// A versão do termo deles é "exemplo", que não existe de verdade: dado de
/// desenvolvimento precisa ser reconhecível. Como os pacientes de exemplo,
/// não estão no banco local e saem junto com eles.
final consentimentosDeExemplo = <String, Consentimento>{
  for (final id in ['exemplo-a', 'exemplo-b', 'exemplo-c', 'exemplo-d'])
    id: Consentimento(
      pacienteId: id,
      registradoEm: DateTime(2026, 6, 1, 9),
      versaoDoTermo: 'exemplo',
      quemAutoriza: QuemAutoriza.paciente,
    ),
};
