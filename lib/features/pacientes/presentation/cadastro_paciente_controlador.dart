import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../data/repositorio_pacientes_local.dart';
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

  /// O estado depois de o profissional mexer em [campo]: sem o erro dele.
  ///
  /// Não revalida — dizer "data inexistente" a cada dígito de uma data pela
  /// metade seria gritar com quem ainda está digitando. O erro some ao
  /// corrigir e volta, se for o caso, no próximo "Salvar". Sem erro no
  /// campo, devolve o mesmo estado — e ninguém é reconstruído a cada tecla.
  EstadoCadastro aoEditar(CampoDoCadastro campo) {
    final temErro = switch (campo) {
      CampoDoCadastro.nome => erroNome,
      CampoDoCadastro.nascimento => erroNascimento,
      CampoDoCadastro.sexo => erroSexo,
      CampoDoCadastro.queixa => erroQueixa,
    };
    return temErro == null ? this : semErroEm(campo);
  }

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
  void editou(CampoDoCadastro campo) {
    final novo = state.aoEditar(campo);
    if (!identical(novo, state)) state = novo;
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

    final conferido = conferirFormulario(
      nome: nome,
      nascimento: nascimento,
      sexo: sexo,
      queixa: queixa,
    );
    final novo = conferido.dados;
    if (novo == null) {
      state = conferido.erros!;
      return null;
    }

    state = const EstadoCadastro(salvando: true);
    // Guardado ANTES da espera: se a tela fechar no meio do salvamento, este
    // controlador é descartado e o `ref` não pode mais ser usado — mas o
    // container, que vive o app inteiro, pode. Ver a invalidação abaixo.
    final container = ref.container;
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
    if (salvo != null) container.invalidate(pacientesProvider);

    if (!ref.mounted) return null;
    state = fim;
    return salvo;
  }
}

/// Confere o formulário do paciente — o do cadastro e o da edição: os dados
/// prontos para salvar, ou o estado com a mensagem de cada campo errado.
({NovoPaciente? dados, EstadoCadastro? erros}) conferirFormulario({
  required String nome,
  required String nascimento,
  required SexoDeReferencia? sexo,
  required String queixa,
}) => switch (validarCadastro(
  nome: nome,
  nascimento: nascimento,
  sexo: sexo,
  queixa: queixa,
  hoje: DateTime.now(),
)) {
  CadastroInvalido(
    nome: final n,
    nascimento: final d,
    sexo: final s,
    queixa: final q,
  ) =>
    (
      dados: null,
      erros: EstadoCadastro(
        erroNome: _mensagem(n),
        erroNascimento: _mensagem(d),
        erroSexo: _mensagem(s),
        erroQueixa: _mensagem(q),
      ),
    ),
  CadastroValido(:final paciente) => (dados: paciente, erros: null),
};

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
