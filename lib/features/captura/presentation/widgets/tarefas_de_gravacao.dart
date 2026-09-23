import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/amostra.dart';
import '../../domain/verificacao_da_amostra.dart';
import '../gravacao_controlador.dart';
import 'medidor_de_nivel.dart';

/// As tarefas do protocolo, cada uma com o seu estado e a sua ação, e o envio
/// para análise no fim.
///
/// Só aparece depois de uma aferição que libere a gravação — quem decide isso
/// é a tela.
class TarefasDeGravacao extends ConsumerWidget {
  const TarefasDeGravacao({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(gravacaoControladorProvider(pacienteId));
    final controlador = ref.read(
      gravacaoControladorProvider(pacienteId).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            AppStrings.tarefasTitulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final tarefa in TarefaDeGravacao.values) ...[
          _CartaoDaTarefa(
            tarefa: tarefa,
            estado: estado,
            proxima: tarefa == _proxima(estado),
            aoGravar: () => controlador.iniciar(tarefa),
            aoParar: controlador.parar,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Primário só quando é o próximo passo — com tarefa por gravar, o
        // primário da tela é o "Gravar" dela.
        AppBotao(
          variante: estado.completa
              ? VarianteBotao.primario
              : VarianteBotao.secundario,
          rotulo: AppStrings.capturaEnviar,
          icone: NomeIcone.avancar,
          aoTocar: null,
          motivoDesabilitado: estado.completa
              ? AppStrings.capturaEnvioIndisponivel
              : AppStrings.capturaEnviarFaltaTarefa,
          ocupaLargura: true,
        ),
      ],
    );
  }
}

/// A tarefa que o profissional deve gravar agora: a primeira sem amostra
/// válida. É a única com botão primário — no máximo um por tela, e com o
/// paciente esperando o olho precisa achar o próximo passo sem procurar.
TarefaDeGravacao? _proxima(EstadoDaGravacao estado) {
  if (estado.ocupado) return null;
  for (final tarefa in TarefaDeGravacao.values) {
    if (estado.amostras[tarefa] == null) return tarefa;
  }
  return null;
}

class _CartaoDaTarefa extends StatelessWidget {
  const _CartaoDaTarefa({
    required this.tarefa,
    required this.estado,
    required this.proxima,
    required this.aoGravar,
    required this.aoParar,
  });

  final TarefaDeGravacao tarefa;
  final EstadoDaGravacao estado;

  /// É a próxima a gravar — ver [_proxima].
  final bool proxima;
  final VoidCallback aoGravar;
  final VoidCallback aoParar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final (titulo, instrucao) = switch (tarefa) {
      TarefaDeGravacao.vogalSustentada => (
        AppStrings.tarefaVogalTitulo,
        AppStrings.tarefaVogalInstrucao,
      ),
      TarefaDeGravacao.falaEncadeada => (
        AppStrings.tarefaFalaTitulo,
        AppStrings.tarefaFalaInstrucao,
      ),
    };
    final amostra = estado.amostras[tarefa];
    final rejeitada = estado.rejeitadas[tarefa];
    final falha = estado.falha?.tarefa == tarefa ? estado.falha!.motivo : null;

    final List<Widget> corpo;
    if (estado.gravando == tarefa) {
      corpo = [
        Semantics(
          liveRegion: true,
          child: Text(
            AppStrings.tarefaGravando(AppStrings.segundos(estado.decorrido)),
            style: textos.titleSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        MedidorDeNivel(dbfs: estado.nivel),
        const SizedBox(height: AppSpacing.md),
        AppBotao.primario(
          rotulo: AppStrings.tarefaParar,
          icone: NomeIcone.pausar,
          aoTocar: aoParar,
          ocupaLargura: true,
        ),
      ];
    } else if (estado.conferindo == tarefa) {
      corpo = [
        Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.roxoProfundo,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppStrings.tarefaConferindo,
                style: textos.bodyMedium,
              ),
            ),
          ],
        ),
      ];
    } else {
      corpo = [
        if (amostra != null) ...[
          _SituacaoDaAmostra(amostra: amostra),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (rejeitada != null) ...[
          _Rejeitada(problemas: rejeitada, haAnterior: amostra != null),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (falha != null) ...[
          _Falha(motivo: falha),
          const SizedBox(height: AppSpacing.sm),
        ],
        _BotaoGravar(
          jaGravada: amostra != null,
          destacar: proxima,
          aoTocar: estado.ocupado ? null : aoGravar,
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: textos.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            instrucao,
            style: textos.bodyMedium?.copyWith(
              color: AppColors.secundarioSobreCreme,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...corpo,
        ],
      ),
    );
  }
}

class _BotaoGravar extends StatelessWidget {
  const _BotaoGravar({
    required this.jaGravada,
    required this.destacar,
    required this.aoTocar,
  });

  final bool jaGravada;
  final bool destacar;

  /// Nulo quando outra tarefa está sendo gravada ou conferida.
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final rotulo = jaGravada
        ? AppStrings.tarefaGravarDeNovo
        : AppStrings.tarefaGravar;
    const motivo = AppStrings.tarefaOutraEmAndamento;
    return destacar
        ? AppBotao.primario(
            rotulo: rotulo,
            icone: NomeIcone.gravar,
            aoTocar: aoTocar,
            motivoDesabilitado: motivo,
            ocupaLargura: true,
          )
        : AppBotao.secundario(
            rotulo: rotulo,
            icone: NomeIcone.gravar,
            aoTocar: aoTocar,
            motivoDesabilitado: motivo,
            ocupaLargura: true,
          );
  }
}

