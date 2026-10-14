import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/core/firestore/firestore_rest.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/cape_v/data/cape_v_no_firestore.dart';
import 'package:fonar_app/features/cape_v/data/repositorio_cape_v_local.dart';
import 'package:fonar_app/features/cape_v/domain/avaliacao_cape_v.dart';
import 'package:fonar_app/features/consentimento/data/repositorio_consentimento_local.dart';
import 'package:fonar_app/features/consentimento/domain/consentimento.dart';
import 'package:fonar_app/features/laudo/data/repositorio_laudos_local.dart';
import 'package:fonar_app/features/pacientes/data/repositorio_pacientes_local.dart';
import 'package:fonar_app/features/pacientes/domain/novo_paciente.dart';
import 'package:fonar_app/features/sincronizacao/data/descida_firestore.dart';
import 'package:fonar_app/features/sincronizacao/data/sincronizacao_firestore.dart';

import '../../apoio/banco_em_memoria.dart';
import '../../apoio/http_falso.dart';

const _conta = 'uid-de-teste';
const _outraConta = 'uid-de-outra-conta';
const _paciente = '0f8b7e5c-3c1a-4d2e-9f00-1a2b3c4d5e6f';
const _sessao = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const _base = 'profissionais/$_conta/pacientes';

/// O Firestore da conta, na memória: coleção → documentos.
class _FirestoreFalso implements FirestoreRest {
  final colecoes = <String, Map<String, Map<String, Object?>>>{};

  void por(String caminho, Map<String, Object?> campos) {
    final i = caminho.lastIndexOf('/');
    (colecoes[caminho.substring(0, i)] ??= {})[caminho.substring(i + 1)] =
        campos;
  }

  @override
  Future<Map<String, Object?>?> ler(String caminho) async {
    final i = caminho.lastIndexOf('/');
    return colecoes[caminho.substring(0, i)]?[caminho.substring(i + 1)];
  }

  @override
  Future<List<({String id, Map<String, Object?> campos})>> listar(
    String caminho,
  ) async => [
    for (final MapEntry(:key, :value) in (colecoes[caminho] ?? {}).entries)
      (id: key, campos: value),
  ];

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('a descida não grava no Firestore');
}

Map<String, Object?> _pacienteRemoto({
  String nome = 'Ana de Teste',
  String queixa = 'rouquidão (teste)',
}) => {
  'nome': nome,
  'data_nascimento': DateTime.utc(1990, 6, 15),
  'sexo_referencia': 'feminino',
  'queixa_principal': queixa,
  'criado_em': DateTime.utc(2026, 10, 1, 12),
};

Map<String, Object?> _registro(
  int seq,
  String tipo, {
  String declarante = 'paciente',
}) => {
  'seq': seq,
  'tipo': tipo,
  'data': DateTime.utc(2026, 10, seq, 9),
  'versao_termo': versaoAtualDoTermo,
  'declarante': declarante,
  if (declarante == 'responsavel_legal') 'nome_responsavel': 'Maria de Teste',
};

