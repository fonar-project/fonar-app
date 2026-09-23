import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../captura/domain/amostra.dart';
import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/resultado_da_analise.dart';

/// TODO(backend): trocar pela API — `GET /analises/{id}`, contrato a acertar
/// com quem mantém a análise, junto do `POST /analises` da fila.
final repositorioAnalisesProvider = Provider<RepositorioAnalises>(
  (ref) => const RepositorioAnalisesPlaceholder(),
);

/// O resultado de uma análise, buscado quando a tela abre.
final analiseProvider = FutureProvider.autoDispose
    .family<ResultadoDaAnalise, String>(
      (ref, analiseId) =>
          ref.watch(repositorioAnalisesProvider).buscar(analiseId),
    );

/// A análise, conferida contra o paciente — ver [daPaciente]. É por aqui que
/// as telas de um paciente leem uma análise.
final analiseDoPacienteProvider = FutureProvider.autoDispose
    .family<ResultadoDaAnalise, ({String pacienteId, String analiseId})>(
      (ref, chave) async => daPaciente(
        await ref.watch(analiseProvider(chave.analiseId).future),
        chave.pacienteId,
      ),
    );

/// PLACEHOLDER — o mesmo resultado FICTÍCIO para qualquer análise.
///
/// Marcado como `exemplo`: a tela avisa que os valores são de exemplo, para
/// que nenhuma captura de tela — inclusive as do texto do TCC — o faça passar
/// por resultado de verdade. Os números não correspondem a nenhum paciente.
class RepositorioAnalisesPlaceholder implements RepositorioAnalises {
  const RepositorioAnalisesPlaceholder();

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async =>
      ResultadoDaAnalise(
        id: analiseId,
        pacienteId: 'exemplo',
        situacao: SituacaoDaAnalise.concluida,
        realizadaEm: DateTime(2026, 7, 23, 10, 5),
        exemplo: true,
        medidas: const [
          MedidaCalculada(medida: MedidaAcustica.avqi, valor: 3.12),
          MedidaCalculada(medida: MedidaAcustica.cpps, valor: 12.4),
          MedidaCalculada(medida: MedidaAcustica.jitter, valor: 0.84),
          MedidaCalculada(medida: MedidaAcustica.shimmer, valor: 3.9),
          MedidaCalculada(medida: MedidaAcustica.hnr, valor: 18.6),
          MedidaCalculada(medida: MedidaAcustica.f0, valor: 212),
        ],
        qualidade: const {
          TarefaDeGravacao.vogalSustentada: QualidadeDaAmostra(adequada: true),
          TarefaDeGravacao.falaEncadeada: QualidadeDaAmostra(adequada: true),
        },
      );
}
