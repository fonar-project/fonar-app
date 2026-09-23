import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;

import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/consentimento/data/consentimentos_de_exemplo.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/consentimento/presentation/retirada_consentimento_controlador.dart';
import 'package:fonar_app/features/fila/data/envio_de_analise_api.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/fila/presentation/fila_controlador.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/repositorios_em_memoria.dart';
import '../../core/migracoes/schema.dart';

final _hora = DateTime(2026, 9, 23, 10);

PedidoDeConsentimento _consentimento() => (validarConsentimento(
  quemAutoriza: QuemAutoriza.paciente,
  nomeDoResponsavel: '',
  concordou: true,
) as ConsentimentoValido).pedido;

PedidoDeRetirada _retirada({String? responsavel}) => (validarRetirada(
  quemPediu: responsavel == null
      ? QuemAutoriza.paciente
      : QuemAutoriza.responsavelLegal,
  nomeDoResponsavel: responsavel ?? '',
) as RetiradaValida).pedido;

RepositorioConsentimentoLocal _repositorio({BancoLocal? banco}) {
  if (banco == null) {
    banco = bancoEmMemoria();
    addTearDown(banco.close);
  }
  return RepositorioConsentimentoLocal(
    banco,
    // Relógio parado: a ordem não pode depender da hora.
    agora: () => _hora,
    exemplos: consentimentosDeExemplo,
  );
}

/// Envio que responde na hora, ou segura até ser cancelado.
class _Envio implements EnvioDeAnalise {
  final recebidos = <String>[];
  var segurar = false;

  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) async {
    recebidos.add(item.id);
    if (segurar) {
      await cancelamento!.quandoPedido;
      throw const EnvioCancelado();
    }
    return 'analise-${item.id}';
  }
}

ItemDaFila _item(String pacienteId, String sessaoId) => ItemDaFila(
  id: 'envio-$sessaoId',
  pacienteId: pacienteId,
  nomeDoPaciente: 'Paciente de Teste',
  sessaoId: sessaoId,
  amostras: [
    Amostra(
      id: 'a-$sessaoId',
      pacienteId: pacienteId,
      sessaoId: sessaoId,
      tarefa: TarefaDeGravacao.vogalSustentada,
      caminho: '/amostras/$pacienteId/$sessaoId.wav',
      gravadaEm: _hora,
      duracao: const Duration(seconds: 3),
      taxaDeAmostragem: 44100,
      canais: 1,
      problemas: const [],
    ),
  ],
  criadoEm: _hora,
);

/// A fila, com a rede e a sessão ligadas, e os consentimentos em memória.
({
  ProviderContainer container,
  _Envio envio,
  RepositorioConsentimentoPlaceholder consentimentos,
  RepositorioFila fila,
})
_montar({List<ItemDaFila> itens = const [], bool online = true}) {
  final envio = _Envio();
  final consentimentos = RepositorioConsentimentoPlaceholder();
  final fila = RepositorioFilaEmMemoria();
  for (final i in itens) {
    fila.adicionar(i);
  }
  final container = ProviderContainer(
    overrides: [
      envioDeAnaliseProvider.overrideWithValue(envio),
      sessaoAbertaProvider.overrideWith(() => Sessao(true)),
      conexaoOnlineProvider.overrideWithValue(online),
      relogioProvider.overrideWithValue(() => _hora),
      repositorioFilaProvider.overrideWithValue(fila),
      repositorioConsentimentoProvider.overrideWithValue(consentimentos),
    ],
  );
  addTearDown(container.dispose);
  container.listen(filaControladorProvider, (_, _) {});
  return (
    container: container,
    envio: envio,
    consentimentos: consentimentos,
    fila: fila,
  );
}

Future<void> _assentar() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<ItemDaFila> _itens(ProviderContainer c) =>
    c.read(filaControladorProvider).value!;

