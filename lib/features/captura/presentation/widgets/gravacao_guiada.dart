import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/breakpoints.dart';
import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_icone.dart';
import '../../../../design_system/widgets/app_situacao.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../../pacientes/data/repositorio_pacientes_local.dart';
import '../../../reproducao/presentation/widgets/player_de_amostra.dart';
import '../../data/configuracao_de_captura.dart';
import '../../domain/afericao_de_ruido.dart';
import '../../domain/amostra.dart';
import '../../domain/fonte_de_nivel.dart';
import '../../domain/verificacao_da_amostra.dart';
import '../afericao_controlador.dart';
import '../gravacao_controlador.dart';
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

    return LayoutBuilder(
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
            ...palco.corpo,
          ],
        );

        final Widget tela;
        if (compacta) {
          tela = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: etapas,
              ),
              Expanded(
                child: _Rolavel(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  // No celular o texto do rodapé rola com o conteúdo: na
                  // barra fixa, com o texto em 200%, não sobraria tela.
                  child: palco.rodape == null
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
                ),
              ),
              if (palco.acoes.isNotEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: context.cores.borda)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, acao) in palco.acoes.indexed) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.xs),
                            acao.botao(ocupaLargura: true),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          tela = Padding(
            padding: const EdgeInsets.fromLTRB(34, 26, 34, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                etapas,
                const SizedBox(height: 22),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.cores.borda),
                      borderRadius: AppRadius.bordaMedia,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Rolavel(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                conteudo,
                                if (palco.acoes.isNotEmpty &&
                                    palco.rodape == null) ...[
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
                            ),
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
                  ),
                ),
              ],
            ),
          );
        }

        // O foco começa na tela, para os atalhos valerem sem clicar antes.
        return Focus(focusNode: _foco, autofocus: true, child: tela);
      },
    );
  }

  // ---------------------------------------------------------------- ruído --

  _Palco _palcoDoRuido(EstadoDaAfericao afericao, EstadoDaGravacao gravacao) {
    void medir() => ref.read(afericaoControladorProvider.notifier).medir();
    final cabeca = _Cabeca(
      rotulo: AppStrings.etapaDe(
        1,
        _tarefas.length + 1,
        AppStrings.etapaRuidoNome,
      ),
      instrucao: switch (afericao) {
        AfericaoNaoIniciada() => AppStrings.instrucaoRuidoPronto,
        AfericaoMedindo() => AppStrings.instrucaoRuidoMedindo,
        AfericaoSemPermissao() ||
        AfericaoFalhou() => AppStrings.instrucaoRuidoSemMicrofone,
        AfericaoConcluida(:final resultado) => switch (resultado.conclusao) {
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
        acoes: [_Acao.primaria(AppStrings.afericaoMedir, medir)],
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
                  if (ajuste != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _Ajuste(ajuste: ajuste),
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
            _Acao(
              rotulo: AppStrings.afericaoMedirDeNovo,
              aoTocar: gravacao.ocupado || !microfoneLiberado ? null : medir,
              motivo: gravacao.ocupado
                  ? AppStrings.afericaoEsperaGravacao
                  : AppStrings.afericaoLiberandoMicrofone,
              primaria: !liberaGravacao,
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
  });

  const _Acao.primaria(this.rotulo, this.aoTocar, {this.motivo})
    : icone = null,
      primaria = true;

  final String rotulo;
  final VoidCallback? aoTocar;
  final NomeIcone? icone;
  final String? motivo;
  final bool primaria;

  Widget botao({required bool ocupaLargura}) => AppBotao(
    variante: primaria ? VarianteBotao.primario : VarianteBotao.secundario,
    rotulo: rotulo,
    icone: icone,
    aoTocar: aoTocar,
    motivoDesabilitado: motivo,
    ocupaLargura: ocupaLargura,
  );
}

/// Centraliza o palco na altura quando cabe, e rola quando não cabe.
class _Rolavel extends StatelessWidget {
  const _Rolavel({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) => SingleChildScrollView(
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
            AppIcone(
              nome: NomeIcone.gravar,
              cor: context.cores.acento,
              tamanho: 18,
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
    final marca = Container(
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
                    : context.cores.secundario,
              ),
            ),
    );
    final conteudo = Semantics(
      label: '$nome, $situacao',
      selected: atual,
      button: aoTocar != null,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              marca,
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
                          : context.cores.secundario,
                    ),
                  ),
                  if (!compacta)
                    Text(
                      situacao,
                      style: textos.bodySmall?.copyWith(
                        fontSize: 12,
                        color: context.cores.secundario,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (aoTocar case final tocar?) {
      return AppToque(
        aoTocar: tocar,
        raio: AppRadius.bordaPequena,
        child: conteudo,
      );
    }
    return conteudo;
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
        ConclusaoDaAfericao.microfoneMudo => const AppSituacao(
          icone: NomeIcone.negacao,
          titulo: AppStrings.afericaoMudo,
          texto: AppStrings.afericaoMudoTexto,
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

/// O aparelho não usou o formato pedido. Não bloqueia — ainda não se sabe
/// quais ajustes a análise tolera —, mas não passa calado.
///
/// TODO(backend): decidir com a API de análise quais ajustes bloqueiam.
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
};
