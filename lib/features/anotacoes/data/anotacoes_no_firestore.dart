import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/firestore/firestore_rest.dart';
import '../../../core/relogio.dart';
import '../../auth/data/sessao.dart';
import '../../sincronizacao/data/sincronizacao_firestore.dart';
import '../../sincronizacao/domain/sincronizavel.dart';
import '../domain/anotacao.dart';
import 'repositorio_anotacoes_local.dart';

/// A subida das anotações, ou `null` no modo de exemplo: sem a API de
/// verdade, não há Firebase para onde subir.
final sincronizacaoDasAnotacoesProvider = Provider<AnotacoesNoFirestore?>((
  ref,
) {
  if (!AppConfig.apiConfigurada) return null;
  final firestore = ref.watch(firestoreRestProvider);
  final banco = ref.watch(bancoLocalProvider);
  String? uid() => ref.read(sessaoProvider)?.uid;
  final pacientes = SincronizacaoFirestore(firestore, banco, uid: uid);
  return AnotacoesNoFirestore(
    firestore,
    RepositorioAnotacoesLocal(banco),
    garantirPaciente: pacientes.garantirPaciente,
    uid: uid,
    agora: ref.watch(relogioProvider),
  );
});

/// Sobe as anotações do banco local para o Firestore, pela API REST (US51),
/// em `profissionais/{uid}/pacientes/{p}/anotacoes/{id}` — no formato que as
/// regras aceitam (ADR-019 da API).
///
/// Cada versão é um documento que não muda de texto: a que falta é criada;
/// a que já está lá só recebe o lembrete visto, se for o caso. As versões
/// sobem na ordem em que foram escritas — a regra pede que a substituída
/// já esteja lá.
///
/// Antes, o cadastro do paciente: anotar não depende de consentimento nem
/// de gravação, e o paciente pode nunca ter subido pela fila.
class AnotacoesNoFirestore implements Sincronizavel {
  AnotacoesNoFirestore(
    this._firestore,
    this._local, {
    required this.garantirPaciente,
    required this.uid,
    required this._agora,
  });

  final FirestoreRest _firestore;
  final RepositorioAnotacoesLocal _local;

  /// Sobe o cadastro do paciente, se ainda não estiver lá como está aqui.
  final Future<void> Function(String pacienteId) garantirPaciente;

  /// A conta que está na sessão: só as anotações dela sobem, na árvore dela.
  final String? Function() uid;
  final DateTime Function() _agora;

  @override
  Future<int> sincronizar() async {
    final conta = uid();
    if (conta == null) throw const NaoAutorizado();
    final List<VersaoDaAnotacao> pendentes;
    try {
      pendentes = await _local.porSubir(conta);
    } catch (erro) {
      throw FalhaDesconhecida(causa: erro);
    }
    var subiram = 0;
    AppException? primeiraFalha;
    final pacientesComFalha = <String>{};
    for (final versao in pendentes) {
      // A versão seguinte do mesmo paciente esperaria a anterior.
      if (pacientesComFalha.contains(versao.pacienteId)) continue;
      try {
        await garantirPaciente(versao.pacienteId);
        if (await _subir(conta, versao)) subiram++;
        await _local.marcarSincronizada(versao, _agora());
      } on AppException catch (falha) {
        pacientesComFalha.add(versao.pacienteId);
        primeiraFalha ??= falha;
      } catch (erro) {
        pacientesComFalha.add(versao.pacienteId);
        primeiraFalha ??= FalhaDesconhecida(causa: erro);
      }
    }
    if (primeiraFalha != null) throw primeiraFalha;
    return subiram;
  }

  /// Grava [versao], ou só o lembrete visto dela. Devolve `true` se gravou.
  Future<bool> _subir(String conta, VersaoDaAnotacao versao) async {
    final caminho =
        'profissionais/$conta/pacientes/${versao.pacienteId}'
        '/anotacoes/${versao.id}';
    final remota = await _firestore.ler(caminho);
    if (remota == null) {
      await _firestore.criar(
        caminho,
        camposDaAnotacao(versao),
        horaDoServidor: const ['registrada_em'],
      );
      return true;
    }
    if (versao.lembreteVistoEm != null && remota['lembrete_visto_em'] == null) {
      await _firestore.atualizar(
        caminho,
        {'lembrete_visto_em': versao.lembreteVistoEm},
        mascara: const ['lembrete_visto_em'],
      );
      return true;
    }
    return false;
  }
}

/// A versão no formato do documento do Firestore — o que as regras aceitam
/// (`anotacaoValida` em `firestore.rules`, na API). `registrada_em` é a
/// hora do servidor, posta na criação.
Map<String, Object?> camposDaAnotacao(VersaoDaAnotacao versao) => {
  'texto': versao.texto,
  // Quando foi escrita, pelo relógio do aparelho: pode subir depois.
  'escrita_em': versao.escritaEm,
  'substitui': versao.substitui,
  'lembrar_na_proxima': versao.lembrarNaProxima,
  // Só com o lembrete pedido: as regras recusam visto sem lembrete.
  'lembrete_visto_em': versao.lembrarNaProxima ? versao.lembreteVistoEm : null,
};

/// A versão como o Firestore a guarda ([camposDaAnotacao], ao contrário),
/// ou `null` se o documento não tiver o formato.
VersaoDaAnotacao? anotacaoDoFirestore(
  String id,
  String pacienteId,
  Map<String, Object?> campos,
) {
  final texto = campos['texto'];
  final escritaEm = campos['escrita_em'];
  final substitui = campos['substitui'];
  final lembrar = campos['lembrar_na_proxima'];
  final visto = campos['lembrete_visto_em'];
  if (texto is! String ||
      escritaEm is! DateTime ||
      lembrar is! bool ||
      (substitui != null && substitui is! String) ||
      (visto != null && visto is! DateTime)) {
    return null;
  }
  return VersaoDaAnotacao(
    id: id,
    pacienteId: pacienteId,
    texto: texto,
    escritaEm: escritaEm,
    substitui: substitui as String?,
    lembrarNaProxima: lembrar,
    lembreteVistoEm: visto as DateTime?,
  );
}

/// Traz as anotações de um paciente da [conta] que estão no Firebase e não
/// aqui (US40, US51): nunca apaga nem passa por cima do que é daqui — o
/// texto nunca muda, e o lembrete visto só vai de vazio para uma data.
/// Devolve quantas versões mudaram aqui.
///
/// Lança só `AppException`.
Future<int> descerAnotacoes(
  FirestoreRest firestore,
  RepositorioAnotacoesLocal local, {
  required String conta,
  required String pacienteId,
  required DateTime agora,
}) async {
  final remotas = await firestore.listar(
    'profissionais/$conta/pacientes/$pacienteId/anotacoes',
  );
  var mudaram = 0;
  for (final (:id, :campos) in remotas) {
    final versao = anotacaoDoFirestore(id, pacienteId, campos);
    if (versao == null) continue;
    try {
      if (await local.trazer(versao, conta: conta, agora: agora)) mudaram++;
    } catch (erro) {
      throw FalhaDesconhecida(causa: erro);
    }
  }
  return mudaram;
}
