import 'dart:math';

import '../identifiers/uuid_v4_generator.dart';

abstract interface class DeviceIdGenerator {
  String generate();
}

/// Generates an RFC 4122 version 4 UUID without reading platform identifiers.
final class UuidV4DeviceIdGenerator implements DeviceIdGenerator {
  UuidV4DeviceIdGenerator({Random? random})
    : _uuidGenerator = UuidV4Generator(random: random);

  final UuidV4Generator _uuidGenerator;

  @override
  String generate() => _uuidGenerator.generate();
}
