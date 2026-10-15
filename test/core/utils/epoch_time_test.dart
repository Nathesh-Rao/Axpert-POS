import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/utils/epoch_time.dart';

void main() {
  final base = DateTime.utc(2026, 10, 7, 11, 27, 8).millisecondsSinceEpoch;

  test('canonical milliseconds shape round-trips byte for byte', () {
    const iso = '2026-10-07T11:27:08.123Z';
    final ms = EpochTime.parse(iso);
    expect(ms, base + 123);
    expect(EpochTime.toIso(ms), iso);
  });

  test('no fraction parses to a whole second and prints .000Z', () {
    final ms = EpochTime.parse('2026-10-07T11:27:08Z');
    expect(ms, base);
    expect(EpochTime.toIso(ms), '2026-10-07T11:27:08.000Z');
  });

  test('a +05:30 offset is converted to UTC, with and without fraction', () {
    expect(EpochTime.parse('2026-10-07T16:57:08+05:30'), base);
    expect(EpochTime.parse('2026-10-07T16:57:08.250+05:30'), base + 250);
    expect(
      EpochTime.canonicalIso('2026-10-07T16:57:08+05:30'),
      '2026-10-07T11:27:08.000Z',
    );
  });

  test('a negative offset moves the day', () {
    expect(
      EpochTime.parse('2026-10-06T23:27:08-12:00'),
      DateTime.utc(2026, 10, 7, 11, 27, 8).millisecondsSinceEpoch,
    );
  });

  test('microseconds are truncated, not rounded', () {
    expect(EpochTime.parse('2026-10-07T11:27:08.123999Z'), base + 123);
    expect(EpochTime.parse('2026-10-07T11:27:08.123456Z'), base + 123);
  });

  test('leap day and the epoch', () {
    expect(
      EpochTime.parse('2028-02-29T00:00:00.000Z'),
      DateTime.utc(2028, 2, 29).millisecondsSinceEpoch,
    );
    expect(EpochTime.parse('1970-01-01T00:00:00.000Z'), 0);
  });

  test('text that is no date: tryParse null, parse throws, lenient is 0', () {
    expect(EpochTime.tryParse('garbage'), isNull);
    expect(EpochTime.tryParse(''), isNull);
    expect(() => EpochTime.parse('garbage'), throwsFormatException);
    expect(EpochTime.parseOrZero('garbage'), 0);
    expect(EpochTime.parseOrNull(null), isNull);
    expect(EpochTime.toIsoOrNull(null), isNull);
  });

  test('nowIso drops the microseconds a native clock carries', () {
    final t = DateTime.utc(2026, 10, 7, 11, 27, 8, 123, 456);
    expect(EpochTime.nowIso(t), '2026-10-07T11:27:08.123Z');
  });
}
