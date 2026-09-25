import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_estrutura.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/network/conexao.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/tokens/app_typography.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_estado.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_indicador_conexao.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../../historico/domain/evolucao_da_medida.dart';
import '../../data/repositorio_pacientes_local.dart';
import '../../domain/paciente.dart';
import '../busca_pacientes_controlador.dart';

/// Tela 01 — lista de pacientes, ponto de partida de toda avaliação.
///
/// Expandida: tabela com busca e contagem no topo. Compacta: cards, busca no
/// cabeçalho e "Nova avaliação" fixo acima das abas, ao alcance do polegar.
///
/// A página observa só a LISTA. O termo da busca fica no
/// `BuscaPacientesControlador`, e quem o observa são apenas as duas partes que
/// dependem dele — o conteúdo e a contagem. Antes o termo morava no `State` e
/// cada tecla reconstruía a página inteira, inclusive a barra de navegação e o
/// próprio campo de busca.
class PacientesListPage extends ConsumerWidget {
  const PacientesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacientes = ref.watch(pacientesProvider);

    return AppEstrutura(
      destino: DestinoPrincipal.pacientes,
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final expandida =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.expandida;

          // Lista vazia já tem o próprio "Cadastrar paciente" no centro. O
          // botão fixo levaria ao mesmo lugar: seriam dois primários iguais na
          // tela, e o AppBotao pede no máximo um.
          final aoNovaAvaliacao = pacientes.value?.isEmpty ?? false
              ? null
              : () => _novaAvaliacao(context);

          final conteudo = _Conteudo(expandida: expandida);

          return expandida
              ? _LayoutExpandido(
                  aoNovaAvaliacao: aoNovaAvaliacao,
                  conteudo: conteudo,
                )
              : _LayoutCompacto(
                  aoNovaAvaliacao: aoNovaAvaliacao,
                  conteudo: conteudo,
                );
        },
      ),
    );
  }
}

void _novaAvaliacao(BuildContext context) =>
    context.goNamed(AppRoutes.novaAvaliacaoNome);

void _abrir(BuildContext context, Paciente paciente) => context.goNamed(
  AppRoutes.pacienteDetalheNome,
  pathParameters: {AppRoutes.paramPacienteId: paciente.id},
);

/// A área que muda quando se digita: tabela, cards ou estado sem conteúdo.
class _Conteudo extends ConsumerWidget {
  const _Conteudo({required this.expandida});

  final bool expandida;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(pacientesFiltradosProvider)
        .when(
          loading: () => Center(
            child: CircularProgressIndicator(color: context.cores.acento),
          ),
          error: (_, _) => AppEstado.central(
            titulo: AppStrings.pacientesErroCarregar,
            acao: AppBotao.secundario(
              rotulo: AppStrings.tentarNovamente,
              aoTocar: () => ref.invalidate(pacientesProvider),
            ),
          ),
          data: (encontrados) {
            if (encontrados.isNotEmpty) {
              return expandida
                  ? _Tabela(pacientes: encontrados)
                  : _Cards(pacientes: encontrados);
            }
            // Nada na tela, e duas causas bem diferentes: o aparelho não tem
            // paciente nenhum, ou tem e a busca não achou.
            final semNenhum =
                ref.watch(pacientesProvider).value?.isEmpty ?? false;
            if (semNenhum) {
              return AppEstado.central(
                titulo: AppStrings.pacientesVaziaTitulo,
                texto: AppStrings.pacientesVaziaTexto,
                acao: AppBotao.primario(
                  rotulo: AppStrings.pacientesCadastrar,
                  icone: NomeIcone.adicionar,
                  aoTocar: () => _novaAvaliacao(context),
                ),
              );
            }
            return AppEstado.central(
              titulo: AppStrings.pacientesSemResultado(
                ref.watch(buscaPacientesProvider).trim(),
              ),
              texto: AppStrings.pacientesSemResultadoDica,
              acao: AppBotao.secundario(
                rotulo: AppStrings.pacientesLimparBusca,
                aoTocar: () =>
                    ref.read(buscaPacientesProvider.notifier).limpar(),
              ),
            );
          },
        );
  }
}

// ------------------------------------------------------------- layouts --

class _LayoutExpandido extends StatelessWidget {
  const _LayoutExpandido({
    required this.aoNovaAvaliacao,
    required this.conteudo,
  });

