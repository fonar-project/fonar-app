import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_movimento.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_area_com_acoes.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_escolha_unica.dart';
import '../../../../design_system/widgets/app_fundo.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../../guia/domain/passo_do_guia.dart';
import '../../../guia/presentation/alvos_do_guia.dart';
import '../../../guia/presentation/widgets/abertura_do_guia.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../reproducao/presentation/widgets/player_de_amostra.dart';
import '../../data/configuracao_de_captura.dart';
import '../../domain/afericao_de_ruido.dart';
import '../../domain/amostra.dart';
import '../../domain/ajuste_de_configuracao.dart';
import '../../domain/microfone.dart';
import '../../domain/processamento_automatico.dart';
import '../../domain/verificacao_da_amostra.dart';
import '../afericao_controlador.dart';
import '../gravacao_controlador.dart';
import '../microfone_controlador.dart';
import 'medidor_de_nivel.dart';

/// A gravação guiada, uma etapa por vez, como no protótipo: o ruído da sala e
/// depois cada tarefa, e no fim a revisão das amostras antes de enviar.
///
/// Cada etapa tem uma instrução GRANDE, escrita para o paciente — em
/// consulta ele lê de ~1 m, com o aparelho virado para ele —, o medidor de
/// nível enquanto grava e poucas ações, uma delas em destaque. No desktop,
/// Espaço inicia e para a gravação, e R regrava.
///
/// A etapa mostrada é estado da TELA; o que foi gravado, medido e conferido
/// continua nos controladores da aferição e da gravação.
class GravacaoGuiada extends ConsumerStatefulWidget {
  const GravacaoGuiada({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  ConsumerState<GravacaoGuiada> createState() => _GravacaoGuiadaState();
}

/// Etapa 0 é o ruído; de 1 a [_tarefas] são as tarefas; depois, a revisão.
const _tarefas = TarefaDeGravacao.values;
const _ruido = 0;
final _revisao = _tarefas.length + 1;

class _GravacaoGuiadaState extends ConsumerState<GravacaoGuiada> {
  var _etapa = _ruido;
  final _foco = FocusNode(debugLabel: 'gravação guiada');

  /// A rolagem do palco. Quando a etapa ou a fase muda, volta ao topo: com a
  /// tela baixa tudo rola, e tocar em "Continuar" lá embaixo deixava a etapa
  /// nova aparecer com o começo dela — o "Etapa 2 de 3" e a instrução —
  /// escondido em cima.
  final _rolagem = ScrollController();
  Object? _faseMostrada;

  String get _id => widget.pacienteId;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_tecla);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_tecla);
    _foco.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  /// Espaço e R, com o foco na tela e não num controle: num botão focado
  /// pelo Tab, Espaço é do botão. Fora da rota do topo — um diálogo aberto,
  /// outra tela por cima —, nenhum dos dois.
  bool _tecla(KeyEvent evento) {
    if (evento is! KeyDownEvent || !mounted) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final foco = FocusManager.instance.primaryFocus;
    final livre = foco == null || foco == _foco || foco is FocusScopeNode;
    if (!livre) return false;
    switch (evento.logicalKey) {
      case LogicalKeyboardKey.space:
        _espaco();
        return true;
      case LogicalKeyboardKey.keyR:
        _regravar();
        return true;
    }
    return false;
  }

  void _irPara(int etapa) => setState(() => _etapa = etapa);

  /// A primeira tarefa ainda sem amostra, ou a revisão.
  int _proximaPendente(EstadoDaGravacao estado) {
    for (final (i, tarefa) in _tarefas.indexed) {
      if (estado.amostras[tarefa] == null) return i + 1;
    }
    return _revisao;
  }

  GravacaoControlador get _gravacao =>
      ref.read(gravacaoControladorProvider(_id).notifier);

  /// Espaço: medir o ruído, iniciar ou parar a gravação da etapa.
  void _espaco() {
    final gravacao = ref.read(gravacaoControladorProvider(_id));
    final afericao = ref.read(afericaoControladorProvider);
    if (_etapa == _ruido) {
      if (afericao is AfericaoNaoIniciada) {
        ref.read(afericaoControladorProvider.notifier).medir();
      }
      return;
    }
    if (_etapa == _revisao) return;
    final tarefa = _tarefas[_etapa - 1];
    if (gravacao.gravando == tarefa) {
      _gravacao.parar();
    } else if (!gravacao.ocupado && gravacao.amostras[tarefa] == null) {
      _gravacao.iniciar(tarefa);
    }
  }

  /// R: regravar a tarefa da etapa.
  void _regravar() {
    final gravacao = ref.read(gravacaoControladorProvider(_id));
    if (_etapa == _ruido || _etapa == _revisao || gravacao.ocupado) return;
    _gravacao.iniciar(_tarefas[_etapa - 1]);
  }

