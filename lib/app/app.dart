import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/escala_da_interface.dart';
import '../design_system/theme/app_theme.dart';
import '../features/anotacoes/presentation/anotacoes_controlador.dart';
import '../features/auth/presentation/widgets/vigia_de_inatividade.dart';
import '../features/cape_v/presentation/sincronizacao_cape_v_controlador.dart';
import '../features/captura/data/gravador_record.dart';
import '../features/conta/data/preferencia_de_tamanho_local.dart';
import '../features/conta/data/preferencia_de_tema_local.dart';
import '../features/conta/domain/tema_escolhido.dart';
import '../features/fila/presentation/fila_controlador.dart';
import '../features/laudo/presentation/sincronizacao_dos_laudos_controlador.dart';
import '../features/sincronizacao/presentation/descida_controlador.dart';
import '../l10n/app_strings.dart';
import 'router/app_router.dart';

/// Raiz do aplicativo.
class FonarApp extends ConsumerWidget {
  const FonarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acorda a fila de sincronização na abertura e a mantém viva: o que ficou
    // pendente sobe sem o profissional precisar abrir a tela da fila.
    // `listen`, não `watch`, para a raiz não se reconstruir a cada envio.
    ref.listen(filaControladorProvider, (_, _) {});
    // A CAPE-V registrada sobe para o Firebase do mesmo jeito (ADR-017 da
    // API): sem ninguém precisar esperar na tela.
    ref.listen(sincronizacaoCapeVControladorProvider, (_, _) {});
    // E a cópia de cada laudo emitido, para a API (ADR-018 da API).
    ref.listen(sincronizacaoDosLaudosControladorProvider, (_, _) {});
    // E as anotações dos pacientes (US51, ADR-019 da API).
    ref.listen(sincronizacaoDasAnotacoesControladorProvider, (_, _) {});
    // E o caminho de volta (US40): o que outro aparelho da mesma conta
    // cadastrou ou registrou desce para este.
    ref.listen(descidaDaContaControladorProvider, (_, _) {});
    // Os WAV que sobraram sem registro (regravação, descarte que falhou no
    // meio) saem na abertura.
    ref.listen(limpezaDeWavSemRegistroProvider, (_, _) {});

    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.escuro,
      // A escolha da tela Conta; enquanto carrega, a do sistema.
      themeMode: switch (ref.watch(temaEscolhidoProvider).value) {
        TemaEscolhido.claro => ThemeMode.light,
        TemaEscolhido.escuro => ThemeMode.dark,
        TemaEscolhido.sistema || null => ThemeMode.system,
      },
      // Troca de tema sem transição: é mudança de ajuste, não animação.
      themeAnimationDuration: Duration.zero,
      routerConfig: ref.watch(routerProvider),
      // Por cima do roteador: o bloqueio vale para qualquer tela, e o
      // tamanho da interface (US48) amplia todas, os diálogos inclusive.
      // Enquanto a escolha carrega, o automático.
      builder: (context, filho) => EscalaDaInterface(
        tamanho:
            ref.watch(tamanhoDaInterfaceProvider).value ??
            TamanhoDaInterface.automatico,
        child: VigiaDeInatividade(child: filho ?? const SizedBox.shrink()),
      ),
    );
  }
}
