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
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escala_visual.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_mensagem_de_campo.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/repositorio_analises_placeholder.dart';
import '../../../analise/domain/resultado_da_analise.dart';
import '../../../analise/presentation/aviso_de_outro_paciente.dart';
import '../../../pacientes/data/repositorio_pacientes_placeholder.dart';
import '../../domain/avaliacao_cape_v.dart';
import '../apresentacao_cape_v.dart';
import '../cape_v_controlador.dart';

/// Tela 08 — escala CAPE-V.
///
/// Tela cheia dedicada em qualquer largura, como pede o CLAUDE.md para o
/// celular: marcar seis escalas com o paciente ao lado não pode dividir
/// espaço com navegação. No desktop, as mesmas escalas em largura de leitura.
///
/// É registro do julgamento do profissional — a tela não sugere nota, não
/// pré-marca nada e não comenta o que foi marcado.
///
/// TODO(clínico): o número aparece enquanto se marca. Na folha de papel
/// quem avalia não vê o número, e vê-lo pode influenciar a marcação. Se a
/// orientação preferir escondê-lo durante a avaliação, o ajuste é no
/// `AppEscalaVisual`.
class CapeVPage extends ConsumerWidget {
  const CapeVPage({
    required this.pacienteId,
    required this.analiseId,
    super.key,
  });

  final String pacienteId;
  final String analiseId;

  void _voltar(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        AppRoutes.analiseResultadoNome,
        pathParameters: {
          AppRoutes.paramPacienteId: pacienteId,
          AppRoutes.paramAnaliseId: analiseId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analise = ref.watch(
      analiseDoPacienteProvider((pacienteId: pacienteId, analiseId: analiseId)),
    );
    final estado = ref.watch(capeVControladorProvider(analiseId));
    void tentarDeNovo() {
      ref.invalidate(analiseProvider(analiseId));
      ref.invalidate(capeVControladorProvider(analiseId));
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final compacta =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.compacta;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCabecalhoDeTarefa(
                titulo: AppStrings.capeVTitulo,
                aoVoltar: () => _voltar(context),
                compacta: compacta,
              ),
              Expanded(
                child: switch ((analise, estado)) {
                  // A análise precisa ser deste paciente — ver `daPaciente`.
                  (AsyncError(:final error), _)
                      when error is AnaliseDeOutroPaciente =>
                    AvisoDeOutroPaciente(aoVoltar: () => _voltar(context)),
                  (AsyncError(), _) || (_, AsyncError()) => AppEstado.central(
                    titulo: AppStrings.capeVErroCarregar,
                    acao: AppBotao.secundario(
                      rotulo: AppStrings.tentarNovamente,
                      aoTocar: tentarDeNovo,
                    ),
                  ),
                  (AsyncData(), AsyncData(:final value)) => _Formulario(
                    pacienteId: pacienteId,
                    analiseId: analiseId,
                    estado: value,
                    compacta: compacta,
                    aoRegistrar: () => _voltar(context),
                  ),
                  _ => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.roxoProfundo,
                    ),
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({
    required this.pacienteId,
    required this.analiseId,
    required this.estado,
    required this.compacta,
    required this.aoRegistrar,
  });

  final String pacienteId;
  final String analiseId;
  final EstadoCapeV estado;
  final bool compacta;
  final VoidCallback aoRegistrar;

  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  late final _comentarios = TextEditingController(
    text: widget.estado.comentariosIniciais,
  );

  @override
  void dispose() {
    _comentarios.dispose();
    super.dispose();
  }

  CapeVControlador get _controlador =>
      ref.read(capeVControladorProvider(widget.analiseId).notifier);

  Future<void> _registrar() async {
    final registrou = await _controlador.registrar(
      pacienteId: widget.pacienteId,
      comentarios: _comentarios.text,
    );
    if (registrou && mounted) widget.aoRegistrar();
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final nome = ref.watch(pacienteProvider(widget.pacienteId)).value?.nome;
    final textos = Theme.of(context).textTheme;
    final ocupado = estado.registrando;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compacta ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (nome != null) ...[
                Text(
                  AppStrings.consentimentoPaciente(nome),
                  style: textos.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                AppStrings.capeVExplicacao,
                style: textos.bodyMedium?.copyWith(
                  color: AppColors.secundarioSobreCreme,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final parametro in ParametroCapeV.values) ...[
                _Parametro(
                  parametro: parametro,
                  nota: estado.notas[parametro] ?? const NotaCapeV(),
                  problema: estado.problemas[parametro],
                  habilitado: !ocupado,
                  controlador: _controlador,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCampoTexto(
                rotulo: AppStrings.capeVComentarios,
                controlador: _comentarios,
                somenteLeitura: ocupado,
                linhas: 3,
                capitalizacao: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppBotao.primario(
                rotulo: ocupado
                    ? AppStrings.capeVRegistrando
                    : AppStrings.capeVRegistrar,
                aoTocar: _registrar,
                ocupaLargura: true,
              ),
              AppMensagemDeCampo(
                erro: estado.erroGeral,
                corDoApoio: AppColors.secundarioSobreCreme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Parametro extends StatelessWidget {
  const _Parametro({
    required this.parametro,
    required this.nota,
    required this.problema,
    required this.habilitado,
    required this.controlador,
  });

  final ParametroCapeV parametro;
  final NotaCapeV nota;
  final ProblemaNaNota? problema;
  final bool habilitado;
  final CapeVControlador controlador;

  @override
  Widget build(BuildContext context) {
    // Cada problema aparece junto do controle que o resolve.
    String? erroSe(ProblemaNaNota p) =>
        problema == p ? mensagemDoProblema(p) : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.branco,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEscalaVisual(
            rotulo: parametro.nome,
            valor: nota.valor,
            aoMudar: habilitado
                ? (v) => controlador.marcar(parametro, v)
                : null,
            rotuloMinimo: AppStrings.capeVSemDesvio,
            rotuloMaximo: AppStrings.capeVDesvioExtremo,
            textoNaoMarcado: AppStrings.capeVNaoMarcado,
            erro: erroSe(ProblemaNaNota.naoMarcada),
          ),
          // Consistência e sentido só aparecem com desvio marcado: sem
          // desvio, não há o que qualificar.
          if (nota.temDesvio) ...[
            const SizedBox(height: AppSpacing.sm),
            AppEscolhaUnica<Consistencia>(
              rotulo: AppStrings.capeVConsistencia,
              opcoes: [
                for (final c in Consistencia.values)
                  AppOpcao(valor: c, rotulo: nomeDaConsistencia(c)),
              ],
              selecionado: nota.consistencia,
              aoEscolher: habilitado
                  ? (c) => controlador.definirConsistencia(parametro, c)
                  : null,
              erro: erroSe(ProblemaNaNota.semConsistencia),
            ),
            if (parametro.temDirecao) ...[
              const SizedBox(height: AppSpacing.sm),
              AppEscolhaUnica<DirecaoDoDesvio>(
                rotulo: AppStrings.capeVSentido,
                opcoes: [
                  for (final d in DirecaoDoDesvio.values)
                    AppOpcao(valor: d, rotulo: parametro.nomeDaDirecao(d)),
                ],
                selecionado: nota.direcao,
                aoEscolher: habilitado
                    ? (d) => controlador.definirDirecao(parametro, d)
                    : null,
                erro: erroSe(ProblemaNaNota.semDirecao),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