  @override
  Widget build(BuildContext context) {
    final afericao = ref.watch(afericaoControladorProvider);
    final gravacao = ref.watch(gravacaoControladorProvider(_id));
    final liberada = afericao is AfericaoConcluida && afericao.liberaGravacao;
    // Sem aferição que libere, só a etapa do ruído — o microfone pode estar
    // mudo, e isso se descobre antes da consulta, não depois.
    final etapa = liberada ? _etapa : _ruido;

    // A dica da primeira vez (US50) só com nada em andamento: antes de medir
    // o ruído, nunca no meio de uma gravação.
    return AberturaDaDica(
      dica: DicaDeTela.gravacao,
      pronta:
          afericao is AfericaoNaoIniciada &&
          !gravacao.ocupado &&
          !gravacao.retomando,
      child: LayoutBuilder(
        builder: (context, restricoes) {
          final compacta =
              Breakpoints.de(restricoes.maxWidth) == LarguraDeTela.compacta;
          final palco = switch (etapa) {
            _ruido => _palcoDoRuido(afericao, gravacao),
            _ when etapa == _revisao => _palcoDaRevisao(gravacao),
            _ => _palcoDaTarefa(_tarefas[etapa - 1], gravacao),
          };

          final etapas = _Etapas(
            atual: etapa,
            concluidas: {
              if (liberada && etapa != _ruido) _ruido,
              for (final (i, tarefa) in _tarefas.indexed)
                if (gravacao.amostras[tarefa] != null) i + 1,
            },
            compacta: compacta,
            // Mudar de etapa no meio de uma gravação a deixaria órfã na tela.
            aoEscolher: liberada && !gravacao.ocupado ? _irPara : null,
          );

          // A fase do palco: muda quando a etapa avança, quando a gravação
          // começa ou termina, quando a conferência devolve o resultado. É ela
          // que decide quando o conteúdo entra animado — ver `AppTrocaAnimada`.
          final fase = switch (etapa) {
            _ruido => afericao.runtimeType,
            _ when etapa == _revisao => 'revisão',
            _ => switch (_tarefas[etapa - 1]) {
              final t when gravacao.gravando == t => 'gravando',
              final t when gravacao.conferindo == t => 'conferindo',
              final t
                  when gravacao.amostras[t] != null ||
                      gravacao.rejeitadas[t] != null ||
                      gravacao.falha?.tarefa == t =>
                'resultado',
              _ => 'pronto',
            },
          };

          final chaveDaFase = (etapa, fase);
          if (_faseMostrada != null && _faseMostrada != chaveDaFase) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_rolagem.hasClients) _rolagem.jumpTo(0);
            });
          }
          _faseMostrada = chaveDaFase;

          final conteudo = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (gravacao.retomadaDe case final inicio?) ...[
                AppSituacao(
                  icone: NomeIcone.informacao,
                  titulo: AppStrings.capturaRetomadaTitulo,
                  texto: AppStrings.capturaRetomadaTexto(
                    AppStrings.hora(inicio),
                    gravacao.amostras.length,
                    _tarefas.length,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTrocaAnimada(
                chave: chaveDaFase,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: palco.corpo,
                ),
              ),
            ],
          );

          // Tela baixa — celular deitado, ou o texto do sistema ampliado —: nada
          // fica preso, tudo rola junto. Ver `AppAreaComAcoes`.
          final baixa =
              restricoes.maxHeight < AppAreaComAcoes.alturaParaFixar(context);

