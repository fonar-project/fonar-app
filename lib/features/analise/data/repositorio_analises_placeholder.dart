import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../captura/domain/amostra.dart';
import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/resultado_da_analise.dart';

/// TODO(backend): trocar pela API — `GET /analises/{id}` e
/// `GET /pacientes/{id}/analises`, contrato a acertar com quem mantém a
/// análise, junto do `POST /analises` da fila.
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

/// Todas as análises de um paciente, para a evolução.
final analisesDoPacienteProvider = FutureProvider.autoDispose
    .family<List<ResultadoDaAnalise>, String>(
      (ref, pacienteId) =>
          ref.watch(repositorioAnalisesProvider).doPaciente(pacienteId),
    );

/// PLACEHOLDER — resultados FICTÍCIOS.
///
/// Todos marcados como `exemplo`: a tela avisa que os valores são de exemplo,
/// para que nenhuma captura de tela — inclusive as do texto do TCC — os faça
/// passar por resultado de verdade. Os números não correspondem a nenhum
/// paciente e não foram escolhidos para cair dentro ou fora de faixa nenhuma.
///
/// Os pacientes de exemplo da lista têm um histórico cada, com a última sessão
/// na mesma data da lista e o AVQI indo na direção que a lista mostra.
/// Paciente cadastrado no aparelho não tem análise nenhuma.
class RepositorioAnalisesPlaceholder implements RepositorioAnalises {
  const RepositorioAnalisesPlaceholder();

  @override
  Future<ResultadoDaAnalise> buscar(String analiseId) async {
    for (final sessoes in _historicos.values) {
      for (final sessao in sessoes) {
        if (sessao.id == analiseId) return sessao;
      }
    }
    return _exemplo(
      id: analiseId,
      pacienteId: 'exemplo',
      em: DateTime(2026, 7, 23, 10, 5),
      avqi: 3.12,
      cpps: 12.4,
      jitter: 0.84,
      shimmer: 3.9,
      hnr: 18.6,
      f0: 212,
    );
  }

  @override
  Future<List<ResultadoDaAnalise>> doPaciente(String pacienteId) async =>
      _historicos[pacienteId] ?? const [];
}

final _historicos = <String, List<ResultadoDaAnalise>>{
  'exemplo-a': [
    _exemplo(
      id: 'exemplo-a-1',
      pacienteId: 'exemplo-a',
      em: DateTime(2026, 5, 28, 9, 40),
      avqi: 4.61,
      cpps: 9.8,
      jitter: 1.32,
      shimmer: 5.4,
      hnr: 15.2,
      f0: 205,
    ),
    _exemplo(
      id: 'exemplo-a-2',
      pacienteId: 'exemplo-a',
      em: DateTime(2026, 6, 18, 10, 10),
      avqi: 4.10,
      cpps: 10.6,
      jitter: 1.10,
      shimmer: 4.8,
      hnr: 16.4,
      f0: 209,
    ),
    _exemplo(
      id: 'exemplo-a-3',
      pacienteId: 'exemplo-a',
      em: DateTime(2026, 7, 2, 9, 55),
      avqi: 3.58,
      cpps: 11.5,
      jitter: 0.95,
      shimmer: 4.3,
      hnr: 17.5,
      f0: 214,
    ),
    _exemplo(
      id: 'exemplo-a-4',
      pacienteId: 'exemplo-a',
      em: DateTime(2026, 7, 23, 10, 5),
      avqi: 3.12,
      cpps: 12.4,
      jitter: 0.84,
      shimmer: 3.9,
      hnr: 18.6,
      f0: 212,
    ),
  ],
  'exemplo-b': [
    _exemplo(
      id: 'exemplo-b-1',
      pacienteId: 'exemplo-b',
      em: DateTime(2026, 6, 20, 14, 30),
      avqi: 3.41,
      cpps: 11.8,
      jitter: 0.97,
      shimmer: 4.5,
      hnr: 17.1,
      f0: 196,
    ),
    _exemplo(
      id: 'exemplo-b-2',
      pacienteId: 'exemplo-b',
      em: DateTime(2026, 7, 18, 14, 15),
      avqi: 3.38,
      cpps: 11.9,
      jitter: 0.95,
      shimmer: 4.4,
      hnr: 17.3,
      f0: 198,
    ),
  ],
  'exemplo-c': [
    _exemplo(
      id: 'exemplo-c-1',
      pacienteId: 'exemplo-c',
      em: DateTime(2026, 6, 5, 11),
      avqi: 2.87,
      cpps: 13.6,
      jitter: 0.71,
      shimmer: 3.2,
      hnr: 20.4,
      f0: 121,
    ),
    _exemplo(
      id: 'exemplo-c-2',
      pacienteId: 'exemplo-c',
      em: DateTime(2026, 7, 10, 11, 20),
      avqi: 3.64,
      cpps: 11.2,
      jitter: 1.02,
      shimmer: 4.6,
      hnr: 17.0,
      f0: 118,
    ),
  ],
  // Com uma f0 que o servidor não calculou, no meio: a linha se interrompe e a
  // tabela diz "não calculada".
  'exemplo-d': [
    _exemplo(
      id: 'exemplo-d-1',
      pacienteId: 'exemplo-d',
      em: DateTime(2026, 5, 7, 8, 50),
      avqi: 5.02,
      cpps: 8.9,
      jitter: 1.55,
      shimmer: 6.1,
      hnr: 13.8,
      f0: 231,
    ),
    _exemplo(
      id: 'exemplo-d-2',
      pacienteId: 'exemplo-d',
      em: DateTime(2026, 6, 4, 9, 5),
      avqi: 4.40,
      cpps: 9.7,
      jitter: 1.38,
      shimmer: 5.5,
      hnr: 14.9,
      f0: null,
    ),
    _exemplo(
      id: 'exemplo-d-3',
      pacienteId: 'exemplo-d',
      em: DateTime(2026, 7, 2, 8, 45),
      avqi: 3.96,
      cpps: 10.5,
      jitter: 1.21,
      shimmer: 5.0,
      hnr: 15.8,
      f0: 226,
    ),
  ],
  'exemplo-e': [
    _exemplo(
      id: 'exemplo-e-1',
      pacienteId: 'exemplo-e',
      em: DateTime(2026, 6, 25, 16, 40),
      avqi: 3.77,
      cpps: 10.9,
      jitter: 1.08,
      shimmer: 4.9,
      hnr: 16.2,
      f0: 187,
    ),
  ],
};

ResultadoDaAnalise _exemplo({
  required String id,
  required String pacienteId,
  required DateTime em,
  required double avqi,
  required double cpps,
  required double jitter,
  required double shimmer,
  required double hnr,
  required double? f0,
}) => ResultadoDaAnalise(
  id: id,
  pacienteId: pacienteId,
  situacao: SituacaoDaAnalise.concluida,
  realizadaEm: em,
  exemplo: true,
  medidas: [
    MedidaCalculada(medida: MedidaAcustica.avqi, valor: avqi),
    MedidaCalculada(medida: MedidaAcustica.cpps, valor: cpps),
    MedidaCalculada(medida: MedidaAcustica.jitter, valor: jitter),
    MedidaCalculada(medida: MedidaAcustica.shimmer, valor: shimmer),
    MedidaCalculada(medida: MedidaAcustica.hnr, valor: hnr),
    MedidaCalculada(medida: MedidaAcustica.f0, valor: f0),
  ],
  qualidade: const {
    TarefaDeGravacao.vogalSustentada: QualidadeDaAmostra(adequada: true),
    TarefaDeGravacao.falaEncadeada: QualidadeDaAmostra(adequada: true),
  },
);
