import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// De onde vem a imagem pronta que o servidor gerou — o espectrograma.
///
/// Só busca e mostra: o aplicativo não desenha espectrograma (ver a regra de
/// processamento de áudio no CLAUDE.md). Trocável nos testes, que não têm
/// rede.
///
/// TODO(backend): se a API exigir o token para servir a imagem, os
/// cabeçalhos entram aqui.
final imagemDoServidorProvider = Provider<ImageProvider Function(String url)>(
  (ref) => NetworkImage.new,
);