          final Widget tela;
          if (compacta) {
            tela = AppAreaComAcoes(
              controller: _rolagem,
              topo: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: etapas,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              centralizar: true,
              // No celular o texto do rodapé rola com o conteúdo: na barra fixa,
              // com o texto em 200%, não sobraria tela.
              corpo: palco.rodape == null
                  ? conteudo
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        conteudo,
                        const SizedBox(height: AppSpacing.sm),
                        _Apoio(palco.rodape!),
                      ],
                    ),
              acoes: palco.acoes.isEmpty
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: context.cores.borda),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, acao) in palco.acoes.indexed) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.xs),
                                acao.botao(ocupaLargura: true),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            );
          } else {
            final corpoDoCartao = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                conteudo,
                if (palco.acoes.isNotEmpty && palco.rodape == null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final acao in palco.acoes)
                        acao.botao(ocupaLargura: false),
                    ],
                  ),
                ],
              ],
            );
            final cartao = Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.cores.borda),
                borderRadius: AppRadius.bordaMedia,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (baixa)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: corpoDoCartao,
                    )
                  else
                    Expanded(
                      child: _Rolavel(
                        controller: _rolagem,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: corpoDoCartao,
                      ),
                    ),
                  if (palco.rodape case final rodape?)
                    _Rodape(texto: rodape, acoes: palco.acoes)
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        AppStrings.capturaAtalhos,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: context.cores.secundario),
                      ),
                    ),
                ],
              ),
            );
            final coluna = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                etapas,
                const SizedBox(height: 22),
                if (baixa) cartao else Expanded(child: cartao),
              ],
            );
            const respiro = EdgeInsets.fromLTRB(34, 26, 34, 26);
            tela = baixa
                ? SingleChildScrollView(
                    controller: _rolagem,
                    padding: respiro,
                    child: coluna,
                  )
                : Padding(padding: respiro, child: coluna);
          }

          // O foco começa na tela, para os atalhos valerem sem clicar antes.
          return Focus(focusNode: _foco, autofocus: true, child: tela);
        },
      ),
    );
  }

  // ---------------------------------------------------------------- ruído --

  _Palco _palcoDoRuido(EstadoDaAfericao afericao, EstadoDaGravacao gravacao) {
    void medir() => ref.read(afericaoControladorProvider.notifier).medir();
    void conferirComAVoz() =>
        ref.read(afericaoControladorProvider.notifier).conferirComAVoz();
    // A escolha do microfone aparece depois da primeira aferição — que já
    // pediu a permissão, sem a qual o navegador não dá os nomes. Trocar mede
    // de novo; com o microfone ocupado ou uma gravação em andamento, espera.
    Widget escolha({required bool livre}) => _EscolhaDoMicrofone(
      aoEscolher: livre && !gravacao.ocupado
          ? (m) => ref
                .read(afericaoControladorProvider.notifier)
                .trocarMicrofone(m)
          : null,
    );
    final cabeca = _Cabeca(
      rotulo: AppStrings.etapaDe(
        1,
        _tarefas.length + 1,
        AppStrings.etapaRuidoNome,
      ),
      instrucao: switch (afericao) {
        AfericaoNaoIniciada() => AppStrings.instrucaoRuidoPronto,
        AfericaoMedindo() => AppStrings.instrucaoRuidoMedindo,
        AfericaoConferindoVoz() => AppStrings.instrucaoRuidoConferindoVoz,
        AfericaoSemPermissao() ||
        AfericaoFalhou() => AppStrings.instrucaoRuidoSemMicrofone,
        AfericaoConcluida(:final resultado) => switch (resultado.conclusao) {
          ConclusaoDaAfericao.microfoneMudo
              when resultado.voz == ConferenciaComAVoz.naoFeita =>
            AppStrings.instrucaoRuidoSilencio,
          ConclusaoDaAfericao.microfoneMudo => AppStrings.instrucaoRuidoMudo,
          ConclusaoDaAfericao.ruidoAlto => AppStrings.instrucaoRuidoAlto,
          ConclusaoDaAfericao.semRestricao => AppStrings.instrucaoRuidoOk,
        },
      },
    );

    return switch (afericao) {
      AfericaoNaoIniciada() => _Palco(
        corpo: [
          cabeca,
          const SizedBox(height: AppSpacing.md),
          const _Apoio(AppStrings.afericaoExplicacao),
        ],
        acoes: [
          _Acao.primaria(
            AppStrings.afericaoMedir,
            medir,
            alvo: PapelNoGuia.afericao,
          ),
        ],
      ),
      AfericaoMedindo(:final nivel, :final progresso) => _Palco(
        corpo: [
          cabeca,
          const SizedBox(height: AppSpacing.lg),
          _Limitado(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MedidorDeNivel(dbfs: nivel, ambiente: true),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppRadius.bordaPilula,
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 4,
                    color: context.cores.acento,
                    backgroundColor: context.cores.borda,
                  ),
                ),
              ],
            ),
          ),
        ],
        acoes: const [],
      ),
      AfericaoConferindoVoz(:final nivel, :final progresso) => _Palco(
        corpo: [
          cabeca,
          const SizedBox(height: AppSpacing.lg),
          _Limitado(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MedidorDeNivel(dbfs: nivel),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppRadius.bordaPilula,
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 4,
                    color: context.cores.acento,
                    backgroundColor: context.cores.borda,
                  ),
                ),
              ],
            ),
          ),
        ],
        acoes: const [],
      ),
      AfericaoSemPermissao() => _Palco(
        corpo: [
          cabeca,
          const SizedBox(height: AppSpacing.lg),
          const _Limitado(
            child: AppSituacao(
              icone: NomeIcone.negacao,
              titulo: AppStrings.afericaoSemPermissao,
              texto: AppStrings.afericaoSemPermissaoTexto,
            ),
          ),
        ],
        acoes: [_Acao.primaria(AppStrings.tentarNovamente, medir)],
      ),
      AfericaoFalhou(:final microfoneLiberado, :final demorouParaLiberar) =>
        _Palco(
          corpo: [
            cabeca,
            const SizedBox(height: AppSpacing.lg),
            _Limitado(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSituacao(
                    icone: NomeIcone.negacao,
                    titulo: AppStrings.afericaoFalhou,
                    texto: AppStrings.afericaoFalhouTexto,
                  ),
                  escolha(livre: microfoneLiberado),
                  if (demorouParaLiberar) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _MicrofoneDemorando(),
                  ],
                ],
              ),
            ),
          ],
          acoes: [
            _Acao.primaria(
              AppStrings.tentarNovamente,
              microfoneLiberado ? medir : null,
              motivo: AppStrings.afericaoLiberandoMicrofone,
            ),
          ],
        ),
      AfericaoConcluida(
        :final resultado,
        :final ajuste,
        :final microfoneLiberado,
        :final demorouParaLiberar,
        :final liberaGravacao,
        :final podeConferirComAVoz,
        :final processamentoLigado,
        :final bancoSoNaMemoria,
      ) =>
        _Palco(
          corpo: [
            cabeca,
            const SizedBox(height: AppSpacing.lg),
            _Limitado(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Conclusao(resultado: resultado),
                  escolha(livre: microfoneLiberado),
                  if (ajuste != null &&
                      !ajuste.confere(
                        taxaPedida: ConfiguracaoDeCaptura.taxaDeAmostragem,
                        canaisPedidos: ConfiguracaoDeCaptura.canais,
                      )) ...[
                    const SizedBox(height: AppSpacing.md),
                    _Ajuste(ajuste: ajuste),
                  ],
                  // O processamento automático muda o que a análise mede:
                  // com ele ligado, a gravação não abre (US42).
                  if (ajuste != null && processamentoLigado) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ProcessamentoLigado(ligados: ajuste.processamentoLigado),
                  ],
                  if (bancoSoNaMemoria) ...[
                    const SizedBox(height: AppSpacing.md),
                    const AppSituacao(
                      icone: NomeIcone.negacao,
                      titulo: AppStrings.capturaSemArmazenamento,
                      texto: AppStrings.capturaSemArmazenamentoTexto,
                    ),
                  ],
                  if (demorouParaLiberar) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _MicrofoneDemorando(),
                  ],
                  // Silêncio absoluto é falha, não sala silenciosa: a
                  // gravação não abre — ver `microphone_permission.dart`.
                  if (resultado.conclusao ==
                      ConclusaoDaAfericao.microfoneMudo) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _Apoio(AppStrings.capturaBloqueadaMicrofone),
                  ],
                ],
              ),
            ),
          ],
          acoes: [
            if (liberaGravacao)
              _Acao.primaria(
                AppStrings.capturaContinuar,
                () => _irPara(_proximaPendente(gravacao)),
              ),
            // Silêncio digital: só a voz diz se é a sala ou o microfone.
            if (resultado.conclusao == ConclusaoDaAfericao.microfoneMudo)
              _Acao(
                rotulo: AppStrings.afericaoConferirComAVoz,
                aoTocar: podeConferirComAVoz && !gravacao.ocupado
                    ? conferirComAVoz
                    : null,
                motivo: gravacao.ocupado
                    ? AppStrings.afericaoEsperaGravacao
                    : AppStrings.afericaoLiberandoMicrofone,
                primaria: true,
              ),
            _Acao(
              rotulo: AppStrings.afericaoMedirDeNovo,
              aoTocar: gravacao.ocupado || !microfoneLiberado ? null : medir,
              motivo: gravacao.ocupado
                  ? AppStrings.afericaoEsperaGravacao
                  : AppStrings.afericaoLiberandoMicrofone,
              primaria:
                  !liberaGravacao &&
                  resultado.conclusao != ConclusaoDaAfericao.microfoneMudo,
            ),
          ],
        ),
    };
  }

  // -------------------------------------------------------------- tarefa --

  _Palco _palcoDaTarefa(TarefaDeGravacao tarefa, EstadoDaGravacao estado) {
    final indice = _tarefas.indexOf(tarefa);
    final nome = _nomeDa(tarefa);
    final (pronto, gravando) = switch (tarefa) {
      TarefaDeGravacao.vogalSustentada => (
        AppStrings.instrucaoVogalPronto,
        AppStrings.instrucaoVogalGravando,
      ),
      TarefaDeGravacao.falaEncadeada => (
        AppStrings.instrucaoFalaPronto,
        AppStrings.instrucaoFalaGravando,
      ),
    };
    final rotulo = AppStrings.etapaDe(indice + 2, _tarefas.length + 1, nome);
    final amostra = estado.amostras[tarefa];
    final rejeitada = estado.rejeitadas[tarefa];
    final falha = estado.falha?.tarefa == tarefa ? estado.falha!.motivo : null;
    final ultima = indice == _tarefas.length - 1;
    void iniciar() => _gravacao.iniciar(tarefa);
    void seguir() => _irPara(indice + 2);
    final proxima = ultima
        ? AppStrings.capturaConcluirERevisar
        : AppStrings.capturaProximaEtapa;

    if (estado.gravando == tarefa) {
      return _Palco(
        corpo: [
          _Cabeca(rotulo: rotulo, instrucao: gravando),
          const SizedBox(height: AppSpacing.lg),
          _Cronometro(decorrido: estado.decorrido),
          const SizedBox(height: AppSpacing.md),
          _Limitado(child: MedidorDeNivel(dbfs: estado.nivel)),
        ],
        acoes: [
          _Acao(
            rotulo: AppStrings.tarefaParar,
            aoTocar: _gravacao.parar,
            icone: NomeIcone.pausar,
            primaria: true,
          ),
        ],
      );
    }
    if (estado.conferindo == tarefa) {
      return _Palco(
        corpo: [
          _Cabeca(rotulo: rotulo, instrucao: AppStrings.instrucaoConferindo),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: context.cores.acento,
              ),
            ),
          ),
        ],
        acoes: const [],
      );
    }

    final outraOcupando = estado.ocupado;
    final resultado = <Widget>[
      if (amostra != null) ...[
        _SituacaoDaAmostra(amostra: amostra),
        const SizedBox(height: AppSpacing.xs),
        // Ouvir antes de seguir: é assim que se nota um ruído de fundo ou
        // uma tosse que o medidor não mostra.
        PlayerDeAmostra(
          caminho: amostra.caminho,
          rotulo: nome,
          duracaoConhecida: amostra.duracao,
          bloqueio: outraOcupando
              ? AppStrings.reproducaoBloqueadaGravando
              : null,
        ),
      ],
      if (rejeitada != null) ...[
        if (amostra != null) const SizedBox(height: AppSpacing.md),
        _Rejeitada(problemas: rejeitada, haAnterior: amostra != null),
      ],
      if (falha != null) ...[
        if (amostra != null || rejeitada != null)
          const SizedBox(height: AppSpacing.md),
        _Falha(motivo: falha),
      ],
    ];

    // Sem nada gravado ainda: a instrução e o botão de começar.
    if (resultado.isEmpty) {
      return _Palco(
        corpo: [_Cabeca(rotulo: rotulo, instrucao: pronto, provisoria: true)],
        acoes: [
          _Acao(
            rotulo: AppStrings.capturaIniciarGravacao,
            aoTocar: outraOcupando ? null : iniciar,
            icone: NomeIcone.gravar,
            motivo: AppStrings.tarefaOutraEmAndamento,
            primaria: true,
          ),
        ],
      );
    }

    final recusada = rejeitada != null || falha != null;
    final instrucao = switch (amostra) {
      _ when recusada && amostra == null =>
        falha != null
            ? AppStrings.tarefaFalhaTitulo
            : AppStrings.instrucaoAmostraRecusada,
      _ when recusada => AppStrings.instrucaoAmostraRecusada,
      final a? when a.problemas.isNotEmpty =>
        AppStrings.instrucaoAmostraRessalva,
      _ => AppStrings.instrucaoAmostraBoa,
    };
    // Regravar é o passo em destaque quando a última tentativa não serviu,
    // ou quando a amostra guardada tem ressalva.
    final regravarEmDestaque =
        recusada || (amostra?.problemas.isNotEmpty ?? false);

    return _Palco(
      corpo: [
        _Cabeca(rotulo: rotulo, instrucao: instrucao),
        const SizedBox(height: AppSpacing.lg),
        _Limitado(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: resultado,
          ),
        ),
      ],
      acoes: [
        _Acao(
          rotulo: AppStrings.capturaRegravar,
          aoTocar: outraOcupando ? null : iniciar,
          icone: NomeIcone.gravar,
          motivo: AppStrings.tarefaOutraEmAndamento,
          primaria: regravarEmDestaque || amostra == null,
        ),
        if (amostra != null)
          _Acao(
            rotulo: proxima,
            aoTocar: outraOcupando ? null : seguir,
            icone: NomeIcone.avancar,
            motivo: AppStrings.capturaEsperaTerminar,
            primaria: !regravarEmDestaque,
          ),
      ],
    );
  }

  // ------------------------------------------------------------- revisão --

  _Palco _palcoDaRevisao(EstadoDaGravacao estado) {
    final afericao = ref.read(afericaoControladorProvider);
    final gravadas = estado.amostras.length;
    return _Palco(
      corpo: [
        const _Cabeca(
          rotulo: AppStrings.revisaoTitulo,
          instrucao: AppStrings.revisaoInstrucao,
          grande: false,
        ),
        const SizedBox(height: AppSpacing.lg),
        _Limitado(
          largura: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (afericao case AfericaoConcluida(:final resultado))
                _LinhaDaRevisao(
                  titulo: AppStrings.afericaoTitulo,
                  aoRefazer: estado.ocupado ? null : () => _irPara(_ruido),
                  rotuloDoRefazer: AppStrings.afericaoMedirDeNovo,
                  child: _Conclusao(resultado: resultado),
                ),
              for (final (i, tarefa) in _tarefas.indexed)
                _LinhaDaRevisao(
                  titulo: _nomeDa(tarefa),
                  aoRefazer: estado.ocupado ? null : () => _irPara(i + 1),
                  rotuloDoRefazer: AppStrings.capturaRegravar,
                  child: switch (estado.amostras[tarefa]) {
                    final amostra? => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SituacaoDaAmostra(amostra: amostra),
                        const SizedBox(height: AppSpacing.xs),
                        PlayerDeAmostra(
                          caminho: amostra.caminho,
                          rotulo: _nomeDa(tarefa),
                          duracaoConhecida: amostra.duracao,
                        ),
                      ],
                    ),
                    null => const _Apoio(AppStrings.capturaEnviarFaltaTarefa),
                  },
                ),
            ],
          ),
        ),
      ],
      rodape:
          '${AppStrings.revisaoResumo(gravadas, _tarefas.length)} '
          '${AppStrings.capturaEnviarApoio}',
      acoes: [
        _Acao(
          rotulo: AppStrings.revisaoVoltar,
          aoTocar: estado.ocupado ? null : () => _irPara(_tarefas.length),
          motivo: AppStrings.capturaEsperaTerminar,
        ),
        _Acao(
          rotulo: estado.enviando
              ? AppStrings.capturaEnviando
              : AppStrings.capturaEnviar,
          aoTocar: estado.completa && !estado.ocupado ? _enviar : null,
          icone: NomeIcone.avancar,
          motivo: AppStrings.capturaEnviarFaltaTarefa,
          primaria: true,
        ),
      ],
    );
  }

  Future<void> _enviar() async {
    final nome = ref.read(pacienteProvider(_id)).value?.nome ?? '';
    final pos = await _gravacao.enviarParaAnalise(nomeDoPaciente: nome);
    // Na fila, o trabalho desta tela acabou: quem acompanha é a fila.
    if (pos && mounted) context.goNamed(AppRoutes.filaNome);
  }
}

