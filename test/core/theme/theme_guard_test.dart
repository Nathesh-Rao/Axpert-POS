// Guards the theme rules from CLAUDE.md: no raw colors, google_fonts only in
// app_typography.dart, no font-size literals outside the token files.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('lib/core/theme/tokens/'))
      .toList();

  void forbid(String why, Pattern pattern) {
    test('no $why outside the token files', () {
      final offenders = <String>[
        for (final f in files)
          if (f.readAsStringSync().contains(pattern)) f.path,
      ];
      expect(offenders, isEmpty);
    });
  }

  forbid('raw Color(0x...) literal', RegExp(r'Color\(\s*0x'));
  forbid('Colors.* constant', RegExp(r'\bColors\.'));
  forbid('fontSize literal', RegExp(r'fontSize:\s*\d'));

  test('google_fonts is imported only by app_typography.dart', () {
    final offenders = <String>[
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') &&
            !f.path.endsWith('tokens/app_typography.dart') &&
            f.readAsStringSync().contains('package:google_fonts'))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
