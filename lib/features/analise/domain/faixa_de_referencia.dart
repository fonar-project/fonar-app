import '../../historico/domain/evolucao_da_medida.dart';
import '../../pacientes/domain/novo_paciente.dart';

/// Faixa de referência de UMA medida para UM perfil.
///
/// ## Regra do projeto — ver "Faixas de referência" no CLAUDE.md
///
/// Os valores de corte são dado de CATÁLOGO, nunca constante de interface: eles
/// variam com sexo, idade e equipamento, e os que aparecem no protótipo ainda
/// não foram validados por profissional da área. Nenhum valor mora no código
/// do aplicativo, e nenhum pode ser inventado.
///
/// Toda faixa traz a [procedencia] — de onde veio. Uma faixa que não sabe dizer
/// de onde veio não pode classificar ninguém.
class FaixaDeReferencia {
  const FaixaDeReferencia({
    required this.procedencia,
    this.minimo,
    this.maximo,
    this.margemLimitrofe,
  }) : assert(
         minimo != null || maximo != null,
         'Faixa sem nenhum limite não classifica nada.',
       );

  /// Abaixo disto está fora. Nulo: sem limite inferior.
  final double? minimo;

  /// Acima disto está fora. Nulo: sem limite superior.
  final double? maximo;

  /// Distância de um limite, por dentro, em que o valor é "no limite da
  /// faixa". Nula: o catálogo não define zona limítrofe, e aí não há
  /// limítrofe — o aplicativo não inventa uma.
  final double? margemLimitrofe;

  /// De onde veio a faixa: estudo, população, equipamento. Exibida ao
  /// profissional junto da classificação.
  final String procedencia;
}

/// Para quem a faixa vale.
class PerfilDeReferencia {
  const PerfilDeReferencia({required this.sexo, required this.idade});

  final SexoDeReferencia sexo;

  /// Anos completos na data da gravação.
  final int idade;

  /// O perfil de um paciente, ou `null` quando falta o que as faixas precisam:
  /// sexo não informado ou data de nascimento desconhecida. Sem perfil, não há
  /// faixa, e as medidas aparecem sem classificação.
  static PerfilDeReferencia? de({
    required SexoDeReferencia? sexo,
    required DateTime? dataDeNascimento,
    required DateTime em,
  }) {
    if (sexo == null || sexo == SexoDeReferencia.naoInformado) return null;
    if (dataDeNascimento == null) return null;
    return PerfilDeReferencia(
      sexo: sexo,
      idade: idadeEntre(dataDeNascimento, em),
    );
  }
}

/// De onde as faixas vêm.
///
/// TODO(clínico): a implementação real lê um catálogo VALIDADO por
/// profissional da área, com procedência de cada faixa, e considera também o
/// equipamento de captação. Enquanto ele não existir, nenhuma faixa é
/// devolvida — ver `CatalogoDeReferenciasVazio`.
abstract interface class CatalogoDeReferencias {
  /// A faixa de [medida] para [perfil], ou `null` se não houver faixa
  /// validada para esse perfil.
  FaixaDeReferencia? faixa(MedidaAcustica medida, PerfilDeReferencia perfil);
}

/// Como um valor fica frente à faixa. Descreve a MEDIDA, nunca o paciente.
enum ClassificacaoDaMedida {
  dentroDaFaixa,
  limitrofe,
  foraDaFaixa,

  /// Sem faixa validada para o perfil, ou sem valor. Estado de primeira
  /// classe: a medida aparece, a classificação não.
  semReferencia,
}

/// Classifica [valor] frente a [faixa].
///
/// Sem faixa ou sem valor, [ClassificacaoDaMedida.semReferencia] — nunca um
/// palpite. Limítrofe só existe quando o catálogo define a margem.
ClassificacaoDaMedida classificar(double? valor, FaixaDeReferencia? faixa) {
  if (valor == null || !valor.isFinite || faixa == null) {
    return ClassificacaoDaMedida.semReferencia;
  }
  final minimo = faixa.minimo;
  final maximo = faixa.maximo;
  final abaixo = minimo != null && valor < minimo;
  final acima = maximo != null && valor > maximo;
  if (abaixo || acima) return ClassificacaoDaMedida.foraDaFaixa;

  final margem = faixa.margemLimitrofe;
  if (margem != null) {
    final pertoDoMinimo = minimo != null && valor - minimo < margem;
    final pertoDoMaximo = maximo != null && maximo - valor < margem;
    if (pertoDoMinimo || pertoDoMaximo) return ClassificacaoDaMedida.limitrofe;
  }
  return ClassificacaoDaMedida.dentroDaFaixa;
}
