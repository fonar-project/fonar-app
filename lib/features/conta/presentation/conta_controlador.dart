import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../auth/data/profissional_atual.dart';
import '../data/repositorio_da_conta_placeholder.dart';
import '../domain/dados_do_profissional.dart';

enum CampoDaConta { nome, registro }

class EstadoDaConta {
  const EstadoDaConta({
    this.salvando = false,
    this.saindo = false,
    this.erroNome,
    this.erroRegistro,
    this.erroGeral,
    this.salvo = false,
  });

  final bool salvando;
  final bool saindo;
  final ProblemaNosDados? erroNome;
  final ProblemaNosDados? erroRegistro;

  /// Falha que não pertence a um campo — rede, servidor.
  final String? erroGeral;

  /// A última gravação deu certo e nada foi editado depois dela.
  final bool salvo;
}

class ContaControlador extends Notifier<EstadoDaConta> {
  @override
  EstadoDaConta build() => const EstadoDaConta();

  /// O profissional mexeu no campo: o erro dele sai, e "salvo" deixa de
  /// valer.
  void editou(CampoDaConta campo) {
    state = EstadoDaConta(
      erroNome: campo == CampoDaConta.nome ? null : state.erroNome,
      erroRegistro: campo == CampoDaConta.registro ? null : state.erroRegistro,
    );
  }

  /// Devolve `true` se salvou.
  Future<bool> salvar({required String nome, required String registro}) async {
    if (state.salvando || state.saindo) return false;
    final resultado = validarDados(
      atual: ref.read(profissionalAtualProvider),
      nome: nome,
      registro: registro,
    );
    switch (resultado) {
      case DadosInvalidos(:final nome, :final registro):
        state = EstadoDaConta(erroNome: nome, erroRegistro: registro);
        return false;
      case DadosValidos(:final profissional):
        state = const EstadoDaConta(salvando: true);
        try {
          await ref.read(repositorioDaContaProvider).salvar(profissional);
          if (!ref.mounted) return false;
          ref.read(profissionalAtualProvider.notifier).definir(profissional);
          state = const EstadoDaConta(salvo: true);
          return true;
        } on AppException catch (e) {
          if (ref.mounted) state = EstadoDaConta(erroGeral: e.mensagem);
          return false;
        } catch (_) {
          if (ref.mounted) {
            state = const EstadoDaConta(erroGeral: AppStrings.erroDesconhecido);
          }
          return false;
        }
    }
  }

  /// Encerra a sessão. Devolve `true` se saiu; a navegação fica com a tela.
  Future<bool> sair() async {
    if (state.salvando || state.saindo) return false;
    state = const EstadoDaConta(saindo: true);
    try {
      await ref.read(repositorioDaContaProvider).sair();
      // Quem entrar depois não herda o profissional desta sessão.
      ref.invalidate(profissionalAtualProvider);
      return true;
    } on AppException catch (e) {
      if (ref.mounted) state = EstadoDaConta(erroGeral: e.mensagem);
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const EstadoDaConta(erroGeral: AppStrings.erroDesconhecido);
      }
      return false;
    }
  }
}

final contaControladorProvider =
    NotifierProvider.autoDispose<ContaControlador, EstadoDaConta>(
      ContaControlador.new,
    );