// ======================================================================
// Peças
// ======================================================================

String _nomeDa(TarefaDeGravacao tarefa) => switch (tarefa) {
  TarefaDeGravacao.vogalSustentada => AppStrings.tarefaVogalTitulo,
  TarefaDeGravacao.falaEncadeada => AppStrings.tarefaFalaTitulo,
};

/// O que o palco de uma etapa mostra: o corpo e as ações — no celular, as
/// ações descem para uma barra fixa embaixo, ao alcance do polegar.
class _Palco {
  const _Palco({required this.corpo, required this.acoes, this.rodape});

  final List<Widget> corpo;
  final List<_Acao> acoes;

  /// Quando há, as ações vão para um rodapé fixo do palco, com este texto
  /// ao lado — na revisão, para "Enviar" não sumir embaixo da lista.
  final String? rodape;
}

class _Acao {
  const _Acao({
    required this.rotulo,
    required this.aoTocar,
    this.icone,
    this.motivo,
    this.primaria = false,
  }) : alvo = null;

  const _Acao.primaria(this.rotulo, this.aoTocar, {this.motivo, this.alvo})
    : icone = null,
      primaria = true;

  final String rotulo;
  final VoidCallback? aoTocar;
  final NomeIcone? icone;
  final String? motivo;
  final bool primaria;

