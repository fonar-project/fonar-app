// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banco_local.dart';

// ignore_for_file: type=lint
class $PacientesTable extends Pacientes
    with TableInfo<$PacientesTable, LinhaDoPaciente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PacientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queixaMeta = const VerificationMeta('queixa');
  @override
  late final GeneratedColumn<String> queixa = GeneratedColumn<String>(
    'queixa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sexoMeta = const VerificationMeta('sexo');
  @override
  late final GeneratedColumn<String> sexo = GeneratedColumn<String>(
    'sexo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataDeNascimentoMeta = const VerificationMeta(
    'dataDeNascimento',
  );
  @override
  late final GeneratedColumn<DateTime> dataDeNascimento =
      GeneratedColumn<DateTime>(
        'data_de_nascimento',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cadastradoEmMeta = const VerificationMeta(
    'cadastradoEm',
  );
  @override
  late final GeneratedColumn<DateTime> cadastradoEm = GeneratedColumn<DateTime>(
    'cadastrado_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    queixa,
    sexo,
    dataDeNascimento,
    cadastradoEm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pacientes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDoPaciente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('queixa')) {
      context.handle(
        _queixaMeta,
        queixa.isAcceptableOrUnknown(data['queixa']!, _queixaMeta),
      );
    } else if (isInserting) {
      context.missing(_queixaMeta);
    }
    if (data.containsKey('sexo')) {
      context.handle(
        _sexoMeta,
        sexo.isAcceptableOrUnknown(data['sexo']!, _sexoMeta),
      );
    }
    if (data.containsKey('data_de_nascimento')) {
      context.handle(
        _dataDeNascimentoMeta,
        dataDeNascimento.isAcceptableOrUnknown(
          data['data_de_nascimento']!,
          _dataDeNascimentoMeta,
        ),
      );
    }
    if (data.containsKey('cadastrado_em')) {
      context.handle(
        _cadastradoEmMeta,
        cadastradoEm.isAcceptableOrUnknown(
          data['cadastrado_em']!,
          _cadastradoEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cadastradoEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaDoPaciente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDoPaciente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      queixa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queixa'],
      )!,
      sexo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sexo'],
      ),
      dataDeNascimento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_de_nascimento'],
      ),
      cadastradoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cadastrado_em'],
      )!,
    );
  }

  @override
  $PacientesTable createAlias(String alias) {
    return $PacientesTable(attachedDatabase, alias);
  }
}

class LinhaDoPaciente extends DataClass implements Insertable<LinhaDoPaciente> {
  final String id;
  final String nome;
  final String queixa;

