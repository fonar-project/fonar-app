import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_estrutura.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/formatacao/mascara_de_data.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_secao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_mensagem_de_campo.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/novo_paciente.dart';
import '../cadastro_paciente_controlador.dart';

/// Tela 02 — perfil do paciente novo, primeiro passo da nova avaliação.
///
/// Depois de salvar, segue direto para o consentimento do paciente recém-
/// criado: sem consentimento registrado a gravação não abre, então esse é
/// sempre o próximo passo. A navegação é `go`, não `push` — voltar do
/// consentimento leva ao paciente, não de volta a este formulário, onde um
/// segundo "Salvar" cadastraria a mesma pessoa duas vezes.
///
/// Funciona sem conexão: o cadastro fica no aparelho e sincroniza depois.
///
/// Uma coluna em qualquer largura, com teto de largura no desktop. Formulário
/// em duas colunas obriga o olho a zigue-zaguear, e com o paciente ao lado o
/// profissional preenche de cima para baixo sem procurar o próximo campo.
///
/// TODO(equipe): decisões tomadas sem o protótipo da tela 02, a confirmar:
/// - queixa principal obrigatória (a lista de pacientes sempre a mostra);
/// - salvar segue direto para o consentimento, e não para o perfil.
/// Faltam também: aviso de paciente possivelmente duplicado (mesmo nome e
/// data de nascimento) e aviso ao sair com o formulário preenchido.
class NovoPacientePage extends ConsumerStatefulWidget {
  const NovoPacientePage({super.key});

  @override
  ConsumerState<NovoPacientePage> createState() => _NovoPacientePageState();
}

class _NovoPacientePageState extends ConsumerState<NovoPacientePage> {
  final _nome = TextEditingController();
  final _nascimento = TextEditingController();
  final _queixa = TextEditingController();
  final _focoNome = FocusNode();
  final _focoNascimento = FocusNode();
  final _focoQueixa = FocusNode();
  SexoDeReferencia? _sexo;

  @override
  void dispose() {
    _nome.dispose();
    _nascimento.dispose();
    _queixa.dispose();
    _focoNome.dispose();
    _focoNascimento.dispose();
    _focoQueixa.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final paciente = await ref
        .read(cadastroPacienteControladorProvider.notifier)
        .salvar(
          nome: _nome.text,
          nascimento: _nascimento.text,
          sexo: _sexo,
          queixa: _queixa.text,
        );
    if (!mounted) return;

    if (paciente != null) {
      context.goNamed(
        AppRoutes.consentimentoNome,
        pathParameters: {AppRoutes.paramPacienteId: paciente.id},
      );
      return;
    }
    _focarPrimeiroErro();
  }

  /// Leva o teclado ao primeiro campo com erro. No celular, com o teclado
  /// aberto, o erro do nome fica fora da tela depois de tocar em "Salvar" lá
  /// embaixo; focar o campo rola até ele.
  void _focarPrimeiroErro() {
    final estado = ref.read(cadastroPacienteControladorProvider);
    final foco = switch (estado) {
      EstadoCadastro(erroNome: _?) => _focoNome,
      EstadoCadastro(erroNascimento: _?) => _focoNascimento,
      EstadoCadastro(erroQueixa: _?) when estado.erroSexo == null =>
        _focoQueixa,
      _ => null,
    };
    foco?.requestFocus();
  }

  void _cancelar() => context.goNamed(AppRoutes.pacientesNome);

  void _editou(CampoDoCadastro campo) =>
      ref.read(cadastroPacienteControladorProvider.notifier).editou(campo);

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(cadastroPacienteControladorProvider);
    final textos = Theme.of(context).textTheme;

