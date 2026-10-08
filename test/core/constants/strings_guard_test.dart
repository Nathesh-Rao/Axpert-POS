@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Text widgets in lib/modules and lib/shared take no string literals',
    () {
      // Text('...'), Text("..."), Text.rich is not scanned (no literals there).
      final literal = RegExp('''Text\\(\\s*(?:const\\s+)?[rR]?['"]''');
      final files = <File>[
        for (final dir in const ['lib/modules', 'lib/shared'])
          ...Directory(dir)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart')),
      ];
      final offenders = [
        for (final f in files)
          if (literal.hasMatch(f.readAsStringSync())) f.path,
      ];
      expect(offenders, isEmpty, reason: 'use AppStrings: $offenders');
    },
  );

  test('the guard regex catches literals', () {
    final literal = RegExp('''Text\\(\\s*(?:const\\s+)?[rR]?['"]''');
    expect(literal.hasMatch("Text('x')"), isTrue);
    expect(literal.hasMatch('Text( "x")'), isTrue);
    expect(literal.hasMatch('Text(context.strings.navPos())'), isFalse);
  });
}
