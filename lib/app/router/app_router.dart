import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analise/presentation/pages/analise_resultado_page.dart';
import '../../features/analise/presentation/pages/espectrograma_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/cape_v/presentation/pages/cape_v_page.dart';
import '../../features/captura/presentation/pages/captura_page.dart';
import '../../features/captura/presentation/pages/gravacoes_nao_enviadas_page.dart';
import '../../features/consentimento/data/repositorio_consentimento_local.dart';
import '../../features/conta/presentation/pages/conta_page.dart';
import '../../features/consentimento/presentation/pages/consentimento_page.dart';
import '../../features/consentimento/presentation/pages/retirada_consentimento_page.dart';
import '../../features/fila/presentation/pages/fila_page.dart';
import '../../features/historico/presentation/pages/evolucao_modo_paciente_page.dart';
import '../../features/historico/presentation/pages/evolucao_page.dart';
import '../../features/historico/presentation/pages/historico_page.dart';
import '../../features/laudo/presentation/pages/laudo_page.dart';
import '../../features/pacientes/presentation/pages/novo_paciente_page.dart';
import '../../features/pacientes/presentation/pages/paciente_detalhe_page.dart';
import '../../features/pacientes/presentation/pages/pacientes_list_page.dart';
import '../app_estrutura.dart';
import 'app_routes.dart';

