// Repositórios em memória, para os testes que não precisam do banco local.
//
// São os que o aplicativo usava antes do Drift (US14), com o mesmo
// comportamento: os testes que dependem deles continuam dizendo a mesma
// coisa. O banco de verdade tem os próprios testes em
// `test/core/banco_local_test.dart`.

import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/consentimento/data/consentimentos_de_exemplo.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/domain/repositorio_consentimento.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/historico/domain/evolucao_da_medida.dart';
import 'package:fonar_app/features/laudo/domain/laudo.dart';
import 'package:fonar_app/features/pacientes/data/pacientes_de_exemplo.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/pacientes/domain/paciente.dart';
import 'package:fonar_app/features/pacientes/domain/repositorio_pacientes.dart';

/// Os pacientes de exemplo e, no topo, os cadastrados.
class RepositorioPacientesPlaceholder implements RepositorioPacientes {
  RepositorioPacientesPlaceholder();

  final _cadastrados = <Paciente>[];

  @override
  Future<List<Paciente>> listar() async => [
    ..._cadastrados.reversed,
    ...pacientesDeExemplo,
  ];

  @override
  Future<Paciente> cadastrar(NovoPaciente novo) async {
    final paciente = Paciente(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      nome: novo.nome,
      queixa: novo.queixa,
      direcaoAvqi: DirecaoDaMedida.semComparacao,
      sexo: novo.sexo,
      dataDeNascimento: novo.dataDeNascimento,
    );
    _cadastrados.add(paciente);
    return paciente;
  }
}

/// Os exemplos A a D já com consentimento; o E sem.
class RepositorioConsentimentoPlaceholder implements RepositorioConsentimento {
  RepositorioConsentimentoPlaceholder();

  final _registros = <String, Consentimento>{...consentimentosDeExemplo};
  final _retiradas = <String, RetiradaDeConsentimento>{};

  @override
  Future<Consentimento?> buscar(String pacienteId) async =>
      _retiradas.containsKey(pacienteId) ? null : _registros[pacienteId];

  @override
  Future<RetiradaDeConsentimento?> retiradaEmVigor(String pacienteId) async =>
      _retiradas[pacienteId];

  @override
  Future<Consentimento> registrar(
    String pacienteId,
    PedidoDeConsentimento pedido,
  ) async {
    final consentimento = Consentimento(
      pacienteId: pacienteId,
      registradoEm: DateTime.now(),
      versaoDoTermo: versaoAtualDoTermo,
      quemAutoriza: pedido.quemAutoriza,
      nomeDoResponsavel: pedido.nomeDoResponsavel,
    );
    _registros[pacienteId] = consentimento;
    _retiradas.remove(pacienteId);
    return consentimento;
  }

  @override
  Future<RetiradaDeConsentimento> retirar(
    String pacienteId,
    PedidoDeRetirada pedido,
  ) async {
    if (await buscar(pacienteId) == null) throw const FalhaDeValidacao();
    return _retiradas[pacienteId] = RetiradaDeConsentimento(
      pacienteId: pacienteId,
      retiradaEm: DateTime.now(),
      quemPediu: pedido.quemPediu,
      nomeDoResponsavel: pedido.nomeDoResponsavel,
    );
  }
}

class RepositorioAmostrasPlaceholder implements RepositorioAmostras {
  RepositorioAmostrasPlaceholder();

  final _amostras = <Amostra>[];

  @override
  Future<List<Amostra>> daSessao(String sessaoId) async => [
    for (final a in _amostras)
      if (a.sessaoId == sessaoId) a,
  ];

  @override
  Future<void> guardar(Amostra amostra) async {
    _amostras
      ..removeWhere(
        (a) => a.sessaoId == amostra.sessaoId && a.tarefa == amostra.tarefa,
      )
      ..add(amostra);
  }
}

class RepositorioFilaEmMemoria implements RepositorioFila {
  RepositorioFilaEmMemoria();

  final _itens = <ItemDaFila>[];

  @override
  Future<List<ItemDaFila>> listar() async => List.unmodifiable(_itens);

  @override
  Future<void> adicionar(ItemDaFila item) async => _itens.add(item);

  @override
  Future<void> atualizar(ItemDaFila item) async {
    final i = _itens.indexWhere((x) => x.id == item.id);
    if (i >= 0) _itens[i] = item;
  }
}

class RepositorioCapeVEmMemoria implements RepositorioCapeV {
  RepositorioCapeVEmMemoria();

  final _porAnalise = <String, AvaliacaoCapeV>{};

  @override
  Future<AvaliacaoCapeV?> daAnalise(String analiseId) async =>
      _porAnalise[analiseId];

  @override
  Future<void> registrar(AvaliacaoCapeV avaliacao) async =>
      _porAnalise[avaliacao.analiseId] = avaliacao;
}

class RepositorioLaudosEmMemoria implements RepositorioLaudos {
  RepositorioLaudosEmMemoria();

  final _porAnalise = <String, Laudo>{};

  @override
  Future<Laudo?> daAnalise(String analiseId) async => _porAnalise[analiseId];

  @override
  Future<void> registrar(Laudo laudo) async =>
      _porAnalise[laudo.analiseId] = laudo;

  @override
  Future<List<Laudo>> doPaciente(String pacienteId) async => [
    for (final l in _porAnalise.values)
      if (l.pacienteId == pacienteId) l,
  ];
}
