import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/firestore/firestore_rest.dart';
import '../../auth/data/sessao.dart';
import '../../fila/domain/item_da_fila.dart';
import '../../sincronizacao/data/sincronizacao_firestore.dart';
import '../domain/avaliacao_cape_v.dart';
import 'repositorio_cape_v_local.dart';

/// A sincronização da CAPE-V, ou `null` no modo de exemplo: sem a API de
/// verdade, não há Firebase para onde subir.
final sincronizacaoDaCapeVProvider = Provider<SincronizacaoDaCapeV?>(
  (ref) => AppConfig.apiConfigurada
      ? CapeVNoFirestore(
          ref.watch(firestoreRestProvider),
          ref.watch(bancoLocalProvider),
          uid: () => ref.read(sessaoProvider)?.uid,
        )
      : null,
);

/// Sobe a CAPE-V do banco local para o Firestore, pela API REST.
///
/// O banco local continua sendo de onde o app lê; o Firestore recebe uma
/// cópia em `profissionais/{uid}/pacientes/{p}/sessoes/{s}/avaliacoes/cape_v`,
/// no formato que as regras de segurança aceitam (ADR-017 da API).
///
/// **De quem é cada avaliação.** A sessão só existe no Firestore na árvore da
/// conta que a mandou para a análise, e é lá que a avaliação dela tem de
/// ficar. Quem mandou está no envio da fila ([ItemDaFila.profissionalId]):
/// sobe só a avaliação de sessão ENVIADA pela conta que está na sessão. A de
/// outra conta espera ela entrar; a de sessão de antes da US32, sem dono, não
/// sobe.
///
/// **O que já está lá.** Antes de gravar, lê o documento. Se o de lá for o
/// mesmo registro, ou um mais novo (outro aparelho registrou depois), fica
/// como está: nada desce, mas também nada de mais antigo apaga o mais novo.
/// O que já foi conferido nesta abertura do app não é lido de novo.
class CapeVNoFirestore implements SincronizacaoDaCapeV {
  CapeVNoFirestore(this._firestore, this._banco, {required this.uid});

  final FirestoreRest _firestore;
  final BancoLocal _banco;

  /// A conta que está na sessão.
  final String? Function() uid;

  /// O que já se sabe que está no Firestore como está aqui (ou que nunca vai
  /// estar, por não passar nas regras): a análise e a hora do registro. Só na
  /// memória: na próxima abertura do app, confere de novo, uma leitura por
  /// avaliação.
  final _resolvidas = <String>{};

  static const _documento = 'avaliacoes/cape_v';

  @override
  Future<int> sincronizar() async {
    final conta = uid();
    if (conta == null) throw const NaoAutorizado();
    final local = RepositorioCapeVLocal(_banco);
    final List<({String analiseId, String pacienteId})> pendentes;
    try {
      pendentes = await _daConta(conta);
    } catch (erro) {
      throw FalhaDesconhecida(causa: erro);
    }
    var subiram = 0;
    AppException? primeiraFalha;
    for (final (:analiseId, :pacienteId) in pendentes) {
      try {
        final avaliacao = await local.daAnalise(analiseId);
        if (avaliacao == null || avaliacao.pacienteId != pacienteId) continue;
        if (await _subir(conta, avaliacao)) subiram++;
      } on AppException catch (falha) {
        // As outras seguem; esta fica para a próxima vez.
        primeiraFalha ??= falha;
      } catch (erro) {
        primeiraFalha ??= FalhaDesconhecida(causa: erro);
      }
    }
    if (primeiraFalha != null) throw primeiraFalha;
    return subiram;
  }