    final formulario = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.cadastroDescricao,
          style: textos.bodyMedium?.copyWith(
            color: AppColors.secundarioSobreCreme,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCampoTexto(
          rotulo: AppStrings.cadastroCampoNome,
          controlador: _nome,
          foco: _focoNome,
          erro: estado.erroNome,
          somenteLeitura: estado.salvando,
          tipoDeTeclado: TextInputType.name,
          acaoDeEntrada: TextInputAction.next,
          aoMudar: (_) => _editou(CampoDoCadastro.nome),
          aoEnviar: (_) => _focoNascimento.requestFocus(),
          // Nome próprio: o corretor troca "Thaís" por "Taís" sem pedir.
          autoCorrecao: false,
          capitalizacao: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCampoTexto(
          rotulo: AppStrings.cadastroCampoNascimento,
          controlador: _nascimento,
          foco: _focoNascimento,
          dica: AppStrings.cadastroNascimentoDica,
          erro: estado.erroNascimento,
          somenteLeitura: estado.salvando,
          tipoDeTeclado: TextInputType.number,
          acaoDeEntrada: TextInputAction.next,
          aoMudar: (_) => _editou(CampoDoCadastro.nascimento),
          aoEnviar: (_) => _focoQueixa.requestFocus(),
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
          selecionado: _sexo,
          aoEscolher: estado.salvando
              ? null
              : (sexo) {
                  setState(() => _sexo = sexo);
                  _editou(CampoDoCadastro.sexo);
                },
          erro: estado.erroSexo,
          apoio: AppStrings.cadastroSexoApoio,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCampoTexto(
          rotulo: AppStrings.cadastroCampoQueixa,
          controlador: _queixa,
          foco: _focoQueixa,
          dica: AppStrings.cadastroQueixaDica,
          erro: estado.erroQueixa,
          somenteLeitura: estado.salvando,
          acaoDeEntrada: TextInputAction.done,
          aoMudar: (_) => _editou(CampoDoCadastro.queixa),
          aoEnviar: (_) => _salvar(),
          capitalizacao: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.cadastroSalvoNoAparelho,
          style: textos.bodySmall?.copyWith(
            color: AppColors.secundarioSobreCreme,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Acoes(
          salvando: estado.salvando,
          aoSalvar: _salvar,
          aoCancelar: _cancelar,
        ),
        // Falha que não é de um campo: o aparelho não conseguiu salvar.
        AppMensagemDeCampo(
          erro: estado.erroGeral,
          corDoApoio: AppColors.secundarioSobreCreme,
        ),
      ],
    );

    return AppEstrutura(
      destino: DestinoPrincipal.novaAvaliacao,
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final largura = Breakpoints.de(restricoes.maxWidth);
          final compacta = largura == LarguraDeTela.compacta;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCabecalhoDeSecao(
                titulo: AppStrings.cadastroTitulo,
                largura: largura,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      // Campo de nome com 1200 px de largura é difícil de ler
                      // e de mirar; o formulário para numa largura de leitura.
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: formulario,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Salvar e cancelar. No celular, empilhados e com a largura toda, o principal
/// em cima, ao alcance do polegar; com espaço, lado a lado à direita, o
/// principal por último, onde o olho termina a leitura do formulário.
class _Acoes extends StatelessWidget {
  const _Acoes({
    required this.salvando,
    required this.aoSalvar,
    required this.aoCancelar,
  });

  final bool salvando;
  final VoidCallback aoSalvar;
  final VoidCallback aoCancelar;

  @override
  Widget build(BuildContext context) {
    // O botão continua habilitado enquanto salva, só com outro rótulo: o
    // controlador já ignora o segundo toque, e desabilitar exigiria um motivo
    // escrito para um estado que dura uma fração de segundo.
    final salvar = AppBotao.primario(
      rotulo: salvando
          ? AppStrings.cadastroSalvando
          : AppStrings.cadastroSalvar,
      icone: NomeIcone.avancar,
      aoTocar: aoSalvar,
      ocupaLargura: true,
    );
    final cancelar = AppBotao.secundario(
      rotulo: AppStrings.cadastroCancelar,
      aoTocar: aoCancelar,
      ocupaLargura: true,
    );

    return LayoutBuilder(
      builder: (context, restricoes) {
        if (restricoes.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              salvar,
              const SizedBox(height: AppSpacing.sm),
              cancelar,
            ],
          );
        }
        return Row(
          children: [
            const Spacer(),
            Flexible(flex: 2, child: cancelar),
            const SizedBox(width: AppSpacing.sm),
            Flexible(flex: 3, child: salvar),
          ],
        );
      },
    );
  }
}
