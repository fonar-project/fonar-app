import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';

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
class AppCampoTexto extends StatelessWidget {
  const AppCampoTexto({
    required this.rotulo,
    this.controlador,
    this.dica,
    this.erro,
    this.apoio,
    this.habilitado = true,
    this.ocultarTexto = false,
    this.tipoDeTeclado,
    this.acaoDeEntrada,
    this.aoMudar,
    this.aoEnviar,
    this.foco,
    this.autoCorrecao = true,
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
  final bool ocultarTexto;
  final TextInputType? tipoDeTeclado;
  final TextInputAction? acaoDeEntrada;
  final ValueChanged<String>? aoMudar;
  final ValueChanged<String>? aoEnviar;
  final FocusNode? foco;

  /// Desligue em campo de e-mail, senha e identificador clínico: a correção
  /// automática do teclado troca palavra que o usuário digitou de propósito.
  final bool autoCorrecao;

  bool get _temErro => erro != null && erro!.isNotEmpty;

  static const _bordaDeErro = OutlineInputBorder(
    borderRadius: AppRadius.bordaMedia,
    borderSide: BorderSide(color: AppColors.erro, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corDoRotulo = habilitado
        ? AppColors.cinzaChumbo
        : AppColors.secundarioSobreCreme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rotulo,
          style: tema.textTheme.labelMedium?.copyWith(color: corDoRotulo),
        ),
        const SizedBox(height: AppSpacing.xxs + 2),
        TextField(
          controller: controlador,
          focusNode: foco,
          enabled: habilitado,
          obscureText: ocultarTexto,
          autocorrect: autoCorrecao,
          enableSuggestions: autoCorrecao,
          keyboardType: tipoDeTeclado,
          textInputAction: acaoDeEntrada,
          onChanged: aoMudar,
          onSubmitted: aoEnviar,
          style: tema.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: tema.textTheme.bodyMedium?.copyWith(
              color: AppColors.secundarioSobreCreme,
            ),
            fillColor: habilitado
                ? AppColors.branco
                : AppColors.lavandaClaro.withValues(alpha: 0.35),
            // A mensagem de erro é desenhada abaixo deste widget, com ícone —
            // não pelo `errorText` do Material, que é só texto vermelho. Aqui
            // fica apenas a borda, e ela é sobrescrita à mão em vez de deixar
            // o campo entrar no estado de erro do Material: assim o espaço da
            // mensagem não é reservado duas vezes.
            enabledBorder: _temErro ? _bordaDeErro : null,
            focusedBorder: _temErro ? _bordaDeErro : null,
          ),
        ),
        if (_temErro)
          _Mensagem(
            texto: erro!,
            cor: AppColors.erro,
            icone: NomeIcone.alerta,
            ehErro: true,
          )
        else if (apoio != null)
          _Mensagem(texto: apoio!, cor: AppColors.secundarioSobreCreme),
      ],
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.texto,
    required this.cor,
    this.icone,
    this.ehErro = false,
  });

  final String texto;
  final Color cor;
  final NomeIcone? icone;
  final bool ehErro;

  @override
  Widget build(BuildContext context) {
    final linha = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icone != null) ...[
            AppIcone(nome: icone!, cor: cor, tamanho: 16),
            const SizedBox(width: AppSpacing.xxs + 2),
          ],
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );

    // `liveRegion` faz o leitor de tela anunciar o erro no momento em que ele
    // aparece, em vez de esperar o usuário voltar o foco ao campo.
    return Semantics(
      liveRegion: ehErro,
      child: MergeSemantics(child: linha),
    );
  }
}
