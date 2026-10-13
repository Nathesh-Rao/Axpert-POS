import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_shadows.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/pos_work_view_controller.dart';
import 'products_shortcut_label.dart';

/// The slim tab on the left edge of the desktop POS work area. In the catalog
/// it reads `Cart (n)` with a count badge and flashes when a tile adds an
/// item; in the cart it reads `Products`. Click (or Ctrl/Cmd+B) switches the
/// view; it is disabled while the cart is empty.
class WorkTab extends StatefulWidget {
  const WorkTab({super.key});

  @override
  State<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends State<WorkTab> with SingleTickerProviderStateMixin {
  late final PosWorkViewController _work = Get.find<PosWorkViewController>();
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppMotion.highlightMs),
  );
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever<int>(_work.pulse, (_) => _flash.forward(from: 0));
  }

  @override
  void dispose() {
    _worker?.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final shortcut = productsShortcutLabel(context);
    return Obx(() {
      final inCatalog = _work.inCatalog;
      final canSwitch = _work.canSwitch;
      final count = _work.count;
      final label = inCatalog ? s.workTabCart(count) : s.productsTabLabel();
      final semantic = !canSwitch
          ? s.workTabEmptySemantic()
          : inCatalog
          ? s.workTabToCartSemantic(count, shortcut)
          : s.workTabToProductsSemantic(shortcut);
      final ink = canSwitch || !inCatalog ? c.text : c.muted;
      return AppPressable(
        onTap: canSwitch ? _work.toggle : null,
        tooltip: semantic,
        semanticLabel: semantic,
        borderRadius: AppRadii.r14,
        builder: (context, hovered) => AnimatedBuilder(
          animation: _flash,
          builder: (context, _) {
            final base = hovered && canSwitch ? c.secondary : c.card;
            final t = _flash.isAnimating
                ? ((_flash.value - 0.35) / 0.65).clamp(0.0, 1.0)
                : 1.0;
            final bg = _flash.isAnimating
                ? Color.lerp(c.highlightBg, base, t)!
                : base;
            return Container(
              width: AppDensitySizes.productsTabWidth,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadii.r14),
                boxShadow: AppShadows.panel.boxShadows,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Column(
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Icon(
                        inCatalog ? AppIcons.shoppingCart : AppIcons.layoutGrid,
                        size: AppDensitySizes.productsTabIcon,
                        color: canSwitch || !inCatalog ? c.blue : c.muted,
                      ),
                      if (inCatalog && count > 0)
                        Positioned(
                          right: -AppSpacing.s8,
                          top: -AppSpacing.s8,
                          child: _Badge(count: count),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            style: context.text
                                .of(
                                  AppFontSize.s13,
                                  weight: AppFontWeight.semiBold,
                                  height: AppLineHeight.base,
                                )
                                .copyWith(color: ink),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(AppRadii.r6),
                            ),
                            child: Text(
                              shortcut,
                              maxLines: 1,
                              softWrap: false,
                              style: context.text
                                  .of(
                                    AppFontSize.s11,
                                    height: AppLineHeight.base,
                                  )
                                  .copyWith(color: c.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: AppSpacing.s16),
      height: AppSpacing.s16,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.blue,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        context.strings.workTabBadge(count),
        maxLines: 1,
        softWrap: false,
        style: context.text
            .of(AppFontSize.s10, weight: AppFontWeight.bold, height: 1)
            .copyWith(color: c.white),
      ),
    );
  }
}
