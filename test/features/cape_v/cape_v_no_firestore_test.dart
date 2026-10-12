import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/firestore/firestore_rest.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/cape_v/data/cape_v_no_firestore.dart';
import 'package:fonar_app/features/cape_v/data/repositorio_cape_v_local.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/http_falso.dart';

const _uid = 'uid-de-teste';
const _paciente = '0f8b7e5c-3c1a-4d2e-9f00-1a2b3c4d5e6f';
const _sessao = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const _outraSessao = '3d6f4a2b-1c5e-4f7a-8b9c-0d1e2f3a4b5c';
const _documentos = 'projects/demo/databases/(default)/documents';

String _caminho(String sessao) =>
    'profissionais/$_uid/pacientes/$_paciente/sessoes/$sessao'
    '/avaliacoes/cape_v';

const _naoExiste = RespostaFalsa(404, {
  'error': {'code': 404, 'status': 'NOT_FOUND'},
});
const _ok = RespostaFalsa(200, {});
const _negado = RespostaFalsa(403, {
  'error': {'code': 403, 'status': 'PERMISSION_DENIED'},
});

final _registradaEm = DateTime.utc(2026, 10, 12, 14, 30, 5, 250);

/// Com desvio e sem, e com o sentido em pitch.
const _notas = {
  ParametroCapeV.grauGeral: NotaCapeV(
    valor: 35,
    consistencia: Consistencia.consistente,
  ),
  ParametroCapeV.rugosidade: NotaCapeV(
    valor: 20,
    consistencia: Consistencia.intermitente,
  ),
  ParametroCapeV.soprosidade: NotaCapeV(valor: 0),
  ParametroCapeV.tensao: NotaCapeV(
    valor: 10,
    consistencia: Consistencia.consistente,
  ),
  ParametroCapeV.pitch: NotaCapeV(
    valor: 15,
    consistencia: Consistencia.intermitente,
    direcao: DirecaoDoDesvio.abaixo,
  ),
  ParametroCapeV.loudness: NotaCapeV(valor: 0),
};

class _Montagem {
  _Montagem(this.banco, this.servidor)
    : sincronizacao = CapeVNoFirestore(
        FirestoreRest(
          Dio(
              BaseOptions(
                baseUrl: 'https://firestore.googleapis.com/v1/',
                contentType: Headers.jsonContentType,
              ),
            )
            ..httpClientAdapter = servidor
            ..interceptors.add(const ErrorInterceptor()),
          projeto: 'demo',
        ),
        banco,
        uid: () => _uid,
      );

  final BancoLocal banco;
  final AdaptadorFalso servidor;
  final CapeVNoFirestore sincronizacao;

  /// As escritas feitas, na ordem: a de cada commit.
  List<Map<String, Object?>> get escritas => [
    for (final pedido in servidor.feitas)
      if (pedido.opcoes.method == 'POST')
        (pedido.json['writes'] as List).single as Map<String, Object?>,
  ];

  /// Os documentos lidos, na ordem.
  List<String> get lidos => [
    for (final pedido in servidor.feitas)
      if (pedido.opcoes.method == 'GET')
        pedido.uri.path.replaceFirst('/v1/$_documentos/', ''),
  ];

  Future<void> registrar({
    String sessao = _sessao,
    DateTime? em,
    Map<ParametroCapeV, NotaCapeV> notas = _notas,
    String comentarios = 'voz rugosa no fim das frases (teste)',
  }) => RepositorioCapeVLocal(banco).registrar(
    AvaliacaoCapeV(
      analiseId: sessao,
      pacienteId: _paciente,
      notas: notas,
      registradaEm: em ?? _registradaEm,
      comentarios: comentarios,
    ),
  );

  Future<void> enviada({
    String sessao = _sessao,
    String? por = _uid,
    SituacaoDoEnvio situacao = SituacaoDoEnvio.enviado,
  }) => RepositorioFilaLocal(banco).adicionar(
    ItemDaFila(
      id: 'envio-$sessao',
      pacienteId: _paciente,
      nomeDoPaciente: 'Ana de Teste',
      sessaoId: sessao,
      amostras: const [],
      criadoEm: _registradaEm,
      situacao: situacao,
      analiseId: sessao,
      profissionalId: por,
    ),
  );
}

_Montagem _montar(List<RespostaFalsa> respostas) {
  final banco = bancoEmMemoria();
  addTearDown(banco.close);
  return _Montagem(banco, AdaptadorFalso(respostas));
}

/// O documento como o Firestore devolve, com a [avaliadaEm] dada.
RespostaFalsa _documento(String sessao, DateTime avaliadaEm) =>
    RespostaFalsa(200, {
      'name': '$_documentos/${_caminho(sessao)}',
      'fields': codificar({
        'notas': <String, Object?>{},
        'comentarios': '',
        'avaliada_em': avaliadaEm,
      }),
    });

