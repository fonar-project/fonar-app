import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/evolucao_da_medida.dart';

/// A medida que o gráfico de evolução mostra, por paciente.
///
/// Fica fora da tela porque duas telas a leem: a do profissional, onde ela é
/// escolhida, e o modo paciente, que mostra a mesma medida em tamanho grande.
/// O profissional escolhe o que quer mostrar e só então vira o aparelho.
///
/// Começa no AVQI: é o índice que resume as outras medidas, e é o que a lista
/// de pacientes já acompanha. Aqui não é resposta de formulário — é só o que
/// está à vista, então começar marcado não põe palavra na boca de ninguém.
class MedidaDaEvolucao extends Notifier<MedidaAcustica> {
  MedidaDaEvolucao(this.pacienteId);

  final String pacienteId;

  @override
  MedidaAcustica build() => MedidaAcustica.avqi;

  void escolher(MedidaAcustica medida) => state = medida;
}

final medidaDaEvolucaoProvider = NotifierProvider.autoDispose
    .family<MedidaDaEvolucao, MedidaAcustica, String>(MedidaDaEvolucao.new);
