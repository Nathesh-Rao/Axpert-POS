import 'package:drift/drift.dart';

import '../device/device_context.dart';
import '../device/device_context_store.dart';
import 'axpert_database.dart';
import 'database_provider.dart';

/// Drift adapter for non-secret device context metadata.
final class DriftDeviceContextStore implements DeviceContextStore {
  const DriftDeviceContextStore(this._databaseProvider);

  final DatabaseProvider _databaseProvider;

  @override
  Future<DeviceContext?> read() async {
    final database = await _databaseProvider.open();
    final row = await (database.select(
      database.deviceContextEntries,
    )..where((entry) => entry.singletonId.equals(1))).getSingleOrNull();
    if (row == null) return null;
    return DeviceContext(
      deviceId: row.deviceId,
      outletId: row.outletId,
      registerId: row.registerId,
    );
  }

  @override
  Future<void> write(DeviceContext context) async {
    final database = await _databaseProvider.open();
    await database
        .into(database.deviceContextEntries)
        .insertOnConflictUpdate(
          DeviceContextEntriesCompanion(
            singletonId: const Value(1),
            deviceId: Value(context.deviceId),
            outletId: Value(context.outletId),
            registerId: Value(context.registerId),
          ),
        );
  }
}
