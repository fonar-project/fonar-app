import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../data/repositorio_pacientes_placeholder.dart';
import '../domain/novo_paciente.dart';
import '../domain/paciente.dart';

/// Os campos do formulário, para dizer qual deles o profissional mexeu.
enum CampoDoCadastro { nome, nascimento, sexo, queixa }

/// Estado do envio do formulário de paciente novo.
///
/// Os VALORES digitados não moram aqui: ficam nos controles da tela, como no
/// login. Aqui fica o que o envio produz — se está salvando e o que deu errado
/// em cada campo.
class EstadoCadastro {
  const EstadoCadastro({
    this.salvando = false,
    this.erroNome,
    this.erroNascimento,
    this.erroSexo,
    this.erroQueixa,
    this.erroGeral,
  });

  final bool salvando;
  final String? erroNome;
  final String? erroNascimento;
  final String? erroSexo;
  final String? erroQueixa;

  /// Falha que não é de um campo — o aparelho não conseguiu salvar.
  final String? erroGeral;

  /// O mesmo estado sem o erro de [campo].
  EstadoCadastro semErroEm(CampoDoCadastro campo) => EstadoCadastro(
    salvando: salvando,
    erroNome: campo == CampoDoCadastro.nome ? null : erroNome,
    erroNascimento: campo == CampoDoCadastro.nascimento ? null : erroNascimento,
    erroSexo: campo == CampoDoCadastro.sexo ? null : erroSexo,
    erroQueixa: campo == CampoDoCadastro.queixa ? null : erroQueixa,
    erroGeral: erroGeral,
  );
}

class CadastroPacienteControlador extends Notifier<EstadoCadastro> {
  @override
  EstadoCadastro build() => const EstadoCadastro();

  /// O profissional mexeu em [campo]: o erro dele sai da tela.
  ///
  /// Não revalida — dizer "data inexistente" a cada dígito de uma data pela
  /// metade seria gritar com quem ainda está digitando. O erro some ao
  /// corrigir e volta, se for o caso, no próximo "Salvar".
  void editou(CampoDoCadastro campo) {
    final atual = state;
    final temErro = switch (campo) {
      CampoDoCadastro.nome => atual.erroNome,
      CampoDoCadastro.nascimento => atual.erroNascimento,
      CampoDoCadastro.sexo => atual.erroSexo,
      CampoDoCadastro.queixa => atual.erroQueixa,
    };
    // Sem erro no campo, nada muda — e ninguém é reconstruído a cada tecla.
    if (temErro != null) state = atual.semErroEm(campo);
  }

  /// Confere e salva. Devolve o paciente salvo, ou `null` se algo impediu —
  /// e aí o motivo está no estado. A navegação fica com a tela.
  Future<Paciente?> salvar({
    required String nome,
    required String nascimento,
    required SexoDeReferencia? sexo,
    required String queixa,
  }) async {
    // Toque duplo em "Salvar e continuar" cadastraria o paciente duas vezes.
    if (state.salvando) return null;

    final resultado = validarCadastro(
      nome: nome,
      nascimento: nascimento,
      sexo: sexo,
      queixa: queixa,
      hoje: DateTime.now(),
    );

    final NovoPaciente novo;
    switch (resultado) {
      case CadastroInvalido():
        state = EstadoCadastro(
          erroNome: _mensagem(resultado.nome),
          erroNascimento: _mensagem(resultado.nascimento),
          erroSexo: _mensagem(resultado.sexo),
          erroQueixa: _mensagem(resultado.queixa),
        );
        return null;
      case CadastroValido(:final paciente):
        novo = paciente;
    }

    state = const EstadoCadastro(salvando: true);
    Paciente? salvo;
    EstadoCadastro fim;
    try {
      salvo = await ref.read(repositorioPacientesProvider).cadastrar(novo);
      fim = const EstadoCadastro();
    } on AppException catch (e) {
      fim = EstadoCadastro(erroGeral: e.mensagem);
    } catch (_) {
      // O contrato é lançar só AppException. Se outra coisa escapar, o pior
      // desfecho é o botão preso em "Salvando…".
      fim = const EstadoCadastro(erroGeral: AppStrings.erroDesconhecido);
    }

    // A lista precisa mostrar o paciente novo quando o profissional voltar a
    // ela — inclusive se a tela tiver sido fechada no meio do salvamento.
    if (salvo != null) ref.invalidate(pacientesProvider);

    if (!ref.mounted) return null;
    state = fim;
    return salvo;
  }
}

String? _mensagem(ProblemaNoCadastro? problema) => switch (problema) {
  null => null,
  ProblemaNoCadastro.nomeVazio => AppStrings.cadastroInformeNome,
  ProblemaNoCadastro.nascimentoVazio => AppStrings.cadastroInformeNascimento,
  ProblemaNoCadastro.nascimentoInvalido =>
    AppStrings.cadastroNascimentoInvalido,
  ProblemaNoCadastro.nascimentoNoFuturo =>
    AppStrings.cadastroNascimentoNoFuturo,
  ProblemaNoCadastro.nascimentoImplausivel =>
    AppStrings.cadastroNascimentoImplausivel(NovoPaciente.idadeMaxima),
  ProblemaNoCadastro.sexoNaoEscolhido => AppStrings.cadastroEscolhaSexo,
  ProblemaNoCadastro.queixaVazia => AppStrings.cadastroInformeQueixa,
};

final cadastroPacienteControladorProvider =
    NotifierProvider.autoDispose<CadastroPacienteControlador, EstadoCadastro>(
      CadastroPacienteControlador.new,
    );
