import '../../../design_system/widgets/app_status_medida.dart';
import '../../../l10n/app_strings.dart';
import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/faixa_de_referencia.dart';
import '../domain/leitura_do_resultado.dart';

/// Como cada medida aparece: nome, descrição, unidade e casas decimais.
///
/// Só apresentação — o valor chega pronto do servidor.
///
/// TODO(backend): confirmar com a API a unidade de cada medida. Shimmer, por
/// exemplo, é publicado tanto em % quanto em dB; se a API devolver a unidade
/// junto do valor, ela deve prevalecer sobre esta tabela.
extension ApresentacaoDaMedida on MedidaAcustica {
  String get nome => switch (this) {
    MedidaAcustica.avqi => AppStrings.medidaAvqi,
    MedidaAcustica.cpps => AppStrings.medidaCpps,
    MedidaAcustica.jitter => AppStrings.medidaJitter,
    MedidaAcustica.shimmer => AppStrings.medidaShimmer,
    MedidaAcustica.hnr => AppStrings.medidaHnr,
    MedidaAcustica.f0 => AppStrings.medidaF0,
  };

  String get descricao => switch (this) {
    MedidaAcustica.avqi => AppStrings.medidaAvqiDescricao,
    MedidaAcustica.cpps => AppStrings.medidaCppsDescricao,
    MedidaAcustica.jitter => AppStrings.medidaJitterDescricao,
    MedidaAcustica.shimmer => AppStrings.medidaShimmerDescricao,
    MedidaAcustica.hnr => AppStrings.medidaHnrDescricao,
    MedidaAcustica.f0 => AppStrings.medidaF0Descricao,
  };

  /// Vazia para o AVQI, que é um índice sem unidade.
  String get unidade => switch (this) {
    MedidaAcustica.avqi => '',
    MedidaAcustica.cpps || MedidaAcustica.hnr => 'dB',
    MedidaAcustica.jitter || MedidaAcustica.shimmer => '%',
    MedidaAcustica.f0 => 'Hz',
  };

  int get casasDecimais => switch (this) {
    MedidaAcustica.f0 => 0,
    MedidaAcustica.cpps || MedidaAcustica.hnr => 1,
    _ => 2,
  };

  /// "3,12", "12,4", "212". Sem a unidade — ela vai ao lado, menor.
  String formatar(double valor) => AppStrings.numero(valor, casasDecimais);

  String _comUnidade(double valor) =>
      unidade.isEmpty ? formatar(valor) : '${formatar(valor)} $unidade';

  /// "180–250 Hz", "até 2,95", "a partir de 14,0 dB".
  String descreverFaixa(FaixaDeReferencia faixa) {
    final minimo = faixa.minimo;
    final maximo = faixa.maximo;
    if (minimo != null && maximo != null) {
      final u = unidade.isEmpty ? '' : ' $unidade';
      return '${formatar(minimo)}–${formatar(maximo)}$u';
    }
    if (maximo != null) return 'até ${_comUnidade(maximo)}';
    return 'a partir de ${_comUnidade(minimo!)}';
  }
}

/// Por que a medida está sem classificação, em uma frase para o profissional.
String explicarSemClassificacao(SemClassificacaoPorque motivo) =>
    switch (motivo) {
      SemClassificacaoPorque.naoCalculada =>
        AppStrings.resultadoNaoCalculadaTexto,
      SemClassificacaoPorque.perfilIncompleto =>
        AppStrings.resultadoPerfilIncompleto,
      SemClassificacaoPorque.semFaixaValidada =>
        AppStrings.resultadoSemFaixaValidada,
    };

/// O status do design system para cada classificação.
StatusMedida statusDaClassificacao(ClassificacaoDaMedida c) => switch (c) {
  ClassificacaoDaMedida.dentroDaFaixa => StatusMedida.dentroDaFaixa,
  ClassificacaoDaMedida.limitrofe => StatusMedida.limitrofe,
  ClassificacaoDaMedida.foraDaFaixa => StatusMedida.foraDaFaixa,
  ClassificacaoDaMedida.semReferencia => StatusMedida.semReferencia,
};