/// Roteador do app.
///
/// As rotas de paciente são aninhadas de propósito: consentimento, captura e
/// resultado só existem no contexto de um paciente, e o caminho carrega esse
/// contexto. Nenhuma delas deve ser alcançável sem `pacienteId`.
///
/// O roteador NÃO embrulha tela nenhuma na [AppEstrutura]: quem decide ter
/// navegação principal é a própria tela. Ver a convenção documentada em
/// `app_estrutura.dart`.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.loginCaminho,
    debugLogDiagnostics: kDebugMode,

    // TODO(auth): redirect que manda para /login quando não há sessão, e tira
    // de /login quando já há. Vai depender de um provider de estado de
    // autenticação (Firebase Auth) + `refreshListenable`.
    routes: [
      GoRoute(
        name: AppRoutes.loginNome,
        path: AppRoutes.loginCaminho,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: AppRoutes.pacientesNome,
        path: AppRoutes.pacientesCaminho,
        builder: (context, state) => const PacientesListPage(),
        routes: [
          // Antes de :pacienteId — ver AppRoutes.novaAvaliacaoCaminho.
          GoRoute(
            name: AppRoutes.novaAvaliacaoNome,
            path: AppRoutes.novaAvaliacaoCaminho,
            builder: (context, state) => const NovoPacientePage(),
          ),
          GoRoute(
            name: AppRoutes.pacienteDetalheNome,
            path: AppRoutes.pacienteDetalheCaminho,
            builder: (context, state) => PacienteDetalhePage(
              pacienteId: state.pathParameters[AppRoutes.paramPacienteId]!,
            ),
            routes: [
              GoRoute(
                name: AppRoutes.consentimentoNome,
                path: AppRoutes.consentimentoCaminho,
                builder: (context, state) => ConsentimentoPage(
                  pacienteId: state.pathParameters[AppRoutes.paramPacienteId]!,
                ),
                routes: [
                  GoRoute(
                    name: AppRoutes.retiradaConsentimentoNome,
                    path: AppRoutes.retiradaConsentimentoCaminho,
                    builder: (context, state) => RetiradaConsentimentoPage(
                      pacienteId:
                          state.pathParameters[AppRoutes.paramPacienteId]!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                name: AppRoutes.gravacoesNaoEnviadasNome,
                path: AppRoutes.gravacoesNaoEnviadasCaminho,
                builder: (context, state) => GravacoesNaoEnviadasPage(
                  pacienteId: state.pathParameters[AppRoutes.paramPacienteId]!,
                ),
              ),
              GoRoute(
                name: AppRoutes.capturaNome,
                path: AppRoutes.capturaCaminho,
                redirect: (context, state) => _exigirConsentimento(ref, state),
                builder: (context, state) => CapturaPage(
                  pacienteId: state.pathParameters[AppRoutes.paramPacienteId]!,
                ),
              ),
              GoRoute(
                name: AppRoutes.analiseResultadoNome,
                path: AppRoutes.analiseResultadoCaminho,
                builder: (context, state) => AnaliseResultadoPage(
                  pacienteId: state.pathParameters[AppRoutes.paramPacienteId]!,
                  analiseId: state.pathParameters[AppRoutes.paramAnaliseId]!,
                ),
                routes: [
                  GoRoute(
                    name: AppRoutes.espectrogramaNome,
                    path: AppRoutes.espectrogramaCaminho,
                    builder: (context, state) => EspectrogramaPage(
                      pacienteId:
                          state.pathParameters[AppRoutes.paramPacienteId]!,
                      analiseId:
                          state.pathParameters[AppRoutes.paramAnaliseId]!,
                    ),
                  ),
                  GoRoute(
                    name: AppRoutes.capeVNome,
                    path: AppRoutes.capeVCaminho,
                    builder: (context, state) => CapeVPage(
                      pacienteId:
                          state.pathParameters[AppRoutes.paramPacienteId]!,
                      analiseId:
                          state.pathParameters[AppRoutes.paramAnaliseId]!,
                    ),
                  ),
                  GoRoute(
                    name: AppRoutes.laudoNome,
                    path: AppRoutes.laudoCaminho,
                    builder: (context, state) => LaudoPage(
                      pacienteId:
                          state.pathParameters[AppRoutes.paramPacienteId]!,
                      analiseId:
                          state.pathParameters[AppRoutes.paramAnaliseId]!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                name: AppRoutes.evolucaoNome,
                path: AppRoutes.evolucaoCaminho,
                builder: (context, state) => EvolucaoPage(
                  pacienteId: state.pathParameters[AppRoutes.paramPacienteId]!,
                ),
                routes: [
                  GoRoute(
                    name: AppRoutes.modoPacienteNome,
                    path: AppRoutes.modoPacienteCaminho,
                    builder: (context, state) => EvolucaoModoPacientePage(
                      pacienteId:
                          state.pathParameters[AppRoutes.paramPacienteId]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.filaNome,
        path: AppRoutes.filaCaminho,
        builder: (context, state) => const FilaPage(),
      ),
      GoRoute(
        name: AppRoutes.contaNome,
        path: AppRoutes.contaCaminho,
        builder: (context, state) => const ContaPage(),
      ),
      GoRoute(
        name: AppRoutes.historicoNome,
        path: AppRoutes.historicoCaminho,
        builder: (context, state) => const HistoricoPage(),
      ),
    ],

    // TODO: tela de erro própria, em pt-BR, no lugar da padrão do go_router.
  );
});

/// BLOQUEIO TÉCNICO da LGPD: sem consentimento registrado, a gravação não
/// abre — quem tenta chegar nela vai parar no consentimento do paciente.
///
/// Mora aqui, no roteador, e não na tela de gravação, de propósito. Um aviso
/// na tela pode ser ignorado, e uma verificação dentro da tela pode ser
/// esquecida por quem a reescrever; o redirect vale para QUALQUER caminho que
/// leve à gravação — botão, link, voltar do navegador, rota digitada no
/// desktop. Áudio de voz vinculado a paciente é dado pessoal sensível.
///
/// Pergunta ao repositório a cada navegação, sem cache: um consentimento
/// acabado de registrar precisa liberar a gravação na mesma hora, e um
/// revogado precisa bloqueá-la na mesma hora.
///
/// Falha FECHADA: se a consulta der erro, o bloqueio vale como se não houvesse
/// consentimento. Na dúvida, não se grava — a tela de consentimento mostra o
/// erro e deixa tentar de novo.
Future<String?> _exigirConsentimento(Ref ref, GoRouterState state) async {
  final pacienteId = state.pathParameters[AppRoutes.paramPacienteId]!;
  try {
    final consentimento = await ref
        .read(repositorioConsentimentoProvider)
        .buscar(pacienteId);
    if (consentimento != null) return null;
  } catch (_) {
    // Segue para o bloqueio.
  }
  return state.namedLocation(
    AppRoutes.consentimentoNome,
    pathParameters: {AppRoutes.paramPacienteId: pacienteId},
  );
}
