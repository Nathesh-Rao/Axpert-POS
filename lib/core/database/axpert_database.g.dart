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
  const HeldBillEntry({
    required this.id,
    required this.ref,
    required this.position,
    required this.heldAt,
    required this.cartJson,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
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
  }) => HeldBillEntry(
    id: id ?? this.id,
    ref: ref ?? this.ref,
    position: position ?? this.position,
    heldAt: heldAt ?? this.heldAt,
    cartJson: cartJson ?? this.cartJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
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
          ..write('deletedAt: $deletedAt')
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
          other.deletedAt == this.deletedAt);
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
  late final $HeldBillEntriesTable heldBillEntries = $HeldBillEntriesTable(
    this,
  );
  late final $ProductEntriesTable productEntries = $ProductEntriesTable(this);
  late final Index productsPosition = Index(
    'products_position',
    'CREATE INDEX products_position ON products (position)',
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
    heldBillEntries,
    productEntries,
    productsPosition,
  ];
}
