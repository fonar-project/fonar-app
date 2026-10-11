import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../auth/data/repositorio_autenticacao_firebase.dart';
import '../../auth/presentation/login_controlador.dart';
import '../data/cadastro_api.dart';
import '../data/criacao_de_conta.dart';
import '../domain/cadastro.dart';
import 'entrada.dart';

/// Estado de um formulário da entrada: criar conta, confirmar o e-mail,
/// preencher o cadastro.
class EstadoDoCadastro {
  const EstadoDoCadastro({
    this.enviando = false,
    this.erros = const {},
    this.erroGeral,
    this.aviso,
  });

  final bool enviando;

  /// Campo -> mensagem, no máximo uma por campo.
  final Map<CampoDoRegistro, String> erros;

  /// Falha que não é de um campo — rede, servidor.
  final String? erroGeral;

  /// Aviso que não é erro: "e-mail reenviado", "ainda não confirmado".
  final ({String titulo, String texto})? aviso;

  String? erroDe(CampoDoRegistro campo) => erros[campo];
}

/// O texto de cada problema do formulário.
String mensagemDe(ProblemaNoRegistro problema) => switch (problema) {
  ProblemaNoRegistro.nomeVazio => AppStrings.registroInformeNome,
  ProblemaNoRegistro.nomeLongo => AppStrings.cadastroNomeLongo,
  ProblemaNoRegistro.regiaoVazia => AppStrings.cadastroInformeRegiao,
  ProblemaNoRegistro.inscricaoVazia => AppStrings.cadastroInformeInscricao,
  ProblemaNoRegistro.inscricaoInvalida => AppStrings.cadastroInscricaoInvalida,
  ProblemaNoRegistro.termosNaoAceitos => AppStrings.cadastroAceiteTermos,
  ProblemaNoRegistro.emailVazio => AppStrings.cadastroInformeEmail,
  ProblemaNoRegistro.emailInvalido => AppStrings.cadastroEmailInvalido,
  ProblemaNoRegistro.senhaCurta => AppStrings.cadastroSenhaCurta,
  ProblemaNoRegistro.senhasDiferentes => AppStrings.cadastroSenhasDiferentes,
};

Map<CampoDoRegistro, String> _mensagens(
  Map<CampoDoRegistro, ProblemaNoRegistro> problemas,
) => {
  for (final MapEntry(key: campo, value: problema) in problemas.entries)
    campo: mensagemDe(problema),
};

/// Entra no app com a conta guardada no cofre — a que acabou de criar a
/// conta ou de entrar com senha.
Future<DestinoDaEntrada> _entrarComAContaGuardada(Ref ref) async {
  final conta = await ref.read(repositorioAutenticacaoProvider).contaGuardada();
  if (conta == null) throw const NaoAutorizado();
  if (ref.mounted) abrirSessao(ref, conta);
  return const EntrarNoApp();
}

// ------------------------------------------------------------ criar conta --

class CriarContaControlador extends Notifier<EstadoDoCadastro> {
  @override
  EstadoDoCadastro build() => const EstadoDoCadastro();

  /// O profissional mexeu no campo: o erro dele sai.
  void editou(CampoDoRegistro campo) {
    if (!state.erros.containsKey(campo) && state.erroGeral == null) return;
    state = EstadoDoCadastro(erros: {...state.erros}..remove(campo));
  }

