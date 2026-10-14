import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Há uma gravação em andamento — a vogal sustentada, a fala encadeada.
///
/// O profissional está trabalhando, ainda que sem tocar na tela: o bloqueio
/// por inatividade não cai no meio de uma gravação, e o fim dela recomeça a
/// contagem (`BloqueioPorInatividade`). Quem diz é o controlador da
/// gravação.
class GravacaoEmAndamento extends Notifier<bool> {
  @override
  bool build() => false;

  void definir(bool gravando) {
    if (state != gravando) state = gravando;
  }
}

final gravacaoEmAndamentoProvider = NotifierProvider<GravacaoEmAndamento, bool>(
  GravacaoEmAndamento.new,
);
