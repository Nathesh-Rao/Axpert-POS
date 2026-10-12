import 'dart:async';

import 'package:get/get.dart';

import 'device_context.dart';
import 'device_context_store.dart';
import 'device_id_generator.dart';

/// Restores or creates stable local identity and exposes current assignment.
final class DeviceContextService extends GetxService {
  DeviceContextService({
    required DeviceContextStore store,
    required DeviceIdGenerator idGenerator,
  }) : _store = store,
       _idGenerator = idGenerator;

  final DeviceContextStore _store;
  final DeviceIdGenerator _idGenerator;
  final Rxn<DeviceContext> context = Rxn<DeviceContext>();
  Future<DeviceContext>? _initialization;

  @override
  void onInit() {
    super.onInit();
    unawaited(initialize());
  }

  Future<DeviceContext> initialize() {
    return _initialization ??= _restoreOrCreate();
  }

  Future<DeviceContext> _restoreOrCreate() async {
    final stored = await _store.read();
    final value = stored ?? DeviceContext(deviceId: _idGenerator.generate());
    if (stored == null) await _store.write(value);
    context.value = value;
    return value;
  }

  /// Persists locally assigned outlet/register identifiers without implying
  /// that either value has been validated or assigned by the backend.
  Future<DeviceContext> setAssignment({
    required String? outletId,
    required String? registerId,
  }) async {
    final current = await initialize();
    final updated = current.withAssignment(
      outletId: outletId,
      registerId: registerId,
    );
    await _store.write(updated);
    context.value = updated;
    return updated;
  }
}
