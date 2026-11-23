import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../l10n/app_strings.dart';
import '../../auth/data/profissional_atual.dart';
import '../../auth/domain/profissional.dart';
import '../data/cadastro_api.dart';
import '../domain/cadastro.dart';

/// O arquivo escolhido pelo profissional: o conteúdo e o nome.
typedef ArquivoDoComprovante = ({Uint8List dados, String nome});

/// Quem abre o seletor de arquivos do sistema. Trocável nos testes de tela,
/// onde não há diálogo nativo.
typedef SeletorDeComprovante = Future<ArquivoDoComprovante?> Function();

/// A imagem ou o PDF da carteira profissional, pelo seletor do sistema
/// (`file_selector`, o mesmo do "Salvar como" do laudo). Cancelado, `null`.
Future<ArquivoDoComprovante?> escolherComprovanteNoSistema() async {
  final arquivo = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Imagem ou PDF',
        extensions: ['jpg', 'jpeg', 'png', 'pdf'],
        mimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
        uniformTypeIdentifiers: ['public.jpeg', 'public.png', 'com.adobe.pdf'],
      ),
    ],
  );
  if (arquivo == null) return null;
  return (dados: await arquivo.readAsBytes(), nome: arquivo.name);
}

final seletorDeComprovanteProvider = Provider<SeletorDeComprovante>(
  (ref) => escolherComprovanteNoSistema,
);

class EstadoDoComprovante {
  const EstadoDoComprovante({
    this.enviando = false,
    this.enviado = false,
    this.erro,
  });

  final bool enviando;

  /// O último envio deu certo.
  final bool enviado;

  /// Por que o último envio não deu certo, em texto para a tela.
  final String? erro;
}

/// O envio do comprovante de inscrição (US63, ADR-021 da API): a carteira
/// de identidade profissional emitida pelo conselho, que a equipe confere
/// antes de credenciar.
class ComprovanteControlador extends Notifier<EstadoDoComprovante> {
  @override
  EstadoDoComprovante build() => const EstadoDoComprovante();

  /// Abre o seletor e envia o arquivo escolhido. Devolve `true` se enviou.
  Future<bool> escolherEEnviar() async {
    if (state.enviando) return false;
    final api = ref.read(cadastroApiProvider);
    if (api == null) return false;
    final ArquivoDoComprovante? arquivo;
    try {
      arquivo = await ref.read(seletorDeComprovanteProvider)();
    } catch (erro) {
      debugPrint('Seletor de arquivo indisponível: $erro');
      state = const EstadoDoComprovante(
        erro: AppStrings.comprovanteErroSeletor,
      );
      return false;
    }
    if (arquivo == null) return false;
    if (arquivo.dados.length > tamanhoMaximoDoComprovante) {
      state = const EstadoDoComprovante(
        erro: AppStrings.comprovanteErroTamanho,
      );
      return false;
    }
    state = const EstadoDoComprovante(enviando: true);
    try {
      final perfil = await api.enviarComprovante(arquivo.dados, arquivo.nome);
      if (!ref.mounted) return true;
      final atual = ref.read(profissionalAtualProvider);
      ref
          .read(profissionalAtualProvider.notifier)
          .definir(
            Profissional(
              nome: atual.nome,
              registro: atual.registro,
              email: atual.email,
              credenciamento: perfil.credenciamento,
              comprovanteEnviadoEm: perfil.comprovanteEnviadoEm,
            ),
          );
      state = const EstadoDoComprovante(enviado: true);
      return true;
    } on ComprovanteRecusado catch (recusa) {
      if (ref.mounted) state = EstadoDoComprovante(erro: recusa.mensagem);
    } on AppException catch (falha) {
      if (ref.mounted) state = EstadoDoComprovante(erro: falha.mensagem);
    } catch (_) {
      if (ref.mounted) {
        state = const EstadoDoComprovante(erro: AppStrings.erroDesconhecido);
      }
    }
    return false;
  }
}

/// O limite da API (`TAMANHO_MAXIMO_COMPROVANTE_BYTES`): conferido antes de
/// enviar, para não gastar a rede com o que vai ser recusado.
const tamanhoMaximoDoComprovante = 10 * 1024 * 1024;

final comprovanteControladorProvider =
    NotifierProvider<ComprovanteControlador, EstadoDoComprovante>(
      ComprovanteControlador.new,
    );