  /// Nulo esconde o botão.
  final VoidCallback? aoNovaAvaliacao;
  final Widget conteudo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          // Altura MÍNIMA, não fixa: com o texto do sistema ampliado o rótulo
          // do botão quebra linha e a barra precisa crescer junto. Presa em
          // 76 px ela estourava por baixo a partir de 1,3×.
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.cores.borda)),
          ),
          // Wrap, não Row com Spacer: em 1024 px de janela o painel já é
          // estreito, e com a fonte ampliada busca, contagem e botão não cabem
          // na mesma linha. O botão desce inteiro em vez de ser espremido.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  // Teto, não largura fixa: o campo encolhe se o painel for
                  // menor que isso.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: const _CampoBusca(),
                  ),
                  const _Contagem(),
                ],
              ),
              if (aoNovaAvaliacao case final aoTocar?)
                AppBotao.primario(
                  rotulo: AppStrings.navNovaAvaliacao,
                  icone: NomeIcone.adicionar,
                  aoTocar: aoTocar,
                ),
            ],
          ),
        ),
        Expanded(child: conteudo),
      ],
    );
  }
}

class _LayoutCompacto extends ConsumerWidget {
  const _LayoutCompacto({
    required this.aoNovaAvaliacao,
    required this.conteudo,
  });

  /// Nulo esconde a barra do botão.
  final VoidCallback? aoNovaAvaliacao;
  final Widget conteudo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.cores.borda)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Wrap, não Row: com o texto do sistema ampliado, marca e
                  // indicador não cabem lado a lado e o indicador desce.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          AppStrings.appTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.95,
                                color: context.cores.acento,
                              ),
                        ),
                      ),
                      AppIndicadorConexao(
                        online: ref.watch(conexaoOnlineProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _CampoBusca(),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: conteudo),
        if (aoNovaAvaliacao case final aoTocar?)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.cores.borda)),
            ),
            child: AppBotao.primario(
              rotulo: AppStrings.navNovaAvaliacao,
              icone: NomeIcone.adicionar,
              aoTocar: aoTocar,
              ocupaLargura: true,
            ),
          ),
      ],
    );
  }
}

/// Contagem do resultado da busca. Sozinha num widget porque é uma das duas
/// coisas que mudam a cada tecla — a outra é o [_Conteudo].
class _Contagem extends ConsumerWidget {
  const _Contagem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantidade = ref.watch(pacientesFiltradosProvider).value?.length;
    // Nada enquanto a lista carrega: "0 pacientes" durante o carregamento
    // seria uma afirmação falsa.
    if (quantidade == null) return const SizedBox.shrink();

    // Anunciada quando muda: é a resposta da busca para quem não enxerga a
    // tabela encolher.
    return Semantics(
      liveRegion: true,
      child: Text(
        AppStrings.pacientesQuantidade(quantidade),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.cores.secundario),
      ),
    );
  }
}

class _CampoBusca extends ConsumerStatefulWidget {
  const _CampoBusca();

  @override
  ConsumerState<_CampoBusca> createState() => _CampoBuscaState();
}

class _CampoBuscaState extends ConsumerState<_CampoBusca> {
  /// O texto fica no controlador do campo e o termo no controlador de estado.
  /// São a mesma informação em dois lugares porque o `TextField` exige o
  /// primeiro; a sincronia vai num sentido só, daqui para lá, com uma exceção
  /// tratada no `build`.
  late final _texto = TextEditingController(
    text: ref.read(buscaPacientesProvider),
  );

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `listen`, não `watch`: o campo é a ORIGEM do termo e não precisa se
    // reconstruir a cada tecla. O que precisa chegar até aqui é a limpeza
    // vinda de fora — o botão "Limpar busca" do estado sem resultado.
    ref.listen(buscaPacientesProvider, (_, termo) {
      if (termo != _texto.text) _texto.text = termo;
    });

    final estiloDoTexto = Theme.of(context).textTheme.bodyMedium;

