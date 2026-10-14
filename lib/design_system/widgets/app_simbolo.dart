import 'package:flutter/material.dart';

/// O símbolo do FONAR (US47): a onda de voz que vira ondas de sonar —
/// fonoaudiologia mais sonar, o nome do produto.
///
/// Desenhado aqui, e não carregado de arquivo, para tomar a cor do tema como
/// qualquer texto: creme na barra lateral roxa, acento no tema escuro. O
/// desenho é o mesmo de `marca/fonar-simbolo.svg`, num quadro de 64; a onda
/// ocupa a metade esquerda, e as três ondas de sonar vão ficando mais claras.
///
/// Decorativo: fica fora da árvore de semântica, porque vem sempre ao lado
/// do nome FONAR escrito, que é o que o leitor de tela lê.
class AppSimbolo extends StatelessWidget {
  const AppSimbolo({required this.cor, this.tamanho = 32, super.key});

  /// Cor do traço. As ondas de sonar saem dela, mais claras.
  final Color cor;

  /// Lado do quadrado do símbolo. O desenho ocupa a largura toda e cerca de
  /// dois terços da altura.
  final double tamanho;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(tamanho),
      painter: PintorDoSimbolo(cor),
    ),
  );
}

/// Pinta o símbolo no tamanho que receber. Público para o teste conferir o
/// repintar.
class PintorDoSimbolo extends CustomPainter {
  PintorDoSimbolo(this.cor);

  final Color cor;

  /// A onda de voz.
  static final _onda = Path()
    ..moveTo(5, 32)
    ..cubicTo(6.5, 23, 10, 23, 11.8, 32)
    ..cubicTo(13.6, 41, 16.2, 38.5, 18, 32)
    ..cubicTo(19.8, 25.5, 22.4, 28.2, 24.6, 32)
    ..cubicTo(26.8, 35.8, 28.6, 33.2, 31, 32);

  /// As ondas de sonar, de dentro para fora, com a opacidade de cada uma.
  static final _ondasDeSonar = [
    (_arco(37.3, 25.5, 38.5, 9), 1.0),
    (_arco(43.2, 19.4, 44.6, 17.5), 0.7),
    (_arco(49.1, 13.3, 50.7, 26), 0.4),
  ];

  static Path _arco(double x, double yInicio, double yFim, double raio) =>
      Path()
        ..moveTo(x, yInicio)
        ..arcToPoint(Offset(x, yFim), radius: Radius.circular(raio));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      _onda,
      traco
        ..color = cor
        ..strokeWidth = 4.2,
    );
    for (final (onda, opacidade) in _ondasDeSonar) {
      canvas.drawPath(
        onda,
        traco
          ..color = cor.withValues(alpha: cor.a * opacidade)
          ..strokeWidth = 4.4,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorDoSimbolo antigo) => antigo.cor != cor;
}

/// O mesmo símbolo em SVG, roxo, para onde não há `Canvas`: o cabeçalho do
/// laudo em PDF.
const simboloDoFonarSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
    '<path d="M5 32C6.5 23 10 23 11.8 32C13.6 41 16.2 38.5 18 32'
    'C19.8 25.5 22.4 28.2 24.6 32C26.8 35.8 28.6 33.2 31 32" '
    'stroke="#40085E" stroke-width="4.2" stroke-linecap="round" '
    'stroke-linejoin="round" fill="none"/>'
    '<path d="M37.3 25.5A9 9 0 0 1 37.3 38.5" stroke="#40085E" '
    'stroke-width="4.4" stroke-linecap="round" fill="none"/>'
    '<path d="M43.2 19.4A17.5 17.5 0 0 1 43.2 44.6" stroke="#40085E" '
    'stroke-opacity="0.7" stroke-width="4.4" stroke-linecap="round" '
    'fill="none"/>'
    '<path d="M49.1 13.3A26 26 0 0 1 49.1 50.7" stroke="#40085E" '
    'stroke-opacity="0.4" stroke-width="4.4" stroke-linecap="round" '
    'fill="none"/>'
    '</svg>';
