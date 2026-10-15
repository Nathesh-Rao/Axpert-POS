// DEC-150: the user menu "Logout" signs out for real: the session and the
// session-scoped controllers are reset in memory, the login screen replaces
// the whole route stack and Back cannot return to a signed-in page.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/features/session/data/in_memory_session_repositories.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/modules/entry/views/login_view.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/views/pos_view.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/shell_chrome_controller.dart';

import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/viewport.dart';

ActiveSession _session() => ActiveSession.fixed(
  user: testUser,
  store: testAccess.first.store,
  counter: testAccess.first.counters.first,
  access: testAccess,
  quickCash: const <String, List<int>>{},
  users: InMemoryUserRepository(
    users: <UserCredential>[testCredential],
    access: <String, List<StoreAccess>>{testUser.id: testAccess},
  ),
);

Future<void> _boot(WidgetTester tester) async {
  useLogicalViewport(tester, const Size(1280, 720));
  final binding = await bootInWidgetTest(tester, session: _session());
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _logoutFromMenu(WidgetTester tester) async {
  Get.find<ShellChromeController>().toggleUserMenu();
  await tester.pumpAndSettle();
  await tester.tap(find.text('Logout'));
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('Logout lands on the login screen with the stack cleared', (
    tester,
  ) async {
    await _boot(tester);
    expect(find.byType(PosView), findsOneWidget);
    final session = Get.find<ActiveSession>();
    expect(session.isSignedIn, isTrue);

    await _logoutFromMenu(tester);

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(PosView), findsNothing);
    expect(Get.currentRoute, AppRoutes.login);
    expect(session.isSignedIn, isFalse);
    expect(session.store.value, isNull);
    // The stack was cleared: nothing below the login page.
    expect(Get.key.currentState!.canPop(), isFalse);
    // System Back (and browser Back) does not return to a signed-in page.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(PosView), findsNothing);
    expect(RxInterface.proxy, isNull);
  });

  testWidgets('the shift close dialog keeps its own behavior (no sign-out)', (
    tester,
  ) async {
    await _boot(tester);
    Get.find<OverlayController>().open('close');
    await tester.pumpAndSettle();
    Get.find<ShiftController>().closeCounter();
    await tester.pumpAndSettle();

    expect(Get.find<ShiftController>().signedOut.value, isTrue);
    expect(Get.find<ActiveSession>().isSignedIn, isTrue);
    expect(find.byType(LoginView), findsNothing);
  });

  testWidgets('sign-out empties the in-memory session state', (tester) async {
    await _boot(tester);
    final products = Get.find<ProductsController>();
    Get.find<CartActionsController>().add(products.byId(5)!);
    Get.find<OverlayController>().open('settings');
    Get.find<ShiftController>().signedOut.value = true;
    // Lets the fake-clock cart save finish, as it does in the real app.
    await tester.pumpAndSettle();
    expect(Get.find<CartController>().isActive, isTrue);

    await tester.runAsync(() => Get.find<ActiveSession>().signOut());
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(Get.find<CartController>().isActive, isFalse);
    expect(products.products, isEmpty);
    expect(Get.find<OverlayController>().modal.value, isNull);
    expect(Get.find<ShiftController>().signedOut.value, isFalse);
    expect(Get.find<ShellChromeController>().menu.value, ShellMenu.none);
    expect(find.text('Counter closed'), findsNothing);
    await tester.pump(const Duration(seconds: 6)); // the add-item toast
  });
}
