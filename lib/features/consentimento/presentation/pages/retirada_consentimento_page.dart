import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_mensagem_de_campo.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../pacientes/domain/paciente.dart';
import '../../data/repositorio_consentimento_local.dart';
import '../../domain/consentimento.dart';
import '../retirada_consentimento_controlador.dart';

/// Retirar o consentimento de um paciente, a pedido dele ou do responsável.
///
/// Diz o que acontece ANTES de registrar: a gravação volta a ficar
/// bloqueada, e o que ainda estava na fila para. Retirar é direito do
/// paciente, prometido no termo — a tela não pergunta "tem certeza?" nem
/// dificulta; só registra quem pediu.
///
/// Registrada a retirada, volta ao perfil do paciente, que passa a mostrar o
/// consentimento como retirado.
class RetiradaConsentimentoPage extends ConsumerWidget {
  const RetiradaConsentimentoPage({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(pacienteProvider(pacienteId));
    final consentimento = ref.watch(consentimentoProvider(pacienteId));

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final compacta =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.compacta;

          final Widget conteudo;
          if (paciente.hasError || consentimento.hasError) {
            conteudo = AppEstado.central(
              titulo: AppStrings.consentimentoErroCarregar,
              acao: AppBotao.secundario(
                rotulo: AppStrings.tentarNovamente,
                aoTocar: () {
                  ref.invalidate(pacienteProvider(pacienteId));
                  ref.invalidate(consentimentoProvider(pacienteId));
                },
              ),
            );
          } else if (!paciente.hasValue || !consentimento.hasValue) {
            conteudo = const Center(
              child: CircularProgressIndicator(color: AppColors.roxoProfundo),
            );
          } else if (paciente.value case final encontrado?) {
            conteudo = switch (consentimento.value) {
              final vigente? => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: _Formulario(
                      paciente: encontrado,
                      consentimento: vigente,
                    ),
                  ),
                ),
              ),
              // Já retirado, ou nunca registrado: não há o que retirar.
              null => AppEstado.central(
                titulo: AppStrings.retiradaNadaARetirar,
                acao: AppBotao.secundario(
                  rotulo: AppStrings.retiradaVoltarAoPaciente,
                  aoTocar: () => _irParaPaciente(context, pacienteId),
                ),
              ),
            };
          } else {
            conteudo = AppEstado.central(
              titulo: AppStrings.consentimentoPacienteNaoEncontrado,
              acao: AppBotao.secundario(
                rotulo: AppStrings.consentimentoVoltarParaLista,
                aoTocar: () => context.goNamed(AppRoutes.pacientesNome),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCabecalhoDeTarefa(
                titulo: AppStrings.retiradaTitulo,
                aoVoltar: () => context.canPop()
                    ? context.pop()
                    : _irParaPaciente(context, pacienteId),
                compacta: compacta,
              ),
              Expanded(child: conteudo),
            ],
          );
        },
      ),
    );
  }
}

void _irParaPaciente(BuildContext context, String pacienteId) =>
    context.goNamed(
      AppRoutes.pacienteDetalheNome,
      pathParameters: {AppRoutes.paramPacienteId: pacienteId},
    );

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({required this.paciente, required this.consentimento});

  final Paciente paciente;
  final Consentimento consentimento;

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  final _responsavel = TextEditingController();
  final _focoResponsavel = FocusNode();
  QuemAutoriza? _quem;

  String get _id => widget.paciente.id;

  @override
  void dispose() {
    _responsavel.dispose();
    _focoResponsavel.dispose();
    super.dispose();
  }

  void _editou(CampoDaRetirada campo) =>
      ref.read(retiradaConsentimentoProvider(_id).notifier).editou(campo);

  Future<void> _retirar() async {
    final retirou = await ref
        .read(retiradaConsentimentoProvider(_id).notifier)
        .retirar(quemPediu: _quem, nomeDoResponsavel: _responsavel.text);
    if (!mounted) return;

    if (retirou) {
      // `go`, e não `pop`: voltar do perfil não pode reabrir este formulário.
      _irParaPaciente(context, _id);
      return;
    }
    if (ref.read(retiradaConsentimentoProvider(_id)).erroResponsavel != null) {
      _focoResponsavel.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(retiradaConsentimentoProvider(_id));
    final textos = Theme.of(context).textTheme;
    final ocupado = estado.registrando;
    final c = widget.consentimento;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.consentimentoPaciente(widget.paciente.nome),
          style: textos.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        AppSituacao(
          icone: NomeIcone.confirmacao,
          titulo: AppStrings.consentimentoRegistrado,
          texto: AppStrings.consentimentoRegistradoTexto(
            data: AppStrings.data(c.registradoEm),
            hora: AppStrings.hora(c.registradoEm),
            quem: switch (c.quemAutoriza) {
              QuemAutoriza.paciente => AppStrings.consentimentoPeloPaciente,
              QuemAutoriza.responsavelLegal =>
                AppStrings.consentimentoPeloResponsavel(
                  c.nomeDoResponsavel ?? '',
                ),
            },
            versao: c.versaoDoTermo,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            AppStrings.retiradaOQueAcontece,
            style: textos.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final efeito in AppStrings.retiradaEfeitos)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Text('•  ', style: textos.bodyLarge)),
                Expanded(child: Text(efeito, style: textos.bodyLarge)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        AppEscolhaUnica<QuemAutoriza>(
          rotulo: AppStrings.retiradaCampoQuem,
          opcoes: const [
            AppOpcao(
              valor: QuemAutoriza.paciente,
              rotulo: AppStrings.consentimentoQuemPaciente,
            ),
            AppOpcao(
              valor: QuemAutoriza.responsavelLegal,
              rotulo: AppStrings.consentimentoQuemResponsavel,
            ),
          ],
          selecionado: _quem,
          aoEscolher: ocupado
              ? null
              : (quem) {
                  setState(() => _quem = quem);
                  _editou(CampoDaRetirada.quemPediu);
                },
          erro: estado.erroQuem,
          apoio: AppStrings.retiradaQuemApoio,
        ),
        if (_quem == QuemAutoriza.responsavelLegal) ...[
          const SizedBox(height: AppSpacing.md),
          AppCampoTexto(
            rotulo: AppStrings.consentimentoCampoResponsavel,
            controlador: _responsavel,
            foco: _focoResponsavel,
            erro: estado.erroResponsavel,
            somenteLeitura: ocupado,
            tipoDeTeclado: TextInputType.name,
            acaoDeEntrada: TextInputAction.done,
            aoMudar: (_) => _editou(CampoDaRetirada.nomeDoResponsavel),
            autoCorrecao: false,
            capitalizacao: TextCapitalization.words,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, restricoes) {
            final estreita = restricoes.maxWidth < 440;
            // Continua habilitado enquanto registra, só com outro rótulo: o
            // controlador já ignora o segundo toque.
            final botao = AppBotao.primario(
              rotulo: ocupado
                  ? AppStrings.retiradaRegistrando
                  : AppStrings.retiradaRegistrar,
              aoTocar: _retirar,
              ocupaLargura: estreita,
            );
            return estreita
                ? botao
                : Align(alignment: Alignment.centerRight, child: botao);
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
