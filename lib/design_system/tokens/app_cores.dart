import 'package:flutter/material.dart';

import 'app_colors.dart';

/// As cores da interface por PAPEL, nos dois temas.
///
/// `AppColors` é a paleta: os valores. Esta classe diz para que cada um serve
/// — fundo, cartão, texto, botão, link —, e é o que as telas leem:
///
/// ```dart
/// final cores = context.cores;
/// Container(color: cores.cartao, ...)
/// ```
///
/// No tema claro cada papel recebe exatamente a constante que as telas usavam
/// antes do tema escuro existir, e o claro não mudou em nada. No escuro, o
/// roxo profundo se divide em três papéis — [primaria], [acento] e
/// [lateral] —, porque sobre fundo escuro ele some.
///
/// Uma cor nova de interface entra aqui, com os dois valores e o contraste
/// conferido em `app_colors_test.dart`. Nunca `AppColors.x` direto num
/// widget: a cor ficaria presa ao tema claro.
///
/// Exceção proposital: o PDF do laudo usa `AppColors` direto. É um documento
/// para imprimir e arquivar, e sai sempre em papel branco.
@immutable
class AppCores extends ThemeExtension<AppCores> {
  const AppCores({
    required this.fundo,
    required this.cartao,
    required this.suave,
    required this.lavanda,
    required this.borda,
    required this.texto,
    required this.secundario,
    required this.secundarioSobreLavanda,
    required this.bordaDeCampo,
    required this.primaria,
    required this.primariaHover,
    required this.primariaPressionada,
    required this.sobrePrimaria,
    required this.acento,
    required this.lateral,
    required this.veu,
    required this.sucesso,
    required this.atencao,
    required this.erro,
    required this.sobreErro,
    required this.foco,
    required this.barreira,
    required this.molduraDeImagem,
  });

  /// O fundo principal do aplicativo.
  final Color fundo;

  /// Superfície de card sobre o fundo.
  final Color cartao;

  /// Superfície suave: aviso, selo, campo desabilitado. No claro é
  /// translúcida — ver `AppColors.lavandaSuave`.
  final Color suave;

  /// Preenchimento lavanda: botão desabilitado. Texto por cima usa
  /// [secundarioSobreLavanda].
  final Color lavanda;

  /// Borda e divisória. Decorativa: nenhuma informação depende dela.
  final Color borda;

  /// Texto e títulos, ícones neutros.
  final Color texto;

  /// Texto secundário sobre o fundo, o cartão e a superfície suave.
  final Color secundario;

  /// Texto secundário sobre a lavanda. No claro é um tom próprio; no escuro,
  /// o mesmo de [secundario].
  final Color secundarioSobreLavanda;

  /// Borda de campo de texto e de caixa de marcação: precisa de 3:1 com o
  /// fundo, ao contrário de [borda].
  final Color bordaDeCampo;

  /// Fundo do botão primário e de controle marcado.
  final Color primaria;
  final Color primariaHover;
  final Color primariaPressionada;

  /// Texto e ícone sobre [primaria] e sobre [lateral].
  final Color sobrePrimaria;

  /// Link, ícone de destaque, borda do botão secundário, linha do gráfico.
  final Color acento;

  /// Barra lateral e painel do login.
  final Color lateral;

  /// Hover e fundo de ícone: o acento bem transparente.
  final Color veu;

  // Estado: sempre junto de ícone ou texto.
  final Color sucesso;
  final Color atencao;
  final Color erro;
  final Color sobreErro;

  /// Anel de foco de teclado.
  final Color foco;

  /// O véu atrás de um diálogo.
  final Color barreira;

  /// Moldura de imagem que vem pronta do servidor — o espectrograma. No
  /// escuro, clara, para a imagem não parecer um erro de carregamento; no
  /// claro, nenhuma.
  final Color molduraDeImagem;

  static const claro = AppCores(
    fundo: AppColors.creme,
    cartao: AppColors.branco,
    suave: AppColors.lavandaSuave,
    lavanda: AppColors.lavandaClaro,
    borda: AppColors.lavandaClaro,
    texto: AppColors.cinzaChumbo,
    secundario: AppColors.secundarioSobreCreme,
    secundarioSobreLavanda: AppColors.secundarioSobreLavanda,
    bordaDeCampo: AppColors.cinzaChumbo,
    primaria: AppColors.roxoProfundo,
    primariaHover: AppColors.roxoHover,
    primariaPressionada: AppColors.roxoPressionado,
    sobrePrimaria: AppColors.creme,
    acento: AppColors.roxoProfundo,
    lateral: AppColors.roxoProfundo,
    veu: AppColors.roxoVeu,
    sucesso: AppColors.sucesso,
    atencao: AppColors.atencao,
    erro: AppColors.erro,
    sobreErro: AppColors.branco,
    foco: AppColors.foco,
    barreira: Color(0x66413C58),
    molduraDeImagem: Color(0x00000000),
  );

  static const escuro = AppCores(
    fundo: AppColors.escuroFundo,
    cartao: AppColors.escuroCartao,
    suave: AppColors.escuroSuave,
    lavanda: AppColors.escuroLavanda,
    borda: AppColors.escuroBorda,
    texto: AppColors.escuroTexto,
    secundario: AppColors.escuroSecundario,
    secundarioSobreLavanda: AppColors.escuroSecundario,
    bordaDeCampo: AppColors.escuroSecundario,
    primaria: AppColors.escuroPrimaria,
    primariaHover: AppColors.escuroPrimariaHover,
    primariaPressionada: AppColors.escuroPrimariaPressionada,
    sobrePrimaria: AppColors.escuroTexto,
    acento: AppColors.escuroAcento,
    lateral: AppColors.escuroLateral,
    veu: AppColors.escuroVeu,
    sucesso: AppColors.escuroSucesso,
    atencao: AppColors.escuroAtencao,
    erro: AppColors.escuroErro,
    sobreErro: AppColors.escuroSobreErro,
    foco: AppColors.escuroFoco,
    barreira: Color(0x99000000),
    molduraDeImagem: AppColors.escuroTexto,
  );

  /// As cores do tema em volta. Sem tema do FONAR — num teste que monta o
  /// widget solto, por exemplo —, as do claro.
  static AppCores de(BuildContext context) =>
      Theme.of(context).extension<AppCores>() ?? claro;

  /// O tom de texto secundário certo para [fundo] — ver `AppFundo`.
  Color secundarioSobre(FundoDeTexto fundo) => switch (fundo) {
    FundoDeTexto.creme => secundario,
    FundoDeTexto.lavanda => secundarioSobreLavanda,
  };

  @override
  AppCores copyWith() => this;

  /// Sem transição entre os temas: a troca é imediata, como pede o respeito
  /// ao movimento reduzido — e ninguém precisa ver cor intermediária.
  @override
  AppCores lerp(AppCores? outro, double t) =>
      outro == null || t < 0.5 ? this : outro;
}

/// `context.cores`: as cores do tema em volta.
extension CoresDoTema on BuildContext {
  AppCores get cores => AppCores.de(this);
}