  /// O que o botão é para a dica da primeira vez (US50), se ela o aponta.
  final PapelNoGuia? alvo;

  Widget botao({required bool ocupaLargura}) {
    final botao = AppBotao(
      variante: primaria ? VarianteBotao.primario : VarianteBotao.secundario,
      rotulo: rotulo,
      icone: icone,
      aoTocar: aoTocar,
      motivoDesabilitado: motivo,
      ocupaLargura: ocupaLargura,
    );
    return switch (alvo) {
      final papel? => AlvoDoGuia(papel: papel, child: botao),
      null => botao,
    };
  }
}

/// Centraliza o palco na altura quando cabe, e rola quando não cabe.
class _Rolavel extends StatelessWidget {
  const _Rolavel({
    required this.padding,
    required this.child,
    required this.controller,
  });

  final EdgeInsets padding;
  final Widget child;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) => SingleChildScrollView(
        controller: controller,
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (restricoes.maxHeight - padding.vertical).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Largura de leitura para o que fica embaixo da instrução.
class _Limitado extends StatelessWidget {
  const _Limitado({required this.child, this.largura = 520});

  final Widget child;
  final double largura;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: largura),
      child: child,
    ),
  );
}

/// "ETAPA 2 DE 3 — VOGAL /A/ SUSTENTADA" e a instrução grande.
class _Cabeca extends StatelessWidget {
  const _Cabeca({
    required this.rotulo,
    required this.instrucao,
    this.provisoria = false,
    this.grande = true,
  });

