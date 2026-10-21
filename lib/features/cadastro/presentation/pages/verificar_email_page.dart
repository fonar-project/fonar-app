import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/navegacao.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../auth/presentation/login_controlador.dart';
import '../../../auth/presentation/widgets/moldura_de_entrada.dart';
import '../cadastro_controlador.dart';
import '../entrada.dart';

/// "Confirme seu e-mail" (US34): a conta existe, e a API só aceita o
/// cadastro depois que o e-mail for verificado — sem isso, qualquer um se
/// cadastraria com o e-mail de outra pessoa.
///
/// O link abre no navegador, fora do app. A pessoa volta e toca em "Já
/// confirmei": o app pega um token novo (é nele que a verificação aparece)
/// e pergunta à API.
class VerificarEmailPage extends ConsumerWidget {
  const VerificarEmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(conexaoOnlineProvider);
    return MolduraDeEntrada(
      online: online,
      formulario: (_) => _Formulario(online: online),
    );
  }
}

class _Formulario extends ConsumerWidget {
  const _Formulario({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(verificacaoControladorProvider);
    final controlador = ref.read(verificacaoControladorProvider.notifier);
    final conta = ref.watch(contaGuardadaProvider).value;
    final textos = Theme.of(context).textTheme;
    final ocupado = estado.enviando;
    final motivo = online ? null : AppStrings.loginEntrarExigeConexao;

    Future<void> confirmar() async {
      final destino = await controlador.confirmar();
      if (destino == null || !context.mounted) return;
      // Confirmado: entra, e a pilha recomeça; ou o cadastro toma o lugar
      // desta tela, que não tem mais o que fazer.
      if (destino is EntrarNoApp) {
        context.goNamed(rotaDe(destino));
      } else {
        context.substituir(rotaDe(destino));
      }
    }

    Future<void> trocar() async {
      final saiu = await controlador.trocarDeConta();
      if (saiu && context.mounted) context.goNamed(AppRoutes.loginNome);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            AppStrings.verificarEmailTitulo,
            style: textos.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          conta == null
              ? AppStrings.verificarEmailSemConta
              : AppStrings.verificarEmailTexto(conta.email),
          style: textos.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (estado.aviso case (:final titulo, :final texto)) ...[
          // Aparece por causa de um toque: quem não vê a tela precisa ouvir.
          Semantics(
            liveRegion: true,
            child: AppSituacao(
              icone: NomeIcone.informacao,
              titulo: titulo,
              texto: texto,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppBotao.primario(
          rotulo: ocupado
              ? AppStrings.verificarEmailConferindo
              : AppStrings.verificarEmailJaConfirmei,
          aoTocar: online && !ocupado ? confirmar : null,
          // Conferindo, o rótulo já é o motivo, e não se repete embaixo.
          motivoDesabilitado: motivo ?? AppStrings.verificarEmailConferindo,
          carregando: ocupado,
          ocupaLargura: true,
        ),
        if (estado.erroGeral case final erro?) ...[
          const SizedBox(height: AppSpacing.sm),
          ErroDaEntrada(mensagem: erro),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppBotao.secundario(
          rotulo: AppStrings.verificarEmailReenviar,
          aoTocar: online && !ocupado ? controlador.reenviar : null,
          motivoDesabilitado: motivo ?? AppStrings.verificarEmailConferindo,
          // Parado pelo mesmo motivo do botão de cima, que já o mostra: um
          // "Conferindo…" na tela, e não três (US49).
          motivoVisivel: false,
          ocupaLargura: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        LinkDaEntrada(
          rotulo: AppStrings.verificarEmailOutraConta,
          aoTocar: ocupado ? null : trocar,
        ),
      ],
    );
  }
}
