import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/modules/shell/widgets/rail_item.dart';
import 'package:pos_application/modules/shell/widgets/sidebar.dart';

/// The rail item named [label]: a `RailItem` (desktop and web) or the touch
/// strip's tooltip-carrying button. Always inside the `Sidebar`.
Finder sidebarItem(String label) => find.descendant(
  of: find.byType(Sidebar),
  matching: find.byWidgetPredicate(
    (w) =>
        (w is RailItem && w.label == label) ||
        (w is Tooltip && w.message == label),
  ),
);
