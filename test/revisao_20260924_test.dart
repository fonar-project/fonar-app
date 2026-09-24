// Testes que acompanharam a revisão de 24/09 (itens 1 a 9), mantidos com as
// expectativas como vieram. Falhavam todos em 59364f4; cada item tem também
// teste próprio no arquivo da funcionalidade.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/network/conexao.dart';
import 'package:fonar_app/features/auth/data/sessao.dart';
import 'package:fonar_app/core/relogio.dart';
import 'package:fonar_app/features/auth/data/bloqueio_por_inatividade.dart';
import 'package:fonar_app/features/auth/domain/profissional.dart';
import 'package:fonar_app/features/conta/data/repositorio_da_conta_placeholder.dart';
import 'package:fonar_app/features/conta/domain/dados_do_profissional.dart';
import 'package:fonar_app/features/conta/presentation/conta_controlador.dart';
import 'package:fonar_app/features/captura/presentation/gravacao_controlador.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';
import 'package:fonar_app/features/captura/data/repositorio_amostras_local.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/captura/domain/gravador.dart';
import 'package:fonar_app/features/captura/domain/sessao_nao_enviada.dart';
import 'package:fonar_app/features/captura/presentation/gravacoes_nao_enviadas_controlador.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/fila/data/envio_de_analise_api.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/fila/presentation/fila_controlador.dart';
import 'package:fonar_app/features/reproducao/data/reprodutor_just_audio.dart';
import 'package:fonar_app/features/reproducao/presentation/reproducao_controlador.dart';

import 'apoio/banco_em_memoria.dart';
import 'apoio/repositorios_em_memoria.dart';
import 'features/reproducao/reproducao_test.dart' show ReprodutorFalso;
import 'features/captura/wav_de_teste.dart';

