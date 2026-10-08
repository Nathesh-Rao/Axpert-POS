@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/pricing_golden_data.g.dart';
import '../../fixtures/s6_golden_data.g.dart';

void main() {
  test('generated Dart copy equals pricing_golden.json', () {
    final json = File('test/fixtures/pricing_golden.json').readAsStringSync();
    expect(pricingGoldenJson, json);
  });

  test('generated Dart copy equals s6_golden.json', () {
    final json = File('test/fixtures/s6_golden.json').readAsStringSync();
    expect(s6GoldenJson, json);
  });
}
