import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/faixa_de_referencia.dart';

/// TODO(clínico): trocar pelo catálogo validado quando ele existir.
final catalogoDeReferenciasProvider = Provider<CatalogoDeReferencias>(
  (ref) => const CatalogoDeReferenciasVazio(),
);

/// Catálogo sem nenhuma faixa — de propósito.
///
/// Os únicos valores de corte à mão são os do protótipo (AVQI, CPPS, jitter,
/// f0), e eles AINDA NÃO FORAM VALIDADOS por profissional da área. Pôr esses
/// valores aqui faria o aplicativo classificar medidas de pacientes de
/// verdade com referência não validada — e classificar sem referência válida
/// é pior que não classificar. Inventar outros valores está fora de questão.
///
/// Então, até o catálogo validado chegar, toda medida aparece com o valor e
/// com "sem faixa de referência". A classificação em si está pronta e
/// testada; só falta o dado.
class CatalogoDeReferenciasVazio implements CatalogoDeReferencias {
  const CatalogoDeReferenciasVazio();

  @override
  FaixaDeReferencia? faixa(MedidaAcustica medida, PerfilDeReferencia perfil) =>
      null;
}