Future<void> settle() async {
  for (var n = 0; n < 12; n++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class Envio implements EnvioDeAnalise {
  int chamadas = 0;
  @override
  Future<String> enviar(ItemDaFila item, {Cancelamento? cancelamento}) async {
    chamadas++;
    return 'analise';
  }
}

class ConsentimentoLento extends RepositorioConsentimentoPlaceholder {
  final pendente = Completer<void>();
  bool consultando = false;
  @override
  Future<RetiradaDeConsentimento?> retiradaEmVigor(String id) async {
    consultando = true;
    await pendente.future;
    return null;
  }
}

class Arquivos implements ArquivosDeAmostra {
  final apagados = <String>[];
  @override
  Future<void> apagar(String caminho) async => apagados.add(caminho);
  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async => null;
  @override
  Future<String> novoCaminho(String id, TarefaDeGravacao t) async =>
      '/novo.wav';
}

class ContaLenta implements RepositorioDaConta {
  final pendente = Completer<void>();
  @override
  Future<void> sair() => pendente.future;
  @override
  Future<void> salvar(Profissional profissional) async {}
}

class DiscoComFalha extends Arquivos {
  final conteudo = <String, Uint8List>{};
  @override
  Future<({Uint8List inicio, int tamanho})?> ler(String caminho) async {
    final bytes = conteudo[caminho];
    return bytes == null ? null : (inicio: bytes, tamanho: bytes.length);
  }

  @override
  Future<void> apagar(String caminho) async {
    if (caminho == '/antiga.wav') throw StateError('arquivo bloqueado');
    conteudo.remove(caminho);
    apagados.add(caminho);
  }
}

class GravadorFalso implements Gravador {
  final niveis = StreamController<double>.broadcast();
  @override
  Future<bool> pedirPermissao() async => true;
  @override
  Future<Stream<double>> iniciar(String caminho, Duration intervalo) async =>
      niveis.stream;
  @override
  Future<void> parar() async {}
  @override
  Future<void> descartar() async {}
}

class ApagaPrimeiroMasFalhaNoSegundo extends Arquivos {
  @override
  Future<void> apagar(String caminho) async {
    if (caminho.endsWith('falaEncadeada.wav')) {
      throw StateError('arquivo em uso');
    }
    apagados.add(caminho);
  }
}

ItemDaFila item({
  SituacaoDoEnvio situacao = SituacaoDoEnvio.naFila,
  List<Amostra> amostras = const [],
}) => ItemDaFila(
  id: 'envio-s',
  pacienteId: 'p',
  nomeDoPaciente: 'Paciente',
  sessaoId: 's',
  amostras: amostras,
  criadoEm: DateTime(2026, 9, 23),
  situacao: situacao,
);

void main() {
  test(
    'review: descarte parcial nao deixa enviar sessao com WAV apagado',
    () async {
      final amostras = [
        for (final tarefa in TarefaDeGravacao.values)
          Amostra(
            id: tarefa.name,
            pacienteId: 'p',
            sessaoId: 's',
            tarefa: tarefa,
            caminho: '/${tarefa.name}.wav',
            gravadaEm: DateTime(2026, 9, 23),
            duracao: const Duration(seconds: 5),
            taxaDeAmostragem: 44100,
            canais: 1,
            problemas: const [],
          ),
      ];
      final repo = RepositorioAmostrasPlaceholder();
      for (final a in amostras) {
        await repo.guardar(a);
      }
      final fila = RepositorioFilaEmMemoria();
      final disco = ApagaPrimeiroMasFalhaNoSegundo();
      final c = ProviderContainer(
        overrides: [
          repositorioAmostrasProvider.overrideWithValue(repo),
          repositorioFilaProvider.overrideWithValue(fila),
          arquivosDeAmostraProvider.overrideWithValue(disco),
          conexaoOnlineProvider.overrideWithValue(false),
          sessaoAbertaProvider.overrideWith(() => Sessao(false)),
        ],
      );
      addTearDown(c.dispose);
      c.listen(limpezaControladorProvider('p'), (_, _) {});
      final ctrl = c.read(limpezaControladorProvider('p').notifier);
      final sessao = SessaoNaoEnviada(
        sessaoId: 's',
        amostras: {for (final a in amostras) a.tarefa: a},
      );
      ctrl.pedirDescarte('s');
      expect(await ctrl.descartar(sessao), isFalse);
      expect(disco.apagados, isNotEmpty);
      expect(await ctrl.enviar(sessao, nomeDoPaciente: 'Paciente'), isFalse);
    },
  );
  test(
    'review: consentimento novo vale mesmo com relogio corrigido para tras',
    () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      var agora = DateTime(2026, 9, 24, 10);
      final repo = RepositorioConsentimentoLocal(banco, agora: () => agora);
      final pedido = (validarConsentimento(
        quemAutoriza: QuemAutoriza.paciente,
        nomeDoResponsavel: '',
        concordou: true,
      ) as ConsentimentoValido).pedido;
      final retirada = (validarRetirada(
        quemPediu: QuemAutoriza.paciente,
        nomeDoResponsavel: '',
      ) as RetiradaValida).pedido;
      await repo.registrar('p', pedido);
      await repo.retirar('p', retirada);
      agora = agora.subtract(const Duration(hours: 1));
      await repo.registrar('p', pedido);
      expect(await repo.buscar('p'), isNotNull);
    },
  );
  test(
    'review: sair do bloqueio mantem a protecao enquanto logout espera',
    () async {
      var agora = DateTime(2026, 9, 24);
      final conta = ContaLenta();
      final c = ProviderContainer(
        overrides: [
          sessaoAbertaProvider.overrideWith(() => Sessao(true)),
          relogioProvider.overrideWithValue(() => agora),
          repositorioDaContaProvider.overrideWithValue(conta),
        ],
      );
      addTearDown(c.dispose);
      c.listen(bloqueioPorInatividadeProvider, (_, _) {});
      c.listen(contaControladorProvider, (_, _) {});
      agora = agora.add(const Duration(minutes: 6));
      c.read(bloqueioPorInatividadeProvider.notifier).conferir();
      expect(c.read(bloqueioPorInatividadeProvider), isTrue);
      final saindo = c.read(contaControladorProvider.notifier).sair();
      await c.pump();
      final protegidoDuranteEspera = c.read(bloqueioPorInatividadeProvider);
      conta.pendente.complete();
      await saindo;
      expect(protegidoDuranteEspera, isTrue);
    },
  );

  test('review: sessao de hoje anterior a uma enviada aparece na limpeza', () {
    Amostra a(String id, int hora) => Amostra(
      id: id,
      pacienteId: 'p',
      sessaoId: id,
      tarefa: TarefaDeGravacao.vogalSustentada,
      caminho: '/$id.wav',
      gravadaEm: DateTime(2026, 9, 24, hora),
      duracao: const Duration(seconds: 5),
      taxaDeAmostragem: 44100,
      canais: 1,
      problemas: const [],
    );
    final lista = sessoesNaoEnviadas(
      amostrasDoPaciente: [a('antiga', 9), a('enviada', 10)],
      sessoesNaFila: {'enviada'},
      agora: DateTime(2026, 9, 24, 11),
    );
    expect(lista.map((s) => s.sessaoId), contains('antiga'));
  });

  test(
    'review: falha apagando WAV antigo nao apaga nova amostra ja salva',
    () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final repo = RepositorioAmostrasLocal(banco);
      final agora = DateTime.now();
      await repo.guardar(
        Amostra(
          id: 'antiga',
          pacienteId: 'p',
          sessaoId: 's',
          tarefa: TarefaDeGravacao.vogalSustentada,
          caminho: '/antiga.wav',
          gravadaEm: agora,
          duracao: const Duration(seconds: 5),
          taxaDeAmostragem: 44100,
          canais: 1,
          problemas: const [],
        ),
      );
      final disco = DiscoComFalha();
      disco.conteudo['/antiga.wav'] = wavDeTeste(
        duracao: const Duration(seconds: 5),
      );
      disco.conteudo['/novo.wav'] = wavDeTeste(
        duracao: const Duration(seconds: 5),
      );
      final gravador = GravadorFalso();
      final c = ProviderContainer(
        overrides: [
          repositorioAmostrasProvider.overrideWithValue(repo),
          repositorioFilaProvider.overrideWithValue(RepositorioFilaEmMemoria()),
          arquivosDeAmostraProvider.overrideWithValue(disco),
          gravadorProvider.overrideWithValue(gravador),
        ],
      );
      addTearDown(c.dispose);
      c.listen(gravacaoControladorProvider('p'), (_, _) {});
      final ctrl = c.read(gravacaoControladorProvider('p').notifier);
      await ctrl.iniciar(TarefaDeGravacao.vogalSustentada);
      for (var i = 0; i < 30; i++) {
        gravador.niveis.add(-30 + (i % 4).toDouble());
      }
      await settle();
      await ctrl.parar();
      final salvo = (await repo.daSessao('s')).single;
      expect(salvo.caminho, '/novo.wav');
      expect(disco.conteudo.containsKey(salvo.caminho), isTrue);
    },
  );
  test('review: parar cancela tambem uma abertura de audio pendente', () async {
    final r = ReprodutorFalso()..segurarAbrir = Completer<void>();
    final c = ProviderContainer(
      overrides: [reprodutorProvider.overrideWithValue(r)],
    );
    addTearDown(c.dispose);
    c.listen(reproducaoControladorProvider, (_, _) {});
    final ctrl = c.read(reproducaoControladorProvider.notifier);
    final abrindo = ctrl.alternar('/a.wav');
    await settle();
    await ctrl.parar();
    r.segurarAbrir!.complete();
    await abrindo;
    expect(r.chamadas, isNot(contains('tocar')));
  });

  test('review: fila reaberta recupera envio interrompido', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    await RepositorioFilaLocal(banco)
        .adicionar(item(situacao: SituacaoDoEnvio.enviando));
    final envio = Envio();
    final c = ProviderContainer(
      overrides: [
        repositorioFilaProvider.overrideWithValue(RepositorioFilaLocal(banco)),
        repositorioConsentimentoProvider.overrideWithValue(
          RepositorioConsentimentoPlaceholder(),
        ),
        envioDeAnaliseProvider.overrideWithValue(envio),
        conexaoOnlineProvider.overrideWithValue(true),
        sessaoAbertaProvider.overrideWith(() => Sessao(true)),
      ],
    );
    addTearDown(c.dispose);
    await c.read(filaControladorProvider.future);
    await settle();
    await c.read(filaControladorProvider.notifier).tentarAgora('envio-s');
    await settle();
    expect(envio.chamadas, 1);
  });

  test(
    'review: logout durante consulta impede inicio tardio de envio',
    () async {
      final repo = RepositorioFilaEmMemoria();
      await repo.adicionar(item());
      final consentimento = ConsentimentoLento();
      final envio = Envio();
      final c = ProviderContainer(
        overrides: [
          repositorioFilaProvider.overrideWithValue(repo),
          repositorioConsentimentoProvider.overrideWithValue(consentimento),
          envioDeAnaliseProvider.overrideWithValue(envio),
          conexaoOnlineProvider.overrideWithValue(true),
          sessaoAbertaProvider.overrideWith(() => Sessao(true)),
        ],
      );
      addTearDown(c.dispose);
      await c.read(filaControladorProvider.future);
      await settle();
      expect(consentimento.consultando, isTrue);
      c.read(sessaoAbertaProvider.notifier).encerrar();
      await c.pump();
      consentimento.pendente.complete();
      await settle();
      expect(envio.chamadas, 0);
    },
  );

  test(
    'review: descarte de lista antiga preserva WAV ja enfileirado',
    () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final a = Amostra(
        id: 'a',
        pacienteId: 'p',
        sessaoId: 's',
        tarefa: TarefaDeGravacao.vogalSustentada,
        caminho: '/a.wav',
        gravadaEm: DateTime(2026, 9, 23),
        duracao: const Duration(seconds: 5),
        taxaDeAmostragem: 44100,
        canais: 1,
        problemas: const [],
      );
      final amostras = RepositorioAmostrasLocal(banco);
      await amostras.guardar(a);
      final sessaoAntiga = SessaoNaoEnviada(
        sessaoId: 's',
        amostras: {a.tarefa: a},
      );
      await RepositorioFilaLocal(banco).adicionar(item(amostras: [a]));
      final arquivos = Arquivos();
      final c = ProviderContainer(
        overrides: [
          repositorioAmostrasProvider.overrideWithValue(amostras),
          arquivosDeAmostraProvider.overrideWithValue(arquivos),
        ],
      );
      addTearDown(c.dispose);
      c.listen(limpezaControladorProvider('p'), (_, _) {});
      final ctrl = c.read(limpezaControladorProvider('p').notifier);
      ctrl.pedirDescarte('s');
      await ctrl.descartar(sessaoAntiga);
      expect(arquivos.apagados, isEmpty);
    },
  );
}
