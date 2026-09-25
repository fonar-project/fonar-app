import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../tokens/app_cores.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_icone.dart';

/// Indicador de conexão, sempre visível no cabeçalho.
///
/// Não é enfeite: gravação funciona offline, análise exige conexão. O
/// profissional precisa saber, ANTES de começar a consulta, se o resultado vai
/// sair hoje ou entrar na fila. Descobrir isso depois de gravar é perder a
/// amostra e o tempo do paciente.
///
/// ## Sem verde, de propósito
///
/// Verde, amarelo e vermelho são exclusivos de status de medida e saturação de
/// áudio. Conexão não é nenhum dos dois — um "online" verde ao lado de uma
/// medida "dentro da faixa" verde diria que as duas coisas são da mesma
/// natureza. O estado se distingue por FORMA: ponto cheio contra anel vazado,
/// borda fina contra borda grossa, texto regular contra negrito. Sem conexão é
/// o estado que exige atenção, então é ele que pesa mais.
class AppIndicadorConexao extends StatelessWidget {
  const AppIndicadorConexao({
    required this.online,
    this.sobreFundoEscuro = false,
    super.key,
  });

  final bool online;

  /// No cabeçalho roxo do mobile o indicador vira creme sobre roxo.
  final bool sobreFundoEscuro;

  @override
  Widget build(BuildContext context) {
    final corBase = sobreFundoEscuro
        ? context.cores.sobrePrimaria
        : context.cores.texto;
    final corDoPonto = sobreFundoEscuro
        ? context.cores.sobrePrimaria
        : (online ? context.cores.acento : context.cores.texto);

    final borda = online
        ? BorderSide(
            color: sobreFundoEscuro
                ? context.cores.sobrePrimaria.withValues(alpha: 0.4)
                : context.cores.borda,
          )
        : BorderSide(color: corBase, width: 1.5);

    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 1,
        ),
        decoration: BoxDecoration(
          border: Border.fromBorderSide(borda),
          borderRadius: AppRadius.bordaPilula,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcone(
              nome: online
                  ? NomeIcone.estadoOnline
                  : NomeIcone.estadoSemConexao,
              cor: corDoPonto,
              tamanho: 16,
            ),
            const SizedBox(width: AppSpacing.xxs),
            // Flexible: com o texto do sistema em 200%, "Sem conexão" não cabe
            // numa linha ao lado do ícone em 390 px, e quebrar é melhor que
            // cortar o estado da rede.
            Flexible(
              child: Text(
                online ? AppStrings.conexaoOnline : AppStrings.conexaoOffline,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: corBase,
                  fontWeight: online ? FontWeight.w600 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
