/// Fora do navegador. Ver `navegador.dart`: nada daqui é chamado no
/// aparelho — quem chama confere `kIsWeb` antes.
library;

import 'dart:typed_data';

/// O que o navegador relata do processamento da faixa de áudio. Ver
/// `navegador_web.dart`.
typedef ProcessamentoRelatado = ({bool? ganho, bool? ruido, bool? eco});

Future<Uint8List> lerEnderecoTemporario(String endereco) =>
    throw UnsupportedError('Só no navegador.');

Future<ProcessamentoRelatado> processamentoRelatadoPeloNavegador({
  required int taxaDeAmostragem,
  required int canais,
  String? microfone,
}) => throw UnsupportedError('Só no navegador.');

String descricaoDoNavegador() => '';

Future<Uint8List> pbkdf2NoNavegador(
  List<int> senha,
  List<int> sal,
  int iteracoes,
  int tamanho,
) => throw UnsupportedError('Só no navegador.');

Future<void> pedirArmazenamentoPersistente() async {}
