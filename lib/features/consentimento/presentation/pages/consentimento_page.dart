import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_caixa_de_marcacao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_fundo.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_mensagem_de_campo.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../pacientes/domain/paciente.dart';
import '../../data/repositorio_consentimento_local.dart';
import '../../domain/consentimento.dart';
import '../registro_consentimento_controlador.dart';
import '../texto_da_retirada.dart';

/// Tela 03 — consentimento do paciente para a gravação.
///
/// Duas caras, conforme o registro:
///
/// - **não registrado** (ou retirado): o termo, quem autoriza e a
///   concordância. É a tela que o profissional mostra ao paciente, então o
///   termo vem em letra de leitura, não em letra de rodapé;
/// - **registrado**: quando, por quem e com qual versão do termo, e o botão
///   que leva à gravação.
///
/// Esta tela NÃO é o bloqueio. O bloqueio é o redirect do roteador, que manda
/// para cá quem tenta abrir a gravação sem consentimento. Aqui só se registra.
///
/// Sem navegação principal: ocupa a tela inteira, como a gravação que vem
/// depois.
class ConsentimentoPage extends ConsumerWidget {
  const ConsentimentoPage({required this.pacienteId, super.key});

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
            conteudo = _Rolagem(
              compacta: compacta,
              child: switch (consentimento.value) {
                final registrado? => _Registrado(
                  paciente: encontrado,
                  consentimento: registrado,
                ),
                null => _Formulario(paciente: encontrado),
              },
            );
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
                titulo: AppStrings.consentimentoTitulo,
                aoVoltar: () => _voltar(context),
                compacta: compacta,
              ),
              Expanded(child: conteudo),
            ],
          );
        },
      ),
    );
  }

  void _voltar(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        AppRoutes.pacienteDetalheNome,
        pathParameters: {AppRoutes.paramPacienteId: pacienteId},
      );
    }
  }
}

void _irParaGravacao(BuildContext context, String pacienteId) =>
    context.goNamed(
      AppRoutes.capturaNome,
      pathParameters: {AppRoutes.paramPacienteId: pacienteId},
    );

/// Área rolável com largura de leitura: o termo em linha de 1200 px não se lê.
class _Rolagem extends StatelessWidget {
  const _Rolagem({required this.compacta, required this.child});

  final bool compacta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: child,
        ),
      ),
    );
  }
}

class _NomeDoPaciente extends StatelessWidget {
  const _NomeDoPaciente({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) => Text(
    AppStrings.consentimentoPaciente(paciente.nome),
    style: Theme.of(context).textTheme.titleMedium,
  );
}

// ------------------------------------------------------------ registrado --

class _Registrado extends StatelessWidget {
  const _Registrado({required this.paciente, required this.consentimento});

  final Paciente paciente;
  final Consentimento consentimento;

  @override
  Widget build(BuildContext context) {
    final quem = switch (consentimento.quemAutoriza) {
      QuemAutoriza.paciente => AppStrings.consentimentoPeloPaciente,
      QuemAutoriza.responsavelLegal => AppStrings.consentimentoPeloResponsavel(
        consentimento.nomeDoResponsavel ?? '',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NomeDoPaciente(paciente: paciente),
        const SizedBox(height: AppSpacing.lg),
        AppSituacao(
          icone: NomeIcone.confirmacao,
          titulo: AppStrings.consentimentoRegistrado,
          texto: AppStrings.consentimentoRegistradoTexto(
            data: AppStrings.data(consentimento.registradoEm),
            hora: AppStrings.hora(consentimento.registradoEm),
            quem: quem,
            versao: consentimento.versaoDoTermo,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _BotaoPrincipal(
          botao: (ocupaLargura) => AppBotao.primario(
            rotulo: AppStrings.consentimentoIniciarGravacao,
            icone: NomeIcone.gravar,
            aoTocar: () => _irParaGravacao(context, paciente.id),
            ocupaLargura: ocupaLargura,
          ),
        ),
      ],
    );
  }
}

/// No celular o botão principal ocupa a linha inteira, ao alcance do polegar;
/// com espaço, fica à direita, onde a leitura termina.
class _BotaoPrincipal extends StatelessWidget {
  const _BotaoPrincipal({required this.botao});

  final Widget Function(bool ocupaLargura) botao;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) => restricoes.maxWidth < 440
          ? botao(true)
          : Align(alignment: Alignment.centerRight, child: botao(false)),
    );
  }
}

