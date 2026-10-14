import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/trava_por_chave.dart';

void main() {
  test('a mesma chave espera a anterior terminar', () async {
    final trava = TravaPorChave();
    final ordem = <String>[];
    final segura = Completer<void>();

    final primeira = trava.executar('s1', () async {
      ordem.add('descarte começou');
      await segura.future;
      ordem.add('descarte terminou');
    });
    final segunda = trava.executar('s1', () async {
      ordem.add('envio');
    });
    await Future<void>.delayed(Duration.zero);
    expect(ordem, ['descarte começou']);

    segura.complete();
    await Future.wait([primeira, segunda]);
    expect(ordem, ['descarte começou', 'descarte terminou', 'envio']);
  });

  test('chaves diferentes não esperam uma pela outra', () async {
    final trava = TravaPorChave();
    final segura = Completer<void>();
    final ordem = <String>[];

    final s1 = trava.executar('s1', () async {
      await segura.future;
      ordem.add('s1');
    });
    await trava.executar('s2', () async => ordem.add('s2'));
    expect(ordem, ['s2']);

    segura.complete();
    await s1;
    expect(ordem, ['s2', 's1']);
  });

  test('a falha de uma não prende a próxima', () async {
    final trava = TravaPorChave();
    await expectLater(
      trava.executar<void>('s1', () async => throw StateError('falhou')),
      throwsStateError,
    );
    expect(await trava.executar('s1', () async => 'seguiu'), 'seguiu');
  });
}
