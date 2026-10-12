import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/error_interceptor.dart';
import '../domain/cadastro.dart';

/// O cadastro do profissional na API: `/v1/profissionais/eu` (o
/// autocadastro da ADR-015 do `fonar-api`).
///
///     GET   403 email_nao_verificado        -> [EmailPorVerificar]
///           403 profissional_nao_cadastrado -> [SemCadastro]
///           200                             -> [Cadastrado] (completo ou não)
///     POST  cria o cadastro, ou completa o antigo (só com e-mail verificado);
///           201 criado, 200 se já existia completo — repetir é seguro
///     PATCH troca nome, região ou número
///
/// O e-mail vem do token: o app nunca o manda no corpo. A API recusa campo
/// que não conhece, então o corpo leva só o que ela pede.
class CadastroApi {
  const CadastroApi(this._dio);

  final Dio _dio;

  static const _caminho = '/v1/profissionais/eu';

  Future<SituacaoDoCadastro> situacao() async {
    try {
      final resposta = await _dio.get<Object?>(_caminho);
      return Cadastrado(perfilDaApi(resposta.data));
    } on DioException catch (e) {
      switch (codigoDaApi(e)) {
        case 'email_nao_verificado':
          return const EmailPorVerificar();
        case 'profissional_nao_cadastrado':
          return const SemCadastro();
      }
      throw _falha(e);
    }
  }

  /// Cria o cadastro — ou completa o antigo, do convite. Se ele já existia
  /// completo (o envio anterior chegou e a resposta se perdeu), a API devolve
  /// o que existe. Lança [EmailAindaNaoVerificado] se ela ainda não vê o
  /// e-mail confirmado.
  Future<PerfilProfissional> cadastrar(DadosDoCadastro dados) async {
    try {
      final resposta = await _dio.post<Object?>(
        _caminho,
        data: {
          'nome': dados.nome,
          'crefono_regiao': dados.crefonoRegiao,
          'crefono_numero': dados.crefonoNumero,
          'versao_termos': versaoDosTermos,
        },
      );
      return perfilDaApi(resposta.data);
    } on DioException catch (e) {
      if (codigoDaApi(e) == 'email_nao_verificado') {
        throw const EmailAindaNaoVerificado();
      }
      throw _falha(e);
    }
  }

  /// Troca nome, região ou número. Trocar a inscrição de quem foi
  /// credenciado volta o cadastro a pendente — quem decide é a API.
  Future<PerfilProfissional> atualizar(DadosDoCadastro dados) async {
    try {
      final resposta = await _dio.patch<Object?>(
        _caminho,
        data: {
          'nome': dados.nome,
          'crefono_regiao': dados.crefonoRegiao,
          'crefono_numero': dados.crefonoNumero,
        },
      );
      return perfilDaApi(resposta.data);
    } on DioException catch (e) {
      throw _falha(e);
    }
  }

  static AppException _falha(DioException e) {
    final falha = e.error;
    return falha is AppException ? falha : FalhaDesconhecida(causa: e);
  }
}

/// O cadastro no formato da API.
PerfilProfissional perfilDaApi(Object? corpo) {
  if (corpo is! Map) {
    throw const FalhaDesconhecida(causa: 'cadastro sem corpo');
  }
  final email = corpo['email'];
  if (email is! String) {
    throw const FalhaDesconhecida(causa: 'cadastro sem e-mail');
  }
  final nome = corpo['nome'];
  final regiao = corpo['crefono_regiao'];
  final numero = corpo['crefono_numero'];
  final registro = corpo['registro_conselho'];
  return PerfilProfissional(
    email: email,
    credenciamento: Credenciamento.daApi(corpo['situacao']),
    // Sem o campo, conta como incompleto: o app pede o cadastro de novo, e
    // o POST é seguro de repetir.
    completo: corpo['cadastro_completo'] == true,
    registro: registro is String ? registro : null,
    nome: nome is String ? nome : null,
    crefonoRegiao: regiao is int ? regiao : null,
    crefonoNumero: numero is String ? numero : null,
  );
}

/// A API do cadastro, ou `null` no build sem `FONAR_API_BASE_URL` — aí não
/// há cadastro a conferir, e a entrada segue como antes.
final cadastroApiProvider = Provider<CadastroApi?>(
  (ref) =>
      AppConfig.apiConfigurada ? CadastroApi(ref.watch(dioProvider)) : null,
);
