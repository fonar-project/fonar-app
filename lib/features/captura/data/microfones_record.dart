import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../../core/banco/banco_local.dart';
import '../../../l10n/app_strings.dart';
import '../domain/microfone.dart';

final listaDeMicrofonesProvider = Provider<ListaDeMicrofones>(
  (ref) => const MicrofonesRecord(),
);

final preferenciaDeMicrofoneProvider = Provider<PreferenciaDeMicrofoneLocal>(
  (ref) => PreferenciaDeMicrofoneLocal(ref.watch(bancoLocalProvider)),
);

/// Os microfones pelo `listInputDevices` do pacote `record` — o mesmo que
/// grava, e que recebe o escolhido no `RecordConfig.device`. Funciona no
/// Windows, no macOS, no Android e no navegador.
///
/// NÃO VERIFICADO EM APARELHO REAL, como o resto da captura: o ambiente em
/// que foi escrito não tem microfone.
class MicrofonesRecord implements ListaDeMicrofones {
  const MicrofonesRecord();

  @override
  Future<List<Microfone>> listar() async {
    final gravador = AudioRecorder();
    try {
      return microfonesParaGravar(await gravador.listInputDevices());
    } finally {
      try {
        await gravador.dispose();
      } catch (_) {}
    }
  }
}

/// Os aparelhos que servem para a gravação clínica, com um nome legível.
///
/// Os de Bluetooth ficam de fora pela mesma razão do `manageBluetooth: false`
/// em `ConfiguracaoDeCaptura`: o microfone de um fone Bluetooth chega
/// comprimido, em banda estreita, e muda o que a análise mede.
///
/// O nome vem do sistema. No Android ele é o modelo do aparelho, igual para
/// os vários microfones embutidos; sem nome, ou com nome repetido, o
/// microfone ganha o nome do tipo, numerado.
@visibleForTesting
List<Microfone> microfonesParaGravar(List<InputDevice> aparelhos) {
  final servem = [
    for (final a in aparelhos)
      if (!_bluetooth.contains(a.type) && a.id.isNotEmpty) a,
  ];
  final repeticoes = <String, int>{};
  for (final a in servem) {
    final nome = a.label.trim();
    repeticoes[nome] = (repeticoes[nome] ?? 0) + 1;
  }
  final usados = <String, int>{};
  return [
    for (final a in servem)
      Microfone(
        id: a.id,
        nome: switch (a.label.trim()) {
          final nome when nome.isNotEmpty && repeticoes[nome] == 1 => nome,
          _ => _numerado(_nomeDoTipo(a.type), usados),
        },
      ),
  ];
}

const _bluetooth = {
  InputDeviceType.bluetoothSco,
  InputDeviceType.bluetoothA2dp,
  InputDeviceType.bluetoothLe,
};

String _nomeDoTipo(InputDeviceType tipo) => switch (tipo) {
  InputDeviceType.builtIn => AppStrings.microfoneEmbutido,
  InputDeviceType.wiredHeadset => AppStrings.microfoneFoneComFio,
  InputDeviceType.usb => AppStrings.microfoneUsb,
  InputDeviceType.lineIn => AppStrings.microfoneEntradaDeLinha,
  _ => AppStrings.microfoneSemNome,
};

String _numerado(String base, Map<String, int> usados) {
  final n = (usados[base] ?? 0) + 1;
  usados[base] = n;
  return n == 1 ? base : '$base $n';
}

/// Onde a escolha do microfone fica: na tabela de preferências do aparelho.
///
/// É do aparelho, e não da conta: o microfone é do computador em que se
/// grava, não de quem entrou nele.
class PreferenciaDeMicrofoneLocal {
  PreferenciaDeMicrofoneLocal(this._banco);

  final BancoLocal _banco;

  static const _chave = 'captura.microfone';

  /// O guardado, ou `null` (o padrão do sistema) — inclusive se o valor
  /// gravado não for legível.
  Future<Microfone?> ler() async {
    final linha = await (_banco.select(
      _banco.preferencias,
    )..where((p) => p.chave.equals(_chave))).getSingleOrNull();
    if (linha == null) return null;
    try {
      final json = jsonDecode(linha.valor) as Map<String, Object?>;
      final id = json['id'] as String;
      return Microfone(id: id, nome: json['nome'] as String? ?? id);
    } catch (_) {
      return null;
    }
  }

  /// Guarda [microfone], ou volta ao padrão do sistema com `null`.
  Future<void> guardar(Microfone? microfone) async {
    if (microfone == null) {
      await (_banco.delete(
        _banco.preferencias,
      )..where((p) => p.chave.equals(_chave))).go();
      return;
    }
    await _banco
        .into(_banco.preferencias)
        .insertOnConflictUpdate(
          PreferenciasCompanion.insert(
            chave: _chave,
            valor: jsonEncode({'id': microfone.id, 'nome': microfone.nome}),
          ),
        );
  }
}
