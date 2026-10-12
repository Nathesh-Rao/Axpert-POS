import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/identifiers/uuid_generator.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';

void main() {
  final pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('generates RFC 4122 version 4 UUIDs (version and variant bits)', () {
    final UuidGenerator generator = UuidV4Generator(random: Random(7));
    for (var i = 0; i < 200; i++) {
      expect(generator.generate(), matches(pattern));
    }
  });

  test('a seeded random source is deterministic, a secure one is unique', () {
    expect(
      UuidV4Generator(random: Random(1)).generate(),
      UuidV4Generator(random: Random(1)).generate(),
    );
    final secure = UuidV4Generator();
    final ids = <String>{for (var i = 0; i < 100; i++) secure.generate()};
    expect(ids, hasLength(100));
  });
}
