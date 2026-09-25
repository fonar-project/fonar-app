import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/trilhas.dart';
import '../../../../app/app_estrutura.dart';
import '../../../../app/router/saida_protegida.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_mensagem_de_campo.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../data/repositorio_pacientes_local.dart';
import '../../domain/novo_paciente.dart';
import '../../domain/paciente.dart';
import '../cadastro_paciente_controlador.dart';
import '../edicao_paciente_controlador.dart';
import '../widgets/campos_do_paciente.dart';

/// Corrigir os dados de um paciente já cadastrado — os mesmos campos e as
/// mesmas regras do cadastro.
///
/// Existe porque um erro no cadastro não é cosmético: sexo e data de
/// nascimento escolhem a faixa de referência, e uma data errada deixa as
/// medidas sem classificação — ou com a de outra idade — em todas as sessões.
class EditarPacientePage extends ConsumerWidget {
  const EditarPacientePage({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(pacienteProvider(pacienteId));

    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      navegacaoInferior: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, restricoes) {
            final largura = Breakpoints.de(restricoes.maxWidth);
            final compacta = largura == LarguraDeTela.compacta;

            final Widget conteudo = switch (paciente) {
              AsyncData(value: final p?) when p.exemplo => AppEstado.central(
                titulo: AppStrings.edicaoExemplo,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.retiradaVoltarAoPaciente,
                  aoTocar: () => _voltar(context, pacienteId),
                ),
              ),
              AsyncData(value: final p?) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _Formulario(paciente: p),
                  ),
                ),
              ),
              AsyncData() => AppEstado.central(
                titulo: AppStrings.consentimentoPacienteNaoEncontrado,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.consentimentoVoltarParaLista,
                  aoTocar: () => context.goNamed(AppRoutes.pacientesNome),
                ),
              ),
              AsyncError() => AppEstado.central(
                titulo: AppStrings.perfilErroCarregar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.tentarNovamente,
                  aoTocar: () => ref.invalidate(pacientesProvider),
                ),
              ),
              _ => const Center(
                child: CircularProgressIndicator(color: AppColors.roxoProfundo),
              ),
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCabecalhoDeTarefa(
                  titulo: AppStrings.edicaoTitulo,
                  aoVoltar: () => _voltar(context, pacienteId),
                  largura: largura,
                  trilha: [
                    ...Trilhas.doPaciente(
                      context,
                      pacienteId: pacienteId,
                      nome: paciente.value?.nome,
                    ),
                    ItemDaTrilha(AppStrings.edicaoTitulo),
                  ],
                ),
                Expanded(child: conteudo),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _voltar(BuildContext context, String pacienteId) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.goNamed(
      AppRoutes.pacienteDetalheNome,
      pathParameters: {AppRoutes.paramPacienteId: pacienteId},
    );
  }
}

/// "02/07/1985" — como se digita no campo.
String _comoSeDigita(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year.toString().padLeft(4, '0')}';

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({required this.paciente});

  final Paciente paciente;

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  late final _nome = TextEditingController(text: widget.paciente.nome);
  late final _nascimento = TextEditingController(
    text: switch (widget.paciente.dataDeNascimento) {
      final d? => _comoSeDigita(d),
      null => '',
    },
  );
  late final _queixa = TextEditingController(text: widget.paciente.queixa);
  final _focoNome = FocusNode();
  final _focoNascimento = FocusNode();
  final _focoQueixa = FocusNode();
  late SexoDeReferencia? _sexo = widget.paciente.sexo;

  String get _id => widget.paciente.id;

  /// Como o formulário abriu: sair sem mexer em nada não pergunta nada.
  late final _inicial = (
    nome: _nome.text,
    nascimento: _nascimento.text,
    queixa: _queixa.text,
    sexo: _sexo,
  );

  @override
  void initState() {
    super.initState();
    _inicial;
    for (final c in [_nome, _nascimento, _queixa]) {
      c.addListener(_marcarAlterado);
    }
  }

  /// Diz ao roteador se há o que perder ao sair — ver `confirmarSaida`.
  void _marcarAlterado() => ref
      .read(formulariosAlteradosProvider.notifier)
      .marcar(
        chaveDaEdicao(_id),
        alterado: dadosAlterados(
          nome: _nome.text,
          nascimento: _nascimento.text,
          queixa: _queixa.text,
          sexo: _sexo,
          inicial: _inicial,
        ),
      );

  void _descartarMarca() => ref
      .read(formulariosAlteradosProvider.notifier)
      .marcar(chaveDaEdicao(_id), alterado: false);

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

  void _editou(CampoDoCadastro campo) =>
      ref.read(edicaoPacienteControladorProvider(_id).notifier).editou(campo);

  Future<void> _salvar({bool mesmoAssim = false}) async {
    final salvo = await ref
        .read(edicaoPacienteControladorProvider(_id).notifier)
        .salvar(
          nome: _nome.text,
          nascimento: _nascimento.text,
          sexo: _sexo,
          queixa: _queixa.text,
          mesmoAssim: mesmoAssim,
        );
    if (!mounted) return;
    if (salvo != null) {
      _descartarMarca();
      _voltar(context, _id);
      return;
    }
    primeiroCampoComErro(
      ref.read(edicaoPacienteControladorProvider(_id)),
      nome: _focoNome,
      nascimento: _focoNascimento,
      queixa: _focoQueixa,
    )?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(edicaoPacienteControladorProvider(_id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSituacao(
          icone: NomeIcone.informacao,
          titulo: AppStrings.edicaoAvisoTitulo,
          texto: AppStrings.edicaoAvisoTexto,
        ),
        const SizedBox(height: AppSpacing.lg),
        CamposDoPaciente(
          nome: _nome,
          nascimento: _nascimento,
          queixa: _queixa,
          focoNome: _focoNome,
          focoNascimento: _focoNascimento,
          focoQueixa: _focoQueixa,
          sexo: _sexo,
          aoEscolherSexo: (sexo) {
            setState(() => _sexo = sexo);
            _marcarAlterado();
          },
          estado: estado,
          aoEditar: _editou,
          aoConcluir: _salvar,
        ),
        if (estado.duplicado case final existente?) ...[
          const SizedBox(height: AppSpacing.md),
          AvisoDeDuplicado(
            paciente: existente,
            aoAbrirExistente: () {
              _descartarMarca();
              context.goNamed(
                AppRoutes.pacienteDetalheNome,
                pathParameters: {AppRoutes.paramPacienteId: existente.id},
              );
            },
            aoSalvarMesmoAssim: () => _salvar(mesmoAssim: true),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, restricoes) {
            // Continua habilitado enquanto salva, com outro rótulo: o
            // controlador já ignora o segundo toque.
            final salvar = AppBotao.primario(
              rotulo: estado.salvando
                  ? AppStrings.cadastroSalvando
                  : AppStrings.edicaoSalvar,
              aoTocar: _salvar,
              ocupaLargura: true,
            );
            final cancelar = AppBotao.secundario(
              rotulo: AppStrings.cadastroCancelar,
              aoTocar: () => _voltar(context, _id),
              ocupaLargura: true,
            );
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
        ),
        AppMensagemDeCampo(
          erro: estado.erroGeral,
          corDoApoio: AppColors.secundarioSobreCreme,
        ),
      ],
    );
  }
}
