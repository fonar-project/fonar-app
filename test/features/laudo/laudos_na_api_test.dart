import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/error/app_exception.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/fila/data/repositorio_fila_local.dart';
import 'package:fonar_app/features/fila/domain/item_da_fila.dart';
import 'package:fonar_app/features/laudo/data/laudos_na_api.dart';
import 'package:fonar_app/features/laudo/data/repositorio_laudos_local.dart';
import 'package:fonar_app/features/laudo/domain/laudo.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/http_falso.dart';

const _uid = 'uid-de-teste';
const _paciente = '0f8b7e5c-3c1a-4d2e-9f00-1a2b3c4d5e6f';
const _sessao = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const _outraSessao = '3d6f4a2b-1c5e-4f7a-8b9c-0d1e2f3a4b5c';
const _primeiro = 'aaaaaaaa-0000-4000-8000-000000000001';
const _segundo = 'bbbbbbbb-0000-4000-8000-000000000002';

const _ok = RespostaFalsa(201, {});
const _recusa = RespostaFalsa(415, {
  'detail': {'codigo': 'formato_nao_suportado', 'mensagem': 'não é PDF'},
});

final _emitidoEm = DateTime.utc(2026, 10, 13, 18, 30);
final _agora = DateTime.utc(2026, 10, 13, 19);

class _Montagem {
  _Montagem(this.banco, this.servidor)
    : sincronizacao = LaudosNaApi(
        Dio(BaseOptions(baseUrl: 'https://api.teste'))
          ..httpClientAdapter = servidor
          ..interceptors.add(const ErrorInterceptor()),
        banco,
        uid: () => _uid,
        agora: () => _agora,
      );

  final BancoLocal banco;
  final AdaptadorFalso servidor;
  final LaudosNaApi sincronizacao;

  RepositorioLaudosLocal get laudos => RepositorioLaudosLocal(banco);

  /// O formulário de cada envio, na ordem.
  List<FormData> get envios => [
    for (final pedido in servidor.feitas) pedido.opcoes.data as FormData,
  ];

  Future<void> emitir(
    String id, {
    String sessao = _sessao,
    DateTime? em,
    String? substitui,
  }) => laudos.registrar(
    Laudo(
      id: id,
      analiseId: sessao,
      pacienteId: _paciente,
      conclusao: 'Conclusão da profissional (teste).',
      geradoEm: em ?? _emitidoEm,
      pdf: Uint8List.fromList(utf8.encode('%PDF-teste $id')),
      substitui: substitui,
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
      criadoEm: _emitidoEm,
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

Map<String, String> _campos(FormData f) => {
  for (final MapEntry(:key, :value) in f.fields) key: value,
};

void main() {
  test('sobe o PDF como foi emitido, com o código, e marca enviado', () async {
    final m = _montar([_ok]);
    await m.emitir(_primeiro);
    await m.enviada();

    expect(await m.sincronizacao.sincronizar(), 1);

    final pedido = m.servidor.feitas.single;
    expect(pedido.opcoes.method, 'POST');
    expect(pedido.uri.path, '/v1/pacientes/$_paciente/sessoes/$_sessao/laudos');
    final envio = m.envios.single;
    expect(_campos(envio), {
      'laudo_id': _primeiro,
      // Com o fuso: a API recusa data sem ele.
      'gerado_em': '2026-10-13T18:30:00.000Z',
      'conclusao': 'Conclusão da profissional (teste).',
    });
    final arquivo = envio.files.single;
    expect(arquivo.key, 'arquivo');
    expect(arquivo.value.contentType?.mimeType, 'application/pdf');
    expect(pedido.corpo, contains('%PDF-teste $_primeiro'));

    expect((await m.laudos.daAnalise(_sessao))!.enviadoEm, _agora);
  });

  test('do mais antigo ao mais recente, e o novo diz qual substitui', () async {
    final m = _montar([_ok, _ok]);
    await m.emitir(
      _segundo,
      em: _emitidoEm.add(const Duration(hours: 1)),
      substitui: _primeiro,
    );
    await m.emitir(_primeiro);
    await m.enviada();

    expect(await m.sincronizacao.sincronizar(), 2);

    expect(
      [for (final e in m.envios) _campos(e)['laudo_id']],
      [_primeiro, _segundo],
    );
    expect(_campos(m.envios.first).containsKey('substitui'), isFalse);
    expect(_campos(m.envios.last)['substitui'], _primeiro);
  });

  test('o que já subiu não sobe de novo', () async {
    final m = _montar([_ok]);
    await m.emitir(_primeiro);
    await m.enviada();
    await m.sincronizacao.sincronizar();

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(m.servidor.feitas, hasLength(1));
  });

  test('só o de sessão ENVIADA pela conta: nenhum outro nem sai', () async {
    final m = _montar([]);
    // Enviada por outra conta: a sessão está na árvore dela.
    await m.emitir(_primeiro);
    await m.enviada(por: 'uid-de-outra');
    // Ainda na fila: a sessão pode nem ter subido.
    await m.emitir(_segundo, sessao: _outraSessao);
    await m.enviada(sessao: _outraSessao, situacao: SituacaoDoEnvio.naFila);

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(m.servidor.feitas, isEmpty);
  });

  test('sem rede: lança, e nada fica marcado', () async {
    final m = _montar([const RespostaFalsa.semRede()]);
    await m.emitir(_primeiro);
    await m.enviada();

    await expectLater(
      m.sincronizacao.sincronizar(),
      throwsA(isA<FalhaDeConexao>()),
    );
    expect((await m.laudos.daAnalise(_sessao))!.enviadoEm, isNull);

    // Na próxima ocasião, sobe.
    m.servidor.respostas.add(_ok);
    expect(await m.sincronizacao.sincronizar(), 1);
  });

  test('recusa pelo conteúdo não se repete nesta abertura, e não trava os '
      'outros', () async {
    final m = _montar([_recusa, _ok]);
    await m.emitir(_primeiro);
    await m.enviada();
    await m.emitir(_segundo, sessao: _outraSessao);
    await m.enviada(sessao: _outraSessao);

    await expectLater(
      m.sincronizacao.sincronizar(),
      throwsA(isA<FalhaDeValidacao>()),
    );
    expect((await m.laudos.daAnalise(_outraSessao))!.enviadoEm, _agora);

    expect(await m.sincronizacao.sincronizar(), 0);
    expect(m.servidor.feitas, hasLength(2));
  });

  test('sem conta na sessão, nada', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final sincronizacao = LaudosNaApi(
      Dio(),
      banco,
      uid: () => null,
      agora: () => _agora,
    );
    await expectLater(
      sincronizacao.sincronizar(),
      throwsA(isA<NaoAutorizado>()),
    );
  });
}
