// Layout matrix of the splash and login screens: no overflow or framework
// error at the three checked sizes, a tablet size and short windows; the form
// texts stay on one line and every control is at least 48 px high.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_entry_tokens.dart';
import 'package:pos_application/modules/entry/views/login_view.dart';
import 'package:pos_application/modules/entry/views/splash_view.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';

import '../golden/harness.dart' show loadTestFonts;
import '../support/test_app.dart';
import '../support/viewport.dart';

const List<Size> _sizes = <Size>[
  Size(950, 733),
  Size(1280, 720),
  Size(1868, 1035),
  Size(1024, 768),
  Size(1194, 834),
  Size(900, 600),
  Size(1280, 600),
  Size(1900, 1000),
];

void main() {
  useTestApp();
  setUpAll(loadTestFonts);

  for (final size in _sizes) {
    for (final dark in <bool>[false, true]) {
      testWidgets(
        'splash and login fit at ${size.width.toInt()}x${size.height.toInt()}'
        '${dark ? ' dark' : ''}',
        (tester) async {
          useLogicalViewport(tester, size);
          final binding = await bootInWidgetTest(tester);
          if (dark) {
            await tester.runAsync(
              () => Get.find<SettingsController>().setDark(true),
            );
          }
          await tester.pumpWidget(
            testApp(binding, initialRoute: AppRoutes.splash),
          );
          await tester.pump(const Duration(milliseconds: 1000));
          expect(tester.takeException(), isNull);
          expect(find.byType(SplashView), findsOneWidget);

          await tester.tap(find.byType(SplashView));
          await tester.pump(
            const Duration(milliseconds: AppEntryMotion.splashToLoginMs),
          );
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.byType(LoginView), findsOneWidget);

          // Texts stay on one line (a wrapped title would be about twice as high).
          for (final text in <String>['Welcome Back', 'Sign In']) {
            final box = tester.getRect(find.text(text));
            expect(box.height, lessThan(80), reason: text);
            expect(box.right, lessThanOrEqualTo(size.width), reason: text);
          }
          // Controls reach the 48 px touch size.
          final fields = find.byType(TextField);
          for (var i = 0; i < 2; i++) {
            final r = tester.getRect(
              find
                  .ancestor(of: fields.at(i), matching: find.byType(Container))
                  .first,
            );
            expect(r.height, greaterThanOrEqualTo(AppEntrySizes.minTouch));
          }
          // The window may be short: the form scrolls instead of overflowing.
          await tester.ensureVisible(find.text('Login with QR Code'));
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
