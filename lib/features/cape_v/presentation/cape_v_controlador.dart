import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/relogio.dart';
import '../../../l10n/app_strings.dart';
import '../data/repositorio_cape_v_em_memoria.dart';
import '../domain/avaliacao_cape_v.dart';

/// O formulário da CAPE-V de uma análise.
class EstadoCapeV {
  const EstadoCapeV({
    this.notas = const {},
    this.comentariosIniciais = '',
    this.jaRegistrada = false,
    this.registrando = false,
    this.problemas = const {},
    this.erroGeral,
  });

  final Map<ParametroCapeV, NotaCapeV> notas;

  /// Os comentários da avaliação já registrada, para o campo começar com
  /// eles ao editar. Depois disso o texto vive no campo.
  final String comentariosIniciais;

  /// Editando uma avaliação que já existe.
  final bool jaRegistrada;
  final bool registrando;

  /// O que falta em cada parâmetro, depois de tentar registrar.
  final Map<ParametroCapeV, ProblemaNaNota> problemas;
  final String? erroGeral;

  EstadoCapeV copiar({
    Map<ParametroCapeV, NotaCapeV>? notas,
    bool? registrando,
    Map<ParametroCapeV, ProblemaNaNota>? problemas,
    String? Function()? erroGeral,
  }) => EstadoCapeV(
    notas: notas ?? this.notas,
    comentariosIniciais: comentariosIniciais,
    jaRegistrada: jaRegistrada,
    registrando: registrando ?? this.registrando,
    problemas: problemas ?? this.problemas,
    erroGeral: erroGeral != null ? erroGeral() : this.erroGeral,
  );
}

class CapeVControlador extends AsyncNotifier<EstadoCapeV> {
  CapeVControlador(this.analiseId);

  final String analiseId;

  @override
  Future<EstadoCapeV> build() async {
    final existente = await ref
        .read(repositorioCapeVProvider)
        .daAnalise(analiseId);
    if (existente == null) return const EstadoCapeV();
    return EstadoCapeV(
      notas: existente.notas,
      comentariosIniciais: existente.comentarios,
      jaRegistrada: true,
    );
  }

  EstadoCapeV get _estado => state.value ?? const EstadoCapeV();

  void marcar(ParametroCapeV parametro, int valor) =>
      _mudar(parametro, (n) => n.comValor(valor));

  void definirConsistencia(ParametroCapeV parametro, Consistencia c) =>
      _mudar(parametro, (n) => n.comConsistencia(c));

  void definirDirecao(ParametroCapeV parametro, DirecaoDoDesvio d) =>
      _mudar(parametro, (n) => n.comDirecao(d));

  /// Muda a nota de [parametro] e tira o problema dele da tela — ele volta,
  /// se ainda houver, na próxima tentativa de registrar.
  void _mudar(ParametroCapeV parametro, NotaCapeV Function(NotaCapeV) mudanca) {
    final atual = _estado;
    final nota = mudanca(atual.notas[parametro] ?? const NotaCapeV());
    state = AsyncData(
      atual.copiar(
        notas: {...atual.notas, parametro: nota},
        problemas: {...atual.problemas}..remove(parametro),
      ),
    );
  }

  /// Confere e registra. Devolve `true` se registrou.
  Future<bool> registrar({
    required String pacienteId,
    required String comentarios,
  }) async {
    final atual = _estado;
    if (atual.registrando) return false;

    final problemas = conferirNotas(atual.notas);
    if (problemas.isNotEmpty) {
      state = AsyncData(
        atual.copiar(problemas: problemas, erroGeral: () => null),
      );
      return false;
    }

    state = AsyncData(atual.copiar(registrando: true, erroGeral: () => null));
    try {
      await ref
          .read(repositorioCapeVProvider)
          .registrar(
            AvaliacaoCapeV(
              analiseId: analiseId,
              pacienteId: pacienteId,
              notas: atual.notas,
              registradaEm: ref.read(relogioProvider)(),
              comentarios: comentarios.trim(),
            ),
          );
    } catch (e) {
      if (ref.mounted) {
        state = AsyncData(
          atual.copiar(
            registrando: false,
            erroGeral: () =>
                e is AppException ? e.mensagem : AppStrings.erroDesconhecido,
          ),
        );
      }
      return false;
    }

    ref.invalidate(capeVDaAnaliseProvider(analiseId));
    if (ref.mounted) state = AsyncData(atual.copiar(registrando: false));
    return true;
  }
}

final capeVControladorProvider = AsyncNotifierProvider.autoDispose
    .family<CapeVControlador, EstadoCapeV, String>(CapeVControlador.new);
