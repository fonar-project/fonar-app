import '../../analise/domain/faixa_de_referencia.dart';
import '../../analise/domain/leitura_do_resultado.dart';
import '../../analise/domain/resultado_da_analise.dart';
import '../../auth/domain/profissional.dart';
import '../../captura/domain/amostra.dart';
import '../../cape_v/domain/avaliacao_cape_v.dart';
import '../../pacientes/domain/novo_paciente.dart';
import '../../pacientes/domain/paciente.dart';

/// Tudo o que vai no laudo, já reunido — o PDF e o resumo do celular leem
/// daqui, e nenhum dos dois decide conteúdo por conta própria.
class ConteudoDoLaudo {
  const ConteudoDoLaudo({
    required this.pacienteId,
    required this.nomeDoPaciente,
    required this.dataDeNascimento,
    required this.sexo,
    required this.realizadaEm,
    required this.medidas,
    required this.qualidade,
    required this.capeV,
    required this.conclusao,
    required this.profissional,
    required this.geradoEm,
    required this.exemplo,
  });

  /// De quem é o laudo. O controlador confere com o paciente da tela antes
  /// de gerar.
  final String pacienteId;
  final String nomeDoPaciente;
  final DateTime? dataDeNascimento;
  final SexoDeReferencia? sexo;

  /// Data da gravação.
  final DateTime? realizadaEm;

  /// Cada medida com a classificação frente à faixa do perfil do paciente na
  /// data da gravação — a mesma leitura da tela de resultado.
  final List<MedidaLida> medidas;
  final Map<TarefaDeGravacao, QualidadeDaAmostra> qualidade;
  final AvaliacaoCapeV? capeV;
  final String conclusao;
  final Profissional profissional;

  /// Nulo enquanto for só pré-visualização: o documento sai marcado como
  /// rascunho.
  final DateTime? geradoEm;

  /// Algum dado é de exemplo (placeholder). O documento inteiro sai marcado:
  /// um PDF de exemplo não pode circular como laudo de alguém.
  final bool exemplo;

  bool get rascunho => geradoEm == null;
}

/// Reúne o conteúdo do laudo de [resultado] para [paciente].
///
/// O paciente é OBRIGATÓRIO, e a análise precisa ser dele — ver
/// `daPaciente`, que lança `AnaliseDeOutroPaciente` se não for. Antes, com o
/// cadastro ausente, o laudo saía com o nome em branco, e nada impedia juntar
/// o cadastro de um paciente com as medidas de outro (achados da revisão de
/// 23/09).
ConteudoDoLaudo montarConteudo({
  required ResultadoDaAnalise resultado,
  required Paciente paciente,
  required AvaliacaoCapeV? capeV,
  required String conclusao,
  required Profissional profissional,
  required CatalogoDeReferencias catalogo,
  required DateTime? geradoEm,
}) {
  daPaciente(resultado, paciente.id);
  return ConteudoDoLaudo(
    pacienteId: paciente.id,
    nomeDoPaciente: paciente.nome,
    dataDeNascimento: paciente.dataDeNascimento,
    sexo: paciente.sexo,
    realizadaEm: resultado.realizadaEm,
    medidas: lerMedidas(
      resultado: resultado,
      sexo: paciente.sexo,
      dataDeNascimento: paciente.dataDeNascimento,
      catalogo: catalogo,
    ),
    qualidade: resultado.qualidade,
    capeV: capeV,
    conclusao: conclusao.trim(),
    profissional: profissional,
    geradoEm: geradoEm,
    exemplo: resultado.exemplo,
  );
}
