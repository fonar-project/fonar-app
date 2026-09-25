import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_movimento.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_botao.dart';

/// Pergunta antes de uma ação que não se desfaz, e devolve `true` só se a
/// pessoa confirmou.
///
/// O caminho seguro é o principal e o que vale por padrão: tocar fora, a
/// tecla Esc ou o voltar do sistema respondem [cancelar], nunca [confirmar].
/// Nada de vermelho: a gravidade está no texto, que diz o que se perde.
///
/// Sem animação de entrada quando o sistema pede menos movimento.
///
/// ## É ESTE o padrão de confirmação destrutiva do aplicativo
///
/// Até 25/09/2026 conviviam três: este diálogo (sair de um formulário com
/// alteração não salva), a pergunta que abria dentro do cartão da sessão
/// (limpeza de gravações, com o estado no controlador) e a que abria dentro
/// da tela da conta (sair, com o estado no widget). A mesma decisão — apagar
/// algo que não volta — era feita de três jeitos, com teclado e leitor de
/// tela funcionando diferente em cada um.
///
/// Ficou este, e não a pergunta embutida na tela, por quatro razões:
///
/// 1. **Foco.** O diálogo é uma rota: prende o foco, anuncia-se ao leitor de
///    tela (`scopesRoute`/`namesRoute`) e devolve o foco ao sair. A pergunta
///    embutida no meio da página não move o foco de lugar nenhum — quem
///    navega por teclado, que é requisito no Windows, podia tocar em
///    "Descartar" e continuar com o foco onde estava, sem nada ser anunciado.
/// 2. **O padrão de saída é cancelar.** Esc, o voltar do sistema e tocar fora
///    respondem `false`. Na pergunta embutida, o voltar do sistema saía da
///    TELA com a pergunta ainda armada.
/// 3. **Hierarquia.** Aqui o seguro é primário e vem primeiro. As duas
///    versões embutidas punham confirmar e cancelar lado a lado, ambos
///    secundários, com o mesmo peso visual para apagar e para desistir.
/// 4. **Um lugar só.** Confirmação destrutiva não é algo que cada tela deva
///    redescobrir; corrigir o comportamento aqui corrige em todas.
///
/// O argumento que sustentava a pergunta embutida — "ela precisa vir junto do
/// que se perde" — continua valendo, e é atendido: [texto] é texto livre, e é
/// nele que entram "há 3 envios na fila, eles pausam e voltam a subir" e
/// "o áudio é apagado deste aparelho". O que se perde é dito; o que mudou é
/// onde a pergunta aparece.
Future<bool> appConfirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String confirmar,
  required String cancelar,
}) async {
  final resposta = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelar,
    barrierColor: AppColors.cinzaChumbo.withValues(alpha: 0.4),
    // Pelo token, não pelo `MediaQuery` direto: `AppMovimento` é onde a
    // preferência de movimento reduzido é lida no projeto, e ele usa a versão
    // `maybe`, que não estoura onde não há `MediaQuery` acima.
    transitionDuration: AppMovimento.duracao(context, AppMovimento.rapida),
    pageBuilder: (context, _, _) => _Confirmacao(
      titulo: titulo,
      texto: texto,
      confirmar: confirmar,
      cancelar: cancelar,
    ),
    transitionBuilder: (context, animacao, _, filho) =>
        FadeTransition(opacity: animacao, child: filho),
  );
  return resposta ?? false;
}

class _Confirmacao extends StatelessWidget {
  const _Confirmacao({
    required this.titulo,
    required this.texto,
    required this.confirmar,
    required this.cancelar,
  });

  final String titulo;
  final String texto;
  final String confirmar;
  final String cancelar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            color: AppColors.creme,
            borderRadius: AppRadius.bordaMedia,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: titulo,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(titulo, style: textos.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(texto, style: textos.bodyLarge),
                    const SizedBox(height: AppSpacing.lg),
                    // O seguro em cima, onde o olho chega primeiro.
                    AppBotao.primario(
                      rotulo: cancelar,
                      aoTocar: () => Navigator.of(context).pop(false),
                      ocupaLargura: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppBotao.secundario(
                      rotulo: confirmar,
                      aoTocar: () => Navigator.of(context).pop(true),
                      ocupaLargura: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
