import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/error_interceptor.dart';
import '../domain/cadastro.dart';

/// O cadastro do profissional na API: `/v1/profissionais/eu`.
///
///     GET   403 email_nao_verificado        -> [EmailPorVerificar]
///           403 profissional_nao_cadastrado -> [SemCadastro]
///           200                             -> [Cadastrado]
///     POST  cria o cadastro (só com e-mail verificado)
///     PATCH troca nome ou inscrição
///
/// O e-mail vem do token: o app nunca o manda no corpo.
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

  /// Cria o cadastro. Se ele já existe (o envio anterior chegou e a resposta
  /// se perdeu), devolve o que existe. Lança [EmailAindaNaoVerificado] se a
  /// API ainda não vê o e-mail confirmado.
  Future<PerfilProfissional> cadastrar(DadosDoCadastro dados) async {
    try {
      final resposta = await _dio.post<Object?>(
        _caminho,
        data: {
          'nome': dados.nome,
          'crefono_regiao': dados.crefonoRegiao,
          'crefono_inscricao': dados.crefonoInscricao,
          'versao_termos': versaoDosTermos,
          'aceita_termos': true,
        },
      );
      return perfilDaApi(resposta.data);
    } on DioException catch (e) {
      switch (codigoDaApi(e)) {
        case 'profissional_ja_cadastrado':
          final situacao = await this.situacao();
          if (situacao case Cadastrado(:final perfil)) return perfil;
        case 'email_nao_verificado':
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
          'crefono_inscricao': dados.crefonoInscricao,
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
  final registro = corpo['registro_conselho'];
  if (email is! String || registro is! String) {
    throw const FalhaDesconhecida(causa: 'cadastro sem e-mail ou registro');
  }
  final nome = corpo['nome'];
  final regiao = corpo['crefono_regiao'];
  final inscricao = corpo['crefono_inscricao'];
  final observacao = corpo['credenciamento_observacao'];
  return PerfilProfissional(
    email: email,
    registro: registro,
    credenciamento: Credenciamento.daApi(corpo['credenciamento']),
    nome: nome is String ? nome : null,
    crefonoRegiao: regiao is int ? regiao : null,
    crefonoInscricao: inscricao is String ? inscricao : null,
    observacao: observacao is String ? observacao : null,
  );
}

/// A API do cadastro, ou `null` no build sem `FONAR_API_BASE_URL` — aí não
/// há cadastro a conferir, e a entrada segue como antes.
final cadastroApiProvider = Provider<CadastroApi?>(
  (ref) =>
      AppConfig.apiConfigurada ? CadastroApi(ref.watch(dioProvider)) : null,
);
