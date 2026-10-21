import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/alcance_do_servidor.dart';
import '../core/network/conexao.dart';
import '../design_system/breakpoints.dart';
import '../design_system/tokens/app_cores.dart';
import '../design_system/tokens/app_movimento.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/widgets/app_fundo.dart';
import '../design_system/widgets/app_indicador_conexao.dart';
import '../design_system/widgets/app_simbolo.dart';
import '../design_system/widgets/app_toque.dart';
import '../features/auth/data/profissional_atual.dart';
import '../features/guia/domain/passo_do_guia.dart';
import '../features/guia/presentation/alvos_do_guia.dart';
import '../l10n/app_strings.dart';
import 'router/app_routes.dart';
import 'router/navegacao.dart';
import 'router/voltar_do_sistema.dart';

/// Destinos da navegação principal.
enum DestinoPrincipal {
  pacientes(
    rotulo: AppStrings.navPacientes,
    rotuloCurto: AppStrings.navPacientes,
    rota: AppRoutes.pacientesNome,
  ),
  novaAvaliacao(
    rotulo: AppStrings.navNovaAvaliacao,
    rotuloCurto: AppStrings.navNovaAvaliacaoCurto,
    rota: AppRoutes.novaAvaliacaoNome,
  ),
  historico(
    rotulo: AppStrings.navHistorico,
    rotuloCurto: AppStrings.navHistorico,
    rota: AppRoutes.historicoNome,
  ),
  fila(
    rotulo: AppStrings.navFila,
    rotuloCurto: AppStrings.navFilaCurto,
    rota: AppRoutes.filaNome,
  ),
  conta(
    rotulo: AppStrings.navConta,
    rotuloCurto: AppStrings.navConta,
    rota: AppRoutes.contaNome,
  );

  const DestinoPrincipal({
    required this.rotulo,
    required this.rotuloCurto,
    required this.rota,
  });

  /// Na barra lateral do desktop.
  final String rotulo;

  /// Na barra inferior do celular.
  final String rotuloCurto;

  /// Nome da rota no go_router.
  final String rota;

  /// O papel do destino no guia da primeira vez (US50), se ele aponta para
  /// este destino.
  PapelNoGuia? get papelNoGuia => switch (this) {
    fila => PapelNoGuia.fila,
    conta => PapelNoGuia.conta,
    _ => null,
  };
}

/// [item] declarado para o guia, se o [destino] tem papel nele.
Widget _paraOGuia(DestinoPrincipal destino, Widget item) =>
    switch (destino.papelNoGuia) {
      final papel? => AlvoDoGuia(papel: papel, child: item),
      null => item,
    };

/// O que a moldura mostra para uma tela: qual destino fica marcado e se as
/// abas aparecem embaixo fora do desktop.
typedef NavegacaoDaTela = ({DestinoPrincipal destino, bool abas});

/// A navegação de cada rota que fica dentro da moldura, pelo nome — ver
/// "Convenção" em [AppEstrutura].
///
/// As telas de destino têm abas; as de tarefa (perfil, gravação, resultado,
/// CAPE-V, laudo...) ocupam a tela inteira no celular, com o próprio voltar,
/// e no desktop ficam ao lado da barra lateral, como no protótipo.
/// `app_estrutura_test.dart` confere que toda rota da moldura está aqui.
const navegacaoDasRotas = <String, NavegacaoDaTela>{
  AppRoutes.pacientesNome: (destino: DestinoPrincipal.pacientes, abas: true),
  AppRoutes.novaAvaliacaoNome: (
    destino: DestinoPrincipal.novaAvaliacao,
    abas: true,
  ),
  AppRoutes.historicoNome: (destino: DestinoPrincipal.historico, abas: true),
  AppRoutes.filaNome: (destino: DestinoPrincipal.fila, abas: true),
  AppRoutes.contaNome: (destino: DestinoPrincipal.conta, abas: true),
  AppRoutes.pacienteDetalheNome: (
    destino: DestinoPrincipal.pacientes,
    abas: false,
  ),
  AppRoutes.edicaoPacienteNome: (
    destino: DestinoPrincipal.pacientes,
    abas: false,
  ),
  // Consentimento e gravação são o caminho da "Nova avaliação".
  AppRoutes.consentimentoNome: (
    destino: DestinoPrincipal.novaAvaliacao,
    abas: false,
  ),
  AppRoutes.retiradaConsentimentoNome: (
    destino: DestinoPrincipal.pacientes,
    abas: false,
  ),
  AppRoutes.gravacoesNaoEnviadasNome: (
    destino: DestinoPrincipal.pacientes,
    abas: false,
  ),
  AppRoutes.capturaNome: (destino: DestinoPrincipal.novaAvaliacao, abas: false),
  AppRoutes.analiseResultadoNome: (
    destino: DestinoPrincipal.pacientes,
    abas: false,
  ),
  AppRoutes.espectrogramaNome: (
    destino: DestinoPrincipal.pacientes,
    abas: false,
  ),
  AppRoutes.capeVNome: (destino: DestinoPrincipal.pacientes, abas: false),
  AppRoutes.laudoNome: (destino: DestinoPrincipal.pacientes, abas: false),
  AppRoutes.evolucaoNome: (destino: DestinoPrincipal.pacientes, abas: false),
};

