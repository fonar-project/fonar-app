import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import 'app_fundo.dart';

/// Área clicável que não é botão: linha de lista, card, item de navegação.
///
/// Existe pelo anel de foco. O `InkWell` puro marca o foco com um véu de 7% do
/// tema — invisível para quem navega por teclado no Windows, e navegação por
/// teclado é requisito. Aqui o foco desenha um anel de 3 px por cima do
/// conteúdo, sem mexer no layout.
///
/// ## O véu de hover muda o fundo, e o fundo escolhe o tom do texto
///
/// Enquanto o ponteiro está em cima — ou enquanto está pressionado — o
/// `InkWell` pinta [corDoHover] por cima da superfície, e o conteúdo passa a
/// estar desenhado sobre outra cor. QUALQUER véu escurece: o creme puro dá
/// 5,00:1 para `secundarioSobreCreme`, e com o roxo a 7% em cima a mesma dupla
/// cai para 4,35:1 — reprova em AA para texto pequeno, exatamente enquanto o
/// profissional está com o cursor na linha que quer ler.
///
/// Por isso o `AppToque` declara [FundoDeTexto.lavanda] para os componentes
/// abaixo dele durante o hover: é o fundo "tingido" da paleta, e o tom escuro
/// do par (`secundarioSobreLavanda`) é o que passa sobre o véu. Em repouso
/// nada é declarado, e o fundo volta a ser o de quem estiver em volta.
///
/// Quem desenha texto secundário dentro de um `AppToque` precisa pedir o tom
/// pelo fundo (`AppFundo.secundarioDe(context)`), e não fixar
/// `AppColors.secundarioSobreCreme`: token fixo não sabe que ficou com um véu
/// em cima.
///
/// É por isso que o conteúdo entra como [conteudo], uma função, e não como um
/// `child` pronto: o `AppFundo` é um `InheritedWidget`, e só quem lê o
/// `BuildContext` de DENTRO dele recebe a declaração. Um `child` montado pelo
/// chamador já traz a cor resolvida no contexto de fora — que é o creme — e o
/// hover não teria como corrigi-la. O parâmetro ser uma função tira a
/// possibilidade de errar isso sem perceber.
class AppToque extends StatefulWidget {
  const AppToque({
    required this.aoTocar,
    required this.conteudo,
    this.corDoFoco = AppColors.foco,
    this.corDoHover = AppColors.roxoVeu,
    this.raio = BorderRadius.zero,
    this.selecionado,
    super.key,
  });

  final VoidCallback aoTocar;

  /// O conteúdo clicável. Recebe um `BuildContext` de dentro do `AppFundo`
  /// declarado durante o hover — use ESSE contexto para qualquer cor que
  /// dependa do fundo. Ver a documentação da classe.
  final Widget Function(BuildContext context) conteudo;

  /// Sobre fundo roxo o azul de foco some; ali, passe [AppColors.creme].
  final Color corDoFoco;

  final Color corDoHover;
  final BorderRadius raio;

  /// Para itens de navegação: anuncia ao leitor de tela qual está ativo.
  final bool? selecionado;

  @override
  State<AppToque> createState() => _AppToqueState();
}

class _AppToqueState extends State<AppToque> {
  var _focado = false;
  var _sobre = false;
  var _pressionado = false;

  /// O véu está pintado? Vale para hover e para pressionado: os dois usam
  /// [AppToque.corDoHover], e os dois escurecem o fundo do conteúdo.
  bool get _comVeu => _sobre || _pressionado;

  @override
  Widget build(BuildContext context) {
    Widget moldura(BuildContext context) => DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.raio,
        border: _focado ? Border.all(color: widget.corDoFoco, width: 3) : null,
      ),
      child: widget.conteudo(context),
    );

    return Semantics(
      button: true,
      selected: widget.selecionado,
      child: InkWell(
        onTap: widget.aoTocar,
        onFocusChange: (focado) => setState(() => _focado = focado),
        onHover: (sobre) => setState(() => _sobre = sobre),
        onHighlightChanged: (pressionado) =>
            setState(() => _pressionado = pressionado),
        borderRadius: widget.raio,
        focusColor: Colors.transparent,
        hoverColor: widget.corDoHover,
        highlightColor: widget.corDoHover,
        splashFactory: NoSplash.splashFactory,
        child: _comVeu
            ? AppFundo(
                fundo: FundoDeTexto.lavanda,
                child: Builder(builder: moldura),
              )
            : Builder(builder: moldura),
      ),
    );
  }
}
