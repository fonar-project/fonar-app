import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registra as licenças que não vêm de pacote Dart, para aparecerem em
/// "Licenças de software", na tela de conta.
///
/// Os pacotes se registram sozinhos. A Urbanist não: é arquivo de fonte
/// embutido no aplicativo, e a licença dela (SIL OFL 1.1) pede que o texto da
/// licença acompanhe a fonte distribuída.
void registrarLicencas() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Urbanist',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
}
