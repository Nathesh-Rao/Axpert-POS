@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pricing sources use no double/num and no Flutter or GetX', () {
    final files = <File>[
      ...Directory('lib/core/services/pricing')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('lib/core/utils/money_formatter.dart'),
    ];
    expect(files, isNotEmpty);
    final banned = {
      RegExp(r'\bdouble\b'): 'double',
      RegExp(r'\bnum\b'): 'num',
      RegExp(r'\.toDouble\('): 'toDouble',
      RegExp(r'package:flutter/'): 'flutter import',
      RegExp(r'package:get/'): 'get import',
      RegExp(r'dart:ui'): 'dart:ui',
    };
    for (final file in files) {
      final text = file.readAsStringSync();
      banned.forEach((pattern, name) {
        expect(
          pattern.hasMatch(text),
          isFalse,
          reason: '${file.path} uses $name',
        );
      });
    }
  });
}
