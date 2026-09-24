import 'package:flutter/material.dart';

import '../../../../core/formatacao/mascara_de_data.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/novo_paciente.dart';
import '../cadastro_paciente_controlador.dart';

/// Os campos do paciente — nome, nascimento, sexo e queixa —, os mesmos no
/// cadastro e na correção dos dados.
///
/// Só os campos: os valores ficam nos controles de quem usa, e o que salvar
/// e para onde ir depois também.
class CamposDoPaciente extends StatelessWidget {
  const CamposDoPaciente({
    required this.nome,
    required this.nascimento,
    required this.queixa,
    required this.focoNome,
    required this.focoNascimento,
    required this.focoQueixa,
    required this.sexo,
    required this.aoEscolherSexo,
    required this.estado,
    required this.aoEditar,
    required this.aoConcluir,
    super.key,
  });

  final TextEditingController nome;
  final TextEditingController nascimento;
  final TextEditingController queixa;
  final FocusNode focoNome;
  final FocusNode focoNascimento;
  final FocusNode focoQueixa;
  final SexoDeReferencia? sexo;
  final ValueChanged<SexoDeReferencia> aoEscolherSexo;

  /// Os erros de cada campo, e se está salvando.
  final EstadoCadastro estado;
  final ValueChanged<CampoDoCadastro> aoEditar;

  /// "Concluir" no teclado, no último campo.
  final VoidCallback aoConcluir;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCampoTexto(
        rotulo: AppStrings.cadastroCampoNome,
        controlador: nome,
        foco: focoNome,
        erro: estado.erroNome,
        somenteLeitura: estado.salvando,
        tipoDeTeclado: TextInputType.name,
        acaoDeEntrada: TextInputAction.next,
        aoMudar: (_) => aoEditar(CampoDoCadastro.nome),
        aoEnviar: (_) => focoNascimento.requestFocus(),
        // Nome próprio: o corretor troca "Thaís" por "Taís" sem pedir.
        autoCorrecao: false,
        capitalizacao: TextCapitalization.words,
      ),
      const SizedBox(height: AppSpacing.md),
      AppCampoTexto(
        rotulo: AppStrings.cadastroCampoNascimento,
        controlador: nascimento,
        foco: focoNascimento,
        dica: AppStrings.cadastroNascimentoDica,
        erro: estado.erroNascimento,
        somenteLeitura: estado.salvando,
        tipoDeTeclado: TextInputType.number,
        acaoDeEntrada: TextInputAction.next,
        aoMudar: (_) => aoEditar(CampoDoCadastro.nascimento),
        aoEnviar: (_) => focoQueixa.requestFocus(),
        autoCorrecao: false,
        formatadores: const [MascaraDeData()],
      ),
      const SizedBox(height: AppSpacing.md),
      AppEscolhaUnica<SexoDeReferencia>(
        rotulo: AppStrings.cadastroCampoSexo,
        opcoes: const [
          AppOpcao(
            valor: SexoDeReferencia.feminino,
            rotulo: AppStrings.cadastroSexoFeminino,
          ),
          AppOpcao(
            valor: SexoDeReferencia.masculino,
            rotulo: AppStrings.cadastroSexoMasculino,
          ),
          AppOpcao(
            valor: SexoDeReferencia.naoInformado,
            rotulo: AppStrings.cadastroSexoNaoInformado,
          ),
        ],
        selecionado: sexo,
        aoEscolher: estado.salvando
            ? null
            : (escolhido) {
                aoEscolherSexo(escolhido);
                aoEditar(CampoDoCadastro.sexo);
              },
        erro: estado.erroSexo,
        apoio: AppStrings.cadastroSexoApoio,
      ),
      const SizedBox(height: AppSpacing.md),
      AppCampoTexto(
        rotulo: AppStrings.cadastroCampoQueixa,
        controlador: queixa,
        foco: focoQueixa,
        dica: AppStrings.cadastroQueixaDica,
        erro: estado.erroQueixa,
        somenteLeitura: estado.salvando,
        acaoDeEntrada: TextInputAction.done,
        aoMudar: (_) => aoEditar(CampoDoCadastro.queixa),
        aoEnviar: (_) => aoConcluir(),
        capitalizacao: TextCapitalization.sentences,
      ),
    ],
  );
}

/// O primeiro campo com erro que tem teclado, para levar o foco até ele.
///
/// No celular, com o teclado aberto, o erro do nome fica fora da tela depois
/// de tocar em "Salvar" lá embaixo; focar o campo rola até ele. O sexo é
/// escolha por toque: com erro nele, o foco não pula para a queixa.
FocusNode? primeiroCampoComErro(
  EstadoCadastro estado, {
  required FocusNode nome,
  required FocusNode nascimento,
  required FocusNode queixa,
}) => switch (estado) {
  EstadoCadastro(erroNome: _?) => nome,
  EstadoCadastro(erroNascimento: _?) => nascimento,
  EstadoCadastro(erroQueixa: _?) when estado.erroSexo == null => queixa,
  _ => null,
};
