// The side rail card alone (default states, one item selected in turn), light
// and dark, at 1280x720 and 1868x1035. Regression goldens (no React reference).
@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/responsive/app_metrics_scope.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/app_theme.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/modules/shell/widgets/rail_card.dart';

import 'harness.dart';

const _sizes = <Size>[Size(1280, 720), Size(1868, 1035)];
const _pages = <AppPage, String>{
  AppPage.pos: 'pos',
  AppPage.products: 'products',
  AppPage.more: 'more',
};

void main() {
  useTolerantGoldens();
  final skipReason = fontsSkipReason();
  final skip = skipReason.isNotEmpty;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!skip) await loadTestFonts();
  });

  for (final size in _sizes) {
    for (final dark in <bool>[false, true]) {
      for (final entry in _pages.entries) {
        final file =
            'rail_${entry.value}_${dark ? 'dark' : 'light'}_${size.width.toInt()}';
        testWidgets('${skip ? '[$skipReason] ' : ''}$file', (tester) async {
          useRealShadows();
          AppTypography.useBundledFonts = true;
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final m = AppMetrics(size, touch: false);
          final theme = dark ? AppTheme.dark : AppTheme.light;
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: AppMetricsScope(
                metrics: m,
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: RepaintBoundary(
                      key: const ValueKey<String>('rail'),
                      child: ColoredBox(
                        color: theme.scaffoldBackgroundColor,
                        child: Padding(
                          padding: EdgeInsets.all(m.layoutGap),
                          child: SizedBox(
                            height: size.height - 2 * m.layoutGap - 64,
                            child: RailCard(
                              current: entry.key,
                              onSelect: (_) {},
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          try {
            await expectLater(
              find.byKey(const ValueKey<String>('rail')),
              matchesGoldenFile('goldens/$file.png'),
            );
          } finally {
            restoreDefaultShadows();
          }
        });
      }
    }
  }
}
