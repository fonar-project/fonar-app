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
  int get schemaVersion => 3;

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
    },
    // O SQLite vem com chave estrangeira DESLIGADA; sem isto, nada impediria
    // apagar a amostra de um envio, e o envio subiria sem o arquivo.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

/// O banco, aberto na primeira consulta e fechado junto do app.
///
/// Nos testes, substitua por um em memória.
final bancoLocalProvider = Provider<BancoLocal>((ref) {
  final banco = BancoLocal.doAparelho();
  ref.onDispose(banco.close);
  return banco;
});
