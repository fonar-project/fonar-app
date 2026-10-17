import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../data/repositorio_autenticacao_firebase.dart';
import '../recuperacao_de_senha_controlador.dart';
import '../widgets/moldura_de_entrada.dart';

/// "Esqueci a senha" (US58): uma tela só para pedir o link de redefinição.
///
/// Antes, o pedido saía da própria tela de entrada, com o e-mail do campo
/// de login e o aviso embaixo do formulário: quem tocava no link sem ter
/// digitado o e-mail via um erro, e o aviso disputava lugar com o "Entrar".
/// Aqui o caminho é um só: o e-mail (já preenchido com o que estava na
/// entrada), "Enviar link", e a confirmação no lugar do formulário.
///
/// A confirmação é a mesma exista ou não conta para o e-mail — ver
/// [RecuperacaoDeSenhaControlador]. Ela fica na tela até a pessoa sair: não
/// some sozinha, porque é ela que diz o que fazer em seguida.
class RecuperarSenhaPage extends ConsumerStatefulWidget {
  const RecuperarSenhaPage({this.emailInicial, super.key});

  /// O que estava no campo de e-mail da entrada. Vai em memória, pela
  /// navegação, e não no endereço: na versão web, o endereço fica no
  /// histórico do navegador.
  final String? emailInicial;

  @override
  ConsumerState<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends ConsumerState<RecuperarSenhaPage> {
  late final _email = TextEditingController(text: widget.emailInicial ?? '');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  RecuperacaoDeSenhaControlador get _controlador =>
      ref.read(recuperacaoDeSenhaProvider.notifier);

  void _enviar() => _controlador.pedir(_email.text);

  /// Volta para a entrada. Aberta pelo "Esqueci a senha", a entrada está
  /// embaixo, com o que já foi digitado; aberta direto pelo endereço (na
  /// web), não há o que desempilhar.
  void _voltar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.loginNome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(conexaoOnlineProvider);
    return MolduraDeEntrada(
      online: online,
      formulario: (_) => _conteudo(online: online),
    );
  }

  Widget _conteudo({required bool online}) {
    final estado = ref.watch(recuperacaoDeSenhaProvider);
    final deExemplo = ref.watch(loginDeExemploProvider);
    final textos = Theme.of(context).textTheme;

    final titulo = Semantics(
      header: true,
      child: Text(AppStrings.recuperarTitulo, style: textos.headlineMedium),
    );

    if (estado.enviadoPara case final email?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          titulo,
          const SizedBox(height: AppSpacing.md),
          // Aparece por causa de um toque: quem não vê a tela precisa ouvir.
          Semantics(
            liveRegion: true,
            child: const AppSituacao(
              icone: NomeIcone.informacao,
              titulo: AppStrings.loginRecuperacaoEnviadaTitulo,
              texto: AppStrings.loginRecuperacaoEnviadaTexto,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Para conferir se não houve erro de digitação. Não diz se a conta
          // existe: é só o que foi digitado.
          Text(AppStrings.recuperarPedidoPara(email), style: textos.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          AppBotao.primario(
            rotulo: AppStrings.recuperarVoltar,
            aoTocar: _voltar,
            ocupaLargura: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          LinkDaEntrada(
            rotulo: AppStrings.recuperarEnviarDeNovo,
            aoTocar: online && !estado.enviando
                ? () => _controlador.pedir(email)
                : null,
          ),
          LinkDaEntrada(
            rotulo: AppStrings.recuperarOutroEmail,
            aoTocar: _controlador.outroEmail,
          ),
        ],
      );
    }

    // No modo de exemplo não há Firebase para mandar o e-mail; sem rede,
    // não há como pedir. O motivo fica preso ao botão parado.
    final motivo = deExemplo
        ? AppStrings.loginRecuperacaoIndisponivelTexto
        : online
        ? null
        : AppStrings.recuperarExigeConexao;
    final pode = motivo == null && !estado.enviando;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          titulo,
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.recuperarTexto, style: textos.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          if (deExemplo) ...[
            const AppSituacao(
              icone: NomeIcone.informacao,
              titulo: AppStrings.loginRecuperacaoIndisponivel,
              texto: AppStrings.loginRecuperacaoIndisponivelTexto,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCampoTexto(
            rotulo: AppStrings.loginCampoEmail,
            controlador: _email,
            erro: estado.erroDoEmail,
            habilitado: online && !deExemplo,
            // Enquanto o pedido está no ar, o que está na tela é o que foi
            // enviado.
            somenteLeitura: estado.enviando,
            tipoDeTeclado: TextInputType.emailAddress,
            acaoDeEntrada: TextInputAction.send,
            aoEnviar: pode ? (_) => _enviar() : null,
            aoMudar: (_) => _controlador.editou(),
            autoCorrecao: false,
            autopreenchimento: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.md),
          AppBotao.primario(
            rotulo: estado.enviando
                ? AppStrings.recuperarEnviando
                : AppStrings.recuperarEnviar,
            aoTocar: pode ? _enviar : null,
            motivoDesabilitado: motivo ?? AppStrings.recuperarEnviando,
            // No modo de exemplo o aviso de cima já explica; enviando, o
            // rótulo já é o motivo.
            motivoVisivel: !deExemplo && !estado.enviando,
            carregando: estado.enviando,
            ocupaLargura: true,
          ),
          if (estado.erroGeral case final erro?) ...[
            const SizedBox(height: AppSpacing.sm),
            ErroDaEntrada(mensagem: erro),
          ],
          const SizedBox(height: AppSpacing.xs),
          LinkDaEntrada(
            rotulo: AppStrings.recuperarVoltar,
            aoTocar: estado.enviando ? null : _voltar,
          ),
        ],
      ),
    );
  }
}
