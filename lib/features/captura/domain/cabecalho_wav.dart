import 'dart:typed_data';

/// O que o cabeçalho de um arquivo WAV declara.
///
/// Serve à regra de captura do CLAUDE.md: "VERIFICAR empiricamente o que
/// saiu, não confiar na configuração solicitada". Depois de cada gravação o
/// arquivo é lido de volta e o formato conferido aqui.
///
/// Só metadados: nenhuma amostra de áudio é lida ou analisada.
class CabecalhoWav {
  const CabecalhoWav({
    required this.formato,
    required this.canais,
    required this.taxaDeAmostragem,
    required this.bitsPorAmostra,
    required this.bytesDeAudio,
    required this.inicioDoAudio,
    this.subformatoPcm = false,
  });

  /// Código de formato do bloco `fmt `. 1 é PCM sem compressão.
  final int formato;
  final int canais;
  final int taxaDeAmostragem;
  final int bitsPorAmostra;

  /// Tamanho declarado do bloco `data`.
  final int bytesDeAudio;

  /// Posição, no arquivo, do primeiro byte de áudio. Com [bytesDeAudio], diz
  /// até onde o arquivo PRECISA ir — ver `verificarAmostra`.
  final int inicioDoAudio;

  static const formatoPcm = 1;

  /// `WAVE_FORMAT_EXTENSIBLE`: o formato de verdade fica num subcampo. Para
  /// PCM de 16 bits mono ou estéreo nenhum gravador precisa dele, mas há os
  /// que usam assim mesmo.
  static const formatoExtensivel = 0xFFFE;

  /// No formato extensível: o subformato declarado é PCM?
  final bool subformatoPcm;

  bool get ehPcm =>
      formato == formatoPcm || (formato == formatoExtensivel && subformatoPcm);

  /// Duração pelo tamanho do áudio e o formato declarado.
  Duration get duracao {
    final bytesPorSegundo = taxaDeAmostragem * canais * (bitsPorAmostra ~/ 8);
    if (bytesPorSegundo == 0) return Duration.zero;
    return Duration(
      microseconds:
          bytesDeAudio * Duration.microsecondsPerSecond ~/ bytesPorSegundo,
    );
  }
}

/// Lê o cabeçalho dos primeiros bytes de um WAV. `null` se não for WAV ou se
/// faltar o bloco `fmt ` ou o `data`.
///
/// Percorre os blocos em vez de supor posições fixas: há gravador que põe um
/// bloco `LIST` ou `fact` entre o `fmt ` e o `data`, e ler o byte 22 como
/// "canais" nesse arquivo daria lixo com cara de número.
///
/// [bytes] precisa conter pelo menos até o início do bloco `data` — alguns
/// KB bastam.
CabecalhoWav? lerCabecalhoWav(Uint8List bytes) {
  if (bytes.length < 12) return null;
  final dados = ByteData.sublistView(bytes);
  if (_texto(bytes, 0) != 'RIFF' || _texto(bytes, 8) != 'WAVE') return null;

  int? formato, canais, taxa, bits;
  var subformatoPcm = false;
  var posicao = 12;

  while (posicao + 8 <= bytes.length) {
    final id = _texto(bytes, posicao);
    final tamanho = dados.getUint32(posicao + 4, Endian.little);
    final corpo = posicao + 8;

    if (id == 'fmt ') {
      if (corpo + 16 > bytes.length) return null;
      formato = dados.getUint16(corpo, Endian.little);
      canais = dados.getUint16(corpo + 2, Endian.little);
      taxa = dados.getUint32(corpo + 4, Endian.little);
      bits = dados.getUint16(corpo + 14, Endian.little);
      // No extensível, os dois primeiros bytes do GUID do subformato repetem
      // o código de formato.
      if (formato == CabecalhoWav.formatoExtensivel &&
          tamanho >= 40 &&
          corpo + 26 <= bytes.length) {
        subformatoPcm =
            dados.getUint16(corpo + 24, Endian.little) ==
            CabecalhoWav.formatoPcm;
      }
    } else if (id == 'data') {
      if (formato == null) return null;
      return CabecalhoWav(
        formato: formato,
        canais: canais!,
        taxaDeAmostragem: taxa!,
        bitsPorAmostra: bits!,
        bytesDeAudio: tamanho,
        inicioDoAudio: corpo,
        subformatoPcm: subformatoPcm,
      );
    }

    // Blocos de tamanho ímpar têm um byte de preenchimento.
    posicao = corpo + tamanho + (tamanho.isOdd ? 1 : 0);
  }
  return null;
}

String _texto(Uint8List bytes, int inicio) =>
    String.fromCharCodes(bytes.sublist(inicio, inicio + 4));
