import 'dart:typed_data';

/// Monta um arquivo WAV para teste: cabeçalho de verdade e áudio zerado.
///
/// O conteúdo do áudio não importa — a conferência só lê o cabeçalho e o
/// tamanho. [comList] põe um bloco `LIST` entre o `fmt ` e o `data`, como
/// fazem alguns gravadores; [extensivel] usa `WAVE_FORMAT_EXTENSIBLE`.
Uint8List wavDeTeste({
  required Duration duracao,
  int formato = 1,
  int taxa = 44100,
  int canais = 1,
  int bits = 16,
  bool comList = false,
  bool extensivel = false,
}) {
  final bytesDeAudio =
      taxa * canais * (bits ~/ 8) * duracao.inMicroseconds ~/ 1000000;
  final saida = BytesBuilder();

  void texto(String t) => saida.add(t.codeUnits);
  void u16(int v) => saida.add(
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List(),
  );
  void u32(int v) => saida.add(
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
  );

  final tamanhoFmt = extensivel ? 40 : 16;
  final lista = comList
      ? 'INFOISFT\x06\x00\x00\x00teste\x00'.codeUnits
      : <int>[];

  texto('RIFF');
  u32(
    4 + (8 + tamanhoFmt) + (comList ? 8 + lista.length : 0) + 8 + bytesDeAudio,
  );
  texto('WAVE');

  texto('fmt ');
  u32(tamanhoFmt);
  u16(extensivel ? 0xFFFE : formato);
  u16(canais);
  u32(taxa);
  u32(taxa * canais * (bits ~/ 8));
  u16(canais * (bits ~/ 8));
  u16(bits);
  if (extensivel) {
    u16(22); // tamanho da extensão
    u16(bits); // bits válidos
    u32(canais == 1 ? 0x4 : 0x3); // máscara de canais
    u16(formato); // início do GUID do subformato
    saida.add(List<int>.filled(14, 0)); // resto do GUID
  }

  if (comList) {
    texto('LIST');
    u32(lista.length);
    saida.add(lista);
  }

  texto('data');
  u32(bytesDeAudio);
  saida.add(Uint8List(bytesDeAudio));
  return saida.toBytes();
}
