import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../data/repositorio_pacientes_local.dart';
import '../domain/novo_paciente.dart';
import '../domain/paciente.dart';
import 'cadastro_paciente_controlador.dart';

/// Correção dos dados de UM paciente já cadastrado.
///
/// Mesmas regras do cadastro ([conferirFormulario]): uma data de nascimento
/// errada deixaria as medidas sem faixa de referência — ou com a faixa de
/// outra idade — em todas as sessões.
class EdicaoPacienteControlador extends Notifier<EstadoCadastro> {
  EdicaoPacienteControlador(this.pacienteId);

  final String pacienteId;

  @override
  EstadoCadastro build() => const EstadoCadastro();

  void editou(CampoDoCadastro campo) {
    final novo = state.aoEditar(campo);
    if (!identical(novo, state)) state = novo;
  }

  /// Confere e salva. Devolve o paciente como ficou, ou `null` — e aí o
  /// motivo está no estado.
  Future<Paciente?> salvar({
    required String nome,
    required String nascimento,
    required SexoDeReferencia? sexo,
    required String queixa,
    bool mesmoAssim = false,
  }) async {
    if (state.salvando) return null;

    final conferido = conferirFormulario(
      nome: nome,
      nascimento: nascimento,
      sexo: sexo,
      queixa: queixa,
    );
    final dados = conferido.dados;
    if (dados == null) {
      state = conferido.erros!;
      return null;
    }

    state = const EstadoCadastro(salvando: true);
    if (!mesmoAssim) {
      final duplicado = await procurarDuplicado(
        ref,
        dados,
        ignorarId: pacienteId,
      );
      if (!ref.mounted) return null;
      if (duplicado != null) {
        state = EstadoCadastro(duplicado: duplicado);
        return null;
      }
    }
    // Guardado antes da espera: a lista e o perfil precisam mostrar a
    // correção mesmo com a tela fechada no meio.
    final container = ref.container;
    Paciente? salvo;
    EstadoCadastro fim;
    try {
      salvo = await ref
          .read(repositorioPacientesProvider)
          .atualizar(pacienteId, dados);
      fim = const EstadoCadastro();
    } on AppException catch (e) {
      fim = EstadoCadastro(erroGeral: e.mensagem);
    } catch (_) {
      fim = const EstadoCadastro(erroGeral: AppStrings.erroDesconhecido);
    }

    if (salvo != null) container.invalidate(pacientesProvider);

    if (!ref.mounted) return null;
    state = fim;
    return salvo;
  }
}

final edicaoPacienteControladorProvider = NotifierProvider.autoDispose
    .family<EdicaoPacienteControlador, EstadoCadastro, String>(
      EdicaoPacienteControlador.new,
    );
