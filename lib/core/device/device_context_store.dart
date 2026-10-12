import 'device_context.dart';

/// Persistence boundary for non-secret device and assignment metadata.
abstract interface class DeviceContextStore {
  Future<DeviceContext?> read();

  Future<void> write(DeviceContext context);
}
