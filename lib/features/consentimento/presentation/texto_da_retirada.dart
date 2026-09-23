import '../../../l10n/app_strings.dart';
import '../domain/consentimento.dart';

/// "Em 23/09/2026, às 10:15, a pedido do próprio paciente. A gravação fica
/// bloqueada até um novo consentimento."
String textoDaRetirada(RetiradaDeConsentimento r) =>
    AppStrings.consentimentoRetiradoTexto(
      data: AppStrings.data(r.retiradaEm),
      hora: AppStrings.hora(r.retiradaEm),
      quem: switch (r.quemPediu) {
        QuemAutoriza.paciente => AppStrings.retiradaPeloPaciente,
        QuemAutoriza.responsavelLegal => AppStrings.retiradaPeloResponsavel(
          r.nomeDoResponsavel ?? '',
        ),
      },
    );
