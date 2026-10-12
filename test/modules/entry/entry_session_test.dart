// Sign-in against the users table and the store and counter picker (DEC-133).
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_entry_tokens.dart';
import 'package:pos_application/features/session/data/in_memory_session_repositories.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/modules/entry/controllers/login_controller.dart';
import 'package:pos_application/modules/entry/controllers/picker_controller.dart';
import 'package:pos_application/modules/entry/views/login_view.dart';
import 'package:pos_application/modules/entry/views/store_picker_view.dart';
import 'package:pos_application/modules/pos/views/pos_view.dart';

import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/viewport.dart';

const Duration _hold = Duration(milliseconds: AppEntryMotion.splashHoldMs);
const Duration _hop = Duration(milliseconds: AppEntryMotion.splashToLoginMs);

ActiveSession _twoStoreSession() => ActiveSession.fixed(
  user: testUser,
  store: testAccess.first.store,
  counter: testAccess.first.counters.first,
  access: const <StoreAccess>[],
  quickCash: const <String, List<int>>{},
  users: InMemoryUserRepository(
    users: <UserCredential>[testCredential],
    access: <String, List<StoreAccess>>{testUser.id: testAccess},
  ),
);

Future<void> _toLogin(WidgetTester tester, {ActiveSession? session}) async {
  useLogicalViewport(tester, const Size(1280, 720));
  final binding = await bootInWidgetTest(tester, session: session);
  await tester.pumpWidget(testApp(binding, initialRoute: AppRoutes.splash));
  await tester.pump();
  await tester.pump(_hold);
  await tester.pump(_hop);
  await tester.pump(
    const Duration(
      milliseconds: AppEntryMotion.formRiseDelayMs + AppEntryMotion.formRiseMs,
    ),
  );
  await tester.pump();
}

Future<void> _submit(WidgetTester tester, String user, String pass) async {
  await tester.enterText(find.byType(TextField).first, user);
  await tester.enterText(find.byType(TextField).last, pass);
  await tester.tap(find.text('Sign In'));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  useTestApp();

  testWidgets('a wrong password shows one generic error and stays', (
    tester,
  ) async {
    await _toLogin(tester);
    await _submit(tester, 'cashier', 'not-the-password');
    expect(find.text('Wrong username or password.'), findsOneWidget);
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(PosView), findsNothing);
    expect(Get.find<LoginController>().password.text, isEmpty);
    // An unknown user gets the same message.
    await _submit(tester, 'ghost', 'secret');
    expect(find.text('Wrong username or password.'), findsOneWidget);
  });

  testWidgets(
    'the right credentials with one store and counter skip the picker',
    (tester) async {
      await _toLogin(tester);
      await _submit(tester, 'cashier', 'secret');
      await tester.pump(
        const Duration(milliseconds: AppEntryMotion.loginToLandingMs + 50),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StorePickerView), findsNothing);
      expect(find.byType(PosView), findsOneWidget);
    },
  );

  testWidgets('several stores open the picker, Continue opens the store', (
    tester,
  ) async {
    await _toLogin(tester, session: _twoStoreSession());
    await _submit(tester, 'cashier', 'secret');
    await tester.pump(
      const Duration(milliseconds: AppEntryMotion.splashToLoginMs + 50),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StorePickerView), findsOneWidget);
    final picker = Get.find<PickerController>();
    expect(picker.stores, hasLength(3));
    picker.selectStore('MAISON GALAXY - MARINA');
    expect(picker.counter.value!.name, 'C3');
    await tester.tap(find.text('Continue'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(
      const Duration(milliseconds: AppEntryMotion.loginToLandingMs + 50),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PosView), findsOneWidget);
    expect(
      Get.find<ActiveSession>().store.value!.name,
      'MAISON GALAXY - MARINA',
    );
  });

  testWidgets('no users: the login says so and nothing signs in', (
    tester,
  ) async {
    final empty = ActiveSession.fixed(
      user: testUser,
      store: testAccess.first.store,
      counter: testAccess.first.counters.first,
      access: const <StoreAccess>[],
      quickCash: const <String, List<int>>{},
    );
    await _toLogin(tester, session: empty);
    await tester.pump();
    expect(
      find.textContaining('No users are set up on this device.'),
      findsOneWidget,
    );
    await _submit(tester, 'cashier', 'secret');
    expect(find.byType(LoginView), findsOneWidget);
  });
}