class _SituacaoDaAmostra extends StatelessWidget {
  const _SituacaoDaAmostra({required this.amostra});

  final Amostra amostra;

  @override
  Widget build(BuildContext context) {
    final duracao = AppStrings.segundos(amostra.duracao);
    if (amostra.problemas.isEmpty) {
      return AppSituacao(
        icone: NomeIcone.confirmacao,
        titulo: AppStrings.tarefaGravada(duracao),
        texto: AppStrings.tarefaGravadaTexto,
      );
    }
    return AppSituacao(
      icone: NomeIcone.alerta,
      titulo: AppStrings.tarefaGravadaComRessalva(duracao),
      texto: amostra.problemas.map(mensagemDoProblema).join(' '),
    );
  }
}

class _Rejeitada extends StatelessWidget {
  const _Rejeitada({required this.problemas, required this.haAnterior});

  final List<ProblemaNaAmostra> problemas;
  final bool haAnterior;

  @override
  Widget build(BuildContext context) {
    final motivos = problemas
        .where((p) => p.invalida)
        .map(mensagemDoProblema)
        .join(' ');
    return Semantics(
      liveRegion: true,
      child: AppSituacao(
        icone: NomeIcone.negacao,
        titulo: AppStrings.tarefaDescartada,
        texto: haAnterior
            ? '$motivos ${AppStrings.tarefaDescartadaMantida}'
            : motivos,
      ),
    );
  }
}

class _Falha extends StatelessWidget {
  const _Falha({required this.motivo});

  final FalhaDaGravacao motivo;

  @override
  Widget build(BuildContext context) {
    final texto = switch (motivo) {
      FalhaDaGravacao.semPermissao => AppStrings.tarefaFalhaPermissao,
      FalhaDaGravacao.naoIniciou => AppStrings.tarefaFalhaIniciar,
      FalhaDaGravacao.naoFinalizou => AppStrings.tarefaFalhaFinalizar,
      FalhaDaGravacao.interrompida => AppStrings.tarefaFalhaInterrompida,
    };
    // Não em vermelho: a cor é reservada a status de medida, saturação de
    // áudio e erro de formulário. O ícone e o título dizem que falhou.
    return Semantics(
      liveRegion: true,
      child: AppSituacao(
        icone: NomeIcone.negacao,
        titulo: AppStrings.tarefaFalhaTitulo,
        texto: texto,
      ),
    );
  }
}

/// O texto que o profissional lê para cada problema da conferência.
String mensagemDoProblema(ProblemaNaAmostra problema) => switch (problema) {
  ProblemaNaAmostra.arquivoIlegivel => AppStrings.problemaArquivoIlegivel,
  ProblemaNaAmostra.naoEPcm => AppStrings.problemaNaoEPcm,
  ProblemaNaAmostra.bitsDiferentes => AppStrings.problemaBitsDiferentes,
  ProblemaNaAmostra.incompleto => AppStrings.problemaIncompleto,
  ProblemaNaAmostra.curtaDemais => AppStrings.problemaCurtaDemais,
  ProblemaNaAmostra.semSinal => AppStrings.problemaSemSinal,
  ProblemaNaAmostra.saturou => AppStrings.problemaSaturou,
  ProblemaNaAmostra.formatoAjustado => AppStrings.problemaFormatoAjustado,
};
