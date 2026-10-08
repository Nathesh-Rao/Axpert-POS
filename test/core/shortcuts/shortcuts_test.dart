import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/shortcuts/shortcut_controller.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/shell_chrome_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/viewport.dart';
import '../../support/test_app.dart';

Future<void> _boot(WidgetTester tester, {InMemoryLocalStore? store}) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester, store: store);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _chord(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 60));
}

void main() {
  useTestApp();

  for (final (name, modifier) in <(String, LogicalKeyboardKey)>[
    ('Ctrl', LogicalKeyboardKey.controlLeft),
    ('Cmd', LogicalKeyboardKey.metaLeft),
  ]) {
    testWidgets('$name+K focuses the search field', (tester) async {
      await _boot(tester);
      final search = Get.find<SearchFieldController>();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(search.focusNode.hasFocus, isFalse);
      await _chord(tester, modifier, LogicalKeyboardKey.keyK);
      expect(search.focusNode.hasFocus, isTrue);
    });
  }

  testWidgets('Ctrl+K inside the field on macOS keeps the text', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _boot(tester);
      final search = Get.find<SearchFieldController>();
      await tester.enterText(find.byType(TextField).first, 'cola');
      search.text.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await _chord(
        tester,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.keyK,
      );
      expect(search.text.text, 'cola');
      expect(search.focusNode.hasFocus, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('F2-F6 fire inside a focused field and with a dialog open', (
    tester,
  ) async {
    await _boot(tester);
    final toasts = Get.find<ToastController>();
    final overlay = Get.find<OverlayController>();
    Get.find<SearchFieldController>().focus();
    await tester.pump();
    const keys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
    ];
    for (final key in keys) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    // F2 and F3 are real since S4.a (empty cart: nothing happens, no toast).
    expect(toasts.toasts.map((t) => t.text), <String>[
      'Hold bill (demo)',
      'Recall bill (demo)',
      'Apply discount (demo)',
    ]);
    toasts.toasts.clear();

    overlay.open('profile');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pump();
    expect(toasts.toasts.single.text, 'Hold bill (demo)');
    expect(overlay.isOpen, isTrue, reason: 'F4 does not close the dialog');
    await _drain(tester);
  });

  testWidgets('Esc closes menus and dialogs and refocuses search', (
    tester,
  ) async {
    await _boot(tester);
    final chrome = Get.find<ShellChromeController>();
    final overlay = Get.find<OverlayController>();
    final search = Get.find<SearchFieldController>();

    chrome.toggleUserMenu();
    await tester.pumpAndSettle();
    expect(chrome.menu.value, ShellMenu.user);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 60));
    expect(chrome.menu.value, ShellMenu.none);
    expect(search.focusNode.hasFocus, isTrue);

    overlay.open('shortcuts');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(overlay.isOpen, isFalse);
    expect(find.text('This screen arrives in a later step.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    expect(search.focusNode.hasFocus, isTrue);
  });

  testWidgets('Delete runs only outside inputs and with no dialog', (
    tester,
  ) async {
    await _boot(tester);
    var calls = 0;
    Get.find<ShortcutController>().handlers[ShortcutAction.deleteSelected] =
        () => calls++;

    // Focus is in the search field (an input): ignored.
    Get.find<SearchFieldController>().focus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(calls, 0);

    // Focus elsewhere: runs.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(calls, 1);

    // Dialog open: ignored.
    Get.find<OverlayController>().open('profile');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(calls, 1);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets('dark mode toggle switches the theme and persists', (
    tester,
  ) async {
    final store = InMemoryLocalStore();
    await _boot(tester, store: store);
    Get.offAllNamed<void>(AppRoutes.more);
    await tester.pumpAndSettle();
    ThemeData theme() => Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme().brightness, Brightness.light);

    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(theme().brightness, Brightness.dark);
    expect(Get.find<SettingsController>().dark, isTrue);
    expect(await tester.runAsync(() => store.read(StorageKeys.dark)), isTrue);

    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(theme().brightness, Brightness.light);
    await tester.pump(const Duration(milliseconds: 60));
  });
}
