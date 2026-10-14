import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/features/laudo/data/repositorio_laudos_local.dart';

import '../../core/migracoes/schema.dart';

/// O formato de `novoId`: UUID versão 4, minúsculo, com hífens.
final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  // US38: na versão 5 o laudo passa a ter código próprio (a chave deixa de
  // ser a análise), quem ele substitui e quando subiu para a API.
  final verificador = SchemaVerifier(GeneratedHelper());

  test(
    'o laudo gravado na versão 4 chega com código, como foi emitido',
    () async {
      final esquema = await verificador.schemaAt(4);
      for (final (analise, byte) in [('an-1', 1), ('an-2', 2)]) {
        esquema.rawDatabase.execute(
          'INSERT INTO laudos (analise_id, paciente_id, conclusao, gerado_em, '
          "pdf) VALUES ('$analise', 'p1', 'Conclusão de $analise.', "
          "'2026-09-01T09:00:00.000Z', x'25504446000$byte')",
        );
      }
      final banco = BancoLocal(esquema.newConnection());
      addTearDown(banco.close);
      await verificador.migrateAndValidate(banco, banco.schemaVersion);

      final repositorio = RepositorioLaudosLocal(banco);
      final um = (await repositorio.daAnalise('an-1'))!;
      final dois = (await repositorio.daAnalise('an-2'))!;
      expect(um.id, matches(_uuidV4));
      expect(dois.id, matches(_uuidV4));
      expect(um.id, isNot(dois.id));
      // O documento, como estava; nada a substituir; a cópia ainda por subir.
      expect(um.pdf, [0x25, 0x50, 0x44, 0x46, 0x00, 0x01]);
      expect(um.conclusao, 'Conclusão de an-1.');
      expect(um.geradoEm, DateTime.utc(2026, 9, 1, 9));
      expect(um.substitui, isNull);
      expect(um.enviadoEm, isNull);
    },
  );
}
