import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_estrutura.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_secao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/catalogo_de_referencias_vazio.dart';
import '../../../auth/data/profissional_atual.dart';
import '../../data/preferencia_de_tema_local.dart';
import '../../domain/tema_escolhido.dart';
import '../../../fila/presentation/fila_controlador.dart';
import '../../domain/dados_do_profissional.dart';
import '../conta_controlador.dart';

/// Conta do profissional (US11).
///
/// Três perguntas que o profissional traz para esta tela: "o laudo sai com o
/// meu nome e registro certos?", "tem coisa minha presa neste aparelho?" e
/// "como saio?". Mais o "sobre", que diz o que o FONAR é e o que não é.
class ContaPage extends ConsumerWidget {
  const ContaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppEstrutura(
      destino: DestinoPrincipal.conta,
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final largura = Breakpoints.de(restricoes.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCabecalhoDeSecao(
                titulo: AppStrings.contaTitulo,
                largura: largura,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: largura == LarguraDeTela.compacta
                        ? AppSpacing.md
                        : AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SeusDados(),
                          SizedBox(height: AppSpacing.xl),
                          _NesteAparelho(),
                          SizedBox(height: AppSpacing.xl),
                          _FaixasDeReferencia(),
                          SizedBox(height: AppSpacing.xl),
                          _Aparencia(),
                          SizedBox(height: AppSpacing.xl),
                          _Sobre(),
                          SizedBox(height: AppSpacing.xl),
                          _Sair(),
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

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.cores.cartao,
      border: Border.all(color: context.cores.borda),
      borderRadius: AppRadius.bordaMedia,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

// ---------------------------------------------------------- seus dados --

class _SeusDados extends ConsumerStatefulWidget {
  const _SeusDados();

  @override
  ConsumerState<_SeusDados> createState() => _SeusDadosState();
}

class _SeusDadosState extends ConsumerState<_SeusDados> {
  late final _nome = TextEditingController(
    text: ref.read(profissionalAtualProvider).nome,
  );
  late final _registro = TextEditingController(
    text: ref.read(profissionalAtualProvider).registro,
  );
  final _focoNome = FocusNode();
  final _focoRegistro = FocusNode();

  @override
  void dispose() {
    _nome.dispose();
    _registro.dispose();
    _focoNome.dispose();
    _focoRegistro.dispose();
    super.dispose();
  }

  ContaControlador get _controlador =>
      ref.read(contaControladorProvider.notifier);

  Future<void> _salvar() async {
    final salvou = await _controlador.salvar(
      nome: _nome.text,
      registro: _registro.text,
    );
    if (salvou || !mounted) return;
    // Foco no primeiro campo com erro, como no cadastro.
    final estado = ref.read(contaControladorProvider);
    if (estado.erroNome != null) {
      _focoNome.requestFocus();
    } else if (estado.erroRegistro != null) {
      _focoRegistro.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(contaControladorProvider);
    final profissional = ref.watch(profissionalAtualProvider);
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: context.cores.secundario,
    );
    final mudou =
        _nome.text != profissional.nome ||
        _registro.text != profissional.registro;
    final ocupado = estado.salvando || estado.saindo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(AppStrings.contaSeusDados),
        Text(AppStrings.contaSeusDadosApoio, style: secundario),
        const SizedBox(height: AppSpacing.md),
        AppCampoTexto(
          rotulo: AppStrings.contaCampoNome,
          controlador: _nome,
          foco: _focoNome,
          erro: _mensagem(estado.erroNome),
          somenteLeitura: ocupado,
          capitalizacao: TextCapitalization.words,
          autoCorrecao: false,
          acaoDeEntrada: TextInputAction.next,
          aoMudar: (_) {
            _controlador.editou(CampoDaConta.nome);
            setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppCampoTexto(
          rotulo: AppStrings.contaCampoRegistro,
          dica: AppStrings.contaRegistroDica,
          controlador: _registro,
          foco: _focoRegistro,
          erro: _mensagem(estado.erroRegistro),
          somenteLeitura: ocupado,
          autoCorrecao: false,
          acaoDeEntrada: TextInputAction.done,
          aoEnviar: (_) => _salvar(),
          aoMudar: (_) {
            _controlador.editou(CampoDaConta.registro);
            setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Só leitura: o e-mail é a identidade da conta, e trocá-lo é
        // assunto da autenticação, não desta tela.
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.contaCampoEmail,
                style: textos.labelSmall?.copyWith(color: context.cores.texto),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(profissional.email, style: textos.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: AppBotao.primario(
            rotulo: estado.salvando
                ? AppStrings.contaSalvando
                : AppStrings.contaSalvar,
            aoTocar: mudou && !ocupado ? _salvar : null,
            motivoDesabilitado: estado.salvando
                ? AppStrings.contaSalvando
                : AppStrings.contaNadaMudou,
          ),
        ),
        if (estado.salvo) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: const AppSituacao(
              icone: NomeIcone.confirmacao,
              titulo: AppStrings.contaSalvo,
            ),
          ),
        ],
        if (estado.erroGeral case final erro?) ...[
          const SizedBox(height: AppSpacing.sm),
          AppSituacao(icone: NomeIcone.alerta, titulo: erro),
        ],
      ],
    );
  }
}

String? _mensagem(ProblemaNosDados? problema) => switch (problema) {
  ProblemaNosDados.nomeVazio => AppStrings.contaInformeNome,
  ProblemaNosDados.registroVazio => AppStrings.contaInformeRegistro,
  null => null,
};

// ------------------------------------------------------- neste aparelho --

class _NesteAparelho extends ConsumerWidget {
  const _NesteAparelho();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendentes = _pendentes(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(AppStrings.contaNesteAparelho),
        _Cartao(
          children: [
            Text(
              AppStrings.contaEnviosPendentes(pendentes),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (pendentes > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: AppBotao.secundario(
                  rotulo: AppStrings.contaVerFila,
                  icone: NomeIcone.avancar,
                  aoTocar: () => context.goNamed(AppRoutes.filaNome),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

int _pendentes(WidgetRef ref) =>
    ref
        .watch(filaControladorProvider)
        .value
        ?.where((item) => item.pendente)
        .length ??
    0;

// ------------------------------------------------------------ aparência --

/// Claro, escuro ou o do sistema. Vale para este aparelho, na hora.
class _Aparencia extends ConsumerWidget {
  const _Aparencia();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escolhido =
        ref.watch(temaEscolhidoProvider).value ?? TemaEscolhido.sistema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(AppStrings.contaAparencia),
        _Cartao(
          children: [
            AppEscolhaUnica<TemaEscolhido>(
              rotulo: AppStrings.contaTema,
              opcoes: const [
                AppOpcao(
                  valor: TemaEscolhido.sistema,
                  rotulo: AppStrings.contaTemaSistema,
                ),
                AppOpcao(
                  valor: TemaEscolhido.claro,
                  rotulo: AppStrings.contaTemaClaro,
                ),
                AppOpcao(
                  valor: TemaEscolhido.escuro,
                  rotulo: AppStrings.contaTemaEscuro,
                ),
              ],
              selecionado: escolhido,
              aoEscolher: (tema) =>
                  ref.read(temaEscolhidoProvider.notifier).escolher(tema),
              apoio: AppStrings.contaTemaApoio,
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------- faixas de referência --

/// De onde vem a classificação das medidas, e por que hoje não há nenhuma.
/// Só leitura: o catálogo não se edita no aparelho.
class _FaixasDeReferencia extends ConsumerWidget {
  const _FaixasDeReferencia();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final vazio =
        ref.watch(catalogoDeReferenciasProvider) is CatalogoDeReferenciasVazio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(AppStrings.contaFaixasTitulo),
        _Cartao(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppPilulaDeSituacao(
                texto: vazio
                    ? AppStrings.contaFaixasPendente
                    : AppStrings.contaFaixasEmUso,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(AppStrings.contaFaixasTexto, style: textos.bodyMedium),
            if (vazio) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(AppStrings.contaFaixasVazio, style: textos.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.contaFaixasSoLeitura,
              style: textos.bodySmall?.copyWith(
                color: context.cores.secundario,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- sobre --

class _Sobre extends StatelessWidget {
  const _Sobre();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: context.cores.secundario,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(AppStrings.contaSobre),
        _Cartao(
          children: [
            Text(AppStrings.contaSobreTexto, style: textos.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(AppStrings.contaSobrePraat, style: textos.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(AppStrings.contaVersao(AppConfig.versao), style: secundario),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: AppBotao.secundario(
                rotulo: AppStrings.contaLicencas,
                aoTocar: () => showLicensePage(
                  context: context,
                  applicationName: AppStrings.appTitle,
                  applicationVersion: AppConfig.versao,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- sair --

/// Sair pede confirmação AQUI, na própria tela, e não num diálogo: a
/// pergunta vem junto do que acontece com o que ficou no aparelho, e o
/// profissional lê as duas coisas no mesmo lugar.
class _Sair extends ConsumerStatefulWidget {
  const _Sair();

  @override
  ConsumerState<_Sair> createState() => _SairState();
}

class _SairState extends ConsumerState<_Sair> {
  var _confirmando = false;

  Future<void> _sair() async {
    final saiu = await ref.read(contaControladorProvider.notifier).sair();
    if (saiu && mounted) context.goNamed(AppRoutes.loginNome);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(contaControladorProvider);
    final pendentes = _pendentes(ref);
    final textos = Theme.of(context).textTheme;

    if (!_confirmando) {
      return Align(
        alignment: Alignment.centerLeft,
        child: AppBotao.secundario(
          rotulo: AppStrings.contaSair,
          aoTocar: estado.salvando
              ? null
              : () => setState(() => _confirmando = true),
          motivoDesabilitado: AppStrings.contaSalvando,
        ),
      );
    }

    return _Cartao(
      children: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(AppStrings.contaSairPergunta, style: textos.titleMedium),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          pendentes > 0
              ? AppStrings.contaSairComFila(pendentes)
              : AppStrings.contaSairTexto,
          style: textos.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppBotao.secundario(
              rotulo: estado.saindo
                  ? AppStrings.contaSaindo
                  : AppStrings.contaConfirmarSair,
              aoTocar: estado.saindo ? null : _sair,
              motivoDesabilitado: AppStrings.contaSaindo,
            ),
            AppBotao.secundario(
              rotulo: AppStrings.contaCancelar,
              aoTocar: estado.saindo
                  ? null
                  : () => setState(() => _confirmando = false),
              motivoDesabilitado: AppStrings.contaSaindo,
            ),
          ],
        ),
      ],
    );
  }
}
