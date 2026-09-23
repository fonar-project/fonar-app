import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/relogio.dart';
import '../domain/consentimento.dart';
import '../domain/repositorio_consentimento.dart';
import 'consentimentos_de_exemplo.dart';

/// Versão do texto do termo que a tela apresenta hoje.
///
/// TODO(jurídico): o texto é PROVISÓRIO. Quando a versão revisada chegar,
/// troque o texto em `app_strings.dart` e mude esta versão junto — é ela que
/// diz, em cada registro, com qual texto a pessoa concordou.
const versaoAtualDoTermo = 'provisorio-1';

final repositorioConsentimentoProvider = Provider<RepositorioConsentimento>(
  (ref) => RepositorioConsentimentoLocal(
    ref.watch(bancoLocalProvider),
    agora: ref.watch(relogioProvider),
    exemplos: consentimentosDeExemplo,
  ),
);

/// Consentimento em vigor para o paciente, ou `null`.
final consentimentoProvider = FutureProvider.family<Consentimento?, String>(
  (ref, pacienteId) =>
      ref.watch(repositorioConsentimentoProvider).buscar(pacienteId),
);

/// A retirada que está valendo para o paciente, ou `null`.
final retiradaEmVigorProvider =
    FutureProvider.family<RetiradaDeConsentimento?, String>(
      (ref, pacienteId) => ref
          .watch(repositorioConsentimentoProvider)
          .retiradaEmVigor(pacienteId),
    );

/// Os consentimentos e as retiradas, no banco local.
///
/// Cada registro é uma linha nova, e nenhuma é apagada ou reescrita: é a
/// prova do que foi autorizado, com qual versão do termo e quando, e de
/// quando foi retirado. Vale o consentimento mais recente, se não tiver sido
/// retirado.
///
/// TODO(backend): subir pela fila de sincronização quando o Firebase entrar.
class RepositorioConsentimentoLocal implements RepositorioConsentimento {
  RepositorioConsentimentoLocal(
    this._banco, {
    required this._agora,
    this.exemplos = const {},
  });

  final BancoLocal _banco;
  final DateTime Function() _agora;

  /// Valem só para quem não tem registro no banco, e nunca são gravados. A
  /// retirada de um deles, essa, vai para o banco.
  final Map<String, Consentimento> exemplos;

  @override
  Future<Consentimento?> buscar(String pacienteId) async =>
      switch (await _ultimo(pacienteId)) {
        (final c?, null) => c,
        _ => null,
      };

  @override
  Future<RetiradaDeConsentimento?> retiradaEmVigor(String pacienteId) async =>
      (await _ultimo(pacienteId)).$2;

  @override
  Future<Consentimento> registrar(
    String pacienteId,
    PedidoDeConsentimento pedido,
  ) async {
    final consentimento = Consentimento(
      pacienteId: pacienteId,
      registradoEm: _agora(),
      versaoDoTermo: versaoAtualDoTermo,
      quemAutoriza: pedido.quemAutoriza,
      nomeDoResponsavel: pedido.nomeDoResponsavel,
    );
    await _banco
        .into(_banco.consentimentos)
        .insert(
          ConsentimentosCompanion.insert(
            pacienteId: pacienteId,
            registradoEm: consentimento.registradoEm,
            versaoDoTermo: consentimento.versaoDoTermo,
            quemAutoriza: consentimento.quemAutoriza.name,
            nomeDoResponsavel: Value(consentimento.nomeDoResponsavel),
          ),
        );
    return consentimento;
  }

  @override
  Future<RetiradaDeConsentimento> retirar(
    String pacienteId,
    PedidoDeRetirada pedido,
  ) => _banco.transaction(() async {
    final linha = await _ultimaLinha(pacienteId);
    final (vigente, retirada) = await _ultimo(pacienteId, linha: linha);
    if (vigente == null || retirada != null) throw const FalhaDeValidacao();

    final nova = RetiradaDeConsentimento(
      pacienteId: pacienteId,
      retiradaEm: _agora(),
      quemPediu: pedido.quemPediu,
      nomeDoResponsavel: pedido.nomeDoResponsavel,
    );
    await _banco
        .into(_banco.retiradasDeConsentimento)
        .insert(
          RetiradasDeConsentimentoCompanion.insert(
            pacienteId: pacienteId,
            // Sem linha no banco, o vigente é o de exemplo.
            consentimentoId: Value(linha?.id),
            retiradaEm: nova.retiradaEm,
            quemPediu: nova.quemPediu.name,
            nomeDoResponsavel: Value(nova.nomeDoResponsavel),
          ),
        );
    return nova;
  });

  /// O último consentimento do paciente e, se ele foi retirado, a retirada.
  Future<(Consentimento?, RetiradaDeConsentimento?)> _ultimo(
    String pacienteId, {
    LinhaDoConsentimento? linha,
  }) async {
    linha ??= await _ultimaLinha(pacienteId);
    final consentimento = linha == null
        ? exemplos[pacienteId]
        : Consentimento(
            pacienteId: linha.pacienteId,
            registradoEm: linha.registradoEm,
            versaoDoTermo: linha.versaoDoTermo,
            quemAutoriza: QuemAutoriza.values.byName(linha.quemAutoriza),
            nomeDoResponsavel: linha.nomeDoResponsavel,
          );
    if (consentimento == null) return (null, null);

    final t = _banco.retiradasDeConsentimento;
    final retirada =
        await (_banco.select(t)
              ..where(
                (r) => linha == null
                    ? r.pacienteId.equals(pacienteId) &
                          r.consentimentoId.isNull()
                    : r.consentimentoId.equals(linha.id),
              )
              ..limit(1))
            .getSingleOrNull();
    return (
      consentimento,
      retirada == null
          ? null
          : RetiradaDeConsentimento(
              pacienteId: retirada.pacienteId,
              retiradaEm: retirada.retiradaEm,
              quemPediu: QuemAutoriza.values.byName(retirada.quemPediu),
              nomeDoResponsavel: retirada.nomeDoResponsavel,
            ),
    );
  }

  Future<LinhaDoConsentimento?> _ultimaLinha(String pacienteId) =>
      (_banco.select(_banco.consentimentos)
            ..where((c) => c.pacienteId.equals(pacienteId))
            ..orderBy([
              (c) => OrderingTerm.desc(c.registradoEm),
              (c) => OrderingTerm.desc(c.id),
            ])
            ..limit(1))
          .getSingleOrNull();
}
