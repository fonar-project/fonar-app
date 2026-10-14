import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/banco/conversao.dart';
import '../../../core/banco/novo_id.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/relogio.dart';
import '../../auth/data/sessao.dart';
import '../../historico/domain/evolucao_da_medida.dart';
import '../domain/novo_paciente.dart';
import '../domain/paciente.dart';
import '../domain/repositorio_pacientes.dart';
import 'pacientes_de_exemplo.dart';

final repositorioPacientesProvider = Provider<RepositorioPacientes>(
  (ref) => RepositorioPacientesLocal(
    ref.watch(bancoLocalProvider),
    agora: ref.watch(relogioProvider),
    // Os de exemplo existem para os resultados de exemplo: com a API de
    // verdade, nenhum dos dois aparece.
    exemplos: AppConfig.apiConfigurada ? const [] : pacientesDeExemplo,
    conta: () => ref.read(sessaoProvider)?.uid,
  ),
);

/// Lista de pacientes da tela, já carregada — os da conta que está na
/// sessão. Trocar de conta carrega de novo.
final pacientesProvider = FutureProvider<List<Paciente>>((ref) {
  ref.watch(sessaoProvider.select((s) => s?.uid));
  return ref.watch(repositorioPacientesProvider).listar();
});

/// Um paciente pelo id, ou `null` se ele não estiver neste aparelho.
///
/// Deriva da lista: com dezenas de pacientes por profissional, procurar na
/// lista já carregada custa menos que uma consulta própria, e cadastrar um
/// paciente novo atualiza os dois de uma vez.
final pacienteProvider = FutureProvider.family<Paciente?, String>((
  ref,
  pacienteId,
) async {
  final todos = await ref.watch(pacientesProvider.future);
  for (final paciente in todos) {
    if (paciente.id == pacienteId) return paciente;
  }
  return null;
});

/// Os pacientes da conta, no banco local.
///
/// O cadastro sobe para o Firebase antes de cada envio para a análise
/// (US33, `SincronizacaoFirestore`), e as correções feitas aqui vão junto. O
/// que outro aparelho cadastrou desce para este (US40, `DescidaDoFirestore`).
///
/// **Cada paciente é de uma conta** (US40). Num aparelho compartilhado, quem
/// entra vê só os pacientes dela: o cadastro leva a conta da sessão, e a
/// lista e a correção só alcançam os dela. O paciente sem dono — cadastrado
/// antes da US40 — aparece para qualquer conta até ser adotado, o que
/// acontece na primeira entrada depois da atualização.
class RepositorioPacientesLocal implements RepositorioPacientes {
  RepositorioPacientesLocal(
    this._banco, {
    required this._agora,
    this.exemplos = const [],
    String? Function()? conta,
  }) : _conta = conta ?? _semConta;

  final BancoLocal _banco;
  final DateTime Function() _agora;

  /// A conta da sessão. Nula só fora de uma sessão (os testes de banco): aí
  /// a lista não filtra por conta.
  final String? Function() _conta;

  static String? _semConta() => null;

  /// Mostrados depois dos cadastrados, e nunca gravados no banco.
  final List<Paciente> exemplos;

  /// Os pacientes que a conta [conta] alcança: os dela e os sem dono.
  static Expression<bool> daConta($PacientesTable p, String? conta) =>
      conta == null
      ? const Constant(true)
      : p.profissionalId.equals(conta) | p.profissionalId.isNull();

  @override
  Future<List<Paciente>> listar() async {
    final conta = _conta();
    if (conta != null) await adotarPacientesSemDono(_banco, conta);
    final linhas =
        await (_banco.select(_banco.pacientes)
              ..where((p) => daConta(p, conta))
              ..orderBy([
                (p) => OrderingTerm.desc(p.cadastradoEm),
                (p) => OrderingTerm.desc(p.rowId),
              ]))
            .get();
    final ultimas = await _ultimaGravacaoPorPaciente();
    return [
      // Recém-cadastrado ainda não tem sessão, e mesmo assim vai no topo: é
      // quem o profissional acabou de atender e vai procurar em seguida.
      for (final l in linhas)
        Paciente(
          id: l.id,
          nome: l.nome,
          queixa: l.queixa,
          ultimaSessao: ultimas[l.id],
          // TODO(clínico): segue sem comparação até haver limiar de mudança
          // validado para o AVQI — ver `limiares_de_mudanca_indefinidos.dart`.
          direcaoAvqi: DirecaoDaMedida.semComparacao,
          sexo: enumOuNulo(SexoDeReferencia.values, l.sexo),
          dataDeNascimento: l.dataDeNascimento,
        ),
      ...exemplos,
    ];
  }

