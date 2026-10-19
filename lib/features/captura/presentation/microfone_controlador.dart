import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/microfones_record.dart';
import '../domain/microfone.dart';

/// O microfone guardado neste aparelho, ou `null` — o padrão do sistema.
///
/// Carregado na abertura do app (quem acorda é o `FonarApp`), e não na hora
/// de gravar: a captura lê o valor que já está na memória
/// ([microfoneParaCapturar]) e nunca espera o banco para abrir o microfone.
/// Só o banco — listar os microfones fica para quando a escolha aparece,
/// porque no navegador listar pede a permissão do microfone.
class MicrofoneGuardadoControlador extends AsyncNotifier<Microfone?> {
  @override
  Future<Microfone?> build() async {
    try {
      return await ref.read(preferenciaDeMicrofoneProvider).ler();
    } catch (erro) {
      // Sem a escolha, vale o padrão — como antes de ela existir.
      debugPrint('Escolha de microfone indisponível: $erro');
      return null;
    }
  }

  /// Vale na hora e guarda. Se guardar falhar, vale até o app fechar.
  Future<void> guardar(Microfone? microfone) async {
    // A leitura da abertura, se ainda estiver em curso, terminaria depois e
    // passaria por cima da escolha nova.
    try {
      await future;
    } catch (_) {}
    state = AsyncData(microfone);
    try {
      await ref.read(preferenciaDeMicrofoneProvider).guardar(microfone);
    } catch (erro) {
      debugPrint('Não foi possível guardar o microfone: $erro');
    }
  }
}

final microfoneGuardadoProvider =
    AsyncNotifierProvider<MicrofoneGuardadoControlador, Microfone?>(
      MicrofoneGuardadoControlador.new,
    );

/// Os microfones ligados e o escolhido para gravar, para a tela.
///
/// Não é `autoDispose`: a lista só se lê de novo quando alguém pede
/// ([atualizar]) — cada aferição concluída pede, para um microfone
/// recém-ligado aparecer.
///
/// No navegador, listar pede a permissão do microfone. Por isso a tela só
/// mostra a escolha depois da primeira aferição, que já a pediu.
class MicrofoneControlador extends AsyncNotifier<EscolhaDoMicrofone> {
  @override
  Future<EscolhaDoMicrofone> build() async {
    final salvo = await ref.watch(microfoneGuardadoProvider.future);
    final List<Microfone> disponiveis;
    try {
      disponiveis = await ref.read(listaDeMicrofonesProvider).listar();
    } catch (erro) {
      // Sem lista, vale o padrão do sistema.
      debugPrint('Microfones indisponíveis: $erro');
      return const EscolhaDoMicrofone();
    }
    return resolverEscolha(disponiveis: disponiveis, salvo: salvo);
  }

  /// Escolhe [microfone] — `null` volta ao padrão do sistema — e guarda.
  Future<void> escolher(Microfone? microfone) =>
      ref.read(microfoneGuardadoProvider.notifier).guardar(microfone);

  /// Lê a lista de novo — e com ela a escolha, que pode ter voltado a
  /// valer ou deixado de valer.
  void atualizar() => ref.invalidateSelf();
}

final microfoneControladorProvider =
    AsyncNotifierProvider<MicrofoneControlador, EscolhaDoMicrofone>(
      MicrofoneControlador.new,
    );

/// O identificador do microfone para a próxima captura, ou `null` para o
/// padrão do sistema. Nunca falha: sem lista, é o padrão.
///
/// Sem escolha guardada — o caso de quase todo aparelho —, nem lista: é o
/// padrão, como antes de a escolha existir. Com escolha, confere se o
/// microfone está ligado; pedir um que não está faria a captura falhar.
Future<String?> microfoneParaCapturar(Ref ref) async {
  try {
    // Só o que já está na memória: quem carrega é o `FonarApp`, na
    // abertura. Ler aqui abriria o banco no meio da captura.
    if (!ref.exists(microfoneGuardadoProvider) ||
        ref.read(microfoneGuardadoProvider).value == null) {
      return null;
    }
    return (await ref.read(microfoneControladorProvider.future)).escolhido?.id;
  } catch (_) {
    return null;
  }
}
