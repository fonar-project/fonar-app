import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonar_app/core/banco/banco_local.dart';
import 'package:fonar_app/features/captura/data/microfones_record.dart';
import 'package:fonar_app/features/captura/domain/microfone.dart';
import 'package:fonar_app/features/captura/presentation/microfone_controlador.dart';
import 'package:fonar_app/l10n/app_strings.dart';
import 'package:record/record.dart';

import '../../apoio/banco_em_memoria.dart';

class _Lista implements ListaDeMicrofones {
  _Lista(this.microfones);

  List<Microfone> microfones;

  @override
  Future<List<Microfone>> listar() async => microfones;
}

const _embutido = Microfone(id: 'a', nome: 'Microfone (Realtek Audio)');
const _virtual = Microfone(id: 'b', nome: 'DroidCam Virtual Audio');

void main() {
  group('microfonesParaGravar', () {
    test('Bluetooth fica de fora: chega comprimido, em banda estreita', () {
      final m = microfonesParaGravar(const [
        InputDevice(id: '1', label: 'Microfone', type: InputDeviceType.builtIn),
        InputDevice(id: '2', label: 'Fone', type: InputDeviceType.bluetoothSco),
        InputDevice(
          id: '3',
          label: 'Fone LE',
          type: InputDeviceType.bluetoothLe,
        ),
        InputDevice(
          id: '4',
          label: 'Fone A2DP',
          type: InputDeviceType.bluetoothA2dp,
        ),
      ]);

      expect(m.map((e) => e.id), ['1']);
    });

    test('sem nome, ou com nome repetido, ganha o nome do tipo, numerado', () {
      // No Android, o nome é o modelo do aparelho, igual nos microfones
      // embutidos.
      final m = microfonesParaGravar(const [
        InputDevice(id: '1', label: 'SM-G991B', type: InputDeviceType.builtIn),
        InputDevice(id: '2', label: 'SM-G991B', type: InputDeviceType.builtIn),
        InputDevice(id: '3', label: '', type: InputDeviceType.usb),
        InputDevice(id: '4', label: 'Yeti', type: InputDeviceType.usb),
      ]);

      expect(m.map((e) => e.nome), [
        AppStrings.microfoneEmbutido,
        '${AppStrings.microfoneEmbutido} 2',
        AppStrings.microfoneUsb,
        'Yeti',
      ]);
    });
  });

  group('resolverEscolha', () {
    test('sem escolha guardada, vale o padrão do sistema', () {
      final e = resolverEscolha(
        disponiveis: const [_embutido, _virtual],
        salvo: null,
      );

      expect(e.escolhido, isNull);
      expect(e.ausente, isNull);
      expect(e.temEscolha, isTrue);
    });

    test('a guardada ligada vale, com o nome de agora', () {
      final e = resolverEscolha(
        disponiveis: const [_embutido, _virtual],
        salvo: const Microfone(id: 'a', nome: 'nome antigo'),
      );

      expect(e.escolhido?.nome, _embutido.nome);
      expect(e.ausente, isNull);
    });

    test('a guardada desligada: vale o padrão, e a tela avisa', () {
      final e = resolverEscolha(
        disponiveis: const [_virtual],
        salvo: _embutido,
      );

      expect(e.escolhido, isNull);
      expect(e.ausente, _embutido);
      // Um microfone só, mas o aviso precisa aparecer.
      expect(e.temEscolha, isTrue);
    });

    test('um microfone só: a escolha aparece, para mostrar qual é', () {
      expect(
        resolverEscolha(disponiveis: const [_virtual], salvo: null).temEscolha,
        isTrue,
      );
    });

    test('o sistema não lista nenhum: não há o que mostrar', () {
      expect(
        resolverEscolha(disponiveis: const [], salvo: null).temEscolha,
        isFalse,
      );
    });
  });

  group('microfoneParaCapturar', () {
    late ProviderContainer container;
    late _Lista lista;

    setUp(() {
      lista = _Lista([_embutido, _virtual]);
      container = ProviderContainer(
        overrides: [
          bancoDeTeste(),
          listaDeMicrofonesProvider.overrideWithValue(lista),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<String?> pedir() =>
        microfoneParaCapturar(container.read(_refProvider));

    test(
      'antes de a escolha carregar, é o padrão — sem abrir o banco',
      () async {
        expect(await pedir(), isNull);
        expect(container.exists(bancoLocalProvider), isFalse);
      },
    );

    test('a escolha guardada vai para a captura, e sobrevive ao app '
        'fechar', () async {
      await container.read(microfoneGuardadoProvider.future);
      await container
          .read(microfoneControladorProvider.notifier)
          .escolher(_virtual);

      expect(await pedir(), _virtual.id);

      // Abre de novo, com o mesmo banco.
      final banco = container.read(bancoLocalProvider);
      final outro = ProviderContainer(
        overrides: [
          bancoLocalProvider.overrideWithValue(banco),
          listaDeMicrofonesProvider.overrideWithValue(lista),
        ],
      );
      addTearDown(outro.dispose);
      expect(await outro.read(microfoneGuardadoProvider.future), _virtual);
    });

    test('a escolhida desligada: a captura usa o padrão', () async {
      await container.read(microfoneGuardadoProvider.future);
      await container
          .read(microfoneControladorProvider.notifier)
          .escolher(_virtual);
      lista.microfones = [_embutido];
      container.read(microfoneControladorProvider.notifier).atualizar();

      expect(await pedir(), isNull);
      expect(
        (await container.read(microfoneControladorProvider.future)).ausente,
        _virtual,
      );
    });

    test('voltar ao padrão apaga a escolha', () async {
      await container.read(microfoneGuardadoProvider.future);
      final controlador = container.read(microfoneControladorProvider.notifier);
      await controlador.escolher(_virtual);
      await controlador.escolher(null);

      expect(await pedir(), isNull);
      expect(
        await container.read(preferenciaDeMicrofoneProvider).ler(),
        isNull,
      );
    });
  });
}

/// Um `Ref` do container, para chamar o que recebe um.
final _refProvider = Provider<Ref>((ref) => ref);
