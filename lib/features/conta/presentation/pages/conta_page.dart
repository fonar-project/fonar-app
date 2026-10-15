import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/escala_da_interface.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_secao.dart';
import '../../../../design_system/widgets/app_cabecalho_de_tarefa.dart';
import '../../../../design_system/widgets/app_confirmacao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../l10n/app_strings.dart';
import '../../../analise/data/catalogo_de_referencias_vazio.dart';
import '../../../auth/data/profissional_atual.dart';
import '../../../auth/data/sessao.dart';
import '../../../cadastro/domain/cadastro.dart';
import '../../data/preferencia_de_tamanho_local.dart';
import '../../data/preferencia_de_tema_local.dart';
import '../../data/troca_de_senha_firebase.dart';
import '../../domain/tema_escolhido.dart';
import '../../domain/troca_de_senha.dart';
import '../../../fila/presentation/fila_controlador.dart';
import '../../domain/dados_do_profissional.dart';
import '../conta_controlador.dart';
import '../troca_de_senha_controlador.dart';

/// Conta do profissional (US11).
///
/// Três perguntas que o profissional traz para esta tela: "o laudo sai com o
/// meu nome e registro certos?", "tem coisa minha presa neste aparelho?" e
/// "como saio?". Mais a troca de senha (US45) e o "sobre", que diz o que o
/// FONAR é e o que não é.
class ContaPage extends ConsumerWidget {
  const ContaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: LayoutBuilder(
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
                  // No desktop largo, duas colunas (US48): a conta — dados,
                  // senha e sair — e este aparelho. Cada uma na largura de
                  // leitura de um formulário; numa coluna só, sobrava vazio
                  // dos dois lados.
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, area) =>
                          area.maxWidth >= _larguraDeDuasColunas
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1240),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _Coluna([
                                      _SeusDados(),
                                      _Senha(),
                                      _Sair(),
                                    ]),
                                  ),
                                  SizedBox(width: AppSpacing.xxl),
                                  Expanded(
                                    child: _Coluna([
                                      _NesteAparelho(),
                                      _Aparencia(),
                                      _FaixasDeReferencia(),
                                      _Sobre(),
                                    ]),
                                  ),
                                ],
                              ),
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: const _Coluna([
                                _SeusDados(),
                                _Senha(),
                                _NesteAparelho(),
                                _FaixasDeReferencia(),
                                _Aparencia(),
                                _Sobre(),
                                _Sair(),
                              ]),
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

/// A partir desta largura de conteúdo, a Conta vai em duas colunas.
const _larguraDeDuasColunas = 1100.0;

/// Seções uma embaixo da outra, com o respiro de sempre entre elas.
class _Coluna extends StatelessWidget {
  const _Coluna(this.secoes);

  final List<Widget> secoes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, secao) in secoes.indexed) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xl),
        secao,
      ],
    ],
  );
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
    // O perfil vem do banco e pode chegar depois de a tela abrir: o campo
    // que o profissional não mexeu acompanha; o que ele mexeu fica.
    ref.listen(profissionalAtualProvider, (antes, depois) {
      if (antes == null) return;
      if (_nome.text == antes.nome) _nome.text = depois.nome;
      if (_registro.text == antes.registro) _registro.text = depois.registro;
    });
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
          // Quem já foi credenciado precisa saber, antes de salvar, que a
          // inscrição nova volta para a conferência.
          apoio: profissional.credenciamento == Credenciamento.credenciado
              ? AppStrings.contaRegistroTrocado
              : null,
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
        if (profissional.credenciamento case final credenciamento?) ...[
          const SizedBox(height: AppSpacing.md),
          _Credenciamento(credenciamento),
        ],
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
  ProblemaNosDados.registroFormato => AppStrings.contaRegistroFormato,
  null => null,
};

/// A situação do credenciamento, quando a API disse qual é (US34).
class _Credenciamento extends StatelessWidget {
  const _Credenciamento(this.credenciamento);

  final Credenciamento credenciamento;

  @override
  Widget build(BuildContext context) => switch (credenciamento) {
    Credenciamento.pendente => const AppSituacao(
      icone: NomeIcone.informacao,
      titulo: AppStrings.contaCredenciamentoPendenteTitulo,
      texto: AppStrings.contaCredenciamentoPendente,
    ),
    Credenciamento.credenciado => const AppSituacao(
      icone: NomeIcone.confirmacao,
      titulo: AppStrings.contaCredenciamentoCredenciado,
    ),
  };
}

// ---------------------------------------------------------------- senha --

