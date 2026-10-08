import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/modules/shell/widgets/bill_summary_frame.dart';
import 'package:pos_application/modules/shell/widgets/offline_banner.dart';
import 'package:pos_application/modules/shell/widgets/sidebar.dart';
import 'package:pos_application/modules/shell/widgets/top_bar.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/shell_chrome_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../golden/harness.dart';
import '../../support/test_app.dart';

Future<void> _boot(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('summary frame is 380 on POS and 310 elsewhere (KG-029)', (
    tester,
  ) async {
    await _boot(tester);
    expect(tester.getSize(find.byType(BillSummaryFrame)).width, 380);
    for (final route in <String>[
      AppRoutes.products,
      AppRoutes.customers,
      AppRoutes.sales,
      AppRoutes.returns,
      AppRoutes.reports,
      AppRoutes.more,
    ]) {
      Get.offAllNamed<void>(route);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(BillSummaryFrame)).width,
        310,
        reason: route,
      );
      expect(find.text('Bill Summary'), findsOneWidget);
    }
  });

  testWidgets('offline banner shows only while offline', (tester) async {
    await _boot(tester);
    const text = 'Offline mode – bills will sync later';
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text(text), findsNothing);
    Get.find<ShellChromeController>().toggleOnline();
    await tester.pump();
    expect(find.text(text), findsOneWidget);
    Get.find<ShellChromeController>().toggleOnline();
    await tester.pump();
    expect(find.text(text), findsNothing);
  });

  testWidgets('dialog dims the whole window; toast sits above it', (
    tester,
  ) async {
    await _boot(tester);
    final overlay = Get.find<OverlayController>();
    final chrome = Get.find<ShellChromeController>();
    overlay.open('profile');
    await tester.pumpAndSettle();
    expect(find.text('This screen arrives in a later step.'), findsOneWidget);

    // Top bar and sidebar are under the scrim: they are not hit-testable.
    expect(find.byType(TopBar).hitTestable(), findsNothing);
    expect(find.byType(Sidebar).hitTestable(), findsNothing);

    // A toast shown now is still reachable above the dialog.
    Get.find<ToastController>().show('Above dialog');
    await tester.pumpAndSettle();
    expect(find.text('Above dialog').hitTestable(), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));

    // Tapping where the top bar is only hits the scrim: no chip toggle.
    await tester.tap(find.text('Online'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chrome.online.value, isTrue);
    expect(overlay.modal.value, isNull);
    overlay.open('profile');
    await tester.pumpAndSettle();

    // Clicking the scrim closes the dialog and refocuses the search field.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(overlay.modal.value, isNull);
    expect(find.text('This screen arrives in a later step.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
  });

  testWidgets('Close button and controller both close the dialog', (
    tester,
  ) async {
    await _boot(tester);
    final overlay = Get.find<OverlayController>();
    overlay.open('scan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(overlay.modal.value, isNull);
    overlay.open('shortcuts');
    await tester.pumpAndSettle();
    expect(find.text('Shortcuts'), findsWidgets);
    overlay.close();
    await tester.pumpAndSettle();
    expect(find.text('This screen arrives in a later step.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets('toasts: last four kept, auto dismiss after 5 s, undo', (
    tester,
  ) async {
    await _boot(tester);
    final toasts = Get.find<ToastController>();
    var undone = false;
    for (var i = 0; i < 6; i++) {
      toasts.show('t$i', onUndo: i == 5 ? () => undone = true : null);
    }
    await tester.pumpAndSettle();
    expect(toasts.toasts.map((t) => t.text), <String>['t2', 't3', 't4', 't5']);
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(toasts.toasts.length, 3);
    await tester.pump(const Duration(seconds: 5));
    expect(toasts.toasts, isEmpty);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 60));
  });
}