    // Mesmo padrão do AppCampoTexto: rótulo e campo fundidos num nó só, para o
    // leitor de tela anunciar o campo COM NOME em vez de "caixa de edição".
    //
    // A diferença é que aqui o rótulo não aparece na tela — um "Buscar" em
    // cima de uma caixa de busca só ocuparia altura no celular, e a dica
    // dentro do campo já faz esse papel visualmente. Só que a dica SOME quando
    // se digita, e com ela sumia o nome do campo; por isso o rótulo é
    // declarado em `Semantics` e a dica sai da semântica, senão o leitor
    // anunciaria o mesmo texto duas vezes enquanto o campo está vazio.
    return MergeSemantics(
      child: Semantics(
        label: AppStrings.pacientesBuscaDica,
        textField: true,
        child: TextField(
          controller: _texto,
          onChanged: (termo) =>
              ref.read(buscaPacientesProvider.notifier).digitar(termo),
          textInputAction: TextInputAction.search,
          autocorrect: false,
          style: estiloDoTexto,
          decoration: InputDecoration(
            hint: ExcludeSemantics(
              child: Text(
                AppStrings.pacientesBuscaDica,
                style: estiloDoTexto?.copyWith(color: context.cores.secundario),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- listas --

class _Tabela extends StatelessWidget {
  const _Tabela({required this.pacientes});

  final List<Paciente> pacientes;

  static const _margem = 34.0;

  @override
  Widget build(BuildContext context) {
    final cabecalho = AppTypography.overline.copyWith(
      color: context.cores.secundario,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_margem, 14, _margem, 8),
          child: ExcludeSemantics(
            // Cada linha já anuncia "tendência AVQI: ..." por inteiro; o
            // cabeçalho visual repetido a cada linha só atrapalharia.
            child: _Colunas(
              paciente: Text(
                AppStrings.pacientesColunaPaciente.toUpperCase(),
                style: cabecalho,
              ),
              sessao: Text(
                AppStrings.pacientesColunaUltimaSessao.toUpperCase(),
                style: cabecalho,
              ),
              tendencia: Text(
                AppStrings.pacientesColunaTendencia.toUpperCase(),
                style: cabecalho,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(_margem, 0, _margem, 20),
            children: [
              for (final p in pacientes) _LinhaTabela(paciente: p),
              const _NotaTendencia(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grade de colunas compartilhada pelo cabeçalho e pelas linhas.
class _Colunas extends StatelessWidget {
  const _Colunas({
    required this.paciente,
    required this.sessao,
    required this.tendencia,
    this.seta,
  });

  final Widget paciente;
  final Widget sessao;
  final Widget tendencia;
  final Widget? seta;

  static const _vao = SizedBox(width: 14);

  /// Proporção das colunas de texto, no lugar de largura fixa em pixel.
  ///
  /// Coluna presa em pixel não acompanha o texto do sistema ampliado: o
  /// conteúdo crescia, a caixa não, e a linha estourava à direita a partir de
  /// 1,3×. Com flex a repartição segue a mesma leitura do protótipo em 100% e
  /// continua válida em qualquer escala.
  static const _flexPaciente = 7;
  static const _flexSessao = 2;
  static const _flexTendencia = 3;

  /// A seta continua em pixel de propósito: é um ícone de 22 px que NÃO
  /// acompanha a escala de texto, então dar flex a ela só tiraria espaço das
  /// colunas que precisam.
  static const _larguraDaSeta = 34.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: _flexPaciente, child: paciente),
        _vao,
        Expanded(flex: _flexSessao, child: sessao),
        _vao,
        Expanded(flex: _flexTendencia, child: tendencia),
        _vao,
        SizedBox(width: _larguraDaSeta, child: seta),
      ],
    );
  }
}

class _LinhaTabela extends StatelessWidget {
  const _LinhaTabela({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return AppToque(
      aoTocar: () => _abrir(context, paciente),
      corDoHover: context.cores.suave,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.cores.borda)),
        ),
        child: _Colunas(
          paciente: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(paciente.nome, style: textos.titleMedium),
              const SizedBox(height: 2),
              Text(
                paciente.queixa,
                style: textos.bodySmall?.copyWith(
                  color: context.cores.secundario,
                ),
              ),
            ],
          ),
          sessao: Text(
            _data(paciente.ultimaSessao),
            style: textos.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          tendencia: Align(
            alignment: Alignment.centerLeft,
            child: _ChipTendencia(direcao: paciente.direcaoAvqi),
          ),
          seta: AppIcone(
            nome: NomeIcone.avancar,
            cor: context.cores.acento,
            tamanho: 22,
          ),
        ),
      ),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.pacientes});

  final List<Paciente> pacientes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.sm,
      ),
      children: [
        for (final p in pacientes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm - 2),
            child: _Card(paciente: p),
          ),
        const _NotaTendencia(),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: context.cores.secundario,
    );

    return AppToque(
      aoTocar: () => _abrir(context, paciente),
      raio: AppRadius.bordaMedia,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        decoration: BoxDecoration(
          border: Border.all(color: context.cores.borda),
          borderRadius: AppRadius.bordaMedia,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(paciente.nome, style: textos.titleMedium),
                      Text(paciente.queixa, style: secundario),
                    ],
                  ),
                ),
                AppIcone(
                  nome: NomeIcone.avancar,
                  cor: context.cores.acento,
                  tamanho: 22,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Wrap, não Row: com fonte ampliada pelo sistema, a data e o chip
            // não cabem lado a lado em 390 px, e cortar texto clínico não é
            // opção.
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  paciente.ultimaSessao == null
                      ? AppStrings.pacientesNenhumaSessao
                      : AppStrings.pacientesUltimaSessao(
                          AppStrings.data(paciente.ultimaSessao!),
                        ),
                  style: secundario?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                _ChipTendencia(direcao: paciente.direcaoAvqi, compacto: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _data(DateTime? data) =>
    data == null ? AppStrings.pacientesNenhumaSessao : AppStrings.data(data);

// ------------------------------------------------------------ elementos --

/// Tendência do AVQI: seta mais texto, sempre os dois — e cada um dizendo uma
/// coisa diferente.
///
/// A SETA É A DIREÇÃO DO NÚMERO, nunca a leitura. No AVQI menor é melhor, então
/// "melhorando" vem com seta para BAIXO — igual à linha do gráfico da tela de
/// evolução, que também desce. Antes a seta apontava para cima ao lado da
/// palavra "melhorando" e contradizia tanto o número quanto o gráfico.
///
/// Quem diz o que a direção significa é [lerEvolucao], no domínio. A palavra
/// carrega essa leitura; o ícone não carrega informação nenhuma que o texto
/// não diga.
///
/// SEM verde e vermelho, divergindo do protótipo: o CLAUDE.md reserva essas
/// cores para status de normalidade de medida e saturação de áudio, e
/// tendência não é nenhum dos dois. TODO(clínico): confirmar com a banca/
/// orientação, junto do vocabulário "melhorando/piorando".
class _ChipTendencia extends StatelessWidget {
  const _ChipTendencia({required this.direcao, this.compacto = false});

  /// Para onde o AVQI foi. A coluna é "Tendência AVQI" — a medida é fixa, e é
  /// dela que sai o sentido de leitura.
  final DirecaoDaMedida direcao;

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final icone = switch (direcao) {
      DirecaoDaMedida.subiu => NomeIcone.tendenciaSobe,
      DirecaoDaMedida.estavel => NomeIcone.tendenciaEstavel,
      DirecaoDaMedida.desceu => NomeIcone.tendenciaDesce,
      DirecaoDaMedida.semComparacao => null,
    };

    final texto = switch (lerEvolucao(
      medida: MedidaAcustica.avqi,
      direcao: direcao,
    )) {
      LeituraDaEvolucao.melhora => AppStrings.tendenciaMelhorando,
      LeituraDaEvolucao.estavel => AppStrings.tendenciaEstavel,
      LeituraDaEvolucao.piora => AppStrings.tendenciaPiorando,
      // No AVQI a única origem de "sem leitura" é a falta de sessão anterior:
      // a medida tem sentido de melhora definido.
      LeituraDaEvolucao.semLeitura => AppStrings.tendenciaSemComparacao,
    };

    final comparavel = icone != null;
    final cor = comparavel ? context.cores.texto : context.cores.secundario;

    return Semantics(
      label: AppStrings.pacientesTendencia(texto),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? 9 : 12,
          vertical: compacto ? 2 : 4,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.bordaPilula,
          border: Border.all(
            // Sem comparação a borda fica lavanda, mais leve: não há
            // afirmação nenhuma sendo feita.
            color: comparavel ? cor : context.cores.borda,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              AppIcone(nome: icone, cor: cor, tamanho: 16),
              const SizedBox(width: AppSpacing.xxs + 2),
            ],
            // Flexible: o ícone tem tamanho fixo, a palavra não. Com o texto
            // do sistema ampliado "melhorando" passava da largura da coluna e
            // estourava a linha; agora quebra dentro da pílula.
            Flexible(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cor,
                  fontWeight: comparavel ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotaTendencia extends StatelessWidget {
  const _NotaTendencia();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        AppStrings.pacientesNotaTendencia,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.cores.secundario),
      ),
    );
  }
}
