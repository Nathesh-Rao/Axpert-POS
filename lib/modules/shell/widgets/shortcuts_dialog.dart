import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/shortcuts/shortcut_help.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_modal.dart';

/// "Keyboard shortcuts" (`modal === "shortcuts"`): the nine rows of the
/// prototype with the platform's key labels (Cmd on macOS, Ctrl elsewhere).
class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final platform = defaultTargetPlatform;
    return AppModal(
      title: s.shortcutsTitle(),
      scrollable: true,
      children: <Widget>[
        for (final entry in ShortcutHelp.entries)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppCheckoutSizes.shortcutRowPadY,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      entry.text(s),
                      style: context.text
                          .of(AppFontSize.s14, height: AppLineHeight.base)
                          .copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(width: AppCheckoutSizes.receiptActionsGap),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.secondary,
                      borderRadius: BorderRadius.circular(AppRadii.r4),
                      border: Border.all(
                        color: c.border,
                        width: AppSizes.borderWidth,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppCheckoutSizes.kbdPadX,
                        vertical: AppCheckoutSizes.kbdPadY,
                      ),
                      child: Text(
                        entry.label(s, platform),
                        maxLines: 1,
                        softWrap: false,
                        style: context.text
                            .fluid(AppCheckoutSizes.kbdFont)
                            .copyWith(color: c.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
