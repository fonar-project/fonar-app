import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/banco/conversao.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/firestore/firestore_rest.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/relogio.dart';
import '../../cape_v/data/cape_v_no_firestore.dart';
import '../../cape_v/data/repositorio_cape_v_local.dart';
import '../../cape_v/domain/avaliacao_cape_v.dart';
import '../../consentimento/domain/consentimento.dart';
import '../../laudo/data/repositorio_laudos_local.dart';
import '../../laudo/domain/laudo.dart';
import '../../pacientes/domain/novo_paciente.dart';
import 'sincronizacao_firestore.dart';

/// A descida, ou `null` no modo de exemplo: sem a API de verdade, não há
/// Firebase de onde descer.
final descidaProvider = Provider<DescidaDoFirestore?>(
  (ref) => AppConfig.apiConfigurada
      ? DescidaDoFirestore(
          ref.watch(firestoreRestProvider),
          ref.watch(dioProvider),
          ref.watch(bancoLocalProvider),
          agora: ref.watch(relogioProvider),
        )
      : null,
);

/// Traz para o banco local o que a conta tem no Firebase e não está aqui
/// (US40): o que outro aparelho cadastrou, registrou ou emitiu.
///
/// O banco local continua sendo de onde o app lê. A descida só ACRESCENTA ou
/// ATUALIZA o que o aparelho não mudou por conta própria — nunca apaga, e
/// nunca passa por cima de uma mudança daqui que ainda não subiu:
///
/// - **Paciente**: o que falta entra; o que existe é atualizado só se não
///   tiver correção daqui por subir (`Pacientes.alteradoEm`).
/// - **Livro de consentimentos**: o do Firebase é a referência. Se o daqui é
///   o começo dele, o resto entra, na ordem; uma retirada registrada noutro
///   aparelho passa a valer aqui também. Se o daqui tem registro que o de lá
///   não tem, quem resolve é a subida (no envio); se os dois divergem, nada
///   muda, e o envio recusa para alguém olhar.
/// - **CAPE-V**: a mais recente vence, dos dois lados (`avaliada_em`).
/// - **Laudo**: o que falta desce, com o PDF como foi emitido, conferido
///   pelo tamanho. Laudo nunca muda, então não há o que atualizar.
///
/// Pacientes e livros descem para a conta inteira ([descerConta]); CAPE-V e
/// laudos, paciente a paciente, quando o perfil dele abre ([descerPaciente])
/// — são várias leituras por sessão, e a maioria dos pacientes não é aberta
/// num dia.
class DescidaDoFirestore {
  DescidaDoFirestore(
    this._firestore,
    this._dio,
    this._banco, {
    required DateTime Function() agora,
  }) : _agora = agora;

  final FirestoreRest _firestore;
  final Dio _dio;
  final BancoLocal _banco;
  final DateTime Function() _agora;

  /// Os pacientes da [conta] e o livro de consentimentos de cada um.
  /// Devolve quantos registros mudaram aqui.
  ///
  /// Lança só `AppException`.
  Future<int> descerConta(String conta) async {
    final remotos = await _firestore.listar('profissionais/$conta/pacientes');
    var mudaram = 0;
    AppException? primeiraFalha;
    for (final (:id, :campos) in remotos) {
      try {
        if (await _paciente(conta, id, campos)) mudaram++;
        mudaram += await _livro(conta, id);
      } on AppException catch (falha) {
        // Os outros seguem; este desce na próxima vez.
        primeiraFalha ??= falha;
      } catch (erro) {
        primeiraFalha ??= FalhaDesconhecida(causa: erro);
      }
    }
    if (primeiraFalha != null) throw primeiraFalha;
    return mudaram;
  }

  /// As CAPE-V e os laudos das sessões de um paciente da [conta]. Devolve
  /// quantos registros mudaram aqui.
  ///
  /// Lança só `AppException`.
  Future<int> descerPaciente(String conta, String pacienteId) async {
    final base = 'profissionais/$conta/pacientes/$pacienteId';
    final sessoes = await _firestore.listar('$base/sessoes');
    var mudaram = 0;
    for (final (id: sessaoId, campos: _) in sessoes) {
      if (await _capeV('$base/sessoes/$sessaoId', pacienteId, sessaoId)) {
        mudaram++;
      }
      mudaram += await _laudos(pacienteId, sessaoId);
    }
    return mudaram;
  }

  // --------------------------------------------------------- paciente --

