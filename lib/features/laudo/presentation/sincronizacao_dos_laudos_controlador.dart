import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sincronizacao/domain/sincronizavel.dart';
import '../../sincronizacao/presentation/sincronizacao_em_segundo_plano.dart';
import '../data/laudos_na_api.dart';

/// Sobe a cópia dos laudos emitidos sem ninguém olhando (US38). O quando é
/// o de toda [SincronizacaoEmSegundoPlano]; o quê, [LaudosNaApi].
class SincronizacaoDosLaudosControlador extends SincronizacaoEmSegundoPlano {
  @override
  Sincronizavel? get alvo => ref.read(sincronizacaoDosLaudosProvider);
}

final sincronizacaoDosLaudosControladorProvider =
    NotifierProvider<SincronizacaoDosLaudosControlador, void>(
      SincronizacaoDosLaudosControlador.new,
    );
