/// A cifra do arquivo do banco local (US44): o que só existe onde há
/// arquivo — no aparelho. No navegador, `cifra_do_banco_web.dart` não faz
/// nada: lá o banco mora no armazenamento da página, isolado por origem.
library;

export 'cifra_do_banco_web.dart'
    if (dart.library.ffi) 'cifra_do_banco_nativa.dart';
