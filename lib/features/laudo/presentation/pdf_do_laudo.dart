import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../design_system/tokens/app_colors.dart';
import '../../../l10n/app_strings.dart';
import '../../analise/domain/leitura_do_resultado.dart';
import '../../analise/domain/resultado_da_analise.dart';
import '../../analise/presentation/apresentacao_da_medida.dart';
import '../../cape_v/domain/avaliacao_cape_v.dart';
import '../../cape_v/presentation/apresentacao_cape_v.dart';
import '../../captura/domain/amostra.dart';
import '../../pacientes/domain/novo_paciente.dart';
import '../domain/conteudo_do_laudo.dart';

/// Monta o PDF do laudo, em A4.
///
/// Só DIAGRAMA o [ConteudoDoLaudo]: nenhum dado nasce aqui. A situação de cada
/// medida vai em TEXTO, não em cor — o laudo é impresso em preto e branco com
/// frequência, e nem na tela a cor sozinha basta.
///
/// TODO(equipe): o espectrograma não entra — é imagem do servidor, e o
/// contrato do resultado ainda não existe. Quando existir, baixar a imagem
/// antes de gerar e embutir no documento.
///
/// TODO(clínico): título, seções e ordem seguem a tela de resultado; conferir
/// com o modelo de laudo que a orientação espera.
///
/// Em Urbanist, a fonte do aplicativo, embutida no arquivo (licença OFL, que
/// permite). As fontes padrão do PDF não têm todos os sinais do português
/// nem o travessão.
Future<Uint8List> gerarPdfDoLaudo(ConteudoDoLaudo conteudo) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Urbanist-Regular.ttf'),
  );
  final negrito = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Urbanist-Bold.ttf'),
  );

  final documento = pw.Document(
    title: AppStrings.laudoDocTitulo,
    creator: AppStrings.appTitle,
  );
  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 48, 56, 48),
      theme: pw.ThemeData.withFont(base: regular, bold: negrito).copyWith(
        defaultTextStyle: _corpo(regular, negrito),
        // Listas e parágrafos no mesmo corpo do resto: o padrão do pacote é
        // maior e justificado.
        paragraphStyle: _corpo(regular, negrito),
        bulletStyle: _corpo(regular, negrito),
      ),
      header: (context) => _cabecalho(conteudo, context),
      footer: _rodape,
      build: (context) => [
        if (conteudo.exemplo) _faixaDeAviso(AppStrings.laudoDocExemplo),
        if (conteudo.rascunho) _faixaDeAviso(AppStrings.laudoDocRascunho),
        _secao(AppStrings.laudoDocIdentificacao),
        _identificacao(conteudo),
        _secao(AppStrings.laudoDocMedidas),
        _medidas(conteudo.medidas),
        if (motivoComum(conteudo.medidas) case final motivo?)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              '${AppStrings.statusSemReferencia}: '
              '${explicarSemClassificacao(motivo)}',
              style: const pw.TextStyle(fontSize: 9.5, color: _secundario),
            ),
          ),
        if (conteudo.qualidade.isNotEmpty) ...[
          _secao(AppStrings.laudoDocQualidade),
          for (final MapEntry(key: tarefa, value: q)
              in conteudo.qualidade.entries)
            pw.Bullet(text: _qualidade(tarefa, q)),
        ],
        _secao(AppStrings.laudoDocCapeV),
        ..._capeV(conteudo.capeV),
        _secao(AppStrings.laudoDocConclusao),
        for (final paragrafo in conteudo.conclusao.split(RegExp(r'\n\s*\n')))
          pw.Paragraph(text: paragrafo.trim(), textAlign: pw.TextAlign.left),
        pw.SizedBox(height: 28),
        _assinatura(conteudo),
      ],
    ),
  );
  return documento.save();
}

pw.TextStyle _corpo(pw.Font regular, pw.Font negrito) => pw.TextStyle(
  font: regular,
  fontBold: negrito,
  fontSize: 10.5,
  lineSpacing: 2,
  color: _texto,
);

