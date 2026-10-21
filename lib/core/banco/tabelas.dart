/// As tabelas do banco local.
///
/// Só o FORMATO do que se guarda. Enum vai como o nome do valor, em texto —
/// reordenar um enum não pode trocar o sentido do que já está gravado. Quem
/// converte de e para o domínio é o repositório de cada funcionalidade, na
/// camada `data`: assim o `core` não depende de feature nenhuma.
///
/// Mudou alguma tabela? Suba o `schemaVersion` em `banco_local.dart`, escreva
/// a migração e gere o código de novo (ver `build.yaml`).
library;

import 'package:drift/drift.dart';

@DataClassName('LinhaDoPaciente')
class Pacientes extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get queixa => text()();

  /// Nome de `SexoDeReferencia`.
  TextColumn get sexo => text().nullable()();
  DateTimeColumn get dataDeNascimento => dateTime().nullable()();
  DateTimeColumn get cadastradoEm => dateTime()();

  /// A conta (id do Firebase) de quem o paciente é (US40). Só ela o vê
  /// neste aparelho. Nulo nos cadastrados antes da US40: a conta que entrar
  /// primeiro os adota (`adotarPacientesSemDono`).
  TextColumn get profissionalId => text().nullable()();

  /// Quando os dados foram mudados NESTE aparelho (cadastro ou correção).
  /// Mais novo que [sincronizadoEm]: a mudança ainda não subiu, e o que
  /// desce do Firebase não a sobrescreve.
  DateTimeColumn get alteradoEm => dateTime().nullable()();

  /// Quando o aparelho e o Firebase tinham, pela última vez, os mesmos dados
  /// deste paciente — na subida ou na descida.
  DateTimeColumn get sincronizadoEm => dateTime().nullable()();

  /// Quantos registros do livro de consentimentos daqui — concessões e
  /// retiradas, na ordem de `livroDeConsentimentoLocal` — já estão no
  /// Firebase. Menor que o livro: há registro por subir.
  ///
  /// É o que deixa a subida em segundo plano saber, sem perguntar ao
  /// servidor paciente a paciente, de quem há consentimento novo.
  IntColumn get livroNoFirebase => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Um registro por consentimento dado, e nenhum é apagado nem reescrito: cada
/// um continua dizendo com qual versão do termo a pessoa concordou naquele
/// dia. O que vale é o mais recente.
@DataClassName('LinhaDoConsentimento')
class Consentimentos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pacienteId => text()();
  DateTimeColumn get registradoEm => dateTime()();
  TextColumn get versaoDoTermo => text()();

  /// Nome de `QuemAutoriza`.
  TextColumn get quemAutoriza => text()();
  TextColumn get nomeDoResponsavel => text().nullable()();
}

/// A retirada de um consentimento. Também só acumula: o consentimento
/// retirado continua na tabela dele, e as duas linhas juntas contam o que
/// aconteceu.
///
/// Aponta para o consentimento que retira, e não compara horários: um
/// consentimento novo, registrado depois, é outra linha, sem retirada — e
/// volta a valer sem depender do relógio do aparelho.
@DataClassName('LinhaDaRetirada')
class RetiradasDeConsentimento extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pacienteId => text()();

  /// Nulo só na retirada de um consentimento de exemplo, que não está no
  /// banco. Único: o mesmo consentimento não se retira duas vezes.
  IntColumn get consentimentoId =>
      integer().nullable().unique().references(Consentimentos, #id)();
  DateTimeColumn get retiradaEm => dateTime()();

  /// Nome de `QuemAutoriza`: quem pediu a retirada.
  TextColumn get quemPediu => text()();
  TextColumn get nomeDoResponsavel => text().nullable()();
}

/// Uma sessão de gravação na fila de envio.
@DataClassName('LinhaDoEnvio')
class Envios extends Table {
  /// Ordem de chegada: é a ordem em que sobem.
  IntColumn get posicao => integer().autoIncrement()();
  TextColumn get id => text().unique()();
  TextColumn get pacienteId => text()();
  TextColumn get nomeDoPaciente => text()();
  TextColumn get sessaoId => text()();
  DateTimeColumn get criadoEm => dateTime()();

  /// Nome de `SituacaoDoEnvio`.
  TextColumn get situacao => text()();
  IntColumn get tentativas => integer()();
  DateTimeColumn get proximaTentativa => dateTime().nullable()();
  TextColumn get ultimaFalha => text().nullable()();
  TextColumn get analiseId => text().nullable()();

  /// O id da conta (Firebase) de quem gravou. O envio só sobe na sessão
  /// dela. Vazio nos envios de antes da US32, do login de exemplo.
  TextColumn get profissionalId => text().nullable()();
}

/// Cada gravação conferida e guardada. O WAV fica no disco; aqui, onde ele
/// está e o que a conferência achou dele.
@DataClassName('LinhaDaAmostra')
class Amostras extends Table {
  TextColumn get id => text()();
  TextColumn get pacienteId => text()();
  TextColumn get sessaoId => text()();

  /// Nome de `TarefaDeGravacao`.
  TextColumn get tarefa => text()();
  TextColumn get caminho => text()();
  DateTimeColumn get gravadaEm => dateTime()();
  IntColumn get duracaoEmMs => integer()();
  IntColumn get taxaDeAmostragem => integer()();
  IntColumn get canais => integer()();

