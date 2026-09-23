import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/banco/novo_id.dart';
import 'package:fonar_app/core/offline/pacientes_em_cache.dart';
import 'package:fonar_app/features/cape_v/data/repositorio_cape_v_local.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/captura/data/repositorio_amostras_local.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/verificacao_da_amostra.dart';
import 'package:fonar_app/features/consentimento/data/consentimentos_de_exemplo.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/laudo/data/repositorio_laudos_local.dart';
import 'package:fonar_app/features/laudo/domain/laudo.dart';
import 'package:fonar_app/features/pacientes/data/pacientes_de_exemplo.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';

import '../apoio/banco_em_memoria.dart';

BancoLocal _banco() {
  final banco = bancoEmMemoria();
  addTearDown(banco.close);
  return banco;
}

NovoPaciente _novo(
  String nome, {
  SexoDeReferencia sexo = SexoDeReferencia.feminino,
}) => (validarCadastro(
  nome: nome,
  nascimento: '14/03/1990',
  sexo: sexo,
  queixa: 'rouquidão (teste)',
  hoje: DateTime(2026, 9, 23),
) as CadastroValido).paciente;

PedidoDeConsentimento _pedido({String? responsavel}) => (validarConsentimento(
  quemAutoriza: responsavel == null
      ? QuemAutoriza.paciente
      : QuemAutoriza.responsavelLegal,
  nomeDoResponsavel: responsavel ?? '',
  concordou: true,
) as ConsentimentoValido).pedido;

Amostra _amostra(
  String id, {
  String sessaoId = 's1',
  TarefaDeGravacao tarefa = TarefaDeGravacao.vogalSustentada,
  List<ProblemaNaAmostra> problemas = const [],
}) => Amostra(
  id: id,
  pacienteId: 'p1',
  sessaoId: sessaoId,
  tarefa: tarefa,
  caminho: '/amostras/p1/$id.wav',
  // Com fração de segundo: duas gravações no mesmo segundo precisam
  // continuar em ordem.
  gravadaEm: DateTime(2026, 9, 23, 10, 15, 30, 250, 125),
  duracao: const Duration(milliseconds: 4321),
  taxaDeAmostragem: 44100,
  canais: 1,
  problemas: problemas,
);

ItemDaFila _envio(String id, {List<Amostra>? amostras}) => ItemDaFila(
  id: id,
  pacienteId: 'p1',
  nomeDoPaciente: 'Ana de Teste',
  sessaoId: 'sessao-$id',
  amostras:
      amostras ??
      [
        _amostra('$id-vogal'),
        _amostra('$id-fala', tarefa: TarefaDeGravacao.falaEncadeada),
      ],
  criadoEm: DateTime(2026, 9, 23, 10),
);