  /// Cria a conta no Firebase e guarda o cadastro para depois da
  /// confirmação do e-mail. Devolve o destino, ou `null` se não criou.
  Future<DestinoDaEntrada?> criar({
    required String email,
    required String senha,
    required String confirmacao,
    required String nome,
    required int? regiao,
    required String inscricao,
    required bool aceitouTermos,
  }) async {
    if (state.enviando) return null;
    final problemas = {
      ...validarConta(email: email, senha: senha, confirmacao: confirmacao),
    };
    final cadastro = validarRegistro(
      nome: nome,
      regiao: regiao,
      inscricao: inscricao,
      aceitouTermos: aceitouTermos,
    );
    if (cadastro case RegistroInvalido(problemas: final doCadastro)) {
      problemas.addAll(doCadastro);
    }
    if (problemas.isNotEmpty || cadastro is! RegistroValido) {
      state = EstadoDoCadastro(erros: _mensagens(problemas));
      return null;
    }
    final criacao = ref.read(criacaoDeContaProvider);
    if (criacao == null) {
      state = const EstadoDoCadastro(erroGeral: AppStrings.erroDesconhecido);
      return null;
    }

    state = const EstadoDoCadastro(enviando: true);
    EstadoDoCadastro? falha;
    try {
      await criacao.criarConta(email: email.trim(), senha: senha);
    } on EmailIndisponivel catch (e) {
      falha = EstadoDoCadastro(erros: {CampoDoRegistro.email: e.mensagem});
    } on EmailInvalido catch (e) {
      falha = EstadoDoCadastro(erros: {CampoDoRegistro.email: e.mensagem});
    } on SenhaFraca catch (e) {
      falha = EstadoDoCadastro(erros: {CampoDoRegistro.senha: e.mensagem});
    } on AppException catch (e) {
      falha = EstadoDoCadastro(erroGeral: e.mensagem);
    } catch (_) {
      falha = const EstadoDoCadastro(erroGeral: AppStrings.erroDesconhecido);
    }
    if (!ref.mounted) return null;
    if (falha != null) {
      state = falha;
      return null;
    }
    ref.read(cadastroPendenteProvider.notifier).guardar(cadastro.dados);
    ref.invalidate(contaGuardadaProvider);
    state = const EstadoDoCadastro();
    return const VerificarEmail();
  }
}

final criarContaControladorProvider =
    NotifierProvider.autoDispose<CriarContaControlador, EstadoDoCadastro>(
      CriarContaControlador.new,
    );

// ------------------------------------------------- confirmação do e-mail --

class VerificacaoControlador extends Notifier<EstadoDoCadastro> {
  @override
  EstadoDoCadastro build() => const EstadoDoCadastro();

  /// "Já confirmei": pega um token novo e pergunta à API. Com o cadastro da
  /// criação da conta guardado, já o envia; sem ele, o destino é o
  /// formulário.
  Future<DestinoDaEntrada?> confirmar() async {
    if (state.enviando) return null;
    state = const EstadoDoCadastro(enviando: true);
    try {
      final destino = await _confirmar();
      if (!ref.mounted) return null;
      switch (destino) {
        case VerificarEmail():
          state = const EstadoDoCadastro(
            aviso: (
              titulo: AppStrings.verificarEmailAindaNaoTitulo,
              texto: AppStrings.verificarEmailAindaNao,
            ),
          );
          return null;
        case EntradaRecusada(:final motivo):
          state = EstadoDoCadastro(
            erroGeral: AppStrings.loginCredencialRecusada(motivo),
          );
          return null;
        case EntrarNoApp() || CompletarCadastro():
          state = const EstadoDoCadastro();
          return destino;
      }
    } on AppException catch (e) {
      if (ref.mounted) state = EstadoDoCadastro(erroGeral: e.mensagem);
    } catch (_) {
      if (ref.mounted) {
        state = const EstadoDoCadastro(erroGeral: AppStrings.erroDesconhecido);
      }
    }
    return null;
  }

  Future<DestinoDaEntrada> _confirmar() async {
    await ref.read(criacaoDeContaProvider)?.atualizarVerificacao();
    final api = ref.read(cadastroApiProvider);
    // Sem a API configurada não há o que conferir: entra.
    if (api == null) return _entrarComAContaGuardada(ref);
    final destino = await destinoPelaApi(api);
    if (destino is EntrarNoApp) return _entrarComAContaGuardada(ref);
    if (destino is! CompletarCadastro) return destino;
    final pendente = ref.read(cadastroPendenteProvider);
    if (pendente == null) return destino;
    try {
      await api.cadastrar(pendente);
    } on EmailAindaNaoVerificado {
      return const VerificarEmail();
    }
    ref.read(cadastroPendenteProvider.notifier).esquecer();
    return _entrarComAContaGuardada(ref);
  }

