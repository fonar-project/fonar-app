import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/data/sessao.dart';
import '../../auth/domain/conta_autenticada.dart';
import '../../auth/presentation/login_controlador.dart';
import '../data/cadastro_api.dart';
import '../domain/cadastro.dart';

/// Para onde vai quem acabou de provar quem é: entrou com senha, criou a
/// conta, confirmou o e-mail ou preencheu o cadastro.
///
/// A API conduz o primeiro acesso (ADR-015 do `fonar-api`): e-mail por
/// verificar, cadastro por preencher, ou pronto. O app só segue.
sealed class DestinoDaEntrada {
  const DestinoDaEntrada();
}

/// Tem cadastro e pode usar o sistema: a sessão abre.
final class EntrarNoApp extends DestinoDaEntrada {
  const EntrarNoApp();
}

/// O e-mail da conta ainda não foi confirmado.
final class VerificarEmail extends DestinoDaEntrada {
  const VerificarEmail();
}

/// E-mail confirmado, cadastro por preencher.
final class CompletarCadastro extends DestinoDaEntrada {
  const CompletarCadastro();
}

/// A equipe recusou o credenciamento: não entra, e a tela diz o motivo.
final class EntradaRecusada extends DestinoDaEntrada {
  const EntradaRecusada(this.motivo);

  final String? motivo;
}

/// Confere o cadastro na API e diz o destino.
///
/// Sem a API configurada, ou com ela fora do alcance, a entrada segue como
/// sempre seguiu: o app funciona sem rede, e a fila espera. Quem não tem
/// cadastro só não consegue ENVIAR — a API recusa, e a fila mostra.
Future<DestinoDaEntrada> conferirCadastro(Ref ref) async {
  final api = ref.read(cadastroApiProvider);
  if (api == null) return const EntrarNoApp();
  try {
    return await destinoPelaApi(api);
  } on AppException {
    return const EntrarNoApp();
  }
}

/// O destino que a situação do cadastro na API manda. Lança a
/// `AppException` da rede — quem chama decide se entra mesmo assim.
Future<DestinoDaEntrada> destinoPelaApi(CadastroApi api) async =>
    switch (await api.situacao()) {
      Cadastrado(:final perfil)
          when perfil.credenciamento == Credenciamento.recusado =>
        EntradaRecusada(perfil.observacao),
      Cadastrado() => const EntrarNoApp(),
      EmailPorVerificar() => const VerificarEmail(),
      SemCadastro() => const CompletarCadastro(),
    };

/// Abre a sessão de [conta] — o fim de toda entrada que deu certo.
void abrirSessao(Ref ref, ContaAutenticada conta) {
  ref.read(sessaoProvider.notifier).abrir(conta);
  // A credencial guardada mudou: o modo offline passa a ser desta conta.
  ref.invalidate(contaGuardadaProvider);
}

/// O nome da rota de cada destino. A recusa fica na entrada, com o motivo.
String rotaDe(DestinoDaEntrada destino) => switch (destino) {
  EntrarNoApp() => AppRoutes.pacientesNome,
  VerificarEmail() => AppRoutes.verificarEmailNome,
  CompletarCadastro() => AppRoutes.completarCadastroNome,
  EntradaRecusada() => AppRoutes.loginNome,
};

/// O cadastro digitado na criação da conta, guardado enquanto o e-mail não
/// é confirmado — para não pedir tudo de novo depois do link.
///
/// Só na memória: se o app fechar antes da confirmação, a próxima entrada
/// leva ao formulário do cadastro, vazio.
class CadastroPendente extends Notifier<DadosDoCadastro?> {
  @override
  DadosDoCadastro? build() => null;

  void guardar(DadosDoCadastro dados) => state = dados;

  void esquecer() => state = null;
}

final cadastroPendenteProvider =
    NotifierProvider<CadastroPendente, DadosDoCadastro?>(CadastroPendente.new);
