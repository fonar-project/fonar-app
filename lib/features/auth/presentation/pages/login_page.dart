import 'package:flutter/material.dart';

import '../../../../design_system/widgets/tela_placeholder.dart';
import '../../../../l10n/app_strings.dart';

/// TODO: implementar autenticação (Firebase Auth).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const TelaPlaceholder(
        titulo: AppStrings.loginTitulo,
        rota: '/login',
      );
}
