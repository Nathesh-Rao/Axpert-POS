import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';
import 'package:get/get.dart';

import '../../support/pos_support.dart';
import '../../support/test_app.dart';

void main() {
  useTestApp();

  test('add: toast, beep, select, highlight, clears search', () async {
    final h = await PosHarness.boot();
    final search = Get.find<SearchFieldController>()..text.text = 'coca';
    final ok = h.actions.add(h.products.byId(0)!);
    expect(ok, isTrue);
    expect(h.toasts.toasts.last.text, 'Coca Cola 500ml added');
    expect(h.toasts.toasts.last.kind, ToastKind.success);
    expect(h.beep.played, 1);
    expect(h.selection.selected.value, 0);
    expect(h.selection.highlight.value, 0);
    expect(search.text.text, '');
    expect(h.cart.cart.value.lines.single.qty, Qty.units(1));
    h.selection.onClose();
  });

  test('add at stock: warning toast, nothing changes, no beep', () async {
    final h = await PosHarness.boot();
    final limited = h.products.byId(14)!;
    for (var i = 0; i < 8; i++) {
      expect(h.actions.add(limited), isTrue);
    }
    final beeps = h.beep.played;
    expect(h.actions.add(limited), isFalse);
    expect(h.toasts.toasts.last.text, 'Available stock: 8');
    expect(h.toasts.toasts.last.kind, ToastKind.warning);
    expect(h.beep.played, beeps);
    expect(h.cart.cart.value.lines.single.qty, Qty.units(8));
    h.selection.onClose();
  });

  test('beep respects the setting', () async {
    final h = await PosHarness.boot();
    await Get.find<SettingsController>().setBeep(false);
    h.actions.add(h.products.byId(0)!);
    expect(h.beep.played, 0);
    await Get.find<SettingsController>().setBeep(true);
    h.actions.add(h.products.byId(0)!);
    expect(h.beep.played, 1);
    h.selection.onClose();
  });

  test('remove shows an info toast whose Undo restores the line', () async {
    final h = await PosHarness.boot();
    h.actions.add(h.products.byId(0)!);
    h.actions.add(h.products.byId(1)!);
    final line = h.cart.lineOf(0)!;
    h.actions.remove(line);
    expect(h.cart.cart.value.lines.length, 1);
    final toast = h.toasts.toasts.last;
    expect(toast.text, 'Coca Cola 500ml removed');
    expect(toast.kind, ToastKind.info);
    h.toasts.undo(toast.id);
    expect(h.cart.cart.value.lines.length, 2);
    h.selection.onClose();
  });

  test('changeQty: over stock warns, zero removes, else sets', () async {
    final h = await PosHarness.boot();
    h.actions.add(h.products.byId(14)!);
    final line = h.cart.lineOf(14)!;
    h.actions.changeQty(line, Qty.units(9));
    expect(h.toasts.toasts.last.text, 'Only 8 available in stock');
    expect(h.cart.lineOf(14)!.qty, Qty.units(1));
    h.actions.changeQty(line, Qty.units(5));
    expect(h.cart.lineOf(14)!.qty, Qty.units(5));
    h.actions.changeQty(h.cart.lineOf(14)!, Qty.zero);
    expect(h.cart.lineOf(14), isNull);
    expect(h.toasts.toasts.last.text, 'Paper Boat Aam 200ml removed');
    h.selection.onClose();
  });

  test('removeSelected removes the selected line only', () async {
    final h = await PosHarness.boot();
    h.actions.add(h.products.byId(0)!);
    h.actions.add(h.products.byId(1)!);
    h.selection.select(0);
    h.actions.removeSelected();
    expect(h.cart.cart.value.lines.map((l) => l.product.id), [1]);
    h.selection.select(null);
    h.actions.removeSelected();
    expect(h.cart.cart.value.lines.length, 1);
    h.selection.onClose();
  });
}
