// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'axpert_database.dart';

// ignore_for_file: type=lint
class $DeviceContextEntriesTable extends DeviceContextEntries
    with TableInfo<$DeviceContextEntriesTable, DeviceContextEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceContextEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outletIdMeta = const VerificationMeta(
    'outletId',
  );
  @override
  late final GeneratedColumn<String> outletId = GeneratedColumn<String>(
    'outlet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registerIdMeta = const VerificationMeta(
    'registerId',
  );
  @override
  late final GeneratedColumn<String> registerId = GeneratedColumn<String>(
    'register_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    deviceId,
    outletId,
    registerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_context_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceContextEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('outlet_id')) {
      context.handle(
        _outletIdMeta,
        outletId.isAcceptableOrUnknown(data['outlet_id']!, _outletIdMeta),
      );
    }
    if (data.containsKey('register_id')) {
      context.handle(
        _registerIdMeta,
        registerId.isAcceptableOrUnknown(data['register_id']!, _registerIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  DeviceContextEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceContextEntry(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      outletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outlet_id'],
      ),
      registerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}register_id'],
      ),
    );
  }

  @override
  $DeviceContextEntriesTable createAlias(String alias) {
    return $DeviceContextEntriesTable(attachedDatabase, alias);
  }
}

class DeviceContextEntry extends DataClass
    implements Insertable<DeviceContextEntry> {
  final int singletonId;
  final String deviceId;
  final String? outletId;
  final String? registerId;
  const DeviceContextEntry({
    required this.singletonId,
    required this.deviceId,
    this.outletId,
    this.registerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || outletId != null) {
      map['outlet_id'] = Variable<String>(outletId);
    }
    if (!nullToAbsent || registerId != null) {
      map['register_id'] = Variable<String>(registerId);
    }
    return map;
  }

  DeviceContextEntriesCompanion toCompanion(bool nullToAbsent) {
    return DeviceContextEntriesCompanion(
      singletonId: Value(singletonId),
      deviceId: Value(deviceId),
      outletId: outletId == null && nullToAbsent
          ? const Value.absent()
          : Value(outletId),
      registerId: registerId == null && nullToAbsent
          ? const Value.absent()
          : Value(registerId),
    );
  }

  factory DeviceContextEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceContextEntry(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      outletId: serializer.fromJson<String?>(json['outletId']),
      registerId: serializer.fromJson<String?>(json['registerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'deviceId': serializer.toJson<String>(deviceId),
      'outletId': serializer.toJson<String?>(outletId),
      'registerId': serializer.toJson<String?>(registerId),
    };
  }

  DeviceContextEntry copyWith({
    int? singletonId,
    String? deviceId,
    Value<String?> outletId = const Value.absent(),
    Value<String?> registerId = const Value.absent(),
  }) => DeviceContextEntry(
    singletonId: singletonId ?? this.singletonId,
    deviceId: deviceId ?? this.deviceId,
    outletId: outletId.present ? outletId.value : this.outletId,
    registerId: registerId.present ? registerId.value : this.registerId,
  );
  DeviceContextEntry copyWithCompanion(DeviceContextEntriesCompanion data) {
    return DeviceContextEntry(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      outletId: data.outletId.present ? data.outletId.value : this.outletId,
      registerId: data.registerId.present
          ? data.registerId.value
          : this.registerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceContextEntry(')
          ..write('singletonId: $singletonId, ')
          ..write('deviceId: $deviceId, ')
          ..write('outletId: $outletId, ')
          ..write('registerId: $registerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(singletonId, deviceId, outletId, registerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceContextEntry &&
          other.singletonId == this.singletonId &&
          other.deviceId == this.deviceId &&
          other.outletId == this.outletId &&
          other.registerId == this.registerId);
}

class DeviceContextEntriesCompanion
    extends UpdateCompanion<DeviceContextEntry> {
  final Value<int> singletonId;
  final Value<String> deviceId;
  final Value<String?> outletId;
  final Value<String?> registerId;
  const DeviceContextEntriesCompanion({
    this.singletonId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.outletId = const Value.absent(),
    this.registerId = const Value.absent(),
  });
  DeviceContextEntriesCompanion.insert({
    this.singletonId = const Value.absent(),
    required String deviceId,
    this.outletId = const Value.absent(),
    this.registerId = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<DeviceContextEntry> custom({
    Expression<int>? singletonId,
    Expression<String>? deviceId,
    Expression<String>? outletId,
    Expression<String>? registerId,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (deviceId != null) 'device_id': deviceId,
      if (outletId != null) 'outlet_id': outletId,
      if (registerId != null) 'register_id': registerId,
    });
  }

  DeviceContextEntriesCompanion copyWith({
    Value<int>? singletonId,
    Value<String>? deviceId,
    Value<String?>? outletId,
    Value<String?>? registerId,
  }) {
    return DeviceContextEntriesCompanion(
      singletonId: singletonId ?? this.singletonId,
      deviceId: deviceId ?? this.deviceId,
      outletId: outletId ?? this.outletId,
      registerId: registerId ?? this.registerId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (outletId.present) {
      map['outlet_id'] = Variable<String>(outletId.value);
    }
    if (registerId.present) {
      map['register_id'] = Variable<String>(registerId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceContextEntriesCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('deviceId: $deviceId, ')
          ..write('outletId: $outletId, ')
          ..write('registerId: $registerId')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String valueJson;

  /// UTC ISO 8601 text.
  final String updatedAt;
  const SettingsEntry({
    required this.key,
    required this.valueJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SettingsEntry copyWith({String? key, String? valueJson, String? updatedAt}) =>
      SettingsEntry(
        key: key ?? this.key,
        valueJson: valueJson ?? this.valueJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String valueJson,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MigrationStateEntriesTable extends MigrationStateEntries
    with TableInfo<$MigrationStateEntriesTable, MigrationStateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationStateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationStateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MigrationStateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationStateEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MigrationStateEntriesTable createAlias(String alias) {
    return $MigrationStateEntriesTable(attachedDatabase, alias);
  }
}

class MigrationStateEntry extends DataClass
    implements Insertable<MigrationStateEntry> {
  final String key;
  final String value;
  const MigrationStateEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MigrationStateEntriesCompanion toCompanion(bool nullToAbsent) {
    return MigrationStateEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory MigrationStateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationStateEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MigrationStateEntry copyWith({String? key, String? value}) =>
      MigrationStateEntry(key: key ?? this.key, value: value ?? this.value);
  MigrationStateEntry copyWithCompanion(MigrationStateEntriesCompanion data) {
    return MigrationStateEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationStateEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationStateEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class MigrationStateEntriesCompanion
    extends UpdateCompanion<MigrationStateEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MigrationStateEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationStateEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MigrationStateEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationStateEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MigrationStateEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationStateEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerEntriesTable extends CustomerEntries
    with TableInfo<$CustomerEntriesTable, CustomerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<String> legacyId = GeneratedColumn<String>(
    'legacy_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberNoMeta = const VerificationMeta(
    'memberNo',
  );
  @override
  late final GeneratedColumn<String> memberNo = GeneratedColumn<String>(
    'member_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    legacyId,
    position,
    name,
    phone,
    email,
    memberNo,
    points,
    createdAt,
    updatedAt,
    deletedAt,
    serverId,
    serverVersion,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_legacyIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('member_no')) {
      context.handle(
        _memberNoMeta,
        memberNo.isAcceptableOrUnknown(data['member_no']!, _memberNoMeta),
      );
    } else if (isInserting) {
      context.missing(_memberNoMeta);
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      memberNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_no'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $CustomerEntriesTable createAlias(String alias) {
    return $CustomerEntriesTable(attachedDatabase, alias);
  }
}

class CustomerEntry extends DataClass implements Insertable<CustomerEntry> {
  final String id;
  final String legacyId;

  /// Index in the app's customer list (the list order is observable).
  final int position;
  final String name;
  final String phone;
  final String email;
  final String memberNo;

  /// Whole loyalty points (not money); may be negative as in the app today.
  final int points;

  /// UTC ISO 8601 text.
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? serverId;
  final int? serverVersion;
  final String? deviceId;
  const CustomerEntry({
    required this.id,
    required this.legacyId,
    required this.position,
    required this.name,
    required this.phone,
    required this.email,
    required this.memberNo,
    required this.points,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.serverId,
    this.serverVersion,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['legacy_id'] = Variable<String>(legacyId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['email'] = Variable<String>(email);
    map['member_no'] = Variable<String>(memberNo);
    map['points'] = Variable<int>(points);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  CustomerEntriesCompanion toCompanion(bool nullToAbsent) {
    return CustomerEntriesCompanion(
      id: Value(id),
      legacyId: Value(legacyId),
      position: Value(position),
      name: Value(name),
      phone: Value(phone),
      email: Value(email),
      memberNo: Value(memberNo),
      points: Value(points),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory CustomerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerEntry(
      id: serializer.fromJson<String>(json['id']),
      legacyId: serializer.fromJson<String>(json['legacyId']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String>(json['email']),
      memberNo: serializer.fromJson<String>(json['memberNo']),
      points: serializer.fromJson<int>(json['points']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'legacyId': serializer.toJson<String>(legacyId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String>(email),
      'memberNo': serializer.toJson<String>(memberNo),
      'points': serializer.toJson<int>(points),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'serverId': serializer.toJson<String?>(serverId),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  CustomerEntry copyWith({
    String? id,
    String? legacyId,
    int? position,
    String? name,
    String? phone,
    String? email,
    String? memberNo,
    int? points,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    Value<String?> serverId = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
  }) => CustomerEntry(
    id: id ?? this.id,
    legacyId: legacyId ?? this.legacyId,
    position: position ?? this.position,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    memberNo: memberNo ?? this.memberNo,
    points: points ?? this.points,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    serverId: serverId.present ? serverId.value : this.serverId,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  CustomerEntry copyWithCompanion(CustomerEntriesCompanion data) {
    return CustomerEntry(
      id: data.id.present ? data.id.value : this.id,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      memberNo: data.memberNo.present ? data.memberNo.value : this.memberNo,
      points: data.points.present ? data.points.value : this.points,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerEntry(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('memberNo: $memberNo, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverId: $serverId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    legacyId,
    position,
    name,
    phone,
    email,
    memberNo,
    points,
    createdAt,
    updatedAt,
    deletedAt,
    serverId,
    serverVersion,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerEntry &&
          other.id == this.id &&
          other.legacyId == this.legacyId &&
          other.position == this.position &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.memberNo == this.memberNo &&
          other.points == this.points &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.serverId == this.serverId &&
          other.serverVersion == this.serverVersion &&
          other.deviceId == this.deviceId);
}

class CustomerEntriesCompanion extends UpdateCompanion<CustomerEntry> {
  final Value<String> id;
  final Value<String> legacyId;
  final Value<int> position;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> email;
  final Value<String> memberNo;
  final Value<int> points;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String?> serverId;
  final Value<int?> serverVersion;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const CustomerEntriesCompanion({
    this.id = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.memberNo = const Value.absent(),
    this.points = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerEntriesCompanion.insert({
    required String id,
    required String legacyId,
    required int position,
    required String name,
    required String phone,
    required String email,
    required String memberNo,
    required int points,
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       legacyId = Value(legacyId),
       position = Value(position),
       name = Value(name),
       phone = Value(phone),
       email = Value(email),
       memberNo = Value(memberNo),
       points = Value(points),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomerEntry> custom({
    Expression<String>? id,
    Expression<String>? legacyId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? memberNo,
    Expression<int>? points,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? serverId,
    Expression<int>? serverVersion,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (legacyId != null) 'legacy_id': legacyId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (memberNo != null) 'member_no': memberNo,
      if (points != null) 'points': points,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (serverId != null) 'server_id': serverId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? legacyId,
    Value<int>? position,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? email,
    Value<String>? memberNo,
    Value<int>? points,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String?>? serverId,
    Value<int?>? serverVersion,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return CustomerEntriesCompanion(
      id: id ?? this.id,
      legacyId: legacyId ?? this.legacyId,
      position: position ?? this.position,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      memberNo: memberNo ?? this.memberNo,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      serverId: serverId ?? this.serverId,
      serverVersion: serverVersion ?? this.serverVersion,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<String>(legacyId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (memberNo.present) {
      map['member_no'] = Variable<String>(memberNo.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('memberNo: $memberNo, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverId: $serverId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CurrencyEntriesTable extends CurrencyEntries
    with TableInfo<$CurrencyEntriesTable, CurrencyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrencyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exponentMeta = const VerificationMeta(
    'exponent',
  );
  @override
  late final GeneratedColumn<int> exponent = GeneratedColumn<int>(
    'exponent',
    aliasedName,
    false,
    check: () => exponent.isIn(const [0, 2, 3]),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupingMeta = const VerificationMeta(
    'grouping',
  );
  @override
  late final GeneratedColumn<String> grouping = GeneratedColumn<String>(
    'grouping',
    aliasedName,
    false,
    check: () => grouping.isIn(const ['thousands', 'lakh']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quickCashMeta = const VerificationMeta(
    'quickCash',
  );
  @override
  late final GeneratedColumn<String> quickCash = GeneratedColumn<String>(
    'quick_cash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    name,
    symbol,
    exponent,
    grouping,
    quickCash,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrencyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('exponent')) {
      context.handle(
        _exponentMeta,
        exponent.isAcceptableOrUnknown(data['exponent']!, _exponentMeta),
      );
    } else if (isInserting) {
      context.missing(_exponentMeta);
    }
    if (data.containsKey('grouping')) {
      context.handle(
        _groupingMeta,
        grouping.isAcceptableOrUnknown(data['grouping']!, _groupingMeta),
      );
    } else if (isInserting) {
      context.missing(_groupingMeta);
    }
    if (data.containsKey('quick_cash')) {
      context.handle(
        _quickCashMeta,
        quickCash.isAcceptableOrUnknown(data['quick_cash']!, _quickCashMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  CurrencyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrencyEntry(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      exponent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exponent'],
      )!,
      grouping: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grouping'],
      )!,
      quickCash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quick_cash'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CurrencyEntriesTable createAlias(String alias) {
    return $CurrencyEntriesTable(attachedDatabase, alias);
  }
}

class CurrencyEntry extends DataClass implements Insertable<CurrencyEntry> {
  /// ISO 4217 code.
  final String code;
  final String name;

  /// Printed before an amount; may carry a trailing space (`AED `).
  final String symbol;

  /// Decimal places of the minor unit: 0, 2 or 3.
  final int exponent;

  /// `thousands` or `lakh`.
  final String grouping;

  /// Quick cash buttons in whole currency units, comma separated.
  final String quickCash;
  final String createdAt;
  final String updatedAt;
  const CurrencyEntry({
    required this.code,
    required this.name,
    required this.symbol,
    required this.exponent,
    required this.grouping,
    required this.quickCash,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['symbol'] = Variable<String>(symbol);
    map['exponent'] = Variable<int>(exponent);
    map['grouping'] = Variable<String>(grouping);
    map['quick_cash'] = Variable<String>(quickCash);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CurrencyEntriesCompanion toCompanion(bool nullToAbsent) {
    return CurrencyEntriesCompanion(
      code: Value(code),
      name: Value(name),
      symbol: Value(symbol),
      exponent: Value(exponent),
      grouping: Value(grouping),
      quickCash: Value(quickCash),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CurrencyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrencyEntry(
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      symbol: serializer.fromJson<String>(json['symbol']),
      exponent: serializer.fromJson<int>(json['exponent']),
      grouping: serializer.fromJson<String>(json['grouping']),
      quickCash: serializer.fromJson<String>(json['quickCash']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'symbol': serializer.toJson<String>(symbol),
      'exponent': serializer.toJson<int>(exponent),
      'grouping': serializer.toJson<String>(grouping),
      'quickCash': serializer.toJson<String>(quickCash),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CurrencyEntry copyWith({
    String? code,
    String? name,
    String? symbol,
    int? exponent,
    String? grouping,
    String? quickCash,
    String? createdAt,
    String? updatedAt,
  }) => CurrencyEntry(
    code: code ?? this.code,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    exponent: exponent ?? this.exponent,
    grouping: grouping ?? this.grouping,
    quickCash: quickCash ?? this.quickCash,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CurrencyEntry copyWithCompanion(CurrencyEntriesCompanion data) {
    return CurrencyEntry(
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      exponent: data.exponent.present ? data.exponent.value : this.exponent,
      grouping: data.grouping.present ? data.grouping.value : this.grouping,
      quickCash: data.quickCash.present ? data.quickCash.value : this.quickCash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyEntry(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('exponent: $exponent, ')
          ..write('grouping: $grouping, ')
          ..write('quickCash: $quickCash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    code,
    name,
    symbol,
    exponent,
    grouping,
    quickCash,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrencyEntry &&
          other.code == this.code &&
          other.name == this.name &&
          other.symbol == this.symbol &&
          other.exponent == this.exponent &&
          other.grouping == this.grouping &&
          other.quickCash == this.quickCash &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CurrencyEntriesCompanion extends UpdateCompanion<CurrencyEntry> {
  final Value<String> code;
  final Value<String> name;
  final Value<String> symbol;
  final Value<int> exponent;
  final Value<String> grouping;
  final Value<String> quickCash;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CurrencyEntriesCompanion({
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.symbol = const Value.absent(),
    this.exponent = const Value.absent(),
    this.grouping = const Value.absent(),
    this.quickCash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrencyEntriesCompanion.insert({
    required String code,
    required String name,
    required String symbol,
    required int exponent,
    required String grouping,
    this.quickCash = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       symbol = Value(symbol),
       exponent = Value(exponent),
       grouping = Value(grouping),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CurrencyEntry> custom({
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? symbol,
    Expression<int>? exponent,
    Expression<String>? grouping,
    Expression<String>? quickCash,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (symbol != null) 'symbol': symbol,
      if (exponent != null) 'exponent': exponent,
      if (grouping != null) 'grouping': grouping,
      if (quickCash != null) 'quick_cash': quickCash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrencyEntriesCompanion copyWith({
    Value<String>? code,
    Value<String>? name,
    Value<String>? symbol,
    Value<int>? exponent,
    Value<String>? grouping,
    Value<String>? quickCash,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return CurrencyEntriesCompanion(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      exponent: exponent ?? this.exponent,
      grouping: grouping ?? this.grouping,
      quickCash: quickCash ?? this.quickCash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (exponent.present) {
      map['exponent'] = Variable<int>(exponent.value);
    }
    if (grouping.present) {
      map['grouping'] = Variable<String>(grouping.value);
    }
    if (quickCash.present) {
      map['quick_cash'] = Variable<String>(quickCash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyEntriesCompanion(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('exponent: $exponent, ')
          ..write('grouping: $grouping, ')
          ..write('quickCash: $quickCash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoreEntriesTable extends StoreEntries
    with TableInfo<$StoreEntriesTable, StoreEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _taxIdMeta = const VerificationMeta('taxId');
  @override
  late final GeneratedColumn<String> taxId = GeneratedColumn<String>(
    'tax_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptHeaderMeta = const VerificationMeta(
    'receiptHeader',
  );
  @override
  late final GeneratedColumn<String> receiptHeader = GeneratedColumn<String>(
    'receipt_header',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptFooterMeta = const VerificationMeta(
    'receiptFooter',
  );
  @override
  late final GeneratedColumn<String> receiptFooter = GeneratedColumn<String>(
    'receipt_footer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    phone,
    taxId,
    receiptHeader,
    receiptFooter,
    currencyCode,
    region,
    active,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('tax_id')) {
      context.handle(
        _taxIdMeta,
        taxId.isAcceptableOrUnknown(data['tax_id']!, _taxIdMeta),
      );
    }
    if (data.containsKey('receipt_header')) {
      context.handle(
        _receiptHeaderMeta,
        receiptHeader.isAcceptableOrUnknown(
          data['receipt_header']!,
          _receiptHeaderMeta,
        ),
      );
    }
    if (data.containsKey('receipt_footer')) {
      context.handle(
        _receiptFooterMeta,
        receiptFooter.isAcceptableOrUnknown(
          data['receipt_footer']!,
          _receiptFooterMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoreEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      taxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_id'],
      )!,
      receiptHeader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_header'],
      )!,
      receiptFooter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_footer'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $StoreEntriesTable createAlias(String alias) {
    return $StoreEntriesTable(attachedDatabase, alias);
  }
}

class StoreEntry extends DataClass implements Insertable<StoreEntry> {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String taxId;
  final String receiptHeader;
  final String receiptFooter;
  final String currencyCode;

  /// Country or region code for tax selection (not used yet).
  final String region;
  final bool active;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  const StoreEntry({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.taxId,
    required this.receiptHeader,
    required this.receiptFooter,
    required this.currencyCode,
    required this.region,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['phone'] = Variable<String>(phone);
    map['tax_id'] = Variable<String>(taxId);
    map['receipt_header'] = Variable<String>(receiptHeader);
    map['receipt_footer'] = Variable<String>(receiptFooter);
    map['currency_code'] = Variable<String>(currencyCode);
    map['region'] = Variable<String>(region);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  StoreEntriesCompanion toCompanion(bool nullToAbsent) {
    return StoreEntriesCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      phone: Value(phone),
      taxId: Value(taxId),
      receiptHeader: Value(receiptHeader),
      receiptFooter: Value(receiptFooter),
      currencyCode: Value(currencyCode),
      region: Value(region),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StoreEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      phone: serializer.fromJson<String>(json['phone']),
      taxId: serializer.fromJson<String>(json['taxId']),
      receiptHeader: serializer.fromJson<String>(json['receiptHeader']),
      receiptFooter: serializer.fromJson<String>(json['receiptFooter']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      region: serializer.fromJson<String>(json['region']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'phone': serializer.toJson<String>(phone),
      'taxId': serializer.toJson<String>(taxId),
      'receiptHeader': serializer.toJson<String>(receiptHeader),
      'receiptFooter': serializer.toJson<String>(receiptFooter),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'region': serializer.toJson<String>(region),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  StoreEntry copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? taxId,
    String? receiptHeader,
    String? receiptFooter,
    String? currencyCode,
    String? region,
    bool? active,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => StoreEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    taxId: taxId ?? this.taxId,
    receiptHeader: receiptHeader ?? this.receiptHeader,
    receiptFooter: receiptFooter ?? this.receiptFooter,
    currencyCode: currencyCode ?? this.currencyCode,
    region: region ?? this.region,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StoreEntry copyWithCompanion(StoreEntriesCompanion data) {
    return StoreEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      taxId: data.taxId.present ? data.taxId.value : this.taxId,
      receiptHeader: data.receiptHeader.present
          ? data.receiptHeader.value
          : this.receiptHeader,
      receiptFooter: data.receiptFooter.present
          ? data.receiptFooter.value
          : this.receiptFooter,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      region: data.region.present ? data.region.value : this.region,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('taxId: $taxId, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('region: $region, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    phone,
    taxId,
    receiptHeader,
    receiptFooter,
    currencyCode,
    region,
    active,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.taxId == this.taxId &&
          other.receiptHeader == this.receiptHeader &&
          other.receiptFooter == this.receiptFooter &&
          other.currencyCode == this.currencyCode &&
          other.region == this.region &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class StoreEntriesCompanion extends UpdateCompanion<StoreEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String> phone;
  final Value<String> taxId;
  final Value<String> receiptHeader;
  final Value<String> receiptFooter;
  final Value<String> currencyCode;
  final Value<String> region;
  final Value<bool> active;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const StoreEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.taxId = const Value.absent(),
    this.receiptHeader = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.region = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoreEntriesCompanion.insert({
    required String id,
    required String name,
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.taxId = const Value.absent(),
    this.receiptHeader = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    required String currencyCode,
    this.region = const Value.absent(),
    this.active = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       currencyCode = Value(currencyCode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StoreEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? taxId,
    Expression<String>? receiptHeader,
    Expression<String>? receiptFooter,
    Expression<String>? currencyCode,
    Expression<String>? region,
    Expression<bool>? active,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (taxId != null) 'tax_id': taxId,
      if (receiptHeader != null) 'receipt_header': receiptHeader,
      if (receiptFooter != null) 'receipt_footer': receiptFooter,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (region != null) 'region': region,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoreEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? address,
    Value<String>? phone,
    Value<String>? taxId,
    Value<String>? receiptHeader,
    Value<String>? receiptFooter,
    Value<String>? currencyCode,
    Value<String>? region,
    Value<bool>? active,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return StoreEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      taxId: taxId ?? this.taxId,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currencyCode: currencyCode ?? this.currencyCode,
      region: region ?? this.region,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (taxId.present) {
      map['tax_id'] = Variable<String>(taxId.value);
    }
    if (receiptHeader.present) {
      map['receipt_header'] = Variable<String>(receiptHeader.value);
    }
    if (receiptFooter.present) {
      map['receipt_footer'] = Variable<String>(receiptFooter.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('taxId: $taxId, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('region: $region, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeldBillEntriesTable extends HeldBillEntries
    with TableInfo<$HeldBillEntriesTable, HeldBillEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeldBillEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heldAtMeta = const VerificationMeta('heldAt');
  @override
  late final GeneratedColumn<String> heldAt = GeneratedColumn<String>(
    'held_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cartJsonMeta = const VerificationMeta(
    'cartJson',
  );
  @override
  late final GeneratedColumn<String> cartJson = GeneratedColumn<String>(
    'cart_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ref,
    position,
    heldAt,
    cartJson,
    createdAt,
    updatedAt,
    deletedAt,
    storeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'held_bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeldBillEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ref')) {
      context.handle(
        _refMeta,
        ref.isAcceptableOrUnknown(data['ref']!, _refMeta),
      );
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('held_at')) {
      context.handle(
        _heldAtMeta,
        heldAt.isAcceptableOrUnknown(data['held_at']!, _heldAtMeta),
      );
    } else if (isInserting) {
      context.missing(_heldAtMeta);
    }
    if (data.containsKey('cart_json')) {
      context.handle(
        _cartJsonMeta,
        cartJson.isAcceptableOrUnknown(data['cart_json']!, _cartJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_cartJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeldBillEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeldBillEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      heldAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}held_at'],
      )!,
      cartJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cart_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
    );
  }

  @override
  $HeldBillEntriesTable createAlias(String alias) {
    return $HeldBillEntriesTable(attachedDatabase, alias);
  }
}

class HeldBillEntry extends DataClass implements Insertable<HeldBillEntry> {
  final String id;
  final String ref;

  /// Index in the app's held list (oldest first; the order is observable).
  final int position;

  /// `HeldBill.time` verbatim (ISO text in the app, never parsed here).
  final String heldAt;

  /// Canonical JSON of the cart snapshot (full product snapshot per line).
  final String cartJson;

  /// UTC ISO 8601 text.
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  /// Owning store (v9); null on legacy rows.
  final String? storeId;
  const HeldBillEntry({
    required this.id,
    required this.ref,
    required this.position,
    required this.heldAt,
    required this.cartJson,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.storeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ref'] = Variable<String>(ref);
    map['position'] = Variable<int>(position);
    map['held_at'] = Variable<String>(heldAt);
    map['cart_json'] = Variable<String>(cartJson);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    return map;
  }

  HeldBillEntriesCompanion toCompanion(bool nullToAbsent) {
    return HeldBillEntriesCompanion(
      id: Value(id),
      ref: Value(ref),
      position: Value(position),
      heldAt: Value(heldAt),
      cartJson: Value(cartJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
    );
  }

  factory HeldBillEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeldBillEntry(
      id: serializer.fromJson<String>(json['id']),
      ref: serializer.fromJson<String>(json['ref']),
      position: serializer.fromJson<int>(json['position']),
      heldAt: serializer.fromJson<String>(json['heldAt']),
      cartJson: serializer.fromJson<String>(json['cartJson']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      storeId: serializer.fromJson<String?>(json['storeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ref': serializer.toJson<String>(ref),
      'position': serializer.toJson<int>(position),
      'heldAt': serializer.toJson<String>(heldAt),
      'cartJson': serializer.toJson<String>(cartJson),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'storeId': serializer.toJson<String?>(storeId),
    };
  }

  HeldBillEntry copyWith({
    String? id,
    String? ref,
    int? position,
    String? heldAt,
    String? cartJson,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
  }) => HeldBillEntry(
    id: id ?? this.id,
    ref: ref ?? this.ref,
    position: position ?? this.position,
    heldAt: heldAt ?? this.heldAt,
    cartJson: cartJson ?? this.cartJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    storeId: storeId.present ? storeId.value : this.storeId,
  );
  HeldBillEntry copyWithCompanion(HeldBillEntriesCompanion data) {
    return HeldBillEntry(
      id: data.id.present ? data.id.value : this.id,
      ref: data.ref.present ? data.ref.value : this.ref,
      position: data.position.present ? data.position.value : this.position,
      heldAt: data.heldAt.present ? data.heldAt.value : this.heldAt,
      cartJson: data.cartJson.present ? data.cartJson.value : this.cartJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeldBillEntry(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('position: $position, ')
          ..write('heldAt: $heldAt, ')
          ..write('cartJson: $cartJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('storeId: $storeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ref,
    position,
    heldAt,
    cartJson,
    createdAt,
    updatedAt,
    deletedAt,
    storeId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeldBillEntry &&
          other.id == this.id &&
          other.ref == this.ref &&
          other.position == this.position &&
          other.heldAt == this.heldAt &&
          other.cartJson == this.cartJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.storeId == this.storeId);
}

class HeldBillEntriesCompanion extends UpdateCompanion<HeldBillEntry> {
  final Value<String> id;
  final Value<String> ref;
  final Value<int> position;
  final Value<String> heldAt;
  final Value<String> cartJson;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String?> storeId;
  final Value<int> rowid;
  const HeldBillEntriesCompanion({
    this.id = const Value.absent(),
    this.ref = const Value.absent(),
    this.position = const Value.absent(),
    this.heldAt = const Value.absent(),
    this.cartJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.storeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeldBillEntriesCompanion.insert({
    required String id,
    required String ref,
    required int position,
    required String heldAt,
    required String cartJson,
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.storeId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ref = Value(ref),
       position = Value(position),
       heldAt = Value(heldAt),
       cartJson = Value(cartJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HeldBillEntry> custom({
    Expression<String>? id,
    Expression<String>? ref,
    Expression<int>? position,
    Expression<String>? heldAt,
    Expression<String>? cartJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? storeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ref != null) 'ref': ref,
      if (position != null) 'position': position,
      if (heldAt != null) 'held_at': heldAt,
      if (cartJson != null) 'cart_json': cartJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (storeId != null) 'store_id': storeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeldBillEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? ref,
    Value<int>? position,
    Value<String>? heldAt,
    Value<String>? cartJson,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String?>? storeId,
    Value<int>? rowid,
  }) {
    return HeldBillEntriesCompanion(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      position: position ?? this.position,
      heldAt: heldAt ?? this.heldAt,
      cartJson: cartJson ?? this.cartJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      storeId: storeId ?? this.storeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (heldAt.present) {
      map['held_at'] = Variable<String>(heldAt.value);
    }
    if (cartJson.present) {
      map['cart_json'] = Variable<String>(cartJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeldBillEntriesCompanion(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('position: $position, ')
          ..write('heldAt: $heldAt, ')
          ..write('cartJson: $cartJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('storeId: $storeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryEntriesTable extends CategoryEntries
    with TableInfo<$CategoryEntriesTable, CategoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    name,
    parentId,
    iconKey,
    position,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CategoryEntriesTable createAlias(String alias) {
    return $CategoryEntriesTable(attachedDatabase, alias);
  }
}

class CategoryEntry extends DataClass implements Insertable<CategoryEntry> {
  final String id;

  /// Null = shared by every store.
  final String? storeId;
  final String name;
  final String? parentId;
  final String iconKey;
  final int position;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  const CategoryEntry({
    required this.id,
    this.storeId,
    required this.name,
    this.parentId,
    required this.iconKey,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['icon_key'] = Variable<String>(iconKey);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  CategoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return CategoryEntriesCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      iconKey: Value(iconKey),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CategoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryEntry(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'iconKey': serializer.toJson<String>(iconKey),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  CategoryEntry copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    String? name,
    Value<String?> parentId = const Value.absent(),
    String? iconKey,
    int? position,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => CategoryEntry(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    iconKey: iconKey ?? this.iconKey,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CategoryEntry copyWithCompanion(CategoryEntriesCompanion data) {
    return CategoryEntry(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryEntry(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('iconKey: $iconKey, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    name,
    parentId,
    iconKey,
    position,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryEntry &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.iconKey == this.iconKey &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CategoryEntriesCompanion extends UpdateCompanion<CategoryEntry> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String> iconKey;
  final Value<int> position;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const CategoryEntriesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryEntriesCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.position = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryEntry> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? iconKey,
    Expression<int>? position,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (iconKey != null) 'icon_key': iconKey,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String?>? parentId,
    Value<String>? iconKey,
    Value<int>? position,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CategoryEntriesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      iconKey: iconKey ?? this.iconKey,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('iconKey: $iconKey, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductEntriesTable extends ProductEntries
    with TableInfo<$ProductEntriesTable, ProductEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<int> legacyId = GeneratedColumn<int>(
    'legacy_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMinorMeta = const VerificationMeta(
    'priceMinor',
  );
  @override
  late final GeneratedColumn<int> priceMinor = GeneratedColumn<int>(
    'price_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subMeta = const VerificationMeta('sub');
  @override
  late final GeneratedColumn<String> sub = GeneratedColumn<String>(
    'sub',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
    'stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gstBpMeta = const VerificationMeta('gstBp');
  @override
  late final GeneratedColumn<int> gstBp = GeneratedColumn<int>(
    'gst_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<int> image = GeneratedColumn<int>(
    'image',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _favouriteMeta = const VerificationMeta(
    'favourite',
  );
  @override
  late final GeneratedColumn<bool> favourite = GeneratedColumn<bool>(
    'favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favourite" IN (0, 1))',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _variantGroupMeta = const VerificationMeta(
    'variantGroup',
  );
  @override
  late final GeneratedColumn<String> variantGroup = GeneratedColumn<String>(
    'variant_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantLabelMeta = const VerificationMeta(
    'variantLabel',
  );
  @override
  late final GeneratedColumn<String> variantLabel = GeneratedColumn<String>(
    'variant_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    legacyId,
    position,
    name,
    code,
    barcode,
    priceMinor,
    currencyCode,
    category,
    sub,
    stock,
    gstBp,
    image,
    favourite,
    storeId,
    categoryId,
    variantGroup,
    variantLabel,
    createdAt,
    updatedAt,
    deletedAt,
    serverId,
    serverVersion,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_legacyIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('price_minor')) {
      context.handle(
        _priceMinorMeta,
        priceMinor.isAcceptableOrUnknown(data['price_minor']!, _priceMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sub')) {
      context.handle(
        _subMeta,
        sub.isAcceptableOrUnknown(data['sub']!, _subMeta),
      );
    } else if (isInserting) {
      context.missing(_subMeta);
    }
    if (data.containsKey('stock')) {
      context.handle(
        _stockMeta,
        stock.isAcceptableOrUnknown(data['stock']!, _stockMeta),
      );
    } else if (isInserting) {
      context.missing(_stockMeta);
    }
    if (data.containsKey('gst_bp')) {
      context.handle(
        _gstBpMeta,
        gstBp.isAcceptableOrUnknown(data['gst_bp']!, _gstBpMeta),
      );
    } else if (isInserting) {
      context.missing(_gstBpMeta);
    }
    if (data.containsKey('image')) {
      context.handle(
        _imageMeta,
        image.isAcceptableOrUnknown(data['image']!, _imageMeta),
      );
    } else if (isInserting) {
      context.missing(_imageMeta);
    }
    if (data.containsKey('favourite')) {
      context.handle(
        _favouriteMeta,
        favourite.isAcceptableOrUnknown(data['favourite']!, _favouriteMeta),
      );
    } else if (isInserting) {
      context.missing(_favouriteMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('variant_group')) {
      context.handle(
        _variantGroupMeta,
        variantGroup.isAcceptableOrUnknown(
          data['variant_group']!,
          _variantGroupMeta,
        ),
      );
    }
    if (data.containsKey('variant_label')) {
      context.handle(
        _variantLabelMeta,
        variantLabel.isAcceptableOrUnknown(
          data['variant_label']!,
          _variantLabelMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      priceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      sub: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub'],
      )!,
      stock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock'],
      )!,
      gstBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gst_bp'],
      )!,
      image: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}image'],
      )!,
      favourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favourite'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      variantGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_group'],
      ),
      variantLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $ProductEntriesTable createAlias(String alias) {
    return $ProductEntriesTable(attachedDatabase, alias);
  }
}

class ProductEntry extends DataClass implements Insertable<ProductEntry> {
  final String id;
  final int legacyId;

  /// Index in the app's product list (the list order is observable).
  final int position;
  final String name;
  final String code;
  final String barcode;
  final int priceMinor;

  /// PROPOSED default INR (DEC-124); the price's currency code.
  final String currencyCode;
  final String category;
  final String sub;

  /// Whole units.
  final int stock;

  /// Basis points; the JSON keeps the prototype's percent number.
  final int gstBp;

  /// Asset number or -1 for none.
  final int image;
  final bool favourite;

  /// Owning store (v9). Null on legacy rows; while the `stores` table is
  /// empty every row is visible (DEC-132).
  final String? storeId;
  final String? categoryId;

  /// Sibling SKUs of one product share a group; the label tells them apart.
  final String? variantGroup;
  final String? variantLabel;

  /// UTC ISO 8601 text.
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? serverId;
  final int? serverVersion;
  final String? deviceId;
  const ProductEntry({
    required this.id,
    required this.legacyId,
    required this.position,
    required this.name,
    required this.code,
    required this.barcode,
    required this.priceMinor,
    required this.currencyCode,
    required this.category,
    required this.sub,
    required this.stock,
    required this.gstBp,
    required this.image,
    required this.favourite,
    this.storeId,
    this.categoryId,
    this.variantGroup,
    this.variantLabel,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.serverId,
    this.serverVersion,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['legacy_id'] = Variable<int>(legacyId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['barcode'] = Variable<String>(barcode);
    map['price_minor'] = Variable<int>(priceMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['category'] = Variable<String>(category);
    map['sub'] = Variable<String>(sub);
    map['stock'] = Variable<int>(stock);
    map['gst_bp'] = Variable<int>(gstBp);
    map['image'] = Variable<int>(image);
    map['favourite'] = Variable<bool>(favourite);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || variantGroup != null) {
      map['variant_group'] = Variable<String>(variantGroup);
    }
    if (!nullToAbsent || variantLabel != null) {
      map['variant_label'] = Variable<String>(variantLabel);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  ProductEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProductEntriesCompanion(
      id: Value(id),
      legacyId: Value(legacyId),
      position: Value(position),
      name: Value(name),
      code: Value(code),
      barcode: Value(barcode),
      priceMinor: Value(priceMinor),
      currencyCode: Value(currencyCode),
      category: Value(category),
      sub: Value(sub),
      stock: Value(stock),
      gstBp: Value(gstBp),
      image: Value(image),
      favourite: Value(favourite),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      variantGroup: variantGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(variantGroup),
      variantLabel: variantLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(variantLabel),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory ProductEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductEntry(
      id: serializer.fromJson<String>(json['id']),
      legacyId: serializer.fromJson<int>(json['legacyId']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      barcode: serializer.fromJson<String>(json['barcode']),
      priceMinor: serializer.fromJson<int>(json['priceMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      category: serializer.fromJson<String>(json['category']),
      sub: serializer.fromJson<String>(json['sub']),
      stock: serializer.fromJson<int>(json['stock']),
      gstBp: serializer.fromJson<int>(json['gstBp']),
      image: serializer.fromJson<int>(json['image']),
      favourite: serializer.fromJson<bool>(json['favourite']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      variantGroup: serializer.fromJson<String?>(json['variantGroup']),
      variantLabel: serializer.fromJson<String?>(json['variantLabel']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'legacyId': serializer.toJson<int>(legacyId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'barcode': serializer.toJson<String>(barcode),
      'priceMinor': serializer.toJson<int>(priceMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'category': serializer.toJson<String>(category),
      'sub': serializer.toJson<String>(sub),
      'stock': serializer.toJson<int>(stock),
      'gstBp': serializer.toJson<int>(gstBp),
      'image': serializer.toJson<int>(image),
      'favourite': serializer.toJson<bool>(favourite),
      'storeId': serializer.toJson<String?>(storeId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'variantGroup': serializer.toJson<String?>(variantGroup),
      'variantLabel': serializer.toJson<String?>(variantLabel),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'serverId': serializer.toJson<String?>(serverId),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  ProductEntry copyWith({
    String? id,
    int? legacyId,
    int? position,
    String? name,
    String? code,
    String? barcode,
    int? priceMinor,
    String? currencyCode,
    String? category,
    String? sub,
    int? stock,
    int? gstBp,
    int? image,
    bool? favourite,
    Value<String?> storeId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> variantGroup = const Value.absent(),
    Value<String?> variantLabel = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    Value<String?> serverId = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
  }) => ProductEntry(
    id: id ?? this.id,
    legacyId: legacyId ?? this.legacyId,
    position: position ?? this.position,
    name: name ?? this.name,
    code: code ?? this.code,
    barcode: barcode ?? this.barcode,
    priceMinor: priceMinor ?? this.priceMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    category: category ?? this.category,
    sub: sub ?? this.sub,
    stock: stock ?? this.stock,
    gstBp: gstBp ?? this.gstBp,
    image: image ?? this.image,
    favourite: favourite ?? this.favourite,
    storeId: storeId.present ? storeId.value : this.storeId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    variantGroup: variantGroup.present ? variantGroup.value : this.variantGroup,
    variantLabel: variantLabel.present ? variantLabel.value : this.variantLabel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    serverId: serverId.present ? serverId.value : this.serverId,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  ProductEntry copyWithCompanion(ProductEntriesCompanion data) {
    return ProductEntry(
      id: data.id.present ? data.id.value : this.id,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      priceMinor: data.priceMinor.present
          ? data.priceMinor.value
          : this.priceMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      category: data.category.present ? data.category.value : this.category,
      sub: data.sub.present ? data.sub.value : this.sub,
      stock: data.stock.present ? data.stock.value : this.stock,
      gstBp: data.gstBp.present ? data.gstBp.value : this.gstBp,
      image: data.image.present ? data.image.value : this.image,
      favourite: data.favourite.present ? data.favourite.value : this.favourite,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      variantGroup: data.variantGroup.present
          ? data.variantGroup.value
          : this.variantGroup,
      variantLabel: data.variantLabel.present
          ? data.variantLabel.value
          : this.variantLabel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductEntry(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('barcode: $barcode, ')
          ..write('priceMinor: $priceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('category: $category, ')
          ..write('sub: $sub, ')
          ..write('stock: $stock, ')
          ..write('gstBp: $gstBp, ')
          ..write('image: $image, ')
          ..write('favourite: $favourite, ')
          ..write('storeId: $storeId, ')
          ..write('categoryId: $categoryId, ')
          ..write('variantGroup: $variantGroup, ')
          ..write('variantLabel: $variantLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverId: $serverId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    legacyId,
    position,
    name,
    code,
    barcode,
    priceMinor,
    currencyCode,
    category,
    sub,
    stock,
    gstBp,
    image,
    favourite,
    storeId,
    categoryId,
    variantGroup,
    variantLabel,
    createdAt,
    updatedAt,
    deletedAt,
    serverId,
    serverVersion,
    deviceId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductEntry &&
          other.id == this.id &&
          other.legacyId == this.legacyId &&
          other.position == this.position &&
          other.name == this.name &&
          other.code == this.code &&
          other.barcode == this.barcode &&
          other.priceMinor == this.priceMinor &&
          other.currencyCode == this.currencyCode &&
          other.category == this.category &&
          other.sub == this.sub &&
          other.stock == this.stock &&
          other.gstBp == this.gstBp &&
          other.image == this.image &&
          other.favourite == this.favourite &&
          other.storeId == this.storeId &&
          other.categoryId == this.categoryId &&
          other.variantGroup == this.variantGroup &&
          other.variantLabel == this.variantLabel &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.serverId == this.serverId &&
          other.serverVersion == this.serverVersion &&
          other.deviceId == this.deviceId);
}

class ProductEntriesCompanion extends UpdateCompanion<ProductEntry> {
  final Value<String> id;
  final Value<int> legacyId;
  final Value<int> position;
  final Value<String> name;
  final Value<String> code;
  final Value<String> barcode;
  final Value<int> priceMinor;
  final Value<String> currencyCode;
  final Value<String> category;
  final Value<String> sub;
  final Value<int> stock;
  final Value<int> gstBp;
  final Value<int> image;
  final Value<bool> favourite;
  final Value<String?> storeId;
  final Value<String?> categoryId;
  final Value<String?> variantGroup;
  final Value<String?> variantLabel;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String?> serverId;
  final Value<int?> serverVersion;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const ProductEntriesCompanion({
    this.id = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.barcode = const Value.absent(),
    this.priceMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.category = const Value.absent(),
    this.sub = const Value.absent(),
    this.stock = const Value.absent(),
    this.gstBp = const Value.absent(),
    this.image = const Value.absent(),
    this.favourite = const Value.absent(),
    this.storeId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.variantGroup = const Value.absent(),
    this.variantLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductEntriesCompanion.insert({
    required String id,
    required int legacyId,
    required int position,
    required String name,
    required String code,
    required String barcode,
    required int priceMinor,
    this.currencyCode = const Value.absent(),
    required String category,
    required String sub,
    required int stock,
    required int gstBp,
    required int image,
    required bool favourite,
    this.storeId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.variantGroup = const Value.absent(),
    this.variantLabel = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       legacyId = Value(legacyId),
       position = Value(position),
       name = Value(name),
       code = Value(code),
       barcode = Value(barcode),
       priceMinor = Value(priceMinor),
       category = Value(category),
       sub = Value(sub),
       stock = Value(stock),
       gstBp = Value(gstBp),
       image = Value(image),
       favourite = Value(favourite),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductEntry> custom({
    Expression<String>? id,
    Expression<int>? legacyId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? barcode,
    Expression<int>? priceMinor,
    Expression<String>? currencyCode,
    Expression<String>? category,
    Expression<String>? sub,
    Expression<int>? stock,
    Expression<int>? gstBp,
    Expression<int>? image,
    Expression<bool>? favourite,
    Expression<String>? storeId,
    Expression<String>? categoryId,
    Expression<String>? variantGroup,
    Expression<String>? variantLabel,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? serverId,
    Expression<int>? serverVersion,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (legacyId != null) 'legacy_id': legacyId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (barcode != null) 'barcode': barcode,
      if (priceMinor != null) 'price_minor': priceMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (category != null) 'category': category,
      if (sub != null) 'sub': sub,
      if (stock != null) 'stock': stock,
      if (gstBp != null) 'gst_bp': gstBp,
      if (image != null) 'image': image,
      if (favourite != null) 'favourite': favourite,
      if (storeId != null) 'store_id': storeId,
      if (categoryId != null) 'category_id': categoryId,
      if (variantGroup != null) 'variant_group': variantGroup,
      if (variantLabel != null) 'variant_label': variantLabel,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (serverId != null) 'server_id': serverId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? legacyId,
    Value<int>? position,
    Value<String>? name,
    Value<String>? code,
    Value<String>? barcode,
    Value<int>? priceMinor,
    Value<String>? currencyCode,
    Value<String>? category,
    Value<String>? sub,
    Value<int>? stock,
    Value<int>? gstBp,
    Value<int>? image,
    Value<bool>? favourite,
    Value<String?>? storeId,
    Value<String?>? categoryId,
    Value<String?>? variantGroup,
    Value<String?>? variantLabel,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String?>? serverId,
    Value<int?>? serverVersion,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return ProductEntriesCompanion(
      id: id ?? this.id,
      legacyId: legacyId ?? this.legacyId,
      position: position ?? this.position,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      priceMinor: priceMinor ?? this.priceMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      category: category ?? this.category,
      sub: sub ?? this.sub,
      stock: stock ?? this.stock,
      gstBp: gstBp ?? this.gstBp,
      image: image ?? this.image,
      favourite: favourite ?? this.favourite,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      variantGroup: variantGroup ?? this.variantGroup,
      variantLabel: variantLabel ?? this.variantLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      serverId: serverId ?? this.serverId,
      serverVersion: serverVersion ?? this.serverVersion,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<int>(legacyId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (priceMinor.present) {
      map['price_minor'] = Variable<int>(priceMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sub.present) {
      map['sub'] = Variable<String>(sub.value);
    }
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
    }
    if (gstBp.present) {
      map['gst_bp'] = Variable<int>(gstBp.value);
    }
    if (image.present) {
      map['image'] = Variable<int>(image.value);
    }
    if (favourite.present) {
      map['favourite'] = Variable<bool>(favourite.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (variantGroup.present) {
      map['variant_group'] = Variable<String>(variantGroup.value);
    }
    if (variantLabel.present) {
      map['variant_label'] = Variable<String>(variantLabel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductEntriesCompanion(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('barcode: $barcode, ')
          ..write('priceMinor: $priceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('category: $category, ')
          ..write('sub: $sub, ')
          ..write('stock: $stock, ')
          ..write('gstBp: $gstBp, ')
          ..write('image: $image, ')
          ..write('favourite: $favourite, ')
          ..write('storeId: $storeId, ')
          ..write('categoryId: $categoryId, ')
          ..write('variantGroup: $variantGroup, ')
          ..write('variantLabel: $variantLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverId: $serverId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CounterEntriesTable extends CounterEntries
    with TableInfo<$CounterEntriesTable, CounterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CounterEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    name,
    active,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<CounterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CounterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CounterEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CounterEntriesTable createAlias(String alias) {
    return $CounterEntriesTable(attachedDatabase, alias);
  }
}

class CounterEntry extends DataClass implements Insertable<CounterEntry> {
  final String id;
  final String storeId;
  final String name;
  final bool active;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  const CounterEntry({
    required this.id,
    required this.storeId,
    required this.name,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['name'] = Variable<String>(name);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  CounterEntriesCompanion toCompanion(bool nullToAbsent) {
    return CounterEntriesCompanion(
      id: Value(id),
      storeId: Value(storeId),
      name: Value(name),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CounterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CounterEntry(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'name': serializer.toJson<String>(name),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  CounterEntry copyWith({
    String? id,
    String? storeId,
    String? name,
    bool? active,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => CounterEntry(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    name: name ?? this.name,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CounterEntry copyWithCompanion(CounterEntriesCompanion data) {
    return CounterEntry(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CounterEntry(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, name, active, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CounterEntry &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CounterEntriesCompanion extends UpdateCompanion<CounterEntry> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> name;
  final Value<bool> active;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const CounterEntriesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CounterEntriesCompanion.insert({
    required String id,
    required String storeId,
    required String name,
    this.active = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CounterEntry> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<bool>? active,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CounterEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? name,
    Value<bool>? active,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CounterEntriesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CounterEntriesCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserEntriesTable extends UserEntries
    with TableInfo<$UserEntriesTable, UserEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<String> salt = GeneratedColumn<String>(
    'salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashAlgoMeta = const VerificationMeta(
    'hashAlgo',
  );
  @override
  late final GeneratedColumn<String> hashAlgo = GeneratedColumn<String>(
    'hash_algo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    displayName,
    role,
    salt,
    passwordHash,
    hashAlgo,
    active,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('salt')) {
      context.handle(
        _saltMeta,
        salt.isAcceptableOrUnknown(data['salt']!, _saltMeta),
      );
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('hash_algo')) {
      context.handle(
        _hashAlgoMeta,
        hashAlgo.isAcceptableOrUnknown(data['hash_algo']!, _hashAlgoMeta),
      );
    } else if (isInserting) {
      context.missing(_hashAlgoMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      salt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salt'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      hashAlgo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_algo'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $UserEntriesTable createAlias(String alias) {
    return $UserEntriesTable(attachedDatabase, alias);
  }
}

class UserEntry extends DataClass implements Insertable<UserEntry> {
  final String id;
  final String username;
  final String displayName;

  /// `admin`, `manager` or `cashier` (stored and shown, not enforced yet).
  final String role;
  final String salt;
  final String passwordHash;

  /// Hash scheme tag, `sha256-salted-v1`, so a stronger KDF can follow.
  final String hashAlgo;
  final bool active;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  const UserEntry({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.salt,
    required this.passwordHash,
    required this.hashAlgo,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['salt'] = Variable<String>(salt);
    map['password_hash'] = Variable<String>(passwordHash);
    map['hash_algo'] = Variable<String>(hashAlgo);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  UserEntriesCompanion toCompanion(bool nullToAbsent) {
    return UserEntriesCompanion(
      id: Value(id),
      username: Value(username),
      displayName: Value(displayName),
      role: Value(role),
      salt: Value(salt),
      passwordHash: Value(passwordHash),
      hashAlgo: Value(hashAlgo),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory UserEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserEntry(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      salt: serializer.fromJson<String>(json['salt']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      hashAlgo: serializer.fromJson<String>(json['hashAlgo']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'salt': serializer.toJson<String>(salt),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'hashAlgo': serializer.toJson<String>(hashAlgo),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  UserEntry copyWith({
    String? id,
    String? username,
    String? displayName,
    String? role,
    String? salt,
    String? passwordHash,
    String? hashAlgo,
    bool? active,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => UserEntry(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    salt: salt ?? this.salt,
    passwordHash: passwordHash ?? this.passwordHash,
    hashAlgo: hashAlgo ?? this.hashAlgo,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  UserEntry copyWithCompanion(UserEntriesCompanion data) {
    return UserEntry(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      salt: data.salt.present ? data.salt.value : this.salt,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      hashAlgo: data.hashAlgo.present ? data.hashAlgo.value : this.hashAlgo,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserEntry(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('salt: $salt, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('hashAlgo: $hashAlgo, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    displayName,
    role,
    salt,
    passwordHash,
    hashAlgo,
    active,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserEntry &&
          other.id == this.id &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.salt == this.salt &&
          other.passwordHash == this.passwordHash &&
          other.hashAlgo == this.hashAlgo &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class UserEntriesCompanion extends UpdateCompanion<UserEntry> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> displayName;
  final Value<String> role;
  final Value<String> salt;
  final Value<String> passwordHash;
  final Value<String> hashAlgo;
  final Value<bool> active;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const UserEntriesCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.salt = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.hashAlgo = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserEntriesCompanion.insert({
    required String id,
    required String username,
    required String displayName,
    required String role,
    required String salt,
    required String passwordHash,
    required String hashAlgo,
    this.active = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       username = Value(username),
       displayName = Value(displayName),
       role = Value(role),
       salt = Value(salt),
       passwordHash = Value(passwordHash),
       hashAlgo = Value(hashAlgo),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserEntry> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<String>? salt,
    Expression<String>? passwordHash,
    Expression<String>? hashAlgo,
    Expression<bool>? active,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (salt != null) 'salt': salt,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (hashAlgo != null) 'hash_algo': hashAlgo,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? username,
    Value<String>? displayName,
    Value<String>? role,
    Value<String>? salt,
    Value<String>? passwordHash,
    Value<String>? hashAlgo,
    Value<bool>? active,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return UserEntriesCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      salt: salt ?? this.salt,
      passwordHash: passwordHash ?? this.passwordHash,
      hashAlgo: hashAlgo ?? this.hashAlgo,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (salt.present) {
      map['salt'] = Variable<String>(salt.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (hashAlgo.present) {
      map['hash_algo'] = Variable<String>(hashAlgo.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserEntriesCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('salt: $salt, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('hashAlgo: $hashAlgo, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleEntriesTable extends SaleEntries
    with TableInfo<$SaleEntriesTable, SaleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasSaleIdMeta = const VerificationMeta(
    'hasSaleId',
  );
  @override
  late final GeneratedColumn<bool> hasSaleId = GeneratedColumn<bool>(
    'has_sale_id',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_sale_id" IN (0, 1))',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<String> occurredAt = GeneratedColumn<String>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counters (id)',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerLegacyIdMeta = const VerificationMeta(
    'customerLegacyId',
  );
  @override
  late final GeneratedColumn<String> customerLegacyId = GeneratedColumn<String>(
    'customer_legacy_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id)',
    ),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleTypeMeta = const VerificationMeta(
    'saleType',
  );
  @override
  late final GeneratedColumn<String> saleType = GeneratedColumn<String>(
    'sale_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billDiscountTypeMeta = const VerificationMeta(
    'billDiscountType',
  );
  @override
  late final GeneratedColumn<String> billDiscountType = GeneratedColumn<String>(
    'bill_discount_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billDiscountBpMeta = const VerificationMeta(
    'billDiscountBp',
  );
  @override
  late final GeneratedColumn<int> billDiscountBp = GeneratedColumn<int>(
    'bill_discount_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billDiscountMinorMeta = const VerificationMeta(
    'billDiscountMinor',
  );
  @override
  late final GeneratedColumn<int> billDiscountMinor = GeneratedColumn<int>(
    'bill_discount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountReasonMeta = const VerificationMeta(
    'discountReason',
  );
  @override
  late final GeneratedColumn<String> discountReason = GeneratedColumn<String>(
    'discount_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsRedeemedMeta = const VerificationMeta(
    'pointsRedeemed',
  );
  @override
  late final GeneratedColumn<int> pointsRedeemed = GeneratedColumn<int>(
    'points_redeemed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<int> items = GeneratedColumn<int>(
    'items',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMinorMeta = const VerificationMeta(
    'valueMinor',
  );
  @override
  late final GeneratedColumn<int> valueMinor = GeneratedColumn<int>(
    'value_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMinorMeta = const VerificationMeta(
    'subtotalMinor',
  );
  @override
  late final GeneratedColumn<int> subtotalMinor = GeneratedColumn<int>(
    'subtotal_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountMinorMeta = const VerificationMeta(
    'discountMinor',
  );
  @override
  late final GeneratedColumn<int> discountMinor = GeneratedColumn<int>(
    'discount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxMinorMeta = const VerificationMeta(
    'taxMinor',
  );
  @override
  late final GeneratedColumn<int> taxMinor = GeneratedColumn<int>(
    'tax_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsMinorMeta = const VerificationMeta(
    'pointsMinor',
  );
  @override
  late final GeneratedColumn<int> pointsMinor = GeneratedColumn<int>(
    'points_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMinorMeta = const VerificationMeta(
    'totalMinor',
  );
  @override
  late final GeneratedColumn<int> totalMinor = GeneratedColumn<int>(
    'total_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenderedMinorMeta = const VerificationMeta(
    'tenderedMinor',
  );
  @override
  late final GeneratedColumn<int> tenderedMinor = GeneratedColumn<int>(
    'tendered_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeMinorMeta = const VerificationMeta(
    'changeMinor',
  );
  @override
  late final GeneratedColumn<int> changeMinor = GeneratedColumn<int>(
    'change_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnedOrderMeta = const VerificationMeta(
    'returnedOrder',
  );
  @override
  late final GeneratedColumn<String> returnedOrder = GeneratedColumn<String>(
    'returned_order',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hasSaleId,
    number,
    position,
    occurredAt,
    storeName,
    storeId,
    counterId,
    userId,
    userName,
    customerName,
    customerLegacyId,
    customerId,
    currencyCode,
    mode,
    saleType,
    billDiscountType,
    billDiscountBp,
    billDiscountMinor,
    discountReason,
    pointsRedeemed,
    note,
    items,
    qtyMilli,
    valueMinor,
    subtotalMinor,
    discountMinor,
    taxMinor,
    pointsMinor,
    totalMinor,
    tenderedMinor,
    changeMinor,
    returnedOrder,
    createdAt,
    updatedAt,
    deletedAt,
    serverId,
    serverVersion,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('has_sale_id')) {
      context.handle(
        _hasSaleIdMeta,
        hasSaleId.isAcceptableOrUnknown(data['has_sale_id']!, _hasSaleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_hasSaleIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_storeNameMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('customer_legacy_id')) {
      context.handle(
        _customerLegacyIdMeta,
        customerLegacyId.isAcceptableOrUnknown(
          data['customer_legacy_id']!,
          _customerLegacyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerLegacyIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('sale_type')) {
      context.handle(
        _saleTypeMeta,
        saleType.isAcceptableOrUnknown(data['sale_type']!, _saleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_saleTypeMeta);
    }
    if (data.containsKey('bill_discount_type')) {
      context.handle(
        _billDiscountTypeMeta,
        billDiscountType.isAcceptableOrUnknown(
          data['bill_discount_type']!,
          _billDiscountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billDiscountTypeMeta);
    }
    if (data.containsKey('bill_discount_bp')) {
      context.handle(
        _billDiscountBpMeta,
        billDiscountBp.isAcceptableOrUnknown(
          data['bill_discount_bp']!,
          _billDiscountBpMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billDiscountBpMeta);
    }
    if (data.containsKey('bill_discount_minor')) {
      context.handle(
        _billDiscountMinorMeta,
        billDiscountMinor.isAcceptableOrUnknown(
          data['bill_discount_minor']!,
          _billDiscountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billDiscountMinorMeta);
    }
    if (data.containsKey('discount_reason')) {
      context.handle(
        _discountReasonMeta,
        discountReason.isAcceptableOrUnknown(
          data['discount_reason']!,
          _discountReasonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountReasonMeta);
    }
    if (data.containsKey('points_redeemed')) {
      context.handle(
        _pointsRedeemedMeta,
        pointsRedeemed.isAcceptableOrUnknown(
          data['points_redeemed']!,
          _pointsRedeemedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointsRedeemedMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('items')) {
      context.handle(
        _itemsMeta,
        items.isAcceptableOrUnknown(data['items']!, _itemsMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsMeta);
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('value_minor')) {
      context.handle(
        _valueMinorMeta,
        valueMinor.isAcceptableOrUnknown(data['value_minor']!, _valueMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMinorMeta);
    }
    if (data.containsKey('subtotal_minor')) {
      context.handle(
        _subtotalMinorMeta,
        subtotalMinor.isAcceptableOrUnknown(
          data['subtotal_minor']!,
          _subtotalMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtotalMinorMeta);
    }
    if (data.containsKey('discount_minor')) {
      context.handle(
        _discountMinorMeta,
        discountMinor.isAcceptableOrUnknown(
          data['discount_minor']!,
          _discountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountMinorMeta);
    }
    if (data.containsKey('tax_minor')) {
      context.handle(
        _taxMinorMeta,
        taxMinor.isAcceptableOrUnknown(data['tax_minor']!, _taxMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_taxMinorMeta);
    }
    if (data.containsKey('points_minor')) {
      context.handle(
        _pointsMinorMeta,
        pointsMinor.isAcceptableOrUnknown(
          data['points_minor']!,
          _pointsMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointsMinorMeta);
    }
    if (data.containsKey('total_minor')) {
      context.handle(
        _totalMinorMeta,
        totalMinor.isAcceptableOrUnknown(data['total_minor']!, _totalMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMinorMeta);
    }
    if (data.containsKey('tendered_minor')) {
      context.handle(
        _tenderedMinorMeta,
        tenderedMinor.isAcceptableOrUnknown(
          data['tendered_minor']!,
          _tenderedMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tenderedMinorMeta);
    }
    if (data.containsKey('change_minor')) {
      context.handle(
        _changeMinorMeta,
        changeMinor.isAcceptableOrUnknown(
          data['change_minor']!,
          _changeMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changeMinorMeta);
    }
    if (data.containsKey('returned_order')) {
      context.handle(
        _returnedOrderMeta,
        returnedOrder.isAcceptableOrUnknown(
          data['returned_order']!,
          _returnedOrderMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hasSaleId: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_sale_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_at'],
      )!,
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerLegacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_legacy_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      saleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_type'],
      )!,
      billDiscountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_discount_type'],
      )!,
      billDiscountBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bill_discount_bp'],
      )!,
      billDiscountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bill_discount_minor'],
      )!,
      discountReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_reason'],
      )!,
      pointsRedeemed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_redeemed'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      items: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items'],
      )!,
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      valueMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_minor'],
      )!,
      subtotalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_minor'],
      )!,
      discountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_minor'],
      )!,
      taxMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_minor'],
      )!,
      pointsMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_minor'],
      )!,
      totalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor'],
      )!,
      tenderedMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tendered_minor'],
      )!,
      changeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_minor'],
      )!,
      returnedOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}returned_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $SaleEntriesTable createAlias(String alias) {
    return $SaleEntriesTable(attachedDatabase, alias);
  }
}

class SaleEntry extends DataClass implements Insertable<SaleEntry> {
  final String id;

  /// True when `id` is the sale's own `saleId`; false for a legacy sale whose
  /// UUID was generated by the copy (the mirror never writes that id into the
  /// LocalStore JSON, DEC-123).
  final bool hasSaleId;
  final String number;

  /// Index in the app's sales list (the list order is observable).
  final int position;

  /// `Sale.date` verbatim (UTC ISO text, never parsed here).
  final String occurredAt;
  final String storeName;

  /// Session context of the sale (v9); null on legacy rows.
  final String? storeId;
  final String? counterId;
  final String? userId;

  /// Cashier display name at the time of the sale.
  final String? userName;
  final String customerName;

  /// `cart.customer` verbatim (the legacy customer id; needed for a byte-exact
  /// cart snapshot).
  final String customerLegacyId;

  /// Resolved link to `customers.id`; null until the customer row is known.
  /// Derived data: filled once, never overwritten.
  final String? customerId;

  /// PROPOSED default INR (DEC-124).
  final String currencyCode;

  /// Cash, Card or Credit as stored by the app.
  final String mode;
  final String saleType;
  final String billDiscountType;
  final int billDiscountBp;
  final int billDiscountMinor;
  final String discountReason;
  final int pointsRedeemed;
  final String note;
  final int items;
  final int qtyMilli;
  final int valueMinor;
  final int subtotalMinor;
  final int discountMinor;
  final int taxMinor;
  final int pointsMinor;
  final int totalMinor;
  final int tenderedMinor;
  final int changeMinor;

  /// JSON array of product ids, first returned first.
  final String returnedOrder;

  /// UTC ISO 8601 text; `updated_at` changes only when a return is applied.
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? serverId;
  final int? serverVersion;
  final String? deviceId;
  const SaleEntry({
    required this.id,
    required this.hasSaleId,
    required this.number,
    required this.position,
    required this.occurredAt,
    required this.storeName,
    this.storeId,
    this.counterId,
    this.userId,
    this.userName,
    required this.customerName,
    required this.customerLegacyId,
    this.customerId,
    required this.currencyCode,
    required this.mode,
    required this.saleType,
    required this.billDiscountType,
    required this.billDiscountBp,
    required this.billDiscountMinor,
    required this.discountReason,
    required this.pointsRedeemed,
    required this.note,
    required this.items,
    required this.qtyMilli,
    required this.valueMinor,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.taxMinor,
    required this.pointsMinor,
    required this.totalMinor,
    required this.tenderedMinor,
    required this.changeMinor,
    required this.returnedOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.serverId,
    this.serverVersion,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['has_sale_id'] = Variable<bool>(hasSaleId);
    map['number'] = Variable<String>(number);
    map['position'] = Variable<int>(position);
    map['occurred_at'] = Variable<String>(occurredAt);
    map['store_name'] = Variable<String>(storeName);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || counterId != null) {
      map['counter_id'] = Variable<String>(counterId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    map['customer_name'] = Variable<String>(customerName);
    map['customer_legacy_id'] = Variable<String>(customerLegacyId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['mode'] = Variable<String>(mode);
    map['sale_type'] = Variable<String>(saleType);
    map['bill_discount_type'] = Variable<String>(billDiscountType);
    map['bill_discount_bp'] = Variable<int>(billDiscountBp);
    map['bill_discount_minor'] = Variable<int>(billDiscountMinor);
    map['discount_reason'] = Variable<String>(discountReason);
    map['points_redeemed'] = Variable<int>(pointsRedeemed);
    map['note'] = Variable<String>(note);
    map['items'] = Variable<int>(items);
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['value_minor'] = Variable<int>(valueMinor);
    map['subtotal_minor'] = Variable<int>(subtotalMinor);
    map['discount_minor'] = Variable<int>(discountMinor);
    map['tax_minor'] = Variable<int>(taxMinor);
    map['points_minor'] = Variable<int>(pointsMinor);
    map['total_minor'] = Variable<int>(totalMinor);
    map['tendered_minor'] = Variable<int>(tenderedMinor);
    map['change_minor'] = Variable<int>(changeMinor);
    map['returned_order'] = Variable<String>(returnedOrder);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  SaleEntriesCompanion toCompanion(bool nullToAbsent) {
    return SaleEntriesCompanion(
      id: Value(id),
      hasSaleId: Value(hasSaleId),
      number: Value(number),
      position: Value(position),
      occurredAt: Value(occurredAt),
      storeName: Value(storeName),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      counterId: counterId == null && nullToAbsent
          ? const Value.absent()
          : Value(counterId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      customerName: Value(customerName),
      customerLegacyId: Value(customerLegacyId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      currencyCode: Value(currencyCode),
      mode: Value(mode),
      saleType: Value(saleType),
      billDiscountType: Value(billDiscountType),
      billDiscountBp: Value(billDiscountBp),
      billDiscountMinor: Value(billDiscountMinor),
      discountReason: Value(discountReason),
      pointsRedeemed: Value(pointsRedeemed),
      note: Value(note),
      items: Value(items),
      qtyMilli: Value(qtyMilli),
      valueMinor: Value(valueMinor),
      subtotalMinor: Value(subtotalMinor),
      discountMinor: Value(discountMinor),
      taxMinor: Value(taxMinor),
      pointsMinor: Value(pointsMinor),
      totalMinor: Value(totalMinor),
      tenderedMinor: Value(tenderedMinor),
      changeMinor: Value(changeMinor),
      returnedOrder: Value(returnedOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory SaleEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleEntry(
      id: serializer.fromJson<String>(json['id']),
      hasSaleId: serializer.fromJson<bool>(json['hasSaleId']),
      number: serializer.fromJson<String>(json['number']),
      position: serializer.fromJson<int>(json['position']),
      occurredAt: serializer.fromJson<String>(json['occurredAt']),
      storeName: serializer.fromJson<String>(json['storeName']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      counterId: serializer.fromJson<String?>(json['counterId']),
      userId: serializer.fromJson<String?>(json['userId']),
      userName: serializer.fromJson<String?>(json['userName']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerLegacyId: serializer.fromJson<String>(json['customerLegacyId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      mode: serializer.fromJson<String>(json['mode']),
      saleType: serializer.fromJson<String>(json['saleType']),
      billDiscountType: serializer.fromJson<String>(json['billDiscountType']),
      billDiscountBp: serializer.fromJson<int>(json['billDiscountBp']),
      billDiscountMinor: serializer.fromJson<int>(json['billDiscountMinor']),
      discountReason: serializer.fromJson<String>(json['discountReason']),
      pointsRedeemed: serializer.fromJson<int>(json['pointsRedeemed']),
      note: serializer.fromJson<String>(json['note']),
      items: serializer.fromJson<int>(json['items']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      valueMinor: serializer.fromJson<int>(json['valueMinor']),
      subtotalMinor: serializer.fromJson<int>(json['subtotalMinor']),
      discountMinor: serializer.fromJson<int>(json['discountMinor']),
      taxMinor: serializer.fromJson<int>(json['taxMinor']),
      pointsMinor: serializer.fromJson<int>(json['pointsMinor']),
      totalMinor: serializer.fromJson<int>(json['totalMinor']),
      tenderedMinor: serializer.fromJson<int>(json['tenderedMinor']),
      changeMinor: serializer.fromJson<int>(json['changeMinor']),
      returnedOrder: serializer.fromJson<String>(json['returnedOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hasSaleId': serializer.toJson<bool>(hasSaleId),
      'number': serializer.toJson<String>(number),
      'position': serializer.toJson<int>(position),
      'occurredAt': serializer.toJson<String>(occurredAt),
      'storeName': serializer.toJson<String>(storeName),
      'storeId': serializer.toJson<String?>(storeId),
      'counterId': serializer.toJson<String?>(counterId),
      'userId': serializer.toJson<String?>(userId),
      'userName': serializer.toJson<String?>(userName),
      'customerName': serializer.toJson<String>(customerName),
      'customerLegacyId': serializer.toJson<String>(customerLegacyId),
      'customerId': serializer.toJson<String?>(customerId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'mode': serializer.toJson<String>(mode),
      'saleType': serializer.toJson<String>(saleType),
      'billDiscountType': serializer.toJson<String>(billDiscountType),
      'billDiscountBp': serializer.toJson<int>(billDiscountBp),
      'billDiscountMinor': serializer.toJson<int>(billDiscountMinor),
      'discountReason': serializer.toJson<String>(discountReason),
      'pointsRedeemed': serializer.toJson<int>(pointsRedeemed),
      'note': serializer.toJson<String>(note),
      'items': serializer.toJson<int>(items),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'valueMinor': serializer.toJson<int>(valueMinor),
      'subtotalMinor': serializer.toJson<int>(subtotalMinor),
      'discountMinor': serializer.toJson<int>(discountMinor),
      'taxMinor': serializer.toJson<int>(taxMinor),
      'pointsMinor': serializer.toJson<int>(pointsMinor),
      'totalMinor': serializer.toJson<int>(totalMinor),
      'tenderedMinor': serializer.toJson<int>(tenderedMinor),
      'changeMinor': serializer.toJson<int>(changeMinor),
      'returnedOrder': serializer.toJson<String>(returnedOrder),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'serverId': serializer.toJson<String?>(serverId),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  SaleEntry copyWith({
    String? id,
    bool? hasSaleId,
    String? number,
    int? position,
    String? occurredAt,
    String? storeName,
    Value<String?> storeId = const Value.absent(),
    Value<String?> counterId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    Value<String?> userName = const Value.absent(),
    String? customerName,
    String? customerLegacyId,
    Value<String?> customerId = const Value.absent(),
    String? currencyCode,
    String? mode,
    String? saleType,
    String? billDiscountType,
    int? billDiscountBp,
    int? billDiscountMinor,
    String? discountReason,
    int? pointsRedeemed,
    String? note,
    int? items,
    int? qtyMilli,
    int? valueMinor,
    int? subtotalMinor,
    int? discountMinor,
    int? taxMinor,
    int? pointsMinor,
    int? totalMinor,
    int? tenderedMinor,
    int? changeMinor,
    String? returnedOrder,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    Value<String?> serverId = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
  }) => SaleEntry(
    id: id ?? this.id,
    hasSaleId: hasSaleId ?? this.hasSaleId,
    number: number ?? this.number,
    position: position ?? this.position,
    occurredAt: occurredAt ?? this.occurredAt,
    storeName: storeName ?? this.storeName,
    storeId: storeId.present ? storeId.value : this.storeId,
    counterId: counterId.present ? counterId.value : this.counterId,
    userId: userId.present ? userId.value : this.userId,
    userName: userName.present ? userName.value : this.userName,
    customerName: customerName ?? this.customerName,
    customerLegacyId: customerLegacyId ?? this.customerLegacyId,
    customerId: customerId.present ? customerId.value : this.customerId,
    currencyCode: currencyCode ?? this.currencyCode,
    mode: mode ?? this.mode,
    saleType: saleType ?? this.saleType,
    billDiscountType: billDiscountType ?? this.billDiscountType,
    billDiscountBp: billDiscountBp ?? this.billDiscountBp,
    billDiscountMinor: billDiscountMinor ?? this.billDiscountMinor,
    discountReason: discountReason ?? this.discountReason,
    pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
    note: note ?? this.note,
    items: items ?? this.items,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    valueMinor: valueMinor ?? this.valueMinor,
    subtotalMinor: subtotalMinor ?? this.subtotalMinor,
    discountMinor: discountMinor ?? this.discountMinor,
    taxMinor: taxMinor ?? this.taxMinor,
    pointsMinor: pointsMinor ?? this.pointsMinor,
    totalMinor: totalMinor ?? this.totalMinor,
    tenderedMinor: tenderedMinor ?? this.tenderedMinor,
    changeMinor: changeMinor ?? this.changeMinor,
    returnedOrder: returnedOrder ?? this.returnedOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    serverId: serverId.present ? serverId.value : this.serverId,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  SaleEntry copyWithCompanion(SaleEntriesCompanion data) {
    return SaleEntry(
      id: data.id.present ? data.id.value : this.id,
      hasSaleId: data.hasSaleId.present ? data.hasSaleId.value : this.hasSaleId,
      number: data.number.present ? data.number.value : this.number,
      position: data.position.present ? data.position.value : this.position,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerLegacyId: data.customerLegacyId.present
          ? data.customerLegacyId.value
          : this.customerLegacyId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      mode: data.mode.present ? data.mode.value : this.mode,
      saleType: data.saleType.present ? data.saleType.value : this.saleType,
      billDiscountType: data.billDiscountType.present
          ? data.billDiscountType.value
          : this.billDiscountType,
      billDiscountBp: data.billDiscountBp.present
          ? data.billDiscountBp.value
          : this.billDiscountBp,
      billDiscountMinor: data.billDiscountMinor.present
          ? data.billDiscountMinor.value
          : this.billDiscountMinor,
      discountReason: data.discountReason.present
          ? data.discountReason.value
          : this.discountReason,
      pointsRedeemed: data.pointsRedeemed.present
          ? data.pointsRedeemed.value
          : this.pointsRedeemed,
      note: data.note.present ? data.note.value : this.note,
      items: data.items.present ? data.items.value : this.items,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      valueMinor: data.valueMinor.present
          ? data.valueMinor.value
          : this.valueMinor,
      subtotalMinor: data.subtotalMinor.present
          ? data.subtotalMinor.value
          : this.subtotalMinor,
      discountMinor: data.discountMinor.present
          ? data.discountMinor.value
          : this.discountMinor,
      taxMinor: data.taxMinor.present ? data.taxMinor.value : this.taxMinor,
      pointsMinor: data.pointsMinor.present
          ? data.pointsMinor.value
          : this.pointsMinor,
      totalMinor: data.totalMinor.present
          ? data.totalMinor.value
          : this.totalMinor,
      tenderedMinor: data.tenderedMinor.present
          ? data.tenderedMinor.value
          : this.tenderedMinor,
      changeMinor: data.changeMinor.present
          ? data.changeMinor.value
          : this.changeMinor,
      returnedOrder: data.returnedOrder.present
          ? data.returnedOrder.value
          : this.returnedOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleEntry(')
          ..write('id: $id, ')
          ..write('hasSaleId: $hasSaleId, ')
          ..write('number: $number, ')
          ..write('position: $position, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('storeName: $storeName, ')
          ..write('storeId: $storeId, ')
          ..write('counterId: $counterId, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('customerName: $customerName, ')
          ..write('customerLegacyId: $customerLegacyId, ')
          ..write('customerId: $customerId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('mode: $mode, ')
          ..write('saleType: $saleType, ')
          ..write('billDiscountType: $billDiscountType, ')
          ..write('billDiscountBp: $billDiscountBp, ')
          ..write('billDiscountMinor: $billDiscountMinor, ')
          ..write('discountReason: $discountReason, ')
          ..write('pointsRedeemed: $pointsRedeemed, ')
          ..write('note: $note, ')
          ..write('items: $items, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('valueMinor: $valueMinor, ')
          ..write('subtotalMinor: $subtotalMinor, ')
          ..write('discountMinor: $discountMinor, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('pointsMinor: $pointsMinor, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('tenderedMinor: $tenderedMinor, ')
          ..write('changeMinor: $changeMinor, ')
          ..write('returnedOrder: $returnedOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverId: $serverId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    hasSaleId,
    number,
    position,
    occurredAt,
    storeName,
    storeId,
    counterId,
    userId,
    userName,
    customerName,
    customerLegacyId,
    customerId,
    currencyCode,
    mode,
    saleType,
    billDiscountType,
    billDiscountBp,
    billDiscountMinor,
    discountReason,
    pointsRedeemed,
    note,
    items,
    qtyMilli,
    valueMinor,
    subtotalMinor,
    discountMinor,
    taxMinor,
    pointsMinor,
    totalMinor,
    tenderedMinor,
    changeMinor,
    returnedOrder,
    createdAt,
    updatedAt,
    deletedAt,
    serverId,
    serverVersion,
    deviceId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleEntry &&
          other.id == this.id &&
          other.hasSaleId == this.hasSaleId &&
          other.number == this.number &&
          other.position == this.position &&
          other.occurredAt == this.occurredAt &&
          other.storeName == this.storeName &&
          other.storeId == this.storeId &&
          other.counterId == this.counterId &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.customerName == this.customerName &&
          other.customerLegacyId == this.customerLegacyId &&
          other.customerId == this.customerId &&
          other.currencyCode == this.currencyCode &&
          other.mode == this.mode &&
          other.saleType == this.saleType &&
          other.billDiscountType == this.billDiscountType &&
          other.billDiscountBp == this.billDiscountBp &&
          other.billDiscountMinor == this.billDiscountMinor &&
          other.discountReason == this.discountReason &&
          other.pointsRedeemed == this.pointsRedeemed &&
          other.note == this.note &&
          other.items == this.items &&
          other.qtyMilli == this.qtyMilli &&
          other.valueMinor == this.valueMinor &&
          other.subtotalMinor == this.subtotalMinor &&
          other.discountMinor == this.discountMinor &&
          other.taxMinor == this.taxMinor &&
          other.pointsMinor == this.pointsMinor &&
          other.totalMinor == this.totalMinor &&
          other.tenderedMinor == this.tenderedMinor &&
          other.changeMinor == this.changeMinor &&
          other.returnedOrder == this.returnedOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.serverId == this.serverId &&
          other.serverVersion == this.serverVersion &&
          other.deviceId == this.deviceId);
}

class SaleEntriesCompanion extends UpdateCompanion<SaleEntry> {
  final Value<String> id;
  final Value<bool> hasSaleId;
  final Value<String> number;
  final Value<int> position;
  final Value<String> occurredAt;
  final Value<String> storeName;
  final Value<String?> storeId;
  final Value<String?> counterId;
  final Value<String?> userId;
  final Value<String?> userName;
  final Value<String> customerName;
  final Value<String> customerLegacyId;
  final Value<String?> customerId;
  final Value<String> currencyCode;
  final Value<String> mode;
  final Value<String> saleType;
  final Value<String> billDiscountType;
  final Value<int> billDiscountBp;
  final Value<int> billDiscountMinor;
  final Value<String> discountReason;
  final Value<int> pointsRedeemed;
  final Value<String> note;
  final Value<int> items;
  final Value<int> qtyMilli;
  final Value<int> valueMinor;
  final Value<int> subtotalMinor;
  final Value<int> discountMinor;
  final Value<int> taxMinor;
  final Value<int> pointsMinor;
  final Value<int> totalMinor;
  final Value<int> tenderedMinor;
  final Value<int> changeMinor;
  final Value<String> returnedOrder;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String?> serverId;
  final Value<int?> serverVersion;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const SaleEntriesCompanion({
    this.id = const Value.absent(),
    this.hasSaleId = const Value.absent(),
    this.number = const Value.absent(),
    this.position = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.storeName = const Value.absent(),
    this.storeId = const Value.absent(),
    this.counterId = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerLegacyId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.mode = const Value.absent(),
    this.saleType = const Value.absent(),
    this.billDiscountType = const Value.absent(),
    this.billDiscountBp = const Value.absent(),
    this.billDiscountMinor = const Value.absent(),
    this.discountReason = const Value.absent(),
    this.pointsRedeemed = const Value.absent(),
    this.note = const Value.absent(),
    this.items = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.valueMinor = const Value.absent(),
    this.subtotalMinor = const Value.absent(),
    this.discountMinor = const Value.absent(),
    this.taxMinor = const Value.absent(),
    this.pointsMinor = const Value.absent(),
    this.totalMinor = const Value.absent(),
    this.tenderedMinor = const Value.absent(),
    this.changeMinor = const Value.absent(),
    this.returnedOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleEntriesCompanion.insert({
    required String id,
    required bool hasSaleId,
    required String number,
    required int position,
    required String occurredAt,
    required String storeName,
    this.storeId = const Value.absent(),
    this.counterId = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    required String customerName,
    required String customerLegacyId,
    this.customerId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    required String mode,
    required String saleType,
    required String billDiscountType,
    required int billDiscountBp,
    required int billDiscountMinor,
    required String discountReason,
    required int pointsRedeemed,
    required String note,
    required int items,
    required int qtyMilli,
    required int valueMinor,
    required int subtotalMinor,
    required int discountMinor,
    required int taxMinor,
    required int pointsMinor,
    required int totalMinor,
    required int tenderedMinor,
    required int changeMinor,
    this.returnedOrder = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hasSaleId = Value(hasSaleId),
       number = Value(number),
       position = Value(position),
       occurredAt = Value(occurredAt),
       storeName = Value(storeName),
       customerName = Value(customerName),
       customerLegacyId = Value(customerLegacyId),
       mode = Value(mode),
       saleType = Value(saleType),
       billDiscountType = Value(billDiscountType),
       billDiscountBp = Value(billDiscountBp),
       billDiscountMinor = Value(billDiscountMinor),
       discountReason = Value(discountReason),
       pointsRedeemed = Value(pointsRedeemed),
       note = Value(note),
       items = Value(items),
       qtyMilli = Value(qtyMilli),
       valueMinor = Value(valueMinor),
       subtotalMinor = Value(subtotalMinor),
       discountMinor = Value(discountMinor),
       taxMinor = Value(taxMinor),
       pointsMinor = Value(pointsMinor),
       totalMinor = Value(totalMinor),
       tenderedMinor = Value(tenderedMinor),
       changeMinor = Value(changeMinor),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SaleEntry> custom({
    Expression<String>? id,
    Expression<bool>? hasSaleId,
    Expression<String>? number,
    Expression<int>? position,
    Expression<String>? occurredAt,
    Expression<String>? storeName,
    Expression<String>? storeId,
    Expression<String>? counterId,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<String>? customerName,
    Expression<String>? customerLegacyId,
    Expression<String>? customerId,
    Expression<String>? currencyCode,
    Expression<String>? mode,
    Expression<String>? saleType,
    Expression<String>? billDiscountType,
    Expression<int>? billDiscountBp,
    Expression<int>? billDiscountMinor,
    Expression<String>? discountReason,
    Expression<int>? pointsRedeemed,
    Expression<String>? note,
    Expression<int>? items,
    Expression<int>? qtyMilli,
    Expression<int>? valueMinor,
    Expression<int>? subtotalMinor,
    Expression<int>? discountMinor,
    Expression<int>? taxMinor,
    Expression<int>? pointsMinor,
    Expression<int>? totalMinor,
    Expression<int>? tenderedMinor,
    Expression<int>? changeMinor,
    Expression<String>? returnedOrder,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? serverId,
    Expression<int>? serverVersion,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hasSaleId != null) 'has_sale_id': hasSaleId,
      if (number != null) 'number': number,
      if (position != null) 'position': position,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (storeName != null) 'store_name': storeName,
      if (storeId != null) 'store_id': storeId,
      if (counterId != null) 'counter_id': counterId,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (customerName != null) 'customer_name': customerName,
      if (customerLegacyId != null) 'customer_legacy_id': customerLegacyId,
      if (customerId != null) 'customer_id': customerId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (mode != null) 'mode': mode,
      if (saleType != null) 'sale_type': saleType,
      if (billDiscountType != null) 'bill_discount_type': billDiscountType,
      if (billDiscountBp != null) 'bill_discount_bp': billDiscountBp,
      if (billDiscountMinor != null) 'bill_discount_minor': billDiscountMinor,
      if (discountReason != null) 'discount_reason': discountReason,
      if (pointsRedeemed != null) 'points_redeemed': pointsRedeemed,
      if (note != null) 'note': note,
      if (items != null) 'items': items,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (valueMinor != null) 'value_minor': valueMinor,
      if (subtotalMinor != null) 'subtotal_minor': subtotalMinor,
      if (discountMinor != null) 'discount_minor': discountMinor,
      if (taxMinor != null) 'tax_minor': taxMinor,
      if (pointsMinor != null) 'points_minor': pointsMinor,
      if (totalMinor != null) 'total_minor': totalMinor,
      if (tenderedMinor != null) 'tendered_minor': tenderedMinor,
      if (changeMinor != null) 'change_minor': changeMinor,
      if (returnedOrder != null) 'returned_order': returnedOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (serverId != null) 'server_id': serverId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleEntriesCompanion copyWith({
    Value<String>? id,
    Value<bool>? hasSaleId,
    Value<String>? number,
    Value<int>? position,
    Value<String>? occurredAt,
    Value<String>? storeName,
    Value<String?>? storeId,
    Value<String?>? counterId,
    Value<String?>? userId,
    Value<String?>? userName,
    Value<String>? customerName,
    Value<String>? customerLegacyId,
    Value<String?>? customerId,
    Value<String>? currencyCode,
    Value<String>? mode,
    Value<String>? saleType,
    Value<String>? billDiscountType,
    Value<int>? billDiscountBp,
    Value<int>? billDiscountMinor,
    Value<String>? discountReason,
    Value<int>? pointsRedeemed,
    Value<String>? note,
    Value<int>? items,
    Value<int>? qtyMilli,
    Value<int>? valueMinor,
    Value<int>? subtotalMinor,
    Value<int>? discountMinor,
    Value<int>? taxMinor,
    Value<int>? pointsMinor,
    Value<int>? totalMinor,
    Value<int>? tenderedMinor,
    Value<int>? changeMinor,
    Value<String>? returnedOrder,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String?>? serverId,
    Value<int?>? serverVersion,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return SaleEntriesCompanion(
      id: id ?? this.id,
      hasSaleId: hasSaleId ?? this.hasSaleId,
      number: number ?? this.number,
      position: position ?? this.position,
      occurredAt: occurredAt ?? this.occurredAt,
      storeName: storeName ?? this.storeName,
      storeId: storeId ?? this.storeId,
      counterId: counterId ?? this.counterId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      customerName: customerName ?? this.customerName,
      customerLegacyId: customerLegacyId ?? this.customerLegacyId,
      customerId: customerId ?? this.customerId,
      currencyCode: currencyCode ?? this.currencyCode,
      mode: mode ?? this.mode,
      saleType: saleType ?? this.saleType,
      billDiscountType: billDiscountType ?? this.billDiscountType,
      billDiscountBp: billDiscountBp ?? this.billDiscountBp,
      billDiscountMinor: billDiscountMinor ?? this.billDiscountMinor,
      discountReason: discountReason ?? this.discountReason,
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
      note: note ?? this.note,
      items: items ?? this.items,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      valueMinor: valueMinor ?? this.valueMinor,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      discountMinor: discountMinor ?? this.discountMinor,
      taxMinor: taxMinor ?? this.taxMinor,
      pointsMinor: pointsMinor ?? this.pointsMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      tenderedMinor: tenderedMinor ?? this.tenderedMinor,
      changeMinor: changeMinor ?? this.changeMinor,
      returnedOrder: returnedOrder ?? this.returnedOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      serverId: serverId ?? this.serverId,
      serverVersion: serverVersion ?? this.serverVersion,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hasSaleId.present) {
      map['has_sale_id'] = Variable<bool>(hasSaleId.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(occurredAt.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerLegacyId.present) {
      map['customer_legacy_id'] = Variable<String>(customerLegacyId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (saleType.present) {
      map['sale_type'] = Variable<String>(saleType.value);
    }
    if (billDiscountType.present) {
      map['bill_discount_type'] = Variable<String>(billDiscountType.value);
    }
    if (billDiscountBp.present) {
      map['bill_discount_bp'] = Variable<int>(billDiscountBp.value);
    }
    if (billDiscountMinor.present) {
      map['bill_discount_minor'] = Variable<int>(billDiscountMinor.value);
    }
    if (discountReason.present) {
      map['discount_reason'] = Variable<String>(discountReason.value);
    }
    if (pointsRedeemed.present) {
      map['points_redeemed'] = Variable<int>(pointsRedeemed.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (items.present) {
      map['items'] = Variable<int>(items.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (valueMinor.present) {
      map['value_minor'] = Variable<int>(valueMinor.value);
    }
    if (subtotalMinor.present) {
      map['subtotal_minor'] = Variable<int>(subtotalMinor.value);
    }
    if (discountMinor.present) {
      map['discount_minor'] = Variable<int>(discountMinor.value);
    }
    if (taxMinor.present) {
      map['tax_minor'] = Variable<int>(taxMinor.value);
    }
    if (pointsMinor.present) {
      map['points_minor'] = Variable<int>(pointsMinor.value);
    }
    if (totalMinor.present) {
      map['total_minor'] = Variable<int>(totalMinor.value);
    }
    if (tenderedMinor.present) {
      map['tendered_minor'] = Variable<int>(tenderedMinor.value);
    }
    if (changeMinor.present) {
      map['change_minor'] = Variable<int>(changeMinor.value);
    }
    if (returnedOrder.present) {
      map['returned_order'] = Variable<String>(returnedOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('hasSaleId: $hasSaleId, ')
          ..write('number: $number, ')
          ..write('position: $position, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('storeName: $storeName, ')
          ..write('storeId: $storeId, ')
          ..write('counterId: $counterId, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('customerName: $customerName, ')
          ..write('customerLegacyId: $customerLegacyId, ')
          ..write('customerId: $customerId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('mode: $mode, ')
          ..write('saleType: $saleType, ')
          ..write('billDiscountType: $billDiscountType, ')
          ..write('billDiscountBp: $billDiscountBp, ')
          ..write('billDiscountMinor: $billDiscountMinor, ')
          ..write('discountReason: $discountReason, ')
          ..write('pointsRedeemed: $pointsRedeemed, ')
          ..write('note: $note, ')
          ..write('items: $items, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('valueMinor: $valueMinor, ')
          ..write('subtotalMinor: $subtotalMinor, ')
          ..write('discountMinor: $discountMinor, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('pointsMinor: $pointsMinor, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('tenderedMinor: $tenderedMinor, ')
          ..write('changeMinor: $changeMinor, ')
          ..write('returnedOrder: $returnedOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('serverId: $serverId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleLineEntriesTable extends SaleLineEntries
    with TableInfo<$SaleLineEntriesTable, SaleLineEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleLineEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _lineNoMeta = const VerificationMeta('lineNo');
  @override
  late final GeneratedColumn<int> lineNo = GeneratedColumn<int>(
    'line_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _productLegacyIdMeta = const VerificationMeta(
    'productLegacyId',
  );
  @override
  late final GeneratedColumn<int> productLegacyId = GeneratedColumn<int>(
    'product_legacy_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productBarcodeMeta = const VerificationMeta(
    'productBarcode',
  );
  @override
  late final GeneratedColumn<String> productBarcode = GeneratedColumn<String>(
    'product_barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productPriceMinorMeta = const VerificationMeta(
    'productPriceMinor',
  );
  @override
  late final GeneratedColumn<int> productPriceMinor = GeneratedColumn<int>(
    'product_price_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productCategoryMeta = const VerificationMeta(
    'productCategory',
  );
  @override
  late final GeneratedColumn<String> productCategory = GeneratedColumn<String>(
    'product_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productSubMeta = const VerificationMeta(
    'productSub',
  );
  @override
  late final GeneratedColumn<String> productSub = GeneratedColumn<String>(
    'product_sub',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productStockMeta = const VerificationMeta(
    'productStock',
  );
  @override
  late final GeneratedColumn<int> productStock = GeneratedColumn<int>(
    'product_stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productGstBpMeta = const VerificationMeta(
    'productGstBp',
  );
  @override
  late final GeneratedColumn<int> productGstBp = GeneratedColumn<int>(
    'product_gst_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productImageMeta = const VerificationMeta(
    'productImage',
  );
  @override
  late final GeneratedColumn<int> productImage = GeneratedColumn<int>(
    'product_image',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productFavouriteMeta = const VerificationMeta(
    'productFavourite',
  );
  @override
  late final GeneratedColumn<bool> productFavourite = GeneratedColumn<bool>(
    'product_favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("product_favourite" IN (0, 1))',
    ),
  );
  static const VerificationMeta _priceMinorMeta = const VerificationMeta(
    'priceMinor',
  );
  @override
  late final GeneratedColumn<int> priceMinor = GeneratedColumn<int>(
    'price_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountBpMeta = const VerificationMeta(
    'discountBp',
  );
  @override
  late final GeneratedColumn<int> discountBp = GeneratedColumn<int>(
    'discount_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offerKindMeta = const VerificationMeta(
    'offerKind',
  );
  @override
  late final GeneratedColumn<String> offerKind = GeneratedColumn<String>(
    'offer_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offerNameMeta = const VerificationMeta(
    'offerName',
  );
  @override
  late final GeneratedColumn<String> offerName = GeneratedColumn<String>(
    'offer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offerSavingMinorMeta = const VerificationMeta(
    'offerSavingMinor',
  );
  @override
  late final GeneratedColumn<int> offerSavingMinor = GeneratedColumn<int>(
    'offer_saving_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offerUnitOffMinorMeta = const VerificationMeta(
    'offerUnitOffMinor',
  );
  @override
  late final GeneratedColumn<int> offerUnitOffMinor = GeneratedColumn<int>(
    'offer_unit_off_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isGiftMeta = const VerificationMeta('isGift');
  @override
  late final GeneratedColumn<bool> isGift = GeneratedColumn<bool>(
    'is_gift',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_gift" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _returnedQtyMilliMeta = const VerificationMeta(
    'returnedQtyMilli',
  );
  @override
  late final GeneratedColumn<int> returnedQtyMilli = GeneratedColumn<int>(
    'returned_qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    lineNo,
    productId,
    productLegacyId,
    productName,
    productCode,
    productBarcode,
    productPriceMinor,
    productCategory,
    productSub,
    productStock,
    productGstBp,
    productImage,
    productFavourite,
    priceMinor,
    qtyMilli,
    discountBp,
    offerKind,
    offerName,
    offerSavingMinor,
    offerUnitOffMinor,
    isGift,
    returnedQtyMilli,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleLineEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('line_no')) {
      context.handle(
        _lineNoMeta,
        lineNo.isAcceptableOrUnknown(data['line_no']!, _lineNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNoMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('product_legacy_id')) {
      context.handle(
        _productLegacyIdMeta,
        productLegacyId.isAcceptableOrUnknown(
          data['product_legacy_id']!,
          _productLegacyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productLegacyIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('product_barcode')) {
      context.handle(
        _productBarcodeMeta,
        productBarcode.isAcceptableOrUnknown(
          data['product_barcode']!,
          _productBarcodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productBarcodeMeta);
    }
    if (data.containsKey('product_price_minor')) {
      context.handle(
        _productPriceMinorMeta,
        productPriceMinor.isAcceptableOrUnknown(
          data['product_price_minor']!,
          _productPriceMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productPriceMinorMeta);
    }
    if (data.containsKey('product_category')) {
      context.handle(
        _productCategoryMeta,
        productCategory.isAcceptableOrUnknown(
          data['product_category']!,
          _productCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productCategoryMeta);
    }
    if (data.containsKey('product_sub')) {
      context.handle(
        _productSubMeta,
        productSub.isAcceptableOrUnknown(data['product_sub']!, _productSubMeta),
      );
    } else if (isInserting) {
      context.missing(_productSubMeta);
    }
    if (data.containsKey('product_stock')) {
      context.handle(
        _productStockMeta,
        productStock.isAcceptableOrUnknown(
          data['product_stock']!,
          _productStockMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productStockMeta);
    }
    if (data.containsKey('product_gst_bp')) {
      context.handle(
        _productGstBpMeta,
        productGstBp.isAcceptableOrUnknown(
          data['product_gst_bp']!,
          _productGstBpMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productGstBpMeta);
    }
    if (data.containsKey('product_image')) {
      context.handle(
        _productImageMeta,
        productImage.isAcceptableOrUnknown(
          data['product_image']!,
          _productImageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productImageMeta);
    }
    if (data.containsKey('product_favourite')) {
      context.handle(
        _productFavouriteMeta,
        productFavourite.isAcceptableOrUnknown(
          data['product_favourite']!,
          _productFavouriteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productFavouriteMeta);
    }
    if (data.containsKey('price_minor')) {
      context.handle(
        _priceMinorMeta,
        priceMinor.isAcceptableOrUnknown(data['price_minor']!, _priceMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMinorMeta);
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('discount_bp')) {
      context.handle(
        _discountBpMeta,
        discountBp.isAcceptableOrUnknown(data['discount_bp']!, _discountBpMeta),
      );
    } else if (isInserting) {
      context.missing(_discountBpMeta);
    }
    if (data.containsKey('offer_kind')) {
      context.handle(
        _offerKindMeta,
        offerKind.isAcceptableOrUnknown(data['offer_kind']!, _offerKindMeta),
      );
    }
    if (data.containsKey('offer_name')) {
      context.handle(
        _offerNameMeta,
        offerName.isAcceptableOrUnknown(data['offer_name']!, _offerNameMeta),
      );
    }
    if (data.containsKey('offer_saving_minor')) {
      context.handle(
        _offerSavingMinorMeta,
        offerSavingMinor.isAcceptableOrUnknown(
          data['offer_saving_minor']!,
          _offerSavingMinorMeta,
        ),
      );
    }
    if (data.containsKey('offer_unit_off_minor')) {
      context.handle(
        _offerUnitOffMinorMeta,
        offerUnitOffMinor.isAcceptableOrUnknown(
          data['offer_unit_off_minor']!,
          _offerUnitOffMinorMeta,
        ),
      );
    }
    if (data.containsKey('is_gift')) {
      context.handle(
        _isGiftMeta,
        isGift.isAcceptableOrUnknown(data['is_gift']!, _isGiftMeta),
      );
    }
    if (data.containsKey('returned_qty_milli')) {
      context.handle(
        _returnedQtyMilliMeta,
        returnedQtyMilli.isAcceptableOrUnknown(
          data['returned_qty_milli']!,
          _returnedQtyMilliMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleLineEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleLineEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      lineNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_no'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      productLegacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_legacy_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      )!,
      productBarcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_barcode'],
      )!,
      productPriceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_price_minor'],
      )!,
      productCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_category'],
      )!,
      productSub: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_sub'],
      )!,
      productStock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_stock'],
      )!,
      productGstBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_gst_bp'],
      )!,
      productImage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_image'],
      )!,
      productFavourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}product_favourite'],
      )!,
      priceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_minor'],
      )!,
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      discountBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_bp'],
      )!,
      offerKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offer_kind'],
      ),
      offerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offer_name'],
      ),
      offerSavingMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offer_saving_minor'],
      ),
      offerUnitOffMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offer_unit_off_minor'],
      ),
      isGift: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_gift'],
      )!,
      returnedQtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}returned_qty_milli'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SaleLineEntriesTable createAlias(String alias) {
    return $SaleLineEntriesTable(attachedDatabase, alias);
  }
}

class SaleLineEntry extends DataClass implements Insertable<SaleLineEntry> {
  final String id;
  final String saleId;
  final int lineNo;

  /// Resolved link to `products.id`; null until the row is known.
  final String? productId;
  final int productLegacyId;
  final String productName;
  final String productCode;
  final String productBarcode;
  final int productPriceMinor;
  final String productCategory;
  final String productSub;
  final int productStock;

  /// Basis points; the JSON keeps the prototype's percent number.
  final int productGstBp;
  final int productImage;
  final bool productFavourite;
  final int priceMinor;
  final int qtyMilli;
  final int discountBp;

  /// Offer applied to the line (v9, DEC-134); null when none.
  final String? offerKind;
  final String? offerName;
  final int? offerSavingMinor;

  /// Fixed per-unit reduction of a fixed-amount discount.
  final int? offerUnitOffMinor;

  /// A free-item row (price 0).
  final bool isGift;
  final int returnedQtyMilli;
  final String createdAt;
  const SaleLineEntry({
    required this.id,
    required this.saleId,
    required this.lineNo,
    this.productId,
    required this.productLegacyId,
    required this.productName,
    required this.productCode,
    required this.productBarcode,
    required this.productPriceMinor,
    required this.productCategory,
    required this.productSub,
    required this.productStock,
    required this.productGstBp,
    required this.productImage,
    required this.productFavourite,
    required this.priceMinor,
    required this.qtyMilli,
    required this.discountBp,
    this.offerKind,
    this.offerName,
    this.offerSavingMinor,
    this.offerUnitOffMinor,
    required this.isGift,
    required this.returnedQtyMilli,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['line_no'] = Variable<int>(lineNo);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['product_legacy_id'] = Variable<int>(productLegacyId);
    map['product_name'] = Variable<String>(productName);
    map['product_code'] = Variable<String>(productCode);
    map['product_barcode'] = Variable<String>(productBarcode);
    map['product_price_minor'] = Variable<int>(productPriceMinor);
    map['product_category'] = Variable<String>(productCategory);
    map['product_sub'] = Variable<String>(productSub);
    map['product_stock'] = Variable<int>(productStock);
    map['product_gst_bp'] = Variable<int>(productGstBp);
    map['product_image'] = Variable<int>(productImage);
    map['product_favourite'] = Variable<bool>(productFavourite);
    map['price_minor'] = Variable<int>(priceMinor);
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['discount_bp'] = Variable<int>(discountBp);
    if (!nullToAbsent || offerKind != null) {
      map['offer_kind'] = Variable<String>(offerKind);
    }
    if (!nullToAbsent || offerName != null) {
      map['offer_name'] = Variable<String>(offerName);
    }
    if (!nullToAbsent || offerSavingMinor != null) {
      map['offer_saving_minor'] = Variable<int>(offerSavingMinor);
    }
    if (!nullToAbsent || offerUnitOffMinor != null) {
      map['offer_unit_off_minor'] = Variable<int>(offerUnitOffMinor);
    }
    map['is_gift'] = Variable<bool>(isGift);
    map['returned_qty_milli'] = Variable<int>(returnedQtyMilli);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SaleLineEntriesCompanion toCompanion(bool nullToAbsent) {
    return SaleLineEntriesCompanion(
      id: Value(id),
      saleId: Value(saleId),
      lineNo: Value(lineNo),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productLegacyId: Value(productLegacyId),
      productName: Value(productName),
      productCode: Value(productCode),
      productBarcode: Value(productBarcode),
      productPriceMinor: Value(productPriceMinor),
      productCategory: Value(productCategory),
      productSub: Value(productSub),
      productStock: Value(productStock),
      productGstBp: Value(productGstBp),
      productImage: Value(productImage),
      productFavourite: Value(productFavourite),
      priceMinor: Value(priceMinor),
      qtyMilli: Value(qtyMilli),
      discountBp: Value(discountBp),
      offerKind: offerKind == null && nullToAbsent
          ? const Value.absent()
          : Value(offerKind),
      offerName: offerName == null && nullToAbsent
          ? const Value.absent()
          : Value(offerName),
      offerSavingMinor: offerSavingMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(offerSavingMinor),
      offerUnitOffMinor: offerUnitOffMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(offerUnitOffMinor),
      isGift: Value(isGift),
      returnedQtyMilli: Value(returnedQtyMilli),
      createdAt: Value(createdAt),
    );
  }

  factory SaleLineEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleLineEntry(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      lineNo: serializer.fromJson<int>(json['lineNo']),
      productId: serializer.fromJson<String?>(json['productId']),
      productLegacyId: serializer.fromJson<int>(json['productLegacyId']),
      productName: serializer.fromJson<String>(json['productName']),
      productCode: serializer.fromJson<String>(json['productCode']),
      productBarcode: serializer.fromJson<String>(json['productBarcode']),
      productPriceMinor: serializer.fromJson<int>(json['productPriceMinor']),
      productCategory: serializer.fromJson<String>(json['productCategory']),
      productSub: serializer.fromJson<String>(json['productSub']),
      productStock: serializer.fromJson<int>(json['productStock']),
      productGstBp: serializer.fromJson<int>(json['productGstBp']),
      productImage: serializer.fromJson<int>(json['productImage']),
      productFavourite: serializer.fromJson<bool>(json['productFavourite']),
      priceMinor: serializer.fromJson<int>(json['priceMinor']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      discountBp: serializer.fromJson<int>(json['discountBp']),
      offerKind: serializer.fromJson<String?>(json['offerKind']),
      offerName: serializer.fromJson<String?>(json['offerName']),
      offerSavingMinor: serializer.fromJson<int?>(json['offerSavingMinor']),
      offerUnitOffMinor: serializer.fromJson<int?>(json['offerUnitOffMinor']),
      isGift: serializer.fromJson<bool>(json['isGift']),
      returnedQtyMilli: serializer.fromJson<int>(json['returnedQtyMilli']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'lineNo': serializer.toJson<int>(lineNo),
      'productId': serializer.toJson<String?>(productId),
      'productLegacyId': serializer.toJson<int>(productLegacyId),
      'productName': serializer.toJson<String>(productName),
      'productCode': serializer.toJson<String>(productCode),
      'productBarcode': serializer.toJson<String>(productBarcode),
      'productPriceMinor': serializer.toJson<int>(productPriceMinor),
      'productCategory': serializer.toJson<String>(productCategory),
      'productSub': serializer.toJson<String>(productSub),
      'productStock': serializer.toJson<int>(productStock),
      'productGstBp': serializer.toJson<int>(productGstBp),
      'productImage': serializer.toJson<int>(productImage),
      'productFavourite': serializer.toJson<bool>(productFavourite),
      'priceMinor': serializer.toJson<int>(priceMinor),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'discountBp': serializer.toJson<int>(discountBp),
      'offerKind': serializer.toJson<String?>(offerKind),
      'offerName': serializer.toJson<String?>(offerName),
      'offerSavingMinor': serializer.toJson<int?>(offerSavingMinor),
      'offerUnitOffMinor': serializer.toJson<int?>(offerUnitOffMinor),
      'isGift': serializer.toJson<bool>(isGift),
      'returnedQtyMilli': serializer.toJson<int>(returnedQtyMilli),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SaleLineEntry copyWith({
    String? id,
    String? saleId,
    int? lineNo,
    Value<String?> productId = const Value.absent(),
    int? productLegacyId,
    String? productName,
    String? productCode,
    String? productBarcode,
    int? productPriceMinor,
    String? productCategory,
    String? productSub,
    int? productStock,
    int? productGstBp,
    int? productImage,
    bool? productFavourite,
    int? priceMinor,
    int? qtyMilli,
    int? discountBp,
    Value<String?> offerKind = const Value.absent(),
    Value<String?> offerName = const Value.absent(),
    Value<int?> offerSavingMinor = const Value.absent(),
    Value<int?> offerUnitOffMinor = const Value.absent(),
    bool? isGift,
    int? returnedQtyMilli,
    String? createdAt,
  }) => SaleLineEntry(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    lineNo: lineNo ?? this.lineNo,
    productId: productId.present ? productId.value : this.productId,
    productLegacyId: productLegacyId ?? this.productLegacyId,
    productName: productName ?? this.productName,
    productCode: productCode ?? this.productCode,
    productBarcode: productBarcode ?? this.productBarcode,
    productPriceMinor: productPriceMinor ?? this.productPriceMinor,
    productCategory: productCategory ?? this.productCategory,
    productSub: productSub ?? this.productSub,
    productStock: productStock ?? this.productStock,
    productGstBp: productGstBp ?? this.productGstBp,
    productImage: productImage ?? this.productImage,
    productFavourite: productFavourite ?? this.productFavourite,
    priceMinor: priceMinor ?? this.priceMinor,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    discountBp: discountBp ?? this.discountBp,
    offerKind: offerKind.present ? offerKind.value : this.offerKind,
    offerName: offerName.present ? offerName.value : this.offerName,
    offerSavingMinor: offerSavingMinor.present
        ? offerSavingMinor.value
        : this.offerSavingMinor,
    offerUnitOffMinor: offerUnitOffMinor.present
        ? offerUnitOffMinor.value
        : this.offerUnitOffMinor,
    isGift: isGift ?? this.isGift,
    returnedQtyMilli: returnedQtyMilli ?? this.returnedQtyMilli,
    createdAt: createdAt ?? this.createdAt,
  );
  SaleLineEntry copyWithCompanion(SaleLineEntriesCompanion data) {
    return SaleLineEntry(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      lineNo: data.lineNo.present ? data.lineNo.value : this.lineNo,
      productId: data.productId.present ? data.productId.value : this.productId,
      productLegacyId: data.productLegacyId.present
          ? data.productLegacyId.value
          : this.productLegacyId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      productBarcode: data.productBarcode.present
          ? data.productBarcode.value
          : this.productBarcode,
      productPriceMinor: data.productPriceMinor.present
          ? data.productPriceMinor.value
          : this.productPriceMinor,
      productCategory: data.productCategory.present
          ? data.productCategory.value
          : this.productCategory,
      productSub: data.productSub.present
          ? data.productSub.value
          : this.productSub,
      productStock: data.productStock.present
          ? data.productStock.value
          : this.productStock,
      productGstBp: data.productGstBp.present
          ? data.productGstBp.value
          : this.productGstBp,
      productImage: data.productImage.present
          ? data.productImage.value
          : this.productImage,
      productFavourite: data.productFavourite.present
          ? data.productFavourite.value
          : this.productFavourite,
      priceMinor: data.priceMinor.present
          ? data.priceMinor.value
          : this.priceMinor,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      discountBp: data.discountBp.present
          ? data.discountBp.value
          : this.discountBp,
      offerKind: data.offerKind.present ? data.offerKind.value : this.offerKind,
      offerName: data.offerName.present ? data.offerName.value : this.offerName,
      offerSavingMinor: data.offerSavingMinor.present
          ? data.offerSavingMinor.value
          : this.offerSavingMinor,
      offerUnitOffMinor: data.offerUnitOffMinor.present
          ? data.offerUnitOffMinor.value
          : this.offerUnitOffMinor,
      isGift: data.isGift.present ? data.isGift.value : this.isGift,
      returnedQtyMilli: data.returnedQtyMilli.present
          ? data.returnedQtyMilli.value
          : this.returnedQtyMilli,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleLineEntry(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('lineNo: $lineNo, ')
          ..write('productId: $productId, ')
          ..write('productLegacyId: $productLegacyId, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('productBarcode: $productBarcode, ')
          ..write('productPriceMinor: $productPriceMinor, ')
          ..write('productCategory: $productCategory, ')
          ..write('productSub: $productSub, ')
          ..write('productStock: $productStock, ')
          ..write('productGstBp: $productGstBp, ')
          ..write('productImage: $productImage, ')
          ..write('productFavourite: $productFavourite, ')
          ..write('priceMinor: $priceMinor, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('discountBp: $discountBp, ')
          ..write('offerKind: $offerKind, ')
          ..write('offerName: $offerName, ')
          ..write('offerSavingMinor: $offerSavingMinor, ')
          ..write('offerUnitOffMinor: $offerUnitOffMinor, ')
          ..write('isGift: $isGift, ')
          ..write('returnedQtyMilli: $returnedQtyMilli, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    saleId,
    lineNo,
    productId,
    productLegacyId,
    productName,
    productCode,
    productBarcode,
    productPriceMinor,
    productCategory,
    productSub,
    productStock,
    productGstBp,
    productImage,
    productFavourite,
    priceMinor,
    qtyMilli,
    discountBp,
    offerKind,
    offerName,
    offerSavingMinor,
    offerUnitOffMinor,
    isGift,
    returnedQtyMilli,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleLineEntry &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.lineNo == this.lineNo &&
          other.productId == this.productId &&
          other.productLegacyId == this.productLegacyId &&
          other.productName == this.productName &&
          other.productCode == this.productCode &&
          other.productBarcode == this.productBarcode &&
          other.productPriceMinor == this.productPriceMinor &&
          other.productCategory == this.productCategory &&
          other.productSub == this.productSub &&
          other.productStock == this.productStock &&
          other.productGstBp == this.productGstBp &&
          other.productImage == this.productImage &&
          other.productFavourite == this.productFavourite &&
          other.priceMinor == this.priceMinor &&
          other.qtyMilli == this.qtyMilli &&
          other.discountBp == this.discountBp &&
          other.offerKind == this.offerKind &&
          other.offerName == this.offerName &&
          other.offerSavingMinor == this.offerSavingMinor &&
          other.offerUnitOffMinor == this.offerUnitOffMinor &&
          other.isGift == this.isGift &&
          other.returnedQtyMilli == this.returnedQtyMilli &&
          other.createdAt == this.createdAt);
}

class SaleLineEntriesCompanion extends UpdateCompanion<SaleLineEntry> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<int> lineNo;
  final Value<String?> productId;
  final Value<int> productLegacyId;
  final Value<String> productName;
  final Value<String> productCode;
  final Value<String> productBarcode;
  final Value<int> productPriceMinor;
  final Value<String> productCategory;
  final Value<String> productSub;
  final Value<int> productStock;
  final Value<int> productGstBp;
  final Value<int> productImage;
  final Value<bool> productFavourite;
  final Value<int> priceMinor;
  final Value<int> qtyMilli;
  final Value<int> discountBp;
  final Value<String?> offerKind;
  final Value<String?> offerName;
  final Value<int?> offerSavingMinor;
  final Value<int?> offerUnitOffMinor;
  final Value<bool> isGift;
  final Value<int> returnedQtyMilli;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SaleLineEntriesCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.lineNo = const Value.absent(),
    this.productId = const Value.absent(),
    this.productLegacyId = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCode = const Value.absent(),
    this.productBarcode = const Value.absent(),
    this.productPriceMinor = const Value.absent(),
    this.productCategory = const Value.absent(),
    this.productSub = const Value.absent(),
    this.productStock = const Value.absent(),
    this.productGstBp = const Value.absent(),
    this.productImage = const Value.absent(),
    this.productFavourite = const Value.absent(),
    this.priceMinor = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.discountBp = const Value.absent(),
    this.offerKind = const Value.absent(),
    this.offerName = const Value.absent(),
    this.offerSavingMinor = const Value.absent(),
    this.offerUnitOffMinor = const Value.absent(),
    this.isGift = const Value.absent(),
    this.returnedQtyMilli = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleLineEntriesCompanion.insert({
    required String id,
    required String saleId,
    required int lineNo,
    this.productId = const Value.absent(),
    required int productLegacyId,
    required String productName,
    required String productCode,
    required String productBarcode,
    required int productPriceMinor,
    required String productCategory,
    required String productSub,
    required int productStock,
    required int productGstBp,
    required int productImage,
    required bool productFavourite,
    required int priceMinor,
    required int qtyMilli,
    required int discountBp,
    this.offerKind = const Value.absent(),
    this.offerName = const Value.absent(),
    this.offerSavingMinor = const Value.absent(),
    this.offerUnitOffMinor = const Value.absent(),
    this.isGift = const Value.absent(),
    this.returnedQtyMilli = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       lineNo = Value(lineNo),
       productLegacyId = Value(productLegacyId),
       productName = Value(productName),
       productCode = Value(productCode),
       productBarcode = Value(productBarcode),
       productPriceMinor = Value(productPriceMinor),
       productCategory = Value(productCategory),
       productSub = Value(productSub),
       productStock = Value(productStock),
       productGstBp = Value(productGstBp),
       productImage = Value(productImage),
       productFavourite = Value(productFavourite),
       priceMinor = Value(priceMinor),
       qtyMilli = Value(qtyMilli),
       discountBp = Value(discountBp),
       createdAt = Value(createdAt);
  static Insertable<SaleLineEntry> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<int>? lineNo,
    Expression<String>? productId,
    Expression<int>? productLegacyId,
    Expression<String>? productName,
    Expression<String>? productCode,
    Expression<String>? productBarcode,
    Expression<int>? productPriceMinor,
    Expression<String>? productCategory,
    Expression<String>? productSub,
    Expression<int>? productStock,
    Expression<int>? productGstBp,
    Expression<int>? productImage,
    Expression<bool>? productFavourite,
    Expression<int>? priceMinor,
    Expression<int>? qtyMilli,
    Expression<int>? discountBp,
    Expression<String>? offerKind,
    Expression<String>? offerName,
    Expression<int>? offerSavingMinor,
    Expression<int>? offerUnitOffMinor,
    Expression<bool>? isGift,
    Expression<int>? returnedQtyMilli,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (lineNo != null) 'line_no': lineNo,
      if (productId != null) 'product_id': productId,
      if (productLegacyId != null) 'product_legacy_id': productLegacyId,
      if (productName != null) 'product_name': productName,
      if (productCode != null) 'product_code': productCode,
      if (productBarcode != null) 'product_barcode': productBarcode,
      if (productPriceMinor != null) 'product_price_minor': productPriceMinor,
      if (productCategory != null) 'product_category': productCategory,
      if (productSub != null) 'product_sub': productSub,
      if (productStock != null) 'product_stock': productStock,
      if (productGstBp != null) 'product_gst_bp': productGstBp,
      if (productImage != null) 'product_image': productImage,
      if (productFavourite != null) 'product_favourite': productFavourite,
      if (priceMinor != null) 'price_minor': priceMinor,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (discountBp != null) 'discount_bp': discountBp,
      if (offerKind != null) 'offer_kind': offerKind,
      if (offerName != null) 'offer_name': offerName,
      if (offerSavingMinor != null) 'offer_saving_minor': offerSavingMinor,
      if (offerUnitOffMinor != null) 'offer_unit_off_minor': offerUnitOffMinor,
      if (isGift != null) 'is_gift': isGift,
      if (returnedQtyMilli != null) 'returned_qty_milli': returnedQtyMilli,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleLineEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<int>? lineNo,
    Value<String?>? productId,
    Value<int>? productLegacyId,
    Value<String>? productName,
    Value<String>? productCode,
    Value<String>? productBarcode,
    Value<int>? productPriceMinor,
    Value<String>? productCategory,
    Value<String>? productSub,
    Value<int>? productStock,
    Value<int>? productGstBp,
    Value<int>? productImage,
    Value<bool>? productFavourite,
    Value<int>? priceMinor,
    Value<int>? qtyMilli,
    Value<int>? discountBp,
    Value<String?>? offerKind,
    Value<String?>? offerName,
    Value<int?>? offerSavingMinor,
    Value<int?>? offerUnitOffMinor,
    Value<bool>? isGift,
    Value<int>? returnedQtyMilli,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return SaleLineEntriesCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      lineNo: lineNo ?? this.lineNo,
      productId: productId ?? this.productId,
      productLegacyId: productLegacyId ?? this.productLegacyId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      productBarcode: productBarcode ?? this.productBarcode,
      productPriceMinor: productPriceMinor ?? this.productPriceMinor,
      productCategory: productCategory ?? this.productCategory,
      productSub: productSub ?? this.productSub,
      productStock: productStock ?? this.productStock,
      productGstBp: productGstBp ?? this.productGstBp,
      productImage: productImage ?? this.productImage,
      productFavourite: productFavourite ?? this.productFavourite,
      priceMinor: priceMinor ?? this.priceMinor,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      discountBp: discountBp ?? this.discountBp,
      offerKind: offerKind ?? this.offerKind,
      offerName: offerName ?? this.offerName,
      offerSavingMinor: offerSavingMinor ?? this.offerSavingMinor,
      offerUnitOffMinor: offerUnitOffMinor ?? this.offerUnitOffMinor,
      isGift: isGift ?? this.isGift,
      returnedQtyMilli: returnedQtyMilli ?? this.returnedQtyMilli,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (lineNo.present) {
      map['line_no'] = Variable<int>(lineNo.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productLegacyId.present) {
      map['product_legacy_id'] = Variable<int>(productLegacyId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (productBarcode.present) {
      map['product_barcode'] = Variable<String>(productBarcode.value);
    }
    if (productPriceMinor.present) {
      map['product_price_minor'] = Variable<int>(productPriceMinor.value);
    }
    if (productCategory.present) {
      map['product_category'] = Variable<String>(productCategory.value);
    }
    if (productSub.present) {
      map['product_sub'] = Variable<String>(productSub.value);
    }
    if (productStock.present) {
      map['product_stock'] = Variable<int>(productStock.value);
    }
    if (productGstBp.present) {
      map['product_gst_bp'] = Variable<int>(productGstBp.value);
    }
    if (productImage.present) {
      map['product_image'] = Variable<int>(productImage.value);
    }
    if (productFavourite.present) {
      map['product_favourite'] = Variable<bool>(productFavourite.value);
    }
    if (priceMinor.present) {
      map['price_minor'] = Variable<int>(priceMinor.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (discountBp.present) {
      map['discount_bp'] = Variable<int>(discountBp.value);
    }
    if (offerKind.present) {
      map['offer_kind'] = Variable<String>(offerKind.value);
    }
    if (offerName.present) {
      map['offer_name'] = Variable<String>(offerName.value);
    }
    if (offerSavingMinor.present) {
      map['offer_saving_minor'] = Variable<int>(offerSavingMinor.value);
    }
    if (offerUnitOffMinor.present) {
      map['offer_unit_off_minor'] = Variable<int>(offerUnitOffMinor.value);
    }
    if (isGift.present) {
      map['is_gift'] = Variable<bool>(isGift.value);
    }
    if (returnedQtyMilli.present) {
      map['returned_qty_milli'] = Variable<int>(returnedQtyMilli.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleLineEntriesCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('lineNo: $lineNo, ')
          ..write('productId: $productId, ')
          ..write('productLegacyId: $productLegacyId, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('productBarcode: $productBarcode, ')
          ..write('productPriceMinor: $productPriceMinor, ')
          ..write('productCategory: $productCategory, ')
          ..write('productSub: $productSub, ')
          ..write('productStock: $productStock, ')
          ..write('productGstBp: $productGstBp, ')
          ..write('productImage: $productImage, ')
          ..write('productFavourite: $productFavourite, ')
          ..write('priceMinor: $priceMinor, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('discountBp: $discountBp, ')
          ..write('offerKind: $offerKind, ')
          ..write('offerName: $offerName, ')
          ..write('offerSavingMinor: $offerSavingMinor, ')
          ..write('offerUnitOffMinor: $offerUnitOffMinor, ')
          ..write('isGift: $isGift, ')
          ..write('returnedQtyMilli: $returnedQtyMilli, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentEntriesTable extends PaymentEntries
    with TableInfo<$PaymentEntriesTable, PaymentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sales (id)',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<String> occurredAt = GeneratedColumn<String>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    method,
    amountMinor,
    currencyCode,
    status,
    occurredAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PaymentEntriesTable createAlias(String alias) {
    return $PaymentEntriesTable(attachedDatabase, alias);
  }
}

class PaymentEntry extends DataClass implements Insertable<PaymentEntry> {
  final String id;
  final String saleId;

  /// `cash` or `card`.
  final String method;
  final int amountMinor;
  final String currencyCode;

  /// `succeeded` (the only value written today).
  final String status;
  final String occurredAt;
  final String createdAt;
  const PaymentEntry({
    required this.id,
    required this.saleId,
    required this.method,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.occurredAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['method'] = Variable<String>(method);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['status'] = Variable<String>(status);
    map['occurred_at'] = Variable<String>(occurredAt);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PaymentEntriesCompanion toCompanion(bool nullToAbsent) {
    return PaymentEntriesCompanion(
      id: Value(id),
      saleId: Value(saleId),
      method: Value(method),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      status: Value(status),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
    );
  }

  factory PaymentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentEntry(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      method: serializer.fromJson<String>(json['method']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      status: serializer.fromJson<String>(json['status']),
      occurredAt: serializer.fromJson<String>(json['occurredAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'method': serializer.toJson<String>(method),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'status': serializer.toJson<String>(status),
      'occurredAt': serializer.toJson<String>(occurredAt),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PaymentEntry copyWith({
    String? id,
    String? saleId,
    String? method,
    int? amountMinor,
    String? currencyCode,
    String? status,
    String? occurredAt,
    String? createdAt,
  }) => PaymentEntry(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    method: method ?? this.method,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    status: status ?? this.status,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
  );
  PaymentEntry copyWithCompanion(PaymentEntriesCompanion data) {
    return PaymentEntry(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      method: data.method.present ? data.method.value : this.method,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      status: data.status.present ? data.status.value : this.status,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentEntry(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('status: $status, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleId,
    method,
    amountMinor,
    currencyCode,
    status,
    occurredAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentEntry &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.method == this.method &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.status == this.status &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt);
}

class PaymentEntriesCompanion extends UpdateCompanion<PaymentEntry> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> method;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<String> status;
  final Value<String> occurredAt;
  final Value<String> createdAt;
  final Value<int> rowid;
  const PaymentEntriesCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.method = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.status = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentEntriesCompanion.insert({
    required String id,
    required String saleId,
    required String method,
    required int amountMinor,
    this.currencyCode = const Value.absent(),
    required String status,
    required String occurredAt,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       method = Value(method),
       amountMinor = Value(amountMinor),
       status = Value(status),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<PaymentEntry> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? method,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? status,
    Expression<String>? occurredAt,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (method != null) 'method': method,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (status != null) 'status': status,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? method,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<String>? status,
    Value<String>? occurredAt,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return PaymentEntriesCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      status: status ?? this.status,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentEntriesCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('status: $status, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CurrentCartEntriesTable extends CurrentCartEntries
    with TableInfo<$CurrentCartEntriesTable, CurrentCartEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrentCartEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _cartJsonMeta = const VerificationMeta(
    'cartJson',
  );
  @override
  late final GeneratedColumn<String> cartJson = GeneratedColumn<String>(
    'cart_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, cartJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'current_cart';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrentCartEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cart_json')) {
      context.handle(
        _cartJsonMeta,
        cartJson.isAcceptableOrUnknown(data['cart_json']!, _cartJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_cartJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CurrentCartEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrentCartEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cartJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cart_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CurrentCartEntriesTable createAlias(String alias) {
    return $CurrentCartEntriesTable(attachedDatabase, alias);
  }
}

class CurrentCartEntry extends DataClass
    implements Insertable<CurrentCartEntry> {
  final int id;
  final String cartJson;

  /// UTC ISO 8601 text.
  final String updatedAt;
  const CurrentCartEntry({
    required this.id,
    required this.cartJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cart_json'] = Variable<String>(cartJson);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CurrentCartEntriesCompanion toCompanion(bool nullToAbsent) {
    return CurrentCartEntriesCompanion(
      id: Value(id),
      cartJson: Value(cartJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CurrentCartEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrentCartEntry(
      id: serializer.fromJson<int>(json['id']),
      cartJson: serializer.fromJson<String>(json['cartJson']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cartJson': serializer.toJson<String>(cartJson),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CurrentCartEntry copyWith({int? id, String? cartJson, String? updatedAt}) =>
      CurrentCartEntry(
        id: id ?? this.id,
        cartJson: cartJson ?? this.cartJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CurrentCartEntry copyWithCompanion(CurrentCartEntriesCompanion data) {
    return CurrentCartEntry(
      id: data.id.present ? data.id.value : this.id,
      cartJson: data.cartJson.present ? data.cartJson.value : this.cartJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrentCartEntry(')
          ..write('id: $id, ')
          ..write('cartJson: $cartJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cartJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrentCartEntry &&
          other.id == this.id &&
          other.cartJson == this.cartJson &&
          other.updatedAt == this.updatedAt);
}

class CurrentCartEntriesCompanion extends UpdateCompanion<CurrentCartEntry> {
  final Value<int> id;
  final Value<String> cartJson;
  final Value<String> updatedAt;
  const CurrentCartEntriesCompanion({
    this.id = const Value.absent(),
    this.cartJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CurrentCartEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String cartJson,
    required String updatedAt,
  }) : cartJson = Value(cartJson),
       updatedAt = Value(updatedAt);
  static Insertable<CurrentCartEntry> custom({
    Expression<int>? id,
    Expression<String>? cartJson,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cartJson != null) 'cart_json': cartJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CurrentCartEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? cartJson,
    Value<String>? updatedAt,
  }) {
    return CurrentCartEntriesCompanion(
      id: id ?? this.id,
      cartJson: cartJson ?? this.cartJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cartJson.present) {
      map['cart_json'] = Variable<String>(cartJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrentCartEntriesCompanion(')
          ..write('id: $id, ')
          ..write('cartJson: $cartJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserAccessEntriesTable extends UserAccessEntries
    with TableInfo<$UserAccessEntriesTable, UserAccessEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserAccessEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counters (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, userId, storeId, counterId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_access';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserAccessEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserAccessEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAccessEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      ),
    );
  }

  @override
  $UserAccessEntriesTable createAlias(String alias) {
    return $UserAccessEntriesTable(attachedDatabase, alias);
  }
}

class UserAccessEntry extends DataClass implements Insertable<UserAccessEntry> {
  final String id;
  final String userId;
  final String storeId;
  final String? counterId;
  const UserAccessEntry({
    required this.id,
    required this.userId,
    required this.storeId,
    this.counterId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['store_id'] = Variable<String>(storeId);
    if (!nullToAbsent || counterId != null) {
      map['counter_id'] = Variable<String>(counterId);
    }
    return map;
  }

  UserAccessEntriesCompanion toCompanion(bool nullToAbsent) {
    return UserAccessEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      storeId: Value(storeId),
      counterId: counterId == null && nullToAbsent
          ? const Value.absent()
          : Value(counterId),
    );
  }

  factory UserAccessEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAccessEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      storeId: serializer.fromJson<String>(json['storeId']),
      counterId: serializer.fromJson<String?>(json['counterId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'storeId': serializer.toJson<String>(storeId),
      'counterId': serializer.toJson<String?>(counterId),
    };
  }

  UserAccessEntry copyWith({
    String? id,
    String? userId,
    String? storeId,
    Value<String?> counterId = const Value.absent(),
  }) => UserAccessEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    storeId: storeId ?? this.storeId,
    counterId: counterId.present ? counterId.value : this.counterId,
  );
  UserAccessEntry copyWithCompanion(UserAccessEntriesCompanion data) {
    return UserAccessEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserAccessEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('storeId: $storeId, ')
          ..write('counterId: $counterId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, storeId, counterId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAccessEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.storeId == this.storeId &&
          other.counterId == this.counterId);
}

class UserAccessEntriesCompanion extends UpdateCompanion<UserAccessEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> storeId;
  final Value<String?> counterId;
  final Value<int> rowid;
  const UserAccessEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.counterId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserAccessEntriesCompanion.insert({
    required String id,
    required String userId,
    required String storeId,
    this.counterId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       storeId = Value(storeId);
  static Insertable<UserAccessEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? storeId,
    Expression<String>? counterId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (storeId != null) 'store_id': storeId,
      if (counterId != null) 'counter_id': counterId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserAccessEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? storeId,
    Value<String?>? counterId,
    Value<int>? rowid,
  }) {
    return UserAccessEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      counterId: counterId ?? this.counterId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserAccessEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('storeId: $storeId, ')
          ..write('counterId: $counterId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfferEntriesTable extends OfferEntries
    with TableInfo<$OfferEntriesTable, OfferEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfferEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(const ['discount', 'promotion', 'gift_tier']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _percentBpMeta = const VerificationMeta(
    'percentBp',
  );
  @override
  late final GeneratedColumn<int> percentBp = GeneratedColumn<int>(
    'percent_bp',
    aliasedName,
    true,
    check: () =>
        percentBp.isNull() |
        ComparableExpr(percentBp).isBetweenValues(0, 10000),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedAmountMinorMeta = const VerificationMeta(
    'fixedAmountMinor',
  );
  @override
  late final GeneratedColumn<int> fixedAmountMinor = GeneratedColumn<int>(
    'fixed_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minCartMinorMeta = const VerificationMeta(
    'minCartMinor',
  );
  @override
  late final GeneratedColumn<int> minCartMinor = GeneratedColumn<int>(
    'min_cart_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _giftProductIdMeta = const VerificationMeta(
    'giftProductId',
  );
  @override
  late final GeneratedColumn<String> giftProductId = GeneratedColumn<String>(
    'gift_product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<String> startsAt = GeneratedColumn<String>(
    'starts_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<String> endsAt = GeneratedColumn<String>(
    'ends_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    name,
    storeId,
    productId,
    percentBp,
    fixedAmountMinor,
    currencyCode,
    minCartMinor,
    giftProductId,
    startsAt,
    endsAt,
    active,
    priority,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offers';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfferEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('percent_bp')) {
      context.handle(
        _percentBpMeta,
        percentBp.isAcceptableOrUnknown(data['percent_bp']!, _percentBpMeta),
      );
    }
    if (data.containsKey('fixed_amount_minor')) {
      context.handle(
        _fixedAmountMinorMeta,
        fixedAmountMinor.isAcceptableOrUnknown(
          data['fixed_amount_minor']!,
          _fixedAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('min_cart_minor')) {
      context.handle(
        _minCartMinorMeta,
        minCartMinor.isAcceptableOrUnknown(
          data['min_cart_minor']!,
          _minCartMinorMeta,
        ),
      );
    }
    if (data.containsKey('gift_product_id')) {
      context.handle(
        _giftProductIdMeta,
        giftProductId.isAcceptableOrUnknown(
          data['gift_product_id']!,
          _giftProductIdMeta,
        ),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfferEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfferEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      percentBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percent_bp'],
      ),
      fixedAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_amount_minor'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      ),
      minCartMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_cart_minor'],
      ),
      giftProductId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gift_product_id'],
      ),
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts_at'],
      ),
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_at'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $OfferEntriesTable createAlias(String alias) {
    return $OfferEntriesTable(attachedDatabase, alias);
  }
}

class OfferEntry extends DataClass implements Insertable<OfferEntry> {
  final String id;
  final String kind;
  final String name;

  /// Null = every store.
  final String? storeId;
  final String? productId;
  final int? percentBp;
  final int? fixedAmountMinor;
  final String? currencyCode;
  final int? minCartMinor;
  final String? giftProductId;

  /// UTC ISO 8601 text; null = no bound.
  final String? startsAt;
  final String? endsAt;
  final bool active;
  final int priority;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  const OfferEntry({
    required this.id,
    required this.kind,
    required this.name,
    this.storeId,
    this.productId,
    this.percentBp,
    this.fixedAmountMinor,
    this.currencyCode,
    this.minCartMinor,
    this.giftProductId,
    this.startsAt,
    this.endsAt,
    required this.active,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || percentBp != null) {
      map['percent_bp'] = Variable<int>(percentBp);
    }
    if (!nullToAbsent || fixedAmountMinor != null) {
      map['fixed_amount_minor'] = Variable<int>(fixedAmountMinor);
    }
    if (!nullToAbsent || currencyCode != null) {
      map['currency_code'] = Variable<String>(currencyCode);
    }
    if (!nullToAbsent || minCartMinor != null) {
      map['min_cart_minor'] = Variable<int>(minCartMinor);
    }
    if (!nullToAbsent || giftProductId != null) {
      map['gift_product_id'] = Variable<String>(giftProductId);
    }
    if (!nullToAbsent || startsAt != null) {
      map['starts_at'] = Variable<String>(startsAt);
    }
    if (!nullToAbsent || endsAt != null) {
      map['ends_at'] = Variable<String>(endsAt);
    }
    map['active'] = Variable<bool>(active);
    map['priority'] = Variable<int>(priority);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  OfferEntriesCompanion toCompanion(bool nullToAbsent) {
    return OfferEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      percentBp: percentBp == null && nullToAbsent
          ? const Value.absent()
          : Value(percentBp),
      fixedAmountMinor: fixedAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedAmountMinor),
      currencyCode: currencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyCode),
      minCartMinor: minCartMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(minCartMinor),
      giftProductId: giftProductId == null && nullToAbsent
          ? const Value.absent()
          : Value(giftProductId),
      startsAt: startsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startsAt),
      endsAt: endsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endsAt),
      active: Value(active),
      priority: Value(priority),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory OfferEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfferEntry(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      productId: serializer.fromJson<String?>(json['productId']),
      percentBp: serializer.fromJson<int?>(json['percentBp']),
      fixedAmountMinor: serializer.fromJson<int?>(json['fixedAmountMinor']),
      currencyCode: serializer.fromJson<String?>(json['currencyCode']),
      minCartMinor: serializer.fromJson<int?>(json['minCartMinor']),
      giftProductId: serializer.fromJson<String?>(json['giftProductId']),
      startsAt: serializer.fromJson<String?>(json['startsAt']),
      endsAt: serializer.fromJson<String?>(json['endsAt']),
      active: serializer.fromJson<bool>(json['active']),
      priority: serializer.fromJson<int>(json['priority']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'storeId': serializer.toJson<String?>(storeId),
      'productId': serializer.toJson<String?>(productId),
      'percentBp': serializer.toJson<int?>(percentBp),
      'fixedAmountMinor': serializer.toJson<int?>(fixedAmountMinor),
      'currencyCode': serializer.toJson<String?>(currencyCode),
      'minCartMinor': serializer.toJson<int?>(minCartMinor),
      'giftProductId': serializer.toJson<String?>(giftProductId),
      'startsAt': serializer.toJson<String?>(startsAt),
      'endsAt': serializer.toJson<String?>(endsAt),
      'active': serializer.toJson<bool>(active),
      'priority': serializer.toJson<int>(priority),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  OfferEntry copyWith({
    String? id,
    String? kind,
    String? name,
    Value<String?> storeId = const Value.absent(),
    Value<String?> productId = const Value.absent(),
    Value<int?> percentBp = const Value.absent(),
    Value<int?> fixedAmountMinor = const Value.absent(),
    Value<String?> currencyCode = const Value.absent(),
    Value<int?> minCartMinor = const Value.absent(),
    Value<String?> giftProductId = const Value.absent(),
    Value<String?> startsAt = const Value.absent(),
    Value<String?> endsAt = const Value.absent(),
    bool? active,
    int? priority,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => OfferEntry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    storeId: storeId.present ? storeId.value : this.storeId,
    productId: productId.present ? productId.value : this.productId,
    percentBp: percentBp.present ? percentBp.value : this.percentBp,
    fixedAmountMinor: fixedAmountMinor.present
        ? fixedAmountMinor.value
        : this.fixedAmountMinor,
    currencyCode: currencyCode.present ? currencyCode.value : this.currencyCode,
    minCartMinor: minCartMinor.present ? minCartMinor.value : this.minCartMinor,
    giftProductId: giftProductId.present
        ? giftProductId.value
        : this.giftProductId,
    startsAt: startsAt.present ? startsAt.value : this.startsAt,
    endsAt: endsAt.present ? endsAt.value : this.endsAt,
    active: active ?? this.active,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  OfferEntry copyWithCompanion(OfferEntriesCompanion data) {
    return OfferEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      percentBp: data.percentBp.present ? data.percentBp.value : this.percentBp,
      fixedAmountMinor: data.fixedAmountMinor.present
          ? data.fixedAmountMinor.value
          : this.fixedAmountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      minCartMinor: data.minCartMinor.present
          ? data.minCartMinor.value
          : this.minCartMinor,
      giftProductId: data.giftProductId.present
          ? data.giftProductId.value
          : this.giftProductId,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      active: data.active.present ? data.active.value : this.active,
      priority: data.priority.present ? data.priority.value : this.priority,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfferEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('percentBp: $percentBp, ')
          ..write('fixedAmountMinor: $fixedAmountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('minCartMinor: $minCartMinor, ')
          ..write('giftProductId: $giftProductId, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('active: $active, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    storeId,
    productId,
    percentBp,
    fixedAmountMinor,
    currencyCode,
    minCartMinor,
    giftProductId,
    startsAt,
    endsAt,
    active,
    priority,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfferEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.storeId == this.storeId &&
          other.productId == this.productId &&
          other.percentBp == this.percentBp &&
          other.fixedAmountMinor == this.fixedAmountMinor &&
          other.currencyCode == this.currencyCode &&
          other.minCartMinor == this.minCartMinor &&
          other.giftProductId == this.giftProductId &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.active == this.active &&
          other.priority == this.priority &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class OfferEntriesCompanion extends UpdateCompanion<OfferEntry> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> storeId;
  final Value<String?> productId;
  final Value<int?> percentBp;
  final Value<int?> fixedAmountMinor;
  final Value<String?> currencyCode;
  final Value<int?> minCartMinor;
  final Value<String?> giftProductId;
  final Value<String?> startsAt;
  final Value<String?> endsAt;
  final Value<bool> active;
  final Value<int> priority;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const OfferEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.storeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.percentBp = const Value.absent(),
    this.fixedAmountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.minCartMinor = const Value.absent(),
    this.giftProductId = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.active = const Value.absent(),
    this.priority = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfferEntriesCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.storeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.percentBp = const Value.absent(),
    this.fixedAmountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.minCartMinor = const Value.absent(),
    this.giftProductId = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.active = const Value.absent(),
    this.priority = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OfferEntry> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? storeId,
    Expression<String>? productId,
    Expression<int>? percentBp,
    Expression<int>? fixedAmountMinor,
    Expression<String>? currencyCode,
    Expression<int>? minCartMinor,
    Expression<String>? giftProductId,
    Expression<String>? startsAt,
    Expression<String>? endsAt,
    Expression<bool>? active,
    Expression<int>? priority,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (storeId != null) 'store_id': storeId,
      if (productId != null) 'product_id': productId,
      if (percentBp != null) 'percent_bp': percentBp,
      if (fixedAmountMinor != null) 'fixed_amount_minor': fixedAmountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (minCartMinor != null) 'min_cart_minor': minCartMinor,
      if (giftProductId != null) 'gift_product_id': giftProductId,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (active != null) 'active': active,
      if (priority != null) 'priority': priority,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfferEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? storeId,
    Value<String?>? productId,
    Value<int?>? percentBp,
    Value<int?>? fixedAmountMinor,
    Value<String?>? currencyCode,
    Value<int?>? minCartMinor,
    Value<String?>? giftProductId,
    Value<String?>? startsAt,
    Value<String?>? endsAt,
    Value<bool>? active,
    Value<int>? priority,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return OfferEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      percentBp: percentBp ?? this.percentBp,
      fixedAmountMinor: fixedAmountMinor ?? this.fixedAmountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      minCartMinor: minCartMinor ?? this.minCartMinor,
      giftProductId: giftProductId ?? this.giftProductId,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      active: active ?? this.active,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (percentBp.present) {
      map['percent_bp'] = Variable<int>(percentBp.value);
    }
    if (fixedAmountMinor.present) {
      map['fixed_amount_minor'] = Variable<int>(fixedAmountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (minCartMinor.present) {
      map['min_cart_minor'] = Variable<int>(minCartMinor.value);
    }
    if (giftProductId.present) {
      map['gift_product_id'] = Variable<String>(giftProductId.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<String>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<String>(endsAt.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfferEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('percentBp: $percentBp, ')
          ..write('fixedAmountMinor: $fixedAmountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('minCartMinor: $minCartMinor, ')
          ..write('giftProductId: $giftProductId, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('active: $active, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeedManifestEntriesTable extends SeedManifestEntries
    with TableInfo<$SeedManifestEntriesTable, SeedManifestEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeedManifestEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tableNameValueMeta = const VerificationMeta(
    'tableNameValue',
  );
  @override
  late final GeneratedColumn<String> tableNameValue = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tableNameValue, rowId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seed_manifest';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeedManifestEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_name')) {
      context.handle(
        _tableNameValueMeta,
        tableNameValue.isAcceptableOrUnknown(
          data['table_name']!,
          _tableNameValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tableNameValueMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tableNameValue, rowId};
  @override
  SeedManifestEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeedManifestEntry(
      tableNameValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
    );
  }

  @override
  $SeedManifestEntriesTable createAlias(String alias) {
    return $SeedManifestEntriesTable(attachedDatabase, alias);
  }
}

class SeedManifestEntry extends DataClass
    implements Insertable<SeedManifestEntry> {
  final String tableNameValue;
  final String rowId;
  const SeedManifestEntry({required this.tableNameValue, required this.rowId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_name'] = Variable<String>(tableNameValue);
    map['row_id'] = Variable<String>(rowId);
    return map;
  }

  SeedManifestEntriesCompanion toCompanion(bool nullToAbsent) {
    return SeedManifestEntriesCompanion(
      tableNameValue: Value(tableNameValue),
      rowId: Value(rowId),
    );
  }

  factory SeedManifestEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeedManifestEntry(
      tableNameValue: serializer.fromJson<String>(json['tableNameValue']),
      rowId: serializer.fromJson<String>(json['rowId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tableNameValue': serializer.toJson<String>(tableNameValue),
      'rowId': serializer.toJson<String>(rowId),
    };
  }

  SeedManifestEntry copyWith({String? tableNameValue, String? rowId}) =>
      SeedManifestEntry(
        tableNameValue: tableNameValue ?? this.tableNameValue,
        rowId: rowId ?? this.rowId,
      );
  SeedManifestEntry copyWithCompanion(SeedManifestEntriesCompanion data) {
    return SeedManifestEntry(
      tableNameValue: data.tableNameValue.present
          ? data.tableNameValue.value
          : this.tableNameValue,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeedManifestEntry(')
          ..write('tableNameValue: $tableNameValue, ')
          ..write('rowId: $rowId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tableNameValue, rowId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeedManifestEntry &&
          other.tableNameValue == this.tableNameValue &&
          other.rowId == this.rowId);
}

class SeedManifestEntriesCompanion extends UpdateCompanion<SeedManifestEntry> {
  final Value<String> tableNameValue;
  final Value<String> rowId;
  final Value<int> rowid;
  const SeedManifestEntriesCompanion({
    this.tableNameValue = const Value.absent(),
    this.rowId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeedManifestEntriesCompanion.insert({
    required String tableNameValue,
    required String rowId,
    this.rowid = const Value.absent(),
  }) : tableNameValue = Value(tableNameValue),
       rowId = Value(rowId);
  static Insertable<SeedManifestEntry> custom({
    Expression<String>? tableNameValue,
    Expression<String>? rowId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tableNameValue != null) 'table_name': tableNameValue,
      if (rowId != null) 'row_id': rowId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeedManifestEntriesCompanion copyWith({
    Value<String>? tableNameValue,
    Value<String>? rowId,
    Value<int>? rowid,
  }) {
    return SeedManifestEntriesCompanion(
      tableNameValue: tableNameValue ?? this.tableNameValue,
      rowId: rowId ?? this.rowId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tableNameValue.present) {
      map['table_name'] = Variable<String>(tableNameValue.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeedManifestEntriesCompanion(')
          ..write('tableNameValue: $tableNameValue, ')
          ..write('rowId: $rowId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AxpertDatabase extends GeneratedDatabase {
  _$AxpertDatabase(QueryExecutor e) : super(e);
  late final $DeviceContextEntriesTable deviceContextEntries =
      $DeviceContextEntriesTable(this);
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final $MigrationStateEntriesTable migrationStateEntries =
      $MigrationStateEntriesTable(this);
  late final $CustomerEntriesTable customerEntries = $CustomerEntriesTable(
    this,
  );
  late final $CurrencyEntriesTable currencyEntries = $CurrencyEntriesTable(
    this,
  );
  late final $StoreEntriesTable storeEntries = $StoreEntriesTable(this);
  late final $HeldBillEntriesTable heldBillEntries = $HeldBillEntriesTable(
    this,
  );
  late final $CategoryEntriesTable categoryEntries = $CategoryEntriesTable(
    this,
  );
  late final $ProductEntriesTable productEntries = $ProductEntriesTable(this);
  late final $CounterEntriesTable counterEntries = $CounterEntriesTable(this);
  late final $UserEntriesTable userEntries = $UserEntriesTable(this);
  late final $SaleEntriesTable saleEntries = $SaleEntriesTable(this);
  late final $SaleLineEntriesTable saleLineEntries = $SaleLineEntriesTable(
    this,
  );
  late final $PaymentEntriesTable paymentEntries = $PaymentEntriesTable(this);
  late final $CurrentCartEntriesTable currentCartEntries =
      $CurrentCartEntriesTable(this);
  late final $UserAccessEntriesTable userAccessEntries =
      $UserAccessEntriesTable(this);
  late final $OfferEntriesTable offerEntries = $OfferEntriesTable(this);
  late final $SeedManifestEntriesTable seedManifestEntries =
      $SeedManifestEntriesTable(this);
  late final Index productsPosition = Index(
    'products_position',
    'CREATE INDEX products_position ON products (position)',
  );
  late final Index salesPosition = Index(
    'sales_position',
    'CREATE INDEX sales_position ON sales (position)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    deviceContextEntries,
    settingsEntries,
    migrationStateEntries,
    customerEntries,
    currencyEntries,
    storeEntries,
    heldBillEntries,
    categoryEntries,
    productEntries,
    counterEntries,
    userEntries,
    saleEntries,
    saleLineEntries,
    paymentEntries,
    currentCartEntries,
    userAccessEntries,
    offerEntries,
    seedManifestEntries,
    productsPosition,
    salesPosition,
  ];
}
