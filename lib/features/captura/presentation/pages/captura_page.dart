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
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../pacientes/data/repositorio_pacientes_placeholder.dart';
import '../../data/configuracao_de_captura.dart';
import '../../domain/afericao_de_ruido.dart';
import '../../domain/fonte_de_nivel.dart';
import '../afericao_controlador.dart';
import '../gravacao_controlador.dart';
import '../widgets/medidor_de_nivel.dart';
import '../widgets/tarefas_de_gravacao.dart';

/// Tela 04 — gravação. Nesta etapa: a aferição de ruído ambiente, com o
/// medidor de nível ao vivo, que vem antes de qualquer gravação.
///
/// A aferição existe por dois motivos, e o segundo é o que a torna
/// obrigatória:
///
/// 1. saber se a sala está barulhenta demais antes de gastar a gravação;
/// 2. descobrir o microfone mudo ANTES da consulta, não depois. Silêncio
///    absoluto é tratado como falha e bloqueia a gravação — ver
///    `core/permissions/microphone_permission.dart`.
///
/// Só se chega aqui com consentimento registrado: o roteador bloqueia.
///
/// Leia antes de mexer aqui: a regra de captura no CLAUDE.md.
class CapturaPage extends ConsumerWidget {
  const CapturaPage({required this.pacienteId, super.key});

  final String pacienteId;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paciente = ref.watch(pacienteProvider(pacienteId)).value;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final compacta =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.compacta;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCabecalhoDeTarefa(
                titulo: AppStrings.capturaTitulo,
                aoVoltar: () => _voltar(context),
                compacta: compacta,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (paciente != null) ...[
                            Text(
                              AppStrings.consentimentoPaciente(paciente.nome),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          _Afericao(pacienteId: pacienteId),
                        ],
                      ),
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

class _Afericao extends ConsumerWidget {
  const _Afericao({required this.pacienteId});

  final String pacienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(afericaoControladorProvider);
    // Aferição e gravação disputam o mesmo microfone: com uma gravação em
    // andamento, medir de novo fica desabilitado.
    final gravando = ref.watch(
      gravacaoControladorProvider(pacienteId).select((g) => g.ocupado),
    );
    final textos = Theme.of(context).textTheme;
    void medir() => ref.read(afericaoControladorProvider.notifier).medir();

    final conteudo = <Widget>[
      ...switch (estado) {
        AfericaoNaoIniciada() => [
          Text(AppStrings.afericaoExplicacao, style: textos.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          _Acao(rotulo: AppStrings.afericaoMedir, aoTocar: medir),
        ],
        AfericaoMedindo(:final nivel, :final progresso) => [
          Semantics(
            liveRegion: true,
            child: Text(AppStrings.afericaoMedindo, style: textos.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.md),
          MedidorDeNivel(dbfs: nivel, ambiente: true),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.bordaPilula,
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 4,
              color: AppColors.roxoProfundo,
              backgroundColor: AppColors.lavandaClaro,
            ),
          ),
        ],
        AfericaoSemPermissao() => [
          const AppSituacao(
            icone: NomeIcone.negacao,
            titulo: AppStrings.afericaoSemPermissao,
            texto: AppStrings.afericaoSemPermissaoTexto,
          ),
          const SizedBox(height: AppSpacing.md),
          _Acao(rotulo: AppStrings.tentarNovamente, aoTocar: medir),
        ],
        AfericaoFalhou(:final microfoneLiberado, :final demorouParaLiberar) => [
          const AppSituacao(
            icone: NomeIcone.negacao,
            titulo: AppStrings.afericaoFalhou,
            texto: AppStrings.afericaoFalhouTexto,
          ),
          if (demorouParaLiberar) ...[
            const SizedBox(height: AppSpacing.md),
            const _MicrofoneDemorando(),
          ],
          const SizedBox(height: AppSpacing.md),
          _Acao(
            rotulo: AppStrings.tentarNovamente,
            aoTocar: microfoneLiberado ? medir : null,
            motivoDesabilitado: AppStrings.afericaoLiberandoMicrofone,
          ),
        ],
        AfericaoConcluida(
          :final resultado,
          :final ajuste,
          :final microfoneLiberado,
          :final demorouParaLiberar,
        ) =>
          [
            _Conclusao(resultado: resultado),
            if (ajuste != null) ...[
              const SizedBox(height: AppSpacing.md),
              _Ajuste(ajuste: ajuste),
            ],
            if (demorouParaLiberar) ...[
              const SizedBox(height: AppSpacing.md),
              const _MicrofoneDemorando(),
            ],
            const SizedBox(height: AppSpacing.md),
            _Acao(
              rotulo: AppStrings.afericaoMedirDeNovo,
              aoTocar: gravando || !microfoneLiberado ? null : medir,
              motivoDesabilitado: gravando
                  ? AppStrings.afericaoEsperaGravacao
                  : AppStrings.afericaoLiberandoMicrofone,
              secundaria: true,
            ),
          ],
      },
      const SizedBox(height: AppSpacing.xl),
      if (estado case AfericaoConcluida(liberaGravacao: true))
        TarefasDeGravacao(pacienteId: pacienteId)
      else
        _BotaoGravar(estado: estado),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(AppStrings.afericaoTitulo, style: textos.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...conteudo,
      ],
    );
  }
}

class _Conclusao extends StatelessWidget {
  const _Conclusao({required this.resultado});

