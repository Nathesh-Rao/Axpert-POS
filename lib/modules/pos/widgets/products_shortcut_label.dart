import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/constants/app_strings_x.dart';

/// `⌘B` on macOS, `Ctrl+B` elsewhere (the Products panel shortcut).
String productsShortcutLabel(BuildContext context) {
  final s = context.strings;
  return defaultTargetPlatform == TargetPlatform.macOS
      ? s.productsShortcutMac()
      : s.productsShortcutOther();
}

/// `⌘.` on macOS, `Ctrl+.` elsewhere (the Billing shortcut).
String billingShortcutLabel(BuildContext context) {
  final s = context.strings;
  return defaultTargetPlatform == TargetPlatform.macOS
      ? s.billingShortcutMac()
      : s.billingShortcutOther();
}