  Future<bool> _paciente(
    String conta,
    String id,
    Map<String, Object?> campos,
  ) async {
    final dados = pacienteDoFirestore(campos);
    // Documento que não passa pelas regras de hoje não chega aqui; se
    // chegar incompleto, fica de fora em vez de virar cadastro pela metade.
    if (dados == null) return false;
    final local = await (_banco.select(
      _banco.pacientes,
    )..where((p) => p.id.equals(id))).getSingleOrNull();

    if (local == null) {
      await _banco
          .into(_banco.pacientes)
          .insert(
            PacientesCompanion.insert(
              id: id,
              nome: dados.nome,
              queixa: dados.queixa,
              sexo: Value(dados.sexo.name),
              dataDeNascimento: Value(dados.nascimento),
              cadastradoEm: dados.criadoEm ?? _agora(),
              profissionalId: Value(conta),
              sincronizadoEm: Value(_agora()),
            ),
          );
      return true;
    }
    // De outra conta, neste aparelho: não é desta descida.
    if (local.profissionalId != null && local.profissionalId != conta) {
      return false;
    }
    if (correcaoPorSubir(local)) return false;
    final igual =
        local.nome == dados.nome &&
        local.queixa == dados.queixa &&
        local.sexo == dados.sexo.name &&
        local.dataDeNascimento == dados.nascimento;
    if (igual) return false;
    await (_banco.update(
      _banco.pacientes,
    )..where((p) => p.id.equals(id))).write(
      PacientesCompanion(
        nome: Value(dados.nome),
        queixa: Value(dados.queixa),
        sexo: Value(dados.sexo.name),
        dataDeNascimento: Value(dados.nascimento),
        profissionalId: Value(conta),
        sincronizadoEm: Value(_agora()),
      ),
    );
    return true;
  }

  // ------------------------------------------------------------ livro --

  Future<int> _livro(String conta, String pacienteId) async {
    final remotos = await _firestore.listar(
      'profissionais/$conta/pacientes/$pacienteId/consentimentos',
    );
    final livro = [for (final r in remotos) r.campos]
      ..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));
    return _banco.transaction(() async {
      final locais = await livroDeConsentimentoLocal(_banco, pacienteId);
      final faltam = registrosQueFaltam(locais, livro);
      int? ultimaConcessao = [
        for (final r in locais)
          if (r.tipo == 'concessao') r.consentimentoId,
      ].lastOrNull;
      for (final registro in faltam) {
        final data = registro['data'] as DateTime;
        final quem = _quem(registro['declarante']);
        final nome = registro['nome_responsavel'] as String?;
        if (registro['tipo'] == 'concessao') {
          ultimaConcessao = await _banco
              .into(_banco.consentimentos)
              .insert(
                ConsentimentosCompanion.insert(
                  pacienteId: pacienteId,
                  registradoEm: data.toLocal(),
                  versaoDoTermo: registro['versao_termo'] as String,
                  quemAutoriza: quem.name,
                  nomeDoResponsavel: Value(nome),
                ),
              );
        } else {
          await _banco
              .into(_banco.retiradasDeConsentimento)
              .insert(
                RetiradasDeConsentimentoCompanion.insert(
                  pacienteId: pacienteId,
                  consentimentoId: Value(ultimaConcessao),
                  retiradaEm: data.toLocal(),
                  quemPediu: quem.name,
                  nomeDoResponsavel: Value(nome),
                ),
              );
        }
      }
      return faltam.length;
    });
  }

  static QuemAutoriza _quem(Object? declarante) =>
      declarante == 'responsavel_legal'
      ? QuemAutoriza.responsavelLegal
      : QuemAutoriza.paciente;

  // ----------------------------------------------------------- CAPE-V --

  Future<bool> _capeV(String sessao, String pacienteId, String sessaoId) async {
    final campos = await _firestore.ler('$sessao/avaliacoes/cape_v');
    if (campos == null) return false;
    final remota = capeVDoFirestore(campos, sessaoId, pacienteId);
    if (remota == null) return false;
    final repositorio = RepositorioCapeVLocal(_banco);
    final local = await repositorio.daAnalise(sessaoId);
    // A mais recente vence: a daqui, se for mais nova, sobe na próxima vez.
    if (local != null && !local.registradaEm.isBefore(remota.registradaEm)) {
      return false;
    }
    await repositorio.registrar(remota);
    return true;
  }

  // ----------------------------------------------------------- laudos --

  Future<int> _laudos(String pacienteId, String sessaoId) async {
    final rota = '/v1/pacientes/$pacienteId/sessoes/$sessaoId/laudos';
    final List<Object?> lista;
    try {
      final resposta = await _dio.get<Object?>(rota);
      lista = resposta.data is List ? resposta.data! as List : const [];
    } on DioException catch (e) {
      // Sessão sem laudo no servidor, ou servidor antes da US38.
      if (e.error is NaoEncontrado) return 0;
      throw e.error is AppException
          ? e.error! as AppException
          : FalhaDesconhecida(causa: e);
    }
    final repositorio = RepositorioLaudosLocal(_banco);
    final aqui = {
      for (final l in await repositorio.emitidosDaAnalise(sessaoId)) l.id,
    };
    var desceram = 0;
    for (final item in lista) {
      if (item is! Map) continue;
      final id = item['id'];
      if (id is! String || aqui.contains(id)) continue;
      final Uint8List pdf;
      try {
        final resposta = await _dio.get<List<int>>(
          '$rota/$id/pdf',
          options: Options(responseType: ResponseType.bytes),
        );
        pdf = Uint8List.fromList(resposta.data ?? const []);
      } on DioException catch (e) {
        throw e.error is AppException
            ? e.error! as AppException
            : FalhaDesconhecida(causa: e);
      }
      // O servidor confere o sha256 antes de entregar; aqui, o tamanho
      // basta para não guardar uma resposta cortada.
      if (pdf.length != item['tamanho_bytes']) continue;
      final geradoEm = DateTime.tryParse('${item['gerado_em']}')?.toLocal();
      await repositorio.registrar(
        Laudo(
          id: id,
          analiseId: sessaoId,
          pacienteId: pacienteId,
          conclusao: '${item['conclusao'] ?? ''}',
          geradoEm: geradoEm ?? _agora(),
          pdf: pdf,
          substitui: item['substitui'] as String?,
          // Veio de lá: já está no servidor.
          enviadoEm:
              DateTime.tryParse('${item['registrado_em']}')?.toLocal() ??
              _agora(),
        ),
      );
      desceram++;
    }
    return desceram;
  }
}

