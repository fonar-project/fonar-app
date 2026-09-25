import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/router/saida_protegida.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../conta/presentation/conta_controlador.dart';
import '../../data/bloqueio_por_inatividade.dart';
import '../../data/profissional_atual.dart';
import '../desbloqueio_controlador.dart';

/// O que aparece por cima de tudo quando o app bloqueia por inatividade.
///
/// Opaca e sem nada do que estava embaixo: nome de paciente, medida e
/// gravação ficam escondidos até a senha. Sem animação de entrada — aparece
/// de uma vez, como o bloqueio do aparelho.
class TelaDeBloqueio extends ConsumerStatefulWidget {
  const TelaDeBloqueio({super.key});

  @override
  ConsumerState<TelaDeBloqueio> createState() => _TelaDeBloqueioState();
}

class _TelaDeBloqueioState extends ConsumerState<TelaDeBloqueio> {
  final _senha = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _senha.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _desbloquear() async {
    final ok = await ref
        .read(desbloqueioControladorProvider.notifier)
        .desbloquear(_senha.text);
    if (!mounted) return;
    if (ok) {
      _senha.clear();
    } else {
      _foco.requestFocus();
    }
  }

  Future<void> _sair() async {
    // Lidos antes da espera, por garantia: a tela pode sair de cena no meio.
    final roteador = ref.read(routerProvider);
    final bloqueio = ref.read(bloqueioPorInatividadeProvider.notifier);
    // Sem a pergunta de "sair sem salvar": ela abriria por cima do formulário,
    // de volta à vista — e quem escolheu sair da conta já decidiu.
    ref.read(formulariosAlteradosProvider.notifier).esquecerTodos();
    // Esta tela continua cobrindo a de baixo durante toda a saída — a sessão
    // fechar não desbloqueia (ver `BloqueioPorInatividade.build`).
    await ref.read(contaControladorProvider.notifier).sair();
    // Para o login MESMO se a saída falhar: a sessão já fechou, e o próximo
    // login sobrescreve o token que ficou.
    roteador.goNamed(AppRoutes.loginNome);
    // A cobertura só sai com o login já desenhado por baixo.
    await WidgetsBinding.instance.endOfFrame;
    bloqueio.liberar();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = ref.watch(desbloqueioControladorProvider);
    final online = ref.watch(conexaoOnlineProvider);
    final profissional = ref.watch(profissionalAtualProvider);
    final minutos = ref.watch(limiteDeInatividadeProvider).inMinutes;
    // `watch`: mantém a saída viva enquanto acontece.
    final saida = ref.watch(contaControladorProvider);

    return Scaffold(
      backgroundColor: context.cores.fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      AppStrings.bloqueioTitulo,
                      style: textos.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.bloqueioProfissional(profissional.nome),
                    style: textos.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.bloqueioTexto(minutos),
                    style: textos.bodyMedium?.copyWith(
                      color: context.cores.secundario,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (online) ...[
                    AppCampoTexto(
                      rotulo: AppStrings.loginCampoSenha,
                      controlador: _senha,
                      foco: _foco,
                      erro: estado.erro,
                      ocultarTexto: true,
                      autoCorrecao: false,
                      somenteLeitura: estado.conferindo,
                      acaoDeEntrada: TextInputAction.done,
                      autopreenchimento: const [AutofillHints.password],
                      aoEnviar: (_) => _desbloquear(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppBotao.primario(
                      rotulo: estado.conferindo
                          ? AppStrings.bloqueioConferindo
                          : AppStrings.bloqueioDesbloquear,
                      aoTocar: _desbloquear,
                      ocupaLargura: true,
                    ),
                  ] else ...[
                    const AppSituacao(
                      icone: NomeIcone.informacao,
                      titulo: AppStrings.bloqueioOfflineTitulo,
                      texto: AppStrings.bloqueioOfflineTexto,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppBotao.primario(
                      rotulo: AppStrings.bloqueioContinuarOffline,
                      aoTocar: _desbloquear,
                      ocupaLargura: true,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppBotao.secundario(
                    rotulo: AppStrings.bloqueioSair,
                    aoTocar: saida.saindo ? null : _sair,
                    motivoDesabilitado: AppStrings.contaSaindo,
                    ocupaLargura: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