  final ResultadoDaAfericao resultado;

  @override
  Widget build(BuildContext context) {
    final nivel = resultado.nivelTipico == null
        ? ''
        : AppStrings.nivelDbfs(resultado.nivelTipico!);

    // Anunciada ao aparecer: é a resposta de 5 segundos de espera.
    return Semantics(
      liveRegion: true,
      child: switch (resultado.conclusao) {
        ConclusaoDaAfericao.microfoneMudo => const AppSituacao(
          icone: NomeIcone.negacao,
          titulo: AppStrings.afericaoMudo,
          texto: AppStrings.afericaoMudoTexto,
        ),
        ConclusaoDaAfericao.ruidoAlto => AppSituacao(
          icone: NomeIcone.alerta,
          titulo: AppStrings.afericaoRuidoAlto,
          texto: AppStrings.afericaoRuidoAltoTexto(
            nivel,
            AppStrings.nivelDbfs(AfericaoDeRuido.limiteDeRuido),
          ),
        ),
        ConclusaoDaAfericao.semRestricao => AppSituacao(
          icone: NomeIcone.confirmacao,
          titulo: AppStrings.afericaoSemRestricao,
          texto: AppStrings.afericaoSemRestricaoTexto(nivel),
        ),
      },
    );
  }
}

/// O aparelho não usou o formato pedido. Não bloqueia — ainda não se sabe
/// quais ajustes a análise tolera —, mas não passa calado.
///
/// TODO(backend): decidir com a API de análise quais ajustes bloqueiam.
class _Ajuste extends StatelessWidget {
  const _Ajuste({required this.ajuste});

  final AjusteDeConfiguracao ajuste;

  @override
  Widget build(BuildContext context) => AppSituacao(
    icone: NomeIcone.informacao,
    titulo: AppStrings.afericaoAjusteTitulo,
    texto: AppStrings.afericaoAjusteTexto(
      taxaUsada: ajuste.taxaDeAmostragem,
      canaisUsados: ajuste.canais,
      taxaPedida: ConfiguracaoDeCaptura.taxaDeAmostragem,
      canaisPedidos: ConfiguracaoDeCaptura.canais,
    ),
  );
}

/// O fechamento do microfone passou do tempo esperado.
class _MicrofoneDemorando extends StatelessWidget {
  const _MicrofoneDemorando();

  @override
  Widget build(BuildContext context) => const AppSituacao(
    icone: NomeIcone.alerta,
    titulo: AppStrings.afericaoMicrofoneDemorando,
    texto: AppStrings.afericaoMicrofoneDemorandoTexto,
  );
}

class _Acao extends StatelessWidget {
  const _Acao({
    required this.rotulo,
    required this.aoTocar,
    this.motivoDesabilitado,
    this.secundaria = false,
  });

  final String rotulo;
  final VoidCallback? aoTocar;
  final String? motivoDesabilitado;
  final bool secundaria;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final ocupaLargura = restricoes.maxWidth < 440;
        final botao = secundaria
            ? AppBotao.secundario(
                rotulo: rotulo,
                aoTocar: aoTocar,
                motivoDesabilitado: motivoDesabilitado,
                ocupaLargura: ocupaLargura,
              )
            : AppBotao.primario(
                rotulo: rotulo,
                aoTocar: aoTocar,
                motivoDesabilitado: motivoDesabilitado,
                ocupaLargura: ocupaLargura,
              );
        return ocupaLargura
            ? botao
            : Align(alignment: Alignment.centerLeft, child: botao);
      },
    );
  }
}

/// "Iniciar gravação" desabilitado, dizendo por que, enquanto a aferição não
/// liberar. Liberada, dá lugar às tarefas.
class _BotaoGravar extends StatelessWidget {
  const _BotaoGravar({required this.estado});

  final EstadoDaAfericao estado;

  @override
  Widget build(BuildContext context) {
    final motivo = switch (estado) {
      AfericaoConcluida(microfoneLiberado: false) =>
        AppStrings.afericaoLiberandoMicrofone,
      AfericaoConcluida() => AppStrings.capturaBloqueadaMicrofone,
      _ => AppStrings.capturaBloqueadaSemAfericao,
    };

    return AppBotao.secundario(
      rotulo: AppStrings.capturaIniciarGravacao,
      icone: NomeIcone.gravar,
      aoTocar: null,
      motivoDesabilitado: motivo,
      ocupaLargura: true,
    );
  }
}
