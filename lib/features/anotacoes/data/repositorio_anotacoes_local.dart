import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/banco/novo_id.dart';
import '../domain/anotacao.dart';

final repositorioAnotacoesProvider = Provider<RepositorioAnotacoesLocal>(
  (ref) => RepositorioAnotacoesLocal(ref.watch(bancoLocalProvider)),
);

/// As anotações do paciente no banco local (US51): uma linha por versão,
/// que nunca muda de texto. Editar acrescenta uma versão; nada se apaga
/// aqui — só a eliminação do paciente (`EliminacaoDoPaciente`).
class RepositorioAnotacoesLocal {
  RepositorioAnotacoesLocal(this._banco);

  final BancoLocal _banco;

  $AnotacoesDoPacienteTable get _tabela => _banco.anotacoesDoPaciente;

  /// As anotações de um paciente, da mais recente à mais antiga, e de novo
  /// a cada mudança.
  Stream<List<Anotacao>> observar(String pacienteId) =>
      (_banco.select(_tabela)..where((a) => a.pacienteId.equals(pacienteId)))
          .watch()
          .map((linhas) => montarAnotacoes(linhas.map(versaoDaLinha)));

  /// As anotações de um paciente agora, da mais recente à mais antiga.
  Future<List<Anotacao>> doPaciente(String pacienteId) async {
    final linhas = await (_banco.select(
      _tabela,
    )..where((a) => a.pacienteId.equals(pacienteId))).get();
    return montarAnotacoes(linhas.map(versaoDaLinha));
  }

  /// Os pacientes da [conta] com anotação neste aparelho, cada um com as
  /// suas — para o selo de lembrete da lista.
  Stream<Map<String, List<Anotacao>>> observarDaConta(String conta) =>
      (_banco.select(
        _tabela,
      )..where((a) => a.profissionalId.equals(conta))).watch().map((linhas) {
        final porPaciente = <String, List<VersaoDaAnotacao>>{};
        for (final linha in linhas) {
          (porPaciente[linha.pacienteId] ??= []).add(versaoDaLinha(linha));
        }
        return {
          for (final MapEntry(:key, :value) in porPaciente.entries)
            key: montarAnotacoes(value),
        };
      });

  /// Escreve uma anotação nova — ou uma versão nova de [substitui].
  Future<VersaoDaAnotacao> escrever({
    required String pacienteId,
    required String profissionalId,
    required String texto,
    required bool lembrarNaProxima,
    required DateTime agora,
    String? substitui,
  }) async {
    final versao = VersaoDaAnotacao(
      id: novoId(),
      pacienteId: pacienteId,
      texto: texto,
      escritaEm: agora,
      substitui: substitui,
      lembrarNaProxima: lembrarNaProxima,
    );
    await _banco
        .into(_tabela)
        .insert(
          AnotacoesDoPacienteCompanion.insert(
            id: versao.id,
            pacienteId: pacienteId,
            profissionalId: profissionalId,
            texto: texto,
            escritaEm: agora,
            substitui: Value(substitui),
            lembrarNaProxima: lembrarNaProxima,
          ),
        );
    return versao;
  }

  /// Marca os lembretes como vistos. O que já estava visto fica com a data
  /// de antes; o que mudou volta a ter o que subir.
  Future<void> marcarLembretesVistos(Iterable<String> ids, DateTime quando) =>
      (_banco.update(
            _tabela,
          )..where((a) => a.id.isIn(ids.toList()) & a.lembreteVistoEm.isNull()))
          .write(
            AnotacoesDoPacienteCompanion(
              lembreteVistoEm: Value(quando),
              sincronizadaEm: const Value(null),
            ),
          );

  // ------------------------------------------------- sincronização --

  /// As versões da [conta] com algo por subir, das mais antigas às mais
  /// novas: uma versão só sobe depois da que ela substitui.
  Future<List<VersaoDaAnotacao>> porSubir(String conta) async {
    final linhas =
        await (_banco.select(_tabela)
              ..where(
                (a) =>
                    a.profissionalId.equals(conta) & a.sincronizadaEm.isNull(),
              )
              ..orderBy([(a) => OrderingTerm.asc(a.escritaEm)]))
            .get();
    return [for (final l in linhas) versaoDaLinha(l)];
  }

  /// O Firebase tem esta versão como ela está aqui — se ela não mudou
  /// enquanto subia (o lembrete visto no meio continua por subir).
  Future<void> marcarSincronizada(VersaoDaAnotacao versao, DateTime quando) =>
      (_banco.update(_tabela)..where(
            (a) =>
                a.id.equals(versao.id) &
                (versao.lembreteVistoEm == null
                    ? a.lembreteVistoEm.isNull()
                    : a.lembreteVistoEm.equals(versao.lembreteVistoEm!)),
          ))
          .write(AnotacoesDoPacienteCompanion(sincronizadaEm: Value(quando)));

  /// Traz uma versão que está no Firebase. A que falta entra; a que existe
  /// só ganha o lembrete visto noutro aparelho — o texto nunca muda, e o
  /// visto só vai de vazio para uma data. Devolve se algo mudou aqui.
  Future<bool> trazer(
    VersaoDaAnotacao remota, {
    required String conta,
    required DateTime agora,
  }) async {
    final local = await (_banco.select(
      _tabela,
    )..where((a) => a.id.equals(remota.id))).getSingleOrNull();
    if (local == null) {
      await _banco
          .into(_tabela)
          .insert(
            AnotacoesDoPacienteCompanion.insert(
              id: remota.id,
              pacienteId: remota.pacienteId,
              profissionalId: conta,
              texto: remota.texto,
              escritaEm: remota.escritaEm,
              substitui: Value(remota.substitui),
              lembrarNaProxima: remota.lembrarNaProxima,
              lembreteVistoEm: Value(remota.lembreteVistoEm),
              sincronizadaEm: Value(agora),
            ),
          );
      return true;
    }
    if (local.lembreteVistoEm == null && remota.lembreteVistoEm != null) {
      await (_banco.update(
        _tabela,
      )..where((a) => a.id.equals(remota.id))).write(
        AnotacoesDoPacienteCompanion(
          lembreteVistoEm: Value(remota.lembreteVistoEm),
          // Igual dos dois lados agora — a não ser que a versão em si
          // ainda não tenha subido.
          sincronizadaEm: local.sincronizadaEm == null
              ? const Value.absent()
              : Value(agora),
        ),
      );
      return true;
    }
    return false;
  }
}

VersaoDaAnotacao versaoDaLinha(LinhaDaAnotacao linha) => VersaoDaAnotacao(
  id: linha.id,
  pacienteId: linha.pacienteId,
  texto: linha.texto,
  escritaEm: linha.escritaEm,
  substitui: linha.substitui,
  lembrarNaProxima: linha.lembrarNaProxima,
  lembreteVistoEm: linha.lembreteVistoEm,
);
