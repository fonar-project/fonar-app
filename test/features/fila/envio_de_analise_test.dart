import 'dart:io';

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/dio_client.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/captura/data/arquivos_de_amostra_no_navegador.dart';
import 'package:fonar_app/features/captura/data/gravador_record.dart';
import 'package:fonar_app/features/captura/domain/amostra.dart';
import 'package:fonar_app/features/fila/data/envio_de_analise_api.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/fila/domain/repositorio_fila.dart';
import 'package:fonar_app/features/sincronizacao/data/sincronizacao_firestore.dart';
import 'package:fonar_app/features/sincronizacao/domain/sincronizacao.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/http_falso.dart';

const _paciente = '0f8b7e5c-3c1a-4d2e-9f00-1a2b3c4d5e6f';
const _sessao = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

/// A sincronização anotada, para conferir que vem antes do primeiro WAV.
class _Sincronizacao implements Sincronizacao {
  _Sincronizacao(this.ordem, {this.falha});

  final List<String> ordem;
  final AppException? falha;

  @override
  Future<void> prepararEnvio(ItemDaFila item) async {
    ordem.add('sincronizou');
    if (falha case final f?) throw f;
  }
}

/// Os campos de texto de um corpo multipart.
Map<String, String> _campos(String corpo) => {
  for (final m in RegExp(
    r'name="([^"]+)"\r\n\r\n([^\r]*)\r\n',
  ).allMatches(corpo))
    m.group(1)!: m.group(2)!,
};

