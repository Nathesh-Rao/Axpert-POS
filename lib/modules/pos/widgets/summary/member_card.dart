import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/responsive/summary_metrics.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../../../shared/controllers/shell_chrome_controller.dart';
import '../../../../shared/widgets/app_input_box.dart';
import '../../../../shared/widgets/app_popover.dart';
import '../../../../shared/widgets/app_pressable.dart';
import '../../controllers/cart_meta_controller.dart';
import '../../controllers/member_controller.dart';
import 'summary_card.dart';

/// The member card: membership number, info, available and redeem points.
/// At height <= 719 it collapses to a one-line header that floats the form.
class MemberCard extends StatelessWidget {
  const MemberCard({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final collapsed = m.heightAtMost719;
    return SummaryCard(
      padding: collapsed ? 0 : m.summary.cardPad,
      child: collapsed ? const _CollapsedMember() : const MembershipForm(),
    );
  }
}

class _CollapsedMember extends StatelessWidget {
  const _CollapsedMember();

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final c = context.colors;
    final s = context.strings;
    final chrome = Get.find<ShellChromeController>();
    final meta = Get.find<CartMetaController>();
    final style = context.text.fluid(MemberCardMetrics.compactFont);
    return Obx(() {
      final open = chrome.menu.value == ShellMenu.member;
      final customer = meta.customer;
      return AppPopover(
        open: open,
        minWidth: MemberCardMetrics.floatingWidth(m.summaryWidth(isPos: true)),
        padding: const EdgeInsets.all(MemberCardMetrics.floatingPad),
        anchor: AppPressable(
          borderRadius: AppRadii.r14,
          onTap: chrome.toggleMemberCard,
          semanticLabel: s.memberCompactTitle(),
          builder: (context, hovered) => ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MemberCardMetrics.compactMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MemberCardMetrics.compactPadX,
                vertical: MemberCardMetrics.compactPadY,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    AppIcons.creditCard,
                    size: AppCheckoutSizes.orderMenuIcon,
                    color: c.fieldIcon,
                  ),
                  const SizedBox(width: MemberCardMetrics.compactGap),
                  Text(
                    s.memberCompactTitle(),
                    style: style.copyWith(color: c.summaryRowText),
                  ),
                  const SizedBox(width: MemberCardMetrics.compactGap),
                  Expanded(
                    child: Text(
                      customer.isWalkIn ? s.memberAdd() : customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: style
                          .copyWith(fontWeight: AppFontWeight.bold.value)
                          .copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(width: MemberCardMetrics.compactGap),
                  Icon(
                    AppIcons.chevronDown,
                    size: AppCheckoutSizes.memberIcon,
                    color: c.fieldIcon,
                  ),
                ],
              ),
            ),
          ),
        ),
        child: SizedBox(
          width:
              MemberCardMetrics.floatingWidth(m.summaryWidth(isPos: true)) -
              2 * MemberCardMetrics.floatingPad,
          child: const MembershipForm(),
        ),
      );
    });
  }
}

/// The two-column form of the member card.
class MembershipForm extends StatelessWidget {
  const MembershipForm({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final sm = m.summary;
    final s = context.strings;
    final c = context.colors;
    final member = Get.find<MemberController>();
    final meta = Get.find<CartMetaController>();
    final overlay = Get.find<OverlayController>();
    final inputHeight = m.heightAtMost719
        ? MemberCardMetrics.floatingInputHeight
        : sm.membershipInputHeight;
    // `.membership > label{line-height:14px}` (12 px when tight).
    final labelLine = sm.density == SummaryDensity.tight
        ? AppCheckoutSizes.memberLabelLineTight
        : AppSizes.controlLabelLineHeight;
    final labelStyle = context.text
        .fluid(sm.membershipFont, height: labelLine / sm.membershipFont)
        .copyWith(color: c.summaryRowText);
    final inputStyle = context.text
        .fluid(sm.membershipFont)
        .copyWith(color: c.text);

    Widget labelled(String label, Widget input) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labelStyle,
        ),
        SizedBox(height: sm.membershipLabelGap),
        input,
      ],
    );
    Widget readOnly(String text) => Container(
      height: inputHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppCheckoutSizes.memberInputPadX,
      ),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(AppRadii.r8),
        border: Border.all(color: c.border, width: AppSizes.borderWidth),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: inputStyle,
      ),
    );

    return Obx(() {
      final customer = meta.customer;
      final walk = customer.isWalkIn;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: labelled(
                  s.memberNumberLabel(),
                  AppInputBox(
                    controller: member.memberText,
                    focusNode: member.memberFocus,
                    style: inputStyle,
                    height: inputHeight,
                    radius: AppRadii.r8,
                    hint: s.memberNumberHint(),
                    semanticLabel: s.memberNumberLabel(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppCheckoutSizes.memberInputPadX,
                    ),
                    onChanged: member.lookup,
                    onSubmitted: (_) => member.submit(),
                    trailing: AppPressable(
                      tooltip: s.memberFindTooltip(),
                      onTap: () => overlay.open('customers'),
                      builder: (context, hovered) => Icon(
                        AppIcons.creditCard,
                        size: AppCheckoutSizes.memberIcon,
                        color: c.fieldIcon,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: sm.membershipGap),
              Expanded(
                child: labelled(
                  s.memberInfoLabel(),
                  readOnly(walk ? '' : customer.name),
                ),
              ),
            ],
          ),
          SizedBox(height: sm.membershipGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: labelled(
                  s.memberPointsAvailable(),
                  readOnly('${customer.points}'),
                ),
              ),
              SizedBox(width: sm.membershipGap),
              Expanded(
                child: labelled(
                  s.memberPointsRedeem(),
                  AppInputBox(
                    controller: member.pointsText,
                    style: inputStyle.copyWith(color: walk ? c.muted : c.text),
                    height: inputHeight,
                    radius: AppRadii.r8,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppCheckoutSizes.memberInputPadX,
                    ),
                    enabled: !walk,
                    digitsOnly: true,
                    semanticLabel: s.memberPointsRedeem(),
                    opacity: walk ? AppCheckoutSizes.memberDisabledOpacity : 1,
                    onChanged: member.setPoints,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
