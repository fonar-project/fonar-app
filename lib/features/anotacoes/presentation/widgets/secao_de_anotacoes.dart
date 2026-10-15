import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_cores.dart';
import '../../../../design_system/tokens/app_movimento.dart';
import '../../../../design_system/tokens/app_radius.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/app_botao.dart';
import '../../../../design_system/widgets/app_caixa_de_marcacao.dart';
import '../../../../design_system/widgets/app_campo_texto.dart';
import '../../../../design_system/widgets/app_toque.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/anotacao.dart';
import '../anotacoes_controlador.dart';

/// A seção "Anotações" do perfil do paciente (US51): escrever, ler, editar
/// e ver as versões de antes.
///
/// É prontuário: nada se apaga, e editar grava uma versão nova, guardando a
/// de antes. Não depende do consentimento — dá para anotar sem ele e depois
/// de retirado; o que ele bloqueia é a gravação.
class SecaoDeAnotacoes extends ConsumerStatefulWidget {
  const SecaoDeAnotacoes({
    required this.pacienteId,
    this.motivoDesabilitado,
    super.key,
  });

  final String pacienteId;

  /// Por que não se anota aqui — o paciente de exemplo. Nulo: anota-se.
  final String? motivoDesabilitado;

  @override
  ConsumerState<SecaoDeAnotacoes> createState() => _SecaoDeAnotacoesState();
}

class _SecaoDeAnotacoesState extends ConsumerState<SecaoDeAnotacoes> {
  final _texto = TextEditingController();
  var _lembrar = false;
  var _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final erro = erroDoTextoDaAnotacao(_texto.text);
    setState(() => _erro = erro);
    if (erro != null) return;
    setState(() => _salvando = true);
    try {
      await ref
          .read(anotacoesControladorProvider)
          .escrever(
            widget.pacienteId,
            texto: _texto.text,
            lembrarNaProxima: _lembrar,
          );
      if (!mounted) return;
      _texto.clear();
      setState(() => _lembrar = false);
    } catch (_) {
      if (mounted) setState(() => _erro = AppStrings.anotacoesErroSalvar);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final anotacoes = ref.watch(anotacoesDoPacienteProvider(widget.pacienteId));
    final bloqueado = widget.motivoDesabilitado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(AppStrings.anotacoesTitulo, style: textos.titleLarge),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppStrings.anotacoesApoio,
          style: textos.bodySmall?.copyWith(color: context.cores.secundario),
        ),
        const SizedBox(height: AppSpacing.md),
        if (bloqueado != null)
          Text(
            bloqueado,
            style: textos.bodyMedium?.copyWith(color: context.cores.secundario),
          )
        else ...[
          AppCampoTexto(
            rotulo: AppStrings.anotacoesCampo,
            controlador: _texto,
            linhas: 4,
            erro: _erro,
            habilitado: !_salvando,
            capitalizacao: TextCapitalization.sentences,
            aoMudar: (_) {
              if (_erro != null) setState(() => _erro = null);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCaixaDeMarcacao(
            rotulo: AppStrings.anotacoesLembrar,
            marcada: _lembrar,
            aoMudar: _salvando ? null : (v) => setState(() => _lembrar = v),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            // Secundário: a ação principal do perfil é gravar.
            child: AppBotao.secundario(
              rotulo: _salvando
                  ? AppStrings.anotacoesSalvando
                  : AppStrings.anotacoesSalvar,
              aoTocar: _salvando ? null : _salvar,
              motivoDesabilitado: AppStrings.anotacoesSalvando,
              carregando: _salvando,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppTrocaAnimada(
          chave: anotacoes.runtimeType,
          child: switch (anotacoes) {
            AsyncData(value: final lista) when lista.isEmpty => Text(
              AppStrings.anotacoesVazio,
              style: textos.bodyMedium?.copyWith(
                color: context.cores.secundario,
              ),
            ),
            AsyncData(value: final lista) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final anotacao in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CartaoDaAnotacao(
                      key: ValueKey(anotacao.versoes.first.id),
                      anotacao: anotacao,
                      editavel: bloqueado == null,
                    ),
                  ),
              ],
            ),
            AsyncError() => Text(
              AppStrings.anotacoesErroCarregar,
              style: textos.bodyMedium,
            ),
            _ => const SizedBox(height: AppSpacing.lg),
          },
        ),
      ],
    );
  }
}

/// O texto pode ser salvo? Nulo se sim; senão, o que corrigir.
String? erroDoTextoDaAnotacao(String texto) {
  final limpo = texto.trim();
  if (limpo.isEmpty) return AppStrings.anotacoesTextoObrigatorio;
  if (limpo.length > tamanhoMaximoDaAnotacao) {
    return AppStrings.anotacoesTextoLongo(tamanhoMaximoDaAnotacao);
  }
  return null;
}

/// Uma anotação: a data, o texto vigente e, se houve, quando foi editada e
/// as versões de antes. Editar troca o cartão pelo campo, no mesmo lugar.
class _CartaoDaAnotacao extends ConsumerStatefulWidget {
  const _CartaoDaAnotacao({
    required this.anotacao,
    required this.editavel,
    super.key,
  });

