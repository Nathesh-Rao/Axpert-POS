import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_management_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';

/// One column of an [AppDataTable]: its header text and width share. React
/// uses the browser's auto table layout; the shares are the column widths
/// measured at the reference viewport (KG-146).
class TableColumnSpec {
  const TableColumnSpec({
    required this.label,
    required this.flex,
    this.alignEnd = false,
    this.minContent = 0,
  });

  final String label;
  final int flex;
  final bool alignEnd;

  /// The narrowest content width (the longest unbreakable word, CSS
  /// `min-content`) the column keeps before the other columns give way; 0
  /// shares the width by [flex] only.
  final double minContent;
}

/// `.data-table` as slivers: the header (secondary fill, muted 12 px) and a
/// lazy list of rows, each row with a bottom border. Cells are widgets; the
/// whole table is a child of a scrolling page, so only the visible rows are
/// built.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rowCount,
    required this.cellsOf,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final List<TableColumnSpec> columns;
  final int rowCount;

  /// The cell widgets of row [index], one per column.
  final List<Widget> Function(BuildContext context, int index) cellsOf;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final head = context.text
        .fluid(
          AppManagementSizes.thFont,
          weight: AppFontWeight.medium,
          height: AppLineHeight.base,
        )
        .copyWith(color: c.muted);
    return SliverPadding(
      padding: padding,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) =>
            _build(context, _widths(constraints.crossAxisExtent), head),
      ),
    );
  }

  /// The column widths: [TableColumnSpec.flex] shares of [available], but no
  /// column below its minimum (`minContent` plus the cell padding); the
  /// columns above their minimum give way in proportion to what they have
  /// above it, as an auto-layout table shrinks to its min-content widths.
  List<double> _widths(double available) {
    final total = columns.fold<double>(0, (sum, c) => sum + c.flex);
    const pad = 2 * AppManagementSizes.cellPadX;
    final mins = <double>[
      for (final c in columns) c.minContent == 0 ? 0 : c.minContent + pad,
    ];
    final widths = <double>[
      for (var i = 0; i < columns.length; i++)
        math.max(mins[i], available * columns[i].flex / total),
    ];
    final excess = widths.fold<double>(0, (a, b) => a + b) - available;
    if (excess > 0) {
      var spare = 0.0;
      for (var i = 0; i < widths.length; i++) {
        spare += widths[i] - mins[i];
      }
      if (spare > 0) {
        final keep = math.max(0, 1 - excess / spare);
        for (var i = 0; i < widths.length; i++) {
          widths[i] = mins[i] + (widths[i] - mins[i]) * keep;
        }
      }
    }
    // Even the minimums do not fit (a very narrow window): every column
    // gives way in proportion; the cells then scale down (KG-149).
    final sum = widths.fold<double>(0, (a, b) => a + b);
    if (sum > available) {
      for (var i = 0; i < widths.length; i++) {
        widths[i] = widths[i] * available / sum;
      }
    }
    return widths;
  }

  Widget _build(BuildContext context, List<double> widths, TextStyle head) {
    final c = context.colors;
    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: ColoredBox(
            color: c.secondary,
            child: Row(
              children: <Widget>[
                for (var i = 0; i < columns.length; i++)
                  SizedBox(
                    width: widths[i],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppManagementSizes.thPadY,
                        horizontal: AppManagementSizes.cellPadX,
                      ),
                      // One line; scales down where the column is too narrow
                      // (KG-149).
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: columns[i].alignEnd
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Text(
                          columns[i].label,
                          maxLines: 1,
                          softWrap: false,
                          style: head,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: rowCount,
          itemBuilder: (context, index) {
            final cells = cellsOf(context, index);
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  for (var i = 0; i < columns.length; i++)
                    SizedBox(
                      width: widths[i],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppManagementSizes.tdPadY,
                          horizontal: AppManagementSizes.cellPadX,
                        ),
                        child: Align(
                          alignment: columns[i].alignEnd
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: cells[i],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A plain table text (14 px, line height 1.5) in the text colour.
class TableText extends StatelessWidget {
  const TableText(
    this.text, {
    this.color,
    this.bold = false,
    this.oneLine = false,
    super.key,
  });

  final String text;
  final Color? color;
  final bool bold;

  /// Numbers, codes and phones stay on one line and scale down in a narrow
  /// column (the browser's table layout keeps them whole, KG-149); names and
  /// emails wrap as in CSS.
  final bool oneLine;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      softWrap: !oneLine,
      maxLines: oneLine ? 1 : null,
      style: context.text
          .fluid(
            AppManagementSizes.tdFont,
            weight: bold ? AppFontWeight.bold : AppFontWeight.regular,
            height: AppLineHeight.base,
          )
          .copyWith(color: color ?? context.colors.text),
    );
    return oneLine
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: label,
          )
        : label;
  }
}

/// `.stock-ok` / `.stock-low`: a coloured chip with the stock number.
class StockChip extends StatelessWidget {
  const StockChip({required this.stock, super.key});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final low = stock < AppManagementSizes.lowStockBelow;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: low ? c.stockLowBg : c.stockOkBg,
        borderRadius: BorderRadius.circular(AppRadii.r5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppManagementSizes.chipPadY,
          horizontal: AppManagementSizes.chipPadX,
        ),
        child: Text(
          context.strings.countBadge(stock),
          style: context.text
              .fluid(AppManagementSizes.tdFont, height: AppLineHeight.base)
              .copyWith(color: low ? c.stockLowFg : c.stockOkFg),
        ),
      ),
    );
  }
}