void main() {
  group('persistência', () {
    test('o que se grava continua lá ao abrir o arquivo de novo', () async {
      // O motivo da US: fechar o app não pode levar o cadastro, o
      // consentimento nem a fila junto.
      final pasta = await Directory.systemTemp.createTemp('fonar_banco');
      addTearDown(() => pasta.delete(recursive: true));
      final arquivo = File('${pasta.path}/fonar.sqlite');
      final agora = DateTime(2026, 9, 23, 9, 30);

      final antes = BancoLocal(NativeDatabase(arquivo));
      final paciente = await RepositorioPacientesLocal(
        antes,
        agora: () => agora,
      ).cadastrar(_novo('Ana de Teste'));
      await RepositorioConsentimentoLocal(
        antes,
        agora: () => agora,
      ).registrar(paciente.id, _pedido());
      await RepositorioFilaLocal(antes).adicionar(_envio('e1'));
      await antes.close();

      final depois = BancoLocal(NativeDatabase(arquivo));
      addTearDown(depois.close);

      final pacientes = await RepositorioPacientesLocal(
        depois,
        agora: () => agora,
      ).listar();
      expect(pacientes.single.nome, 'Ana de Teste');
      final consentimento = await RepositorioConsentimentoLocal(
        depois,
        agora: () => agora,
      ).buscar(paciente.id);
      expect(consentimento?.registradoEm, agora);
      final fila = await RepositorioFilaLocal(depois).listar();
      expect(fila.single.id, 'e1');
      expect(fila.single.amostras, hasLength(2));
    });

    test('chave estrangeira ligada: amostra de um envio não some', () async {
      final banco = _banco();
      await RepositorioFilaLocal(banco).adicionar(_envio('e1'));

      await expectLater(
        (banco.delete(
          banco.amostras,
        )..where((a) => a.id.equals('e1-vogal'))).go(),
        throwsA(anything),
      );
    });
  });

  group('pacientes', () {
    test('cadastrado vai para o topo, antes dos de exemplo', () async {
      final banco = _banco();
      var hora = DateTime(2026, 9, 23, 9);
      final repositorio = RepositorioPacientesLocal(
        banco,
        agora: () => hora,
        exemplos: pacientesDeExemplo,
      );

      await repositorio.cadastrar(_novo('Primeira de Teste'));
      hora = hora.add(const Duration(minutes: 1));
      await repositorio.cadastrar(_novo('Segunda de Teste'));

      final nomes = [for (final p in await repositorio.listar()) p.nome];
      expect(nomes.take(2), ['Segunda de Teste', 'Primeira de Teste']);
      expect(nomes.skip(2), [for (final p in pacientesDeExemplo) p.nome]);
    });

    test('sexo e nascimento voltam como foram', () async {
      final repositorio = RepositorioPacientesLocal(
        _banco(),
        agora: DateTime.now,
      );
      final salvo = await repositorio.cadastrar(
        _novo('Ana de Teste', sexo: SexoDeReferencia.naoInformado),
      );

      final lido = (await repositorio.listar()).single;
      expect(lido.id, salvo.id);
      expect(lido.sexo, SexoDeReferencia.naoInformado);
      expect(lido.dataDeNascimento, DateTime(1990, 3, 14));
      expect(lido.ultimaSessao, isNull);
    });

    test('só os do banco contam para entrar offline, contados de novo a cada '
        'vez que o login aparece', () async {
      final container = ProviderContainer(overrides: [bancoDeTeste()]);
      addTearDown(container.dispose);

      // O login aparece: nada no banco — os de exemplo não contam.
      var login = container.listen(pacientesEmCacheProvider.future, (_, _) {});
      expect(await login.read(), 0);
      login.close();

      // Durante a sessão, um cadastro; depois, sair e o login aparece de novo.
      await container
          .read(repositorioPacientesProvider)
          .cadastrar(_novo('Ana de Teste'));
      await Future<void>.delayed(Duration.zero);
      login = container.listen(pacientesEmCacheProvider.future, (_, _) {});
      addTearDown(login.close);

      expect(await login.read(), 1);
    });
  });

  test('id novo: UUID versão 4, sem repetir', () {
    final ids = {for (var i = 0; i < 1000; i++) novoId()};

    expect(ids, hasLength(1000));
    for (final id in ids) {
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
  });

  group('consentimento', () {
    test('sem registro no banco, vale o de exemplo', () async {
      final repositorio = RepositorioConsentimentoLocal(
        _banco(),
        agora: DateTime.now,
        exemplos: consentimentosDeExemplo,
      );

      expect((await repositorio.buscar('exemplo-a'))?.versaoDoTermo, 'exemplo');
      expect(await repositorio.buscar('exemplo-e'), isNull);
    });

    test('registrar de novo guarda os dois, e vale o mais recente', () async {
      final banco = _banco();
      var hora = DateTime(2026, 9, 23, 9);
      final repositorio = RepositorioConsentimentoLocal(
        banco,
        agora: () => hora,
      );

      await repositorio.registrar('p1', _pedido());
      hora = hora.add(const Duration(days: 30));
      await repositorio.registrar('p1', _pedido(responsavel: 'Rui de Teste'));

      final vigente = await repositorio.buscar('p1');
      expect(vigente?.registradoEm, hora);
      expect(vigente?.quemAutoriza, QuemAutoriza.responsavelLegal);
      expect(vigente?.nomeDoResponsavel, 'Rui de Teste');
      expect(vigente?.versaoDoTermo, versaoAtualDoTermo);
      // A prova do primeiro continua lá.
      expect(await banco.consentimentos.count().getSingle(), 2);
    });

    test('o de um paciente não vale para outro', () async {
      final repositorio = RepositorioConsentimentoLocal(
        _banco(),
        agora: DateTime.now,
      );
      await repositorio.registrar('p1', _pedido());

      expect(await repositorio.buscar('p2'), isNull);
    });
  });

  group('amostras', () {
    test('regravar a tarefa substitui só na mesma sessão', () async {
      final repositorio = RepositorioAmostrasLocal(_banco());
      await repositorio.guardar(_amostra('a1'));
      await repositorio.guardar(_amostra('a2', sessaoId: 's2'));
      await repositorio.guardar(
        _amostra('a3', tarefa: TarefaDeGravacao.falaEncadeada),
      );

      await repositorio.guardar(_amostra('a4'));

      expect([for (final a in await repositorio.daSessao('s1')) a.id]..sort(), [
        'a3',
        'a4',
      ]);
      expect([for (final a in await repositorio.daSessao('s2')) a.id], ['a2']);
    });

    test('formato conferido e problemas voltam como foram', () async {
      final repositorio = RepositorioAmostrasLocal(_banco());
      final original = _amostra(
        'a1',
        problemas: [
          ProblemaNaAmostra.saturou,
          ProblemaNaAmostra.formatoAjustado,
        ],
      );
      await repositorio.guardar(original);
      await repositorio.guardar(
        _amostra('a2', tarefa: TarefaDeGravacao.falaEncadeada),
      );

      final lidas = {for (final a in await repositorio.daSessao('s1')) a.id: a};
      final lida = lidas['a1']!;
      expect(lida.gravadaEm, original.gravadaEm);
      expect(lida.duracao, original.duracao);
      expect(lida.taxaDeAmostragem, 44100);
      expect(lida.canais, 1);
      expect(lida.caminho, original.caminho);
      expect(lida.problemas, original.problemas);
      expect(lidas['a2']!.problemas, isEmpty);
    });

    test('problema que o app não conhece mais é deixado de fora', () async {
      final banco = _banco();
      await RepositorioAmostrasLocal(banco)
          .guardar(_amostra('a1', problemas: [ProblemaNaAmostra.saturou]));
      await (banco.update(banco.amostras)..where((a) => a.id.equals('a1')))
          .write(const AmostrasCompanion(problemas: Value('saturou,removido')));

      final lida = (await RepositorioAmostrasLocal(banco).daSessao('s1'))
          .single;
      expect(lida.problemas, [ProblemaNaAmostra.saturou]);
    });
  });

  group('fila', () {
    test(
      'lista na ordem de chegada, com as amostras na ordem do envio',
      () async {
        final repositorio = RepositorioFilaLocal(_banco());
        await repositorio.adicionar(_envio('e2'));
        await repositorio.adicionar(_envio('e1'));

        final itens = await repositorio.listar();
        expect([for (final i in itens) i.id], ['e2', 'e1']);
        expect(
          [for (final a in itens.first.amostras) a.id],
          ['e2-vogal', 'e2-fala'],
        );
        expect(itens.first.situacao, SituacaoDoEnvio.naFila);
        expect(itens.first.nomeDoPaciente, 'Ana de Teste');
      },
    );

    test('atualizar grava a situação, e apaga o que ficou nulo', () async {
      final repositorio = RepositorioFilaLocal(_banco());
      final item = _envio('e1');
      await repositorio.adicionar(item);

      final falhou = item.copiar(
        situacao: SituacaoDoEnvio.aguardandoNovaTentativa,
        tentativas: 2,
        proximaTentativa: () => DateTime(2026, 9, 23, 10, 1),
        ultimaFalha: () => 'Sem conexão (teste).',
      );
      await repositorio.atualizar(falhou);
      var lido = (await repositorio.listar()).single;
      expect(lido.situacao, SituacaoDoEnvio.aguardandoNovaTentativa);
      expect(lido.tentativas, 2);
      expect(lido.proximaTentativa, DateTime(2026, 9, 23, 10, 1));
      expect(lido.ultimaFalha, 'Sem conexão (teste).');

      await repositorio.atualizar(
        falhou.copiar(
          situacao: SituacaoDoEnvio.enviado,
          proximaTentativa: () => null,
          ultimaFalha: () => null,
          analiseId: 'an-1',
        ),
      );
      lido = (await repositorio.listar()).single;
      expect(lido.situacao, SituacaoDoEnvio.enviado);
      expect(lido.proximaTentativa, isNull);
      expect(lido.ultimaFalha, isNull);
      expect(lido.analiseId, 'an-1');
      expect(lido.amostras, hasLength(2));
    });

    test('envio que falha ao gravar não fica pela metade', () async {
      final repositorio = RepositorioFilaLocal(_banco());
      await repositorio.adicionar(_envio('e1'));

      // Mesmo id: o banco recusa, e nada do segundo fica.
      await expectLater(
        repositorio.adicionar(
          _envio('e1', amostras: [_amostra('outra', sessaoId: 'x')]),
        ),
        throwsA(anything),
      );

      final itens = await repositorio.listar();
      expect(
        [for (final a in itens.single.amostras) a.id],
        ['e1-vogal', 'e1-fala'],
      );
    });
  });

  group('CAPE-V', () {
    AvaliacaoCapeV avaliacao(Map<ParametroCapeV, NotaCapeV> notas) =>
        AvaliacaoCapeV(
          analiseId: 'an-1',
          pacienteId: 'p1',
          notas: notas,
          registradaEm: DateTime(2026, 9, 23, 11),
          comentarios: 'voz tensa (teste)',
        );

    test('as notas voltam como foram marcadas', () async {
      final repositorio = RepositorioCapeVLocal(_banco());
      await repositorio.registrar(
        avaliacao({
          ParametroCapeV.grauGeral: const NotaCapeV(
            valor: 40,
            consistencia: Consistencia.intermitente,
          ),
          ParametroCapeV.pitch: const NotaCapeV(
            valor: 25,
            consistencia: Consistencia.consistente,
            direcao: DirecaoDoDesvio.abaixo,
          ),
          ParametroCapeV.rugosidade: const NotaCapeV(valor: 0),
        }),
      );

      final lida = (await repositorio.daAnalise('an-1'))!;
      expect(lida.comentarios, 'voz tensa (teste)');
      expect(lida.registradaEm, DateTime(2026, 9, 23, 11));
      expect(lida.notas, hasLength(3));
      expect(lida.notas[ParametroCapeV.grauGeral]?.valor, 40);
      expect(
        lida.notas[ParametroCapeV.grauGeral]?.consistencia,
        Consistencia.intermitente,
      );
      expect(lida.notas[ParametroCapeV.pitch]?.direcao, DirecaoDoDesvio.abaixo);
      expect(lida.notas[ParametroCapeV.rugosidade]?.valor, 0);
      expect(lida.notas[ParametroCapeV.rugosidade]?.consistencia, isNull);
      expect(await repositorio.daAnalise('an-2'), isNull);
    });

    test('registrar de novo substitui por inteiro', () async {
      final repositorio = RepositorioCapeVLocal(_banco());
      await repositorio.registrar(
        avaliacao({
          ParametroCapeV.grauGeral: const NotaCapeV(valor: 40),
          ParametroCapeV.tensao: const NotaCapeV(valor: 10),
        }),
      );

      await repositorio.registrar(
        avaliacao({ParametroCapeV.grauGeral: const NotaCapeV(valor: 20)}),
      );

      final lida = (await repositorio.daAnalise('an-1'))!;
      expect(lida.notas.keys, [ParametroCapeV.grauGeral]);
      expect(lida.notas[ParametroCapeV.grauGeral]?.valor, 20);
    });
  });

  group('laudos', () {
    Laudo laudo(String analiseId, String pacienteId, List<int> bytes) => Laudo(
      analiseId: analiseId,
      pacienteId: pacienteId,
      conclusao: 'conclusão do profissional (teste)',
      geradoEm: DateTime(2026, 9, 23, 12),
      pdf: Uint8List.fromList(bytes),
    );

    test('o PDF volta byte a byte, e gerar de novo substitui', () async {
      final repositorio = RepositorioLaudosLocal(_banco());
      await repositorio.registrar(laudo('an-1', 'p1', [1, 2, 3]));
      await repositorio.registrar(
        laudo('an-1', 'p1', [0x25, 0x50, 0x44, 0x46]),
      );

      final lido = (await repositorio.daAnalise('an-1'))!;
      expect(lido.pdf, [0x25, 0x50, 0x44, 0x46]);
      expect(lido.conclusao, 'conclusão do profissional (teste)');
      expect(lido.geradoEm, DateTime(2026, 9, 23, 12));
      expect(await repositorio.daAnalise('an-2'), isNull);
    });

    test('os do paciente, e só os dele', () async {
      final repositorio = RepositorioLaudosLocal(_banco());
      await repositorio.registrar(laudo('an-1', 'p1', [1]));
      await repositorio.registrar(laudo('an-2', 'p1', [2]));
      await repositorio.registrar(laudo('an-3', 'p2', [3]));

      final doP1 = await repositorio.doPaciente('p1');
      expect([for (final l in doP1) l.analiseId]..sort(), ['an-1', 'an-2']);
    });
  });
}
