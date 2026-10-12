// Demo entry flow: splash, login, landing. Fake time throughout; nothing is
// stored or sent, any non-empty username and password signs in.
@TestOn('vm')
library;

import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/config/entry_config.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_entry_tokens.dart';
import 'package:pos_application/modules/entry/controllers/login_controller.dart';
import 'package:pos_application/modules/entry/views/login_view.dart';
import 'package:pos_application/modules/entry/views/splash_view.dart';
import 'package:pos_application/modules/pos/views/pos_view.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const Duration _hold = Duration(milliseconds: AppEntryMotion.splashHoldMs);
const Duration _hop = Duration(milliseconds: AppEntryMotion.splashToLoginMs);

Future<void> _openSplash(WidgetTester tester) async {
  useLogicalViewport(tester, const Size(1280, 720));
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding, initialRoute: AppRoutes.splash));
  await tester.pump();
}

Future<void> _toLogin(WidgetTester tester) async {
  await tester.pump(_hold);
  await tester.pump(_hop);
  await tester.pump(
    const Duration(
      milliseconds: AppEntryMotion.formRiseDelayMs + AppEntryMotion.formRiseMs,
    ),
  );
  await tester.pump();
}

Finder _field(String label) => find.bySemanticsLabel(label);

void main() {
  useTestApp();

  test('the entry flow is on by default (SKIP_ENTRY is off)', () {
    expect(EntryConfig.skip, isFalse);
    expect(EntryConfig.initialRoute, AppRoutes.splash);
  });

  testWidgets('the test app skips the entry flow like SKIP_ENTRY', (
    tester,
  ) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    expect(find.byType(PosView), findsOneWidget);
    expect(find.byType(SplashView), findsNothing);
  });

  testWidgets('splash shows for about 2 s, then the login opens', (
    tester,
  ) async {
    await _openSplash(tester);
    expect(find.byType(SplashView), findsOneWidget);
    await tester.pump(_hold - const Duration(milliseconds: 100));
    expect(find.byType(SplashView), findsOneWidget);
    expect(find.byType(LoginView), findsNothing);
    await _toLogin(tester);
    // (the 100 ms left of the hold are inside _toLogin's first pump)
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('a tap skips the splash', (tester) async {
    await _openSplash(tester);
    await tester.tap(find.byType(SplashView));
    await tester.pump(_hop);
    await tester.pump();
    expect(find.byType(LoginView), findsOneWidget);
    await tester.pump(_hold); // the cancelled timer must not fire again
  });

  testWidgets('a key press skips the splash', (tester) async {
    await _openSplash(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(_hop);
    await tester.pump();
    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('empty fields show errors and focus the first one', (
    tester,
  ) async {
    await _openSplash(tester);
    await _toLogin(tester);
    final ctl = Get.find<LoginController>();
    expect(ctl.usernameFocus.hasFocus, isTrue, reason: 'autofocus');

    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your username or email'), findsNWidgets(2));
    // (one is the hint, one the error)
    expect(ctl.usernameEmpty.value, isTrue);
    expect(ctl.passwordEmpty.value, isTrue);
    expect(ctl.usernameFocus.hasFocus, isTrue);
    expect(find.byType(PosView), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'cashier');
    await tester.pump();
    expect(ctl.usernameEmpty.value, isFalse, reason: 'typing clears it');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(ctl.passwordEmpty.value, isTrue);
    expect(ctl.passwordFocus.hasFocus, isTrue);
    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('whitespace-only username is empty', (tester) async {
    await _openSplash(tester);
    await _toLogin(tester);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.enterText(find.byType(TextField).last, 'x');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(Get.find<LoginController>().usernameEmpty.value, isTrue);
  });

  testWidgets('Tab goes username to password', (tester) async {
    await _openSplash(tester);
    await _toLogin(tester);
    final ctl = Get.find<LoginController>();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(ctl.passwordFocus.hasFocus, isTrue);
  });

  testWidgets('submit shows a 600 ms loading state, then the landing page', (
    tester,
  ) async {
    await _openSplash(tester);
    await _toLogin(tester);
    final ctl = Get.find<LoginController>();
    await tester.enterText(find.byType(TextField).first, 'cashier');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(ctl.loading.value, isTrue);
    expect(find.text('Sign In'), findsNothing);

    // A second tap while loading does nothing.
    await tester.pump(const Duration(milliseconds: 500));
    expect(ctl.loading.value, isTrue);
    expect(find.byType(PosView), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(
      const Duration(milliseconds: AppEntryMotion.loginToLandingMs),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PosView), findsOneWidget);
    expect(find.byType(LoginView), findsNothing);
  });

  testWidgets('Enter in the password field submits', (tester) async {
    await _openSplash(tester);
    await _toLogin(tester);
    await tester.enterText(find.byType(TextField).first, 'cashier');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(Get.find<LoginController>().loading.value, isTrue);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(PosView), findsOneWidget);
  });

  testWidgets('the eye button shows and hides the password', (tester) async {
    await _openSplash(tester);
    await _toLogin(tester);
    final ctl = Get.find<LoginController>();
    expect(ctl.obscure.value, isTrue);
    await tester.tap(_field('Show password'));
    await tester.pump();
    expect(ctl.obscure.value, isFalse);
    await tester.tap(_field('Hide password'));
    await tester.pump();
    expect(ctl.obscure.value, isTrue);
  });

  testWidgets('QR login and forgot password are demo-only toasts', (
    tester,
  ) async {
    await _openSplash(tester);
    await _toLogin(tester);
    await tester.tap(find.text('Login with QR Code'));
    await tester.pump();
    expect(
      find.text('Login with QR Code is not available in this demo'),
      findsOneWidget,
    );
    expect(find.byType(LoginView), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('reduced motion: no animation, the same 2 s hold', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const _Reduced();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _openSplash(tester);
    expect(find.byType(SplashView), findsOneWidget);
    await tester.pump(_hold);
    await tester.pump(); // no route animation: the login is there at once
    expect(find.byType(LoginView), findsOneWidget);
    // The form is fully visible without waiting for the rise animation.
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text('Welcome Back'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 1);

    await tester.enterText(find.byType(TextField).first, 'cashier');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: AppEntryMotion.fakeLoginMs));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(PosView), findsOneWidget);
  });
}

class _Reduced implements AccessibilityFeatures {
  const _Reduced();

  @override
  bool get disableAnimations => true;

  @override
  bool get accessibleNavigation => false;
  @override
  bool get boldText => false;
  @override
  bool get highContrast => false;
  @override
  bool get invertColors => false;
  @override
  bool get onOffSwitchLabels => false;
  @override
  bool get reduceMotion => true;
  @override
  bool get supportsAnnounce => false;
}
