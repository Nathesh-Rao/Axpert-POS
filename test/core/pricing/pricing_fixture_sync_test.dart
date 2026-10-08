@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/pricing_golden_data.g.dart';

void main() {
  test('generated Dart copy equals pricing_golden.json', () {
    final json = File('test/fixtures/pricing_golden.json').readAsStringSync();
    expect(pricingGoldenJson, json);
  });
}
