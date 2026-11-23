import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/network/interceptors/error_interceptor.dart';
import 'package:fonar_app/features/auth/data/profissional_atual.dart';
import 'package:fonar_app/features/cadastro/data/cadastro_api.dart';
import 'package:fonar_app/features/cadastro/domain/cadastro.dart';
import 'package:fonar_app/features/cadastro/presentation/comprovante_controlador.dart';
import 'package:fonar_app/l10n/app_strings.dart';

import '../../apoio/http_falso.dart';

/// O comprovante de inscrição (US63, ADR-021 da API): o envio pela API e o
/// controlador da Conta.
const _perfil = {
  'id': 'uid-1',
  'email': 'fono@exemplo.com',
  'nome': 'Ana Souza',
  'crefono_regiao': 2,
  'crefono_numero': '12345',
  'registro_conselho': 'CRFa 2-12345',
  'situacao': 'pendente',
  'credenciado_em': null,
  'versao_termos': '2026-10-14',
  'cadastro_completo': true,
  'comprovante_enviado_em': '2026-11-23T18:00:00Z',
  'comprovante_conferido_em': null,
};

final _png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 1, 2]);

({CadastroApi api, AdaptadorFalso servidor}) _montar(
  List<RespostaFalsa> respostas,
) {
  final servidor = AdaptadorFalso(respostas);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = servidor
    ..interceptors.add(const ErrorInterceptor());
  return (api: CadastroApi(dio), servidor: servidor);
}

RespostaFalsa _recusa(int status, String codigo) => RespostaFalsa(status, {
  'detail': {'codigo': codigo, 'mensagem': 'x'},
});

void main() {
  group('CadastroApi.enviarComprovante', () {
    test('PUT multipart no /comprovante, e lê a data do envio', () async {
      final m = _montar([const RespostaFalsa(200, _perfil)]);
      final perfil = await m.api.enviarComprovante(_png, 'carteira.png');
      final pedido = m.servidor.feitas.single;
      expect(pedido.opcoes.method, 'PUT');
      expect(
        pedido.uri.toString(),
        'https://api.test/v1/profissionais/eu/comprovante',
      );
      expect(pedido.corpo, contains('filename="carteira.png"'));
      expect(
        perfil.comprovanteEnviadoEm?.toUtc(),
        DateTime.utc(2026, 11, 23, 18),
      );
    });

    test('cada recusa da API vira a mensagem do que fazer', () async {
      final casos = {
        _recusa(415, 'formato_nao_suportado'):
            AppStrings.comprovanteErroFormato,
        _recusa(413, 'arquivo_grande_demais'):
            AppStrings.comprovanteErroTamanho,
        _recusa(422, 'ja_credenciado'): AppStrings.comprovanteErroJaCredenciado,
        _recusa(422, 'cadastro_incompleto'):
            AppStrings.comprovanteErroCadastroIncompleto,
      };
      for (final MapEntry(key: resposta, value: mensagem) in casos.entries) {
        final m = _montar([resposta]);
        await expectLater(
          m.api.enviarComprovante(_png, 'carteira.png'),
          throwsA(
            isA<ComprovanteRecusado>().having(
              (r) => r.mensagem,
              'mensagem',
              mensagem,
            ),
          ),
        );
      }
    });
  });

  group('ComprovanteControlador', () {
    ProviderContainer montar(
      List<RespostaFalsa> respostas, {
      ArquivoDoComprovante? escolhido,
    }) {
      final m = _montar(respostas);
      final container = ProviderContainer(
        overrides: [
          cadastroApiProvider.overrideWithValue(m.api),
          seletorDeComprovanteProvider.overrideWithValue(() async => escolhido),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('envia o escolhido e atualiza o profissional da sessão', () async {
      final container = montar(
        [const RespostaFalsa(200, _perfil)],
        escolhido: (dados: _png, nome: 'carteira.png'),
      );
      final enviou = await container
          .read(comprovanteControladorProvider.notifier)
          .escolherEEnviar();
      expect(enviou, isTrue);
      expect(container.read(comprovanteControladorProvider).enviado, isTrue);
      final profissional = container.read(profissionalAtualProvider);
      expect(profissional.credenciamento, Credenciamento.pendente);
      expect(profissional.comprovanteEnviadoEm, isNotNull);
    });

    test('cancelar a escolha não envia nada', () async {
      final container = montar(const []);
      final enviou = await container
          .read(comprovanteControladorProvider.notifier)
          .escolherEEnviar();
      expect(enviou, isFalse);
      expect(container.read(comprovanteControladorProvider).erro, isNull);
    });

    test('acima de 10 MB, recusa antes de gastar a rede', () async {
      final container = montar(
        const [],
        escolhido: (
          dados: Uint8List(tamanhoMaximoDoComprovante + 1),
          nome: 'grande.png',
        ),
      );
      await container
          .read(comprovanteControladorProvider.notifier)
          .escolherEEnviar();
      expect(
        container.read(comprovanteControladorProvider).erro,
        AppStrings.comprovanteErroTamanho,
      );
    });

    test('recusa da API: a mensagem fica no estado', () async {
      final container = montar(
        [_recusa(415, 'formato_nao_suportado')],
        escolhido: (dados: _png, nome: 'carteira.gif'),
      );
      await container
          .read(comprovanteControladorProvider.notifier)
          .escolherEEnviar();
      expect(
        container.read(comprovanteControladorProvider).erro,
        AppStrings.comprovanteErroFormato,
      );
    });
  });
}
