import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_shadows.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../pos/controllers/global_search_controller.dart';
import '../../products/models/product.dart';

/// Shows the top-bar search results (`.search-results`) under [child]: the
/// field's width, 4 px below it (`top:48` of a 44 px field), over the page.
/// The text field keeps the focus; rows are clicked or picked with the
/// arrow keys and Enter (handled by [GlobalSearchController]).
class SearchResultsPortal extends StatefulWidget {
  const SearchResultsPortal({required this.child, super.key});

  /// Result rows built since the counter was reset (a test counter).
  static int rowBuilds = 0;

  final Widget child;

  @override
  State<SearchResultsPortal> createState() => _SearchResultsPortalState();
}

class _SearchResultsPortalState extends State<SearchResultsPortal> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalSearchController _search = Get.find<GlobalSearchController>();
  Worker? _worker;
  double _width = 0;

  @override
  void initState() {
    super.initState();
    _worker = ever<List<Product>>(_search.matches, (list) {
      if (!mounted) return;
      if (list.isNotEmpty) {
        _width = context.size?.width ?? _width;
        if (!_portal.isShowing) _portal.show();
      } else if (_portal.isShowing) {
        _portal.hide();
      }
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(
            0,
            AppCheckoutSizes.searchResultsTop - context.metrics.searchHeight,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _width,
              child: _Results(search: _search),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.search}) : super(key: resultsKey);

  /// Finds the popover in tests.
  static const Key resultsKey = ValueKey<String>('search-results');

  final GlobalSearchController search;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final m = context.metrics;
    final name = context.text.fluid(m.catalogFont).copyWith(color: c.text);
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        label: s.searchResultsLabel(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppRadii.r9),
            border: Border.all(color: c.border),
            boxShadow: AppShadows.searchResults.boxShadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppCheckoutSizes.searchResultsPad),
            child: Obx(() {
              final list = search.matches;
              final index = search.arrowed.value ? search.highlight.value : -1;
              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  SearchResultsPortal.rowBuilds++;
                  final product = list[i];
                  return AppPressable(
                    key: ValueKey<int>(product.id),
                    borderRadius: AppRadii.r5,
                    semanticLabel: product.name,
                    onTap: () => search.pick(product),
                    builder: (context, hovered) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: hovered || i == index ? c.secondary : null,
                        borderRadius: BorderRadius.circular(AppRadii.r5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppCheckoutSizes.searchResultRowPad,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: name,
                                  ),
                                  Text(
                                    product.code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text
                                        .fluid(
                                          AppCheckoutSizes
                                              .searchResultSmallFont,
                                        )
                                        .copyWith(color: c.muted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              MoneyFormatter.format(product.price),
                              maxLines: 1,
                              softWrap: false,
                              style: name.copyWith(
                                fontWeight: AppFontWeight.bold.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
