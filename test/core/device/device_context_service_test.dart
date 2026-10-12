import 'dart:math';

import 'package:pos_application/core/device/device_context_service.dart';
import 'package:pos_application/core/database/database_config.dart';
import 'package:pos_application/core/database/drift_device_context_store.dart';
import 'package:pos_application/core/database/native_database_provider.dart';
import 'package:pos_application/core/device/device_context.dart';
import 'package:pos_application/core/device/device_id_generator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NativeDatabaseProvider databaseProvider;
  late DriftDeviceContextStore store;

  setUp(() {
    databaseProvider = NativeDatabaseProvider(
      config: const DatabaseConfig(),
      executor: NativeDatabase.memory(),
    );
    store = DriftDeviceContextStore(databaseProvider);
  });

  tearDown(() => databaseProvider.close());

  test('creates and restores stable UUID device identity', () async {
    final first = DeviceContextService(
      store: store,
      idGenerator: const _FixedIdGenerator(
        '4b1f3a52-191c-4dd2-9e19-2da6fd9aec21',
      ),
    );

    final initial = await first.initialize();
    expect(initial.deviceId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(initial.outletId, isNull);
    expect(initial.registerId, isNull);

    final restored = DeviceContextService(
      store: store,
      idGenerator: _FailingIdGenerator(),
    );
    expect(await restored.initialize(), initial);
  });

  test('UUID generator emits version 4 UUIDs', () {
    final id = UuidV4DeviceIdGenerator(random: Random(4)).generate();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test(
    'persists opaque outlet and register context with device identity',
    () async {
      final service = DeviceContextService(
        store: store,
        idGenerator: const _FixedIdGenerator(
          '4b1f3a52-191c-4dd2-9e19-2da6fd9aec21',
        ),
      );
      await service.initialize();

      final assigned = await service.setAssignment(
        outletId: 'outlet-reference',
        registerId: 'register-reference',
      );
      expect(
        assigned,
        const DeviceContext(
          deviceId: '4b1f3a52-191c-4dd2-9e19-2da6fd9aec21',
          outletId: 'outlet-reference',
          registerId: 'register-reference',
        ),
      );
      expect(await store.read(), assigned);
    },
  );
}

final class _FixedIdGenerator implements DeviceIdGenerator {
  const _FixedIdGenerator(this.id);

  final String id;

  @override
  String generate() => id;
}

final class _FailingIdGenerator implements DeviceIdGenerator {
  @override
  String generate() => throw StateError('Should restore the persisted UUID.');
}
