@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no Dart file name contains "host.dart" (web test server clash)', () {
    // `flutter test --platform chrome` serves its own runner for every URL
    // containing "host.dart.js", so a module such as dialog_host.dart.js is
    // never delivered and the whole suite hangs at "loading" (DEC-080).
    final offenders = <String>[
      for (final dir in const ['lib', 'test'])
        for (final f in Directory(dir).listSync(recursive: true))
          if (f is File && f.path.endsWith('host.dart')) f.path,
    ];
    expect(offenders, isEmpty, reason: 'rename: $offenders');
  });
}
