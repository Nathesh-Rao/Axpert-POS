@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pos_application/core/theme/tokens/app_icons.dart';

void main() {
  // The package class is only used here, to prove AppIcons matches it.
  final package = <String, IconData>{
    'barcode': LucideIcons.barcode,
    'bell': LucideIcons.bell,
    'chartNoAxesColumnIncreasing': LucideIcons.chartNoAxesColumnIncreasing,
    'check': LucideIcons.check,
    'chevronDown': LucideIcons.chevronDown,
    'ellipsis': LucideIcons.ellipsis,
    'ellipsisVertical': LucideIcons.ellipsisVertical,
    'fileText': LucideIcons.fileText,
    'keyboard': LucideIcons.keyboard,
    'logOut': LucideIcons.logOut,
    'search': LucideIcons.search,
    'settings': LucideIcons.settings,
    'shoppingBag': LucideIcons.shoppingBag,
    'shoppingCart': LucideIcons.shoppingCart,
    'undo2': LucideIcons.undo2,
    'userRound': LucideIcons.userRound,
    'users': LucideIcons.users,
    'volume2': LucideIcons.volume2,
    'x': LucideIcons.x,
    'star': LucideIcons.star,
    'cupSoda': LucideIcons.cupSoda,
    'cookie': LucideIcons.cookie,
    'bottleWine': LucideIcons.bottleWine,
    'chevronRight': LucideIcons.chevronRight,
    'layoutGrid': LucideIcons.layoutGrid,
    'list': LucideIcons.list,
    'plus': LucideIcons.plus,
    'minus': LucideIcons.minus,
    'trash2': LucideIcons.trash2,
    'pauseCircle': LucideIcons.pauseCircle,
    'rotateCcw': LucideIcons.rotateCcw,
    'package': LucideIcons.package,
    'indianRupee': LucideIcons.indianRupee,
  };

  test('AppIcons equals the lucide_icons_flutter constants', () {
    expect(AppIcons.all.keys.toSet(), package.keys.toSet());
    package.forEach((name, icon) {
      final mine = AppIcons.all[name]!;
      expect(mine.codePoint, icon.codePoint, reason: name);
      expect(mine.fontFamily, icon.fontFamily, reason: name);
      expect(mine.fontPackage, icon.fontPackage, reason: name);
    });
  });

  test('lib/ never imports the huge LucideIcons library (DEC-079)', () {
    // On web (DDC) its lazy initializer overflows the JS stack when first
    // touched deep inside the widget build stack.
    final offenders = <String>[
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.readAsStringSync().contains('lucide_icons_flutter/lucide_icons'))
          f.path,
    ];
    expect(offenders, isEmpty, reason: 'use AppIcons instead: $offenders');
  });
}