  /// Manda o e-mail de verificação de novo.
  Future<void> reenviar() async {
    if (state.enviando) return;
    state = const EstadoDoCadastro(enviando: true);
    EstadoDoCadastro fim;
    try {
      final criacao = ref.read(criacaoDeContaProvider);
      if (criacao == null) throw const FalhaDesconhecida();
      await criacao.reenviarVerificacao();
      fim = const EstadoDoCadastro(
        aviso: (
          titulo: AppStrings.verificarEmailReenviadoTitulo,
          texto: AppStrings.verificarEmailReenviado,
        ),
      );
    } on AppException catch (e) {
      fim = EstadoDoCadastro(erroGeral: e.mensagem);
    } catch (_) {
      fim = const EstadoDoCadastro(erroGeral: AppStrings.erroDesconhecido);
    }
    if (ref.mounted) state = fim;
  }

  /// "Entrar com outra conta": a credencial desta sai do aparelho.
  Future<bool> trocarDeConta() => _trocarDeConta(ref);
}

/// Apaga a credencial e o cadastro guardado: volta para a entrada.
Future<bool> _trocarDeConta(Ref ref) async {
  try {
    await ref.read(repositorioAutenticacaoProvider).sair();
  } on AppException {
    return false;
  }
  if (!ref.mounted) return true;
  ref.read(cadastroPendenteProvider.notifier).esquecer();
  ref.invalidate(contaGuardadaProvider);
  return true;
}

final verificacaoControladorProvider =
    NotifierProvider.autoDispose<VerificacaoControlador, EstadoDoCadastro>(
      VerificacaoControlador.new,
    );

// --------------------------------------------------- completar cadastro --

class CompletarCadastroControlador extends Notifier<EstadoDoCadastro> {
  @override
  EstadoDoCadastro build() => const EstadoDoCadastro();

  void editou(CampoDoRegistro campo) {
    if (!state.erros.containsKey(campo) && state.erroGeral == null) return;
    state = EstadoDoCadastro(erros: {...state.erros}..remove(campo));
  }

  /// Manda o cadastro à API e entra. Devolve o destino, ou `null` se não
  /// deu.
  Future<DestinoDaEntrada?> concluir({
    required String nome,
    required int? regiao,
    required String inscricao,
    required bool aceitouTermos,
  }) async {
    if (state.enviando) return null;
    final cadastro = validarRegistro(
      nome: nome,
      regiao: regiao,
      inscricao: inscricao,
      aceitouTermos: aceitouTermos,
    );
    switch (cadastro) {
      case RegistroInvalido(:final problemas):
        state = EstadoDoCadastro(erros: _mensagens(problemas));
        return null;
      case RegistroValido(:final dados):
        state = const EstadoDoCadastro(enviando: true);
        try {
          await ref.read(cadastroApiProvider)?.cadastrar(dados);
          final destino = await _entrarComAContaGuardada(ref);
          if (ref.mounted) state = const EstadoDoCadastro();
          return destino;
        } on EmailAindaNaoVerificado {
          if (ref.mounted) state = const EstadoDoCadastro();
          return const VerificarEmail();
        } on AppException catch (e) {
          if (ref.mounted) state = EstadoDoCadastro(erroGeral: e.mensagem);
        } catch (_) {
          if (ref.mounted) {
            state = const EstadoDoCadastro(
              erroGeral: AppStrings.erroDesconhecido,
            );
          }
        }
        return null;
    }
  }

  Future<bool> trocarDeConta() => _trocarDeConta(ref);
}

final completarCadastroControladorProvider =
    NotifierProvider.autoDispose<
      CompletarCadastroControlador,
      EstadoDoCadastro
    >(CompletarCadastroControlador.new);
