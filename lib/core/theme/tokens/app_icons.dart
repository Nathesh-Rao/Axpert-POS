import 'package:flutter/widgets.dart';

/// The Lucide icons the app uses, as plain constants (same code points and
/// font as `package:lucide_icons_flutter`).
///
/// Why not `LucideIcons` itself: that class lives in one library of about
/// 130 000 lines. On web in debug (DDC) the library is initialized lazily on
/// first access, and when the first access happens deep inside the widget
/// build stack the initializer overflows the JS stack (StackOverflowError while
/// building Sidebar, DEC-079). The package stays a dependency for its font;
/// `test/core/theme/app_icons_test.dart` keeps these values equal to it and
/// forbids importing `lucide_icons.dart` from `lib/`.
///
/// To add an icon: copy its name and code point from the package and add a
/// line here; the test checks it.
abstract final class AppIcons {
  static const String _family = 'Lucide';
  static const String _package = 'lucide_icons_flutter';

  static const IconData barcode = IconData(
    58675,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData bell = IconData(
    57433,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData chartNoAxesColumnIncreasing = IconData(
    57450,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData check = IconData(
    57452,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData chevronDown = IconData(
    57453,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData ellipsis = IconData(
    57526,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData ellipsisVertical = IconData(
    57527,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData fileText = IconData(
    57548,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData keyboard = IconData(
    57988,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData logOut = IconData(
    57614,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData search = IconData(
    57681,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData settings = IconData(
    57684,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData shoppingBag = IconData(
    57691,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData shoppingCart = IconData(
    57692,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData undo2 = IconData(
    58017,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData userRound = IconData(
    58472,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData users = IconData(
    57764,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData volume2 = IconData(
    57771,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData x = IconData(
    57778,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// All icons by name, for the sync test.
  static const Map<String, IconData> all = <String, IconData>{
    'barcode': barcode,
    'bell': bell,
    'chartNoAxesColumnIncreasing': chartNoAxesColumnIncreasing,
    'check': check,
    'chevronDown': chevronDown,
    'ellipsis': ellipsis,
    'ellipsisVertical': ellipsisVertical,
    'fileText': fileText,
    'keyboard': keyboard,
    'logOut': logOut,
    'search': search,
    'settings': settings,
    'shoppingBag': shoppingBag,
    'shoppingCart': shoppingCart,
    'undo2': undo2,
    'userRound': userRound,
    'users': users,
    'volume2': volume2,
    'x': x,
  };
}