  final Anotacao anotacao;
  final bool editavel;

  @override
  ConsumerState<_CartaoDaAnotacao> createState() => _CartaoDaAnotacaoState();
}

class _CartaoDaAnotacaoState extends ConsumerState<_CartaoDaAnotacao> {
  TextEditingController? _edicao;
  var _lembrar = false;
  var _salvando = false;
  var _anterioresAbertas = false;
  String? _erro;

  @override
  void dispose() {
    _edicao?.dispose();
    super.dispose();
  }

  void _editar() => setState(() {
    _edicao = TextEditingController(text: widget.anotacao.texto);
    _lembrar = widget.anotacao.vigente.lembrarNaProxima;
    _erro = null;
  });

  void _cancelar() => setState(() {
    _edicao?.dispose();
    _edicao = null;
  });

  Future<void> _salvar() async {
    final edicao = _edicao;
    if (edicao == null) return;
    final erro = erroDoTextoDaAnotacao(edicao.text);
    setState(() => _erro = erro);
    if (erro != null) return;
    // Sem mudança, não há versão nova: só fecha.
    if (edicao.text.trim() == widget.anotacao.texto &&
        _lembrar == widget.anotacao.vigente.lembrarNaProxima) {
      _cancelar();
      return;
    }
    setState(() => _salvando = true);
    try {
      await ref
          .read(anotacoesControladorProvider)
          .editar(
            widget.anotacao,
            texto: edicao.text,
            lembrarNaProxima: _lembrar,
          );
      if (mounted) _cancelar();
    } catch (_) {
      if (mounted) setState(() => _erro = AppStrings.anotacoesErroSalvar);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final secundario = textos.bodySmall?.copyWith(
      color: context.cores.secundario,
    );
    final anotacao = widget.anotacao;
    final editadaEm = anotacao.editadaEm;
    final edicao = _edicao;
    final anteriores = anotacao.anteriores;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: context.cores.borda),
        borderRadius: AppRadius.bordaMedia,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [
              AppStrings.data(anotacao.criadaEm.toLocal()),
              if (editadaEm != null)
                AppStrings.anotacoesEditadaEm(
                  AppStrings.data(editadaEm.toLocal()),
                ),
            ].join(' · '),
            style: secundario?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (edicao == null) ...[
            Text(anotacao.texto, style: textos.bodyMedium),
            if (anotacao.vigente.lembrarNaProxima) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.anotacoesComLembrete,
                style: textos.labelMedium?.copyWith(
                  color: context.cores.acento,
                ),
              ),
            ],
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.editavel)
                  _Acao(rotulo: AppStrings.anotacoesEditar, aoTocar: _editar),
                if (anteriores.isNotEmpty)
                  _Acao(
                    rotulo: _anterioresAbertas
                        ? AppStrings.anotacoesEsconderAnteriores
                        : AppStrings.anotacoesVerAnteriores(anteriores.length),
                    aoTocar: () => setState(
                      () => _anterioresAbertas = !_anterioresAbertas,
                    ),
                  ),
              ],
            ),
            AppRevelar(
              visivel: _anterioresAbertas && anteriores.isNotEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final versao in anteriores)
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: context.cores.borda,
                            width: 3,
                          ),
                        ),
                      ),
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.anotacoesVersaoDe(
                                AppStrings.data(versao.escritaEm.toLocal()),
                              ),
                              style: secundario,
                            ),
                            Text(
                              versao.texto,
                              style: textos.bodyMedium?.copyWith(
                                color: context.cores.secundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            AppCampoTexto(
              rotulo: AppStrings.anotacoesCampoEdicao,
              controlador: edicao,
              linhas: 4,
              erro: _erro,
              habilitado: !_salvando,
              capitalizacao: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppCaixaDeMarcacao(
              rotulo: AppStrings.anotacoesLembrar,
              marcada: _lembrar,
              aoMudar: _salvando ? null : (v) => setState(() => _lembrar = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppBotao.secundario(
                  rotulo: _salvando
                      ? AppStrings.anotacoesSalvando
                      : AppStrings.anotacoesSalvarEdicao,
                  aoTocar: _salvando ? null : _salvar,
                  motivoDesabilitado: AppStrings.anotacoesSalvando,
                  carregando: _salvando,
                ),
                _Acao(
                  rotulo: AppStrings.anotacoesCancelar,
                  aoTocar: _salvando ? null : _cancelar,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma ação de texto do cartão, com o alvo de toque mínimo.
class _Acao extends StatelessWidget {
  const _Acao({required this.rotulo, required this.aoTocar});

  final String rotulo;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: context.cores.acento,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: context.cores.acento,
    );
    final texto = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.alvoDeToqueMinimo,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Text(rotulo, style: estilo),
        ),
      ),
    );
    final tocar = aoTocar;
    // Parada só enquanto a edição é salva — um instante.
    if (tocar == null) {
      return ExcludeSemantics(child: Opacity(opacity: 0.5, child: texto));
    }
    return AppToque(
      aoTocar: tocar,
      raio: AppRadius.bordaPequena,
      conteudo: (_) => texto,
    );
  }
}
