import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_strings.dart';

/// One row of the "Keyboard shortcuts" dialog: the text and the real key it
/// stands for. [keys] are the activators of `AppShortcuts.bindings` the row
/// relies on (empty for Enter, which the search field handles itself).
class ShortcutHelpEntry {
  const ShortcutHelpEntry({
    required this.text,
    required this.label,
    required this.keys,
  });

  final String Function(AppStrings s) text;
  final String Function(AppStrings s, TargetPlatform platform) label;
  final List<ShortcutActivator> keys;
}

/// The nine rows of the prototype's dialog. Each key listed here must exist
/// as a binding (a test checks it), so the help never names a shortcut that
/// does not work.
abstract final class ShortcutHelp {
  static String _fn(AppStrings s, int n) => s.keyFunction(n);

  static final List<ShortcutHelpEntry> entries = <ShortcutHelpEntry>[
    ShortcutHelpEntry(
      text: (s) => s.helpFocusSearch(),
      // "⌘K" on macOS, "Ctrl+K" elsewhere (DEC-007).
      label: (s, platform) => platform == TargetPlatform.macOS
          ? s.searchShortcutMac()
          : s.searchShortcutOther(),
      keys: const <ShortcutActivator>[
        SingleActivator(LogicalKeyboardKey.keyK, control: true),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true),
      ],
    ),
    ShortcutHelpEntry(
      text: (s) => s.helpAddScanned(),
      label: (s, _) => s.keyEnter(),
      keys: const <ShortcutActivator>[],
    ),
    ShortcutHelpEntry(
      text: (s) => s.shortcutCash(),
      label: (s, _) => _fn(s, 2),
      keys: const <ShortcutActivator>[SingleActivator(LogicalKeyboardKey.f2)],
    ),
    ShortcutHelpEntry(
      text: (s) => s.shortcutCard(),
      label: (s, _) => _fn(s, 3),
      keys: const <ShortcutActivator>[SingleActivator(LogicalKeyboardKey.f3)],
    ),
    ShortcutHelpEntry(
      text: (s) => s.shortcutHold(),
      label: (s, _) => _fn(s, 4),
      keys: const <ShortcutActivator>[SingleActivator(LogicalKeyboardKey.f4)],
    ),
    ShortcutHelpEntry(
      text: (s) => s.shortcutRecall(),
      label: (s, _) => _fn(s, 5),
      keys: const <ShortcutActivator>[SingleActivator(LogicalKeyboardKey.f5)],
    ),
    ShortcutHelpEntry(
      text: (s) => s.shortcutDiscount(),
      label: (s, _) => _fn(s, 6),
      keys: const <ShortcutActivator>[SingleActivator(LogicalKeyboardKey.f6)],
    ),
    ShortcutHelpEntry(
      text: (s) => s.helpRemoveLine(),
      label: (s, _) => s.keyDelete(),
      keys: const <ShortcutActivator>[
        SingleActivator(LogicalKeyboardKey.delete),
      ],
    ),
    ShortcutHelpEntry(
      text: (s) => s.helpCloseDialog(),
      label: (s, _) => s.keyEscape(),
      keys: const <ShortcutActivator>[
        SingleActivator(LogicalKeyboardKey.escape),
      ],
    ),
  ];
}
