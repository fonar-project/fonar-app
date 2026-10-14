/// O que só existe quando o FONAR roda no navegador (US42, a versão para o
/// iPhone).
///
/// O mesmo nome nos dois lados: no navegador, `navegador_web.dart`, que fala
/// com o navegador pelo `package:web`; fora dele, `navegador_fora.dart`, que
/// nunca é chamado — quem chama confere `kIsWeb` antes — e existe para o
/// resto do app compilar sem `dart:js_interop`, que só há no navegador.
///
/// Nada aqui decide layout nem libera funcionalidade: as plataformas têm o
/// mesmo conjunto de recursos. É o encanamento que o navegador pede para
/// fazer o mesmo que o aparelho faz com arquivo e microfone.
library;

export 'navegador_fora.dart' if (dart.library.js_interop) 'navegador_web.dart';
