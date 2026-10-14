import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analise/data/repositorio_analises_placeholder.dart';
import '../../captura/domain/amostra.dart';
import '../../fila/presentation/fila_controlador.dart';

/// Uma gravação que se pode ouvir: onde ela está e, se já se sabe, quanto
/// dura.
class GravacaoParaOuvir {
  const GravacaoParaOuvir({required this.caminho, this.duracao});

  /// O arquivo neste aparelho, ou o endereço na API ([caminhoNaApi]) da
  /// gravação feita em outro aparelho.
  final String caminho;
  final Duration? duracao;
}

/// O começo do caminho de uma gravação que está só no servidor.
const prefixoDaApi = 'api:';

/// O caminho da gravação [amostraId] no servidor, para o reprodutor buscar
/// com o token (`GET .../amostras/{a}/audio`).
String caminhoNaApi(String pacienteId, String sessaoId, String amostraId) =>
    '$prefixoDaApi/v1/pacientes/$pacienteId/sessoes/$sessaoId'
    '/amostras/$amostraId/audio';

/// As gravações de uma análise que se pode ouvir, por tarefa (US13, US40).
///
/// A deste aparelho, se ainda estiver aqui (achada pelo envio da fila);
/// senão, a do servidor, pelo id que a análise traz — a gravação feita em
/// outro aparelho da mesma conta também se ouve, buscada quando se toca.
final gravacoesParaOuvirProvider = Provider.autoDispose
    .family<Map<TarefaDeGravacao, GravacaoParaOuvir>, ChaveDaAnalise>((
      ref,
      chave,
    ) {
      final locais = ref.watch(amostrasDaAnaliseProvider(chave.analiseId));
      final noServidor =
          ref.watch(analiseProvider(chave)).value?.gravacoes ?? const {};
      return {
        for (final tarefa in TarefaDeGravacao.values)
          if (locais[tarefa] case final amostra?)
            tarefa: GravacaoParaOuvir(
              caminho: amostra.caminho,
              duracao: amostra.duracao,
            )
          else if (noServidor[tarefa] case final id?)
            tarefa: GravacaoParaOuvir(
              caminho: caminhoNaApi(chave.pacienteId, chave.analiseId, id),
            ),
      };
    });