void main() {
  group('validarRetirada', () {
    test('sem dizer quem pede, não registra', () {
      final r = validarRetirada(quemPediu: null, nomeDoResponsavel: '');

      expect(r, isA<RetiradaInvalida>());
      expect(
        (r as RetiradaInvalida).quemPediu,
        ProblemaNaRetirada.quemPediuNaoEscolhido,
      );
    });

    test('responsável legal precisa de nome', () {
      final r = validarRetirada(
        quemPediu: QuemAutoriza.responsavelLegal,
        nomeDoResponsavel: '   ',
      );

      expect(
        (r as RetiradaInvalida).nomeDoResponsavel,
        ProblemaNaRetirada.nomeDoResponsavelVazio,
      );
    });

    test('o nome do responsável só é guardado quando é ele quem pede', () {
      final doPaciente = validarRetirada(
        quemPediu: QuemAutoriza.paciente,
        nomeDoResponsavel: 'Rui de Teste',
      );
      final doResponsavel = validarRetirada(
        quemPediu: QuemAutoriza.responsavelLegal,
        nomeDoResponsavel: '  Rui   de Teste ',
      );

      expect((doPaciente as RetiradaValida).pedido.nomeDoResponsavel, isNull);
      expect(
        (doResponsavel as RetiradaValida).pedido.nomeDoResponsavel,
        'Rui de Teste',
      );
    });
  });

  group('no banco local', () {
    test('retirado, deixa de valer — e os dois registros ficam', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repositorio = _repositorio(banco: banco);
      await repositorio.registrar('p1', _consentimento());

      await repositorio.retirar('p1', _retirada(responsavel: 'Rui de Teste'));

      expect(await repositorio.buscar('p1'), isNull);
      final retirada = (await repositorio.retiradaEmVigor('p1'))!;
      expect(retirada.retiradaEm, _hora);
      expect(retirada.quemPediu, QuemAutoriza.responsavelLegal);
      expect(retirada.nomeDoResponsavel, 'Rui de Teste');
      expect(await banco.consentimentos.count().getSingle(), 1);
      expect(await banco.retiradasDeConsentimento.count().getSingle(), 1);
    });

    test('consentimento novo volta a valer, mesmo no mesmo instante', () async {
      // Relógio parado: se a regra comparasse horários, a retirada e o
      // consentimento novo empatariam.
      final repositorio = _repositorio();
      await repositorio.registrar('p1', _consentimento());
      await repositorio.retirar('p1', _retirada());

      await repositorio.registrar('p1', _consentimento());

      expect(await repositorio.buscar('p1'), isNotNull);
      expect(await repositorio.retiradaEmVigor('p1'), isNull);
    });

    test('sem consentimento em vigor, não há o que retirar', () async {
      final repositorio = _repositorio();

      await expectLater(
        repositorio.retirar('p1', _retirada()),
        throwsA(isA<FalhaDeValidacao>()),
      );

      await repositorio.registrar('p1', _consentimento());
      await repositorio.retirar('p1', _retirada());
      await expectLater(
        repositorio.retirar('p1', _retirada()),
        throwsA(isA<FalhaDeValidacao>()),
      );
    });

    test('a retirada de um paciente não mexe no de outro', () async {
      final repositorio = _repositorio();
      await repositorio.registrar('p1', _consentimento());
      await repositorio.registrar('p2', _consentimento());

      await repositorio.retirar('p1', _retirada());

      expect(await repositorio.buscar('p2'), isNotNull);
      expect(await repositorio.retiradaEmVigor('p2'), isNull);
    });

    test('o de exemplo também se retira, e um novo volta a valer', () async {
      final repositorio = _repositorio();
      expect(await repositorio.buscar('exemplo-a'), isNotNull);

      await repositorio.retirar('exemplo-a', _retirada());
      expect(await repositorio.buscar('exemplo-a'), isNull);
      expect(await repositorio.retiradaEmVigor('exemplo-a'), isNotNull);
      // Os outros exemplos continuam como estavam.
      expect(await repositorio.buscar('exemplo-b'), isNotNull);

      await repositorio.registrar('exemplo-a', _consentimento());
      expect(await repositorio.buscar('exemplo-a'), isNotNull);
      expect(await repositorio.retiradaEmVigor('exemplo-a'), isNull);
    });
  });

  group('migração do banco', () {
    final verificador = SchemaVerifier(GeneratedHelper());

    test(
      'da versão 1 para a 2, o formato fica igual ao de um banco novo',
      () async {
        final conexao = await verificador.startAt(1);
        final banco = BancoLocal(conexao);
        addTearDown(banco.close);

        await verificador.migrateAndValidate(banco, 2);
      },
    );

    test('o consentimento gravado na versão 1 continua valendo', () async {
      final esquema = await verificador.schemaAt(1);
      // Como o Drift grava data em texto: com o fuso. Sem ele, lê como UTC.
      esquema.rawDatabase.execute(
        'INSERT INTO consentimentos '
        '(paciente_id, registrado_em, versao_do_termo, quem_autoriza) '
        "VALUES ('p1', '2026-09-01T09:00:00.000Z', 'provisorio-1', 'paciente')",
      );
      final banco = BancoLocal(esquema.newConnection());
      addTearDown(banco.close);
      await verificador.migrateAndValidate(banco, 2);

      final repositorio = _repositorio(banco: banco);
      final c = (await repositorio.buscar('p1'))!;
      expect(
        c.registradoEm.isAtSameMomentAs(DateTime.utc(2026, 9, 1, 9)),
        isTrue,
      );
      expect(c.versaoDoTermo, 'provisorio-1');

      // E dá para retirar depois de atualizar.
      await repositorio.retirar('p1', _retirada());
      expect(await repositorio.buscar('p1'), isNull);
    });
  });

  group('fila', () {
    test('com o consentimento retirado, nada do paciente sobe', () async {
      final m = _montar(itens: [_item('p1', 's1'), _item('p2', 's2')]);
      await m.consentimentos.registrar('p1', _consentimento());
      await m.consentimentos.retirar('p1', _retirada());

      // Com rede e sessão: a fila tenta tudo na abertura.
      await m.container.read(filaControladorProvider.future);
      await _assentar();

      expect(m.envio.recebidos, ['envio-s2']);
      expect(
        [for (final i in _itens(m.container)) i.situacao],
        [SituacaoDoEnvio.semConsentimento, SituacaoDoEnvio.enviado],
      );
    });

    test('a retirada para o que esperava a vez, e só do paciente', () async {
      final m = _montar(
        online: false,
        itens: [_item('p1', 's1'), _item('p2', 's2'), _item('p1', 's3')],
      );
      await m.container.read(filaControladorProvider.future);

      await m.container
          .read(filaControladorProvider.notifier)
          .pararEnviosDoPaciente('p1');

      expect(
        [for (final i in _itens(m.container)) i.situacao],
        [
          SituacaoDoEnvio.semConsentimento,
          SituacaoDoEnvio.naFila,
          SituacaoDoEnvio.semConsentimento,
        ],
      );
      // E fica gravado, não só na tela.
      expect(
        [for (final i in await m.fila.listar()) i.situacao],
        [
          SituacaoDoEnvio.semConsentimento,
          SituacaoDoEnvio.naFila,
          SituacaoDoEnvio.semConsentimento,
        ],
      );
    });

    test('o envio do paciente que está no ar é interrompido', () async {
      final m = _montar();
      await m.consentimentos.registrar('p1', _consentimento());
      await m.container.read(filaControladorProvider.future);
      m.envio.segurar = true;
      unawaited(
        m.container
            .read(filaControladorProvider.notifier)
            .enfileirar(
              pacienteId: 'p1',
              nomeDoPaciente: 'Paciente de Teste',
              sessaoId: 's1',
              amostras: _item('p1', 's1').amostras,
            ),
      );
      await _assentar();
      expect(_itens(m.container).single.situacao, SituacaoDoEnvio.enviando);

      await m.consentimentos.retirar('p1', _retirada());
      await m.container
          .read(filaControladorProvider.notifier)
          .pararEnviosDoPaciente('p1');
      await _assentar();

      expect(
        _itens(m.container).single.situacao,
        SituacaoDoEnvio.semConsentimento,
      );
      expect(m.envio.recebidos, ['envio-s1']);
    });

    test('envio de outro paciente no ar não é interrompido', () async {
      final m = _montar();
      await m.consentimentos.registrar('p1', _consentimento());
      await m.container.read(filaControladorProvider.future);
      m.envio.segurar = true;
      unawaited(
        m.container
            .read(filaControladorProvider.notifier)
            .enfileirar(
              pacienteId: 'p2',
              nomeDoPaciente: 'Outro de Teste',
              sessaoId: 's2',
              amostras: _item('p2', 's2').amostras,
            ),
      );
      await _assentar();

      await m.consentimentos.retirar('p1', _retirada());
      await m.container
          .read(filaControladorProvider.notifier)
          .pararEnviosDoPaciente('p1');
      await _assentar();

      expect(_itens(m.container).single.situacao, SituacaoDoEnvio.enviando);
    });

    test('tentar de novo só sobe com consentimento novo', () async {
      final m = _montar(itens: [_item('p1', 's1')]);
      await m.consentimentos.registrar('p1', _consentimento());
      await m.consentimentos.retirar('p1', _retirada());
      await m.container.read(filaControladorProvider.future);
      await _assentar();
      final controlador = m.container.read(filaControladorProvider.notifier);

      await controlador.tentarAgora('envio-s1');
      expect(
        _itens(m.container).single.situacao,
        SituacaoDoEnvio.semConsentimento,
      );
      expect(m.envio.recebidos, isEmpty);

      await m.consentimentos.registrar('p1', _consentimento());
      await controlador.tentarAgora('envio-s1');
      expect(_itens(m.container).single.situacao, SituacaoDoEnvio.enviado);
      expect(m.envio.recebidos, ['envio-s1']);
    });

    test(
      'sem conseguir conferir, não envia: espera e confere de novo',
      () async {
        final envio = _Envio();
        final container = ProviderContainer(
          overrides: [
            envioDeAnaliseProvider.overrideWithValue(envio),
            sessaoAbertaProvider.overrideWith(() => Sessao(true)),
            conexaoOnlineProvider.overrideWithValue(true),
            relogioProvider.overrideWithValue(() => _hora),
            repositorioFilaProvider.overrideWithValue(
              RepositorioFilaEmMemoria()..adicionar(_item('p1', 's1')),
            ),
            repositorioConsentimentoProvider.overrideWithValue(
              _ConsentimentoQuebrado(),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(filaControladorProvider, (_, _) {});
        await container.read(filaControladorProvider.future);
        await _assentar();

        final item = _itens(container).single;
        expect(envio.recebidos, isEmpty);
        expect(item.situacao, SituacaoDoEnvio.aguardandoNovaTentativa);
        expect(item.proximaTentativa, isNotNull);
      },
    );
  });

  group('controlador', () {
    ProviderContainer montar(RepositorioConsentimentoPlaceholder c) {
      final container = ProviderContainer(
        overrides: [
          envioDeAnaliseProvider.overrideWithValue(_Envio()),
          sessaoAbertaProvider.overrideWith(() => Sessao(true)),
          conexaoOnlineProvider.overrideWithValue(false),
          relogioProvider.overrideWithValue(() => _hora),
          repositorioFilaProvider.overrideWithValue(
            RepositorioFilaEmMemoria()..adicionar(_item('exemplo-a', 's1')),
          ),
          repositorioConsentimentoProvider.overrideWithValue(c),
        ],
      );
      addTearDown(container.dispose);
      container.listen(filaControladorProvider, (_, _) {});
      return container;
    }

    test('sem dizer quem pede, não retira e diz o que corrigir', () async {
      final consentimentos = RepositorioConsentimentoPlaceholder();
      final c = montar(consentimentos);
      c.listen(retiradaConsentimentoProvider('exemplo-a'), (_, _) {});

      final retirou = await c
          .read(retiradaConsentimentoProvider('exemplo-a').notifier)
          .retirar(quemPediu: null, nomeDoResponsavel: '');

      expect(retirou, isFalse);
      expect(
        c.read(retiradaConsentimentoProvider('exemplo-a')).erroQuem,
        AppStrings.retiradaEscolhaQuem,
      );
      expect(await consentimentos.buscar('exemplo-a'), isNotNull);
    });

    test('retira, atualiza o que a tela mostra e para a fila', () async {
      final c = montar(RepositorioConsentimentoPlaceholder());
      await c.read(filaControladorProvider.future);
      expect(
        await c.read(consentimentoProvider('exemplo-a').future),
        isNotNull,
      );
      c.listen(retiradaConsentimentoProvider('exemplo-a'), (_, _) {});

      final retirou = await c
          .read(retiradaConsentimentoProvider('exemplo-a').notifier)
          .retirar(quemPediu: QuemAutoriza.paciente, nomeDoResponsavel: '');

      expect(retirou, isTrue);
      expect(await c.read(consentimentoProvider('exemplo-a').future), isNull);
      expect(
        await c.read(retiradaEmVigorProvider('exemplo-a').future),
        isNotNull,
      );
      expect(_itens(c).single.situacao, SituacaoDoEnvio.semConsentimento);
    });

    test('tela fechada no meio: a fila para mesmo assim', () async {
      final consentimentos = _ConsentimentoLento();
      final c = montar(consentimentos);
      await c.read(filaControladorProvider.future);
      final escuta = c.listen(
        retiradaConsentimentoProvider('exemplo-a'),
        (_, _) {},
      );

      final retirando = c
          .read(retiradaConsentimentoProvider('exemplo-a').notifier)
          .retirar(quemPediu: QuemAutoriza.paciente, nomeDoResponsavel: '');
      // A tela fecha enquanto o banco ainda não respondeu.
      escuta.close();
      await _assentar();
      consentimentos.espera.complete();
      await retirando;

      expect(_itens(c).single.situacao, SituacaoDoEnvio.semConsentimento);
      expect(await c.read(consentimentoProvider('exemplo-a').future), isNull);
    });
  });
}

class _ConsentimentoQuebrado extends RepositorioConsentimentoPlaceholder {
  @override
  Future<RetiradaDeConsentimento?> retiradaEmVigor(String pacienteId) =>
      Future.error(StateError('banco indisponível'));
}

/// Retira só quando o teste deixar.
class _ConsentimentoLento extends RepositorioConsentimentoPlaceholder {
  final espera = Completer<void>();

  @override
  Future<RetiradaDeConsentimento> retirar(
    String pacienteId,
    PedidoDeRetirada pedido,
  ) async {
    await espera.future;
    return super.retirar(pacienteId, pedido);
  }
}
