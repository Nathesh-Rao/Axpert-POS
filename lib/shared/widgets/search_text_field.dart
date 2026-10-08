import 'package:flutter/material.dart';

import '../../core/responsive/app_metrics_scope.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_icons.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
import 'app_pressable.dart';
import 'css_gradient.dart';
import 'focus_outline.dart';

/// `.field.search-field`: gradient box (120deg secondary to card), search icon,
/// input with the focus outline and a clear button while there is text.
class SearchTextField extends StatefulWidget {
  const SearchTextField({
    required this.controller,
    required this.hint,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
    this.showClear = true,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  /// The catalog field has a clear button; the management pages' field does
  /// not (`.field.search-field` with a bare input).
  final bool showClear;

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  final FocusNode _focus = FocusNode(debugLabel: 'catalog-search');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final style = context.text
        .fluid(m.catalogFont)
        .copyWith(color: c.searchFieldFg);
    return SizedBox(
      height: m.fieldHeight,
      child: CssGradientBox(
        angleDeg: 120,
        colors: <Color>[c.secondary, c.card],
        borderRadius: BorderRadius.circular(AppRadii.r7),
        border: Border.all(color: c.border),
        // CssGradientBox draws the border over its box: add the 1 px the CSS
        // border takes from the content box.
        padding: EdgeInsets.symmetric(
          horizontal: m.fieldPadX + AppSizes.borderWidth,
          vertical: AppSizes.borderWidth,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              AppIcons.search,
              size: AppSizes.fieldSearchIcon,
              color: c.fieldIcon,
            ),
            SizedBox(width: m.fieldGap),
            Expanded(
              child: FocusOutline(
                focusNode: _focus,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  style: style,
                  // The input fills the field (`input{height:100%}`), so the
                  // focus ring has the height React draws.
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: c.searchFieldFg,
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintMaxLines: 1,
                    hintText: widget.hint,
                    hintStyle: style.copyWith(color: c.placeholder),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                if (!widget.showClear || widget.controller.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return AppPressable(
                  tooltip: widget.clearTooltip,
                  onTap: widget.onClear,
                  builder: (context, hovered) => Icon(
                    AppIcons.x,
                    size: AppSizes.fieldClearIcon,
                    color: c.fieldIcon,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
