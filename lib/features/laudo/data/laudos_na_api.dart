import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/relogio.dart';
import '../../auth/data/sessao.dart';
import '../../fila/domain/item_da_fila.dart';
import '../../sincronizacao/domain/sincronizavel.dart';
import '../domain/laudo.dart';
import 'repositorio_laudos_local.dart';

/// A subida dos laudos, ou `null` no modo de exemplo: sem a API de verdade,
/// não há para onde subir.
final sincronizacaoDosLaudosProvider = Provider<Sincronizavel?>(
  (ref) => AppConfig.apiConfigurada
      ? LaudosNaApi(
          ref.watch(dioProvider),
          ref.watch(bancoLocalProvider),
          uid: () => ref.read(sessaoProvider)?.uid,
          agora: ref.watch(relogioProvider),
        )
      : null,
);

/// Sobe para a API a cópia de cada laudo emitido (US38, ADR-018 da API):
/// `POST /v1/pacientes/{p}/sessoes/{s}/laudos`, com o PDF como saiu.
///
/// **De quem é cada laudo.** A sessão só existe no servidor na árvore da
/// conta que a mandou para a análise, e é lá que o laudo dela tem de ficar.
/// Quem mandou está no envio da fila: sobe só o laudo de sessão ENVIADA
/// pela conta que está na sessão — como a CAPE-V (`CapeVNoFirestore`).
///
/// **Em que ordem.** Do mais antigo ao mais recente: o laudo que substitui
/// outro chega depois dele.
///
/// **Repetir é seguro.** O código do documento vai junto, e a API devolve o
/// que já tem quando é o mesmo PDF. O que ela recusa por conteúdo (não é
/// PDF, conclusão longa demais, código já usado para outro documento) não
/// muda tentando de novo: fica de lado até o app abrir outra vez.
class LaudosNaApi implements Sincronizavel {
  LaudosNaApi(this._dio, this._banco, {required this.uid, required this.agora});

  final Dio _dio;
  final BancoLocal _banco;

  /// A conta que está na sessão.
  final String? Function() uid;
  final DateTime Function() agora;

  /// Os que a API recusou pelo conteúdo, nesta abertura do app.
  final _recusados = <String>{};

  @override
  Future<int> sincronizar() async {
    final conta = uid();
    if (conta == null) throw const NaoAutorizado();
    final List<Laudo> pendentes;
    try {
      pendentes = await _pendentes(conta);
    } catch (erro) {
      throw FalhaDesconhecida(causa: erro);
    }
    final repositorio = RepositorioLaudosLocal(_banco);
    var subiram = 0;
    AppException? primeiraFalha;
    for (final laudo in pendentes) {
      try {
        await _subir(laudo);
        await repositorio.marcarEnviado(laudo.id, agora());
        subiram++;
      } on DioException catch (e) {
        final falha = e.error is AppException
            ? e.error! as AppException
            : FalhaDesconhecida(causa: e);
        // 413, 415, 422 e o 409 de código já usado: recusa pelo conteúdo.
        if (falha is FalhaDeValidacao) _recusados.add(laudo.id);
        primeiraFalha ??= falha;
      } on AppException catch (falha) {
        primeiraFalha ??= falha;
      } catch (erro) {
        primeiraFalha ??= FalhaDesconhecida(causa: erro);
      }
    }
    if (primeiraFalha != null) throw primeiraFalha;
    return subiram;
  }

  /// Os laudos ainda não enviados de sessões que [conta] mandou para a
  /// análise, do mais antigo ao mais recente.
  Future<List<Laudo>> _pendentes(String conta) async {
    final laudos = _banco.laudos;
    final envios = _banco.envios;
    final consulta = _banco.select(laudos).join([
      // O id da análise é o id da sessão (ADR-014 da API).
      innerJoin(envios, envios.sessaoId.equalsExp(laudos.analiseId)),
    ]);
    consulta.where(
      laudos.enviadoEm.isNull() &
          envios.profissionalId.equals(conta) &
          envios.situacao.equals(SituacaoDoEnvio.enviado.name),
    );
    consulta.orderBy([
      OrderingTerm.asc(laudos.geradoEm),
      // A ordem de gravação desempata a mesma hora (ver o repositório).
      OrderingTerm.asc(const CustomExpression<int>('laudos.rowid')),
    ]);
    final porId = <String, Laudo>{};
    for (final linha in await consulta.get()) {
      final l = linha.readTable(laudos);
      if (_recusados.contains(l.id)) continue;
      porId[l.id] = Laudo(
        id: l.id,
        analiseId: l.analiseId,
        pacienteId: l.pacienteId,
        conclusao: l.conclusao,
        geradoEm: l.geradoEm,
        pdf: l.pdf,
        substitui: l.substitui,
      );
    }
    return porId.values.toList();
  }

  Future<void> _subir(Laudo laudo) => _dio.post<Object?>(
    '/v1/pacientes/${laudo.pacienteId}/sessoes/${laudo.analiseId}/laudos',
    data: FormData.fromMap({
      'arquivo': MultipartFile.fromBytes(
        laudo.pdf,
        filename: 'laudo-${laudo.codigo}.pdf',
        contentType: DioMediaType('application', 'pdf'),
      ),
      'laudo_id': laudo.id,
      // Com o fuso: a API recusa data sem ele.
      'gerado_em': laudo.geradoEm.toUtc().toIso8601String(),
      'conclusao': laudo.conclusao,
      'substitui': ?laudo.substitui,
    }),
  );
}
