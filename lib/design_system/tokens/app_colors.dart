import 'package:flutter/material.dart';

/// Tokens de cor do FONAR.
///
/// A paleta é fechada: quatro cores de marca mais um conjunto pequeno de
/// derivados. **Nunca introduza cor nova** — se algo precisa de um tom que não
/// está aqui, ou o design está errado ou falta um token, e os dois casos se
/// resolvem conversando, não escrevendo `Color(0xFF...)` dentro de um widget.
///
/// Verde, amarelo e vermelho são reservados EXCLUSIVAMENTE para status de
/// normalidade de medida e saturação de áudio. Nunca como decoração.
///
/// Regra de acessibilidade do projeto: nenhuma informação crítica pode ser
/// comunicada apenas por cor. Estado sempre acompanha ícone, texto ou forma.
abstract final class AppColors {
  // ------------------------------------------------------------- marca --

  /// Fundo principal do aplicativo.
  static const creme = Color(0xFFFFF7EB);

  /// Primária: botões, cabeçalho, gráficos, links.
  static const roxoProfundo = Color(0xFF40085E);

  /// Textos e títulos sobre fundos claros.
  static const cinzaChumbo = Color(0xFF413C58);

  /// Bordas, faixas e cards secundários, divisórias, estados desabilitados.
  static const lavandaClaro = Color(0xFFDBD2E0);

  // --------------------------------------------------- derivados do roxo --

  /// Hover do roxo. Só para superfície de controle, nunca para texto.
  static const roxoHover = Color(0xFF53187A);

  /// Pressionado.
  static const roxoPressionado = Color(0xFF2E0345);

  /// Fundo de ícone, hover de botão secundário. Roxo a 7%.
  static const roxoVeu = Color(0x1240085E);

  /// Superfície neutra de card sobre o creme.
  static const branco = Color(0xFFFFFFFF);

  /// Superfície suave de aviso e de campo desabilitado. Lavanda a 35%.
  ///
  /// Translúcida: a cor final depende do que está atrás. Sobre o creme ela
  /// resulta em `#F2EAE7`, e é nesse fundo que o contraste de texto precisa
  /// ser conferido — ver `app_colors_test.dart`.
  static const lavandaSuave = Color(0x59DBD2E0);

  // ------------------------------------------------ texto secundário --

  /// Texto secundário SOBRE CREME. Contraste 5,00:1.
  ///
  /// Sobre lavanda este mesmo tom cai para 3,62:1 e reprova em AA para texto
  /// pequeno — nesse fundo use [secundarioSobreLavanda]. São dois tokens
  /// porque são dois problemas diferentes, não por preciosismo.
  static const secundarioSobreCreme = Color(0xFF6E6787);

  /// Texto secundário SOBRE LAVANDA. Contraste 4,86:1.
  static const secundarioSobreLavanda = Color(0xFF5A5472);

  // ------------------------------------------------------------ estado --
  // Usar SEMPRE junto de ícone ou rótulo. Ver [AppColors] no topo.

  static const sucesso = Color(0xFF1B6B3A);
  static const atencao = Color(0xFF8A5A00);
  static const erro = Color(0xFFB3261E);

  /// Indicador de foco de teclado, em TODO controle interativo. Navegação por
  /// teclado é requisito no Windows.
  ///
  /// É azul, fora da paleta, de propósito: foco precisa se destacar de tudo o
  /// que a tela já pinta de roxo. A landing page usa um anel roxo translúcido;
  /// no aplicativo, com botão roxo sobre cabeçalho roxo, esse anel sumiria.
  static const foco = Color(0xFF0B57D0);

  /// Semente do Material 3. O restante do esquema é derivado dela, mas os
  /// componentes do design system usam os tokens acima diretamente: o
  /// `ColorScheme.fromSeed` gera tons harmônicos que NÃO são a paleta da
  /// marca, e deixar um botão escolher por conta própria já rendeu roxo
  /// errado em protótipo antes.
  static const semente = roxoProfundo;
}
