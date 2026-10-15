import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/banco/banco_local.dart';
import '../../../core/banco/conversao.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/firestore/firestore_rest.dart';
import '../../auth/data/sessao.dart';
import '../../consentimento/domain/consentimento.dart';
import '../../fila/domain/item_da_fila.dart';
import '../../pacientes/domain/novo_paciente.dart';
import '../domain/sincronizacao.dart';

final sincronizacaoProvider = Provider<Sincronizacao>(
  (ref) => SincronizacaoFirestore(
    ref.watch(firestoreRestProvider),
    ref.watch(bancoLocalProvider),
    uid: () => ref.read(sessaoProvider)?.uid,
  ),
);

/// Os limites que as regras do Firestore aplicam ao que o app grava — os
/// mesmos de `domain/models.py`, na API.
abstract final class LimitesDoFirestore {
  static const nome = 200;
  static const queixa = 2000;

  /// Os comentários da CAPE-V (`TAMANHO_MAXIMO_COMENTARIOS_CAPE_V`).
  static const comentariosCapeV = 2000;
}

/// Sobe do banco local para o Firestore o paciente, o livro de
/// consentimentos e a sessão de um envio.
///
/// O banco local continua sendo de onde o app lê; o Firestore recebe uma
/// cópia, na árvore da conta que está na sessão
/// (`profissionais/{uid}/pacientes/{id}/...`). O formato de cada documento é
/// o que as regras de segurança aceitam — ver `firestore.rules` no
/// repositório da API.
///
/// O livro de consentimentos é uma sequência sem buraco (`consentimentos/1`,
/// `/2`...): concessão e retirada intercaladas, na ordem em que foram
/// gravadas no aparelho. O que já está no Firestore tem de ser o começo da
/// sequência daqui; só o resto sobe. Se não for — outro aparelho escreveu um
/// livro diferente para o mesmo paciente —, nada é gravado e o envio é
/// recusado com o motivo, para alguém olhar.
class SincronizacaoFirestore implements Sincronizacao {
  SincronizacaoFirestore(this._firestore, this._banco, {required this.uid});

  final FirestoreRest _firestore;
  final BancoLocal _banco;

  /// A conta que está na sessão: a fila só envia na sessão de quem gravou.
  final String? Function() uid;

  @override
  Future<void> prepararEnvio(ItemDaFila item) async {
    final conta = uid();
    if (conta == null) throw const NaoAutorizado();
    final base = 'profissionais/$conta/pacientes/${item.pacienteId}';
    await _paciente(base, item.pacienteId, conta);
    await _consentimentos(base, item.pacienteId);
    await _sessao(base, item);
  }

  /// Garante no Firebase só o cadastro do paciente, sem consentimentos nem
  /// sessão — o que as anotações (US51) precisam: anotar não depende do
  /// consentimento, e o paciente pode nunca ter mandado gravação. Sobe só
  /// se o daqui ainda não subiu como está.
  ///
  /// Lança só `AppException`.
  Future<void> garantirPaciente(String pacienteId) async {
    final conta = uid();
    if (conta == null) throw const NaoAutorizado();
    final linha = await (_banco.select(
      _banco.pacientes,
    )..where((p) => p.id.equals(pacienteId))).getSingleOrNull();
    final sincronizado = linha?.sincronizadoEm;
    final alterado = linha?.alteradoEm;
    if (sincronizado != null &&
        (alterado == null || !alterado.isAfter(sincronizado))) {
      return;
    }
    await _paciente(
      'profissionais/$conta/pacientes/$pacienteId',
      pacienteId,
      conta,
    );
  }

  Future<void> _paciente(String base, String pacienteId, String conta) async {
    final linha = await (_banco.select(
      _banco.pacientes,
    )..where((p) => p.id.equals(pacienteId))).getSingleOrNull();
    // Paciente de exemplo, ou apagado do aparelho: não há o que subir.
    if (linha == null) {
      throw const FalhaDeValidacao(causa: 'paciente fora do banco local');
    }
    final nascimento = linha.dataDeNascimento;
    final sexo = _sexo(linha.sexo);
    if (nascimento == null || sexo == null) {
      throw const FalhaDeValidacao(causa: 'cadastro sem nascimento ou sexo');
    }
    if (linha.nome.length > LimitesDoFirestore.nome ||
        linha.queixa.length > LimitesDoFirestore.queixa) {
      throw const FalhaDeValidacao(causa: 'cadastro maior que o aceito');
    }
    final campos = <String, Object?>{
      'nome': linha.nome,
      // Data sem hora: meia-noite UTC, como as regras exigem.
      'data_nascimento': DateTime.utc(
        nascimento.year,
        nascimento.month,
        nascimento.day,
      ),
      'sexo_referencia': sexo,
      if (linha.queixa.trim().isNotEmpty) 'queixa_principal': linha.queixa,
    };

    final existente = await _firestore.ler(base);
    if (existente == null) {
      await _firestore.criar(base, campos, horaDoServidor: ['criado_em']);
    } else {
      final mudou = camposEditaveisDoPaciente.any(
        (c) => existente[c] != campos[c],
      );
      // Os dados do paciente podem ter sido corrigidos no aparelho (US20).
      if (mudou) {
        await _firestore.atualizar(
          base,
          campos,
          mascara: camposEditaveisDoPaciente,
        );
      }
    }
    // Aparelho e Firebase iguais (US40): a partir daqui, o que descer pode
    // atualizar este paciente — até a próxima correção feita aqui. A marca é
    // a da mudança que subiu, e não a hora de agora: uma correção feita
    // durante o envio continua por subir.
    await (_banco.update(
      _banco.pacientes,
    )..where((p) => p.id.equals(pacienteId))).write(
      PacientesCompanion(
        sincronizadoEm: Value(linha.alteradoEm ?? DateTime.now()),
        // Sem dono (antes da US40): é de quem o mandou para a análise.
        profissionalId: Value(linha.profissionalId ?? conta),
      ),
    );
  }

