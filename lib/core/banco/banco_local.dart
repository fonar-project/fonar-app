import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'tabelas.dart';

part 'banco_local.g.dart';

/// O banco local do aparelho — um só, para todas as funcionalidades.
///
/// Guarda o que precisa sobreviver ao app fechado: pacientes, consentimentos,
/// gravações, a fila de envio, CAPE-V, laudos e as preferências do aparelho. É o que deixa o consultório sem sinal
/// trabalhar: gravar funciona offline, e a fila sobe depois.
///
/// Nenhuma medida acústica mora aqui: elas vêm do servidor.
@DriftDatabase(
  tables: [
    Pacientes,
    Consentimentos,
    RetiradasDeConsentimento,
    Envios,
    Amostras,
    AmostrasDoEnvio,
    AvaliacoesCapeV,
    NotasCapeV,
    Laudos,
    Preferencias,
  ],
)
class BancoLocal extends _$BancoLocal {
  BancoLocal(super.conexao);

  /// O arquivo do aparelho, na área PRIVADA do aplicativo — a mesma pasta dos
  /// WAV. A pasta de documentos, que é o padrão, no Windows é a "Documentos"
  /// do usuário: dado de paciente não vai para lá.
  ///
  /// TODO(jurídico): o arquivo não é cifrado — mesma pendência dos WAV.
  factory BancoLocal.doAparelho() => BancoLocal(
    driftDatabase(
      name: 'fonar',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    ),
  );

  /// Subiu a versão? Antes, guarde o formato novo e escreva a migração:
  ///
  ///     dart run drift_dev schema dump lib/core/banco/banco_local.dart drift_schemas/
  ///
  /// `drift_schemas/` guarda o formato de cada versão já distribuída; é com
  /// ele que se testa que o banco de quem atualiza o app chega inteiro.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Uma versão por vez, na ordem: o aparelho pode estar várias atrás.
    onUpgrade: (m, de, para) async {
      if (de < 2) {
        // US15: retirada do consentimento.
        await m.createTable(retiradasDeConsentimento);
      }
      if (de < 3) {
        // US30: preferências do aparelho (o tema).
        await m.createTable(preferencias);
      }
      if (de < 4) {
        // US32: de quem é cada envio da fila.
        await m.addColumn(envios, envios.profissionalId);
      }
      if (de < 5) {
        // US38: o laudo emitido não se sobrescreve (ADR-018 da API). A
        // chave passa da análise para o código do documento, e cada laudo
        // que já existia ganha um código - os PDFs dele, de antes, não o
        // trazem impresso, e continuam como foram.
        await m.alterTable(
          TableMigration(
            laudos,
            columnTransformer: {laudos.id: const CustomExpression(uuidV4Sql)},
            newColumns: [laudos.id, laudos.substitui, laudos.enviadoEm],
          ),
        );
      }
    },
    // O SQLite vem com chave estrangeira DESLIGADA; sem isto, nada impediria
    // apagar a amostra de um envio, e o envio subiria sem o arquivo.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

/// Um UUID versão 4 em SQL, para dar id a linha que já existia numa
/// migração: o mesmo formato de `novoId` (`novo_id.dart`), minúsculo e com
/// hífens.
///
/// Avaliado uma vez por linha copiada.
const uuidV4Sql =
    "lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || "
    "substr(hex(randomblob(2)), 2) || '-' || "
    "substr('89ab', 1 + (abs(random()) % 4), 1) || "
    "substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6)))";

/// O banco, aberto na primeira consulta e fechado junto do app.
///
/// Nos testes, substitua por um em memória.
final bancoLocalProvider = Provider<BancoLocal>((ref) {
  final banco = BancoLocal.doAparelho();
  ref.onDispose(banco.close);
  return banco;
});