  final String rotulo;
  final String instrucao;

  /// Grande quando é para o paciente ler; na revisão, quem lê é o
  /// profissional, e o espaço é das amostras.
  final bool grande;

  /// O texto dito ao paciente ainda não foi validado — e a tela diz.
  final bool provisoria;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final compacta =
        Breakpoints.de(MediaQuery.sizeOf(context).width) ==
        LarguraDeTela.compacta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          rotulo.toUpperCase(),
          textAlign: TextAlign.center,
          style: textos.labelSmall?.copyWith(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: context.cores.secundario,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Anunciada a cada troca: é o que muda quando a etapa avança.
        Semantics(
          liveRegion: true,
          header: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                instrucao,
                textAlign: TextAlign.center,
                // Grande de propósito: o paciente lê de ~1 m.
                style: textos.displaySmall?.copyWith(
                  fontSize: !grande
                      ? 22
                      : compacta
                      ? 30
                      : 44,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: context.cores.texto,
                ),
              ),
            ),
          ),
        ),
        if (provisoria) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.instrucaoProvisoria,
            textAlign: TextAlign.center,
            style: textos.bodySmall?.copyWith(color: context.cores.secundario),
          ),
        ],
      ],
    );
  }
}

class _Apoio extends StatelessWidget {
  const _Apoio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => _Limitado(
    child: Text(
      texto,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.cores.secundario),
    ),
  );
}

/// "GRAVANDO 00:04".
class _Cronometro extends StatelessWidget {
  const _Cronometro({required this.decorrido});

  final Duration decorrido;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final s = decorrido.inSeconds;
    final mmss =
        '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
    return Semantics(
      label: AppStrings.tarefaGravando(AppStrings.segundos(decorrido)),
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Pulsar(
              child: AppIcone(
                nome: NomeIcone.gravar,
                cor: context.cores.acento,
                tamanho: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppStrings.gravandoRotulo.toUpperCase(),
              style: textos.labelSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: context.cores.acento,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              mmss,
              style: textos.titleLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O ponto de "gravando" pulsando devagar: diz, sem precisar ler, que a
/// captura está acontecendo agora. É o único movimento contínuo da
/// interface além do medidor — e, ao contrário dele, para com movimento
/// reduzido: o texto "Gravando" e o cronômetro já dizem o mesmo.
class _Pulsar extends StatefulWidget {
  const _Pulsar({required this.child});

  final Widget child;

  @override
  State<_Pulsar> createState() => _PulsarState();
}

class _PulsarState extends State<_Pulsar> with SingleTickerProviderStateMixin {
  late final _controle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMovimento.reduzido(context)) {
      _controle
        ..stop()
        ..value = 1;
    } else if (!_controle.isAnimating) {
      _controle.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _controle, curve: Curves.easeInOut)),
    child: widget.child,
  );
}

/// As etapas no topo: número (ou ✓), nome e situação.
class _Etapas extends StatelessWidget {
  const _Etapas({
    required this.atual,
    required this.concluidas,
    required this.compacta,
    required this.aoEscolher,
  });

  final int atual;
  final Set<int> concluidas;
  final bool compacta;

  /// Nulo enquanto não se pode trocar de etapa.
  final ValueChanged<int>? aoEscolher;

  @override
  Widget build(BuildContext context) {
    final nomes = [
      AppStrings.etapaRuidoCurta,
      for (final tarefa in _tarefas)
        switch (tarefa) {
          TarefaDeGravacao.vogalSustentada => AppStrings.tarefaVogalCurta,
          TarefaDeGravacao.falaEncadeada => AppStrings.tarefaFalaCurta,
        },
    ];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (i, nome) in nomes.indexed) ...[
          if (i > 0)
            Container(
              width: compacta ? 12 : 48,
              height: 1.5,
              color: context.cores.borda,
            ),
          _Etapa(
            numero: i + 1,
            nome: nome,
            atual: i == atual,
            concluida: concluidas.contains(i) && i != atual,
            compacta: compacta,
            aoTocar: aoEscolher == null || i == atual
                ? null
                : () => aoEscolher!(i),
          ),
        ],
      ],
    );
  }
}

class _Etapa extends StatelessWidget {
  const _Etapa({
    required this.numero,
    required this.nome,
    required this.atual,
    required this.concluida,
    required this.compacta,
    required this.aoTocar,
  });

