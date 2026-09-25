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

/// O último laudo gerado para cada análise, com o PDF como saiu.
@DataClassName('LinhaDoLaudo')
class Laudos extends Table {
  TextColumn get analiseId => text()();
  TextColumn get pacienteId => text()();
  TextColumn get conclusao => text()();
  DateTimeColumn get geradoEm => dateTime()();
  BlobColumn get pdf => blob()();

  @override
  Set<Column<Object>> get primaryKey => {analiseId};
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
