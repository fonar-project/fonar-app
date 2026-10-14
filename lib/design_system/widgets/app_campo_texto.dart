import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_cores.dart';
import '../tokens/app_spacing.dart';
import 'app_fundo.dart';
import 'app_icone.dart';
import 'app_mensagem_de_campo.dart';

/// Campo de texto do design system.
///
/// O rótulo fica ACIMA do campo, sempre visível — não é `placeholder` nem
/// rótulo flutuante. Placeholder some quando o usuário digita, e aí um campo
/// preenchido pela metade não diz mais o que é. Em formulário de paciente,
/// preenchido com pressa, isso vira dado no lugar errado.
///
/// ## Erro nunca é só a borda vermelha
///
/// Quando [erro] vem preenchido, aparecem borda, ícone e mensagem de texto
/// juntos, e a mensagem diz o que fazer, não só o que está errado. Borda
/// colorida sozinha é invisível para parte dos usuários e ambígua para o
/// resto.
///
/// ## Senha: o olho (US46)
///
/// Com [ocultarTexto], o campo traz no fim um botão de olho que mostra e
/// volta a esconder o que foi digitado — quem digita com pressa, com o
/// paciente ao lado, confere a senha antes de errar e esperar. Começa sempre
/// escondida. O botão fica fora da árvore de semântica, porque o campo funde
/// rótulo e entrada num nó só (ver o `MergeSemantics` abaixo) e o botão
/// fundido viraria parte da caixa de edição; para o leitor de tela, mostrar e
/// esconder é uma AÇÃO do próprio campo, com o mesmo nome do botão. Pelo
/// teclado, o botão continua alcançável com Tab.
class AppCampoTexto extends StatefulWidget {
  const AppCampoTexto({
    required this.rotulo,
    this.controlador,
    this.dica,
    this.erro,
    this.apoio,
    this.habilitado = true,
    this.somenteLeitura = false,
    this.ocultarTexto = false,
    this.tipoDeTeclado,
    this.acaoDeEntrada,
    this.aoMudar,
    this.aoEnviar,
    this.foco,
    this.autoCorrecao = true,
    this.autopreenchimento,
    this.formatadores,
    this.capitalizacao = TextCapitalization.none,
    this.linhas = 1,
    super.key,
  });

  /// Nome do campo. Exibido acima e usado como rótulo semântico.
  final String rotulo;

  final TextEditingController? controlador;

  /// Exemplo do formato esperado. Nunca substitui o [rotulo].
  final String? dica;

  /// Mensagem de erro. Preenchida, coloca o campo em estado de erro.
  final String? erro;

  /// Texto de apoio permanente, abaixo do campo. Oculto enquanto houver
  /// [erro] — duas mensagens embaixo do mesmo campo competem por atenção.
  final String? apoio;

  final bool habilitado;

  /// Mantém o foco e o visual normal, mas não aceita edição. Para esperas
  /// curtas, como o envio de um formulário: desabilitar faria o campo piscar
  /// em lavanda e perder o foco de teclado a cada tentativa.
  final bool somenteLeitura;
  final bool ocultarTexto;
  final TextInputType? tipoDeTeclado;
  final TextInputAction? acaoDeEntrada;
  final ValueChanged<String>? aoMudar;
  final ValueChanged<String>? aoEnviar;
  final FocusNode? foco;

  /// Desligue em campo de e-mail, senha e identificador clínico: a correção
  /// automática do teclado troca palavra que o usuário digitou de propósito.
  final bool autoCorrecao;

  /// Dicas para o gerenciador de senhas e o autopreenchimento do sistema, ex.:
  /// `[AutofillHints.email]`. No desktop do consultório é o que evita digitar
  /// a senha inteira toda manhã.
  final Iterable<String>? autopreenchimento;

  /// Máscara aplicada enquanto se digita — ex.: as barras da data.
  final List<TextInputFormatter>? formatadores;

  /// Maiúscula automática do teclado do celular. `words` em nome próprio,
  /// `sentences` em texto livre.
  final TextCapitalization capitalizacao;

  /// Mais de uma para texto livre (comentários): o campo nasce com essa
  /// altura e cresce até o dobro antes de rolar.
  final int linhas;

