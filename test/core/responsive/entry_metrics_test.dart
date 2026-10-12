@TestOn('vm')
library;

import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/responsive/entry_metrics.dart';
import 'package:pos_application/core/theme/tokens/app_entry_tokens.dart';

void main() {
  test('scale follows the width inside the clamp', () {
    expect(EntryMetrics.of(const Size(1672, 941)).scale, 1);
    expect(EntryMetrics.of(const Size(900, 700)).scale, AppEntrySizes.minScale);
    expect(
      EntryMetrics.of(const Size(2400, 1200)).scale,
      AppEntrySizes.maxScale,
    );
  });

  test('at the reference width the form is the screenshot column', () {
    final m = EntryMetrics.of(const Size(1672, 941));
    expect(m.formWidth, closeTo(AppEntrySizes.formWidth, 0.5));
    expect(m.panelOverlapsPhoto, isFalse);
  });

  test('narrow and tall windows put the panel over the photo', () {
    expect(EntryMetrics.of(const Size(950, 733)).panelOverlapsPhoto, isTrue);
    expect(EntryMetrics.of(const Size(1024, 768)).panelOverlapsPhoto, isTrue);
    expect(EntryMetrics.of(const Size(1868, 1035)).panelOverlapsPhoto, isFalse);
  });

  test('the form always fits its panel', () {
    for (final w in <double>[900, 950, 1024, 1280, 1500, 1868, 2400]) {
      final m = EntryMetrics.of(Size(w, 800));
      expect(m.formWidth, lessThanOrEqualTo(m.panelWidth), reason: '$w');
      expect(m.formWidth, greaterThanOrEqualTo(AppEntrySizes.formMinWidth));
    }
  });
}