// ------------------------------------------------------------ formulário --

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({required this.paciente});

  final Paciente paciente;

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  final _responsavel = TextEditingController();
  final _focoResponsavel = FocusNode();
  QuemAutoriza? _quem;
  var _concordou = false;

  String get _id => widget.paciente.id;

  @override
  void dispose() {
    _responsavel.dispose();
    _focoResponsavel.dispose();
    super.dispose();
  }

  void _editou(CampoDoConsentimento campo) =>
      ref.read(registroConsentimentoProvider(_id).notifier).editou(campo);

  Future<void> _registrar() async {
    final registrou = await ref
        .read(registroConsentimentoProvider(_id).notifier)
        .registrar(
          quemAutoriza: _quem,
          nomeDoResponsavel: _responsavel.text,
          concordou: _concordou,
        );
    if (!mounted) return;

    if (registrou) {
      _irParaGravacao(context, _id);
      return;
    }
    // O único campo de texto é o do responsável; os outros são toque.
    if (ref.read(registroConsentimentoProvider(_id)).erroResponsavel != null) {
      _focoResponsavel.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registroConsentimentoProvider(_id));
    final textos = Theme.of(context).textTheme;
    final ocupado = estado.registrando;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NomeDoPaciente(paciente: widget.paciente),
        const SizedBox(height: AppSpacing.md),
        // Retirado antes: diz quando, para ninguém achar que nunca houve.
        if (ref.watch(retiradaEmVigorProvider(_id)).value case final r?)
          AppSituacao(
            icone: NomeIcone.negacao,
            titulo: AppStrings.consentimentoRetirado,
            texto: textoDaRetirada(r),
          )
        else
          const AppSituacao(
            icone: NomeIcone.negacao,
            titulo: AppStrings.consentimentoNaoRegistrado,
            texto: AppStrings.consentimentoNaoRegistradoTexto,
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.consentimentoMostreAoPaciente,
          style: textos.bodySmall?.copyWith(
            color: AppColors.secundarioSobreCreme,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const _Termo(),
        const SizedBox(height: AppSpacing.lg),
        AppEscolhaUnica<QuemAutoriza>(
          rotulo: AppStrings.consentimentoCampoQuem,
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
                  _editou(CampoDoConsentimento.quemAutoriza);
                },
          erro: estado.erroQuem,
          apoio: AppStrings.consentimentoQuemApoio,
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
            aoMudar: (_) => _editou(CampoDoConsentimento.nomeDoResponsavel),
            autoCorrecao: false,
            capitalizacao: TextCapitalization.words,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppCaixaDeMarcacao(
          rotulo: AppStrings.consentimentoConcordancia,
          marcada: _concordou,
          aoMudar: ocupado
              ? null
              : (marcada) {
                  setState(() => _concordou = marcada);
                  _editou(CampoDoConsentimento.concordancia);
                },
          erro: estado.erroConcordancia,
        ),
        const SizedBox(height: AppSpacing.lg),
        _BotaoPrincipal(
          // Continua habilitado enquanto registra, só com outro rótulo: o
          // controlador já ignora o segundo toque.
          botao: (ocupaLargura) => AppBotao.primario(
            rotulo: ocupado
                ? AppStrings.consentimentoRegistrando
                : AppStrings.consentimentoRegistrar,
            icone: NomeIcone.confirmacao,
            aoTocar: _registrar,
            ocupaLargura: ocupaLargura,
          ),
        ),
        AppMensagemDeCampo(
          erro: estado.erroGeral,
          corDoApoio: AppColors.secundarioSobreCreme,
        ),
      ],
    );
  }
}

/// O texto do termo, em letra de leitura: é para o paciente ler.
class _Termo extends StatelessWidget {
  const _Termo();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.lavandaSuave,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: AppFundo(
        fundo: FundoDeTexto.lavanda,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                AppStrings.consentimentoTermoTitulo,
                style: textos.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in AppStrings.consentimentoTermoItens)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text('•  ', style: textos.bodyLarge),
                    ),
                    Expanded(child: Text(item, style: textos.bodyLarge)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
