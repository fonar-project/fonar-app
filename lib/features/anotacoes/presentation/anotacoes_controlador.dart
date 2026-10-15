import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/relogio.dart';
import '../../auth/data/sessao.dart';
import '../../sincronizacao/domain/sincronizavel.dart';
import '../../sincronizacao/presentation/sincronizacao_em_segundo_plano.dart';
import '../data/anotacoes_no_firestore.dart';
import '../data/repositorio_anotacoes_local.dart';
import '../domain/anotacao.dart';

/// As anotações de um paciente, da mais recente à mais antiga, e de novo a
/// cada mudança — daqui ou da descida.
final anotacoesDoPacienteProvider = StreamProvider.autoDispose
    .family<List<Anotacao>, String>(
      (ref, pacienteId) =>
          ref.watch(repositorioAnotacoesProvider).observar(pacienteId),
    );

/// Os lembretes de um paciente que esperam ser vistos hoje.
final lembretesDoPacienteProvider = Provider.autoDispose
    .family<List<Anotacao>, String>((ref, pacienteId) {
      final anotacoes = ref.watch(anotacoesDoPacienteProvider(pacienteId));
      return lembretesPendentes(
        anotacoes.value ?? const [],
        ref.watch(relogioProvider)(),
      );
    });

/// Os pacientes da conta com lembrete esperando ser visto hoje — o selo da
/// lista de pacientes.
final pacientesComLembreteProvider = StreamProvider.autoDispose<Set<String>>((
  ref,
) {
  final conta = ref.watch(sessaoProvider.select((s) => s?.uid));
  if (conta == null) return Stream.value(const {});
  final hoje = ref.watch(relogioProvider);
  return ref
      .watch(repositorioAnotacoesProvider)
      .observarDaConta(conta)
      .map(
        (porPaciente) => {
          for (final MapEntry(:key, :value) in porPaciente.entries)
            if (lembretesPendentes(value, hoje()).isNotEmpty) key,
        },
      );
});

/// Escrever, editar e ver o lembrete (US51). Tudo vai primeiro para o banco
/// do aparelho — funciona sem rede — e sobe depois, sozinho.
class AnotacoesControlador {
  AnotacoesControlador(this._ref);

  final Ref _ref;

  RepositorioAnotacoesLocal get _repositorio =>
      _ref.read(repositorioAnotacoesProvider);

  /// Escreve uma anotação nova.
  Future<void> escrever(
    String pacienteId, {
    required String texto,
    required bool lembrarNaProxima,
  }) => _gravar(pacienteId, texto: texto, lembrarNaProxima: lembrarNaProxima);

  /// Edita [anotacao]: grava uma versão nova, que substitui a vigente. A de
  /// antes continua guardada.
  Future<void> editar(
    Anotacao anotacao, {
    required String texto,
    required bool lembrarNaProxima,
  }) => _gravar(
    anotacao.vigente.pacienteId,
    texto: texto,
    lembrarNaProxima: lembrarNaProxima,
    substitui: anotacao.id,
  );

  /// O profissional viu os lembretes.
  Future<void> marcarVistos(Iterable<Anotacao> lembretes) async {
    await _repositorio.marcarLembretesVistos([
      for (final a in lembretes) a.id,
    ], _ref.read(relogioProvider)());
    _ref.read(sincronizacaoDasAnotacoesControladorProvider.notifier).pedir();
  }

  Future<void> _gravar(
    String pacienteId, {
    required String texto,
    required bool lembrarNaProxima,
    String? substitui,
  }) async {
    final conta = _ref.read(sessaoProvider)?.uid;
    if (conta == null) throw StateError('anotação sem sessão aberta');
    await _repositorio.escrever(
      pacienteId: pacienteId,
      profissionalId: conta,
      texto: texto.trim(),
      lembrarNaProxima: lembrarNaProxima,
      agora: _ref.read(relogioProvider)(),
      substitui: substitui,
    );
    _ref.read(sincronizacaoDasAnotacoesControladorProvider.notifier).pedir();
  }
}

final anotacoesControladorProvider = Provider<AnotacoesControlador>(
  AnotacoesControlador.new,
);

/// Sobe as anotações para o Firebase sem ninguém olhando (US51). O quando é
/// o de toda [SincronizacaoEmSegundoPlano]; o quê, [AnotacoesNoFirestore].
class SincronizacaoDasAnotacoesControlador extends SincronizacaoEmSegundoPlano {
  @override
  Sincronizavel? get alvo => ref.read(sincronizacaoDasAnotacoesProvider);
}

final sincronizacaoDasAnotacoesControladorProvider =
    NotifierProvider<SincronizacaoDasAnotacoesControlador, void>(
      SincronizacaoDasAnotacoesControlador.new,
    );
