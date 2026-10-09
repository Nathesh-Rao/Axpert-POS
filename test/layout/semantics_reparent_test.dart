// Guard for the Flutter 3.38.4 web engine bug flutter/flutter#175180 (fixed in
// PR #177069, not in 3.38.4): with web accessibility ON, the engine corrupts
// its semantics tree when, in ONE frame, a semantics node is removed while one
// of its children is attached to another parent. The console then floods with
// "Child #N is missing in the tree" and "Unexpected null value".
// This VM test records (node id -> parent id) around every UI step and fails on
// exactly that pattern, so the trigger is found without a browser.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';

import '../support/test_app.dart';
import '../support/viewport.dart';

Map<int, int> _parents(WidgetTester tester) {
  final map = <int, int>{};
  final root =
      tester.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  void walk(SemanticsNode node) {
    node.visitChildren((child) {
      map[child.id] = node.id;
      walk(child);
      return true;
    });
  }

  if (root != null) {
    map[root.id] = -1;
    walk(root);
  }
  return map;
}

/// Nodes that survived, changed parent, while their old parent was removed.
List<String> _reparented(Map<int, int> before, Map<int, int> after) {
  final out = <String>[];
  after.forEach((id, parent) {
    final old = before[id];
    if (old != null && old != parent) {
      out.add('node $id: parent $old (removed) -> $parent');
    }
  });
  return out;
}

void main() {
  useTestApp();

  testWidgets('search + Enter (first item) reparents no semantics node', (
    tester,
  ) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final handle = tester.ensureSemantics();
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();

    final bad = <String>[];
    var last = _parents(tester);
    Future<void> frame(String step, [Duration d = Duration.zero]) async {
      await tester.pump(d);
      final now = _parents(tester);
      final moved = _reparented(last, now);
      bad.addAll(moved.map((m) => '$step $m'));
      last = now;
    }

    await tester.tap(find.byType(EditableText).first);
    await frame('focus');
    await tester.enterText(find.byType(EditableText).first, 'Coca');
    await frame('typed');
    await frame('typed+', const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await frame('enter');
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().byId(5)!,
    );
    await frame('add');
    for (var i = 0; i < 8; i++) {
      await frame('f$i', const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 6));
    expect(bad, isEmpty, reason: bad.join('\n'));
    handle.dispose();
  });

  testWidgets('every page, dialog, drawer and toast reparents no node', (
    tester,
  ) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final handle = tester.ensureSemantics();
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();

    // After EVERY frame (the engine sees every frame as one update).
    final bad = <String>[];
    var step = 'start';
    var last = _parents(tester);
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      final now = _parents(tester);
      bad.addAll(_reparented(last, now).map((m) => '$step: $m'));
      last = now;
    });
    Future<void> settle(String name) async {
      step = name;
      await tester.pumpAndSettle();
    }

    final products = Get.find<ProductsController>();
    final overlay = Get.find<OverlayController>();
    for (final id in <int>[5, 6, 7]) {
      Get.find<CartActionsController>().add(products.byId(id)!);
      await settle('add $id');
    }
    Get.find<CartActionsController>().add(products.byId(5)!);
    await settle('add again');
    for (final page in <String>[
      AppRoutes.products,
      AppRoutes.customers,
      AppRoutes.sales,
      AppRoutes.returns,
      AppRoutes.reports,
      AppRoutes.more,
      AppRoutes.pos,
    ]) {
      Get.offAllNamed<void>(page);
      await settle('page $page');
    }
    for (final id in <String>[
      'settings',
      'profile',
      'close',
      'shortcuts',
      'scan',
      'priceCheck',
      'customers',
      'addCustomer',
      'recall',
      'discount',
      'counter',
      'note',
      'reprint',
      'confirm',
    ]) {
      if (id == 'confirm') {
        overlay.openConfirm('Confirm?', () {});
      } else {
        overlay.open(id);
      }
      await settle('open $id');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle('close $id');
    }
    await tester.pump(const Duration(seconds: 6));
    expect(bad, isEmpty, reason: bad.join('\n'));
    handle.dispose();
  });
}
