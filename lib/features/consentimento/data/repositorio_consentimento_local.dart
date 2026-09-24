import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
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

/// Os consentimentos, no banco local.
///
/// Cada registro é uma linha nova, e nenhuma é apagada ou reescrita: é a
/// prova do que foi autorizado, com qual versão do termo e quando. O que vale
/// é o último registrado — pela ordem de gravação, e não pelo horário: o
/// relógio do aparelho pode ter sido corrigido para trás entre um registro e
/// outro. O horário fica como está, como prova.
///
/// TODO(backend): a sincronização vai precisar de uma regra explícita de
/// ordem entre aparelhos — a sequência local só vale neste banco.
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

  /// Valem só para quem não tem registro no banco, e nunca são gravados.
  final Map<String, Consentimento> exemplos;

  @override
  Future<Consentimento?> buscar(String pacienteId) async {
    final linha =
        await (_banco.select(_banco.consentimentos)
              ..where((c) => c.pacienteId.equals(pacienteId))
              // `id` é autoincremento: cresce a cada registro, com o relógio
              // certo ou não (revisão de 24/09).
              ..orderBy([(c) => OrderingTerm.desc(c.id)])
              ..limit(1))
            .getSingleOrNull();
    if (linha == null) return exemplos[pacienteId];
    return Consentimento(
      pacienteId: linha.pacienteId,
      registradoEm: linha.registradoEm,
      versaoDoTermo: linha.versaoDoTermo,
      quemAutoriza: QuemAutoriza.values.byName(linha.quemAutoriza),
      nomeDoResponsavel: linha.nomeDoResponsavel,
    );
  }

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
}
