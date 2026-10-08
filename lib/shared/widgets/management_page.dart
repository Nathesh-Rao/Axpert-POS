import 'package:flutter/material.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/responsive/app_metrics_scope.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_management_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_panel.dart';
import 'search_text_field.dart';

/// `.management`: the white panel of a secondary page. The whole page scrolls
/// (`overflow:auto`) inside the panel padding; [slivers] go after the heading
/// and the optional search field.
class ManagementPage extends StatelessWidget {
  const ManagementPage({
    required this.title,
    required this.slivers,
    this.action,
    this.search,
    super.key,
  });

  final String title;

  /// The heading's right side (`Add Customer`).
  final Widget? action;

  /// The `.field.search-field` under the heading.
  final Widget? search;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = context.metrics.managementPad;
    return SizedBox.expand(
      child: AppPanel(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppManagementSizes.headingMarginBottom,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom:
                                        AppManagementSizes.eyebrowMarginBottom,
                                  ),
                                  child: Text(
                                    context.strings.workspaceEyebrow(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text
                                        .of(
                                          AppFontSize.s10,
                                          height: AppLineHeight.base,
                                          letterSpacing:
                                              AppTracking.managementEyebrow,
                                        )
                                        .copyWith(color: c.muted),
                                  ),
                                ),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text
                                      .of(
                                        AppFontSize.s30,
                                        weight: AppFontWeight.bold,
                                        height: AppLineHeight.base,
                                      )
                                      .copyWith(color: c.text),
                                ),
                              ],
                            ),
                          ),
                          ?action,
                        ],
                      ),
                    ),
                    if (search != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppManagementSizes.searchMarginBottom,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppManagementSizes.searchMaxWidth,
                            ),
                            child: search,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ...slivers,
            SliverToBoxAdapter(child: SizedBox(height: pad)),
          ],
        ),
      ),
    );
  }
}

/// The management pages' search box: `SearchTextField` without the clear
/// button, bound to a [TextEditingController] and a change callback.
class ManagementSearch extends StatelessWidget {
  const ManagementSearch({
    required this.controller,
    required this.hint,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchTextField(
      controller: controller,
      hint: hint,
      clearTooltip: context.strings.clearSearchTooltip(),
      onChanged: onChanged,
      onClear: () {},
      showClear: false,
    );
  }
}
