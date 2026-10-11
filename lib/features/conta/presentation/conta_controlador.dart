import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../auth/data/profissional_atual.dart';
import '../../auth/data/sessao.dart';
import '../../auth/data/repositorio_autenticacao_firebase.dart';
import '../../auth/domain/profissional.dart';
import '../../cadastro/data/cadastro_api.dart';
import '../../cadastro/domain/cadastro.dart';
import '../data/repositorio_da_conta_local.dart';
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
      case DadosValidos(:var profissional):
        // Com a API, o cadastro vive lá (US34): o registro vai como região e
        // número, e só se aceita no formato "CRFa 2-12345".
        final api = ref.read(cadastroApiProvider);
        final registro = lerRegistro(profissional.registro);
        if (api != null && registro == null) {
          state = const EstadoDaConta(
            erroRegistro: ProblemaNosDados.registroFormato,
          );
          return false;
        }
        state = const EstadoDaConta(salvando: true);
        // O container, e não o `ref`, depois da espera: com a tela fechada
        // no meio, o `ref` já foi descartado — e o dado salvo precisa chegar
        // à sessão mesmo assim (revisão de 23/09).
        final container = ref.container;
        try {
          final uid = ref.read(sessaoProvider)?.uid;
          // A Conta só abre com a sessão aberta; sem ela, não há de quem
          // guardar.
          if (uid == null) throw const NaoAutorizado();
          if (api != null && registro != null) {
            final perfil = await api.atualizar(
              DadosDoCadastro(
                nome: profissional.nome,
                crefonoRegiao: registro.regiao,
                crefonoInscricao: registro.inscricao,
              ),
            );
            // O que a API gravou: o registro sai no formato dela, e o
            // credenciamento pode ter voltado a pendente.
            profissional = Profissional(
              nome: perfil.nome ?? profissional.nome,
              registro: perfil.registro,
              email: profissional.email,
              credenciamento: perfil.credenciamento,
            );
          }
          await ref.read(repositorioDaContaProvider).salvar(uid, profissional);
          container
              .read(profissionalAtualProvider.notifier)
              .definir(profissional);
          if (ref.mounted) state = const EstadoDaConta(salvo: true);
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
  ///
  /// A fila pausa ANTES de a credencial sair: um envio no meio é
  /// interrompido, e nada mais sobe até alguém entrar de novo (revisão de
  /// 23/09). Sair apaga a credencial do cofre — depois disso, nem o modo
  /// offline entra nesta conta sem a senha.
  Future<bool> sair() async {
    if (state.salvando || state.saindo) return false;
    state = const EstadoDaConta(saindo: true);
    final container = ref.container;
    container.read(sessaoProvider.notifier).encerrar();
    try {
      await ref.read(repositorioAutenticacaoProvider).sair();
    } on AppException catch (e) {
      if (ref.mounted) state = EstadoDaConta(erroGeral: e.mensagem);
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const EstadoDaConta(erroGeral: AppStrings.erroDesconhecido);
      }
      return false;
    }
    return true;
  }
}

final contaControladorProvider =
    NotifierProvider.autoDispose<ContaControlador, EstadoDaConta>(
      ContaControlador.new,
    );