// Os tokens do aplicativo, convertidos: o PDF não usa `Color` do Flutter.
PdfColor _cor(Color c) => PdfColor.fromInt(c.toARGB32());
final _roxo = _cor(AppColors.roxoProfundo);
final _lavanda = _cor(AppColors.lavandaClaro);
const _texto = PdfColor.fromInt(0xFF413C58);
const _secundario = PdfColor.fromInt(0xFF6E6787);

pw.Widget _cabecalho(ConteudoDoLaudo conteudo, pw.Context context) =>
    pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _lavanda)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            AppStrings.laudoDocTitulo,
            style: pw.TextStyle(
              fontSize: context.pageNumber == 1 ? 18 : 11,
              fontWeight: pw.FontWeight.bold,
              color: _roxo,
            ),
          ),
          pw.Text(
            AppStrings.appTitle,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
              color: _roxo,
            ),
          ),
        ],
      ),
    );

pw.Widget _rodape(pw.Context context) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 16),
  padding: const pw.EdgeInsets.only(top: 8),
  decoration: pw.BoxDecoration(
    border: pw.Border(top: pw.BorderSide(color: _lavanda)),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Text(
          AppStrings.laudoDocRodape,
          style: const pw.TextStyle(fontSize: 8, color: _secundario),
        ),
      ),
      pw.SizedBox(width: 16),
      pw.Text(
        AppStrings.laudoDocPagina(context.pageNumber, context.pagesCount),
        style: const pw.TextStyle(fontSize: 8, color: _secundario),
      ),
    ],
  ),
);

pw.Widget _faixaDeAviso(String texto) => pw.Container(
  width: double.infinity,
  margin: const pw.EdgeInsets.only(bottom: 10),
  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: pw.BoxDecoration(border: pw.Border.all(color: _roxo, width: 1.5)),
  child: pw.Text(
    texto,
    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _roxo),
  ),
);

pw.Widget _secao(String titulo) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
  child: pw.Text(
    titulo,
    style: pw.TextStyle(
      fontSize: 12.5,
      fontWeight: pw.FontWeight.bold,
      color: _roxo,
    ),
  ),
);

pw.Widget _identificacao(ConteudoDoLaudo c) {
  pw.TableRow linha(String rotulo, String valor) => pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(rotulo, style: const pw.TextStyle(color: _secundario)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(valor),
      ),
    ],
  );

  final nascimento = c.dataDeNascimento;
  final gravacao = c.realizadaEm;
  return pw.Table(
    columnWidths: const {0: pw.FixedColumnWidth(130), 1: pw.FlexColumnWidth()},
    children: [
      linha(AppStrings.laudoDocPaciente, c.nomeDoPaciente),
      linha(
        AppStrings.laudoDocNascimento,
        nascimento == null
            ? AppStrings.laudoDocNaoInformado
            : AppStrings.data(nascimento),
      ),
      linha(AppStrings.laudoDocSexo, _nomeDoSexo(c.sexo)),
      linha(
        AppStrings.laudoDocGravacao,
        gravacao == null
            ? AppStrings.laudoDocNaoInformado
            : '${AppStrings.data(gravacao)}, ${AppStrings.hora(gravacao)}',
      ),
    ],
  );
}

String _nomeDoSexo(SexoDeReferencia? sexo) => switch (sexo) {
  SexoDeReferencia.feminino => AppStrings.cadastroSexoFeminino,
  SexoDeReferencia.masculino => AppStrings.cadastroSexoMasculino,
  SexoDeReferencia.naoInformado || null => AppStrings.laudoDocNaoInformado,
};

String _qualidade(TarefaDeGravacao tarefa, QualidadeDaAmostra q) {
  final nome = _nomeDaTarefa(tarefa);
  if (q.adequada) return AppStrings.resultadoAmostraAdequada(nome);
  final motivo = q.motivo ?? AppStrings.resultadoAmostraSemMotivo;
  return '${AppStrings.resultadoAmostraComProblema(nome)} — $motivo';
}

String _nomeDaTarefa(TarefaDeGravacao t) => switch (t) {
  TarefaDeGravacao.vogalSustentada => AppStrings.tarefaVogalTitulo,
  TarefaDeGravacao.falaEncadeada => AppStrings.tarefaFalaTitulo,
};

