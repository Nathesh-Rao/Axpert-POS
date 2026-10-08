// TEMPORARY with the swatch page (DEC-065): replaced by real screen goldens
// from step 1.4c. Needs the four TTFs in test/fonts; without them the golden
// tests are skipped LOUDLY (see the skip reason) and the viewport test still runs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/app_theme.dart';
import 'package:pos_application/core/theme/debug/theme_swatch_page.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';

import 'harness.dart';

Widget _app(ThemeData theme, bool dark) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  home: ThemeSwatchPage(initialDark: dark),
);

void main() {
  useTolerantGoldens();
  tearDownAll(() => AppTypography.useBundledFonts = false);

  testWidgets('reference viewport is 2102x1164 px at 1.125 (1868.44x1034.67)', (
    tester,
  ) async {
    AppTypography.useBundledFonts = true;
    useReferenceViewport(tester);
    await tester.pumpWidget(_app(AppTheme.light, false));
    final view = tester.view;
    expect(view.physicalSize, referencePhysicalSize);
    expect(view.devicePixelRatio, referenceScale);
    final logical = tester.getSize(find.byType(MaterialApp));
    expect(logical.width, closeTo(1868.444, 0.001));
    expect(logical.height, closeTo(1034.667, 0.001));
    expect(
      referencePageOffset +
          Offset(logical.width, logical.height) * referenceScale,
      const Offset(2112, 1172),
    );
  });

  final skipReason = fontsSkipReason();
  final skip = skipReason.isNotEmpty;
  // Outside testWidgets: real file IO would never complete in its fake-async zone.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!skip) await loadTestFonts();
  });
  final prefix = skip ? '[$skipReason] ' : '';

  for (final dark in <bool>[false, true]) {
    testWidgets(
      '${prefix}swatch specimen golden (${dark ? 'dark, unverified' : 'light'})',
      (tester) async {
        useRealShadows();
        try {
          useReferenceViewport(tester);
          await tester.pumpWidget(
            _app(dark ? AppTheme.dark : AppTheme.light, dark),
          );
          await tester.pumpAndSettle();
          final mode = dark ? 'dark' : 'light';
          // The page scrolls: capture the top, then each section at the top.
          for (final (name, heading) in <(String, String?)>[
            ('top', null),
            ('icons', 'Lucide icons (package lucide_icons_flutter)'),
            ('colors', 'Colors'),
            ('shadows', 'Shadows'),
          ]) {
            final position = tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            if (heading == null) {
              position.jumpTo(0);
            } else {
              final dy = tester.getTopLeft(find.text(heading)).dy;
              position.jumpTo(position.pixels + dy - 70);
            }
            await tester.pumpAndSettle();
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/specimen_${mode}_$name.png'),
            );
          }
        } finally {
          restoreDefaultShadows();
        }
      },
      skip: skip,
    );
  }

  testWidgets(
    '${prefix}Roboto Condensed loads: four distinct weights, not the fallback font',
    (tester) async {
      double width(AppFontWeight w) {
        final painter = TextPainter(
          text: TextSpan(
            text: 'Quick brown fox 0123456789',
            style: AppTypography.style(AppFontSize.s20, weight: w),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        return painter.width;
      }

      final widths = AppFontWeight.values.map(width).toSet();
      expect(widths.length, 4, reason: 'each weight must load its own file');
      final fallback = TextPainter(
        text: const TextSpan(
          text: 'Quick brown fox 0123456789',
          style: TextStyle(fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(widths, isNot(contains(fallback.width)));
    },
    skip: skip,
  );
}
