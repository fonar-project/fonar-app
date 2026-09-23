import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_estrutura.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_secao.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/item_da_fila.dart';
import '../fila_controlador.dart';

/// Tela 06 — fila de sincronização: o que foi mandado para análise e em que
/// pé cada envio está.
///
/// Existe para uma pergunta do profissional: "aquela gravação chegou?". Cada
/// envio diz a situação por escrito e com ícone, e o que fazer quando há algo
/// a fazer. Sem botão primário: a fila trabalha sozinha, e as ações aqui são
/// exceção.
class FilaPage extends ConsumerWidget {
  const FilaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fila = ref.watch(filaControladorProvider);
    final online = ref.watch(conexaoOnlineProvider);

    return AppEstrutura(
      destino: DestinoPrincipal.fila,
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final largura = Breakpoints.de(restricoes.maxWidth);
          final compacta = largura == LarguraDeTela.compacta;

          final Widget conteudo = switch (fila) {
            AsyncData(:final value) when value.isEmpty => AppEstado.central(
              titulo: AppStrings.filaVaziaTitulo,
              texto: AppStrings.filaVaziaTexto,
              acao: AppBotao.secundario(
                rotulo: AppStrings.filaIrParaPacientes,
                aoTocar: () => context.goNamed(AppRoutes.pacientesNome),
              ),
            ),
            AsyncData(:final value) => _Lista(
              itens: value,
              online: online,
              compacta: compacta,
            ),
            _ => const Center(
              child: CircularProgressIndicator(color: AppColors.roxoProfundo),
            ),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCabecalhoDeSecao(
                titulo: AppStrings.filaTitulo,
                largura: largura,
              ),
              Expanded(child: conteudo),
            ],
          );
        },
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.itens,
    required this.online,
    required this.compacta,
  });

  final List<ItemDaFila> itens;
  final bool online;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final pendentes = itens.where((i) => i.pendente).length;
    // O mais novo em cima: é o que o profissional acabou de mandar e veio
    // conferir.
    final ordenados = itens.reversed.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: compacta ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!online && pendentes > 0) ...[
                const AppSituacao(
                  icone: NomeIcone.estadoSemConexao,
                  titulo: AppStrings.filaSemConexaoTitulo,
                  texto: AppStrings.filaSemConexaoTexto,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Semantics(
                liveRegion: true,
                child: Text(
                  AppStrings.filaResumo(pendentes),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.secundarioSobreCreme),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final item in ordenados) ...[
                _CartaoDoEnvio(item: item, online: online),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoDoEnvio extends ConsumerWidget {
  const _CartaoDoEnvio({required this.item, required this.online});

  final ItemDaFila item;
  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    void tentar() =>
        ref.read(filaControladorProvider.notifier).tentarAgora(item.id);
    final motivo = item.ultimaFalha ?? '';

    final (icone, titulo, texto) = switch (item.situacao) {
      SituacaoDoEnvio.naFila when !online => (
        NomeIcone.passoPendente,
        AppStrings.filaAguardandoConexao,
        AppStrings.filaAguardandoConexaoTexto,
      ),
      SituacaoDoEnvio.naFila => (
        NomeIcone.passoPendente,
        AppStrings.filaNaFila,
        AppStrings.filaNaFilaTexto,
      ),
      SituacaoDoEnvio.enviando => (
        NomeIcone.gravar,
        AppStrings.filaEnviando,
        AppStrings.filaEnviandoTexto,
      ),
      SituacaoDoEnvio.aguardandoNovaTentativa when !online => (
        NomeIcone.passoPendente,
        AppStrings.filaAguardandoConexao,
        AppStrings.filaAguardandoConexaoTexto,
      ),
      SituacaoDoEnvio.aguardandoNovaTentativa => (
        NomeIcone.alerta,
        AppStrings.filaFalhou,
        AppStrings.filaFalhouTexto(
          motivo,
          AppStrings.hora(item.proximaTentativa ?? item.criadoEm),
        ),
      ),
      SituacaoDoEnvio.aguardandoLogin => (
        NomeIcone.alerta,
        AppStrings.filaSessaoExpirada,
        AppStrings.filaSessaoExpiradaTexto,
      ),
      SituacaoDoEnvio.recusado => (
        NomeIcone.alerta,
        AppStrings.filaRecusado,
        AppStrings.filaRecusadoTexto(motivo),
      ),
      SituacaoDoEnvio.enviado => (
        NomeIcone.confirmacao,
        AppStrings.filaEnviado,
        AppStrings.filaEnviadoTexto,
      ),
    };

    // TODO(auth): com o Firebase Auth, "sessão expirada" deve levar ao login
    // e a fila deve retomar sozinha depois de entrar. Hoje só oferece tentar
    // de novo, que falha igual enquanto a sessão não for renovada.
    final Widget? acao = switch (item.situacao) {
      SituacaoDoEnvio.aguardandoNovaTentativa ||
      SituacaoDoEnvio.aguardandoLogin ||
      SituacaoDoEnvio.recusado => AppBotao.secundario(
        rotulo: item.situacao == SituacaoDoEnvio.aguardandoNovaTentativa
            ? AppStrings.filaTentarAgora
            : AppStrings.filaTentarDeNovo,
        aoTocar: online ? tentar : null,
        motivoDesabilitado: AppStrings.filaTentarExigeConexao,
      ),
      SituacaoDoEnvio.enviado when item.analiseId != null =>
        AppBotao.secundario(
          rotulo: AppStrings.filaVerResultado,
          icone: NomeIcone.avancar,
          aoTocar: () => context.goNamed(
            AppRoutes.analiseResultadoNome,
            pathParameters: {
              AppRoutes.paramPacienteId: item.pacienteId,
              AppRoutes.paramAnaliseId: item.analiseId!,
            },
          ),
        ),
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.nomeDoPaciente, style: textos.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            AppStrings.filaGravacoes(
              item.amostras.length,
              '${AppStrings.data(item.criadoEm)}, ${AppStrings.hora(item.criadoEm)}',
            ),
            style: textos.bodySmall?.copyWith(
              color: AppColors.secundarioSobreCreme,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSituacao(icone: icone, titulo: titulo, texto: texto),
          if (acao != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(alignment: Alignment.centerLeft, child: acao),
          ],
        ],
      ),
    );
  }
}
