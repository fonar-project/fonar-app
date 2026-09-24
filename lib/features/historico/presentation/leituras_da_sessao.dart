import '../../analise/domain/faixa_de_referencia.dart';
import '../../analise/domain/leitura_do_resultado.dart';
import '../../analise/domain/resultado_da_analise.dart';
import '../../pacientes/domain/paciente.dart';
import '../domain/evolucao_da_medida.dart';

/// A leitura de [medida] em cada sessão, na mesma ordem de [sessoes].
///
/// Cada sessão com o perfil que o paciente tinha NAQUELA data — ver
/// `lerMedidas`. Nula quando o servidor nem mandou a medida.
List<MedidaLida?> leiturasDaSessao({
  required MedidaAcustica medida,
  required List<ResultadoDaAnalise> sessoes,
  required Paciente? paciente,
  required CatalogoDeReferencias catalogo,
}) => [
  for (final sessao in sessoes)
    lerMedidas(
      resultado: sessao,
      sexo: paciente?.sexo,
      dataDeNascimento: paciente?.dataDeNascimento,
      catalogo: catalogo,
    ).where((m) => m.medida == medida).firstOrNull,
];