  Future<void> _consentimentos(String base, String pacienteId) async {
    final locais = await livroDeConsentimentoLocal(_banco, pacienteId);
    final colecao = '$base/consentimentos';
    final remotos = await _firestore.listar(colecao);
    remotos.sort(
      (a, b) => (a.campos['seq'] as int).compareTo(b.campos['seq'] as int),
    );

    final comuns = remotos.length < locais.length
        ? remotos.length
        : locais.length;
    for (var i = 0; i < comuns; i++) {
      final remoto = remotos[i].campos;
      final local = locais[i];
      if (remoto['seq'] != i + 1 ||
          remoto['tipo'] != local.tipo ||
          remoto['versao_termo'] != local.versaoDoTermo) {
        throw FalhaDeValidacao(
          causa: 'livro de consentimentos divergente no registro ${i + 1}',
        );
      }
    }
    for (var i = remotos.length; i < locais.length; i++) {
      final registro = locais[i];
      final seq = i + 1;
      await _firestore.criar(
        '$colecao/$seq',
        {
          'seq': seq,
          'tipo': registro.tipo,
          'data': registro.data,
          'versao_termo': registro.versaoDoTermo,
          'declarante': registro.declarante,
          'nome_responsavel': ?registro.nomeDoResponsavel,
        },
        horaDoServidor: ['registrado_em'],
      );
    }
  }

  Future<void> _sessao(String base, ItemDaFila item) async {
    final caminho = '$base/sessoes/${item.sessaoId}';
    if (await _firestore.ler(caminho) != null) return;
    final gravadas = [for (final a in item.amostras) a.gravadaEm];
    final data = gravadas.isEmpty
        ? item.criadoEm
        : gravadas.reduce((a, b) => a.isBefore(b) ? a : b);
    await _firestore.criar(
      caminho,
      {
        // A data da sessão é a da primeira gravação: é ela que dá a idade do
        // paciente para a faixa de referência.
        'data': data,
        // Mandada para a análise, a sessão está encerrada.
        'estado': 'concluida',
      },
      horaDoServidor: ['criado_em'],
    );
  }

  /// O sexo do cadastro com o nome que o Firestore (e a API) usa.
  static String? _sexo(String? nome) =>
      switch (enumOuNulo(SexoDeReferencia.values, nome)) {
        SexoDeReferencia.feminino => 'feminino',
        SexoDeReferencia.masculino => 'masculino',
        SexoDeReferencia.naoInformado => 'nao_informado',
        null => null,
      };
}

/// Os consentimentos e as retiradas do paciente como um livro só, na
/// ordem em que foram gravados: cada retirada logo depois do
/// consentimento que ela retira.
Future<List<RegistroDoLivro>> livroDeConsentimentoLocal(
  BancoLocal banco,
  String pacienteId,
) async {
  final consentimentos =
      await (banco.select(banco.consentimentos)
            ..where((c) => c.pacienteId.equals(pacienteId))
            ..orderBy([(c) => OrderingTerm.asc(c.id)]))
          .get();
  // Retirada sem consentimento no banco é a de um consentimento de
  // exemplo, que nunca sobe.
  final retiradas =
      await (banco.select(banco.retiradasDeConsentimento)..where(
            (r) =>
                r.pacienteId.equals(pacienteId) & r.consentimentoId.isNotNull(),
          ))
          .get();
  final retiradaDe = {for (final r in retiradas) r.consentimentoId!: r};
  return [
    for (final c in consentimentos) ...[
      RegistroDoLivro(
        tipo: 'concessao',
        data: c.registradoEm,
        versaoDoTermo: c.versaoDoTermo,
        quem: c.quemAutoriza,
        nome: c.nomeDoResponsavel,
        consentimentoId: c.id,
      ),
      if (retiradaDe[c.id] case final r?)
        RegistroDoLivro(
          tipo: 'retirada',
          data: r.retiradaEm,
          versaoDoTermo: c.versaoDoTermo,
          quem: r.quemPediu,
          nome: r.nomeDoResponsavel,
          consentimentoId: c.id,
        ),
    ],
  ];
}

/// Os campos do documento do paciente que o aparelho corrige (US20) — os
/// que sobem e os que descem.
const camposEditaveisDoPaciente = [
  'nome',
  'data_nascimento',
  'sexo_referencia',
  'queixa_principal',
];

/// Um registro do livro de consentimentos, no formato do Firestore.
class RegistroDoLivro {
  RegistroDoLivro({
    required this.tipo,
    required this.data,
    required this.versaoDoTermo,
    required String quem,
    required String? nome,
    this.consentimentoId,
  }) : declarante = quem == QuemAutoriza.responsavelLegal.name
           ? 'responsavel_legal'
           : 'paciente',
       // O nome só vai quando quem declarou foi o responsável legal: as
       // regras recusam nome de terceiro na declaração do próprio paciente.
       nomeDoResponsavel =
           quem == QuemAutoriza.responsavelLegal.name &&
               (nome?.trim().isNotEmpty ?? false)
           ? nome!.trim()
           : null;

  final String tipo;
  final DateTime data;
  final String versaoDoTermo;
  final String declarante;
  final String? nomeDoResponsavel;

  /// O consentimento do banco local a que o registro se refere: o dado, na
  /// concessão; o retirado, na retirada.
  final int? consentimentoId;
}