void main() {
  test('nada no Firebase: cria no formato das regras, com a hora do '
      'servidor', () async {
    final m = _montar([_naoExiste, _ok]);
    await m.registrar();
    await m.enviada();

    expect(await m.sincronizacao.sincronizar(), 1);

    expect(m.lidos, [_caminho(_sessao)]);
    final escrita = m.escritas.single;
    final update = escrita['update'] as Map<String, Object?>;
    expect(update['name'], '$_documentos/${_caminho(_sessao)}');
    final campos = {
      for (final MapEntry(:key, :value)
          in (update['fields'] as Map<String, Object?>).entries)
        key: decodificarValor(value),
    };
    expect(campos, {
      'notas': {
        'grau_geral': {'valor': 35, 'consistencia': 'consistente'},
        'rugosidade': {'valor': 20, 'consistencia': 'intermitente'},
        // Sem desvio, só o valor: as regras recusam consistência e sentido.
        'soprosidade': {'valor': 0},
        'tensao': {'valor': 10, 'consistencia': 'consistente'},
        'pitch': {
          'valor': 15,
          'consistencia': 'intermitente',
          'direcao': 'abaixo',
        },
        'loudness': {'valor': 0},
      },
      'comentarios': 'voz rugosa no fim das frases (teste)',
      'avaliada_em': _registradaEm,
    });
    expect(escrita['currentDocument'], {'exists': false});
    expect(escrita['updateTransforms'], [
      {'fieldPath': 'criado_em', 'setToServerValue': 'REQUEST_TIME'},
      {'fieldPath': 'atualizado_em', 'setToServerValue': 'REQUEST_TIME'},
    ]);
  });

  test('a de lá é a mesma: não grava, e na vez seguinte nem lê', () async {
    final m = _montar([_documento(_sessao, _registradaEm)]);
    await m.registrar();
    await m.enviada();

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(await m.sincronizacao.sincronizar(), 0);

    expect(m.lidos, hasLength(1));
    expect(m.escritas, isEmpty);
  });

  test('a de lá é mais antiga: substitui, sem tocar em criado_em', () async {
    final antes = _registradaEm.subtract(const Duration(days: 1));
    final m = _montar([_documento(_sessao, antes), _ok]);
    await m.registrar();
    await m.enviada();

    expect(await m.sincronizacao.sincronizar(), 1);

    final escrita = m.escritas.single;
    expect(escrita['currentDocument'], {'exists': true});
    expect(escrita['updateMask'], {
      'fieldPaths': ['notas', 'comentarios', 'avaliada_em'],
    });
    expect(escrita['updateTransforms'], [
      {'fieldPath': 'atualizado_em', 'setToServerValue': 'REQUEST_TIME'},
    ]);
  });

  test('a de lá é mais nova (outro aparelho registrou depois): fica', () async {
    final depois = _registradaEm.add(const Duration(minutes: 5));
    final m = _montar([_documento(_sessao, depois)]);
    await m.registrar();
    await m.enviada();

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(m.escritas, isEmpty);
  });

  test('registrada de novo aqui, sobe de novo', () async {
    final m = _montar([_naoExiste, _ok]);
    await m.registrar();
    await m.enviada();
    await m.sincronizacao.sincronizar();

    final nova = _registradaEm.add(const Duration(hours: 1));
    await m.registrar(em: nova);
    m.servidor.respostas.addAll([_documento(_sessao, _registradaEm), _ok]);
    expect(await m.sincronizacao.sincronizar(), 1);
    expect(m.escritas.last['currentDocument'], {'exists': true});
  });

  test('só a de sessão ENVIADA pela conta: nenhuma outra é nem lida', () async {
    final m = _montar([]);
    // Enviada por outra conta: a sessão está na árvore dela.
    await m.registrar();
    await m.enviada(por: 'uid-de-outra');
    // Ainda na fila: a sessão pode nem ter subido.
    await m.registrar(sessao: _outraSessao);
    await m.enviada(sessao: _outraSessao, situacao: SituacaoDoEnvio.naFila);
    // Sem envio nenhum (análise de exemplo).
    await m.registrar(sessao: 'an-exemplo');

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(m.servidor.feitas, isEmpty);
  });

  test('envio de antes da US32, sem dono, não sobe', () async {
    final m = _montar([]);
    await m.registrar();
    await m.enviada(por: null);

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(m.servidor.feitas, isEmpty);
  });

  test('falha numa não impede a outra, e a que falhou tenta de novo', () async {
    final m = _montar([_negado, _naoExiste, _ok]);
    final primeira = _registradaEm.subtract(const Duration(days: 1));
    await m.registrar(em: primeira);
    await m.enviada();
    await m.registrar(sessao: _outraSessao);
    await m.enviada(sessao: _outraSessao);

    await expectLater(m.sincronizacao.sincronizar(), throwsA(isA<Proibido>()));
    expect(m.lidos, [_caminho(_sessao), _caminho(_outraSessao)]);
    expect(
      (m.escritas.single['update'] as Map)['name'],
      '$_documentos/${_caminho(_outraSessao)}',
    );

    // Na próxima vez, só a que falhou.
    m.servidor.respostas.addAll([_naoExiste, _ok]);
    expect(await m.sincronizacao.sincronizar(), 1);
    expect(m.lidos.skip(2), [_caminho(_sessao)]);
  });

  test('a que as regras recusariam não sobe nem tenta', () async {
    final m = _montar([]);
    // Sem um dos parâmetros: de antes de uma conferência nova, digamos.
    await m.registrar(notas: {..._notas}..remove(ParametroCapeV.tensao));
    await m.enviada();
    await m.registrar(sessao: _outraSessao, comentarios: 'x' * 2001);
    await m.enviada(sessao: _outraSessao);

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(m.servidor.feitas, isEmpty);
  });

  test('sem conta na sessão, nada', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final sincronizacao = CapeVNoFirestore(
      FirestoreRest(Dio(), projeto: 'demo'),
      banco,
      uid: () => null,
    );
    await expectLater(
      sincronizacao.sincronizar(),
      throwsA(isA<NaoAutorizado>()),
    );
  });
}
