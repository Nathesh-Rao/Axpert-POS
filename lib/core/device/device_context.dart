/// Local device and assigned business context for this application instance.
///
/// Outlet and register identifiers are opaque strings because their backend
/// formats are not yet defined. Device identity is a locally generated UUID.
final class DeviceContext {
  const DeviceContext({required this.deviceId, this.outletId, this.registerId});

  final String deviceId;
  final String? outletId;
  final String? registerId;

  DeviceContext withAssignment({String? outletId, String? registerId}) =>
      DeviceContext(
        deviceId: deviceId,
        outletId: outletId,
        registerId: registerId,
      );

  @override
  bool operator ==(Object other) =>
      other is DeviceContext &&
      other.deviceId == deviceId &&
      other.outletId == outletId &&
      other.registerId == registerId;

  @override
  int get hashCode => Object.hash(deviceId, outletId, registerId);
}
