// Asserts every token against the tables in docs/css_metrics.md (the tables
// are the reference; edit the document and the token together).
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/tokens/app_colors.dart';
import 'package:pos_application/core/theme/tokens/app_motion.dart';
import 'package:pos_application/core/theme/tokens/app_radii.dart';
import 'package:pos_application/core/theme/tokens/app_shadows.dart';
import 'package:pos_application/core/theme/tokens/app_sizes.dart';
import 'package:pos_application/core/theme/tokens/app_spacing.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';

/// Rows (cell lists) of the table that follows `<!-- table:[name] -->`.
List<List<String>> table(String name) {
  final lines = File('docs/css_metrics.md').readAsLinesSync();
  final start = lines.indexOf('<!-- table:$name -->');
  expect(start, isNonNegative, reason: 'marker table:$name missing');
  final rows = <List<String>>[];
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty && rows.isEmpty) continue;
    if (!line.startsWith('|')) break;
    rows.add(
      line
          .split('|')
          .sublist(1, line.split('|').length - 1)
          .map((c) => c.trim())
          .toList(),
    );
  }
  return rows.skip(2).toList(); // header + separator
}

String _name(String cell) => cell.replaceAll('`', '');

Color cssColor(String cell) {
  final hex = cell.replaceAll('`', '').replaceAll('#', '');
  final v = int.parse(hex, radix: 16);
  if (hex.length == 6) return Color(0xFF000000 | v);
  if (hex.length == 8) return Color(((v & 0xFF) << 24) | (v >> 8));
  fail('bad css color $cell');
}

void main() {
  group('colors', () {
    test('light matches the css_metrics table, every token documented', () {
      final rows = table('colors-light');
      final actual = AppColors.light.toMap();
      expect(rows.length, actual.length);
      for (final r in rows) {
        expect(actual[_name(r[0])], cssColor(r[1]), reason: r[0]);
      }
    });

    test('dark: only the documented tokens differ from light', () {
      final rows = table('colors-dark');
      final dark = AppColors.dark.toMap();
      final light = AppColors.light.toMap();
      final documented = <String>{};
      for (final r in rows) {
        final name = _name(r[0]);
        documented.add(name);
        expect(dark[name], cssColor(r[1]), reason: r[0]);
      }
      for (final name in light.keys.where((k) => !documented.contains(k))) {
        expect(dark[name], light[name], reason: '$name must not differ');
      }
      expect(documented.length, 21);
    });
  });

  void scalars(String name, Map<String, num> actual) {
    test('$name matches css_metrics', () {
      final rows = table(name);
      expect(rows.length, actual.length);
      for (final r in rows) {
        expect(actual[_name(r[0])], num.parse(r[1]), reason: r[0]);
      }
    });
  }

  group('scalars', () {
    scalars('radii', AppRadii.all);
    scalars('spacing', AppSpacing.all);
    scalars('sizes', AppSizes.all);
    scalars('motion', AppMotion.all);
    scalars('tracking', <String, num>{
      'brand': AppTracking.brand,
      'catalogCaption': AppTracking.catalogCaption,
      'managementEyebrow': AppTracking.managementEyebrow,
      'invoiceTotal': AppTracking.invoiceTotal,
      'receiptBrand': AppTracking.receiptBrand,
    });
  });

  test('shadows match css_metrics (layers, colors, inset flags)', () {
    final rows = table('shadows');
    expect(rows.length, AppShadows.all.length);
    for (final r in rows) {
      final layers = AppShadows.all[_name(r[0])]!;
      final parts = r[1].split(';').map((p) => p.trim()).toList();
      expect(layers.length, parts.length, reason: r[0]);
      for (var i = 0; i < parts.length; i++) {
        final t = parts[i].split(' ');
        final s = layers[i];
        expect(s.dx, double.parse(t[0]), reason: r[0]);
        expect(s.dy, double.parse(t[1]), reason: r[0]);
        expect(s.blur, double.parse(t[2]), reason: r[0]);
        expect(s.spread, double.parse(t[3]), reason: r[0]);
        expect(s.color, cssColor(t[4]), reason: r[0]);
        expect(s.inset, t.length > 5 && t[5] == 'inset', reason: r[0]);
      }
    }
  });
}
