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

abstract class _$AxpertDatabase extends GeneratedDatabase {
  _$AxpertDatabase(QueryExecutor e) : super(e);
  late final $DeviceContextEntriesTable deviceContextEntries =
      $DeviceContextEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [deviceContextEntries];
}
