import '../../historico/domain/evolucao_da_medida.dart';
import '../../pacientes/domain/novo_paciente.dart';
import 'faixa_de_referencia.dart';
import 'resultado_da_analise.dart';

/// Por que uma medida está sem classificação.
enum SemClassificacaoPorque {
  /// O servidor não calculou a medida.
  naoCalculada,

  /// O cadastro não tem sexo (ou tem "não informar") ou data de nascimento, e
  /// a faixa depende dos dois.
  perfilIncompleto,

  /// O perfil está completo, mas o catálogo não tem faixa validada para ele.
  semFaixaValidada,
}

/// Uma medida pronta para exibir: o valor, a faixa usada e a classificação.
class MedidaLida {
  const MedidaLida({
    required this.medida,
    required this.valor,
    required this.classificacao,
    this.faixa,
    this.semClassificacaoPorque,
  });

  final MedidaAcustica medida;
  final double? valor;
  final ClassificacaoDaMedida classificacao;
  final FaixaDeReferencia? faixa;

  /// Preenchido quando [classificacao] é "sem referência".
  final SemClassificacaoPorque? semClassificacaoPorque;
}

/// Lê as medidas de [resultado] para o perfil do paciente.
///
/// A idade é a da data da GRAVAÇÃO, não a de hoje: um resultado revisto um
/// ano depois continua comparado à faixa da idade que o paciente tinha.
List<MedidaLida> lerMedidas({
  required ResultadoDaAnalise resultado,
  required SexoDeReferencia? sexo,
  required DateTime? dataDeNascimento,
  required CatalogoDeReferencias catalogo,
}) {
  final realizadaEm = resultado.realizadaEm;
  final perfil = realizadaEm == null
      ? null
      : PerfilDeReferencia.de(
          sexo: sexo,
          dataDeNascimento: dataDeNascimento,
          em: realizadaEm,
        );

  return [
    for (final m in resultado.medidas)
      if (m.valor == null)
        MedidaLida(
          medida: m.medida,
          valor: null,
          classificacao: ClassificacaoDaMedida.semReferencia,
          semClassificacaoPorque: SemClassificacaoPorque.naoCalculada,
        )
      else if (perfil == null)
        MedidaLida(
          medida: m.medida,
          valor: m.valor,
          classificacao: ClassificacaoDaMedida.semReferencia,
          semClassificacaoPorque: SemClassificacaoPorque.perfilIncompleto,
        )
      else
        _comCatalogo(m, catalogo.faixa(m.medida, perfil)),
  ];
}

MedidaLida _comCatalogo(MedidaCalculada m, FaixaDeReferencia? faixa) {
  final classificacao = classificar(m.valor, faixa);
  return MedidaLida(
    medida: m.medida,
    valor: m.valor,
    classificacao: classificacao,
    faixa: faixa,
    semClassificacaoPorque: faixa == null
        ? SemClassificacaoPorque.semFaixaValidada
        : null,
  );
}
