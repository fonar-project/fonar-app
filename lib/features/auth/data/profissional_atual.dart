import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profissional.dart';

/// Quem está com o aplicativo aberto.
///
/// Estado da sessão, e não consulta: a barra lateral e o laudo leem daqui a
/// toda hora, e a tela de conta o atualiza quando o profissional corrige os
/// próprios dados.
///
/// TODO(auth): nascer da sessão do Firebase Auth (e do perfil guardado junto
/// dela), em vez do profissional fictício.
class ProfissionalAtual extends Notifier<Profissional> {
  @override
  Profissional build() => const Profissional(
    nome: 'Fon.ª Exemplo da Silva',
    registro: 'CRFa 0-00000 (exemplo)',
    email: 'profissional@exemplo.invalid',
  );

  void definir(Profissional profissional) => state = profissional;
}

/// PLACEHOLDER — profissional fictício, marcado "(exemplo)".
final profissionalAtualProvider =
    NotifierProvider<ProfissionalAtual, Profissional>(ProfissionalAtual.new);
