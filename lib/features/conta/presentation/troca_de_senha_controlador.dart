import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../auth/data/sessao.dart';
import '../data/troca_de_senha_firebase.dart';
import '../domain/troca_de_senha.dart';

class EstadoDaTroca {
  const EstadoDaTroca({
    this.trocando = false,
    this.trocada = false,
    this.erroAtual,
    this.erroNova,
    this.erroConfirmacao,
    this.erroGeral,
  });

  final bool trocando;

  /// A última troca deu certo e nada foi digitado depois dela.
  final bool trocada;

  /// O que dizer embaixo de cada campo.
  final String? erroAtual;
  final String? erroNova;
  final String? erroConfirmacao;

  /// Falha que não pertence a um campo — rede, conta pausada.
  final String? erroGeral;
}

/// O formulário de troca de senha da Conta (US45).
class TrocaDeSenhaControlador extends Notifier<EstadoDaTroca> {
  @override
  EstadoDaTroca build() => const EstadoDaTroca();

  /// O profissional mexeu no campo: o erro dele sai, e "trocada" deixa de
  /// valer.
  void editou(CampoDaTrocaDeSenha campo) {
    if (state.trocando) return;
    state = EstadoDaTroca(
      erroAtual: campo == CampoDaTrocaDeSenha.atual ? null : state.erroAtual,
      erroNova: campo == CampoDaTrocaDeSenha.nova ? null : state.erroNova,
      erroConfirmacao: campo == CampoDaTrocaDeSenha.confirmacao
          ? null
          : state.erroConfirmacao,
    );
  }

  /// Volta ao estado de antes de abrir o formulário.
  void cancelar() {
    if (state.trocando) return;
    state = const EstadoDaTroca();
  }

  /// Devolve `true` se trocou.
  Future<bool> trocar({
    required String atual,
    required String nova,
    required String confirmacao,
  }) async {
    if (state.trocando) return false;
    final problemas = validarTrocaDeSenha(
      atual: atual,
      nova: nova,
      confirmacao: confirmacao,
    );
    if (problemas.isNotEmpty) {
      state = EstadoDaTroca(
        erroAtual: _mensagem(problemas[CampoDaTrocaDeSenha.atual]),
        erroNova: _mensagem(problemas[CampoDaTrocaDeSenha.nova]),
        erroConfirmacao: _mensagem(problemas[CampoDaTrocaDeSenha.confirmacao]),
      );
      return false;
    }
    // Lidos antes da espera: a tela pode fechar no meio dela.
    final troca = ref.read(trocaDeSenhaProvider);
    final conta = ref.read(sessaoProvider);
    if (troca == null || conta == null) {
      state = const EstadoDaTroca(erroGeral: AppStrings.erroDesconhecido);
      return false;
    }

    state = const EstadoDaTroca(trocando: true);
    String? erroAtual;
    String? erroNova;
    String? erroGeral;
    try {
      await troca.trocar(conta: conta, atual: atual, nova: nova);
    } on CredencialInvalida {
      erroAtual = AppStrings.contaSenhaAtualNaoConfere;
    } on SenhaFraca catch (e) {
      erroNova = e.mensagem;
    } on AppException catch (e) {
      erroGeral = e.mensagem;
    } catch (_) {
      erroGeral = AppStrings.erroDesconhecido;
    }
    final trocou = erroAtual == null && erroNova == null && erroGeral == null;
    if (ref.mounted) {
      state = EstadoDaTroca(
        trocada: trocou,
        erroAtual: erroAtual,
        erroNova: erroNova,
        erroGeral: erroGeral,
      );
    }
    return trocou;
  }
}

String? _mensagem(ProblemaNaTrocaDeSenha? problema) => switch (problema) {
  ProblemaNaTrocaDeSenha.atualVazia => AppStrings.contaSenhaInformeAtual,
  ProblemaNaTrocaDeSenha.novaCurta => AppStrings.cadastroSenhaCurta,
  ProblemaNaTrocaDeSenha.novaIgualAtual => AppStrings.contaSenhaNovaIgual,
  ProblemaNaTrocaDeSenha.senhasDiferentes =>
    AppStrings.cadastroSenhasDiferentes,
  null => null,
};

final trocaDeSenhaControladorProvider =
    NotifierProvider.autoDispose<TrocaDeSenhaControlador, EstadoDaTroca>(
      TrocaDeSenhaControlador.new,
    );
