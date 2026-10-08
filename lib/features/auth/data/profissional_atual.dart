import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    try {
      final perfil = await ref.read(repositorioDaContaProvider).perfil(uid);
      // A sessão pode ter mudado enquanto o banco respondia.
      if (perfil == null || !ref.mounted) return;
      if (ref.read(sessaoProvider)?.uid != uid) return;
      // Só o que ainda está vazio: se a Conta salvou nesse meio-tempo, vale
      // o que foi salvo.
      if (state.nome.isNotEmpty || state.registro.isNotEmpty) return;
      state = Profissional(
        nome: perfil.nome,
        registro: perfil.registro,
        email: state.email,
      );
    } catch (erro) {
      // Sem o perfil, a Conta pede de novo; o app não deixa de abrir.
      debugPrint('Perfil do profissional indisponível: $erro');
    }
  }

  void definir(Profissional profissional) => state = profissional;
}

final profissionalAtualProvider =
    NotifierProvider<ProfissionalAtual, Profissional>(ProfissionalAtual.new);