  @override
  State<AppCampoTexto> createState() => _AppCampoTextoState();
}

class _AppCampoTextoState extends State<AppCampoTexto> {
  /// A senha está à mostra? Só o profissional a mostra, pelo olho.
  var _senhaAMostra = false;

  bool get _temErro => widget.erro != null && widget.erro!.isNotEmpty;

  void _alternarSenha() => setState(() => _senhaAMostra = !_senhaAMostra);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final erro = widget.erro;
    final habilitado = widget.habilitado;
    // O olho só existe em campo de senha que se pode usar.
    final comOlho = widget.ocultarTexto && habilitado;
    final rotuloDoOlho = _senhaAMostra
        ? AppStrings.campoOcultarSenha
        : AppStrings.campoMostrarSenha;

    // Dois fundos diferentes, e por isso dois tons de texto secundário.
    //
    // Fora da caixa — rótulo em cima, apoio embaixo — quem está atrás é a
    // superfície da tela. DENTRO da caixa, o campo desabilitado se pinta de
    // `lavandaSuave`, e ali o token "sobre creme" cai para 4,48:1 e reprova
    // em AA. Ver `app_colors_test.dart`.
    final fundoDaTela = AppFundo.de(context);
    final fundoDaCaixa = habilitado ? fundoDaTela : FundoDeTexto.lavanda;
    final corSecundaria = context.cores.secundarioSobre(fundoDaTela);
    final corDoRotulo = habilitado ? context.cores.texto : corSecundaria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // MergeSemantics funde o rótulo visual e o campo num nó só: sem
        // isso, o leitor de tela chega no campo e anuncia "caixa de edição",
        // sem nome. O rótulo em cima é só visual; quem o liga à entrada é
        // esta fusão.
        MergeSemantics(
          child: Semantics(
            customSemanticsActions: comOlho
                ? {CustomSemanticsAction(label: rotuloDoOlho): _alternarSenha}
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.rotulo,
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: corDoRotulo,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs + 2),
                TextField(
                  controller: widget.controlador,
                  focusNode: widget.foco,
                  enabled: habilitado,
                  readOnly: widget.somenteLeitura,
                  obscureText: widget.ocultarTexto && !_senhaAMostra,
                  autocorrect: widget.autoCorrecao,
                  enableSuggestions: widget.autoCorrecao,
                  autofillHints: widget.autopreenchimento,
                  inputFormatters: widget.formatadores,
                  textCapitalization: widget.capitalizacao,
                  minLines: widget.linhas,
                  maxLines: widget.linhas == 1 ? 1 : widget.linhas * 2,
                  keyboardType: widget.tipoDeTeclado,
                  textInputAction: widget.acaoDeEntrada,
                  onChanged: widget.aoMudar,
                  onSubmitted: widget.aoEnviar,
                  style: tema.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.dica,
                    hintStyle: tema.textTheme.bodyMedium?.copyWith(
                      color: context.cores.secundarioSobre(fundoDaCaixa),
                    ),
                    filled: !habilitado,
                    fillColor: context.cores.suave,
                    // A mensagem de erro é desenhada abaixo, com ícone — não
                    // pelo `errorText` do Material, que é só texto vermelho.
                    // Aqui fica apenas a borda. O foco continua azul mesmo
                    // com erro: ele diz ONDE o teclado está, e o erro já está
                    // dito em texto logo abaixo.
                    enabledBorder: _temErro
                        ? Theme.of(context).inputDecorationTheme.errorBorder
                        : null,
                    suffixIcon: comOlho
                        ? ExcludeSemantics(
                            child: IconButton(
                              onPressed: _alternarSenha,
                              tooltip: rotuloDoOlho,
                              icon: AppIcone(
                                nome: _senhaAMostra
                                    ? NomeIcone.ocultarSenha
                                    : NomeIcone.mostrarSenha,
                                cor: corSecundaria,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        AppMensagemDeCampo(
          erro: _temErro ? erro : null,
          apoio: widget.apoio,
          corDoApoio: corSecundaria,
        ),
      ],
    );
  }
}
