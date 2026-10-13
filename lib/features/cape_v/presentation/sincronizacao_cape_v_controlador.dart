import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sincronizacao/domain/sincronizavel.dart';
import '../../sincronizacao/presentation/sincronizacao_em_segundo_plano.dart';
import '../data/cape_v_no_firestore.dart';

/// Sobe a CAPE-V para o Firebase sem ninguém olhando (US37). O quando é o
/// de toda [SincronizacaoEmSegundoPlano]; o quê, [CapeVNoFirestore].
class SincronizacaoCapeVControlador extends SincronizacaoEmSegundoPlano {
  @override
  Sincronizavel? get alvo => ref.read(sincronizacaoDaCapeVProvider);
}

final sincronizacaoCapeVControladorProvider =
    NotifierProvider<SincronizacaoCapeVControlador, void>(
      SincronizacaoCapeVControlador.new,
    );
