import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'page_filter_controller.dart';

/// A page table that shows a list filtered by the shared page filter text
/// (KG-027): the text is debounced (150 ms), each row's lowercase key is
/// computed once per change of the source list, and the match is a plain
/// lowercase `includes`, as the prototype's `filter`.
abstract class FilteredListController<T> extends GetxController {
  FilteredListController({required this.pageFilter});

  static const Duration debounceDuration = Duration(milliseconds: 150);

  final PageFilterController pageFilter;

  /// The rows shown (filtered, in display order).
  final RxList<T> rows = <T>[].obs;

  /// The page's search field text; follows the shared filter (sidebar
  /// navigation clears it).
  final TextEditingController filterText = TextEditingController();

  /// The permanent list the page reads (not copied).
  RxList<T> get source;

  /// The lowercase text a row is matched on.
  String keyOf(T item);

  /// Newest first: the prototype's `.slice().reverse()` after the filter.
  bool get newestFirst => false;

  final List<Worker> _workers = <Worker>[];
  List<(T, String)> _entries = <(T, String)>[];
  String _applied = '';

  @override
  void onInit() {
    super.onInit();
    filterText.text = pageFilter.filter.value;
    _applied = pageFilter.filter.value;
    _reindex();
    _workers
      ..add(ever(source, (_) => _reindex()))
      ..add(
        debounce(pageFilter.filter, (String value) {
          _applied = value;
          _recompute();
        }, time: debounceDuration),
      )
      ..add(
        ever(pageFilter.filter, (String value) {
          if (filterText.text != value) filterText.text = value;
        }),
      );
  }

  void _reindex() {
    _entries = <(T, String)>[for (final item in source) (item, keyOf(item))];
    _recompute();
  }

  void _recompute() {
    final needle = _applied.toLowerCase();
    final found = <T>[
      for (final entry in _entries)
        if (entry.$2.contains(needle)) entry.$1,
    ];
    rows.assignAll(newestFirst ? found.reversed : found);
  }

  /// The search field's `onChange`.
  void onFilterChanged(String value) => pageFilter.set(value);

  /// Applies [value] now, without the debounce (tests, timing).
  void filterNow(String value) {
    pageFilter.set(value);
    _applied = value;
    _recompute();
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    filterText.dispose();
    super.onClose();
  }
}