/// O paciente tem correção feita neste aparelho que ainda não subiu? Então o
/// que desce não passa por cima dela.
bool correcaoPorSubir(LinhaDoPaciente p) {
  final alterado = p.alteradoEm;
  if (alterado == null) return false;
  final sincronizado = p.sincronizadoEm;
  return sincronizado == null || alterado.isAfter(sincronizado);
}

/// Os dados de um paciente como o Firestore os guarda, ou `null` se faltar
/// o que as regras exigem.
({
  String nome,
  String queixa,
  SexoDeReferencia sexo,
  DateTime nascimento,
  DateTime? criadoEm,
})?
pacienteDoFirestore(Map<String, Object?> campos) {
  final nome = campos['nome'];
  final nascimento = campos['data_nascimento'];
  final sexo = switch (campos['sexo_referencia']) {
    'feminino' => SexoDeReferencia.feminino,
    'masculino' => SexoDeReferencia.masculino,
    'nao_informado' => SexoDeReferencia.naoInformado,
    _ => null,
  };
  if (nome is! String || nascimento is! DateTime || sexo == null) return null;
  final criado = campos['criado_em'];
  // Data sem hora: no Firestore é meia-noite UTC; aqui, o dia, como o
  // cadastro guarda.
  final dia = nascimento.toUtc();
  return (
    nome: nome,
    queixa: (campos['queixa_principal'] as String?) ?? '',
    sexo: sexo,
    nascimento: DateTime(dia.year, dia.month, dia.day),
    criadoEm: criado is DateTime ? criado.toLocal() : null,
  );
}

/// Os registros do livro do Firebase ([remoto], em ordem de `seq`) que faltam
/// no livro daqui ([local]) — vazio quando não falta nada, quando o daqui
/// está à frente (sobe no envio) ou quando os dois divergem.
List<Map<String, Object?>> registrosQueFaltam(
  List<RegistroDoLivro> local,
  List<Map<String, Object?>> remoto,
) {
  if (remoto.length <= local.length) return const [];
  for (var i = 0; i < local.length; i++) {
    final r = remoto[i];
    if (r['seq'] != i + 1 ||
        r['tipo'] != local[i].tipo ||
        r['versao_termo'] != local[i].versaoDoTermo) {
      return const [];
    }
  }
  final resto = remoto.sublist(local.length);
  // Sem buraco na sequência, e cada retirada logo depois de uma concessão.
  for (var i = 0; i < resto.length; i++) {
    final r = resto[i];
    if (r['seq'] != local.length + i + 1 || r['data'] is! DateTime) {
      return const [];
    }
    if (r['tipo'] == 'retirada') {
      final anterior = i == 0
          ? local.lastOrNull?.tipo
          : resto[i - 1]['tipo'] as String?;
      if (anterior != 'concessao') return const [];
    } else if (r['tipo'] != 'concessao' || r['versao_termo'] is! String) {
      return const [];
    }
  }
  return resto;
}

/// A CAPE-V como o Firestore a guarda (`camposDaCapeV`, ao contrário), ou
/// `null` se não for uma avaliação completa.
AvaliacaoCapeV? capeVDoFirestore(
  Map<String, Object?> campos,
  String sessaoId,
  String pacienteId,
) {
  final notas = campos['notas'];
  final avaliadaEm = campos['avaliada_em'];
  if (notas is! Map || avaliadaEm is! DateTime) return null;
  final convertidas = <ParametroCapeV, NotaCapeV>{};
  for (final parametro in ParametroCapeV.values) {
    final nota = notas[nomeNoFirestore(parametro)];
    if (nota is! Map || nota['valor'] is! int) return null;
    convertidas[parametro] = NotaCapeV(
      valor: nota['valor'] as int,
      consistencia: enumOuNulo(
        Consistencia.values,
        nota['consistencia'] as String?,
      ),
      direcao: enumOuNulo(DirecaoDoDesvio.values, nota['direcao'] as String?),
    );
  }
  if (conferirNotas(convertidas).isNotEmpty) return null;
  return AvaliacaoCapeV(
    analiseId: sessaoId,
    pacienteId: pacienteId,
    notas: convertidas,
    registradaEm: avaliadaEm.toLocal(),
    comentarios: (campos['comentarios'] as String?) ?? '',
  );
}
