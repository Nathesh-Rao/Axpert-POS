import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../shared/controllers/overlay_controller.dart';
import '../../shared/controllers/search_field_controller.dart';
import '../../shared/controllers/shell_chrome_controller.dart';
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
/// Ctrl+K and Cmd+K focus the search field; F2 to F6 always fire, even inside
/// inputs and with dialogs open (port as-is, KG-014); Esc closes the dialog
/// and menus and refocuses search; Delete only outside text input and with no
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
              Get.find<ShellChromeController>().closeMenu();
              Get.find<OverlayController>().close();
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