  /// A data da gravação mais recente de cada paciente, neste aparelho.
  ///
  /// É a "última sessão" da lista: a consulta em que algo foi gravado, tenha
  /// ido para a análise ou não. A sessão inteira é de um dia só (a retomada
  /// só vale no mesmo dia — `captura/domain/retomada.dart`), então a gravação
  /// mais nova dá a data dela.
  ///
  /// O máximo sai aqui, e não do agregado de data do Drift: com a data
  /// guardada como texto (`build.yaml`), ele passa por `unixepoch` e volta como
  /// `datetime(…, 'unixepoch')` — em UTC, sem o fuso com que foi gravada e
  /// cortado no segundo. Perto da meia-noite, isso pode trocar o dia. Lida
  /// coluna a coluna, a data volta como foi gravada. São poucas linhas: duas
  /// tarefas por sessão.
  Future<Map<String, DateTime>> _ultimaGravacaoPorPaciente() async {
    final amostras = _banco.amostras;
    final linhas = await (_banco.selectOnly(
      amostras,
    )..addColumns([amostras.pacienteId, amostras.gravadaEm])).get();
    final ultimas = <String, DateTime>{};
    for (final linha in linhas) {
      final paciente = linha.read(amostras.pacienteId)!;
      final gravadaEm = linha.read(amostras.gravadaEm)!;
      final atual = ultimas[paciente];
      if (atual == null || gravadaEm.isAfter(atual)) {
        ultimas[paciente] = gravadaEm;
      }
    }
    return ultimas;
  }

  @override
  Future<Paciente> atualizar(String id, NovoPaciente dados) async {
    final conta = _conta();
    final alteradas =
        await (_banco.update(
          _banco.pacientes,
        )..where((p) => p.id.equals(id) & daConta(p, conta))).write(
          PacientesCompanion(
            nome: Value(dados.nome),
            queixa: Value(dados.queixa),
            sexo: Value(dados.sexo.name),
            dataDeNascimento: Value(dados.dataDeNascimento),
            // A correção ainda não subiu: o que descer não a sobrescreve.
            alteradoEm: Value(_agora()),
          ),
        );
    if (alteradas == 0) throw const NaoEncontrado();
    return Paciente(
      id: id,
      nome: dados.nome,
      queixa: dados.queixa,
      direcaoAvqi: DirecaoDaMedida.semComparacao,
      sexo: dados.sexo,
      dataDeNascimento: dados.dataDeNascimento,
    );
  }

  @override
  Future<Paciente> cadastrar(NovoPaciente novo) async {
    final paciente = Paciente(
      // Gerado no aparelho, para não colidir na sincronização.
      id: novoId(),
      nome: novo.nome,
      queixa: novo.queixa,
      direcaoAvqi: DirecaoDaMedida.semComparacao,
      sexo: novo.sexo,
      dataDeNascimento: novo.dataDeNascimento,
    );
    await _banco
        .into(_banco.pacientes)
        .insert(
          PacientesCompanion.insert(
            id: paciente.id,
            nome: paciente.nome,
            queixa: paciente.queixa,
            sexo: Value(novo.sexo.name),
            dataDeNascimento: Value(novo.dataDeNascimento),
            cadastradoEm: _agora(),
            profissionalId: Value(_conta()),
            alteradoEm: Value(_agora()),
          ),
        );
    return paciente;
  }
}

/// Dá dono aos pacientes cadastrados antes da US40, que não têm: o de quem
/// gravou a primeira sessão dele, se houver; senão, a [conta] que está
/// entrando. Devolve quantos foram adotados.
///
/// Antes da US40 o aparelho não separava por conta; a gravação já dizia de
/// quem era (`Envios.profissionalId`, desde a US32), e é ela que decide
/// primeiro. Roda a cada lista — depois da primeira vez, não acha ninguém.
Future<int> adotarPacientesSemDono(BancoLocal banco, String conta) =>
    banco.customUpdate(
      'UPDATE pacientes SET profissional_id = COALESCE(('
      'SELECT e.profissional_id FROM envios e '
      'WHERE e.paciente_id = pacientes.id AND e.profissional_id IS NOT NULL '
      'ORDER BY e.posicao LIMIT 1'
      '), ?) WHERE profissional_id IS NULL',
      variables: [Variable.withString(conta)],
      updates: {banco.pacientes},
      updateKind: UpdateKind.update,
    );