  final int numero;
  final String nome;
  final bool atual;
  final bool concluida;
  final bool compacta;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final situacao = atual
        ? AppStrings.etapaEmAndamento
        : concluida
        ? AppStrings.etapaConcluida
        : AppStrings.etapaPendente;
    final destaque = atual || concluida;
    Widget marca(BuildContext context) {
      // A cor da etapa muda com transição curta quando ela é concluída ou
      // passa a ser a atual.
      return AnimatedContainer(
        duration: AppMovimento.duracao(context, AppMovimento.media),
        curve: AppMovimento.curva,
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: atual ? context.cores.primaria : null,
          border: Border.all(
            color: destaque ? context.cores.acento : context.cores.borda,
            width: 1.5,
          ),
        ),
        child: concluida
            ? AppIcone(
                nome: NomeIcone.confirmacao,
                cor: context.cores.acento,
                tamanho: 16,
              )
            : Text(
                '$numero',
                style: textos.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: atual
                      ? context.cores.sobrePrimaria
                      : AppFundo.secundarioDe(context),
                ),
              ),
      );
    }

    Widget conteudo(BuildContext context) {
      return Semantics(
        label: '$nome, $situacao',
        selected: atual,
        button: aoTocar != null,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                marca(context),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: textos.labelSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: atual ? FontWeight.w700 : FontWeight.w600,
                        color: atual
                            ? context.cores.texto
                            : AppFundo.secundarioDe(context),
                      ),
                    ),
                    if (!compacta)
                      Text(
                        situacao,
                        style: textos.bodySmall?.copyWith(
                          fontSize: 12,
                          color: AppFundo.secundarioDe(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (aoTocar case final tocar?) {
      return AppToque(
        aoTocar: tocar,
        raio: AppRadius.bordaPequena,
        conteudo: conteudo,
      );
    }
    return conteudo(context);
  }
}

/// O rodapé do palco no desktop: o texto à esquerda, as ações à direita.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.texto, required this.acoes});

  final String texto;
  final List<_Acao> acoes;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.cores.borda)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.cores.secundario),
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final acao in acoes) acao.botao(ocupaLargura: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma linha da revisão: o que foi gravado, e como refazer.
class _LinhaDaRevisao extends StatelessWidget {
  const _LinhaDaRevisao({
    required this.titulo,
    required this.child,
    required this.aoRefazer,
    required this.rotuloDoRefazer,
  });

  final String titulo;
  final Widget child;
  final VoidCallback? aoRefazer;
  final String rotuloDoRefazer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: context.cores.borda),
          borderRadius: AppRadius.bordaMedia,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                AppBotao.secundario(
                  rotulo: rotuloDoRefazer,
                  aoTocar: aoRefazer,
                  motivoDesabilitado: AppStrings.capturaEsperaTerminar,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------ situações e conclusões --

class _Conclusao extends StatelessWidget {
  const _Conclusao({required this.resultado});

  final ResultadoDaAfericao resultado;

  @override
  Widget build(BuildContext context) {
    final nivel = resultado.nivelTipico == null
        ? ''
        : AppStrings.nivelDbfs(resultado.nivelTipico!);

    // Anunciada ao aparecer: é a resposta de 5 segundos de espera.
    return Semantics(
      liveRegion: true,
      child: switch (resultado.conclusao) {
        ConclusaoDaAfericao.microfoneMudo
            when resultado.voz == ConferenciaComAVoz.naoFeita =>
          const AppSituacao(
            icone: NomeIcone.alerta,
            titulo: AppStrings.afericaoSilencio,
            texto: AppStrings.afericaoSilencioTexto,
          ),
        ConclusaoDaAfericao.microfoneMudo => const AppSituacao(
          icone: NomeIcone.negacao,
          titulo: AppStrings.afericaoMudo,
          texto: AppStrings.afericaoMudoTexto,
        ),
        ConclusaoDaAfericao.semRestricao
            when resultado.voz == ConferenciaComAVoz.captou =>
          const AppSituacao(
            icone: NomeIcone.confirmacao,
            titulo: AppStrings.afericaoSalaSilenciosa,
            texto: AppStrings.afericaoSalaSilenciosaTexto,
          ),
        ConclusaoDaAfericao.ruidoAlto => AppSituacao(
          icone: NomeIcone.alerta,
          titulo: AppStrings.afericaoRuidoAlto,
          texto: AppStrings.afericaoRuidoAltoTexto(
            nivel,
            AppStrings.nivelDbfs(AfericaoDeRuido.limiteDeRuido),
          ),
        ),
        ConclusaoDaAfericao.semRestricao => AppSituacao(
          icone: NomeIcone.confirmacao,
          titulo: AppStrings.afericaoSemRestricao,
          texto: AppStrings.afericaoSemRestricaoTexto(nivel),
        ),
      },
    );
  }
}

/// A escolha do microfone, com o padrão do sistema como primeira opção.
///
/// Só aparece quando há o que escolher (`EscolhaDoMicrofone.temEscolha`):
/// com um microfone só, a pergunta é ruído. Se o escolhido antes não está
/// ligado, diz — gravar de outro microfone sem avisar é o que a escolha
/// veio evitar.
class _EscolhaDoMicrofone extends ConsumerWidget {
  const _EscolhaDoMicrofone({required this.aoEscolher});

  /// Nulo deixa só para leitura: medindo, liberando o microfone, gravando.
  final ValueChanged<Microfone?>? aoEscolher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escolha = ref.watch(microfoneControladorProvider).value;
    if (escolha == null || !escolha.temEscolha) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (escolha.ausente case final ausente?) ...[
            AppSituacao(
              icone: NomeIcone.alerta,
              titulo: AppStrings.microfoneAusente(ausente.nome),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppEscolhaUnica<Microfone?>(
            rotulo: AppStrings.microfoneRotulo,
            opcoes: [
              const AppOpcao(valor: null, rotulo: AppStrings.microfonePadrao),
              for (final m in escolha.disponiveis)
                AppOpcao(valor: m, rotulo: m.nome),
            ],
            selecionado: escolha.escolhido,
            aoEscolher: aoEscolher,
            apoio: AppStrings.microfoneApoio,
          ),
        ],
      ),
    );
  }
}

/// O aparelho não usou o formato pedido. Aqui, na aferição, só informa: quem
/// decide é a conferência de cada gravação, que invalida o que a análise não
/// recebe (`ProblemaNaAmostra.formatoForaDoAceito`) e só avisa do resto
/// (US39).
class _Ajuste extends StatelessWidget {
  const _Ajuste({required this.ajuste});

