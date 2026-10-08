import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../shared/controllers/search_field_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product.dart';
import '../services/product_search.dart';
import 'cart_actions_controller.dart';
import 'scan_controller.dart';

/// The top-bar search: the results dropdown (debounced, at most 6 products)
/// and Enter (adds the first match, else scans the text). Enter and the
/// arrow keys read the typed text at once; only the dropdown is debounced.
class GlobalSearchController extends GetxController {
  GlobalSearchController({
    required this.search,
    required this.products,
    required this.actions,
    required this.scan,
  });

  static const Duration debounceDuration = Duration(milliseconds: 120);

  final SearchFieldController search;
  final ProductsController products;
  final CartActionsController actions;
  final ScanController scan;

  final RxList<Product> matches = <Product>[].obs;

  /// The highlighted row (arrow keys); Enter without arrows takes row 0.
  final RxInt highlight = 0.obs;

  /// The highlight is drawn only after an arrow key moved it (as in the
  /// prototype nothing is shaded; Enter still takes the first row).
  final RxBool arrowed = false.obs;

  final RxString _typed = ''.obs;

  VoidCallback? _listener;
  String _lastText = '';

  @override
  void onInit() {
    super.onInit();
    _listener = () {
      final text = search.text.text;
      // The controller also notifies on selection and focus changes.
      if (text == _lastText) return;
      _lastText = text;
      if (text.isEmpty || ProductSearch.isDigitsOnly(text)) {
        // Nothing to look up: close the dropdown at once.
        if (matches.isNotEmpty) matches.clear();
        highlight.value = 0;
        arrowed.value = false;
      }
      _typed.value = text;
    };
    search.text.addListener(_listener!);
    // Arrow keys and Enter are handled on the field's own focus node, before
    // the (multi-line) text field acts on them.
    search.focusNode.onKeyEvent = _onKey;
    debounce(_typed, (_) => _refresh(), time: debounceDuration);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) onEnter();
      return KeyEventResult.handled;
    }
    if (matches.isNotEmpty) {
      if (key == LogicalKeyboardKey.arrowDown) {
        move(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        move(-1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void onClose() {
    search.focusNode.onKeyEvent = null;
    if (_listener != null) search.text.removeListener(_listener!);
    super.onClose();
  }

  /// Matches for the text right now (what the prototype's `matches` is).
  List<Product> matchesNow() => ProductSearch.matches(
    products.products,
    products.searchKey,
    search.text.text,
  );

  void _refresh() {
    matches.assignAll(matchesNow());
    highlight.value = 0;
    arrowed.value = false;
  }

  /// Applies the dropdown now (tests, timing).
  void refreshNow() => _refresh();

  /// Up (-1) and Down (+1), wrapping.
  void move(int delta) {
    if (matches.isEmpty) return;
    arrowed.value = true;
    highlight.value = (highlight.value + delta) % matches.length;
    if (highlight.value < 0) highlight.value += matches.length;
  }

  /// A click on a row, or Enter on the highlighted one.
  void pick(Product product) => actions.add(product);

  /// Enter: the highlighted match (the first unless an arrow moved), else the
  /// text is scanned as a barcode or code.
  void onEnter() {
    final now = matchesNow();
    if (now.isNotEmpty) {
      final index = highlight.value < now.length ? highlight.value : 0;
      pick(now[index]);
    } else {
      scan.scanProduct(search.text.text);
    }
  }
}
