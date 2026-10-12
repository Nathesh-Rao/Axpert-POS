import 'dart:math';

import 'uuid_generator.dart';

/// Generates an RFC 4122 version 4 UUID without platform identifiers.
///
/// Four 32-bit draws per UUID (not sixteen byte draws): `Random.secure()` is a
/// system call per draw on the VM, which made a 10,000-product copy spend
/// seconds here (DEC-128). Still 122 random bits.
final class UuidV4Generator implements UuidGenerator {
  UuidV4Generator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static final List<String> _hex = <String>[
    for (var i = 0; i < 256; i++) i.toRadixString(16).padLeft(2, '0'),
  ];

  @override
  String generate() {
    final bytes = List<int>.filled(16, 0);
    for (var word = 0; word < 4; word++) {
      final value = _random.nextInt(0x100000000);
      bytes[word * 4] = (value >> 24) & 0xff;
      bytes[word * 4 + 1] = (value >> 16) & 0xff;
      bytes[word * 4 + 2] = (value >> 8) & 0xff;
      bytes[word * 4 + 3] = value & 0xff;
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final out = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) out.write('-');
      out.write(_hex[bytes[i]]);
    }
    return out.toString();
  }
}
