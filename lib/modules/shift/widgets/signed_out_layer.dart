import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_shadows.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/modal_primary_button.dart';
import '../../../shared/widgets/request_focus_on_show.dart';
import '../controllers/shift_controller.dart';

/// `.signed-out`: while the counter is closed the whole window is the
/// "Counter closed" card on the background colour. The app underneath stays
/// alive (cart, held bills, filters) but takes no focus; its shortcut handlers
/// keep running as in the prototype (KG-160).
class SignedOutLayer extends StatelessWidget {
  const SignedOutLayer({required this.child, super.key});

  /// The app (navigator).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shift = Get.find<ShiftController>();
    return Obx(() {
      final out = shift.signedOut.value;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExcludeFocus(
            excluding: out,
            child: ExcludeSemantics(excluding: out, child: child),
          ),
          if (out) _SignedOutCard(onStart: shift.startNewShift),
        ],
      );
    });
  }
}

class _SignedOutCard extends StatefulWidget {
  const _SignedOutCard({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_SignedOutCard> createState() => _SignedOutCardState();
}

class _SignedOutCardState extends State<_SignedOutCard> {
  final FocusNode _start = FocusNode(debugLabel: 'start-shift');

  @override
  void dispose() {
    _start.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return ColoredBox(
      color: c.background,
      child: Center(
        child: SingleChildScrollView(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AppRadii.r16),
              boxShadow: AppShadows.signCard.boxShadows,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppManagementSizes.signCardPad),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(
                        bottom: AppManagementSizes.signMarkMarginBottom,
                      ),
                      child: BrandMark(
                        width: AppManagementSizes.signMarkWidth,
                        fontSize: AppManagementSizes.signMarkFont,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppManagementSizes.signTitleMarginBottom,
                      ),
                      child: Text(
                        s.signedOutTitle(),
                        textAlign: TextAlign.center,
                        style: context.text
                            .fluid(
                              AppManagementSizes.signTitleFont,
                              weight: AppFontWeight.bold,
                              height: AppLineHeight.base,
                            )
                            .copyWith(color: c.text),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppManagementSizes.signBodyMarginBottom,
                      ),
                      child: Text(
                        s.signedOutBody(),
                        textAlign: TextAlign.center,
                        style: context.text
                            .of(AppFontSize.s14, height: AppLineHeight.base)
                            .copyWith(color: c.muted),
                      ),
                    ),
                    IntrinsicWidth(
                      child: RequestFocusOnShow(
                        focusNode: _start,
                        child: ModalPrimaryButton(
                          label: s.signedOutStart(),
                          focusNode: _start,
                          onTap: widget.onStart,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
