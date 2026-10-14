/// No navegador. Ver `navegador.dart`.
///
/// Fala com o navegador pelo `package:web`, a ponte oficial do Dart para as
/// APIs da web. NÃO VERIFICADO NO IPHONE: escrito contra o `package:web` 1.1
/// e o código do `record_web` 2.1, sem aparelho para testar (PENDENCIAS.md).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// O que o navegador relata do processamento da faixa de áudio: `true`,
/// ligado; `false`, desligado; `null`, não relata.
typedef ProcessamentoRelatado = ({bool? ganho, bool? ruido, bool? eco});

/// Os bytes de um endereço `blob:` — é como o `record_web` entrega o WAV
/// gravado, porque no navegador não há arquivo. O endereço é solto depois de
/// lido: segurar a gravação na memória da página sem dono é o que não pode.
Future<Uint8List> lerEnderecoTemporario(String endereco) async {
  try {
    final resposta = await web.window.fetch(endereco.toJS).toDart;
    final conteudo = await resposta.arrayBuffer().toDart;
    return conteudo.toDart.asUint8List();
  } finally {
    web.URL.revokeObjectURL(endereco);
  }
}

/// Abre o microfone com o mesmo pedido da captura — os três processamentos
/// desligados, a taxa e os canais do projeto —, lê o que o navegador diz ter
/// aplicado à faixa (`getSettings()`) e fecha.
///
/// É a evidência que a regra de captura pede: não o que foi pedido, mas o
/// que o navegador relata. Quem decide o que bloqueia é
/// `naoConfirmadosDesligados`, no domínio da captura.
Future<ProcessamentoRelatado> processamentoRelatadoPeloNavegador({
  required int taxaDeAmostragem,
  required int canais,
}) async {
  final pedido = web.MediaStreamConstraints(
    audio: {
      'autoGainControl': false,
      'echoCancellation': false,
      'noiseSuppression': false,
      'sampleRate': taxaDeAmostragem,
      'sampleSize': 16,
      'channelCount': canais,
    }.jsify()!,
  );
  final fluxo = await web.window.navigator.mediaDevices
      .getUserMedia(pedido)
      .toDart;
  final faixas = fluxo.getAudioTracks().toDart;
  try {
    // Sem faixa, nada foi relatado — e sem relato não há evidência.
    if (faixas.isEmpty) return (ganho: null, ruido: null, eco: null);
    final relatado = faixas.first.getSettings();
    bool? ler(String nome) {
      final chave = nome.toJS;
      if (!relatado.hasProperty(chave).toDart) return null;
      if (!relatado.getProperty<JSAny?>(chave).typeofEquals('boolean')) {
        return null;
      }
      return relatado.getProperty<JSBoolean>(chave).toDart;
    }

    return (
      ganho: ler('autoGainControl'),
      ruido: ler('noiseSuppression'),
      eco: ler('echoCancellation'),
    );
  } finally {
    // O microfone desta conferência fecha antes de a captura abrir o dela.
    for (final faixa in faixas) {
      faixa.stop();
    }
  }
}

/// O navegador, como ele se apresenta — vai com cada gravação como metadado
/// de captura, no lugar do sistema e da versão que o aparelho informa.
String descricaoDoNavegador() => web.window.navigator.userAgent;

/// Pede ao navegador para não apagar os dados do FONAR quando faltar espaço.
///
/// Sem isto, o navegador pode limpar o banco local — com gravações que ainda
/// não subiram — por conta própria. O navegador pode recusar; pedir não
/// custa nada e nunca falha daqui.
Future<void> pedirArmazenamentoPersistente() async {
  try {
    final armazenamento = web.window.navigator.storage;
    if (!(await armazenamento.persisted().toDart).toDart) {
      await armazenamento.persist().toDart;
    }
  } catch (_) {
    // Navegador sem a API, ou que recusa: segue como está.
  }
}
