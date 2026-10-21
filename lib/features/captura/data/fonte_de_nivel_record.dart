import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../../core/navegador/navegador.dart';
import '../domain/ajuste_de_configuracao.dart';
import '../domain/fonte_de_nivel.dart';
import '../domain/processamento_automatico.dart';
import 'configuracao_de_captura.dart';

/// Uma fonte nova a cada uso: cada aferição abre e fecha o próprio recorder.
final fonteDeNivelProvider = Provider.autoDispose<FonteDeNivel>((ref) {
  final fonte = FonteDeNivelRecord(
    conferirNavegador: kIsWeb ? processamentoDoNavegador : null,
  );
  // Sair da tela fecha o microfone. Microfone aberto sem ninguém olhando é
  // exatamente o que não pode acontecer com dado de saúde.
  ref.onDispose(fonte.fechar);
  return fonte;
});

/// Nível do microfone lido pelo pacote `record`.
///
/// A aferição abre uma captura em fluxo (nada é gravado em arquivo) e lê o
/// nível pelo `onAmplitudeChanged`. Os bytes de áudio chegam e são
/// descartados: o aplicativo não analisa áudio — só o nível, que é a exceção
/// permitida.
///
/// NÃO VERIFICADO EM APARELHO REAL. Escrito contra a API do `record` 7.1 e o
/// código do `record_windows` 2.3, sem microfone para testar. Conferir no
/// Android e no Windows antes de confiar, em especial: o valor que chega com
/// o microfone bloqueado pela privacidade do Windows, e se o
/// `setOnConfigChanged` dispara quando o aparelho troca a taxa.
class FonteDeNivelRecord implements FonteDeNivel {
  FonteDeNivelRecord({this.conferirNavegador});

  /// No navegador (US42), a conferência própria do processamento automático,
  /// feita antes de a aferição abrir o microfone. Nula no aparelho.
  ///
  /// Existe porque o aviso do `record_web` não basta: propriedade que o
  /// navegador não relata volta como foi PEDIDA, desligada — e não relatar
  /// não é evidência de nada. Ver `naoConfirmadosDesligados`.
  ///
  /// Recebe o microfone escolhido: a conferência abre a MESMA faixa que a
  /// captura vai abrir, senão confere o processamento de outro microfone.
  final Future<Set<ProcessamentoAutomatico>> Function(String? microfone)?
  conferirNavegador;

  AudioRecorder? _gravador;
  StreamSubscription<List<int>>? _bytes;
  AjusteDeConfiguracao? _ajuste;
  Set<ProcessamentoAutomatico> _doNavegador = const {};

  @override
  AjusteDeConfiguracao? get ajuste => AjusteDeConfiguracao.juntar(
    _ajuste,
    _doNavegador,
    taxaPedida: ConfiguracaoDeCaptura.taxaDeAmostragem,
    canaisPedidos: ConfiguracaoDeCaptura.canais,
  );

  @override
  Future<bool> pedirPermissao() async {
    final gravador = _gravador ??= AudioRecorder();
    return gravador.hasPermission();
  }

  @override
  Future<Stream<double>> abrir(Duration intervalo, {String? microfone}) async {
    final gravador = _gravador ??= AudioRecorder();
    _ajuste = null;
    _doNavegador = const {};
    if (conferirNavegador case final conferir?) {
      _doNavegador = await conferir(microfone);
    }
    await gravador.setOnConfigChanged(
      (usada) => _ajuste = ConfiguracaoDeCaptura.ajusteDe(usada),
    );

    final audio = await gravador.startStream(
      ConfiguracaoDeCaptura.para(
        ConfiguracaoDeCaptura.formatoDaAfericao,
        microfone: microfone,
      ),
    );
    // Consumir o fluxo é obrigatório — sem ouvinte, os trechos se acumulam
    // na memória. O conteúdo é descartado.
    _bytes = audio.listen((_) {});

    return gravador.onAmplitudeChanged(intervalo).map((a) => a.current);
  }

  @override
  Future<void> fechar() async {
    final gravador = _gravador;
    _gravador = null;
    await _bytes?.cancel();
    _bytes = null;
    if (gravador == null) return;
    try {
      await gravador.stop();
    } finally {
      await gravador.dispose();
    }
  }
}

/// A conferência do navegador (US42): o que ele relata da faixa de áudio
/// aberta com o pedido da captura, julgado por `naoConfirmadosDesligados`.
Future<Set<ProcessamentoAutomatico>> processamentoDoNavegador(
  String? microfone,
) async {
  final relatado = await processamentoRelatadoPeloNavegador(
    taxaDeAmostragem: ConfiguracaoDeCaptura.taxaDeAmostragem,
    canais: ConfiguracaoDeCaptura.canais,
    microfone: microfone,
  );
  return naoConfirmadosDesligados(
    ganho: relatado.ganho,
    ruido: relatado.ruido,
    eco: relatado.eco,
  );
}