void main() {
  late Directory pasta;
  late List<Amostra> amostras;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('fonar-envio-');
    addTearDown(() => pasta.deleteSync(recursive: true));
    Amostra gravar(String id, TarefaDeGravacao tarefa) {
      final arquivo = File('${pasta.path}/$id.wav')
        ..writeAsBytesSync([82, 73, 70, 70, 0, 1, 2, 3]);
      return Amostra(
        id: id,
        pacienteId: _paciente,
        sessaoId: _sessao,
        tarefa: tarefa,
        caminho: arquivo.path,
        gravadaEm: DateTime.utc(2026, 10, 11, 13),
        duracao: const Duration(seconds: 3),
        taxaDeAmostragem: 44100,
        canais: 1,
        problemas: const [],
      );
    }

    amostras = [
      gravar('a1', TarefaDeGravacao.vogalSustentada),
      gravar('a2', TarefaDeGravacao.falaEncadeada),
    ];
  });

  ItemDaFila item() => ItemDaFila(
    id: 'envio-$_sessao',
    pacienteId: _paciente,
    nomeDoPaciente: 'Ana de Teste',
    sessaoId: _sessao,
    amostras: amostras,
    criadoEm: DateTime.utc(2026, 10, 11, 13),
  );

  ({EnvioDeAnaliseApi envio, AdaptadorFalso servidor, List<String> ordem})
  montar(List<RespostaFalsa> respostas, {AppException? falhaNaSincronizacao}) {
    final ordem = <String>[];
    final servidor = AdaptadorFalso(respostas);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = servidor
      ..interceptors.add(const ErrorInterceptor());
    final envio = EnvioDeAnaliseApi(
      dio,
      _Sincronizacao(ordem, falha: falhaNaSincronizacao),
      plataforma: () => (sistema: 'android', versao: 'Android 15 (teste)'),
    );
    return (envio: envio, servidor: servidor, ordem: ordem);
  }

  test('cada gravação vai numa requisição, depois da sincronização, e a '
      'análise é a sessão', () async {
    final m = montar([
      const RespostaFalsa(201, {}),
      const RespostaFalsa(201, {}),
    ]);

    final analiseId = await m.envio.enviar(item());

    expect(analiseId, _sessao);
    expect(m.ordem, ['sincronizou']);
    expect(m.servidor.feitas, hasLength(2));
    for (final pedido in m.servidor.feitas) {
      expect(pedido.opcoes.method, 'POST');
      expect(
        pedido.uri.toString(),
        'https://api.test/v1/pacientes/$_paciente/sessoes/$_sessao/amostras',
      );
    }
    final [vogal, fala] = [for (final p in m.servidor.feitas) _campos(p.corpo)];
    expect(vogal, {
      'amostra_id': 'a1',
      'tipo_tarefa': 'vogal_sustentada',
      'plataforma': 'android',
      'dispositivo': 'Android 15 (teste)',
      'taxa_amostragem_hz': '44100',
      'canais': '1',
    });
    expect(fala['amostra_id'], 'a2');
    expect(fala['tipo_tarefa'], 'fala_encadeada');
    // O WAV vai no campo `arquivo`, com o id da amostra no nome.
    expect(
      m.servidor.feitas.first.corpo,
      contains('name="arquivo"; filename="a1.wav"'),
    );
  });

  test('a falha na sincronização para antes de qualquer WAV', () async {
    final m = montar([], falhaNaSincronizacao: const Proibido());
    await expectLater(m.envio.enviar(item()), throwsA(isA<Proibido>()));
    expect(m.servidor.feitas, isEmpty);
  });

  test('cancelado depois da sincronização, nenhum WAV sai', () async {
    final cancelamento = Cancelamento();
    final ordem = <String>[];
    final servidor = AdaptadorFalso([]);
    final envio = EnvioDeAnaliseApi(
      Dio()..httpClientAdapter = servidor,
      _CancelaAoSincronizar(ordem, cancelamento),
    );
    await expectLater(
      envio.enviar(item(), cancelamento: cancelamento),
      throwsA(isA<EnvioCancelado>()),
    );
    expect(servidor.feitas, isEmpty);
  });

  // US42: no navegador o WAV mora no banco local, e o envio o lê de lá.
  group('no navegador', () {
    ({EnvioDeAnalise envio, AdaptadorFalso servidor}) montarNoNavegador(
      ArquivosDeAmostraNoNavegador arquivos,
      List<RespostaFalsa> respostas,
    ) {
      final servidor = AdaptadorFalso(respostas);
      final container = ProviderContainer(
        overrides: [
          arquivosDeAmostraProvider.overrideWithValue(arquivos),
          dioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'https://api.test'))
              ..httpClientAdapter = servidor
              ..interceptors.add(const ErrorInterceptor()),
          ),
          sincronizacaoProvider.overrideWithValue(_Sincronizacao([])),
        ],
      );
      addTearDown(container.dispose);
      return (
        envio: container.read(envioDeAnaliseProvider),
        servidor: servidor,
      );
    }

    test(
      'o WAV sai do banco local, com o mesmo nome e os mesmos bytes',
      () async {
        final banco = bancoEmMemoria();
        addTearDown(banco.close);
        final arquivos = ArquivosDeAmostraNoNavegador(banco);
        for (final a in amostras) {
          await arquivos.guardar(
            a.caminho,
            Uint8List.fromList(File(a.caminho).readAsBytesSync()),
          );
          File(a.caminho).deleteSync();
        }
        final m = montarNoNavegador(arquivos, [
          const RespostaFalsa(201, {}),
          const RespostaFalsa(201, {}),
        ]);

        expect(await m.envio.enviar(item()), _sessao);

        expect(m.servidor.feitas, hasLength(2));
        final corpo = m.servidor.feitas.first.corpo;
        expect(corpo, contains('name="arquivo"; filename="a1.wav"'));
        expect(corpo, contains('RIFF'));
        expect(_campos(corpo)['plataforma'], startsWith('web-'));
      },
    );

    test('gravação que não está no banco não vai, e não volta', () async {
      final banco = bancoEmMemoria();
      addTearDown(banco.close);
      final m = montarNoNavegador(ArquivosDeAmostraNoNavegador(banco), []);

      await expectLater(
        m.envio.enviar(item()),
        throwsA(isA<GravacaoNaoEncontrada>()),
      );
      expect(m.servidor.feitas, isEmpty);
    });
  });

  group('recusas da API', () {
    Future<AppException> falhaCom(int status, [String? codigo]) async {
      final m = montar([
        RespostaFalsa(status, {
          if (codigo != null) 'detail': {'codigo': codigo, 'mensagem': 'teste'},
        }),
      ]);
      try {
        await m.envio.enviar(item());
      } on AppException catch (falha) {
        return falha;
      }
      fail('o envio devia ter falhado');
    }

    test('sem consentimento no servidor para como a retirada', () async {
      final falha = await falhaCom(409, 'consentimento_ausente');
      expect(falha, isA<SemConsentimentoNoServidor>());
      expect(
        PoliticaDeReenvio.depoisDe(falha),
        SituacaoDoEnvio.semConsentimento,
      );
    });

    test('id reaproveitado, arquivo grande demais ou formato recusado: '
        'ninguém tenta de novo sozinho', () async {
      for (final (status, codigo) in [
        (409, 'id_ja_existe'),
        (413, 'arquivo_grande_demais'),
        (415, 'formato_nao_suportado'),
        (422, 'nao_e_mono'),
      ]) {
        final falha = await falhaCom(status, codigo);
        expect(falha, isA<FalhaDeValidacao>(), reason: codigo);
        expect(PoliticaDeReenvio.depoisDe(falha), SituacaoDoEnvio.recusado);
      }
    });

    test('Storage ou banco fora do ar: tenta de novo depois', () async {
      final falha = await falhaCom(503, 'armazenamento_indisponivel');
      expect(falha, isA<FalhaNoServidor>());
      expect(
        PoliticaDeReenvio.depoisDe(falha),
        SituacaoDoEnvio.aguardandoNovaTentativa,
      );
    });
  });
}

/// Pede o cancelamento no meio da sincronização — como sair da conta
/// enquanto o paciente sobe para o Firebase.
class _CancelaAoSincronizar implements Sincronizacao {
  _CancelaAoSincronizar(this.ordem, this.cancelamento);

  final List<String> ordem;
  final Cancelamento cancelamento;

  @override
  Future<void> prepararEnvio(ItemDaFila item) async {
    ordem.add('sincronizou');
    cancelamento.pedir();
  }
}