/// O `builder` do `ShellRoute` das telas de quem entrou: a [AppEstrutura]
/// com o destino e as abas da tela de cima, por [navegacaoDasRotas].
///
/// Público para os testes montarem roteadores com a mesma moldura do app.
Widget molduraDoRoteador(
  BuildContext context,
  GoRouterState state,
  Widget filho,
) {
  final nome = state.topRoute?.name;
  final navegacao =
      navegacaoDasRotas[nome] ??
      (destino: DestinoPrincipal.pacientes, abas: false);
  // O voltar do Android (US60): com tela embaixo, desempilha — volta para a
  // tela de onde se veio. Sozinha na pilha, a tela volta para a lista de
  // pacientes; e na lista o app fecha.
  return VoltarDoSistema(
    para: AppRoutes.pacientesNome,
    naRaiz: nome == AppRoutes.pacientesNome,
    child: AppEstrutura(
      destino: navegacao.destino,
      navegacaoInferior: navegacao.abas,
      child: filho,
    ),
  );
}

/// Moldura das telas com navegação principal.
///
/// Expandida: barra lateral roxa com a marca, os destinos, a conexão e o
/// profissional logado. Compacta e média: destinos em abas de texto embaixo.
/// O cabeçalho do celular é da tela, não daqui — cada tela põe nele o que
/// precisa (a lista de pacientes, por exemplo, põe a busca).
///
/// ## Convenção: O ROTEADOR EMBRULHA, por um `ShellRoute` (US57)
///
/// As telas de quem entrou ficam todas dentro de um `ShellRoute`, e é ele
/// quem monta a moldura — uma vez só. Ao trocar de tela, a barra lateral e as
/// abas ficam PARADAS e só o conteúdo troca, com a entrada do
/// `AppMovimento`; o destaque do destino ativo anda com a transição curta dos
/// controles. Antes da US57 cada tela montava a própria moldura, e a página
/// inteira, barra lateral inclusive, era trocada e animava junto.
///
/// Nenhuma tela se embrulha: o que muda de uma para outra (o destino marcado,
/// as abas embaixo ou a tela inteira no celular) está em [navegacaoDasRotas],
/// num lugar só. Ficam fora da moldura a entrada (que vem antes de haver
/// navegação) e o modo paciente, que é tela inteira para o paciente ver.
/// `app_estrutura_test.dart` segura a convenção, pelo roteador de verdade.
class AppEstrutura extends StatelessWidget {
  const AppEstrutura({
    required this.destino,
    required this.child,
    this.navegacaoInferior = true,
    super.key,
  });

  /// Qual destino marcar como ativo.
  final DestinoPrincipal destino;

  final Widget child;

  /// Abas embaixo fora do desktop. Falso nas telas de tarefa: no celular elas
  /// ocupam a tela inteira, com o próprio voltar, e [child] aparece sozinho.
  final bool navegacaoInferior;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        if (Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.expandida) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BarraLateral(ativo: destino),
                Expanded(child: SafeArea(left: false, child: child)),
              ],
            ),
          );
        }
        // A mesma estrutura com e sem abas: só a barra entra e sai. O
        // conteúdo (o navegador das telas, na moldura do roteador) fica no
        // mesmo lugar da árvore e não é remontado.
        //
        // As margens do sistema (US60): desde o Android 15 o app desenha por
        // baixo das barras do sistema. A de cima é de cada tela — o
        // cabeçalho pinta o fundo dela e põe o conteúdo abaixo. As dos lados
        // (a barra dos três botões, com o celular deitado) e a de baixo são
        // daqui, para toda tela: com as abas, quem fica em cima da barra
        // dos botões é a barra das abas; sem elas, é o conteúdo que para
        // antes dela.
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                // O `Builder` lê as margens já dentro do Scaffold, que tira
                // o teclado do corpo.
                child: Builder(
                  builder: (context) => MediaQuery.removePadding(
                    context: context,
                    removeBottom: navegacaoInferior,
                    child: SafeArea(top: false, child: child),
                  ),
                ),
              ),
              if (navegacaoInferior) _BarraInferior(ativo: destino),
            ],
          ),
        );
      },
    );
  }
}

class _BarraLateral extends ConsumerWidget {
  const _BarraLateral({required this.ativo});

  final DestinoPrincipal ativo;

  static const _largura = 222.0;
  static const _margem = 22.0;
  static Widget _divisoria(BuildContext context) =>
      Divider(color: context.cores.sobrePrimaria.withValues(alpha: 0.18));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final profissional = ref.watch(profissionalAtualProvider);
    final creme = context.cores.sobrePrimaria;

