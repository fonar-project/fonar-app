import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_indicador_conexao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../pacientes/data/pacientes_em_cache.dart';
import '../login_controlador.dart';

/// Tela 00 — entrada do profissional.
///
/// O estado da rede aparece antes de qualquer outra coisa, porque decide o que
/// dá para fazer: online entra com e-mail e senha; offline com pacientes no
/// aparelho entra em modo offline; offline sem nada no aparelho não entra.
///
/// Largura expandida: painel da marca à esquerda, formulário à direita.
/// Compacta e média: cabeçalho roxo em cima, formulário embaixo.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _focoSenha = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _focoSenha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final entrou = await ref
        .read(loginControladorProvider.notifier)
        .entrar(email: _email.text, senha: _senha.text);
    if (entrou && mounted) context.goNamed(AppRoutes.pacientesNome);
  }

  void _esqueciSenha() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(AppStrings.loginRecuperacaoIndisponivel)),
  );

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(conexaoOnlineProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final expandida =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.expandida;
          final formulario = _formulario(online: online, comTitulo: expandida);
          return expandida
              ? _LayoutExpandido(online: online, formulario: formulario)
              : _LayoutCompacto(online: online, formulario: formulario);
        },
      ),
    );
  }

  Widget _formulario({required bool online, required bool comTitulo}) {
    final estado = ref.watch(loginControladorProvider);
    final pacientesEmCache = ref.watch(pacientesEmCacheProvider);
    final textos = Theme.of(context).textTheme;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (comTitulo) ...[
            Semantics(
              header: true,
              child: Text(AppStrings.loginTitulo, style: textos.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Sem conexão, o aviso vem ANTES dos campos, não depois como no
          // protótipo. Offline, ele é a única coisa acionável da tela; embaixo
          // do formulário desabilitado ele caía abaixo da dobra num celular de
          // 844 px — justamente o botão que o profissional precisa no
          // consultório sem sinal.
          if (!online) ...[
            _avisoOffline(pacientesEmCache),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppCampoTexto(
            rotulo: AppStrings.loginCampoEmail,
            controlador: _email,
            erro: estado.erroEmail,
            habilitado: online,
            tipoDeTeclado: TextInputType.emailAddress,
            acaoDeEntrada: TextInputAction.next,
            aoEnviar: (_) => _focoSenha.requestFocus(),
            autoCorrecao: false,
            autopreenchimento: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCampoTexto(
            rotulo: AppStrings.loginCampoSenha,
            controlador: _senha,
            foco: _focoSenha,
            erro: estado.erroSenha,
            habilitado: online,
            ocultarTexto: true,
            acaoDeEntrada: TextInputAction.done,
            aoEnviar: (_) => _entrar(),
            autoCorrecao: false,
            autopreenchimento: const [AutofillHints.password],
          ),
          const SizedBox(height: AppSpacing.md),
          AppBotao.primario(
            rotulo: estado.carregando
                ? AppStrings.loginBotaoEntrando
                : AppStrings.loginBotaoEntrar,
            aoTocar: online ? _entrar : null,
            motivoDesabilitado: online
                ? null
                : AppStrings.loginEntrarExigeConexao,
            ocupaLargura: true,
          ),
          if (estado.erroGeral case final erro?) ...[
            const SizedBox(height: AppSpacing.sm),
            _ErroGeral(mensagem: erro),
          ],
          if (online) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: _esqueciSenha,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.roxoProfundo,
                  minimumSize: const Size(0, AppSpacing.alvoDeToqueMinimo),
                  textStyle: textos.labelSmall?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: const Text(AppStrings.loginEsqueciSenha),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// O que dá para fazer sem conexão, conforme haja pacientes no aparelho.
Widget _avisoOffline(int pacientesEmCache) {
  if (pacientesEmCache > 0) {
    return _AvisoOffline(
      titulo: AppStrings.loginOfflineComCacheTitulo,
      texto: AppStrings.loginOfflineComCacheTexto(pacientesEmCache),
      acao: const _BotaoEntrarOffline(),
    );
  }
  // A explicação vai como motivo do botão desabilitado, não como parágrafo
  // solto: assim ela fica presa ao controle que explica, e o leitor de tela a
  // anuncia junto dele.
  return const _AvisoOffline(
    titulo: AppStrings.loginOfflineSemCacheTitulo,
    acao: AppBotao.primario(
      rotulo: AppStrings.loginOfflineIndisponivel,
      aoTocar: null,
      motivoDesabilitado: AppStrings.loginOfflineSemCacheTexto,
      ocupaLargura: true,
    ),
  );
}

// TODO(auth): modo offline precisa de uma sessão anterior guardada no
// aparelho, e o roteador precisa saber que a sessão é offline. Hoje só navega —
// não há redirect de autenticação para contornar.
class _BotaoEntrarOffline extends StatelessWidget {
  const _BotaoEntrarOffline();

  @override
  Widget build(BuildContext context) => AppBotao.secundario(
    rotulo: AppStrings.loginEntrarOffline,
    aoTocar: () => context.goNamed(AppRoutes.pacientesNome),
    ocupaLargura: true,
  );
}

/// Desktop e tablet em paisagem: marca à esquerda, formulário à direita.
class _LayoutExpandido extends StatelessWidget {
  const _LayoutExpandido({required this.online, required this.formulario});

  final bool online;
  final Widget formulario;

  static const _larguraDoPainel = 560.0;
  static const _larguraDoFormulario = 440.0;
  static const _margemDoPainel = 60.0;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    const creme = AppColors.creme;
    final cremeSuave = creme.withValues(alpha: 0.85);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: _larguraDoPainel,
          color: AppColors.roxoProfundo,
          padding: const EdgeInsets.all(_margemDoPainel),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Marca(tamanho: 44),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.loginSubtitulo,
                style: textos.bodyLarge?.copyWith(
                  fontSize: 19,
                  color: cremeSuave,
                ),
              ),
              const SizedBox(height: AppSpacing.lg + 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  AppStrings.loginDescricao,
                  style: textos.bodyMedium?.copyWith(
                    height: 1.6,
                    color: cremeSuave,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SafeArea(
            left: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _margemDoPainel,
                vertical: AppSpacing.xl - 2,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppIndicadorConexao(online: online),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _larguraDoFormulario,
                          ),
                          child: formulario,
                        ),
                      ),
                    ),
                  ),
                  const _AvisoApoioDecisao(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Celular e janela estreita: cabeçalho roxo, formulário rolável embaixo.
class _LayoutCompacto extends StatelessWidget {
  const _LayoutCompacto({required this.online, required this.formulario});

  final bool online;
  final Widget formulario;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: AppColors.roxoProfundo,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl + 2,
                AppSpacing.lg,
                AppSpacing.lg + 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Marca(tamanho: 30),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.loginSubtitulo,
                          style: textos.bodySmall?.copyWith(
                            color: AppColors.creme.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIndicadorConexao(online: online, sobreFundoEscuro: true),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg - 4,
              vertical: AppSpacing.lg,
            ),
            // Na largura média o formulário não estica até a borda: campo de
            // e-mail com 900 px de largura é difícil de ler e de mirar.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: formulario,
              ),
            ),
          ),
        ),
        const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg - 4,
              0,
              AppSpacing.lg - 4,
              AppSpacing.md + 2,
            ),
            child: _AvisoApoioDecisao(),
          ),
        ),
      ],
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca({required this.tamanho});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        AppStrings.appTitle,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: tamanho,
          letterSpacing: tamanho * 0.05,
          color: AppColors.creme,
        ),
      ),
    );
  }
}

class _AvisoApoioDecisao extends StatelessWidget {
  const _AvisoApoioDecisao();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.avisoApoioDecisao,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.secundarioSobreCreme),
    );
  }
}

/// O que dá para fazer sem conexão.
class _AvisoOffline extends StatelessWidget {
  const _AvisoOffline({required this.titulo, required this.acao, this.texto});

  final String titulo;
  final String? texto;
  final Widget acao;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.lavandaSuave,
        border: Border.all(color: AppColors.lavandaClaro),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: textos.titleMedium),
          if (texto case final texto?) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              texto,
              style: textos.bodySmall?.copyWith(
                color: AppColors.secundarioSobreLavanda,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          acao,
        ],
      ),
    );
  }
}

/// Falha que não é de um campo específico: rede caiu no meio, servidor fora.
class _ErroGeral extends StatelessWidget {
  const _ErroGeral({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIcone(
              nome: NomeIcone.alerta,
              cor: AppColors.erro,
              tamanho: 16,
            ),
            const SizedBox(width: AppSpacing.xxs + 2),
            Expanded(
              child: Text(
                mensagem,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.erro,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
