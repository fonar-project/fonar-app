import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cadastro/data/cadastro_api.dart';
import '../../cadastro/domain/cadastro.dart';
import '../../conta/data/repositorio_da_conta_local.dart';
import '../domain/profissional.dart';
import 'sessao.dart';

/// Quem está com o aplicativo aberto: o e-mail vem da sessão, e o nome e o
/// registro, do perfil que o profissional preencheu na Conta.
///
/// Estado da sessão, e não consulta: a barra lateral e o laudo leem daqui a
/// toda hora, e a tela de conta o atualiza quando o profissional corrige os
/// próprios dados.
///
/// Sem perfil preenchido — a primeira entrada neste aparelho —, nome e
/// registro ficam vazios, e quem os mostra diz que faltam: o laudo não sai
/// sem quem assina.
class ProfissionalAtual extends Notifier<Profissional> {
  @override
  Profissional build() {
    final conta = ref.watch(sessaoProvider);
    if (conta == null) return const Profissional(nome: '', registro: '');
    _carregar(conta.uid);
    return Profissional(nome: '', registro: '', email: conta.email);
  }

  Future<void> _carregar(String uid) async {
    await _carregarDoAparelho(uid);
    await _carregarDaApi(uid);
  }

  /// O que ficou guardado neste aparelho: rápido, e funciona sem rede.
  Future<void> _carregarDoAparelho(String uid) async {
    try {
      final perfil = await ref.read(repositorioDaContaProvider).perfil(uid);
      // A sessão pode ter mudado enquanto o banco respondia.
      if (perfil == null || !_daSessao(uid)) return;
      // Só o que ainda está vazio: se a Conta salvou nesse meio-tempo, vale
      // o que foi salvo.
      if (state.nome.isNotEmpty || state.registro.isNotEmpty) return;
      state = Profissional(
        nome: perfil.nome,
        registro: perfil.registro,
        email: state.email,
        credenciamento: state.credenciamento,
      );
    } catch (erro) {
      // Sem o perfil, a Conta pede de novo; o app não deixa de abrir.
      debugPrint('Perfil do profissional indisponível: $erro');
    }
  }

  /// O cadastro na API, que é a fonte da verdade quando ela está
  /// configurada (US34): nome, registro e a situação do credenciamento. O
  /// que vier fica guardado no aparelho, para o laudo sair sem rede.
  Future<void> _carregarDaApi(String uid) async {
    final api = ref.read(cadastroApiProvider);
    if (api == null) return;
    try {
      final situacao = await api.situacao();
      if (!_daSessao(uid)) return;
      if (situacao case Cadastrado(:final perfil)) {
        final profissional = Profissional(
          nome: perfil.nome ?? state.nome,
          registro: perfil.registro ?? state.registro,
          email: state.email,
          credenciamento: perfil.credenciamento,
        );
        state = profissional;
        await ref.read(repositorioDaContaProvider).salvar(uid, profissional);
      }
    } catch (erro) {
      // Sem rede ou sem a API: fica o que estava no aparelho.
      debugPrint('Cadastro na API indisponível: $erro');
    }
  }

  bool _daSessao(String uid) =>
      ref.mounted && ref.read(sessaoProvider)?.uid == uid;

  void definir(Profissional profissional) => state = profissional;
}

final profissionalAtualProvider =
    NotifierProvider<ProfissionalAtual, Profissional>(ProfissionalAtual.new);
