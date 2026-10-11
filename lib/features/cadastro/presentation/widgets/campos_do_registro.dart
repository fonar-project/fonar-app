import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_caixa_de_marcacao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/cadastro.dart';

/// Nome, região do Crefono, número de inscrição e o aceite dos termos — o
/// que o profissional informa ao criar a conta e ao completar o cadastro.
///
/// A região é escolha visível de uma vez (nove opções curtas), e o número é
/// só o número: "CRFa 2-12345" se monta dos dois.
class CamposDoRegistro extends StatelessWidget {
  const CamposDoRegistro({
    required this.nome,
    required this.inscricao,
    required this.regiao,
    required this.aceitouTermos,
    required this.aoEscolherRegiao,
    required this.aoMarcarTermos,
    required this.aoEditar,
    required this.erroDe,
    required this.ocupado,
    this.aoEnviar,
    super.key,
  });

  final TextEditingController nome;
  final TextEditingController inscricao;
  final int? regiao;
  final bool aceitouTermos;
  final ValueChanged<int> aoEscolherRegiao;
  final ValueChanged<bool> aoMarcarTermos;

  /// O campo mudou: o erro dele sai.
  final ValueChanged<CampoDoCadastro> aoEditar;
  final String? Function(CampoDoCadastro) erroDe;

  /// Enquanto o formulário é enviado, nada se edita.
  final bool ocupado;

  /// Enter no último campo de texto.
  final VoidCallback? aoEnviar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCampoTexto(
          rotulo: AppStrings.cadastroCampoNome,
          apoio: AppStrings.cadastroNomeApoio,
          controlador: nome,
          erro: erroDe(CampoDoCadastro.nome),
          somenteLeitura: ocupado,
          capitalizacao: TextCapitalization.words,
          autoCorrecao: false,
          acaoDeEntrada: TextInputAction.next,
          autopreenchimento: const [AutofillHints.name],
          aoMudar: (_) => aoEditar(CampoDoCadastro.nome),
        ),
        const SizedBox(height: AppSpacing.md),
        AppEscolhaUnica<int>(
          rotulo: AppStrings.cadastroCampoRegiao,
          opcoes: [
            for (final r in regioesDoCrefono)
              AppOpcao(valor: r, rotulo: AppStrings.cadastroRegiao(r)),
          ],
          selecionado: regiao,
          aoEscolher: ocupado
              ? null
              : (r) {
                  aoEditar(CampoDoCadastro.regiao);
                  aoEscolherRegiao(r);
                },
          erro: erroDe(CampoDoCadastro.regiao),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCampoTexto(
          rotulo: AppStrings.cadastroCampoInscricao,
          dica: AppStrings.cadastroInscricaoDica,
          apoio: AppStrings.cadastroInscricaoApoio,
          controlador: inscricao,
          erro: erroDe(CampoDoCadastro.inscricao),
          somenteLeitura: ocupado,
          tipoDeTeclado: TextInputType.number,
          autoCorrecao: false,
          acaoDeEntrada: TextInputAction.done,
          aoEnviar: aoEnviar == null ? null : (_) => aoEnviar!(),
          aoMudar: (_) => aoEditar(CampoDoCadastro.inscricao),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.cadastroTermosTexto,
          style: textos.bodySmall?.copyWith(color: context.cores.secundario),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCaixaDeMarcacao(
          rotulo: AppStrings.cadastroTermosRotulo,
          marcada: aceitouTermos,
          aoMudar: ocupado
              ? null
              : (marcada) {
                  aoEditar(CampoDoCadastro.termos);
                  aoMarcarTermos(marcada);
                },
          erro: erroDe(CampoDoCadastro.termos),
        ),
      ],
    );
  }
}

/// Título de seção de um formulário da entrada.
class TituloDaSecao extends StatelessWidget {
  const TituloDaSecao(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