  final AjusteDeConfiguracao ajuste;

  @override
  Widget build(BuildContext context) => AppSituacao(
    icone: NomeIcone.informacao,
    titulo: AppStrings.afericaoAjusteTitulo,
    texto: AppStrings.afericaoAjusteTexto(
      taxaUsada: ajuste.taxaDeAmostragem,
      canaisUsados: ajuste.canais,
      taxaPedida: ConfiguracaoDeCaptura.taxaDeAmostragem,
      canaisPedidos: ConfiguracaoDeCaptura.canais,
    ),
  );
}

/// O aparelho manteve ligado, ou não confirmou ter desligado, o
/// processamento automático do microfone (US42). Bloqueia: a captura
/// mudaria exatamente o que a análise mede.
class _ProcessamentoLigado extends StatelessWidget {
  const _ProcessamentoLigado({required this.ligados});

  final Set<ProcessamentoAutomatico> ligados;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AppSituacao(
      icone: NomeIcone.negacao,
      titulo: AppStrings.capturaProcessamentoLigado,
      texto: AppStrings.capturaProcessamentoLigadoTexto([
        for (final p in ProcessamentoAutomatico.values)
          if (ligados.contains(p)) nomeDoProcessamento(p),
      ]),
    ),
  );
}

/// O nome que o profissional lê para cada processamento.
String nomeDoProcessamento(ProcessamentoAutomatico processamento) =>
    switch (processamento) {
      ProcessamentoAutomatico.ganhoAutomatico =>
        AppStrings.processamentoGanhoAutomatico,
      ProcessamentoAutomatico.supressaoDeRuido =>
        AppStrings.processamentoSupressaoDeRuido,
      ProcessamentoAutomatico.cancelamentoDeEco =>
        AppStrings.processamentoCancelamentoDeEco,
    };

/// O fechamento do microfone passou do tempo esperado.
class _MicrofoneDemorando extends StatelessWidget {
  const _MicrofoneDemorando();

  @override
  Widget build(BuildContext context) => const AppSituacao(
    icone: NomeIcone.alerta,
    titulo: AppStrings.afericaoMicrofoneDemorando,
    texto: AppStrings.afericaoMicrofoneDemorandoTexto,
  );
}

class _SituacaoDaAmostra extends StatelessWidget {
  const _SituacaoDaAmostra({required this.amostra});

  final Amostra amostra;

  @override
  Widget build(BuildContext context) {
    final duracao = AppStrings.segundos(amostra.duracao);
    if (amostra.problemas.isEmpty) {
      return AppSituacao(
        icone: NomeIcone.confirmacao,
        titulo: AppStrings.tarefaGravada(duracao),
        texto: AppStrings.tarefaGravadaTexto,
      );
    }
    return AppSituacao(
      icone: NomeIcone.alerta,
      titulo: AppStrings.tarefaGravadaComRessalva(duracao),
      texto: amostra.problemas.map(mensagemDoProblema).join(' '),
    );
  }
}

class _Rejeitada extends StatelessWidget {
  const _Rejeitada({required this.problemas, required this.haAnterior});

  final List<ProblemaNaAmostra> problemas;
  final bool haAnterior;

  @override
  Widget build(BuildContext context) {
    final motivos = problemas
        .where((p) => p.invalida)
        .map(mensagemDoProblema)
        .join(' ');
    return Semantics(
      liveRegion: true,
      child: AppSituacao(
        icone: NomeIcone.negacao,
        titulo: AppStrings.tarefaDescartada,
        texto: haAnterior
            ? '$motivos ${AppStrings.tarefaDescartadaMantida}'
            : motivos,
      ),
    );
  }
}

class _Falha extends StatelessWidget {
  const _Falha({required this.motivo});

  final FalhaDaGravacao motivo;

  @override
  Widget build(BuildContext context) {
    final texto = switch (motivo) {
      FalhaDaGravacao.semPermissao => AppStrings.tarefaFalhaPermissao,
      FalhaDaGravacao.naoIniciou => AppStrings.tarefaFalhaIniciar,
      FalhaDaGravacao.naoFinalizou => AppStrings.tarefaFalhaFinalizar,
      FalhaDaGravacao.interrompida => AppStrings.tarefaFalhaInterrompida,
    };
    // Não em vermelho: a cor é reservada a status de medida, saturação de
    // áudio e erro de formulário. O ícone e o título dizem que falhou.
    return Semantics(
      liveRegion: true,
      child: AppSituacao(
        icone: NomeIcone.negacao,
        titulo: AppStrings.tarefaFalhaTitulo,
        texto: texto,
      ),
    );
  }
}

/// O texto que o profissional lê para cada problema da conferência.
String mensagemDoProblema(ProblemaNaAmostra problema) => switch (problema) {
  ProblemaNaAmostra.arquivoIlegivel => AppStrings.problemaArquivoIlegivel,
  ProblemaNaAmostra.naoEPcm => AppStrings.problemaNaoEPcm,
  ProblemaNaAmostra.bitsDiferentes => AppStrings.problemaBitsDiferentes,
  ProblemaNaAmostra.incompleto => AppStrings.problemaIncompleto,
  ProblemaNaAmostra.curtaDemais => AppStrings.problemaCurtaDemais,
  ProblemaNaAmostra.semSinal => AppStrings.problemaSemSinal,
  ProblemaNaAmostra.saturou => AppStrings.problemaSaturou,
  ProblemaNaAmostra.formatoAjustado => AppStrings.problemaFormatoAjustado,
  ProblemaNaAmostra.formatoForaDoAceito =>
    AppStrings.problemaFormatoForaDoAceito,
  ProblemaNaAmostra.processamentoLigado =>
    AppStrings.problemaProcessamentoLigado,
};
