import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O aparelho tem alguma interface de rede ativa?
///
/// ## Este provider NÃO responde "a API está alcançável"
///
/// Ele responde uma pergunta mais estreita, e a diferença importa: o sistema
/// operacional diz que existe Wi-Fi, cabo ou dados móveis ligados — não que
/// exista saída para a internet do outro lado.
///
/// O caso que separa as duas coisas é comum justamente onde o aplicativo é
/// usado: **Wi-Fi de consultório atrás de portal cativo**, ou rede de clínica
/// que só enxerga a intranet. O aparelho aparece conectado, o indicador diz
/// "Online", e toda chamada ao servidor falha do mesmo jeito. O inverso também
/// existe, e é mais raro: a interface cai por um instante entre duas
/// requisições que funcionaram.
///
/// Por isso o contrato desta camada é:
///
/// - **sem interface** é resposta confiável — não há como alcançar a API, e a
///   interface pode desabilitar o que exige conexão sem tentar;
/// - **com interface** é só uma PISTA — significa "vale a pena tentar", nunca
///   "vai funcionar".
///
/// Nada que dependa de a análise ter chegado ao servidor pode se apoiar neste
/// provider. Quem sabe disso é a resposta da própria chamada, e é a fila de
/// sincronização que guarda o trabalho enquanto ela não chega.
///
/// TODO(US06): cruzar esta pista com o resultado das últimas chamadas à API,
/// para que o indicador de conexão possa mostrar "rede sem acesso ao servidor"
/// — hoje ele mostra "Online" em consultório com portal cativo.
///
/// Continua sendo um `Provider<bool>` de propósito: os testes de tela
/// sobrescrevem com `conexaoOnlineProvider.overrideWithValue(false)` e não
/// precisam de plugin, de canal de plataforma nem de stream falsa.
final conexaoOnlineProvider = Provider<bool>((ref) {
  // Otimista enquanto a primeira leitura não chega: são milissegundos, e
  // abrir a tela de login já piscando "Sem conexão" treina o usuário a não
  // acreditar no indicador.
  return ref.watch(interfaceDeRedeProvider).value ?? true;
});

/// Leitura crua do plugin, isolada aqui para poder ser trocada nos testes sem
/// mexer em [conexaoOnlineProvider].
final interfaceDeRedeProvider = StreamProvider<bool>((ref) {
  final conectividade = ref.watch(conectividadeProvider);
  // `onConnectivityChanged` só emite na MUDANÇA. Sem a leitura inicial, um
  // aparelho que abre o aplicativo já offline ficaria com o valor otimista até
  // a rede mexer — que, em consultório sem sinal, pode ser nunca.
  return conectividade
      .checkConnectivity()
      .asStream()
      .followedBy(conectividade.onConnectivityChanged)
      .map(temInterfaceDeRede);
});

/// O plugin. Provider para que um teste possa injetar outro.
final conectividadeProvider = Provider<Connectivity>((ref) => Connectivity());

/// Traduz o resultado do plugin para a pergunta desta camada.
///
/// O plugin devolve uma LISTA porque um aparelho pode ter Wi-Fi e dados móveis
/// ao mesmo tempo. `ConnectivityResult.none` é a ausência de interface; `vpn`
/// e `other` contam como interface, porque não dá para afirmar que não levam a
/// lugar nenhum.
bool temInterfaceDeRede(List<ConnectivityResult> resultado) =>
    resultado.any((r) => r != ConnectivityResult.none);

extension _Emenda<T> on Stream<T> {
  /// `this` inteira e depois [proxima]. Existe porque `Stream.concat` não faz
  /// parte da biblioteca padrão do Dart.
  Stream<T> followedBy(Stream<T> proxima) async* {
    yield* this;
    yield* proxima;
  }
}
