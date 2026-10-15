import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../shared/controllers/overlay_controller.dart';
import '../../shared/controllers/search_field_controller.dart';
import '../../shared/controllers/shell_chrome_controller.dart';
import '../../modules/pos/controllers/pos_work_view_controller.dart';
import 'shortcut_controller.dart';

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class CloseOverlaysIntent extends Intent {
  const CloseOverlaysIntent();
}

class RunShortcutIntent extends Intent {
  const RunShortcutIntent(this.action);

  final ShortcutAction action;
}

/// Global keyboard shortcuts, placed above the Navigator (DEC-005, DEC-041):
/// Ctrl+K and Cmd+K focus the search field; Ctrl/Cmd+B resizes the Products
/// panel and Ctrl/Cmd+. shows or hides Billing (DEC-141); F2 to F6 always fire, even inside
/// inputs and with dialogs open (port as-is, KG-014); Esc closes the dialog
/// and menus (or, with none open, goes from the catalog layout back to the cart) and refocuses search; Delete only outside text input and with no
/// dialog open.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({required this.child, super.key});

  final Widget child;

  static final Map<ShortcutActivator, Intent> bindings =
      <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            const FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            const FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            const RunShortcutIntent(ShortcutAction.switchWorkView),
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
            const RunShortcutIntent(ShortcutAction.switchWorkView),
        const SingleActivator(LogicalKeyboardKey.period, control: true):
            const RunShortcutIntent(ShortcutAction.toggleBilling),
        const SingleActivator(LogicalKeyboardKey.period, meta: true):
            const RunShortcutIntent(ShortcutAction.toggleBilling),
        // Ctrl/Cmd+I: new product (Ctrl/Cmd+N is the browser's new window).
        const SingleActivator(LogicalKeyboardKey.keyI, control: true):
            const RunShortcutIntent(ShortcutAction.newProduct),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true):
            const RunShortcutIntent(ShortcutAction.newProduct),
        const SingleActivator(LogicalKeyboardKey.f2): const RunShortcutIntent(
          ShortcutAction.cash,
        ),
        const SingleActivator(LogicalKeyboardKey.f3): const RunShortcutIntent(
          ShortcutAction.card,
        ),
        const SingleActivator(LogicalKeyboardKey.f4): const RunShortcutIntent(
          ShortcutAction.hold,
        ),
        const SingleActivator(LogicalKeyboardKey.f5): const RunShortcutIntent(
          ShortcutAction.recall,
        ),
        const SingleActivator(LogicalKeyboardKey.f6): const RunShortcutIntent(
          ShortcutAction.discount,
        ),
        const SingleActivator(LogicalKeyboardKey.escape):
            const CloseOverlaysIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const RunShortcutIntent(ShortcutAction.deleteSelected),
      };

  /// True while the focused widget is a text field.
  static bool get isEditingText {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: bindings,
      child: Actions(
        actions: <Type, Action<Intent>>{
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (_) {
              Get.find<SearchFieldController>().focus();
              return null;
            },
          ),
          CloseOverlaysIntent: CallbackAction<CloseOverlaysIntent>(
            onInvoke: (_) {
              final chrome = Get.find<ShellChromeController>();
              final overlay = Get.find<OverlayController>();
              // A dialog or menu closes first; with none open Escape returns
              // from the catalog to the cart (desktop layout, items in the
              // cart).
              final somethingOpen =
                  overlay.isOpen || chrome.menu.value != ShellMenu.none;
              chrome.closeMenu();
              overlay.close();
              if (!somethingOpen && Get.isRegistered<PosWorkViewController>()) {
                Get.find<PosWorkViewController>().back();
              }
              return null;
            },
          ),
          RunShortcutIntent: CallbackAction<RunShortcutIntent>(
            onInvoke: (intent) {
              if (intent.action == ShortcutAction.deleteSelected &&
                  (isEditingText || Get.find<OverlayController>().isOpen)) {
                return null;
              }
              Get.find<ShortcutController>().run(intent.action);
              return null;
            },
          ),
        },
        // Fallback focus so key events have a target when nothing else is
        // focused (e.g. right after a dialog closes).
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          debugLabel: 'app-shortcuts',
          child: child,
        ),
      ),
    );
  }
}