  /// Nome de `SexoDeReferencia`.
  final String? sexo;
  final DateTime? dataDeNascimento;
  final DateTime cadastradoEm;
  const LinhaDoPaciente({
    required this.id,
    required this.nome,
    required this.queixa,
    this.sexo,
    this.dataDeNascimento,
    required this.cadastradoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    map['queixa'] = Variable<String>(queixa);
    if (!nullToAbsent || sexo != null) {
      map['sexo'] = Variable<String>(sexo);
    }
    if (!nullToAbsent || dataDeNascimento != null) {
      map['data_de_nascimento'] = Variable<DateTime>(dataDeNascimento);
    }
    map['cadastrado_em'] = Variable<DateTime>(cadastradoEm);
    return map;
  }

  PacientesCompanion toCompanion(bool nullToAbsent) {
    return PacientesCompanion(
      id: Value(id),
      nome: Value(nome),
      queixa: Value(queixa),
      sexo: sexo == null && nullToAbsent ? const Value.absent() : Value(sexo),
      dataDeNascimento: dataDeNascimento == null && nullToAbsent
          ? const Value.absent()
          : Value(dataDeNascimento),
      cadastradoEm: Value(cadastradoEm),
    );
  }

  factory LinhaDoPaciente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDoPaciente(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      queixa: serializer.fromJson<String>(json['queixa']),
      sexo: serializer.fromJson<String?>(json['sexo']),
      dataDeNascimento: serializer.fromJson<DateTime?>(
        json['dataDeNascimento'],
      ),
      cadastradoEm: serializer.fromJson<DateTime>(json['cadastradoEm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'queixa': serializer.toJson<String>(queixa),
      'sexo': serializer.toJson<String?>(sexo),
      'dataDeNascimento': serializer.toJson<DateTime?>(dataDeNascimento),
      'cadastradoEm': serializer.toJson<DateTime>(cadastradoEm),
    };
  }

  LinhaDoPaciente copyWith({
    String? id,
    String? nome,
    String? queixa,
    Value<String?> sexo = const Value.absent(),
    Value<DateTime?> dataDeNascimento = const Value.absent(),
    DateTime? cadastradoEm,
  }) => LinhaDoPaciente(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    queixa: queixa ?? this.queixa,
    sexo: sexo.present ? sexo.value : this.sexo,
    dataDeNascimento: dataDeNascimento.present
        ? dataDeNascimento.value
        : this.dataDeNascimento,
    cadastradoEm: cadastradoEm ?? this.cadastradoEm,
  );
  LinhaDoPaciente copyWithCompanion(PacientesCompanion data) {
    return LinhaDoPaciente(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      queixa: data.queixa.present ? data.queixa.value : this.queixa,
      sexo: data.sexo.present ? data.sexo.value : this.sexo,
      dataDeNascimento: data.dataDeNascimento.present
          ? data.dataDeNascimento.value
          : this.dataDeNascimento,
      cadastradoEm: data.cadastradoEm.present
          ? data.cadastradoEm.value
          : this.cadastradoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDoPaciente(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('queixa: $queixa, ')
          ..write('sexo: $sexo, ')
          ..write('dataDeNascimento: $dataDeNascimento, ')
          ..write('cadastradoEm: $cadastradoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nome, queixa, sexo, dataDeNascimento, cadastradoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDoPaciente &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.queixa == this.queixa &&
          other.sexo == this.sexo &&
          other.dataDeNascimento == this.dataDeNascimento &&
          other.cadastradoEm == this.cadastradoEm);
}

class PacientesCompanion extends UpdateCompanion<LinhaDoPaciente> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String> queixa;
  final Value<String?> sexo;
  final Value<DateTime?> dataDeNascimento;
  final Value<DateTime> cadastradoEm;
  final Value<int> rowid;
  const PacientesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.queixa = const Value.absent(),
    this.sexo = const Value.absent(),
    this.dataDeNascimento = const Value.absent(),
    this.cadastradoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PacientesCompanion.insert({
    required String id,
    required String nome,
    required String queixa,
    this.sexo = const Value.absent(),
    this.dataDeNascimento = const Value.absent(),
    required DateTime cadastradoEm,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       queixa = Value(queixa),
       cadastradoEm = Value(cadastradoEm);
  static Insertable<LinhaDoPaciente> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? queixa,
    Expression<String>? sexo,
    Expression<DateTime>? dataDeNascimento,
    Expression<DateTime>? cadastradoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (queixa != null) 'queixa': queixa,
      if (sexo != null) 'sexo': sexo,
      if (dataDeNascimento != null) 'data_de_nascimento': dataDeNascimento,
      if (cadastradoEm != null) 'cadastrado_em': cadastradoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PacientesCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String>? queixa,
    Value<String?>? sexo,
    Value<DateTime?>? dataDeNascimento,
    Value<DateTime>? cadastradoEm,
    Value<int>? rowid,
  }) {
    return PacientesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      queixa: queixa ?? this.queixa,
      sexo: sexo ?? this.sexo,
      dataDeNascimento: dataDeNascimento ?? this.dataDeNascimento,
      cadastradoEm: cadastradoEm ?? this.cadastradoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (queixa.present) {
      map['queixa'] = Variable<String>(queixa.value);
    }
    if (sexo.present) {
      map['sexo'] = Variable<String>(sexo.value);
    }
    if (dataDeNascimento.present) {
      map['data_de_nascimento'] = Variable<DateTime>(dataDeNascimento.value);
    }
    if (cadastradoEm.present) {
      map['cadastrado_em'] = Variable<DateTime>(cadastradoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PacientesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('queixa: $queixa, ')
          ..write('sexo: $sexo, ')
          ..write('dataDeNascimento: $dataDeNascimento, ')
          ..write('cadastradoEm: $cadastradoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentimentosTable extends Consentimentos
    with TableInfo<$ConsentimentosTable, LinhaDoConsentimento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentimentosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pacienteIdMeta = const VerificationMeta(
    'pacienteId',
  );
  @override
  late final GeneratedColumn<String> pacienteId = GeneratedColumn<String>(
    'paciente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registradoEmMeta = const VerificationMeta(
    'registradoEm',
  );
  @override
  late final GeneratedColumn<DateTime> registradoEm = GeneratedColumn<DateTime>(
    'registrado_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versaoDoTermoMeta = const VerificationMeta(
    'versaoDoTermo',
  );
  @override
  late final GeneratedColumn<String> versaoDoTermo = GeneratedColumn<String>(
    'versao_do_termo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quemAutorizaMeta = const VerificationMeta(
    'quemAutoriza',
  );
  @override
  late final GeneratedColumn<String> quemAutoriza = GeneratedColumn<String>(
    'quem_autoriza',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeDoResponsavelMeta = const VerificationMeta(
    'nomeDoResponsavel',
  );
  @override
  late final GeneratedColumn<String> nomeDoResponsavel =
      GeneratedColumn<String>(
        'nome_do_responsavel',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pacienteId,
    registradoEm,
    versaoDoTermo,
    quemAutoriza,
    nomeDoResponsavel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consentimentos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDoConsentimento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('paciente_id')) {
      context.handle(
        _pacienteIdMeta,
        pacienteId.isAcceptableOrUnknown(data['paciente_id']!, _pacienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pacienteIdMeta);
    }
    if (data.containsKey('registrado_em')) {
      context.handle(
        _registradoEmMeta,
        registradoEm.isAcceptableOrUnknown(
          data['registrado_em']!,
          _registradoEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registradoEmMeta);
    }
    if (data.containsKey('versao_do_termo')) {
      context.handle(
        _versaoDoTermoMeta,
        versaoDoTermo.isAcceptableOrUnknown(
          data['versao_do_termo']!,
          _versaoDoTermoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versaoDoTermoMeta);
    }
    if (data.containsKey('quem_autoriza')) {
      context.handle(
        _quemAutorizaMeta,
        quemAutoriza.isAcceptableOrUnknown(
          data['quem_autoriza']!,
          _quemAutorizaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quemAutorizaMeta);
    }
    if (data.containsKey('nome_do_responsavel')) {
      context.handle(
        _nomeDoResponsavelMeta,
        nomeDoResponsavel.isAcceptableOrUnknown(
          data['nome_do_responsavel']!,
          _nomeDoResponsavelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaDoConsentimento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDoConsentimento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pacienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paciente_id'],
      )!,
      registradoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}registrado_em'],
      )!,
      versaoDoTermo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}versao_do_termo'],
      )!,
      quemAutoriza: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quem_autoriza'],
      )!,
      nomeDoResponsavel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_do_responsavel'],
      ),
    );
  }

  @override
  $ConsentimentosTable createAlias(String alias) {
    return $ConsentimentosTable(attachedDatabase, alias);
  }
}

class LinhaDoConsentimento extends DataClass
    implements Insertable<LinhaDoConsentimento> {
  final int id;
  final String pacienteId;
  final DateTime registradoEm;
  final String versaoDoTermo;

  /// Nome de `QuemAutoriza`.
  final String quemAutoriza;
  final String? nomeDoResponsavel;
  const LinhaDoConsentimento({
    required this.id,
    required this.pacienteId,
    required this.registradoEm,
    required this.versaoDoTermo,
    required this.quemAutoriza,
    this.nomeDoResponsavel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['paciente_id'] = Variable<String>(pacienteId);
    map['registrado_em'] = Variable<DateTime>(registradoEm);
    map['versao_do_termo'] = Variable<String>(versaoDoTermo);
    map['quem_autoriza'] = Variable<String>(quemAutoriza);
    if (!nullToAbsent || nomeDoResponsavel != null) {
      map['nome_do_responsavel'] = Variable<String>(nomeDoResponsavel);
    }
    return map;
  }

  ConsentimentosCompanion toCompanion(bool nullToAbsent) {
    return ConsentimentosCompanion(
      id: Value(id),
      pacienteId: Value(pacienteId),
      registradoEm: Value(registradoEm),
      versaoDoTermo: Value(versaoDoTermo),
      quemAutoriza: Value(quemAutoriza),
      nomeDoResponsavel: nomeDoResponsavel == null && nullToAbsent
          ? const Value.absent()
          : Value(nomeDoResponsavel),
    );
  }

  factory LinhaDoConsentimento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDoConsentimento(
      id: serializer.fromJson<int>(json['id']),
      pacienteId: serializer.fromJson<String>(json['pacienteId']),
      registradoEm: serializer.fromJson<DateTime>(json['registradoEm']),
      versaoDoTermo: serializer.fromJson<String>(json['versaoDoTermo']),
      quemAutoriza: serializer.fromJson<String>(json['quemAutoriza']),
      nomeDoResponsavel: serializer.fromJson<String?>(
        json['nomeDoResponsavel'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pacienteId': serializer.toJson<String>(pacienteId),
      'registradoEm': serializer.toJson<DateTime>(registradoEm),
      'versaoDoTermo': serializer.toJson<String>(versaoDoTermo),
      'quemAutoriza': serializer.toJson<String>(quemAutoriza),
      'nomeDoResponsavel': serializer.toJson<String?>(nomeDoResponsavel),
    };
  }

  LinhaDoConsentimento copyWith({
    int? id,
    String? pacienteId,
    DateTime? registradoEm,
    String? versaoDoTermo,
    String? quemAutoriza,
    Value<String?> nomeDoResponsavel = const Value.absent(),
  }) => LinhaDoConsentimento(
    id: id ?? this.id,
    pacienteId: pacienteId ?? this.pacienteId,
    registradoEm: registradoEm ?? this.registradoEm,
    versaoDoTermo: versaoDoTermo ?? this.versaoDoTermo,
    quemAutoriza: quemAutoriza ?? this.quemAutoriza,
    nomeDoResponsavel: nomeDoResponsavel.present
        ? nomeDoResponsavel.value
        : this.nomeDoResponsavel,
  );
  LinhaDoConsentimento copyWithCompanion(ConsentimentosCompanion data) {
    return LinhaDoConsentimento(
      id: data.id.present ? data.id.value : this.id,
      pacienteId: data.pacienteId.present
          ? data.pacienteId.value
          : this.pacienteId,
      registradoEm: data.registradoEm.present
          ? data.registradoEm.value
          : this.registradoEm,
      versaoDoTermo: data.versaoDoTermo.present
          ? data.versaoDoTermo.value
          : this.versaoDoTermo,
      quemAutoriza: data.quemAutoriza.present
          ? data.quemAutoriza.value
          : this.quemAutoriza,
      nomeDoResponsavel: data.nomeDoResponsavel.present
          ? data.nomeDoResponsavel.value
          : this.nomeDoResponsavel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDoConsentimento(')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('registradoEm: $registradoEm, ')
          ..write('versaoDoTermo: $versaoDoTermo, ')
          ..write('quemAutoriza: $quemAutoriza, ')
          ..write('nomeDoResponsavel: $nomeDoResponsavel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pacienteId,
    registradoEm,
    versaoDoTermo,
    quemAutoriza,
    nomeDoResponsavel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDoConsentimento &&
          other.id == this.id &&
          other.pacienteId == this.pacienteId &&
          other.registradoEm == this.registradoEm &&
          other.versaoDoTermo == this.versaoDoTermo &&
          other.quemAutoriza == this.quemAutoriza &&
          other.nomeDoResponsavel == this.nomeDoResponsavel);
}

class ConsentimentosCompanion extends UpdateCompanion<LinhaDoConsentimento> {
  final Value<int> id;
  final Value<String> pacienteId;
  final Value<DateTime> registradoEm;
  final Value<String> versaoDoTermo;
  final Value<String> quemAutoriza;
  final Value<String?> nomeDoResponsavel;
  const ConsentimentosCompanion({
    this.id = const Value.absent(),
    this.pacienteId = const Value.absent(),
    this.registradoEm = const Value.absent(),
    this.versaoDoTermo = const Value.absent(),
    this.quemAutoriza = const Value.absent(),
    this.nomeDoResponsavel = const Value.absent(),
  });
  ConsentimentosCompanion.insert({
    this.id = const Value.absent(),
    required String pacienteId,
    required DateTime registradoEm,
    required String versaoDoTermo,
    required String quemAutoriza,
    this.nomeDoResponsavel = const Value.absent(),
  }) : pacienteId = Value(pacienteId),
       registradoEm = Value(registradoEm),
       versaoDoTermo = Value(versaoDoTermo),
       quemAutoriza = Value(quemAutoriza);
  static Insertable<LinhaDoConsentimento> custom({
    Expression<int>? id,
    Expression<String>? pacienteId,
    Expression<DateTime>? registradoEm,
    Expression<String>? versaoDoTermo,
    Expression<String>? quemAutoriza,
    Expression<String>? nomeDoResponsavel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pacienteId != null) 'paciente_id': pacienteId,
      if (registradoEm != null) 'registrado_em': registradoEm,
      if (versaoDoTermo != null) 'versao_do_termo': versaoDoTermo,
      if (quemAutoriza != null) 'quem_autoriza': quemAutoriza,
      if (nomeDoResponsavel != null) 'nome_do_responsavel': nomeDoResponsavel,
    });
  }

  ConsentimentosCompanion copyWith({
    Value<int>? id,
    Value<String>? pacienteId,
    Value<DateTime>? registradoEm,
    Value<String>? versaoDoTermo,
    Value<String>? quemAutoriza,
    Value<String?>? nomeDoResponsavel,
  }) {
    return ConsentimentosCompanion(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      registradoEm: registradoEm ?? this.registradoEm,
      versaoDoTermo: versaoDoTermo ?? this.versaoDoTermo,
      quemAutoriza: quemAutoriza ?? this.quemAutoriza,
      nomeDoResponsavel: nomeDoResponsavel ?? this.nomeDoResponsavel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pacienteId.present) {
      map['paciente_id'] = Variable<String>(pacienteId.value);
    }
    if (registradoEm.present) {
      map['registrado_em'] = Variable<DateTime>(registradoEm.value);
    }
    if (versaoDoTermo.present) {
      map['versao_do_termo'] = Variable<String>(versaoDoTermo.value);
    }
    if (quemAutoriza.present) {
      map['quem_autoriza'] = Variable<String>(quemAutoriza.value);
    }
    if (nomeDoResponsavel.present) {
      map['nome_do_responsavel'] = Variable<String>(nomeDoResponsavel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentimentosCompanion(')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('registradoEm: $registradoEm, ')
          ..write('versaoDoTermo: $versaoDoTermo, ')
          ..write('quemAutoriza: $quemAutoriza, ')
          ..write('nomeDoResponsavel: $nomeDoResponsavel')
          ..write(')'))
        .toString();
  }
}

class $RetiradasDeConsentimentoTable extends RetiradasDeConsentimento
    with TableInfo<$RetiradasDeConsentimentoTable, LinhaDaRetirada> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RetiradasDeConsentimentoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pacienteIdMeta = const VerificationMeta(
    'pacienteId',
  );
  @override
  late final GeneratedColumn<String> pacienteId = GeneratedColumn<String>(
    'paciente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consentimentoIdMeta = const VerificationMeta(
    'consentimentoId',
  );
  @override
  late final GeneratedColumn<int> consentimentoId = GeneratedColumn<int>(
    'consentimento_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES consentimentos (id)',
    ),
  );
  static const VerificationMeta _retiradaEmMeta = const VerificationMeta(
    'retiradaEm',
  );
  @override
  late final GeneratedColumn<DateTime> retiradaEm = GeneratedColumn<DateTime>(
    'retirada_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quemPediuMeta = const VerificationMeta(
    'quemPediu',
  );
  @override
  late final GeneratedColumn<String> quemPediu = GeneratedColumn<String>(
    'quem_pediu',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeDoResponsavelMeta = const VerificationMeta(
    'nomeDoResponsavel',
  );
  @override
  late final GeneratedColumn<String> nomeDoResponsavel =
      GeneratedColumn<String>(
        'nome_do_responsavel',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pacienteId,
    consentimentoId,
    retiradaEm,
    quemPediu,
    nomeDoResponsavel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'retiradas_de_consentimento';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDaRetirada> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('paciente_id')) {
      context.handle(
        _pacienteIdMeta,
        pacienteId.isAcceptableOrUnknown(data['paciente_id']!, _pacienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pacienteIdMeta);
    }
    if (data.containsKey('consentimento_id')) {
      context.handle(
        _consentimentoIdMeta,
        consentimentoId.isAcceptableOrUnknown(
          data['consentimento_id']!,
          _consentimentoIdMeta,
        ),
      );
    }
    if (data.containsKey('retirada_em')) {
      context.handle(
        _retiradaEmMeta,
        retiradaEm.isAcceptableOrUnknown(data['retirada_em']!, _retiradaEmMeta),
      );
    } else if (isInserting) {
      context.missing(_retiradaEmMeta);
    }
    if (data.containsKey('quem_pediu')) {
      context.handle(
        _quemPediuMeta,
        quemPediu.isAcceptableOrUnknown(data['quem_pediu']!, _quemPediuMeta),
      );
    } else if (isInserting) {
      context.missing(_quemPediuMeta);
    }
    if (data.containsKey('nome_do_responsavel')) {
      context.handle(
        _nomeDoResponsavelMeta,
        nomeDoResponsavel.isAcceptableOrUnknown(
          data['nome_do_responsavel']!,
          _nomeDoResponsavelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaDaRetirada map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDaRetirada(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pacienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paciente_id'],
      )!,
      consentimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consentimento_id'],
      ),
      retiradaEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retirada_em'],
      )!,
      quemPediu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quem_pediu'],
      )!,
      nomeDoResponsavel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_do_responsavel'],
      ),
    );
  }

  @override
  $RetiradasDeConsentimentoTable createAlias(String alias) {
    return $RetiradasDeConsentimentoTable(attachedDatabase, alias);
  }
}

class LinhaDaRetirada extends DataClass implements Insertable<LinhaDaRetirada> {
  final int id;
  final String pacienteId;

  /// Nulo só na retirada de um consentimento de exemplo, que não está no
  /// banco. Único: o mesmo consentimento não se retira duas vezes.
  final int? consentimentoId;
  final DateTime retiradaEm;

  /// Nome de `QuemAutoriza`: quem pediu a retirada.
  final String quemPediu;
  final String? nomeDoResponsavel;
  const LinhaDaRetirada({
    required this.id,
    required this.pacienteId,
    this.consentimentoId,
    required this.retiradaEm,
    required this.quemPediu,
    this.nomeDoResponsavel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['paciente_id'] = Variable<String>(pacienteId);
    if (!nullToAbsent || consentimentoId != null) {
      map['consentimento_id'] = Variable<int>(consentimentoId);
    }
    map['retirada_em'] = Variable<DateTime>(retiradaEm);
    map['quem_pediu'] = Variable<String>(quemPediu);
    if (!nullToAbsent || nomeDoResponsavel != null) {
      map['nome_do_responsavel'] = Variable<String>(nomeDoResponsavel);
    }
    return map;
  }

  RetiradasDeConsentimentoCompanion toCompanion(bool nullToAbsent) {
    return RetiradasDeConsentimentoCompanion(
      id: Value(id),
      pacienteId: Value(pacienteId),
      consentimentoId: consentimentoId == null && nullToAbsent
          ? const Value.absent()
          : Value(consentimentoId),
      retiradaEm: Value(retiradaEm),
      quemPediu: Value(quemPediu),
      nomeDoResponsavel: nomeDoResponsavel == null && nullToAbsent
          ? const Value.absent()
          : Value(nomeDoResponsavel),
    );
  }

  factory LinhaDaRetirada.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDaRetirada(
      id: serializer.fromJson<int>(json['id']),
      pacienteId: serializer.fromJson<String>(json['pacienteId']),
      consentimentoId: serializer.fromJson<int?>(json['consentimentoId']),
      retiradaEm: serializer.fromJson<DateTime>(json['retiradaEm']),
      quemPediu: serializer.fromJson<String>(json['quemPediu']),
      nomeDoResponsavel: serializer.fromJson<String?>(
        json['nomeDoResponsavel'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pacienteId': serializer.toJson<String>(pacienteId),
      'consentimentoId': serializer.toJson<int?>(consentimentoId),
      'retiradaEm': serializer.toJson<DateTime>(retiradaEm),
      'quemPediu': serializer.toJson<String>(quemPediu),
      'nomeDoResponsavel': serializer.toJson<String?>(nomeDoResponsavel),
    };
  }

  LinhaDaRetirada copyWith({
    int? id,
    String? pacienteId,
    Value<int?> consentimentoId = const Value.absent(),
    DateTime? retiradaEm,
    String? quemPediu,
    Value<String?> nomeDoResponsavel = const Value.absent(),
  }) => LinhaDaRetirada(
    id: id ?? this.id,
    pacienteId: pacienteId ?? this.pacienteId,
    consentimentoId: consentimentoId.present
        ? consentimentoId.value
        : this.consentimentoId,
    retiradaEm: retiradaEm ?? this.retiradaEm,
    quemPediu: quemPediu ?? this.quemPediu,
    nomeDoResponsavel: nomeDoResponsavel.present
        ? nomeDoResponsavel.value
        : this.nomeDoResponsavel,
  );
  LinhaDaRetirada copyWithCompanion(RetiradasDeConsentimentoCompanion data) {
    return LinhaDaRetirada(
      id: data.id.present ? data.id.value : this.id,
      pacienteId: data.pacienteId.present
          ? data.pacienteId.value
          : this.pacienteId,
      consentimentoId: data.consentimentoId.present
          ? data.consentimentoId.value
          : this.consentimentoId,
      retiradaEm: data.retiradaEm.present
          ? data.retiradaEm.value
          : this.retiradaEm,
      quemPediu: data.quemPediu.present ? data.quemPediu.value : this.quemPediu,
      nomeDoResponsavel: data.nomeDoResponsavel.present
          ? data.nomeDoResponsavel.value
          : this.nomeDoResponsavel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDaRetirada(')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('consentimentoId: $consentimentoId, ')
          ..write('retiradaEm: $retiradaEm, ')
          ..write('quemPediu: $quemPediu, ')
          ..write('nomeDoResponsavel: $nomeDoResponsavel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pacienteId,
    consentimentoId,
    retiradaEm,
    quemPediu,
    nomeDoResponsavel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDaRetirada &&
          other.id == this.id &&
          other.pacienteId == this.pacienteId &&
          other.consentimentoId == this.consentimentoId &&
          other.retiradaEm == this.retiradaEm &&
          other.quemPediu == this.quemPediu &&
          other.nomeDoResponsavel == this.nomeDoResponsavel);
}

class RetiradasDeConsentimentoCompanion
    extends UpdateCompanion<LinhaDaRetirada> {
  final Value<int> id;
  final Value<String> pacienteId;
  final Value<int?> consentimentoId;
  final Value<DateTime> retiradaEm;
  final Value<String> quemPediu;
  final Value<String?> nomeDoResponsavel;
  const RetiradasDeConsentimentoCompanion({
    this.id = const Value.absent(),
    this.pacienteId = const Value.absent(),
    this.consentimentoId = const Value.absent(),
    this.retiradaEm = const Value.absent(),
    this.quemPediu = const Value.absent(),
    this.nomeDoResponsavel = const Value.absent(),
  });
  RetiradasDeConsentimentoCompanion.insert({
    this.id = const Value.absent(),
    required String pacienteId,
    this.consentimentoId = const Value.absent(),
    required DateTime retiradaEm,
    required String quemPediu,
    this.nomeDoResponsavel = const Value.absent(),
  }) : pacienteId = Value(pacienteId),
       retiradaEm = Value(retiradaEm),
       quemPediu = Value(quemPediu);
  static Insertable<LinhaDaRetirada> custom({
    Expression<int>? id,
    Expression<String>? pacienteId,
    Expression<int>? consentimentoId,
    Expression<DateTime>? retiradaEm,
    Expression<String>? quemPediu,
    Expression<String>? nomeDoResponsavel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pacienteId != null) 'paciente_id': pacienteId,
      if (consentimentoId != null) 'consentimento_id': consentimentoId,
      if (retiradaEm != null) 'retirada_em': retiradaEm,
      if (quemPediu != null) 'quem_pediu': quemPediu,
      if (nomeDoResponsavel != null) 'nome_do_responsavel': nomeDoResponsavel,
    });
  }

  RetiradasDeConsentimentoCompanion copyWith({
    Value<int>? id,
    Value<String>? pacienteId,
    Value<int?>? consentimentoId,
    Value<DateTime>? retiradaEm,
    Value<String>? quemPediu,
    Value<String?>? nomeDoResponsavel,
  }) {
    return RetiradasDeConsentimentoCompanion(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      consentimentoId: consentimentoId ?? this.consentimentoId,
      retiradaEm: retiradaEm ?? this.retiradaEm,
      quemPediu: quemPediu ?? this.quemPediu,
      nomeDoResponsavel: nomeDoResponsavel ?? this.nomeDoResponsavel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pacienteId.present) {
      map['paciente_id'] = Variable<String>(pacienteId.value);
    }
    if (consentimentoId.present) {
      map['consentimento_id'] = Variable<int>(consentimentoId.value);
    }
    if (retiradaEm.present) {
      map['retirada_em'] = Variable<DateTime>(retiradaEm.value);
    }
    if (quemPediu.present) {
      map['quem_pediu'] = Variable<String>(quemPediu.value);
    }
    if (nomeDoResponsavel.present) {
      map['nome_do_responsavel'] = Variable<String>(nomeDoResponsavel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RetiradasDeConsentimentoCompanion(')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('consentimentoId: $consentimentoId, ')
          ..write('retiradaEm: $retiradaEm, ')
          ..write('quemPediu: $quemPediu, ')
          ..write('nomeDoResponsavel: $nomeDoResponsavel')
          ..write(')'))
        .toString();
  }
}

class $EnviosTable extends Envios with TableInfo<$EnviosTable, LinhaDoEnvio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnviosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _posicaoMeta = const VerificationMeta(
    'posicao',
  );
  @override
  late final GeneratedColumn<int> posicao = GeneratedColumn<int>(
    'posicao',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _pacienteIdMeta = const VerificationMeta(
    'pacienteId',
  );
  @override
  late final GeneratedColumn<String> pacienteId = GeneratedColumn<String>(
    'paciente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeDoPacienteMeta = const VerificationMeta(
    'nomeDoPaciente',
  );
  @override
  late final GeneratedColumn<String> nomeDoPaciente = GeneratedColumn<String>(
    'nome_do_paciente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessaoIdMeta = const VerificationMeta(
    'sessaoId',
  );
  @override
  late final GeneratedColumn<String> sessaoId = GeneratedColumn<String>(
    'sessao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  @override
  late final GeneratedColumn<DateTime> criadoEm = GeneratedColumn<DateTime>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _situacaoMeta = const VerificationMeta(
    'situacao',
  );
  @override
  late final GeneratedColumn<String> situacao = GeneratedColumn<String>(
    'situacao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tentativasMeta = const VerificationMeta(
    'tentativas',
  );
  @override
  late final GeneratedColumn<int> tentativas = GeneratedColumn<int>(
    'tentativas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proximaTentativaMeta = const VerificationMeta(
    'proximaTentativa',
  );
  @override
  late final GeneratedColumn<DateTime> proximaTentativa =
      GeneratedColumn<DateTime>(
        'proxima_tentativa',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ultimaFalhaMeta = const VerificationMeta(
    'ultimaFalha',
  );
  @override
  late final GeneratedColumn<String> ultimaFalha = GeneratedColumn<String>(
    'ultima_falha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _analiseIdMeta = const VerificationMeta(
    'analiseId',
  );
  @override
  late final GeneratedColumn<String> analiseId = GeneratedColumn<String>(
    'analise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    posicao,
    id,
    pacienteId,
    nomeDoPaciente,
    sessaoId,
    criadoEm,
    situacao,
    tentativas,
    proximaTentativa,
    ultimaFalha,
    analiseId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'envios';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDoEnvio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('posicao')) {
      context.handle(
        _posicaoMeta,
        posicao.isAcceptableOrUnknown(data['posicao']!, _posicaoMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('paciente_id')) {
      context.handle(
        _pacienteIdMeta,
        pacienteId.isAcceptableOrUnknown(data['paciente_id']!, _pacienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pacienteIdMeta);
    }
    if (data.containsKey('nome_do_paciente')) {
      context.handle(
        _nomeDoPacienteMeta,
        nomeDoPaciente.isAcceptableOrUnknown(
          data['nome_do_paciente']!,
          _nomeDoPacienteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nomeDoPacienteMeta);
    }
    if (data.containsKey('sessao_id')) {
      context.handle(
        _sessaoIdMeta,
        sessaoId.isAcceptableOrUnknown(data['sessao_id']!, _sessaoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessaoIdMeta);
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    if (data.containsKey('situacao')) {
      context.handle(
        _situacaoMeta,
        situacao.isAcceptableOrUnknown(data['situacao']!, _situacaoMeta),
      );
    } else if (isInserting) {
      context.missing(_situacaoMeta);
    }
    if (data.containsKey('tentativas')) {
      context.handle(
        _tentativasMeta,
        tentativas.isAcceptableOrUnknown(data['tentativas']!, _tentativasMeta),
      );
    } else if (isInserting) {
      context.missing(_tentativasMeta);
    }
    if (data.containsKey('proxima_tentativa')) {
      context.handle(
        _proximaTentativaMeta,
        proximaTentativa.isAcceptableOrUnknown(
          data['proxima_tentativa']!,
          _proximaTentativaMeta,
        ),
      );
    }
    if (data.containsKey('ultima_falha')) {
      context.handle(
        _ultimaFalhaMeta,
        ultimaFalha.isAcceptableOrUnknown(
          data['ultima_falha']!,
          _ultimaFalhaMeta,
        ),
      );
    }
    if (data.containsKey('analise_id')) {
      context.handle(
        _analiseIdMeta,
        analiseId.isAcceptableOrUnknown(data['analise_id']!, _analiseIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {posicao};
  @override
  LinhaDoEnvio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDoEnvio(
      posicao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posicao'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pacienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paciente_id'],
      )!,
      nomeDoPaciente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_do_paciente'],
      )!,
      sessaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sessao_id'],
      )!,
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}criado_em'],
      )!,
      situacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}situacao'],
      )!,
      tentativas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tentativas'],
      )!,
      proximaTentativa: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}proxima_tentativa'],
      ),
      ultimaFalha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultima_falha'],
      ),
      analiseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analise_id'],
      ),
    );
  }

  @override
  $EnviosTable createAlias(String alias) {
    return $EnviosTable(attachedDatabase, alias);
  }
}

class LinhaDoEnvio extends DataClass implements Insertable<LinhaDoEnvio> {
  /// Ordem de chegada: é a ordem em que sobem.
  final int posicao;
  final String id;
  final String pacienteId;
  final String nomeDoPaciente;
  final String sessaoId;
  final DateTime criadoEm;

  /// Nome de `SituacaoDoEnvio`.
  final String situacao;
  final int tentativas;
  final DateTime? proximaTentativa;
  final String? ultimaFalha;
  final String? analiseId;
  const LinhaDoEnvio({
    required this.posicao,
    required this.id,
    required this.pacienteId,
    required this.nomeDoPaciente,
    required this.sessaoId,
    required this.criadoEm,
    required this.situacao,
    required this.tentativas,
    this.proximaTentativa,
    this.ultimaFalha,
    this.analiseId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['posicao'] = Variable<int>(posicao);
    map['id'] = Variable<String>(id);
    map['paciente_id'] = Variable<String>(pacienteId);
    map['nome_do_paciente'] = Variable<String>(nomeDoPaciente);
    map['sessao_id'] = Variable<String>(sessaoId);
    map['criado_em'] = Variable<DateTime>(criadoEm);
    map['situacao'] = Variable<String>(situacao);
    map['tentativas'] = Variable<int>(tentativas);
    if (!nullToAbsent || proximaTentativa != null) {
      map['proxima_tentativa'] = Variable<DateTime>(proximaTentativa);
    }
    if (!nullToAbsent || ultimaFalha != null) {
      map['ultima_falha'] = Variable<String>(ultimaFalha);
    }
    if (!nullToAbsent || analiseId != null) {
      map['analise_id'] = Variable<String>(analiseId);
    }
    return map;
  }

  EnviosCompanion toCompanion(bool nullToAbsent) {
    return EnviosCompanion(
      posicao: Value(posicao),
      id: Value(id),
      pacienteId: Value(pacienteId),
      nomeDoPaciente: Value(nomeDoPaciente),
      sessaoId: Value(sessaoId),
      criadoEm: Value(criadoEm),
      situacao: Value(situacao),
      tentativas: Value(tentativas),
      proximaTentativa: proximaTentativa == null && nullToAbsent
          ? const Value.absent()
          : Value(proximaTentativa),
      ultimaFalha: ultimaFalha == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaFalha),
      analiseId: analiseId == null && nullToAbsent
          ? const Value.absent()
          : Value(analiseId),
    );
  }

  factory LinhaDoEnvio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDoEnvio(
      posicao: serializer.fromJson<int>(json['posicao']),
      id: serializer.fromJson<String>(json['id']),
      pacienteId: serializer.fromJson<String>(json['pacienteId']),
      nomeDoPaciente: serializer.fromJson<String>(json['nomeDoPaciente']),
      sessaoId: serializer.fromJson<String>(json['sessaoId']),
      criadoEm: serializer.fromJson<DateTime>(json['criadoEm']),
      situacao: serializer.fromJson<String>(json['situacao']),
      tentativas: serializer.fromJson<int>(json['tentativas']),
      proximaTentativa: serializer.fromJson<DateTime?>(
        json['proximaTentativa'],
      ),
      ultimaFalha: serializer.fromJson<String?>(json['ultimaFalha']),
      analiseId: serializer.fromJson<String?>(json['analiseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'posicao': serializer.toJson<int>(posicao),
      'id': serializer.toJson<String>(id),
      'pacienteId': serializer.toJson<String>(pacienteId),
      'nomeDoPaciente': serializer.toJson<String>(nomeDoPaciente),
      'sessaoId': serializer.toJson<String>(sessaoId),
      'criadoEm': serializer.toJson<DateTime>(criadoEm),
      'situacao': serializer.toJson<String>(situacao),
      'tentativas': serializer.toJson<int>(tentativas),
      'proximaTentativa': serializer.toJson<DateTime?>(proximaTentativa),
      'ultimaFalha': serializer.toJson<String?>(ultimaFalha),
      'analiseId': serializer.toJson<String?>(analiseId),
    };
  }

  LinhaDoEnvio copyWith({
    int? posicao,
    String? id,
    String? pacienteId,
    String? nomeDoPaciente,
    String? sessaoId,
    DateTime? criadoEm,
    String? situacao,
    int? tentativas,
    Value<DateTime?> proximaTentativa = const Value.absent(),
    Value<String?> ultimaFalha = const Value.absent(),
    Value<String?> analiseId = const Value.absent(),
  }) => LinhaDoEnvio(
    posicao: posicao ?? this.posicao,
    id: id ?? this.id,
    pacienteId: pacienteId ?? this.pacienteId,
    nomeDoPaciente: nomeDoPaciente ?? this.nomeDoPaciente,
    sessaoId: sessaoId ?? this.sessaoId,
    criadoEm: criadoEm ?? this.criadoEm,
    situacao: situacao ?? this.situacao,
    tentativas: tentativas ?? this.tentativas,
    proximaTentativa: proximaTentativa.present
        ? proximaTentativa.value
        : this.proximaTentativa,
    ultimaFalha: ultimaFalha.present ? ultimaFalha.value : this.ultimaFalha,
    analiseId: analiseId.present ? analiseId.value : this.analiseId,
  );
  LinhaDoEnvio copyWithCompanion(EnviosCompanion data) {
    return LinhaDoEnvio(
      posicao: data.posicao.present ? data.posicao.value : this.posicao,
      id: data.id.present ? data.id.value : this.id,
      pacienteId: data.pacienteId.present
          ? data.pacienteId.value
          : this.pacienteId,
      nomeDoPaciente: data.nomeDoPaciente.present
          ? data.nomeDoPaciente.value
          : this.nomeDoPaciente,
      sessaoId: data.sessaoId.present ? data.sessaoId.value : this.sessaoId,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
      situacao: data.situacao.present ? data.situacao.value : this.situacao,
      tentativas: data.tentativas.present
          ? data.tentativas.value
          : this.tentativas,
      proximaTentativa: data.proximaTentativa.present
          ? data.proximaTentativa.value
          : this.proximaTentativa,
      ultimaFalha: data.ultimaFalha.present
          ? data.ultimaFalha.value
          : this.ultimaFalha,
      analiseId: data.analiseId.present ? data.analiseId.value : this.analiseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDoEnvio(')
          ..write('posicao: $posicao, ')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('nomeDoPaciente: $nomeDoPaciente, ')
          ..write('sessaoId: $sessaoId, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('situacao: $situacao, ')
          ..write('tentativas: $tentativas, ')
          ..write('proximaTentativa: $proximaTentativa, ')
          ..write('ultimaFalha: $ultimaFalha, ')
          ..write('analiseId: $analiseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    posicao,
    id,
    pacienteId,
    nomeDoPaciente,
    sessaoId,
    criadoEm,
    situacao,
    tentativas,
    proximaTentativa,
    ultimaFalha,
    analiseId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDoEnvio &&
          other.posicao == this.posicao &&
          other.id == this.id &&
          other.pacienteId == this.pacienteId &&
          other.nomeDoPaciente == this.nomeDoPaciente &&
          other.sessaoId == this.sessaoId &&
          other.criadoEm == this.criadoEm &&
          other.situacao == this.situacao &&
          other.tentativas == this.tentativas &&
          other.proximaTentativa == this.proximaTentativa &&
          other.ultimaFalha == this.ultimaFalha &&
          other.analiseId == this.analiseId);
}

class EnviosCompanion extends UpdateCompanion<LinhaDoEnvio> {
  final Value<int> posicao;
  final Value<String> id;
  final Value<String> pacienteId;
  final Value<String> nomeDoPaciente;
  final Value<String> sessaoId;
  final Value<DateTime> criadoEm;
  final Value<String> situacao;
  final Value<int> tentativas;
  final Value<DateTime?> proximaTentativa;
  final Value<String?> ultimaFalha;
  final Value<String?> analiseId;
  const EnviosCompanion({
    this.posicao = const Value.absent(),
    this.id = const Value.absent(),
    this.pacienteId = const Value.absent(),
    this.nomeDoPaciente = const Value.absent(),
    this.sessaoId = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.situacao = const Value.absent(),
    this.tentativas = const Value.absent(),
    this.proximaTentativa = const Value.absent(),
    this.ultimaFalha = const Value.absent(),
    this.analiseId = const Value.absent(),
  });
  EnviosCompanion.insert({
    this.posicao = const Value.absent(),
    required String id,
    required String pacienteId,
    required String nomeDoPaciente,
    required String sessaoId,
    required DateTime criadoEm,
    required String situacao,
    required int tentativas,
    this.proximaTentativa = const Value.absent(),
    this.ultimaFalha = const Value.absent(),
    this.analiseId = const Value.absent(),
  }) : id = Value(id),
       pacienteId = Value(pacienteId),
       nomeDoPaciente = Value(nomeDoPaciente),
       sessaoId = Value(sessaoId),
       criadoEm = Value(criadoEm),
       situacao = Value(situacao),
       tentativas = Value(tentativas);
  static Insertable<LinhaDoEnvio> custom({
    Expression<int>? posicao,
    Expression<String>? id,
    Expression<String>? pacienteId,
    Expression<String>? nomeDoPaciente,
    Expression<String>? sessaoId,
    Expression<DateTime>? criadoEm,
    Expression<String>? situacao,
    Expression<int>? tentativas,
    Expression<DateTime>? proximaTentativa,
    Expression<String>? ultimaFalha,
    Expression<String>? analiseId,
  }) {
    return RawValuesInsertable({
      if (posicao != null) 'posicao': posicao,
      if (id != null) 'id': id,
      if (pacienteId != null) 'paciente_id': pacienteId,
      if (nomeDoPaciente != null) 'nome_do_paciente': nomeDoPaciente,
      if (sessaoId != null) 'sessao_id': sessaoId,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (situacao != null) 'situacao': situacao,
      if (tentativas != null) 'tentativas': tentativas,
      if (proximaTentativa != null) 'proxima_tentativa': proximaTentativa,
      if (ultimaFalha != null) 'ultima_falha': ultimaFalha,
      if (analiseId != null) 'analise_id': analiseId,
    });
  }

  EnviosCompanion copyWith({
    Value<int>? posicao,
    Value<String>? id,
    Value<String>? pacienteId,
    Value<String>? nomeDoPaciente,
    Value<String>? sessaoId,
    Value<DateTime>? criadoEm,
    Value<String>? situacao,
    Value<int>? tentativas,
    Value<DateTime?>? proximaTentativa,
    Value<String?>? ultimaFalha,
    Value<String?>? analiseId,
  }) {
    return EnviosCompanion(
      posicao: posicao ?? this.posicao,
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      nomeDoPaciente: nomeDoPaciente ?? this.nomeDoPaciente,
      sessaoId: sessaoId ?? this.sessaoId,
      criadoEm: criadoEm ?? this.criadoEm,
      situacao: situacao ?? this.situacao,
      tentativas: tentativas ?? this.tentativas,
      proximaTentativa: proximaTentativa ?? this.proximaTentativa,
      ultimaFalha: ultimaFalha ?? this.ultimaFalha,
      analiseId: analiseId ?? this.analiseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (posicao.present) {
      map['posicao'] = Variable<int>(posicao.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pacienteId.present) {
      map['paciente_id'] = Variable<String>(pacienteId.value);
    }
    if (nomeDoPaciente.present) {
      map['nome_do_paciente'] = Variable<String>(nomeDoPaciente.value);
    }
    if (sessaoId.present) {
      map['sessao_id'] = Variable<String>(sessaoId.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<DateTime>(criadoEm.value);
    }
    if (situacao.present) {
      map['situacao'] = Variable<String>(situacao.value);
    }
    if (tentativas.present) {
      map['tentativas'] = Variable<int>(tentativas.value);
    }
    if (proximaTentativa.present) {
      map['proxima_tentativa'] = Variable<DateTime>(proximaTentativa.value);
    }
    if (ultimaFalha.present) {
      map['ultima_falha'] = Variable<String>(ultimaFalha.value);
    }
    if (analiseId.present) {
      map['analise_id'] = Variable<String>(analiseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnviosCompanion(')
          ..write('posicao: $posicao, ')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('nomeDoPaciente: $nomeDoPaciente, ')
          ..write('sessaoId: $sessaoId, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('situacao: $situacao, ')
          ..write('tentativas: $tentativas, ')
          ..write('proximaTentativa: $proximaTentativa, ')
          ..write('ultimaFalha: $ultimaFalha, ')
          ..write('analiseId: $analiseId')
          ..write(')'))
        .toString();
  }
}

class $AmostrasTable extends Amostras
    with TableInfo<$AmostrasTable, LinhaDaAmostra> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmostrasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pacienteIdMeta = const VerificationMeta(
    'pacienteId',
  );
  @override
  late final GeneratedColumn<String> pacienteId = GeneratedColumn<String>(
    'paciente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessaoIdMeta = const VerificationMeta(
    'sessaoId',
  );
  @override
  late final GeneratedColumn<String> sessaoId = GeneratedColumn<String>(
    'sessao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tarefaMeta = const VerificationMeta('tarefa');
  @override
  late final GeneratedColumn<String> tarefa = GeneratedColumn<String>(
    'tarefa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caminhoMeta = const VerificationMeta(
    'caminho',
  );
  @override
  late final GeneratedColumn<String> caminho = GeneratedColumn<String>(
    'caminho',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gravadaEmMeta = const VerificationMeta(
    'gravadaEm',
  );
  @override
  late final GeneratedColumn<DateTime> gravadaEm = GeneratedColumn<DateTime>(
    'gravada_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _duracaoEmMsMeta = const VerificationMeta(
    'duracaoEmMs',
  );
  @override
  late final GeneratedColumn<int> duracaoEmMs = GeneratedColumn<int>(
    'duracao_em_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxaDeAmostragemMeta = const VerificationMeta(
    'taxaDeAmostragem',
  );
  @override
  late final GeneratedColumn<int> taxaDeAmostragem = GeneratedColumn<int>(
    'taxa_de_amostragem',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canaisMeta = const VerificationMeta('canais');
  @override
  late final GeneratedColumn<int> canais = GeneratedColumn<int>(
    'canais',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _problemasMeta = const VerificationMeta(
    'problemas',
  );
  @override
  late final GeneratedColumn<String> problemas = GeneratedColumn<String>(
    'problemas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pacienteId,
    sessaoId,
    tarefa,
    caminho,
    gravadaEm,
    duracaoEmMs,
    taxaDeAmostragem,
    canais,
    problemas,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amostras';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDaAmostra> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('paciente_id')) {
      context.handle(
        _pacienteIdMeta,
        pacienteId.isAcceptableOrUnknown(data['paciente_id']!, _pacienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pacienteIdMeta);
    }
    if (data.containsKey('sessao_id')) {
      context.handle(
        _sessaoIdMeta,
        sessaoId.isAcceptableOrUnknown(data['sessao_id']!, _sessaoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessaoIdMeta);
    }
    if (data.containsKey('tarefa')) {
      context.handle(
        _tarefaMeta,
        tarefa.isAcceptableOrUnknown(data['tarefa']!, _tarefaMeta),
      );
    } else if (isInserting) {
      context.missing(_tarefaMeta);
    }
    if (data.containsKey('caminho')) {
      context.handle(
        _caminhoMeta,
        caminho.isAcceptableOrUnknown(data['caminho']!, _caminhoMeta),
      );
    } else if (isInserting) {
      context.missing(_caminhoMeta);
    }
    if (data.containsKey('gravada_em')) {
      context.handle(
        _gravadaEmMeta,
        gravadaEm.isAcceptableOrUnknown(data['gravada_em']!, _gravadaEmMeta),
      );
    } else if (isInserting) {
      context.missing(_gravadaEmMeta);
    }
    if (data.containsKey('duracao_em_ms')) {
      context.handle(
        _duracaoEmMsMeta,
        duracaoEmMs.isAcceptableOrUnknown(
          data['duracao_em_ms']!,
          _duracaoEmMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_duracaoEmMsMeta);
    }
    if (data.containsKey('taxa_de_amostragem')) {
      context.handle(
        _taxaDeAmostragemMeta,
        taxaDeAmostragem.isAcceptableOrUnknown(
          data['taxa_de_amostragem']!,
          _taxaDeAmostragemMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxaDeAmostragemMeta);
    }
    if (data.containsKey('canais')) {
      context.handle(
        _canaisMeta,
        canais.isAcceptableOrUnknown(data['canais']!, _canaisMeta),
      );
    } else if (isInserting) {
      context.missing(_canaisMeta);
    }
    if (data.containsKey('problemas')) {
      context.handle(
        _problemasMeta,
        problemas.isAcceptableOrUnknown(data['problemas']!, _problemasMeta),
      );
    } else if (isInserting) {
      context.missing(_problemasMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LinhaDaAmostra map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDaAmostra(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pacienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paciente_id'],
      )!,
      sessaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sessao_id'],
      )!,
      tarefa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tarefa'],
      )!,
      caminho: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caminho'],
      )!,
      gravadaEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}gravada_em'],
      )!,
      duracaoEmMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duracao_em_ms'],
      )!,
      taxaDeAmostragem: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taxa_de_amostragem'],
      )!,
      canais: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}canais'],
      )!,
      problemas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}problemas'],
      )!,
    );
  }

  @override
  $AmostrasTable createAlias(String alias) {
    return $AmostrasTable(attachedDatabase, alias);
  }
}

class LinhaDaAmostra extends DataClass implements Insertable<LinhaDaAmostra> {
  final String id;
  final String pacienteId;
  final String sessaoId;

  /// Nome de `TarefaDeGravacao`.
  final String tarefa;
  final String caminho;
  final DateTime gravadaEm;
  final int duracaoEmMs;
  final int taxaDeAmostragem;
  final int canais;

  /// Nomes de `ProblemaNaAmostra`, separados por vírgula. Vazio: sem
  /// ressalva.
  final String problemas;
  const LinhaDaAmostra({
    required this.id,
    required this.pacienteId,
    required this.sessaoId,
    required this.tarefa,
    required this.caminho,
    required this.gravadaEm,
    required this.duracaoEmMs,
    required this.taxaDeAmostragem,
    required this.canais,
    required this.problemas,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['paciente_id'] = Variable<String>(pacienteId);
    map['sessao_id'] = Variable<String>(sessaoId);
    map['tarefa'] = Variable<String>(tarefa);
    map['caminho'] = Variable<String>(caminho);
    map['gravada_em'] = Variable<DateTime>(gravadaEm);
    map['duracao_em_ms'] = Variable<int>(duracaoEmMs);
    map['taxa_de_amostragem'] = Variable<int>(taxaDeAmostragem);
    map['canais'] = Variable<int>(canais);
    map['problemas'] = Variable<String>(problemas);
    return map;
  }

  AmostrasCompanion toCompanion(bool nullToAbsent) {
    return AmostrasCompanion(
      id: Value(id),
      pacienteId: Value(pacienteId),
      sessaoId: Value(sessaoId),
      tarefa: Value(tarefa),
      caminho: Value(caminho),
      gravadaEm: Value(gravadaEm),
      duracaoEmMs: Value(duracaoEmMs),
      taxaDeAmostragem: Value(taxaDeAmostragem),
      canais: Value(canais),
      problemas: Value(problemas),
    );
  }

  factory LinhaDaAmostra.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDaAmostra(
      id: serializer.fromJson<String>(json['id']),
      pacienteId: serializer.fromJson<String>(json['pacienteId']),
      sessaoId: serializer.fromJson<String>(json['sessaoId']),
      tarefa: serializer.fromJson<String>(json['tarefa']),
      caminho: serializer.fromJson<String>(json['caminho']),
      gravadaEm: serializer.fromJson<DateTime>(json['gravadaEm']),
      duracaoEmMs: serializer.fromJson<int>(json['duracaoEmMs']),
      taxaDeAmostragem: serializer.fromJson<int>(json['taxaDeAmostragem']),
      canais: serializer.fromJson<int>(json['canais']),
      problemas: serializer.fromJson<String>(json['problemas']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pacienteId': serializer.toJson<String>(pacienteId),
      'sessaoId': serializer.toJson<String>(sessaoId),
      'tarefa': serializer.toJson<String>(tarefa),
      'caminho': serializer.toJson<String>(caminho),
      'gravadaEm': serializer.toJson<DateTime>(gravadaEm),
      'duracaoEmMs': serializer.toJson<int>(duracaoEmMs),
      'taxaDeAmostragem': serializer.toJson<int>(taxaDeAmostragem),
      'canais': serializer.toJson<int>(canais),
      'problemas': serializer.toJson<String>(problemas),
    };
  }

  LinhaDaAmostra copyWith({
    String? id,
    String? pacienteId,
    String? sessaoId,
    String? tarefa,
    String? caminho,
    DateTime? gravadaEm,
    int? duracaoEmMs,
    int? taxaDeAmostragem,
    int? canais,
    String? problemas,
  }) => LinhaDaAmostra(
    id: id ?? this.id,
    pacienteId: pacienteId ?? this.pacienteId,
    sessaoId: sessaoId ?? this.sessaoId,
    tarefa: tarefa ?? this.tarefa,
    caminho: caminho ?? this.caminho,
    gravadaEm: gravadaEm ?? this.gravadaEm,
    duracaoEmMs: duracaoEmMs ?? this.duracaoEmMs,
    taxaDeAmostragem: taxaDeAmostragem ?? this.taxaDeAmostragem,
    canais: canais ?? this.canais,
    problemas: problemas ?? this.problemas,
  );
  LinhaDaAmostra copyWithCompanion(AmostrasCompanion data) {
    return LinhaDaAmostra(
      id: data.id.present ? data.id.value : this.id,
      pacienteId: data.pacienteId.present
          ? data.pacienteId.value
          : this.pacienteId,
      sessaoId: data.sessaoId.present ? data.sessaoId.value : this.sessaoId,
      tarefa: data.tarefa.present ? data.tarefa.value : this.tarefa,
      caminho: data.caminho.present ? data.caminho.value : this.caminho,
      gravadaEm: data.gravadaEm.present ? data.gravadaEm.value : this.gravadaEm,
      duracaoEmMs: data.duracaoEmMs.present
          ? data.duracaoEmMs.value
          : this.duracaoEmMs,
      taxaDeAmostragem: data.taxaDeAmostragem.present
          ? data.taxaDeAmostragem.value
          : this.taxaDeAmostragem,
      canais: data.canais.present ? data.canais.value : this.canais,
      problemas: data.problemas.present ? data.problemas.value : this.problemas,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDaAmostra(')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('sessaoId: $sessaoId, ')
          ..write('tarefa: $tarefa, ')
          ..write('caminho: $caminho, ')
          ..write('gravadaEm: $gravadaEm, ')
          ..write('duracaoEmMs: $duracaoEmMs, ')
          ..write('taxaDeAmostragem: $taxaDeAmostragem, ')
          ..write('canais: $canais, ')
          ..write('problemas: $problemas')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pacienteId,
    sessaoId,
    tarefa,
    caminho,
    gravadaEm,
    duracaoEmMs,
    taxaDeAmostragem,
    canais,
    problemas,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDaAmostra &&
          other.id == this.id &&
          other.pacienteId == this.pacienteId &&
          other.sessaoId == this.sessaoId &&
          other.tarefa == this.tarefa &&
          other.caminho == this.caminho &&
          other.gravadaEm == this.gravadaEm &&
          other.duracaoEmMs == this.duracaoEmMs &&
          other.taxaDeAmostragem == this.taxaDeAmostragem &&
          other.canais == this.canais &&
          other.problemas == this.problemas);
}

class AmostrasCompanion extends UpdateCompanion<LinhaDaAmostra> {
  final Value<String> id;
  final Value<String> pacienteId;
  final Value<String> sessaoId;
  final Value<String> tarefa;
  final Value<String> caminho;
  final Value<DateTime> gravadaEm;
  final Value<int> duracaoEmMs;
  final Value<int> taxaDeAmostragem;
  final Value<int> canais;
  final Value<String> problemas;
  final Value<int> rowid;
  const AmostrasCompanion({
    this.id = const Value.absent(),
    this.pacienteId = const Value.absent(),
    this.sessaoId = const Value.absent(),
    this.tarefa = const Value.absent(),
    this.caminho = const Value.absent(),
    this.gravadaEm = const Value.absent(),
    this.duracaoEmMs = const Value.absent(),
    this.taxaDeAmostragem = const Value.absent(),
    this.canais = const Value.absent(),
    this.problemas = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AmostrasCompanion.insert({
    required String id,
    required String pacienteId,
    required String sessaoId,
    required String tarefa,
    required String caminho,
    required DateTime gravadaEm,
    required int duracaoEmMs,
    required int taxaDeAmostragem,
    required int canais,
    required String problemas,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pacienteId = Value(pacienteId),
       sessaoId = Value(sessaoId),
       tarefa = Value(tarefa),
       caminho = Value(caminho),
       gravadaEm = Value(gravadaEm),
       duracaoEmMs = Value(duracaoEmMs),
       taxaDeAmostragem = Value(taxaDeAmostragem),
       canais = Value(canais),
       problemas = Value(problemas);
  static Insertable<LinhaDaAmostra> custom({
    Expression<String>? id,
    Expression<String>? pacienteId,
    Expression<String>? sessaoId,
    Expression<String>? tarefa,
    Expression<String>? caminho,
    Expression<DateTime>? gravadaEm,
    Expression<int>? duracaoEmMs,
    Expression<int>? taxaDeAmostragem,
    Expression<int>? canais,
    Expression<String>? problemas,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pacienteId != null) 'paciente_id': pacienteId,
      if (sessaoId != null) 'sessao_id': sessaoId,
      if (tarefa != null) 'tarefa': tarefa,
      if (caminho != null) 'caminho': caminho,
      if (gravadaEm != null) 'gravada_em': gravadaEm,
      if (duracaoEmMs != null) 'duracao_em_ms': duracaoEmMs,
      if (taxaDeAmostragem != null) 'taxa_de_amostragem': taxaDeAmostragem,
      if (canais != null) 'canais': canais,
      if (problemas != null) 'problemas': problemas,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AmostrasCompanion copyWith({
    Value<String>? id,
    Value<String>? pacienteId,
    Value<String>? sessaoId,
    Value<String>? tarefa,
    Value<String>? caminho,
    Value<DateTime>? gravadaEm,
    Value<int>? duracaoEmMs,
    Value<int>? taxaDeAmostragem,
    Value<int>? canais,
    Value<String>? problemas,
    Value<int>? rowid,
  }) {
    return AmostrasCompanion(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      sessaoId: sessaoId ?? this.sessaoId,
      tarefa: tarefa ?? this.tarefa,
      caminho: caminho ?? this.caminho,
      gravadaEm: gravadaEm ?? this.gravadaEm,
      duracaoEmMs: duracaoEmMs ?? this.duracaoEmMs,
      taxaDeAmostragem: taxaDeAmostragem ?? this.taxaDeAmostragem,
      canais: canais ?? this.canais,
      problemas: problemas ?? this.problemas,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pacienteId.present) {
      map['paciente_id'] = Variable<String>(pacienteId.value);
    }
    if (sessaoId.present) {
      map['sessao_id'] = Variable<String>(sessaoId.value);
    }
    if (tarefa.present) {
      map['tarefa'] = Variable<String>(tarefa.value);
    }
    if (caminho.present) {
      map['caminho'] = Variable<String>(caminho.value);
    }
    if (gravadaEm.present) {
      map['gravada_em'] = Variable<DateTime>(gravadaEm.value);
    }
    if (duracaoEmMs.present) {
      map['duracao_em_ms'] = Variable<int>(duracaoEmMs.value);
    }
    if (taxaDeAmostragem.present) {
      map['taxa_de_amostragem'] = Variable<int>(taxaDeAmostragem.value);
    }
    if (canais.present) {
      map['canais'] = Variable<int>(canais.value);
    }
    if (problemas.present) {
      map['problemas'] = Variable<String>(problemas.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmostrasCompanion(')
          ..write('id: $id, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('sessaoId: $sessaoId, ')
          ..write('tarefa: $tarefa, ')
          ..write('caminho: $caminho, ')
          ..write('gravadaEm: $gravadaEm, ')
          ..write('duracaoEmMs: $duracaoEmMs, ')
          ..write('taxaDeAmostragem: $taxaDeAmostragem, ')
          ..write('canais: $canais, ')
          ..write('problemas: $problemas, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AmostrasDoEnvioTable extends AmostrasDoEnvio
    with TableInfo<$AmostrasDoEnvioTable, LinhaDaAmostraDoEnvio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmostrasDoEnvioTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _envioIdMeta = const VerificationMeta(
    'envioId',
  );
  @override
  late final GeneratedColumn<String> envioId = GeneratedColumn<String>(
    'envio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES envios (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amostraIdMeta = const VerificationMeta(
    'amostraId',
  );
  @override
  late final GeneratedColumn<String> amostraId = GeneratedColumn<String>(
    'amostra_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES amostras (id)',
    ),
  );
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  @override
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
    'ordem',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [envioId, amostraId, ordem];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amostras_do_envio';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDaAmostraDoEnvio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('envio_id')) {
      context.handle(
        _envioIdMeta,
        envioId.isAcceptableOrUnknown(data['envio_id']!, _envioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_envioIdMeta);
    }
    if (data.containsKey('amostra_id')) {
      context.handle(
        _amostraIdMeta,
        amostraId.isAcceptableOrUnknown(data['amostra_id']!, _amostraIdMeta),
      );
    } else if (isInserting) {
      context.missing(_amostraIdMeta);
    }
    if (data.containsKey('ordem')) {
      context.handle(
        _ordemMeta,
        ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta),
      );
    } else if (isInserting) {
      context.missing(_ordemMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {envioId, amostraId};
  @override
  LinhaDaAmostraDoEnvio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDaAmostraDoEnvio(
      envioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envio_id'],
      )!,
      amostraId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amostra_id'],
      )!,
      ordem: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordem'],
      )!,
    );
  }

  @override
  $AmostrasDoEnvioTable createAlias(String alias) {
    return $AmostrasDoEnvioTable(attachedDatabase, alias);
  }
}

class LinhaDaAmostraDoEnvio extends DataClass
    implements Insertable<LinhaDaAmostraDoEnvio> {
  final String envioId;
  final String amostraId;
  final int ordem;
  const LinhaDaAmostraDoEnvio({
    required this.envioId,
    required this.amostraId,
    required this.ordem,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['envio_id'] = Variable<String>(envioId);
    map['amostra_id'] = Variable<String>(amostraId);
    map['ordem'] = Variable<int>(ordem);
    return map;
  }

  AmostrasDoEnvioCompanion toCompanion(bool nullToAbsent) {
    return AmostrasDoEnvioCompanion(
      envioId: Value(envioId),
      amostraId: Value(amostraId),
      ordem: Value(ordem),
    );
  }

  factory LinhaDaAmostraDoEnvio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDaAmostraDoEnvio(
      envioId: serializer.fromJson<String>(json['envioId']),
      amostraId: serializer.fromJson<String>(json['amostraId']),
      ordem: serializer.fromJson<int>(json['ordem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'envioId': serializer.toJson<String>(envioId),
      'amostraId': serializer.toJson<String>(amostraId),
      'ordem': serializer.toJson<int>(ordem),
    };
  }

  LinhaDaAmostraDoEnvio copyWith({
    String? envioId,
    String? amostraId,
    int? ordem,
  }) => LinhaDaAmostraDoEnvio(
    envioId: envioId ?? this.envioId,
    amostraId: amostraId ?? this.amostraId,
    ordem: ordem ?? this.ordem,
  );
  LinhaDaAmostraDoEnvio copyWithCompanion(AmostrasDoEnvioCompanion data) {
    return LinhaDaAmostraDoEnvio(
      envioId: data.envioId.present ? data.envioId.value : this.envioId,
      amostraId: data.amostraId.present ? data.amostraId.value : this.amostraId,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDaAmostraDoEnvio(')
          ..write('envioId: $envioId, ')
          ..write('amostraId: $amostraId, ')
          ..write('ordem: $ordem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(envioId, amostraId, ordem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDaAmostraDoEnvio &&
          other.envioId == this.envioId &&
          other.amostraId == this.amostraId &&
          other.ordem == this.ordem);
}

class AmostrasDoEnvioCompanion extends UpdateCompanion<LinhaDaAmostraDoEnvio> {
  final Value<String> envioId;
  final Value<String> amostraId;
  final Value<int> ordem;
  final Value<int> rowid;
  const AmostrasDoEnvioCompanion({
    this.envioId = const Value.absent(),
    this.amostraId = const Value.absent(),
    this.ordem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AmostrasDoEnvioCompanion.insert({
    required String envioId,
    required String amostraId,
    required int ordem,
    this.rowid = const Value.absent(),
  }) : envioId = Value(envioId),
       amostraId = Value(amostraId),
       ordem = Value(ordem);
  static Insertable<LinhaDaAmostraDoEnvio> custom({
    Expression<String>? envioId,
    Expression<String>? amostraId,
    Expression<int>? ordem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (envioId != null) 'envio_id': envioId,
      if (amostraId != null) 'amostra_id': amostraId,
      if (ordem != null) 'ordem': ordem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AmostrasDoEnvioCompanion copyWith({
    Value<String>? envioId,
    Value<String>? amostraId,
    Value<int>? ordem,
    Value<int>? rowid,
  }) {
    return AmostrasDoEnvioCompanion(
      envioId: envioId ?? this.envioId,
      amostraId: amostraId ?? this.amostraId,
      ordem: ordem ?? this.ordem,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (envioId.present) {
      map['envio_id'] = Variable<String>(envioId.value);
    }
    if (amostraId.present) {
      map['amostra_id'] = Variable<String>(amostraId.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmostrasDoEnvioCompanion(')
          ..write('envioId: $envioId, ')
          ..write('amostraId: $amostraId, ')
          ..write('ordem: $ordem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AvaliacoesCapeVTable extends AvaliacoesCapeV
    with TableInfo<$AvaliacoesCapeVTable, LinhaDaAvaliacaoCapeV> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AvaliacoesCapeVTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _analiseIdMeta = const VerificationMeta(
    'analiseId',
  );
  @override
  late final GeneratedColumn<String> analiseId = GeneratedColumn<String>(
    'analise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pacienteIdMeta = const VerificationMeta(
    'pacienteId',
  );
  @override
  late final GeneratedColumn<String> pacienteId = GeneratedColumn<String>(
    'paciente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registradaEmMeta = const VerificationMeta(
    'registradaEm',
  );
  @override
  late final GeneratedColumn<DateTime> registradaEm = GeneratedColumn<DateTime>(
    'registrada_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _comentariosMeta = const VerificationMeta(
    'comentarios',
  );
  @override
  late final GeneratedColumn<String> comentarios = GeneratedColumn<String>(
    'comentarios',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    analiseId,
    pacienteId,
    registradaEm,
    comentarios,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'avaliacoes_cape_v';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDaAvaliacaoCapeV> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('analise_id')) {
      context.handle(
        _analiseIdMeta,
        analiseId.isAcceptableOrUnknown(data['analise_id']!, _analiseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_analiseIdMeta);
    }
    if (data.containsKey('paciente_id')) {
      context.handle(
        _pacienteIdMeta,
        pacienteId.isAcceptableOrUnknown(data['paciente_id']!, _pacienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pacienteIdMeta);
    }
    if (data.containsKey('registrada_em')) {
      context.handle(
        _registradaEmMeta,
        registradaEm.isAcceptableOrUnknown(
          data['registrada_em']!,
          _registradaEmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registradaEmMeta);
    }
    if (data.containsKey('comentarios')) {
      context.handle(
        _comentariosMeta,
        comentarios.isAcceptableOrUnknown(
          data['comentarios']!,
          _comentariosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_comentariosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {analiseId};
  @override
  LinhaDaAvaliacaoCapeV map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDaAvaliacaoCapeV(
      analiseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analise_id'],
      )!,
      pacienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paciente_id'],
      )!,
      registradaEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}registrada_em'],
      )!,
      comentarios: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comentarios'],
      )!,
    );
  }

  @override
  $AvaliacoesCapeVTable createAlias(String alias) {
    return $AvaliacoesCapeVTable(attachedDatabase, alias);
  }
}

class LinhaDaAvaliacaoCapeV extends DataClass
    implements Insertable<LinhaDaAvaliacaoCapeV> {
  final String analiseId;
  final String pacienteId;
  final DateTime registradaEm;
  final String comentarios;
  const LinhaDaAvaliacaoCapeV({
    required this.analiseId,
    required this.pacienteId,
    required this.registradaEm,
    required this.comentarios,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['analise_id'] = Variable<String>(analiseId);
    map['paciente_id'] = Variable<String>(pacienteId);
    map['registrada_em'] = Variable<DateTime>(registradaEm);
    map['comentarios'] = Variable<String>(comentarios);
    return map;
  }

  AvaliacoesCapeVCompanion toCompanion(bool nullToAbsent) {
    return AvaliacoesCapeVCompanion(
      analiseId: Value(analiseId),
      pacienteId: Value(pacienteId),
      registradaEm: Value(registradaEm),
      comentarios: Value(comentarios),
    );
  }

  factory LinhaDaAvaliacaoCapeV.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDaAvaliacaoCapeV(
      analiseId: serializer.fromJson<String>(json['analiseId']),
      pacienteId: serializer.fromJson<String>(json['pacienteId']),
      registradaEm: serializer.fromJson<DateTime>(json['registradaEm']),
      comentarios: serializer.fromJson<String>(json['comentarios']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'analiseId': serializer.toJson<String>(analiseId),
      'pacienteId': serializer.toJson<String>(pacienteId),
      'registradaEm': serializer.toJson<DateTime>(registradaEm),
      'comentarios': serializer.toJson<String>(comentarios),
    };
  }

  LinhaDaAvaliacaoCapeV copyWith({
    String? analiseId,
    String? pacienteId,
    DateTime? registradaEm,
    String? comentarios,
  }) => LinhaDaAvaliacaoCapeV(
    analiseId: analiseId ?? this.analiseId,
    pacienteId: pacienteId ?? this.pacienteId,
    registradaEm: registradaEm ?? this.registradaEm,
    comentarios: comentarios ?? this.comentarios,
  );
  LinhaDaAvaliacaoCapeV copyWithCompanion(AvaliacoesCapeVCompanion data) {
    return LinhaDaAvaliacaoCapeV(
      analiseId: data.analiseId.present ? data.analiseId.value : this.analiseId,
      pacienteId: data.pacienteId.present
          ? data.pacienteId.value
          : this.pacienteId,
      registradaEm: data.registradaEm.present
          ? data.registradaEm.value
          : this.registradaEm,
      comentarios: data.comentarios.present
          ? data.comentarios.value
          : this.comentarios,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDaAvaliacaoCapeV(')
          ..write('analiseId: $analiseId, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('registradaEm: $registradaEm, ')
          ..write('comentarios: $comentarios')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(analiseId, pacienteId, registradaEm, comentarios);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDaAvaliacaoCapeV &&
          other.analiseId == this.analiseId &&
          other.pacienteId == this.pacienteId &&
          other.registradaEm == this.registradaEm &&
          other.comentarios == this.comentarios);
}

class AvaliacoesCapeVCompanion extends UpdateCompanion<LinhaDaAvaliacaoCapeV> {
  final Value<String> analiseId;
  final Value<String> pacienteId;
  final Value<DateTime> registradaEm;
  final Value<String> comentarios;
  final Value<int> rowid;
  const AvaliacoesCapeVCompanion({
    this.analiseId = const Value.absent(),
    this.pacienteId = const Value.absent(),
    this.registradaEm = const Value.absent(),
    this.comentarios = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AvaliacoesCapeVCompanion.insert({
    required String analiseId,
    required String pacienteId,
    required DateTime registradaEm,
    required String comentarios,
    this.rowid = const Value.absent(),
  }) : analiseId = Value(analiseId),
       pacienteId = Value(pacienteId),
       registradaEm = Value(registradaEm),
       comentarios = Value(comentarios);
  static Insertable<LinhaDaAvaliacaoCapeV> custom({
    Expression<String>? analiseId,
    Expression<String>? pacienteId,
    Expression<DateTime>? registradaEm,
    Expression<String>? comentarios,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (analiseId != null) 'analise_id': analiseId,
      if (pacienteId != null) 'paciente_id': pacienteId,
      if (registradaEm != null) 'registrada_em': registradaEm,
      if (comentarios != null) 'comentarios': comentarios,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AvaliacoesCapeVCompanion copyWith({
    Value<String>? analiseId,
    Value<String>? pacienteId,
    Value<DateTime>? registradaEm,
    Value<String>? comentarios,
    Value<int>? rowid,
  }) {
    return AvaliacoesCapeVCompanion(
      analiseId: analiseId ?? this.analiseId,
      pacienteId: pacienteId ?? this.pacienteId,
      registradaEm: registradaEm ?? this.registradaEm,
      comentarios: comentarios ?? this.comentarios,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (analiseId.present) {
      map['analise_id'] = Variable<String>(analiseId.value);
    }
    if (pacienteId.present) {
      map['paciente_id'] = Variable<String>(pacienteId.value);
    }
    if (registradaEm.present) {
      map['registrada_em'] = Variable<DateTime>(registradaEm.value);
    }
    if (comentarios.present) {
      map['comentarios'] = Variable<String>(comentarios.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AvaliacoesCapeVCompanion(')
          ..write('analiseId: $analiseId, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('registradaEm: $registradaEm, ')
          ..write('comentarios: $comentarios, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotasCapeVTable extends NotasCapeV
    with TableInfo<$NotasCapeVTable, LinhaDaNotaCapeV> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotasCapeVTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _analiseIdMeta = const VerificationMeta(
    'analiseId',
  );
  @override
  late final GeneratedColumn<String> analiseId = GeneratedColumn<String>(
    'analise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES avaliacoes_cape_v (analise_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _parametroMeta = const VerificationMeta(
    'parametro',
  );
  @override
  late final GeneratedColumn<String> parametro = GeneratedColumn<String>(
    'parametro',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<int> valor = GeneratedColumn<int>(
    'valor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consistenciaMeta = const VerificationMeta(
    'consistencia',
  );
  @override
  late final GeneratedColumn<String> consistencia = GeneratedColumn<String>(
    'consistencia',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _direcaoMeta = const VerificationMeta(
    'direcao',
  );
  @override
  late final GeneratedColumn<String> direcao = GeneratedColumn<String>(
    'direcao',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    analiseId,
    parametro,
    valor,
    consistencia,
    direcao,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notas_cape_v';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDaNotaCapeV> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('analise_id')) {
      context.handle(
        _analiseIdMeta,
        analiseId.isAcceptableOrUnknown(data['analise_id']!, _analiseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_analiseIdMeta);
    }
    if (data.containsKey('parametro')) {
      context.handle(
        _parametroMeta,
        parametro.isAcceptableOrUnknown(data['parametro']!, _parametroMeta),
      );
    } else if (isInserting) {
      context.missing(_parametroMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    }
    if (data.containsKey('consistencia')) {
      context.handle(
        _consistenciaMeta,
        consistencia.isAcceptableOrUnknown(
          data['consistencia']!,
          _consistenciaMeta,
        ),
      );
    }
    if (data.containsKey('direcao')) {
      context.handle(
        _direcaoMeta,
        direcao.isAcceptableOrUnknown(data['direcao']!, _direcaoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {analiseId, parametro};
  @override
  LinhaDaNotaCapeV map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDaNotaCapeV(
      analiseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analise_id'],
      )!,
      parametro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parametro'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor'],
      ),
      consistencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consistencia'],
      ),
      direcao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direcao'],
      ),
    );
  }

  @override
  $NotasCapeVTable createAlias(String alias) {
    return $NotasCapeVTable(attachedDatabase, alias);
  }
}

class LinhaDaNotaCapeV extends DataClass
    implements Insertable<LinhaDaNotaCapeV> {
  final String analiseId;

  /// Nome de `ParametroCapeV`.
  final String parametro;
  final int? valor;

  /// Nome de `Consistencia`.
  final String? consistencia;

  /// Nome de `DirecaoDoDesvio`.
  final String? direcao;
  const LinhaDaNotaCapeV({
    required this.analiseId,
    required this.parametro,
    this.valor,
    this.consistencia,
    this.direcao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['analise_id'] = Variable<String>(analiseId);
    map['parametro'] = Variable<String>(parametro);
    if (!nullToAbsent || valor != null) {
      map['valor'] = Variable<int>(valor);
    }
    if (!nullToAbsent || consistencia != null) {
      map['consistencia'] = Variable<String>(consistencia);
    }
    if (!nullToAbsent || direcao != null) {
      map['direcao'] = Variable<String>(direcao);
    }
    return map;
  }

  NotasCapeVCompanion toCompanion(bool nullToAbsent) {
    return NotasCapeVCompanion(
      analiseId: Value(analiseId),
      parametro: Value(parametro),
      valor: valor == null && nullToAbsent
          ? const Value.absent()
          : Value(valor),
      consistencia: consistencia == null && nullToAbsent
          ? const Value.absent()
          : Value(consistencia),
      direcao: direcao == null && nullToAbsent
          ? const Value.absent()
          : Value(direcao),
    );
  }

  factory LinhaDaNotaCapeV.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDaNotaCapeV(
      analiseId: serializer.fromJson<String>(json['analiseId']),
      parametro: serializer.fromJson<String>(json['parametro']),
      valor: serializer.fromJson<int?>(json['valor']),
      consistencia: serializer.fromJson<String?>(json['consistencia']),
      direcao: serializer.fromJson<String?>(json['direcao']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'analiseId': serializer.toJson<String>(analiseId),
      'parametro': serializer.toJson<String>(parametro),
      'valor': serializer.toJson<int?>(valor),
      'consistencia': serializer.toJson<String?>(consistencia),
      'direcao': serializer.toJson<String?>(direcao),
    };
  }

  LinhaDaNotaCapeV copyWith({
    String? analiseId,
    String? parametro,
    Value<int?> valor = const Value.absent(),
    Value<String?> consistencia = const Value.absent(),
    Value<String?> direcao = const Value.absent(),
  }) => LinhaDaNotaCapeV(
    analiseId: analiseId ?? this.analiseId,
    parametro: parametro ?? this.parametro,
    valor: valor.present ? valor.value : this.valor,
    consistencia: consistencia.present ? consistencia.value : this.consistencia,
    direcao: direcao.present ? direcao.value : this.direcao,
  );
  LinhaDaNotaCapeV copyWithCompanion(NotasCapeVCompanion data) {
    return LinhaDaNotaCapeV(
      analiseId: data.analiseId.present ? data.analiseId.value : this.analiseId,
      parametro: data.parametro.present ? data.parametro.value : this.parametro,
      valor: data.valor.present ? data.valor.value : this.valor,
      consistencia: data.consistencia.present
          ? data.consistencia.value
          : this.consistencia,
      direcao: data.direcao.present ? data.direcao.value : this.direcao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDaNotaCapeV(')
          ..write('analiseId: $analiseId, ')
          ..write('parametro: $parametro, ')
          ..write('valor: $valor, ')
          ..write('consistencia: $consistencia, ')
          ..write('direcao: $direcao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(analiseId, parametro, valor, consistencia, direcao);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDaNotaCapeV &&
          other.analiseId == this.analiseId &&
          other.parametro == this.parametro &&
          other.valor == this.valor &&
          other.consistencia == this.consistencia &&
          other.direcao == this.direcao);
}

class NotasCapeVCompanion extends UpdateCompanion<LinhaDaNotaCapeV> {
  final Value<String> analiseId;
  final Value<String> parametro;
  final Value<int?> valor;
  final Value<String?> consistencia;
  final Value<String?> direcao;
  final Value<int> rowid;
  const NotasCapeVCompanion({
    this.analiseId = const Value.absent(),
    this.parametro = const Value.absent(),
    this.valor = const Value.absent(),
    this.consistencia = const Value.absent(),
    this.direcao = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotasCapeVCompanion.insert({
    required String analiseId,
    required String parametro,
    this.valor = const Value.absent(),
    this.consistencia = const Value.absent(),
    this.direcao = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : analiseId = Value(analiseId),
       parametro = Value(parametro);
  static Insertable<LinhaDaNotaCapeV> custom({
    Expression<String>? analiseId,
    Expression<String>? parametro,
    Expression<int>? valor,
    Expression<String>? consistencia,
    Expression<String>? direcao,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (analiseId != null) 'analise_id': analiseId,
      if (parametro != null) 'parametro': parametro,
      if (valor != null) 'valor': valor,
      if (consistencia != null) 'consistencia': consistencia,
      if (direcao != null) 'direcao': direcao,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotasCapeVCompanion copyWith({
    Value<String>? analiseId,
    Value<String>? parametro,
    Value<int?>? valor,
    Value<String?>? consistencia,
    Value<String?>? direcao,
    Value<int>? rowid,
  }) {
    return NotasCapeVCompanion(
      analiseId: analiseId ?? this.analiseId,
      parametro: parametro ?? this.parametro,
      valor: valor ?? this.valor,
      consistencia: consistencia ?? this.consistencia,
      direcao: direcao ?? this.direcao,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (analiseId.present) {
      map['analise_id'] = Variable<String>(analiseId.value);
    }
    if (parametro.present) {
      map['parametro'] = Variable<String>(parametro.value);
    }
    if (valor.present) {
      map['valor'] = Variable<int>(valor.value);
    }
    if (consistencia.present) {
      map['consistencia'] = Variable<String>(consistencia.value);
    }
    if (direcao.present) {
      map['direcao'] = Variable<String>(direcao.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotasCapeVCompanion(')
          ..write('analiseId: $analiseId, ')
          ..write('parametro: $parametro, ')
          ..write('valor: $valor, ')
          ..write('consistencia: $consistencia, ')
          ..write('direcao: $direcao, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LaudosTable extends Laudos with TableInfo<$LaudosTable, LinhaDoLaudo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LaudosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _analiseIdMeta = const VerificationMeta(
    'analiseId',
  );
  @override
  late final GeneratedColumn<String> analiseId = GeneratedColumn<String>(
    'analise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pacienteIdMeta = const VerificationMeta(
    'pacienteId',
  );
  @override
  late final GeneratedColumn<String> pacienteId = GeneratedColumn<String>(
    'paciente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conclusaoMeta = const VerificationMeta(
    'conclusao',
  );
  @override
  late final GeneratedColumn<String> conclusao = GeneratedColumn<String>(
    'conclusao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geradoEmMeta = const VerificationMeta(
    'geradoEm',
  );
  @override
  late final GeneratedColumn<DateTime> geradoEm = GeneratedColumn<DateTime>(
    'gerado_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pdfMeta = const VerificationMeta('pdf');
  @override
  late final GeneratedColumn<Uint8List> pdf = GeneratedColumn<Uint8List>(
    'pdf',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    analiseId,
    pacienteId,
    conclusao,
    geradoEm,
    pdf,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'laudos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinhaDoLaudo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('analise_id')) {
      context.handle(
        _analiseIdMeta,
        analiseId.isAcceptableOrUnknown(data['analise_id']!, _analiseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_analiseIdMeta);
    }
    if (data.containsKey('paciente_id')) {
      context.handle(
        _pacienteIdMeta,
        pacienteId.isAcceptableOrUnknown(data['paciente_id']!, _pacienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pacienteIdMeta);
    }
    if (data.containsKey('conclusao')) {
      context.handle(
        _conclusaoMeta,
        conclusao.isAcceptableOrUnknown(data['conclusao']!, _conclusaoMeta),
      );
    } else if (isInserting) {
      context.missing(_conclusaoMeta);
    }
    if (data.containsKey('gerado_em')) {
      context.handle(
        _geradoEmMeta,
        geradoEm.isAcceptableOrUnknown(data['gerado_em']!, _geradoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_geradoEmMeta);
    }
    if (data.containsKey('pdf')) {
      context.handle(
        _pdfMeta,
        pdf.isAcceptableOrUnknown(data['pdf']!, _pdfMeta),
      );
    } else if (isInserting) {
      context.missing(_pdfMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {analiseId};
  @override
  LinhaDoLaudo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinhaDoLaudo(
      analiseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analise_id'],
      )!,
      pacienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paciente_id'],
      )!,
      conclusao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conclusao'],
      )!,
      geradoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}gerado_em'],
      )!,
      pdf: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}pdf'],
      )!,
    );
  }

  @override
  $LaudosTable createAlias(String alias) {
    return $LaudosTable(attachedDatabase, alias);
  }
}

class LinhaDoLaudo extends DataClass implements Insertable<LinhaDoLaudo> {
  final String analiseId;
  final String pacienteId;
  final String conclusao;
  final DateTime geradoEm;
  final Uint8List pdf;
  const LinhaDoLaudo({
    required this.analiseId,
    required this.pacienteId,
    required this.conclusao,
    required this.geradoEm,
    required this.pdf,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['analise_id'] = Variable<String>(analiseId);
    map['paciente_id'] = Variable<String>(pacienteId);
    map['conclusao'] = Variable<String>(conclusao);
    map['gerado_em'] = Variable<DateTime>(geradoEm);
    map['pdf'] = Variable<Uint8List>(pdf);
    return map;
  }

  LaudosCompanion toCompanion(bool nullToAbsent) {
    return LaudosCompanion(
      analiseId: Value(analiseId),
      pacienteId: Value(pacienteId),
      conclusao: Value(conclusao),
      geradoEm: Value(geradoEm),
      pdf: Value(pdf),
    );
  }

  factory LinhaDoLaudo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinhaDoLaudo(
      analiseId: serializer.fromJson<String>(json['analiseId']),
      pacienteId: serializer.fromJson<String>(json['pacienteId']),
      conclusao: serializer.fromJson<String>(json['conclusao']),
      geradoEm: serializer.fromJson<DateTime>(json['geradoEm']),
      pdf: serializer.fromJson<Uint8List>(json['pdf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'analiseId': serializer.toJson<String>(analiseId),
      'pacienteId': serializer.toJson<String>(pacienteId),
      'conclusao': serializer.toJson<String>(conclusao),
      'geradoEm': serializer.toJson<DateTime>(geradoEm),
      'pdf': serializer.toJson<Uint8List>(pdf),
    };
  }

  LinhaDoLaudo copyWith({
    String? analiseId,
    String? pacienteId,
    String? conclusao,
    DateTime? geradoEm,
    Uint8List? pdf,
  }) => LinhaDoLaudo(
    analiseId: analiseId ?? this.analiseId,
    pacienteId: pacienteId ?? this.pacienteId,
    conclusao: conclusao ?? this.conclusao,
    geradoEm: geradoEm ?? this.geradoEm,
    pdf: pdf ?? this.pdf,
  );
  LinhaDoLaudo copyWithCompanion(LaudosCompanion data) {
    return LinhaDoLaudo(
      analiseId: data.analiseId.present ? data.analiseId.value : this.analiseId,
      pacienteId: data.pacienteId.present
          ? data.pacienteId.value
          : this.pacienteId,
      conclusao: data.conclusao.present ? data.conclusao.value : this.conclusao,
      geradoEm: data.geradoEm.present ? data.geradoEm.value : this.geradoEm,
      pdf: data.pdf.present ? data.pdf.value : this.pdf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinhaDoLaudo(')
          ..write('analiseId: $analiseId, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('conclusao: $conclusao, ')
          ..write('geradoEm: $geradoEm, ')
          ..write('pdf: $pdf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    analiseId,
    pacienteId,
    conclusao,
    geradoEm,
    $driftBlobEquality.hash(pdf),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinhaDoLaudo &&
          other.analiseId == this.analiseId &&
          other.pacienteId == this.pacienteId &&
          other.conclusao == this.conclusao &&
          other.geradoEm == this.geradoEm &&
          $driftBlobEquality.equals(other.pdf, this.pdf));
}

class LaudosCompanion extends UpdateCompanion<LinhaDoLaudo> {
  final Value<String> analiseId;
  final Value<String> pacienteId;
  final Value<String> conclusao;
  final Value<DateTime> geradoEm;
  final Value<Uint8List> pdf;
  final Value<int> rowid;
  const LaudosCompanion({
    this.analiseId = const Value.absent(),
    this.pacienteId = const Value.absent(),
    this.conclusao = const Value.absent(),
    this.geradoEm = const Value.absent(),
    this.pdf = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LaudosCompanion.insert({
    required String analiseId,
    required String pacienteId,
    required String conclusao,
    required DateTime geradoEm,
    required Uint8List pdf,
    this.rowid = const Value.absent(),
  }) : analiseId = Value(analiseId),
       pacienteId = Value(pacienteId),
       conclusao = Value(conclusao),
       geradoEm = Value(geradoEm),
       pdf = Value(pdf);
  static Insertable<LinhaDoLaudo> custom({
    Expression<String>? analiseId,
    Expression<String>? pacienteId,
    Expression<String>? conclusao,
    Expression<DateTime>? geradoEm,
    Expression<Uint8List>? pdf,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (analiseId != null) 'analise_id': analiseId,
      if (pacienteId != null) 'paciente_id': pacienteId,
      if (conclusao != null) 'conclusao': conclusao,
      if (geradoEm != null) 'gerado_em': geradoEm,
      if (pdf != null) 'pdf': pdf,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LaudosCompanion copyWith({
    Value<String>? analiseId,
    Value<String>? pacienteId,
    Value<String>? conclusao,
    Value<DateTime>? geradoEm,
    Value<Uint8List>? pdf,
    Value<int>? rowid,
  }) {
    return LaudosCompanion(
      analiseId: analiseId ?? this.analiseId,
      pacienteId: pacienteId ?? this.pacienteId,
      conclusao: conclusao ?? this.conclusao,
      geradoEm: geradoEm ?? this.geradoEm,
      pdf: pdf ?? this.pdf,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (analiseId.present) {
      map['analise_id'] = Variable<String>(analiseId.value);
    }
    if (pacienteId.present) {
      map['paciente_id'] = Variable<String>(pacienteId.value);
    }
    if (conclusao.present) {
      map['conclusao'] = Variable<String>(conclusao.value);
    }
    if (geradoEm.present) {
      map['gerado_em'] = Variable<DateTime>(geradoEm.value);
    }
    if (pdf.present) {
      map['pdf'] = Variable<Uint8List>(pdf.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LaudosCompanion(')
          ..write('analiseId: $analiseId, ')
          ..write('pacienteId: $pacienteId, ')
          ..write('conclusao: $conclusao, ')
          ..write('geradoEm: $geradoEm, ')
          ..write('pdf: $pdf, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BancoLocal extends GeneratedDatabase {
  _$BancoLocal(QueryExecutor e) : super(e);
  $BancoLocalManager get managers => $BancoLocalManager(this);
  late final $PacientesTable pacientes = $PacientesTable(this);
  late final $ConsentimentosTable consentimentos = $ConsentimentosTable(this);
  late final $RetiradasDeConsentimentoTable retiradasDeConsentimento =
      $RetiradasDeConsentimentoTable(this);
  late final $EnviosTable envios = $EnviosTable(this);
  late final $AmostrasTable amostras = $AmostrasTable(this);
  late final $AmostrasDoEnvioTable amostrasDoEnvio = $AmostrasDoEnvioTable(
    this,
  );
  late final $AvaliacoesCapeVTable avaliacoesCapeV = $AvaliacoesCapeVTable(
    this,
  );
  late final $NotasCapeVTable notasCapeV = $NotasCapeVTable(this);
  late final $LaudosTable laudos = $LaudosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pacientes,
    consentimentos,
    retiradasDeConsentimento,
    envios,
    amostras,
    amostrasDoEnvio,
    avaliacoesCapeV,
    notasCapeV,
    laudos,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'envios',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('amostras_do_envio', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'avaliacoes_cape_v',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notas_cape_v', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$PacientesTableCreateCompanionBuilder = PacientesCompanion Function({
  required String id,
  required String nome,
  required String queixa,
  Value<String?> sexo,
  Value<DateTime?> dataDeNascimento,
  required DateTime cadastradoEm,
  Value<int> rowid,
});
typedef $$PacientesTableUpdateCompanionBuilder = PacientesCompanion Function({
  Value<String> id,
  Value<String> nome,
  Value<String> queixa,
  Value<String?> sexo,
  Value<DateTime?> dataDeNascimento,
  Value<DateTime> cadastradoEm,
  Value<int> rowid,
});

class $$PacientesTableFilterComposer
    extends Composer<_$BancoLocal, $PacientesTable> {
  $$PacientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get queixa => $composableBuilder(
    column: $table.queixa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sexo => $composableBuilder(
    column: $table.sexo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataDeNascimento => $composableBuilder(
    column: $table.dataDeNascimento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cadastradoEm => $composableBuilder(
    column: $table.cadastradoEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PacientesTableOrderingComposer
    extends Composer<_$BancoLocal, $PacientesTable> {
  $$PacientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queixa => $composableBuilder(
    column: $table.queixa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sexo => $composableBuilder(
    column: $table.sexo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataDeNascimento => $composableBuilder(
    column: $table.dataDeNascimento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cadastradoEm => $composableBuilder(
    column: $table.cadastradoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PacientesTableAnnotationComposer
    extends Composer<_$BancoLocal, $PacientesTable> {
  $$PacientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get queixa =>
      $composableBuilder(column: $table.queixa, builder: (column) => column);

  GeneratedColumn<String> get sexo =>
      $composableBuilder(column: $table.sexo, builder: (column) => column);

  GeneratedColumn<DateTime> get dataDeNascimento => $composableBuilder(
    column: $table.dataDeNascimento,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cadastradoEm => $composableBuilder(
    column: $table.cadastradoEm,
    builder: (column) => column,
  );
}

class $$PacientesTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $PacientesTable,
          LinhaDoPaciente,
          $$PacientesTableFilterComposer,
          $$PacientesTableOrderingComposer,
          $$PacientesTableAnnotationComposer,
          $$PacientesTableCreateCompanionBuilder,
          $$PacientesTableUpdateCompanionBuilder,
          (
            LinhaDoPaciente,
            BaseReferences<_$BancoLocal, $PacientesTable, LinhaDoPaciente>,
          ),
          LinhaDoPaciente,
          PrefetchHooks Function()
        > {
  $$PacientesTableTableManager(_$BancoLocal db, $PacientesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PacientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PacientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PacientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> queixa = const Value.absent(),
                Value<String?> sexo = const Value.absent(),
                Value<DateTime?> dataDeNascimento = const Value.absent(),
                Value<DateTime> cadastradoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PacientesCompanion(
                id: id,
                nome: nome,
                queixa: queixa,
                sexo: sexo,
                dataDeNascimento: dataDeNascimento,
                cadastradoEm: cadastradoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                required String queixa,
                Value<String?> sexo = const Value.absent(),
                Value<DateTime?> dataDeNascimento = const Value.absent(),
                required DateTime cadastradoEm,
                Value<int> rowid = const Value.absent(),
              }) => PacientesCompanion.insert(
                id: id,
                nome: nome,
                queixa: queixa,
                sexo: sexo,
                dataDeNascimento: dataDeNascimento,
                cadastradoEm: cadastradoEm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PacientesTable, LinhaDoPaciente>(table),
                  BaseReferences<
                    _$BancoLocal,
                    $PacientesTable,
                    LinhaDoPaciente
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PacientesTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $PacientesTable,
      LinhaDoPaciente,
      $$PacientesTableFilterComposer,
      $$PacientesTableOrderingComposer,
      $$PacientesTableAnnotationComposer,
      $$PacientesTableCreateCompanionBuilder,
      $$PacientesTableUpdateCompanionBuilder,
      (
        LinhaDoPaciente,
        BaseReferences<_$BancoLocal, $PacientesTable, LinhaDoPaciente>,
      ),
      LinhaDoPaciente,
      PrefetchHooks Function()
    >;
typedef $$ConsentimentosTableCreateCompanionBuilder =
    ConsentimentosCompanion Function({
      Value<int> id,
      required String pacienteId,
      required DateTime registradoEm,
      required String versaoDoTermo,
      required String quemAutoriza,
      Value<String?> nomeDoResponsavel,
    });
typedef $$ConsentimentosTableUpdateCompanionBuilder =
    ConsentimentosCompanion Function({
      Value<int> id,
      Value<String> pacienteId,
      Value<DateTime> registradoEm,
      Value<String> versaoDoTermo,
      Value<String> quemAutoriza,
      Value<String?> nomeDoResponsavel,
    });

final class $$ConsentimentosTableReferences
    extends
        BaseReferences<
          _$BancoLocal,
          $ConsentimentosTable,
          LinhaDoConsentimento
        > {
  $$ConsentimentosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $RetiradasDeConsentimentoTable,
    List<LinhaDaRetirada>
  >
  _retiradasDeConsentimentoRefsTable(_$BancoLocal db) =>
      MultiTypedResultKey.fromTable(
        db.retiradasDeConsentimento,
        aliasName:
            'consentimentos__id__retiradas_de_consentimento__consentimento_id',
      );

  $$RetiradasDeConsentimentoTableProcessedTableManager
  get retiradasDeConsentimentoRefs {
    final manager = $$RetiradasDeConsentimentoTableTableManager(
      $_db,
      $_db.retiradasDeConsentimento,
    ).filter((f) => f.consentimentoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _retiradasDeConsentimentoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConsentimentosTableFilterComposer
    extends Composer<_$BancoLocal, $ConsentimentosTable> {
  $$ConsentimentosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registradoEm => $composableBuilder(
    column: $table.registradoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versaoDoTermo => $composableBuilder(
    column: $table.versaoDoTermo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quemAutoriza => $composableBuilder(
    column: $table.quemAutoriza,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomeDoResponsavel => $composableBuilder(
    column: $table.nomeDoResponsavel,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> retiradasDeConsentimentoRefs(
    Expression<bool> Function($$RetiradasDeConsentimentoTableFilterComposer f)
    f,
  ) {
    final $$RetiradasDeConsentimentoTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.retiradasDeConsentimento,
          getReferencedColumn: (t) => t.consentimentoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RetiradasDeConsentimentoTableFilterComposer(
                $db: $db,
                $table: $db.retiradasDeConsentimento,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ConsentimentosTableOrderingComposer
    extends Composer<_$BancoLocal, $ConsentimentosTable> {
  $$ConsentimentosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registradoEm => $composableBuilder(
    column: $table.registradoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versaoDoTermo => $composableBuilder(
    column: $table.versaoDoTermo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quemAutoriza => $composableBuilder(
    column: $table.quemAutoriza,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomeDoResponsavel => $composableBuilder(
    column: $table.nomeDoResponsavel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConsentimentosTableAnnotationComposer
    extends Composer<_$BancoLocal, $ConsentimentosTable> {
  $$ConsentimentosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get registradoEm => $composableBuilder(
    column: $table.registradoEm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get versaoDoTermo => $composableBuilder(
    column: $table.versaoDoTermo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quemAutoriza => $composableBuilder(
    column: $table.quemAutoriza,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nomeDoResponsavel => $composableBuilder(
    column: $table.nomeDoResponsavel,
    builder: (column) => column,
  );

  Expression<T> retiradasDeConsentimentoRefs<T extends Object>(
    Expression<T> Function($$RetiradasDeConsentimentoTableAnnotationComposer a)
    f,
  ) {
    final $$RetiradasDeConsentimentoTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.retiradasDeConsentimento,
          getReferencedColumn: (t) => t.consentimentoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RetiradasDeConsentimentoTableAnnotationComposer(
                $db: $db,
                $table: $db.retiradasDeConsentimento,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ConsentimentosTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $ConsentimentosTable,
          LinhaDoConsentimento,
          $$ConsentimentosTableFilterComposer,
          $$ConsentimentosTableOrderingComposer,
          $$ConsentimentosTableAnnotationComposer,
          $$ConsentimentosTableCreateCompanionBuilder,
          $$ConsentimentosTableUpdateCompanionBuilder,
          (LinhaDoConsentimento, $$ConsentimentosTableReferences),
          LinhaDoConsentimento,
          PrefetchHooks Function({bool retiradasDeConsentimentoRefs})
        > {
  $$ConsentimentosTableTableManager(_$BancoLocal db, $ConsentimentosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentimentosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentimentosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentimentosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pacienteId = const Value.absent(),
                Value<DateTime> registradoEm = const Value.absent(),
                Value<String> versaoDoTermo = const Value.absent(),
                Value<String> quemAutoriza = const Value.absent(),
                Value<String?> nomeDoResponsavel = const Value.absent(),
              }) => ConsentimentosCompanion(
                id: id,
                pacienteId: pacienteId,
                registradoEm: registradoEm,
                versaoDoTermo: versaoDoTermo,
                quemAutoriza: quemAutoriza,
                nomeDoResponsavel: nomeDoResponsavel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String pacienteId,
                required DateTime registradoEm,
                required String versaoDoTermo,
                required String quemAutoriza,
                Value<String?> nomeDoResponsavel = const Value.absent(),
              }) => ConsentimentosCompanion.insert(
                id: id,
                pacienteId: pacienteId,
                registradoEm: registradoEm,
                versaoDoTermo: versaoDoTermo,
                quemAutoriza: quemAutoriza,
                nomeDoResponsavel: nomeDoResponsavel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConsentimentosTable, LinhaDoConsentimento>(
                    table,
                  ),
                  $$ConsentimentosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({retiradasDeConsentimentoRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (retiradasDeConsentimentoRefs) db.retiradasDeConsentimento,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (retiradasDeConsentimentoRefs)
                    await $_getPrefetchedData<
                      LinhaDoConsentimento,
                      $ConsentimentosTable,
                      LinhaDaRetirada
                    >(
                      currentTable: table,
                      referencedTable: $$ConsentimentosTableReferences
                          ._retiradasDeConsentimentoRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConsentimentosTableReferences(
                            db,
                            table,
                            p0,
                          ).retiradasDeConsentimentoRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.consentimentoId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConsentimentosTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $ConsentimentosTable,
      LinhaDoConsentimento,
      $$ConsentimentosTableFilterComposer,
      $$ConsentimentosTableOrderingComposer,
      $$ConsentimentosTableAnnotationComposer,
      $$ConsentimentosTableCreateCompanionBuilder,
      $$ConsentimentosTableUpdateCompanionBuilder,
      (LinhaDoConsentimento, $$ConsentimentosTableReferences),
      LinhaDoConsentimento,
      PrefetchHooks Function({bool retiradasDeConsentimentoRefs})
    >;
typedef $$RetiradasDeConsentimentoTableCreateCompanionBuilder =
    RetiradasDeConsentimentoCompanion Function({
      Value<int> id,
      required String pacienteId,
      Value<int?> consentimentoId,
      required DateTime retiradaEm,
      required String quemPediu,
      Value<String?> nomeDoResponsavel,
    });
typedef $$RetiradasDeConsentimentoTableUpdateCompanionBuilder =
    RetiradasDeConsentimentoCompanion Function({
      Value<int> id,
      Value<String> pacienteId,
      Value<int?> consentimentoId,
      Value<DateTime> retiradaEm,
      Value<String> quemPediu,
      Value<String?> nomeDoResponsavel,
    });

final class $$RetiradasDeConsentimentoTableReferences
    extends
        BaseReferences<
          _$BancoLocal,
          $RetiradasDeConsentimentoTable,
          LinhaDaRetirada
        > {
  $$RetiradasDeConsentimentoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConsentimentosTable _consentimentoIdTable(_$BancoLocal db) =>
      db.consentimentos.createAlias(
        'retiradas_de_consentimento__consentimento_id__consentimentos__id',
      );

  $$ConsentimentosTableProcessedTableManager? get consentimentoId {
    final $_column = $_itemColumn<int>('consentimento_id');
    if ($_column == null) return null;
    final manager = $$ConsentimentosTableTableManager(
      $_db,
      $_db.consentimentos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_consentimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RetiradasDeConsentimentoTableFilterComposer
    extends Composer<_$BancoLocal, $RetiradasDeConsentimentoTable> {
  $$RetiradasDeConsentimentoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get retiradaEm => $composableBuilder(
    column: $table.retiradaEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quemPediu => $composableBuilder(
    column: $table.quemPediu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomeDoResponsavel => $composableBuilder(
    column: $table.nomeDoResponsavel,
    builder: (column) => ColumnFilters(column),
  );

  $$ConsentimentosTableFilterComposer get consentimentoId {
    final $$ConsentimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.consentimentoId,
      referencedTable: $db.consentimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsentimentosTableFilterComposer(
            $db: $db,
            $table: $db.consentimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RetiradasDeConsentimentoTableOrderingComposer
    extends Composer<_$BancoLocal, $RetiradasDeConsentimentoTable> {
  $$RetiradasDeConsentimentoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retiradaEm => $composableBuilder(
    column: $table.retiradaEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quemPediu => $composableBuilder(
    column: $table.quemPediu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomeDoResponsavel => $composableBuilder(
    column: $table.nomeDoResponsavel,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConsentimentosTableOrderingComposer get consentimentoId {
    final $$ConsentimentosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.consentimentoId,
      referencedTable: $db.consentimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsentimentosTableOrderingComposer(
            $db: $db,
            $table: $db.consentimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RetiradasDeConsentimentoTableAnnotationComposer
    extends Composer<_$BancoLocal, $RetiradasDeConsentimentoTable> {
  $$RetiradasDeConsentimentoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get retiradaEm => $composableBuilder(
    column: $table.retiradaEm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quemPediu =>
      $composableBuilder(column: $table.quemPediu, builder: (column) => column);

  GeneratedColumn<String> get nomeDoResponsavel => $composableBuilder(
    column: $table.nomeDoResponsavel,
    builder: (column) => column,
  );

  $$ConsentimentosTableAnnotationComposer get consentimentoId {
    final $$ConsentimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.consentimentoId,
      referencedTable: $db.consentimentos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsentimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.consentimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RetiradasDeConsentimentoTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $RetiradasDeConsentimentoTable,
          LinhaDaRetirada,
          $$RetiradasDeConsentimentoTableFilterComposer,
          $$RetiradasDeConsentimentoTableOrderingComposer,
          $$RetiradasDeConsentimentoTableAnnotationComposer,
          $$RetiradasDeConsentimentoTableCreateCompanionBuilder,
          $$RetiradasDeConsentimentoTableUpdateCompanionBuilder,
          (LinhaDaRetirada, $$RetiradasDeConsentimentoTableReferences),
          LinhaDaRetirada,
          PrefetchHooks Function({bool consentimentoId})
        > {
  $$RetiradasDeConsentimentoTableTableManager(
    _$BancoLocal db,
    $RetiradasDeConsentimentoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RetiradasDeConsentimentoTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RetiradasDeConsentimentoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RetiradasDeConsentimentoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pacienteId = const Value.absent(),
                Value<int?> consentimentoId = const Value.absent(),
                Value<DateTime> retiradaEm = const Value.absent(),
                Value<String> quemPediu = const Value.absent(),
                Value<String?> nomeDoResponsavel = const Value.absent(),
              }) => RetiradasDeConsentimentoCompanion(
                id: id,
                pacienteId: pacienteId,
                consentimentoId: consentimentoId,
                retiradaEm: retiradaEm,
                quemPediu: quemPediu,
                nomeDoResponsavel: nomeDoResponsavel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String pacienteId,
                Value<int?> consentimentoId = const Value.absent(),
                required DateTime retiradaEm,
                required String quemPediu,
                Value<String?> nomeDoResponsavel = const Value.absent(),
              }) => RetiradasDeConsentimentoCompanion.insert(
                id: id,
                pacienteId: pacienteId,
                consentimentoId: consentimentoId,
                retiradaEm: retiradaEm,
                quemPediu: quemPediu,
                nomeDoResponsavel: nomeDoResponsavel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RetiradasDeConsentimentoTable, LinhaDaRetirada>(
                    table,
                  ),
                  $$RetiradasDeConsentimentoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({consentimentoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (consentimentoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.consentimentoId,
                        referencedTable:
                            $$RetiradasDeConsentimentoTableReferences
                                ._consentimentoIdTable(db),
                        referencedColumn:
                            $$RetiradasDeConsentimentoTableReferences
                                ._consentimentoIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RetiradasDeConsentimentoTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $RetiradasDeConsentimentoTable,
      LinhaDaRetirada,
      $$RetiradasDeConsentimentoTableFilterComposer,
      $$RetiradasDeConsentimentoTableOrderingComposer,
      $$RetiradasDeConsentimentoTableAnnotationComposer,
      $$RetiradasDeConsentimentoTableCreateCompanionBuilder,
      $$RetiradasDeConsentimentoTableUpdateCompanionBuilder,
      (LinhaDaRetirada, $$RetiradasDeConsentimentoTableReferences),
      LinhaDaRetirada,
      PrefetchHooks Function({bool consentimentoId})
    >;
typedef $$EnviosTableCreateCompanionBuilder = EnviosCompanion Function({
  Value<int> posicao,
  required String id,
  required String pacienteId,
  required String nomeDoPaciente,
  required String sessaoId,
  required DateTime criadoEm,
  required String situacao,
  required int tentativas,
  Value<DateTime?> proximaTentativa,
  Value<String?> ultimaFalha,
  Value<String?> analiseId,
});
typedef $$EnviosTableUpdateCompanionBuilder = EnviosCompanion Function({
  Value<int> posicao,
  Value<String> id,
  Value<String> pacienteId,
  Value<String> nomeDoPaciente,
  Value<String> sessaoId,
  Value<DateTime> criadoEm,
  Value<String> situacao,
  Value<int> tentativas,
  Value<DateTime?> proximaTentativa,
  Value<String?> ultimaFalha,
  Value<String?> analiseId,
});

final class $$EnviosTableReferences
    extends BaseReferences<_$BancoLocal, $EnviosTable, LinhaDoEnvio> {
  $$EnviosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AmostrasDoEnvioTable, List<LinhaDaAmostraDoEnvio>>
  _amostrasDoEnvioRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.amostrasDoEnvio,
    aliasName: 'envios__id__amostras_do_envio__envio_id',
  );

  $$AmostrasDoEnvioTableProcessedTableManager get amostrasDoEnvioRefs {
    final manager = $$AmostrasDoEnvioTableTableManager(
      $_db,
      $_db.amostrasDoEnvio,
    ).filter((f) => f.envioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _amostrasDoEnvioRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EnviosTableFilterComposer extends Composer<_$BancoLocal, $EnviosTable> {
  $$EnviosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get posicao => $composableBuilder(
    column: $table.posicao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomeDoPaciente => $composableBuilder(
    column: $table.nomeDoPaciente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessaoId => $composableBuilder(
    column: $table.sessaoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get situacao => $composableBuilder(
    column: $table.situacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get proximaTentativa => $composableBuilder(
    column: $table.proximaTentativa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimaFalha => $composableBuilder(
    column: $table.ultimaFalha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analiseId => $composableBuilder(
    column: $table.analiseId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> amostrasDoEnvioRefs(
    Expression<bool> Function($$AmostrasDoEnvioTableFilterComposer f) f,
  ) {
    final $$AmostrasDoEnvioTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amostrasDoEnvio,
      getReferencedColumn: (t) => t.envioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmostrasDoEnvioTableFilterComposer(
            $db: $db,
            $table: $db.amostrasDoEnvio,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EnviosTableOrderingComposer
    extends Composer<_$BancoLocal, $EnviosTable> {
  $$EnviosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get posicao => $composableBuilder(
    column: $table.posicao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomeDoPaciente => $composableBuilder(
    column: $table.nomeDoPaciente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessaoId => $composableBuilder(
    column: $table.sessaoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get situacao => $composableBuilder(
    column: $table.situacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get proximaTentativa => $composableBuilder(
    column: $table.proximaTentativa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimaFalha => $composableBuilder(
    column: $table.ultimaFalha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analiseId => $composableBuilder(
    column: $table.analiseId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnviosTableAnnotationComposer
    extends Composer<_$BancoLocal, $EnviosTable> {
  $$EnviosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get posicao =>
      $composableBuilder(column: $table.posicao, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nomeDoPaciente => $composableBuilder(
    column: $table.nomeDoPaciente,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessaoId =>
      $composableBuilder(column: $table.sessaoId, builder: (column) => column);

  GeneratedColumn<DateTime> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  GeneratedColumn<String> get situacao =>
      $composableBuilder(column: $table.situacao, builder: (column) => column);

  GeneratedColumn<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get proximaTentativa => $composableBuilder(
    column: $table.proximaTentativa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ultimaFalha => $composableBuilder(
    column: $table.ultimaFalha,
    builder: (column) => column,
  );

  GeneratedColumn<String> get analiseId =>
      $composableBuilder(column: $table.analiseId, builder: (column) => column);

  Expression<T> amostrasDoEnvioRefs<T extends Object>(
    Expression<T> Function($$AmostrasDoEnvioTableAnnotationComposer a) f,
  ) {
    final $$AmostrasDoEnvioTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amostrasDoEnvio,
      getReferencedColumn: (t) => t.envioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmostrasDoEnvioTableAnnotationComposer(
            $db: $db,
            $table: $db.amostrasDoEnvio,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EnviosTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $EnviosTable,
          LinhaDoEnvio,
          $$EnviosTableFilterComposer,
          $$EnviosTableOrderingComposer,
          $$EnviosTableAnnotationComposer,
          $$EnviosTableCreateCompanionBuilder,
          $$EnviosTableUpdateCompanionBuilder,
          (LinhaDoEnvio, $$EnviosTableReferences),
          LinhaDoEnvio,
          PrefetchHooks Function({bool amostrasDoEnvioRefs})
        > {
  $$EnviosTableTableManager(_$BancoLocal db, $EnviosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnviosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnviosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnviosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> posicao = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> pacienteId = const Value.absent(),
                Value<String> nomeDoPaciente = const Value.absent(),
                Value<String> sessaoId = const Value.absent(),
                Value<DateTime> criadoEm = const Value.absent(),
                Value<String> situacao = const Value.absent(),
                Value<int> tentativas = const Value.absent(),
                Value<DateTime?> proximaTentativa = const Value.absent(),
                Value<String?> ultimaFalha = const Value.absent(),
                Value<String?> analiseId = const Value.absent(),
              }) => EnviosCompanion(
                posicao: posicao,
                id: id,
                pacienteId: pacienteId,
                nomeDoPaciente: nomeDoPaciente,
                sessaoId: sessaoId,
                criadoEm: criadoEm,
                situacao: situacao,
                tentativas: tentativas,
                proximaTentativa: proximaTentativa,
                ultimaFalha: ultimaFalha,
                analiseId: analiseId,
              ),
          createCompanionCallback:
              ({
                Value<int> posicao = const Value.absent(),
                required String id,
                required String pacienteId,
                required String nomeDoPaciente,
                required String sessaoId,
                required DateTime criadoEm,
                required String situacao,
                required int tentativas,
                Value<DateTime?> proximaTentativa = const Value.absent(),
                Value<String?> ultimaFalha = const Value.absent(),
                Value<String?> analiseId = const Value.absent(),
              }) => EnviosCompanion.insert(
                posicao: posicao,
                id: id,
                pacienteId: pacienteId,
                nomeDoPaciente: nomeDoPaciente,
                sessaoId: sessaoId,
                criadoEm: criadoEm,
                situacao: situacao,
                tentativas: tentativas,
                proximaTentativa: proximaTentativa,
                ultimaFalha: ultimaFalha,
                analiseId: analiseId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EnviosTable, LinhaDoEnvio>(table),
                  $$EnviosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({amostrasDoEnvioRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (amostrasDoEnvioRefs) db.amostrasDoEnvio,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (amostrasDoEnvioRefs)
                    await $_getPrefetchedData<
                      LinhaDoEnvio,
                      $EnviosTable,
                      LinhaDaAmostraDoEnvio
                    >(
                      currentTable: table,
                      referencedTable: $$EnviosTableReferences
                          ._amostrasDoEnvioRefsTable(db),
                      managerFromTypedResult: (p0) => $$EnviosTableReferences(
                        db,
                        table,
                        p0,
                      ).amostrasDoEnvioRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.envioId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EnviosTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $EnviosTable,
      LinhaDoEnvio,
      $$EnviosTableFilterComposer,
      $$EnviosTableOrderingComposer,
      $$EnviosTableAnnotationComposer,
      $$EnviosTableCreateCompanionBuilder,
      $$EnviosTableUpdateCompanionBuilder,
      (LinhaDoEnvio, $$EnviosTableReferences),
      LinhaDoEnvio,
      PrefetchHooks Function({bool amostrasDoEnvioRefs})
    >;
typedef $$AmostrasTableCreateCompanionBuilder = AmostrasCompanion Function({
  required String id,
  required String pacienteId,
  required String sessaoId,
  required String tarefa,
  required String caminho,
  required DateTime gravadaEm,
  required int duracaoEmMs,
  required int taxaDeAmostragem,
  required int canais,
  required String problemas,
  Value<int> rowid,
});
typedef $$AmostrasTableUpdateCompanionBuilder = AmostrasCompanion Function({
  Value<String> id,
  Value<String> pacienteId,
  Value<String> sessaoId,
  Value<String> tarefa,
  Value<String> caminho,
  Value<DateTime> gravadaEm,
  Value<int> duracaoEmMs,
  Value<int> taxaDeAmostragem,
  Value<int> canais,
  Value<String> problemas,
  Value<int> rowid,
});

final class $$AmostrasTableReferences
    extends BaseReferences<_$BancoLocal, $AmostrasTable, LinhaDaAmostra> {
  $$AmostrasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AmostrasDoEnvioTable, List<LinhaDaAmostraDoEnvio>>
  _amostrasDoEnvioRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.amostrasDoEnvio,
    aliasName: 'amostras__id__amostras_do_envio__amostra_id',
  );

  $$AmostrasDoEnvioTableProcessedTableManager get amostrasDoEnvioRefs {
    final manager = $$AmostrasDoEnvioTableTableManager(
      $_db,
      $_db.amostrasDoEnvio,
    ).filter((f) => f.amostraId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _amostrasDoEnvioRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AmostrasTableFilterComposer
    extends Composer<_$BancoLocal, $AmostrasTable> {
  $$AmostrasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessaoId => $composableBuilder(
    column: $table.sessaoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tarefa => $composableBuilder(
    column: $table.tarefa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caminho => $composableBuilder(
    column: $table.caminho,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get gravadaEm => $composableBuilder(
    column: $table.gravadaEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duracaoEmMs => $composableBuilder(
    column: $table.duracaoEmMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxaDeAmostragem => $composableBuilder(
    column: $table.taxaDeAmostragem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get canais => $composableBuilder(
    column: $table.canais,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get problemas => $composableBuilder(
    column: $table.problemas,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> amostrasDoEnvioRefs(
    Expression<bool> Function($$AmostrasDoEnvioTableFilterComposer f) f,
  ) {
    final $$AmostrasDoEnvioTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amostrasDoEnvio,
      getReferencedColumn: (t) => t.amostraId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmostrasDoEnvioTableFilterComposer(
            $db: $db,
            $table: $db.amostrasDoEnvio,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AmostrasTableOrderingComposer
    extends Composer<_$BancoLocal, $AmostrasTable> {
  $$AmostrasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessaoId => $composableBuilder(
    column: $table.sessaoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tarefa => $composableBuilder(
    column: $table.tarefa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caminho => $composableBuilder(
    column: $table.caminho,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get gravadaEm => $composableBuilder(
    column: $table.gravadaEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duracaoEmMs => $composableBuilder(
    column: $table.duracaoEmMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxaDeAmostragem => $composableBuilder(
    column: $table.taxaDeAmostragem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get canais => $composableBuilder(
    column: $table.canais,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get problemas => $composableBuilder(
    column: $table.problemas,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AmostrasTableAnnotationComposer
    extends Composer<_$BancoLocal, $AmostrasTable> {
  $$AmostrasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessaoId =>
      $composableBuilder(column: $table.sessaoId, builder: (column) => column);

  GeneratedColumn<String> get tarefa =>
      $composableBuilder(column: $table.tarefa, builder: (column) => column);

  GeneratedColumn<String> get caminho =>
      $composableBuilder(column: $table.caminho, builder: (column) => column);

  GeneratedColumn<DateTime> get gravadaEm =>
      $composableBuilder(column: $table.gravadaEm, builder: (column) => column);

  GeneratedColumn<int> get duracaoEmMs => $composableBuilder(
    column: $table.duracaoEmMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxaDeAmostragem => $composableBuilder(
    column: $table.taxaDeAmostragem,
    builder: (column) => column,
  );

  GeneratedColumn<int> get canais =>
      $composableBuilder(column: $table.canais, builder: (column) => column);

  GeneratedColumn<String> get problemas =>
      $composableBuilder(column: $table.problemas, builder: (column) => column);

  Expression<T> amostrasDoEnvioRefs<T extends Object>(
    Expression<T> Function($$AmostrasDoEnvioTableAnnotationComposer a) f,
  ) {
    final $$AmostrasDoEnvioTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amostrasDoEnvio,
      getReferencedColumn: (t) => t.amostraId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmostrasDoEnvioTableAnnotationComposer(
            $db: $db,
            $table: $db.amostrasDoEnvio,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AmostrasTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $AmostrasTable,
          LinhaDaAmostra,
          $$AmostrasTableFilterComposer,
          $$AmostrasTableOrderingComposer,
          $$AmostrasTableAnnotationComposer,
          $$AmostrasTableCreateCompanionBuilder,
          $$AmostrasTableUpdateCompanionBuilder,
          (LinhaDaAmostra, $$AmostrasTableReferences),
          LinhaDaAmostra,
          PrefetchHooks Function({bool amostrasDoEnvioRefs})
        > {
  $$AmostrasTableTableManager(_$BancoLocal db, $AmostrasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmostrasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmostrasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmostrasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pacienteId = const Value.absent(),
                Value<String> sessaoId = const Value.absent(),
                Value<String> tarefa = const Value.absent(),
                Value<String> caminho = const Value.absent(),
                Value<DateTime> gravadaEm = const Value.absent(),
                Value<int> duracaoEmMs = const Value.absent(),
                Value<int> taxaDeAmostragem = const Value.absent(),
                Value<int> canais = const Value.absent(),
                Value<String> problemas = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmostrasCompanion(
                id: id,
                pacienteId: pacienteId,
                sessaoId: sessaoId,
                tarefa: tarefa,
                caminho: caminho,
                gravadaEm: gravadaEm,
                duracaoEmMs: duracaoEmMs,
                taxaDeAmostragem: taxaDeAmostragem,
                canais: canais,
                problemas: problemas,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pacienteId,
                required String sessaoId,
                required String tarefa,
                required String caminho,
                required DateTime gravadaEm,
                required int duracaoEmMs,
                required int taxaDeAmostragem,
                required int canais,
                required String problemas,
                Value<int> rowid = const Value.absent(),
              }) => AmostrasCompanion.insert(
                id: id,
                pacienteId: pacienteId,
                sessaoId: sessaoId,
                tarefa: tarefa,
                caminho: caminho,
                gravadaEm: gravadaEm,
                duracaoEmMs: duracaoEmMs,
                taxaDeAmostragem: taxaDeAmostragem,
                canais: canais,
                problemas: problemas,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AmostrasTable, LinhaDaAmostra>(table),
                  $$AmostrasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({amostrasDoEnvioRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (amostrasDoEnvioRefs) db.amostrasDoEnvio,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (amostrasDoEnvioRefs)
                    await $_getPrefetchedData<
                      LinhaDaAmostra,
                      $AmostrasTable,
                      LinhaDaAmostraDoEnvio
                    >(
                      currentTable: table,
                      referencedTable: $$AmostrasTableReferences
                          ._amostrasDoEnvioRefsTable(db),
                      managerFromTypedResult: (p0) => $$AmostrasTableReferences(
                        db,
                        table,
                        p0,
                      ).amostrasDoEnvioRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.amostraId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AmostrasTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $AmostrasTable,
      LinhaDaAmostra,
      $$AmostrasTableFilterComposer,
      $$AmostrasTableOrderingComposer,
      $$AmostrasTableAnnotationComposer,
      $$AmostrasTableCreateCompanionBuilder,
      $$AmostrasTableUpdateCompanionBuilder,
      (LinhaDaAmostra, $$AmostrasTableReferences),
      LinhaDaAmostra,
      PrefetchHooks Function({bool amostrasDoEnvioRefs})
    >;
typedef $$AmostrasDoEnvioTableCreateCompanionBuilder =
    AmostrasDoEnvioCompanion Function({
      required String envioId,
      required String amostraId,
      required int ordem,
      Value<int> rowid,
    });
typedef $$AmostrasDoEnvioTableUpdateCompanionBuilder =
    AmostrasDoEnvioCompanion Function({
      Value<String> envioId,
      Value<String> amostraId,
      Value<int> ordem,
      Value<int> rowid,
    });

final class $$AmostrasDoEnvioTableReferences
    extends
        BaseReferences<
          _$BancoLocal,
          $AmostrasDoEnvioTable,
          LinhaDaAmostraDoEnvio
        > {
  $$AmostrasDoEnvioTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EnviosTable _envioIdTable(_$BancoLocal db) =>
      db.envios.createAlias('amostras_do_envio__envio_id__envios__id');

  $$EnviosTableProcessedTableManager get envioId {
    final $_column = $_itemColumn<String>('envio_id')!;

    final manager = $$EnviosTableTableManager(
      $_db,
      $_db.envios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_envioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AmostrasTable _amostraIdTable(_$BancoLocal db) =>
      db.amostras.createAlias('amostras_do_envio__amostra_id__amostras__id');

  $$AmostrasTableProcessedTableManager get amostraId {
    final $_column = $_itemColumn<String>('amostra_id')!;

    final manager = $$AmostrasTableTableManager(
      $_db,
      $_db.amostras,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_amostraIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AmostrasDoEnvioTableFilterComposer
    extends Composer<_$BancoLocal, $AmostrasDoEnvioTable> {
  $$AmostrasDoEnvioTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnFilters(column),
  );

  $$EnviosTableFilterComposer get envioId {
    final $$EnviosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.envioId,
      referencedTable: $db.envios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnviosTableFilterComposer(
            $db: $db,
            $table: $db.envios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmostrasTableFilterComposer get amostraId {
    final $$AmostrasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.amostraId,
      referencedTable: $db.amostras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmostrasTableFilterComposer(
            $db: $db,
            $table: $db.amostras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmostrasDoEnvioTableOrderingComposer
    extends Composer<_$BancoLocal, $AmostrasDoEnvioTable> {
  $$AmostrasDoEnvioTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnOrderings(column),
  );

  $$EnviosTableOrderingComposer get envioId {
    final $$EnviosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.envioId,
      referencedTable: $db.envios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnviosTableOrderingComposer(
            $db: $db,
            $table: $db.envios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmostrasTableOrderingComposer get amostraId {
    final $$AmostrasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.amostraId,
      referencedTable: $db.amostras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmostrasTableOrderingComposer(
            $db: $db,
            $table: $db.amostras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmostrasDoEnvioTableAnnotationComposer
    extends Composer<_$BancoLocal, $AmostrasDoEnvioTable> {
  $$AmostrasDoEnvioTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  $$EnviosTableAnnotationComposer get envioId {
    final $$EnviosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.envioId,
      referencedTable: $db.envios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnviosTableAnnotationComposer(
            $db: $db,
            $table: $db.envios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AmostrasTableAnnotationComposer get amostraId {
    final $$AmostrasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.amostraId,
      referencedTable: $db.amostras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmostrasTableAnnotationComposer(
            $db: $db,
            $table: $db.amostras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmostrasDoEnvioTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $AmostrasDoEnvioTable,
          LinhaDaAmostraDoEnvio,
          $$AmostrasDoEnvioTableFilterComposer,
          $$AmostrasDoEnvioTableOrderingComposer,
          $$AmostrasDoEnvioTableAnnotationComposer,
          $$AmostrasDoEnvioTableCreateCompanionBuilder,
          $$AmostrasDoEnvioTableUpdateCompanionBuilder,
          (LinhaDaAmostraDoEnvio, $$AmostrasDoEnvioTableReferences),
          LinhaDaAmostraDoEnvio,
          PrefetchHooks Function({bool envioId, bool amostraId})
        > {
  $$AmostrasDoEnvioTableTableManager(
    _$BancoLocal db,
    $AmostrasDoEnvioTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmostrasDoEnvioTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmostrasDoEnvioTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmostrasDoEnvioTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> envioId = const Value.absent(),
                Value<String> amostraId = const Value.absent(),
                Value<int> ordem = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmostrasDoEnvioCompanion(
                envioId: envioId,
                amostraId: amostraId,
                ordem: ordem,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String envioId,
                required String amostraId,
                required int ordem,
                Value<int> rowid = const Value.absent(),
              }) => AmostrasDoEnvioCompanion.insert(
                envioId: envioId,
                amostraId: amostraId,
                ordem: ordem,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AmostrasDoEnvioTable, LinhaDaAmostraDoEnvio>(
                    table,
                  ),
                  $$AmostrasDoEnvioTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({envioId = false, amostraId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (envioId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.envioId,
                        referencedTable: $$AmostrasDoEnvioTableReferences
                            ._envioIdTable(db),
                        referencedColumn: $$AmostrasDoEnvioTableReferences
                            ._envioIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (amostraId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.amostraId,
                        referencedTable: $$AmostrasDoEnvioTableReferences
                            ._amostraIdTable(db),
                        referencedColumn: $$AmostrasDoEnvioTableReferences
                            ._amostraIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AmostrasDoEnvioTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $AmostrasDoEnvioTable,
      LinhaDaAmostraDoEnvio,
      $$AmostrasDoEnvioTableFilterComposer,
      $$AmostrasDoEnvioTableOrderingComposer,
      $$AmostrasDoEnvioTableAnnotationComposer,
      $$AmostrasDoEnvioTableCreateCompanionBuilder,
      $$AmostrasDoEnvioTableUpdateCompanionBuilder,
      (LinhaDaAmostraDoEnvio, $$AmostrasDoEnvioTableReferences),
      LinhaDaAmostraDoEnvio,
      PrefetchHooks Function({bool envioId, bool amostraId})
    >;
typedef $$AvaliacoesCapeVTableCreateCompanionBuilder =
    AvaliacoesCapeVCompanion Function({
      required String analiseId,
      required String pacienteId,
      required DateTime registradaEm,
      required String comentarios,
      Value<int> rowid,
    });
typedef $$AvaliacoesCapeVTableUpdateCompanionBuilder =
    AvaliacoesCapeVCompanion Function({
      Value<String> analiseId,
      Value<String> pacienteId,
      Value<DateTime> registradaEm,
      Value<String> comentarios,
      Value<int> rowid,
    });

final class $$AvaliacoesCapeVTableReferences
    extends
        BaseReferences<
          _$BancoLocal,
          $AvaliacoesCapeVTable,
          LinhaDaAvaliacaoCapeV
        > {
  $$AvaliacoesCapeVTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$NotasCapeVTable, List<LinhaDaNotaCapeV>>
  _notasCapeVRefsTable(_$BancoLocal db) => MultiTypedResultKey.fromTable(
    db.notasCapeV,
    aliasName: 'avaliacoes_cape_v__analise_id__notas_cape_v__analise_id',
  );

  $$NotasCapeVTableProcessedTableManager get notasCapeVRefs {
    final manager = $$NotasCapeVTableTableManager($_db, $_db.notasCapeV).filter(
      (f) =>
          f.analiseId.analiseId.sqlEquals($_itemColumn<String>('analise_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_notasCapeVRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AvaliacoesCapeVTableFilterComposer
    extends Composer<_$BancoLocal, $AvaliacoesCapeVTable> {
  $$AvaliacoesCapeVTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get analiseId => $composableBuilder(
    column: $table.analiseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registradaEm => $composableBuilder(
    column: $table.registradaEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comentarios => $composableBuilder(
    column: $table.comentarios,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> notasCapeVRefs(
    Expression<bool> Function($$NotasCapeVTableFilterComposer f) f,
  ) {
    final $$NotasCapeVTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analiseId,
      referencedTable: $db.notasCapeV,
      getReferencedColumn: (t) => t.analiseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasCapeVTableFilterComposer(
            $db: $db,
            $table: $db.notasCapeV,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AvaliacoesCapeVTableOrderingComposer
    extends Composer<_$BancoLocal, $AvaliacoesCapeVTable> {
  $$AvaliacoesCapeVTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get analiseId => $composableBuilder(
    column: $table.analiseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registradaEm => $composableBuilder(
    column: $table.registradaEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comentarios => $composableBuilder(
    column: $table.comentarios,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AvaliacoesCapeVTableAnnotationComposer
    extends Composer<_$BancoLocal, $AvaliacoesCapeVTable> {
  $$AvaliacoesCapeVTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get analiseId =>
      $composableBuilder(column: $table.analiseId, builder: (column) => column);

  GeneratedColumn<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get registradaEm => $composableBuilder(
    column: $table.registradaEm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comentarios => $composableBuilder(
    column: $table.comentarios,
    builder: (column) => column,
  );

  Expression<T> notasCapeVRefs<T extends Object>(
    Expression<T> Function($$NotasCapeVTableAnnotationComposer a) f,
  ) {
    final $$NotasCapeVTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analiseId,
      referencedTable: $db.notasCapeV,
      getReferencedColumn: (t) => t.analiseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotasCapeVTableAnnotationComposer(
            $db: $db,
            $table: $db.notasCapeV,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AvaliacoesCapeVTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $AvaliacoesCapeVTable,
          LinhaDaAvaliacaoCapeV,
          $$AvaliacoesCapeVTableFilterComposer,
          $$AvaliacoesCapeVTableOrderingComposer,
          $$AvaliacoesCapeVTableAnnotationComposer,
          $$AvaliacoesCapeVTableCreateCompanionBuilder,
          $$AvaliacoesCapeVTableUpdateCompanionBuilder,
          (LinhaDaAvaliacaoCapeV, $$AvaliacoesCapeVTableReferences),
          LinhaDaAvaliacaoCapeV,
          PrefetchHooks Function({bool notasCapeVRefs})
        > {
  $$AvaliacoesCapeVTableTableManager(
    _$BancoLocal db,
    $AvaliacoesCapeVTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AvaliacoesCapeVTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AvaliacoesCapeVTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AvaliacoesCapeVTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> analiseId = const Value.absent(),
                Value<String> pacienteId = const Value.absent(),
                Value<DateTime> registradaEm = const Value.absent(),
                Value<String> comentarios = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AvaliacoesCapeVCompanion(
                analiseId: analiseId,
                pacienteId: pacienteId,
                registradaEm: registradaEm,
                comentarios: comentarios,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String analiseId,
                required String pacienteId,
                required DateTime registradaEm,
                required String comentarios,
                Value<int> rowid = const Value.absent(),
              }) => AvaliacoesCapeVCompanion.insert(
                analiseId: analiseId,
                pacienteId: pacienteId,
                registradaEm: registradaEm,
                comentarios: comentarios,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AvaliacoesCapeVTable, LinhaDaAvaliacaoCapeV>(
                    table,
                  ),
                  $$AvaliacoesCapeVTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notasCapeVRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (notasCapeVRefs) db.notasCapeV],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notasCapeVRefs)
                    await $_getPrefetchedData<
                      LinhaDaAvaliacaoCapeV,
                      $AvaliacoesCapeVTable,
                      LinhaDaNotaCapeV
                    >(
                      currentTable: table,
                      referencedTable: $$AvaliacoesCapeVTableReferences
                          ._notasCapeVRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AvaliacoesCapeVTableReferences(
                            db,
                            table,
                            p0,
                          ).notasCapeVRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.analiseId == item.analiseId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AvaliacoesCapeVTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $AvaliacoesCapeVTable,
      LinhaDaAvaliacaoCapeV,
      $$AvaliacoesCapeVTableFilterComposer,
      $$AvaliacoesCapeVTableOrderingComposer,
      $$AvaliacoesCapeVTableAnnotationComposer,
      $$AvaliacoesCapeVTableCreateCompanionBuilder,
      $$AvaliacoesCapeVTableUpdateCompanionBuilder,
      (LinhaDaAvaliacaoCapeV, $$AvaliacoesCapeVTableReferences),
      LinhaDaAvaliacaoCapeV,
      PrefetchHooks Function({bool notasCapeVRefs})
    >;
typedef $$NotasCapeVTableCreateCompanionBuilder = NotasCapeVCompanion Function({
  required String analiseId,
  required String parametro,
  Value<int?> valor,
  Value<String?> consistencia,
  Value<String?> direcao,
  Value<int> rowid,
});
typedef $$NotasCapeVTableUpdateCompanionBuilder = NotasCapeVCompanion Function({
  Value<String> analiseId,
  Value<String> parametro,
  Value<int?> valor,
  Value<String?> consistencia,
  Value<String?> direcao,
  Value<int> rowid,
});

final class $$NotasCapeVTableReferences
    extends BaseReferences<_$BancoLocal, $NotasCapeVTable, LinhaDaNotaCapeV> {
  $$NotasCapeVTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AvaliacoesCapeVTable _analiseIdTable(_$BancoLocal db) => db
      .avaliacoesCapeV
      .createAlias('notas_cape_v__analise_id__avaliacoes_cape_v__analise_id');

  $$AvaliacoesCapeVTableProcessedTableManager get analiseId {
    final $_column = $_itemColumn<String>('analise_id')!;

    final manager = $$AvaliacoesCapeVTableTableManager(
      $_db,
      $_db.avaliacoesCapeV,
    ).filter((f) => f.analiseId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_analiseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotasCapeVTableFilterComposer
    extends Composer<_$BancoLocal, $NotasCapeVTable> {
  $$NotasCapeVTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get parametro => $composableBuilder(
    column: $table.parametro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consistencia => $composableBuilder(
    column: $table.consistencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direcao => $composableBuilder(
    column: $table.direcao,
    builder: (column) => ColumnFilters(column),
  );

  $$AvaliacoesCapeVTableFilterComposer get analiseId {
    final $$AvaliacoesCapeVTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analiseId,
      referencedTable: $db.avaliacoesCapeV,
      getReferencedColumn: (t) => t.analiseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AvaliacoesCapeVTableFilterComposer(
            $db: $db,
            $table: $db.avaliacoesCapeV,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotasCapeVTableOrderingComposer
    extends Composer<_$BancoLocal, $NotasCapeVTable> {
  $$NotasCapeVTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get parametro => $composableBuilder(
    column: $table.parametro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consistencia => $composableBuilder(
    column: $table.consistencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direcao => $composableBuilder(
    column: $table.direcao,
    builder: (column) => ColumnOrderings(column),
  );

  $$AvaliacoesCapeVTableOrderingComposer get analiseId {
    final $$AvaliacoesCapeVTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analiseId,
      referencedTable: $db.avaliacoesCapeV,
      getReferencedColumn: (t) => t.analiseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AvaliacoesCapeVTableOrderingComposer(
            $db: $db,
            $table: $db.avaliacoesCapeV,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotasCapeVTableAnnotationComposer
    extends Composer<_$BancoLocal, $NotasCapeVTable> {
  $$NotasCapeVTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get parametro =>
      $composableBuilder(column: $table.parametro, builder: (column) => column);

  GeneratedColumn<int> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get consistencia => $composableBuilder(
    column: $table.consistencia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direcao =>
      $composableBuilder(column: $table.direcao, builder: (column) => column);

  $$AvaliacoesCapeVTableAnnotationComposer get analiseId {
    final $$AvaliacoesCapeVTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.analiseId,
      referencedTable: $db.avaliacoesCapeV,
      getReferencedColumn: (t) => t.analiseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AvaliacoesCapeVTableAnnotationComposer(
            $db: $db,
            $table: $db.avaliacoesCapeV,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotasCapeVTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $NotasCapeVTable,
          LinhaDaNotaCapeV,
          $$NotasCapeVTableFilterComposer,
          $$NotasCapeVTableOrderingComposer,
          $$NotasCapeVTableAnnotationComposer,
          $$NotasCapeVTableCreateCompanionBuilder,
          $$NotasCapeVTableUpdateCompanionBuilder,
          (LinhaDaNotaCapeV, $$NotasCapeVTableReferences),
          LinhaDaNotaCapeV,
          PrefetchHooks Function({bool analiseId})
        > {
  $$NotasCapeVTableTableManager(_$BancoLocal db, $NotasCapeVTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotasCapeVTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotasCapeVTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotasCapeVTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> analiseId = const Value.absent(),
                Value<String> parametro = const Value.absent(),
                Value<int?> valor = const Value.absent(),
                Value<String?> consistencia = const Value.absent(),
                Value<String?> direcao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotasCapeVCompanion(
                analiseId: analiseId,
                parametro: parametro,
                valor: valor,
                consistencia: consistencia,
                direcao: direcao,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String analiseId,
                required String parametro,
                Value<int?> valor = const Value.absent(),
                Value<String?> consistencia = const Value.absent(),
                Value<String?> direcao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotasCapeVCompanion.insert(
                analiseId: analiseId,
                parametro: parametro,
                valor: valor,
                consistencia: consistencia,
                direcao: direcao,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotasCapeVTable, LinhaDaNotaCapeV>(table),
                  $$NotasCapeVTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({analiseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (analiseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.analiseId,
                        referencedTable: $$NotasCapeVTableReferences
                            ._analiseIdTable(db),
                        referencedColumn: $$NotasCapeVTableReferences
                            ._analiseIdTable(db)
                            .analiseId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotasCapeVTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $NotasCapeVTable,
      LinhaDaNotaCapeV,
      $$NotasCapeVTableFilterComposer,
      $$NotasCapeVTableOrderingComposer,
      $$NotasCapeVTableAnnotationComposer,
      $$NotasCapeVTableCreateCompanionBuilder,
      $$NotasCapeVTableUpdateCompanionBuilder,
      (LinhaDaNotaCapeV, $$NotasCapeVTableReferences),
      LinhaDaNotaCapeV,
      PrefetchHooks Function({bool analiseId})
    >;
typedef $$LaudosTableCreateCompanionBuilder = LaudosCompanion Function({
  required String analiseId,
  required String pacienteId,
  required String conclusao,
  required DateTime geradoEm,
  required Uint8List pdf,
  Value<int> rowid,
});
typedef $$LaudosTableUpdateCompanionBuilder = LaudosCompanion Function({
  Value<String> analiseId,
  Value<String> pacienteId,
  Value<String> conclusao,
  Value<DateTime> geradoEm,
  Value<Uint8List> pdf,
  Value<int> rowid,
});

class $$LaudosTableFilterComposer extends Composer<_$BancoLocal, $LaudosTable> {
  $$LaudosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get analiseId => $composableBuilder(
    column: $table.analiseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conclusao => $composableBuilder(
    column: $table.conclusao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get geradoEm => $composableBuilder(
    column: $table.geradoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get pdf => $composableBuilder(
    column: $table.pdf,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LaudosTableOrderingComposer
    extends Composer<_$BancoLocal, $LaudosTable> {
  $$LaudosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get analiseId => $composableBuilder(
    column: $table.analiseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conclusao => $composableBuilder(
    column: $table.conclusao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get geradoEm => $composableBuilder(
    column: $table.geradoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get pdf => $composableBuilder(
    column: $table.pdf,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LaudosTableAnnotationComposer
    extends Composer<_$BancoLocal, $LaudosTable> {
  $$LaudosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get analiseId =>
      $composableBuilder(column: $table.analiseId, builder: (column) => column);

  GeneratedColumn<String> get pacienteId => $composableBuilder(
    column: $table.pacienteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conclusao =>
      $composableBuilder(column: $table.conclusao, builder: (column) => column);

  GeneratedColumn<DateTime> get geradoEm =>
      $composableBuilder(column: $table.geradoEm, builder: (column) => column);

  GeneratedColumn<Uint8List> get pdf =>
      $composableBuilder(column: $table.pdf, builder: (column) => column);
}

class $$LaudosTableTableManager
    extends
        RootTableManager<
          _$BancoLocal,
          $LaudosTable,
          LinhaDoLaudo,
          $$LaudosTableFilterComposer,
          $$LaudosTableOrderingComposer,
          $$LaudosTableAnnotationComposer,
          $$LaudosTableCreateCompanionBuilder,
          $$LaudosTableUpdateCompanionBuilder,
          (
            LinhaDoLaudo,
            BaseReferences<_$BancoLocal, $LaudosTable, LinhaDoLaudo>,
          ),
          LinhaDoLaudo,
          PrefetchHooks Function()
        > {
  $$LaudosTableTableManager(_$BancoLocal db, $LaudosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LaudosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LaudosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LaudosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> analiseId = const Value.absent(),
                Value<String> pacienteId = const Value.absent(),
                Value<String> conclusao = const Value.absent(),
                Value<DateTime> geradoEm = const Value.absent(),
                Value<Uint8List> pdf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LaudosCompanion(
                analiseId: analiseId,
                pacienteId: pacienteId,
                conclusao: conclusao,
                geradoEm: geradoEm,
                pdf: pdf,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String analiseId,
                required String pacienteId,
                required String conclusao,
                required DateTime geradoEm,
                required Uint8List pdf,
                Value<int> rowid = const Value.absent(),
              }) => LaudosCompanion.insert(
                analiseId: analiseId,
                pacienteId: pacienteId,
                conclusao: conclusao,
                geradoEm: geradoEm,
                pdf: pdf,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LaudosTable, LinhaDoLaudo>(table),
                  BaseReferences<_$BancoLocal, $LaudosTable, LinhaDoLaudo>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LaudosTableProcessedTableManager =
    ProcessedTableManager<
      _$BancoLocal,
      $LaudosTable,
      LinhaDoLaudo,
      $$LaudosTableFilterComposer,
      $$LaudosTableOrderingComposer,
      $$LaudosTableAnnotationComposer,
      $$LaudosTableCreateCompanionBuilder,
      $$LaudosTableUpdateCompanionBuilder,
      (LinhaDoLaudo, BaseReferences<_$BancoLocal, $LaudosTable, LinhaDoLaudo>),
      LinhaDoLaudo,
      PrefetchHooks Function()
    >;

class $BancoLocalManager {
  final _$BancoLocal _db;
  $BancoLocalManager(this._db);
  $$PacientesTableTableManager get pacientes =>
      $$PacientesTableTableManager(_db, _db.pacientes);
  $$ConsentimentosTableTableManager get consentimentos =>
      $$ConsentimentosTableTableManager(_db, _db.consentimentos);
  $$RetiradasDeConsentimentoTableTableManager get retiradasDeConsentimento =>
      $$RetiradasDeConsentimentoTableTableManager(
        _db,
        _db.retiradasDeConsentimento,
      );
  $$EnviosTableTableManager get envios =>
      $$EnviosTableTableManager(_db, _db.envios);
  $$AmostrasTableTableManager get amostras =>
      $$AmostrasTableTableManager(_db, _db.amostras);
  $$AmostrasDoEnvioTableTableManager get amostrasDoEnvio =>
      $$AmostrasDoEnvioTableTableManager(_db, _db.amostrasDoEnvio);
  $$AvaliacoesCapeVTableTableManager get avaliacoesCapeV =>
      $$AvaliacoesCapeVTableTableManager(_db, _db.avaliacoesCapeV);
  $$NotasCapeVTableTableManager get notasCapeV =>
      $$NotasCapeVTableTableManager(_db, _db.notasCapeV);
  $$LaudosTableTableManager get laudos =>
      $$LaudosTableTableManager(_db, _db.laudos);
}
