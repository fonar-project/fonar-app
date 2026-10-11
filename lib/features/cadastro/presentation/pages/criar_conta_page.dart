import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../auth/presentation/widgets/moldura_de_entrada.dart';
import '../../domain/cadastro.dart';
import '../cadastro_controlador.dart';
import '../entrada.dart';
import '../widgets/campos_do_registro.dart';

/// Criar conta (US34): e-mail e senha da conta no Firebase, e o registro
/// profissional, que vai para a API depois que o e-mail for confirmado.
///
/// O cadastro é aberto: a pessoa usa o app enquanto a equipe confere a
/// inscrição no Crefono (ADR-015 da API). A tela diz isso antes do botão.
class CriarContaPage extends ConsumerStatefulWidget {
  const CriarContaPage({super.key});

  @override
  ConsumerState<CriarContaPage> createState() => _CriarContaPageState();
}

class _CriarContaPageState extends ConsumerState<CriarContaPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _nome = TextEditingController();
  final _inscricao = TextEditingController();
  int? _regiao;
  var _aceitouTermos = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    _nome.dispose();
    _inscricao.dispose();
    super.dispose();
  }

  CriarContaControlador get _controlador =>
      ref.read(criarContaControladorProvider.notifier);

  Future<void> _criar() async {
    final destino = await _controlador.criar(
      email: _email.text,
      senha: _senha.text,
      confirmacao: _confirmacao.text,
      nome: _nome.text,
      regiao: _regiao,
      inscricao: _inscricao.text,
      aceitouTermos: _aceitouTermos,
    );
    if (destino != null && mounted) context.goNamed(rotaDe(destino));
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(conexaoOnlineProvider);
    return MolduraDeEntrada(
      online: online,
      formulario: (_) => _formulario(online),
    );
  }

  Widget _formulario(bool online) {
    final estado = ref.watch(criarContaControladorProvider);
    final textos = Theme.of(context).textTheme;
    final ocupado = estado.enviando;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.criarContaTitulo,
              style: textos.headlineMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.criarContaApoio,
            style: textos.bodySmall?.copyWith(color: context.cores.secundario),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TituloDaSecao(AppStrings.criarContaSecaoConta),
          AppCampoTexto(
            rotulo: AppStrings.loginCampoEmail,
            controlador: _email,
            erro: estado.erroDe(CampoDoCadastro.email),
            somenteLeitura: ocupado,
            tipoDeTeclado: TextInputType.emailAddress,
            acaoDeEntrada: TextInputAction.next,
            autoCorrecao: false,
            autopreenchimento: const [AutofillHints.email],
            aoMudar: (_) => _controlador.editou(CampoDoCadastro.email),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCampoTexto(
            rotulo: AppStrings.loginCampoSenha,
            apoio: AppStrings.criarContaSenhaApoio,
            controlador: _senha,
            erro: estado.erroDe(CampoDoCadastro.senha),
            somenteLeitura: ocupado,
            ocultarTexto: true,
            acaoDeEntrada: TextInputAction.next,
            autoCorrecao: false,
            autopreenchimento: const [AutofillHints.newPassword],
            aoMudar: (_) => _controlador.editou(CampoDoCadastro.senha),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCampoTexto(
            rotulo: AppStrings.criarContaCampoConfirmacao,
            controlador: _confirmacao,
            erro: estado.erroDe(CampoDoCadastro.confirmacao),
            somenteLeitura: ocupado,
            ocultarTexto: true,
            acaoDeEntrada: TextInputAction.next,
            autoCorrecao: false,
            autopreenchimento: const [AutofillHints.newPassword],
            aoMudar: (_) => _controlador.editou(CampoDoCadastro.confirmacao),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TituloDaSecao(AppStrings.criarContaSecaoRegistro),
          CamposDoRegistro(
            nome: _nome,
            inscricao: _inscricao,
            regiao: _regiao,
            aceitouTermos: _aceitouTermos,
            aoEscolherRegiao: (r) => setState(() => _regiao = r),
            aoMarcarTermos: (m) => setState(() => _aceitouTermos = m),
            aoEditar: _controlador.editou,
            erroDe: estado.erroDe,
            ocupado: ocupado,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!online) ...[
            const AppSituacao(
              icone: NomeIcone.alerta,
              titulo: AppStrings.loginEntrarExigeConexao,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppBotao.primario(
            rotulo: ocupado
                ? AppStrings.criarContaCriando
                : AppStrings.criarContaBotao,
            aoTocar: online && !ocupado ? _criar : null,
            motivoDesabilitado: online
                ? AppStrings.criarContaCriando
                : AppStrings.loginEntrarExigeConexao,
            ocupaLargura: true,
          ),
          if (estado.erroGeral case final erro?) ...[
            const SizedBox(height: AppSpacing.sm),
            ErroDaEntrada(mensagem: erro),
          ],
          const SizedBox(height: AppSpacing.xs),
          LinkDaEntrada(
            rotulo: AppStrings.criarContaJaTenho,
            aoTocar: ocupado
                ? null
                : () => context.goNamed(AppRoutes.loginNome),
          ),
        ],
      ),
    );
  }
}
