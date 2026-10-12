import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../auth/presentation/widgets/moldura_de_entrada.dart';
import '../cadastro_controlador.dart';
import '../entrada.dart';
import '../widgets/campos_do_registro.dart';

/// "Complete seu cadastro" (US34): o e-mail está confirmado e falta o
/// registro profissional. Aparece para quem criou a conta e fechou o app
/// antes de confirmar o e-mail, e para quem entra pela primeira vez com uma
/// conta criada fora do app.
class CompletarCadastroPage extends ConsumerStatefulWidget {
  const CompletarCadastroPage({super.key});

  @override
  ConsumerState<CompletarCadastroPage> createState() =>
      _CompletarCadastroPageState();
}

class _CompletarCadastroPageState extends ConsumerState<CompletarCadastroPage> {
  final _nome = TextEditingController();
  final _inscricao = TextEditingController();
  int? _regiao;
  var _aceitouTermos = false;

  @override
  void dispose() {
    _nome.dispose();
    _inscricao.dispose();
    super.dispose();
  }

  CompletarCadastroControlador get _controlador =>
      ref.read(completarCadastroControladorProvider.notifier);

  Future<void> _concluir() async {
    final destino = await _controlador.concluir(
      nome: _nome.text,
      regiao: _regiao,
      inscricao: _inscricao.text,
      aceitouTermos: _aceitouTermos,
    );
    if (destino != null && mounted) context.goNamed(rotaDe(destino));
  }

  Future<void> _trocarDeConta() async {
    final saiu = await _controlador.trocarDeConta();
    if (saiu && mounted) context.goNamed(AppRoutes.loginNome);
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
    final estado = ref.watch(completarCadastroControladorProvider);
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
              AppStrings.completarCadastroTitulo,
              style: textos.headlineMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.completarCadastroApoio,
            style: textos.bodySmall?.copyWith(color: context.cores.secundario),
          ),
          const SizedBox(height: AppSpacing.lg),
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
            aoEnviar: online ? _concluir : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppBotao.primario(
            rotulo: ocupado
                ? AppStrings.completarCadastroSalvando
                : AppStrings.completarCadastroBotao,
            aoTocar: online && !ocupado ? _concluir : null,
            motivoDesabilitado: online
                ? AppStrings.completarCadastroSalvando
                : AppStrings.loginEntrarExigeConexao,
            ocupaLargura: true,
          ),
          if (estado.erroGeral case final erro?) ...[
            const SizedBox(height: AppSpacing.sm),
            ErroDaEntrada(mensagem: erro),
          ],
          const SizedBox(height: AppSpacing.xs),
          LinkDaEntrada(
            rotulo: AppStrings.verificarEmailOutraConta,
            aoTocar: ocupado ? null : _trocarDeConta,
          ),
        ],
      ),
    );
  }
}