  /// As avaliações cuja sessão [conta] mandou para a análise, ainda por
  /// conferir nesta abertura.
  Future<List<({String analiseId, String pacienteId})>> _daConta(
    String conta,
  ) async {
    final avaliacoes = _banco.avaliacoesCapeV;
    final envios = _banco.envios;
    final consulta = _banco.select(avaliacoes).join([
      // O id da análise é o id da sessão (ADR-014 da API).
      innerJoin(envios, envios.sessaoId.equalsExp(avaliacoes.analiseId)),
    ]);
    consulta.where(
      envios.profissionalId.equals(conta) &
          envios.situacao.equals(SituacaoDoEnvio.enviado.name),
    );
    // A mais antiga primeiro: é a que espera há mais tempo.
    consulta.orderBy([OrderingTerm.asc(avaliacoes.registradaEm)]);
    final linhas = await consulta.get();
    final porAnalise = <String, String>{};
    for (final linha in linhas) {
      final avaliacao = linha.readTable(avaliacoes);
      final chave = _chave(avaliacao.analiseId, avaliacao.registradaEm);
      if (_resolvidas.contains(chave)) continue;
      porAnalise[avaliacao.analiseId] = linha.readTable(envios).pacienteId;
    }
    return [
      for (final e in porAnalise.entries)
        (analiseId: e.key, pacienteId: e.value),
    ];
  }

  /// Grava [avaliacao] no Firestore, se for preciso. Devolve `true` se gravou.
  Future<bool> _subir(String conta, AvaliacaoCapeV avaliacao) async {
    final chave = _chave(avaliacao.analiseId, avaliacao.registradaEm);
    // O que as regras recusam não sobe: o app só registra avaliação completa,
    // mas um registro de antes de uma regra nova ficaria tentando para
    // sempre.
    if (conferirNotas(avaliacao.notas).isNotEmpty ||
        avaliacao.comentarios.length > LimitesDoFirestore.comentariosCapeV) {
      _resolvidas.add(chave);
      return false;
    }

    final caminho =
        'profissionais/$conta/pacientes/${avaliacao.pacienteId}'
        '/sessoes/${avaliacao.analiseId}/$_documento';
    final campos = camposDaCapeV(avaliacao);
    final remota = await _firestore.ler(caminho);
    if (remota == null) {
      await _firestore.criar(
        caminho,
        campos,
        horaDoServidor: const ['criado_em', 'atualizado_em'],
      );
    } else {
      final avaliadaEm = remota['avaliada_em'];
      if (avaliadaEm is DateTime &&
          !avaliadaEm.isBefore(avaliacao.registradaEm)) {
        // A mesma, ou uma registrada depois em outro aparelho.
        _resolvidas.add(chave);
        return false;
      }
      await _firestore.atualizar(
        caminho,
        campos,
        mascara: const ['notas', 'comentarios', 'avaliada_em'],
        horaDoServidor: const ['atualizado_em'],
      );
    }
    _resolvidas.add(chave);
    return true;
  }

  static String _chave(String analiseId, DateTime registradaEm) =>
      '$analiseId@${registradaEm.toUtc().toIso8601String()}';
}

/// A avaliação no formato do documento do Firestore — o que as regras
/// aceitam (`capeVValida` em `firestore.rules`, na API).
///
/// Consistência só com desvio, e sentido só com desvio em pitch e loudness:
/// sem desvio, a nota leva só o valor.
Map<String, Object?> camposDaCapeV(AvaliacaoCapeV avaliacao) => {
  'notas': {
    for (final parametro in ParametroCapeV.values)
      nomeNoFirestore(parametro): _nota(parametro, avaliacao.notas[parametro]!),
  },
  'comentarios': avaliacao.comentarios,
  // Quando o profissional registrou, pelo relógio do aparelho: a avaliação
  // pode subir horas depois, quando a rede voltar.
  'avaliada_em': avaliacao.registradaEm,
};

Map<String, Object?> _nota(ParametroCapeV parametro, NotaCapeV nota) => {
  'valor': nota.valor,
  if (nota.temDesvio) 'consistencia': nota.consistencia!.name,
  if (nota.temDesvio && parametro.temDirecao) 'direcao': nota.direcao!.name,
};

/// O nome do parâmetro como as regras e a API o chamam
/// (`ParametroCapeV` em `domain/models.py`) — na subida e na descida.
String nomeNoFirestore(ParametroCapeV parametro) => switch (parametro) {
  ParametroCapeV.grauGeral => 'grau_geral',
  ParametroCapeV.rugosidade => 'rugosidade',
  ParametroCapeV.soprosidade => 'soprosidade',
  ParametroCapeV.tensao => 'tensao',
  ParametroCapeV.pitch => 'pitch',
  ParametroCapeV.loudness => 'loudness',
};
