import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O aparelho alcança a rede agora?
///
/// PLACEHOLDER — sempre online.
///
/// TODO: ligar a uma fonte real de conectividade. Detectar interface de rede
/// ativa não basta: Wi-Fi de consultório com portal cativo "está conectado" e
/// não alcança a API. A fonte de verdade precisa ser o resultado das próprias
/// chamadas ao servidor, com a interface de rede servindo só de pista rápida.
final conexaoOnlineProvider = Provider<bool>((ref) => true);