void main() {
  late BancoLocal banco;
  late _FirestoreFalso firestore;
  late AdaptadorFalso api;
  late DescidaDoFirestore descida;
  var agora = DateTime(2026, 10, 14, 10);

  setUp(() {
    agora = DateTime(2026, 10, 14, 10);
    banco = bancoEmMemoria();
    firestore = _FirestoreFalso();
    api = AdaptadorFalso([]);
    descida = DescidaDoFirestore(
      firestore,
      Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = api
        ..interceptors.add(const ErrorInterceptor()),
      banco,
      agora: () => agora,
    );
  });
  tearDown(() => banco.close());

  RepositorioPacientesLocal pacientes({String conta = _conta}) =>
      RepositorioPacientesLocal(banco, agora: () => agora, conta: () => conta);

  group('pacientes', () {
    test('o cadastrado noutro aparelho desce, da conta', () async {
      firestore.por('$_base/$_paciente', _pacienteRemoto());

      expect(await descida.descerConta(_conta), 1);

      final [paciente] = await pacientes().listar();
      expect(paciente.id, _paciente);
      expect(paciente.nome, 'Ana de Teste');
      expect(paciente.sexo, SexoDeReferencia.feminino);
      expect(paciente.dataDeNascimento, DateTime(1990, 6, 15));
      // E não aparece para outra conta deste aparelho.
      expect(await pacientes(conta: _outraConta).listar(), isEmpty);
    });

    test('descer de novo não muda nada', () async {
      firestore.por('$_base/$_paciente', _pacienteRemoto());
      await descida.descerConta(_conta);
      expect(await descida.descerConta(_conta), 0);
    });

    test('a correção feita noutro aparelho desce', () async {
      firestore.por('$_base/$_paciente', _pacienteRemoto());
      await descida.descerConta(_conta);
      agora = agora.add(const Duration(minutes: 5));
      firestore.por('$_base/$_paciente', _pacienteRemoto(nome: 'Ana Souza'));

      expect(await descida.descerConta(_conta), 1);
      expect((await pacientes().listar()).single.nome, 'Ana Souza');
    });

    test('a correção daqui que não subiu não é sobrescrita', () async {
      firestore.por('$_base/$_paciente', _pacienteRemoto());
      await descida.descerConta(_conta);
      final [ana] = await pacientes().listar();
      agora = agora.add(const Duration(minutes: 5));
      await pacientes().atualizar(
        ana.id,
        (validarCadastro(
          nome: 'Ana Corrigida',
          nascimento: '15/06/1990',
          sexo: SexoDeReferencia.feminino,
          queixa: 'rouquidão (teste)',
          hoje: DateTime(2026, 10, 14),
        ) as CadastroValido).paciente,
      );
      firestore.por('$_base/$_paciente', _pacienteRemoto(nome: 'Ana Velha'));

      await descida.descerConta(_conta);
      expect((await pacientes().listar()).single.nome, 'Ana Corrigida');
    });

    test('documento incompleto fica de fora', () async {
      firestore.por('$_base/$_paciente', {'nome': 'Sem nascimento'});
      expect(await descida.descerConta(_conta), 0);
      expect(await pacientes().listar(), isEmpty);
    });
  });

  group('livro de consentimentos', () {
    Future<void> comPaciente(List<Map<String, Object?>> livro) async {
      firestore.por('$_base/$_paciente', _pacienteRemoto());
      for (final r in livro) {
        firestore.por('$_base/$_paciente/consentimentos/${r['seq']}', r);
      }
    }

    RepositorioConsentimentoLocal consentimentos() =>
        RepositorioConsentimentoLocal(banco, agora: () => agora);

    test('o consentimento dado noutro aparelho desce e libera aqui', () async {
      await comPaciente([
        _registro(1, 'concessao', declarante: 'responsavel_legal'),
      ]);

      await descida.descerConta(_conta);

      final consentimento = await consentimentos().buscar(_paciente);
      expect(consentimento, isNotNull);
      expect(consentimento!.nomeDoResponsavel, 'Maria de Teste');
    });

    test('a retirada feita noutro aparelho passa a valer aqui', () async {
      await comPaciente([_registro(1, 'concessao')]);
      await descida.descerConta(_conta);
      expect(await consentimentos().buscar(_paciente), isNotNull);

      firestore.por(
        '$_base/$_paciente/consentimentos/2',
        _registro(2, 'retirada'),
      );
      await descida.descerConta(_conta);

      expect(await consentimentos().buscar(_paciente), isNull);
      expect(await consentimentos().retiradaEmVigor(_paciente), isNotNull);
      // E o livro daqui fica igual ao de lá: a subida não acha diferença.
      final livro = await livroDeConsentimentoLocal(banco, _paciente);
      expect([for (final r in livro) r.tipo], ['concessao', 'retirada']);
    });

    test('livro daqui à frente: nada desce, a subida resolve', () async {
      await comPaciente([_registro(1, 'concessao')]);
      await descida.descerConta(_conta);
      await consentimentos().retirar(
        _paciente,
        (validarRetirada(
          quemPediu: QuemAutoriza.paciente,
          nomeDoResponsavel: '',
        ) as RetiradaValida).pedido,
      );
      expect(await descida.descerConta(_conta), 0);
    });
  });

  group('registrosQueFaltam', () {
    RegistroDoLivro local(String tipo) => RegistroDoLivro(
      tipo: tipo,
      data: DateTime.utc(2026, 10, 1),
      versaoDoTermo: versaoAtualDoTermo,
      quem: 'paciente',
      nome: null,
    );

    test('divergentes: nada', () {
      expect(
        registrosQueFaltam(
          [local('concessao')],
          [
            {..._registro(1, 'concessao'), 'versao_termo': 'outra'},
            _registro(2, 'retirada'),
          ],
        ),
        isEmpty,
      );
    });

    test('buraco na sequência ou retirada sem concessão: nada', () {
      expect(registrosQueFaltam([], [_registro(2, 'concessao')]), isEmpty);
      expect(registrosQueFaltam([], [_registro(1, 'retirada')]), isEmpty);
    });
  });

  group('perfil do paciente: CAPE-V e laudos', () {
    final notas = {
      for (final p in ParametroCapeV.values)
        p: p == ParametroCapeV.grauGeral
            ? const NotaCapeV(valor: 32, consistencia: Consistencia.consistente)
            : const NotaCapeV(valor: 0),
    };

    setUp(() {
      firestore.por('$_base/$_paciente', _pacienteRemoto());
      firestore.por('$_base/$_paciente/sessoes/$_sessao', {
        'estado': 'concluida',
      });
    });

    test('a CAPE-V registrada noutro aparelho desce', () async {
      firestore.por(
        '$_base/$_paciente/sessoes/$_sessao/avaliacoes/cape_v',
        camposDaCapeV(
          AvaliacaoCapeV(
            analiseId: _sessao,
            pacienteId: _paciente,
            notas: notas,
            registradaEm: DateTime.utc(2026, 10, 13, 15),
            comentarios: 'comentário de teste',
          ),
        ),
      );
      api.respostas.add(const RespostaFalsa(404, {'detail': 'Not Found'}));

      expect(await descida.descerPaciente(_conta, _paciente), 1);

      final capeV = await RepositorioCapeVLocal(banco).daAnalise(_sessao);
      expect(capeV!.comentarios, 'comentário de teste');
      expect(capeV.notas[ParametroCapeV.grauGeral]!.valor, 32);
    });

    test('a CAPE-V daqui, mais nova, fica', () async {
      firestore.por(
        '$_base/$_paciente/sessoes/$_sessao/avaliacoes/cape_v',
        camposDaCapeV(
          AvaliacaoCapeV(
            analiseId: _sessao,
            pacienteId: _paciente,
            notas: notas,
            registradaEm: DateTime.utc(2026, 10, 13, 15),
            comentarios: 'a de lá',
          ),
        ),
      );
      await RepositorioCapeVLocal(banco).registrar(
        AvaliacaoCapeV(
          analiseId: _sessao,
          pacienteId: _paciente,
          notas: notas,
          registradaEm: DateTime.utc(2026, 10, 14, 9),
          comentarios: 'a daqui',
        ),
      );
      api.respostas.add(const RespostaFalsa(200, []));

      expect(await descida.descerPaciente(_conta, _paciente), 0);
      final capeV = await RepositorioCapeVLocal(banco).daAnalise(_sessao);
      expect(capeV!.comentarios, 'a daqui');
    });

    test('o laudo emitido noutro aparelho desce, com o PDF', () async {
      final pdf = '%PDF-1.4 teste'.codeUnits;
      api.respostas.addAll([
        RespostaFalsa(200, [
          {
            'id': 'b7c1f9e2-0000-4000-8000-000000000001',
            'gerado_em': '2026-10-13T15:00:00Z',
            'registrado_em': '2026-10-13T15:00:05Z',
            'conclusao': 'Conclusão de teste.',
            'sha256': 'x' * 64,
            'tamanho_bytes': pdf.length,
            'substitui': null,
          },
        ]),
        RespostaFalsa.bytes(200, pdf, 'application/pdf'),
      ]);

      expect(await descida.descerPaciente(_conta, _paciente), 1);

      final [laudo] = await RepositorioLaudosLocal(banco)
          .emitidosDaAnalise(_sessao);
      expect(laudo.codigo, 'B7C1F9E2');
      expect(laudo.pdf, pdf);
      expect(laudo.enviadoEm, isNotNull);
      expect(
        api.feitas.last.uri.path,
        '/v1/pacientes/$_paciente/sessoes/$_sessao/laudos/'
        'b7c1f9e2-0000-4000-8000-000000000001/pdf',
      );
    });

    test('PDF cortado no caminho não é guardado', () async {
      api.respostas.addAll([
        const RespostaFalsa(200, [
          {
            'id': 'b7c1f9e2-0000-4000-8000-000000000002',
            'gerado_em': '2026-10-13T15:00:00Z',
            'conclusao': 'x',
            'tamanho_bytes': 999,
          },
        ]),
        RespostaFalsa.bytes(200, '%PDF-'.codeUnits, 'application/pdf'),
      ]);

      expect(await descida.descerPaciente(_conta, _paciente), 0);
      expect(
        await RepositorioLaudosLocal(banco).emitidosDaAnalise(_sessao),
        isEmpty,
      );
    });
  });

  group('donos dos pacientes de antes da US40', () {
    test('o de quem gravou; os outros, de quem entra', () async {
      for (final id in ['p1', 'p2']) {
        await banco
            .into(banco.pacientes)
            .insert(
              PacientesCompanion.insert(
                id: id,
                nome: 'Paciente $id de Teste',
                queixa: '',
                cadastradoEm: DateTime(2026, 9, 1),
              ),
            );
      }
      await banco
          .into(banco.envios)
          .insert(
            EnviosCompanion.insert(
              id: 'envio-1',
              pacienteId: 'p1',
              nomeDoPaciente: 'Paciente p1 de Teste',
              sessaoId: 's1',
              criadoEm: DateTime(2026, 9, 2),
              situacao: 'enviado',
              tentativas: 0,
              profissionalId: const Value(_outraConta),
            ),
          );

      expect(await adotarPacientesSemDono(banco, _conta), 2);

      expect([for (final p in await pacientes().listar()) p.id], ['p2']);
      expect(
        [for (final p in await pacientes(conta: _outraConta).listar()) p.id],
        ['p1'],
      );
    });
  });
}