/// Trocar a senha sem sair do app (US45): fechada, é um botão; aberta, a
/// senha atual e a nova, duas vezes.
class _Senha extends ConsumerStatefulWidget {
  const _Senha();

  @override
  ConsumerState<_Senha> createState() => _SenhaState();
}

class _SenhaState extends ConsumerState<_Senha> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();
  final _focoAtual = FocusNode();
  final _focoNova = FocusNode();
  final _focoConfirmacao = FocusNode();
  var _aberta = false;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmacao.dispose();
    _focoAtual.dispose();
    _focoNova.dispose();
    _focoConfirmacao.dispose();
    super.dispose();
  }

  TrocaDeSenhaControlador get _controlador =>
      ref.read(trocaDeSenhaControladorProvider.notifier);

  void _limpar() {
    _atual.clear();
    _nova.clear();
    _confirmacao.clear();
  }

  void _abrir() {
    _controlador.cancelar();
    setState(() => _aberta = true);
    // O campo só existe depois do próximo quadro.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focoAtual.requestFocus();
    });
  }

  void _fechar() {
    _controlador.cancelar();
    _limpar();
    setState(() => _aberta = false);
  }

  Future<void> _trocar() async {
    final trocou = await _controlador.trocar(
      atual: _atual.text,
      nova: _nova.text,
      confirmacao: _confirmacao.text,
    );
    if (!mounted) return;
    if (trocou) {
      // A senha não fica em campo nenhum depois de trocada.
      _limpar();
      setState(() => _aberta = false);
      return;
    }
    // Foco no primeiro campo com erro, como no cadastro.
    final estado = ref.read(trocaDeSenhaControladorProvider);
    if (estado.erroAtual != null) {
      _focoAtual.requestFocus();
    } else if (estado.erroNova != null) {
      _focoNova.requestFocus();
    } else if (estado.erroConfirmacao != null) {
      _focoConfirmacao.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final disponivel = ref.watch(trocaDeSenhaProvider) != null;
    final online = ref.watch(conexaoOnlineProvider);
    final estado = ref.watch(trocaDeSenhaControladorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(AppStrings.contaSenhaTitulo),
        _Cartao(
          children: [
            if (!disponivel)
              Text(AppStrings.contaSenhaExemplo, style: textos.bodyMedium)
            else ...[
              Text(AppStrings.contaSenhaApoio, style: textos.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              if (_aberta)
                ..._formulario(estado, online: online)
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBotao.secundario(
                    rotulo: AppStrings.contaSenhaTrocar,
                    aoTocar: online ? _abrir : null,
                    motivoDesabilitado: AppStrings.contaSenhaPrecisaConexao,
                  ),
                ),
              if (estado.trocada) ...[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: const AppSituacao(
                    icone: NomeIcone.confirmacao,
                    titulo: AppStrings.contaSenhaTrocada,
                  ),
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }

  List<Widget> _formulario(EstadoDaTroca estado, {required bool online}) => [
    AppCampoTexto(
      rotulo: AppStrings.contaSenhaCampoAtual,
      controlador: _atual,
      foco: _focoAtual,
      erro: estado.erroAtual,
      somenteLeitura: estado.trocando,
      ocultarTexto: true,
      autoCorrecao: false,
      autopreenchimento: const [AutofillHints.password],
      acaoDeEntrada: TextInputAction.next,
      aoMudar: (_) => _controlador.editou(CampoDaTrocaDeSenha.atual),
    ),
    const SizedBox(height: AppSpacing.md),
    AppCampoTexto(
      rotulo: AppStrings.contaSenhaCampoNova,
      apoio: AppStrings.criarContaSenhaApoio,
      controlador: _nova,
      foco: _focoNova,
      erro: estado.erroNova,
      somenteLeitura: estado.trocando,
      ocultarTexto: true,
      autoCorrecao: false,
      autopreenchimento: const [AutofillHints.newPassword],
      acaoDeEntrada: TextInputAction.next,
      aoMudar: (_) => _controlador.editou(CampoDaTrocaDeSenha.nova),
    ),
    const SizedBox(height: AppSpacing.md),
    AppCampoTexto(
      rotulo: AppStrings.contaSenhaCampoConfirmacao,
      controlador: _confirmacao,
      foco: _focoConfirmacao,
      erro: estado.erroConfirmacao,
      somenteLeitura: estado.trocando,
      ocultarTexto: true,
      autoCorrecao: false,
      autopreenchimento: const [AutofillHints.newPassword],
      acaoDeEntrada: TextInputAction.done,
      aoEnviar: (_) => _trocar(),
      aoMudar: (_) => _controlador.editou(CampoDaTrocaDeSenha.confirmacao),
    ),
    if (estado.erroGeral case final erro?) ...[
      const SizedBox(height: AppSpacing.sm),
      AppSituacao(icone: NomeIcone.alerta, titulo: erro),
    ],
    const SizedBox(height: AppSpacing.md),
    Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppBotao.primario(
          rotulo: estado.trocando
              ? AppStrings.contaSenhaTrocando
              : AppStrings.contaSenhaTrocar,
          aoTocar: online && !estado.trocando ? _trocar : null,
          motivoDesabilitado: estado.trocando
              ? AppStrings.contaSenhaTrocando
              : AppStrings.contaSenhaPrecisaConexao,
        ),
        AppBotao.secundario(
          rotulo: AppStrings.contaCancelar,
          aoTocar: estado.trocando ? null : _fechar,
          motivoDesabilitado: AppStrings.contaSenhaTrocando,
          // O botão do lado já diz "Trocando…" no rótulo.
          motivoVisivel: false,
        ),
      ],
    ),
  ];
}

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

/// Os envios pendentes DESTA conta: são os que pausam ao sair e voltam a
/// subir quando ela entrar de novo. Os de outra conta no aparelho esperam
/// por ela, e não mudam com esta saída.
int _pendentes(WidgetRef ref) {
  final uid = ref.watch(sessaoProvider)?.uid ?? '';
  return ref
          .watch(filaControladorProvider)
          .value
          ?.where((item) => item.pendente && item.deQuem(uid))
          .length ??
      0;
}

// ------------------------------------------------------------ aparência --

/// Claro, escuro ou o do sistema, e o tamanho da interface (US48). Valem
/// para este aparelho, na hora.
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
            const SizedBox(height: AppSpacing.lg),
            AppEscolhaUnica<TamanhoDaInterface>(
              rotulo: AppStrings.contaTamanho,
              opcoes: const [
                AppOpcao(
                  valor: TamanhoDaInterface.automatico,
                  rotulo: AppStrings.contaTamanhoAutomatico,
                ),
                AppOpcao(
                  valor: TamanhoDaInterface.cem,
                  rotulo: AppStrings.contaTamanho100,
                ),
                AppOpcao(
                  valor: TamanhoDaInterface.centoEQuinze,
                  rotulo: AppStrings.contaTamanho115,
                ),
                AppOpcao(
                  valor: TamanhoDaInterface.centoETrinta,
                  rotulo: AppStrings.contaTamanho130,
                ),
              ],
              selecionado:
                  ref.watch(tamanhoDaInterfaceProvider).value ??
                  TamanhoDaInterface.automatico,
              aoEscolher: (tamanho) => ref
                  .read(tamanhoDaInterfaceProvider.notifier)
                  .escolher(tamanho),
              apoio: AppStrings.contaTamanhoApoio(
                EscalaDaInterface.fatorDe(context),
              ),
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

/// Sair pergunta antes, no diálogo do design system (`appConfirmar`).
///
/// Até 25/09/2026 a pergunta abria aqui dentro da tela, para vir junto do que
/// acontece com o que ficou no aparelho. O que se perde continua sendo dito —
/// é o texto do diálogo, e ele muda conforme a fila —, mas a pergunta passou
/// a ser a mesma do resto do aplicativo. A justificativa está em
/// `design_system/widgets/app_confirmacao.dart`.
class _Sair extends ConsumerWidget {
  const _Sair();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(contaControladorProvider);
    final pendentes = _pendentes(ref);

    Future<void> perguntarESair() async {
      final sair = await appConfirmar(
        context,
        titulo: AppStrings.contaSairPergunta,
        texto: pendentes > 0
            ? AppStrings.contaSairComFila(pendentes)
            : AppStrings.contaSairTexto,
        confirmar: AppStrings.contaConfirmarSair,
        cancelar: AppStrings.contaCancelar,
      );
      if (!sair || !context.mounted) return;
      final saiu = await ref.read(contaControladorProvider.notifier).sair();
      if (saiu && context.mounted) context.goNamed(AppRoutes.loginNome);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: AppBotao.secundario(
        rotulo: estado.saindo ? AppStrings.contaSaindo : AppStrings.contaSair,
        aoTocar: estado.salvando || estado.saindo ? null : perguntarESair,
        motivoDesabilitado: estado.saindo
            ? AppStrings.contaSaindo
            : AppStrings.contaSalvando,
      ),
    );
  }
}
