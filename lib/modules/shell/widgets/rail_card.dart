import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_rail_sizes.dart';
import '../../../shared/widgets/app_panel.dart';
import '../models/nav_destination.dart';
import 'rail_item.dart';

/// The desktop and web rail: a rounded card with the primary items on top, a
/// thin divider, then the secondary items (More). Icon-only; names live in
/// tooltips and semantics.
class RailCard extends StatelessWidget {
  const RailCard({required this.current, required this.onSelect, super.key});

  final AppPage current;
  final ValueChanged<AppPage> onSelect;

  @override
  Widget build(BuildContext context) {
    final sizes = context.metrics.railSizes;
    final strings = context.strings;
    final items = NavDestination.all;
    final secondary = <NavDestination>[
      for (final d in items)
        if (d.page == AppPage.more) d,
    ];
    final primary = <NavDestination>[
      for (final d in items)
        if (d.page != AppPage.more) d,
    ];

    Widget group(List<NavDestination> list) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < list.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppRailSizes.itemGap),
          RailItem(
            destination: list[i],
            label: list[i].label(strings),
            active: list[i].page == current,
            onTap: () => onSelect(list[i].page),
          ),
        ],
      ],
    );

    return SizedBox(
      width: sizes.width,
      child: AppPanel(
        padding: EdgeInsets.symmetric(
          horizontal: sizes.padX,
          vertical: AppRailSizes.padY,
        ),
        child: Column(
          children: <Widget>[
            Flexible(child: SingleChildScrollView(child: group(primary))),
            const _RailDivider(),
            group(secondary),
          ],
        ),
      ),
    );
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppRailSizes.dividerMargin),
      child: SizedBox(
        height: AppRailSizes.dividerThickness,
        width: double.infinity,
        child: ColoredBox(color: context.rail.divider),
      ),
    );
  }
}
