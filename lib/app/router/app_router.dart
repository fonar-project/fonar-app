import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/widgets/tela_placeholder.dart';
import '../../features/analise/presentation/pages/analise_resultado_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/captura/presentation/pages/captura_page.dart';
import '../../features/consentimento/presentation/pages/consentimento_page.dart';
import '../../features/historico/presentation/pages/historico_page.dart';
import '../../features/pacientes/presentation/pages/novo_paciente_page.dart';
import '../../features/pacientes/presentation/pages/paciente_detalhe_page.dart';
import '../../features/pacientes/presentation/pages/pacientes_list_page.dart';
import '../../l10n/app_strings.dart';
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
    //
    // TODO(LGPD — bloqueio técnico): a rota de captura não pode ser alcançável
    // sem consentimento registrado para aquele paciente. O bloqueio é aqui, no
    // redirect, não um aviso na tela de captura: se o consentimento não estiver
    // registrado, redirecionar para /pacientes/:pacienteId/consentimento.
    // Áudio de voz vinculado a paciente é dado pessoal sensível.
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
              ),
              GoRoute(
                name: AppRoutes.capturaNome,
                path: AppRoutes.capturaCaminho,
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
              ),
            ],
          ),
        ],
      ),
      // TODO(US06): fila de sincronização.
      GoRoute(
        name: AppRoutes.filaNome,
        path: AppRoutes.filaCaminho,
        builder: (context, state) => const TelaPlaceholder(
          titulo: AppStrings.filaTitulo,
          rota: AppRoutes.filaCaminho,
          destino: DestinoPrincipal.fila,
        ),
      ),
      // TODO(US11): conta do profissional.
      GoRoute(
        name: AppRoutes.contaNome,
        path: AppRoutes.contaCaminho,
        builder: (context, state) => const TelaPlaceholder(
          titulo: AppStrings.contaTitulo,
          rota: AppRoutes.contaCaminho,
          destino: DestinoPrincipal.conta,
        ),
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