    return Container(
      width: _largura,
      color: context.cores.lateral,
      child: SafeArea(
        right: false,
        // Rola quando não cabe. Com o texto do sistema em 200% os quatro
        // destinos mais a marca e o rodapé passam da altura da tela, e a
        // coluna estourava por baixo — escondendo justamente o profissional
        // logado e o estado da conexão. O `IntrinsicHeight` com altura mínima
        // igual à da tela mantém o `Spacer` empurrando o rodapé para baixo
        // enquanto há espaço sobrando; passando disso, vira rolagem.
        child: LayoutBuilder(
          builder: (context, restricoes) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: restricoes.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _margem,
                        _margem,
                        _margem,
                        18,
                      ),
                      child: Semantics(
                        header: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppSimbolo(cor: creme, tamanho: 30),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    AppStrings.appTitle,
                                    style: textos.titleLarge?.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: creme,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              AppStrings.loginSubtitulo,
                              style: textos.bodySmall?.copyWith(
                                color: creme.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _divisoria(context),
                    const SizedBox(height: AppSpacing.sm),
                    for (final destino in DestinoPrincipal.values)
                      _paraOGuia(
                        destino,
                        _ItemLateral(destino: destino, ativo: destino == ativo),
                      ),
                    const Spacer(),
                    _divisoria(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _margem,
                        14,
                        _margem,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AlvoDoGuia(
                            papel: PapelNoGuia.conexao,
                            child: AppIndicadorConexao(
                              online: ref.watch(conexaoOnlineProvider),
                              semServidor: ref.watch(
                                semAcessoAoServidorProvider,
                              ),
                              sobreFundoEscuro: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            profissional.identificacao,
                            style: textos.labelSmall?.copyWith(color: creme),
                          ),
                          Text(
                            profissional.completo
                                ? profissional.registro
                                : AppStrings.contaPerfilIncompleto,
                            style: textos.bodySmall?.copyWith(
                              color: creme.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({required this.destino, required this.ativo});

  final DestinoPrincipal destino;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final creme = context.cores.sobrePrimaria;
    return AppToque(
      aoTocar: () => context.irAoDestino(destino),
      selecionado: ativo,
      // Azul some sobre o roxo; o anel aqui é creme.
      corDoFoco: creme,
      corDoHover: creme.withValues(alpha: 0.08),
      // O destaque anda com a transição dos controles: a barra lateral
      // fica parada entre as telas (ver a convenção em [AppEstrutura]), e só
      // o destino marcado muda.
      conteudo: (context) => AnimatedContainer(
        duration: AppMovimento.duracao(context, AppMovimento.rapida),
        curve: AppMovimento.curva,
        constraints: const BoxConstraints(
          minHeight: AppSpacing.alvoDeToqueMinimo,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
        decoration: BoxDecoration(
          color: ativo
              ? creme.withValues(alpha: 0.14)
              : creme.withValues(alpha: 0),
          // Marca à esquerda no ativo: o estado não depende só do fundo.
          border: Border(
            left: BorderSide(
              color: ativo ? creme : creme.withValues(alpha: 0),
              width: 3,
            ),
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppMovimento.duracao(context, AppMovimento.rapida),
          curve: AppMovimento.curva,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: ativo ? creme : creme.withValues(alpha: 0.8),
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(destino.rotulo),
        ),
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.ativo});

  final DestinoPrincipal ativo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cores.fundo,
        border: Border(top: BorderSide(color: context.cores.borda)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final destino in DestinoPrincipal.values)
              Expanded(
                child: _paraOGuia(
                  destino,
                  _ItemInferior(destino: destino, ativo: destino == ativo),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemInferior extends StatelessWidget {
  const _ItemInferior({required this.destino, required this.ativo});

  final DestinoPrincipal destino;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return AppToque(
      aoTocar: () => context.irAoDestino(destino),
      selecionado: ativo,
      conteudo: (context) => AnimatedContainer(
        duration: AppMovimento.duracao(context, AppMovimento.rapida),
        curve: AppMovimento.curva,
        constraints: const BoxConstraints(
          minHeight: AppSpacing.alvoDeToqueMinimo + AppSpacing.xs,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 12),
        decoration: BoxDecoration(
          // Traço em cima da aba ativa, além do peso e da cor do texto.
          border: Border(
            top: BorderSide(
              color: ativo
                  ? context.cores.acento
                  : context.cores.acento.withValues(alpha: 0),
              width: 3,
            ),
          ),
        ),
        // FittedBox reduz o rótulo só quando ele não cabe na aba. Com o texto
        // do sistema em 200%, "Pacientes" quebrava no meio da palavra
        // ("Pacien/tes"), que é pior que letra um pouco menor.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            destino.rotuloCurto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ativo
                  ? context.cores.acento
                  // Pelo fundo, não fixo: a barra é a cor de fundo em
                  // repouso, mas o véu de hover do `AppToque` a escurece, e
                  // ali o tom comum reprova em AA.
                  : AppFundo.secundarioDe(context),
              fontWeight: ativo ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
