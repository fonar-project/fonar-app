import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/conexao.dart';
import '../../../../core/offline/pacientes_em_cache.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_caixa_de_marcacao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../cadastro/data/criacao_de_conta.dart';
import '../../../cadastro/presentation/entrada.dart';
import '../../data/repositorio_autenticacao_firebase.dart';
import '../../domain/conta_autenticada.dart';
import '../login_controlador.dart';
import '../widgets/moldura_de_entrada.dart';

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

  /// "Manter conectado neste aparelho" (US59). Começa desmarcada: abrir o
  /// app sem senha é escolha de quem está no aparelho, a cada entrada.
  var _manterConectado = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _focoSenha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final destino = await ref
        .read(loginControladorProvider.notifier)
        .entrar(
          email: _email.text,
          senha: _senha.text,
          manterConectado: _manterConectado,
        );
    if (destino != null && mounted) context.goNamed(rotaDe(destino));
  }

  /// "Esqueci a senha" abre a tela própria do pedido (US58), com o e-mail
  /// que já estava aqui. Empilhada: voltar de lá traz esta tela de volta
  /// como estava.
  void _recuperar() => context.pushNamed(
    AppRoutes.recuperarSenhaNome,
    extra: _email.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(conexaoOnlineProvider);
    return MolduraDeEntrada(
      online: online,
      formulario: (comTitulo) =>
          _formulario(online: online, comTitulo: comTitulo),
    );
  }

  Widget _formulario({required bool online, required bool comTitulo}) {
    final estado = ref.watch(loginControladorProvider);
    // Enquanto o banco não respondeu, conta como nenhum: entrar offline só
    // fica disponível quando se sabe que há com quem trabalhar.
    final pacientesEmCache = ref.watch(pacientesEmCacheProvider).value ?? 0;
    // Idem: enquanto o cofre não respondeu, nenhuma conta para o offline.
    final contaGuardada = ref.watch(contaGuardadaProvider).value;
    final deExemplo = ref.watch(loginDeExemploProvider);
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
          if (deExemplo) ...[
            const AppSituacao(
              icone: NomeIcone.informacao,
              titulo: AppStrings.loginExemploTitulo,
              texto: AppStrings.loginExemploTexto,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Sem conexão, o aviso vem ANTES dos campos, não depois como no
          // protótipo. Offline, ele é a única coisa acionável da tela; embaixo
          // do formulário desabilitado ele caía abaixo da dobra num celular de
          // 844 px — justamente o botão que o profissional precisa no
          // consultório sem sinal.
          if (!online) ...[
            _avisoOffline(pacientesEmCache, contaGuardada),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppCampoTexto(
            rotulo: AppStrings.loginCampoEmail,
            controlador: _email,
            erro: estado.erroEmail,
            habilitado: online,
            // Enquanto a tentativa está no ar, o que está na tela é o que foi
            // enviado. Editar agora faria a resposta da tentativa A aparecer
            // junto dos valores B.
            somenteLeitura: estado.carregando,
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
            // Enquanto a tentativa está no ar, o que está na tela é o que foi
            // enviado. Editar agora faria a resposta da tentativa A aparecer
            // junto dos valores B.
            somenteLeitura: estado.carregando,
            ocultarTexto: true,
            acaoDeEntrada: TextInputAction.done,
            aoEnviar: (_) => _entrar(),
            autoCorrecao: false,
            autopreenchimento: const [AutofillHints.password],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCaixaDeMarcacao(
            rotulo: AppStrings.loginManterConectado,
            marcada: _manterConectado,
            aoMudar: online && !estado.carregando
                ? (marcada) => setState(() => _manterConectado = marcada)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
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
            ErroDaEntrada(mensagem: erro),
          ],
          if (online) ...[
            const SizedBox(height: AppSpacing.xs),
            LinkDaEntrada(
              rotulo: AppStrings.loginEsqueciSenha,
              aoTocar: estado.carregando ? null : _recuperar,
            ),
            // Criar conta só existe com o Firebase de verdade.
            if (ref.watch(criacaoDeContaProvider) != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.loginSemConta,
                textAlign: TextAlign.center,
                style: textos.bodySmall?.copyWith(
                  color: context.cores.secundario,
                ),
              ),
              LinkDaEntrada(
                rotulo: AppStrings.loginCriarConta,
                aoTocar: estado.carregando
                    ? null
                    : () => context.goNamed(AppRoutes.criarContaNome),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// O que dá para fazer sem conexão, conforme haja pacientes no aparelho e
/// uma entrada com senha anterior com que entrar.
Widget _avisoOffline(int pacientesEmCache, ContaAutenticada? conta) {
  if (pacientesEmCache > 0) {
    return AppEstado.faixa(
      titulo: AppStrings.loginOfflineComCacheTitulo,
      texto: AppStrings.loginOfflineComCacheTexto(pacientesEmCache),
      // Sem conta guardada, o motivo vai no botão desabilitado, como abaixo.
      acao: conta == null
          ? const AppBotao.secundario(
              rotulo: AppStrings.loginOfflineIndisponivel,
              aoTocar: null,
              motivoDesabilitado: AppStrings.loginOfflineSemContaTexto,
              ocupaLargura: true,
            )
          : _BotaoEntrarOffline(conta: conta),
    );
  }
  // A explicação vai como motivo do botão desabilitado, não como `texto` do
  // estado: assim ela fica presa ao controle que explica, e o leitor de tela a
  // anuncia junto dele.
  return const AppEstado.faixa(
    titulo: AppStrings.loginOfflineSemCacheTitulo,
    acao: AppBotao.primario(
      rotulo: AppStrings.loginOfflineIndisponivel,
      aoTocar: null,
      motivoDesabilitado: AppStrings.loginOfflineSemCacheTexto,
      ocupaLargura: true,
    ),
  );
}

/// Entra com a conta da última entrada com senha — a credencial guardada no
/// cofre. Quem saiu da conta apagou a credencial: o modo offline some junto.
///
/// Com a senha dessa conta (US43), conferida com o verificador que a última
/// entrada com rede guardou ([SenhaSemRede]). Sem ela, o aparelho na mão de
/// outra pessoa seria a lista de pacientes aberta.
class _BotaoEntrarOffline extends ConsumerStatefulWidget {
  const _BotaoEntrarOffline({required this.conta});

  final ContaAutenticada conta;

  @override
  ConsumerState<_BotaoEntrarOffline> createState() =>
      _BotaoEntrarOfflineState();
}

class _BotaoEntrarOfflineState extends ConsumerState<_BotaoEntrarOffline> {
  final _senha = TextEditingController();

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final entrou = await ref
        .read(loginControladorProvider.notifier)
        .entrarOffline(_senha.text);
    if (entrou && mounted) context.goNamed(AppRoutes.pacientesNome);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(loginControladorProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCampoTexto(
          rotulo: AppStrings.loginCampoSenha,
          controlador: _senha,
          erro: estado.erroSemRede,
          somenteLeitura: estado.carregando,
          ocultarTexto: true,
          autoCorrecao: false,
          acaoDeEntrada: TextInputAction.done,
          autopreenchimento: const [AutofillHints.password],
          aoEnviar: (_) => _entrar(),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppBotao.secundario(
          rotulo: estado.carregando
              ? AppStrings.loginBotaoEntrando
              : AppStrings.loginEntrarOffline,
          aoTocar: estado.carregando ? null : _entrar,
          ocupaLargura: true,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppStrings.loginOfflineComo(widget.conta.email),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
