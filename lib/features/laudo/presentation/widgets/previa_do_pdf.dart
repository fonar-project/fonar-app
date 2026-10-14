import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_cores.dart';

/// A função que o `PdfPreview` recebe, refeita só quando muda a função que
/// gera o PDF.
///
/// O `PdfPreview` compara essa função por identidade e rasteriza o A4 de novo
/// sempre que recebe outra. Um `(_) => gerar()` escrito direto no `build` é
/// outra a cada reconstrução da tela — um foco, um hover, o respiro da
/// digitação —, e a folha piscava (US53).
class MemoDaPrevia {
  Future<Uint8List> Function()? _gerar;
  LayoutCallback? _build;

  LayoutCallback para(Future<Uint8List> Function() gerar) {
    if (_build == null || gerar != _gerar) {
      _gerar = gerar;
      _build = (_) => gerar();
    }
    return _build!;
  }
}

/// A pré-visualização A4 do laudo no desktop.
///
/// É o próprio PDF, rasterizado pelo `printing` — o que se vê é o que sai, e
/// não uma imitação em widgets que poderia divergir do documento.
///
/// Rasteriza só quando [gerar] muda: quem chama guarda a mesma função
/// enquanto o documento não muda (ver `_previa` em `laudo_page.dart`).
class PreviaDoPdf extends StatefulWidget {
  const PreviaDoPdf({super.key, required this.gerar});

  final Future<Uint8List> Function() gerar;

  @override
  State<PreviaDoPdf> createState() => _PreviaDoPdfState();
}

class _PreviaDoPdfState extends State<PreviaDoPdf> {
  final _memo = MemoDaPrevia();

  @override
  Widget build(BuildContext context) => PdfPreview.builder(
    build: _memo.para(widget.gerar),
    useActions: false,
    allowPrinting: false,
    allowSharing: false,
    canChangeOrientation: false,
    canChangePageFormat: false,
    canDebug: false,
    maxPageWidth: 640,
    // A folha continua branca; em volta dela, a cor do tema.
    scrollViewDecoration: BoxDecoration(color: context.cores.borda),
    pagesBuilder: (context, paginas) => ListView.builder(
      itemCount: paginas.length,
      itemBuilder: (context, i) => _Folha(paginas[i]),
    ),
  );
}

/// Uma página, como o `printing` a desenha — com uma diferença: a imagem
/// anterior fica na tela até a nova estar pronta.
///
/// Sem isso, cada troca legítima (o texto da conclusão depois do respiro, o
/// espectrograma que chegou, o laudo emitido) deixava a folha em branco por
/// um instante, entre uma imagem e outra. Não são dois estados ao mesmo
/// tempo: a imagem velha já ficava ali enquanto a nova era rasterizada; o
/// que sai é só o quadro em branco do meio.
class _Folha extends StatelessWidget {
  const _Folha(this.pagina);

  final PdfPreviewPageData pagina;

  @override
  Widget build(BuildContext context) {
    // A mesma margem do `printing`: a página não fica sob a barra de rolagem.
    final trilho =
        Theme.of(context).scrollbarTheme.thickness
            ?.resolve({WidgetState.hovered}) ??
        12;
    return Container(
      margin: EdgeInsets.only(
        left: 8 + trilho,
        top: 8,
        right: 8 + trilho,
        bottom: 12,
      ),
      // É o papel do documento, branco nos dois temas — a exceção do PDF do
      // laudo descrita em `app_cores.dart`.
      decoration: const BoxDecoration(
        color: AppColors.branco,
        boxShadow: [BoxShadow(offset: Offset(0, 3), blurRadius: 5)],
      ),
      child: AspectRatio(
        aspectRatio: pagina.aspectRatio,
        child: Image(
          image: pagina.image,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