pw.Widget _tabela({
  required List<String> cabecalho,
  required List<List<String>> linhas,
  Map<int, pw.TableColumnWidth>? larguras,
}) => pw.TableHelper.fromTextArray(
  headers: cabecalho,
  data: linhas,
  border: pw.TableBorder(
    horizontalInside: pw.BorderSide(color: _lavanda, width: 0.5),
    bottom: pw.BorderSide(color: _lavanda, width: 0.5),
  ),
  headerStyle: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 9.5,
    color: _texto,
  ),
  headerDecoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _roxo)),
  ),
  headerAlignment: pw.Alignment.centerLeft,
  cellAlignment: pw.Alignment.centerLeft,
  cellStyle: const pw.TextStyle(fontSize: 10),
  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
  columnWidths: larguras,
);

pw.Widget _medidas(List<MedidaLida> medidas) => _tabela(
  cabecalho: const [
    AppStrings.laudoDocColunaMedida,
    AppStrings.laudoDocColunaValor,
    AppStrings.laudoDocColunaFaixa,
    AppStrings.laudoDocColunaSituacao,
  ],
  larguras: const {
    0: pw.FlexColumnWidth(2.6),
    1: pw.FlexColumnWidth(1.3),
    2: pw.FlexColumnWidth(2.4),
    3: pw.FlexColumnWidth(1.8),
  },
  linhas: [
    for (final m in medidas)
      [
        '${m.medida.nome} — ${m.medida.descricao}',
        switch (m.valor) {
          null => AppStrings.resultadoNaoCalculada,
          final v when m.medida.unidade.isEmpty => m.medida.formatar(v),
          final v => '${m.medida.formatar(v)} ${m.medida.unidade}',
        },
        switch (m.faixa) {
          null => AppStrings.laudoDocSemFaixa,
          final f =>
            '${m.medida.descreverFaixa(f)}\n'
                '${AppStrings.resultadoProcedencia(f.procedencia)}',
        },
        m.valor == null
            ? AppStrings.laudoDocSemFaixa
            : statusDaClassificacao(m.classificacao).rotulo,
      ],
  ],
);

List<pw.Widget> _capeV(AvaliacaoCapeV? avaliacao) {
  if (avaliacao == null) {
    return [
      pw.Text(
        AppStrings.laudoDocCapeVNaoRegistrada,
        style: const pw.TextStyle(color: _secundario),
      ),
    ];
  }
  return [
    _tabela(
      cabecalho: const [
        AppStrings.laudoDocColunaParametro,
        AppStrings.laudoDocColunaNota,
        AppStrings.laudoDocColunaConsistencia,
        AppStrings.laudoDocColunaSentido,
      ],
      linhas: [
        for (final p in ParametroCapeV.values)
          if (avaliacao.notas[p] case final nota?)
            [
              p.nome,
              '${nota.valor ?? AppStrings.laudoDocSemFaixa}',
              switch (nota.consistencia) {
                null => AppStrings.laudoDocSemFaixa,
                final c => nomeDaConsistencia(c),
              },
              switch (nota.direcao) {
                null => AppStrings.laudoDocSemFaixa,
                final d => p.nomeDaDirecao(d),
              },
            ],
      ],
    ),
    if (avaliacao.comentarios.isNotEmpty) ...[
      pw.SizedBox(height: 6),
      pw.Text('${AppStrings.laudoDocComentarios}: ${avaliacao.comentarios}'),
    ],
  ];
}

pw.Widget _assinatura(ConteudoDoLaudo c) {
  final gerado = c.geradoEm;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(width: 220, height: 0.8, color: _texto),
      pw.SizedBox(height: 4),
      pw.Text(
        c.profissional.nome,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(c.profissional.registro),
      if (gerado != null)
        pw.Text(
          AppStrings.laudoDocGeradoEm(
            AppStrings.data(gerado),
            AppStrings.hora(gerado),
          ),
          style: const pw.TextStyle(fontSize: 9, color: _secundario),
        ),
    ],
  );
}