  /// Nomes de `ProblemaNaAmostra`, separados por vírgula. Vazio: sem
  /// ressalva.
  TextColumn get problemas => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Quais amostras sobem em cada envio, e em que ordem.
///
/// A amostra que já está num envio não pode ser apagada: a chave estrangeira
/// recusa, em vez de deixar o envio sem o arquivo.
@DataClassName('LinhaDaAmostraDoEnvio')
class AmostrasDoEnvio extends Table {
  TextColumn get envioId =>
      text().references(Envios, #id, onDelete: KeyAction.cascade)();
  TextColumn get amostraId => text().references(Amostras, #id)();
  IntColumn get ordem => integer()();

  @override
  Set<Column<Object>> get primaryKey => {envioId, amostraId};
}

/// Uma avaliação CAPE-V por análise; registrar de novo substitui.
@DataClassName('LinhaDaAvaliacaoCapeV')
class AvaliacoesCapeV extends Table {
  TextColumn get analiseId => text()();
  TextColumn get pacienteId => text()();
  DateTimeColumn get registradaEm => dateTime()();
  TextColumn get comentarios => text()();

  @override
  Set<Column<Object>> get primaryKey => {analiseId};
}

/// A marca de cada parâmetro de uma avaliação.
@DataClassName('LinhaDaNotaCapeV')
class NotasCapeV extends Table {
  TextColumn get analiseId => text().references(
    AvaliacoesCapeV,
    #analiseId,
    onDelete: KeyAction.cascade,
  )();

  /// Nome de `ParametroCapeV`.
  TextColumn get parametro => text()();
  IntColumn get valor => integer().nullable()();

  /// Nome de `Consistencia`.
  TextColumn get consistencia => text().nullable()();

  /// Nome de `DirecaoDoDesvio`.
  TextColumn get direcao => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {analiseId, parametro};
}

/// Os laudos EMITIDOS, cada um com o PDF como saiu (US38, ADR-018 da API).
///
/// Uma linha por emissão, e nenhuma é alterada nem apagada pelo app: emitir
/// de novo acrescenta outra, que diz em [substitui] qual veio antes. O
/// vigente de uma análise é o de [geradoEm] mais recente. O único campo que
/// muda depois é [enviadoEm], que não é o documento.
@DataClassName('LinhaDoLaudo')
class Laudos extends Table {
  /// O código do documento (UUID), impresso no PDF.
  TextColumn get id => text()();
  TextColumn get analiseId => text()();
  TextColumn get pacienteId => text()();
  TextColumn get conclusao => text()();
  DateTimeColumn get geradoEm => dateTime()();
  BlobColumn get pdf => blob()();

  /// O código do laudo desta análise que este substitui.
  TextColumn get substitui => text().nullable()();

  /// Quando a cópia chegou à API. Nulo: só neste aparelho, por enquanto.
  DateTimeColumn get enviadoEm => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// As anotações do paciente (US51, ADR-019 da API) — prontuário. Uma linha
/// por VERSÃO, e nenhuma é alterada nem apagada pelo app, a não ser na
/// eliminação do paciente: editar acrescenta outra, que diz em [substitui]
/// qual veio antes. A anotação vigente é a versão que nenhuma outra
/// substitui. O único campo do registro que muda depois é
/// [lembreteVistoEm], uma vez; [sincronizadaEm] não é o registro.
@DataClassName('LinhaDaAnotacao')
class AnotacoesDoPaciente extends Table {
  /// UUID da versão (`novoId`).
  TextColumn get id => text()();
  TextColumn get pacienteId => text()();

  /// A conta que escreveu: só ela a sobe, na árvore dela.
  TextColumn get profissionalId => text()();
  TextColumn get texto => text()();

  /// Quando foi escrita, pelo relógio do aparelho.
  DateTimeColumn get escritaEm => dateTime()();

  /// A versão que esta substitui.
  TextColumn get substitui => text().nullable()();

  /// Lembrar na próxima consulta: num dia posterior ao de [escritaEm].
  BoolColumn get lembrarNaProxima => boolean()();
  DateTimeColumn get lembreteVistoEm => dateTime().nullable()();

  /// Quando o Firebase passou a ter esta versão como está aqui — na subida
  /// ou na descida. Nulo: algo daqui ainda não subiu (a versão, ou o
  /// lembrete visto).
  DateTimeColumn get sincronizadaEm => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Os WAV gravados no navegador (US42), com o caminho que a amostra aponta.
///
/// No aparelho a gravação é um arquivo na área privada do app, e esta tabela
/// fica vazia. No navegador não há pasta de arquivos: o `record` entrega o
/// WAV em memória, e ele mora aqui até subir, com a mesma vida que o arquivo
/// teria — apagado no descarte, na regravação, na retirada do consentimento
/// e na limpeza dos sem registro. [caminho] é o mesmo texto de
/// `Amostra.caminho`, para o resto do app não saber a diferença.
@DataClassName('LinhaDoAudioDoNavegador')
class AudiosDoNavegador extends Table {
  TextColumn get caminho => text()();
  BlobColumn get wav => blob()();
  DateTimeColumn get gravadoEm => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {caminho};
}

/// Preferências deste aparelho, como chave e valor — hoje, só o tema (US30).
///
/// Ficam no aparelho, não na conta: consultório com luz forte e casa à noite
/// pedem escolhas diferentes do mesmo profissional.
@DataClassName('LinhaDePreferencia')
class Preferencias extends Table {
  TextColumn get chave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column<Object>> get primaryKey => {chave};
}
