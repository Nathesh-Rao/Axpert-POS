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
import '../models/pos_panel_layout.dart';
import 'products_shortcut_label.dart';

/// The slim control on the left edge of the desktop POS work area (DEC-141).
/// Two chevron buttons make the Products panel wider or narrower (hidden,
/// 25%, 75%), three dots show the step, and the body (icon, rotated label and
/// the Ctrl/Cmd+B chip) cycles the steps. With the catalog layout up and items
/// in the cart it reads `Cart (n)` with a count badge, flashes when a tile
/// adds an item, and a click shows the cart. Disabled while the cart is empty.
class ProductsEdgeControl extends StatefulWidget {
  const ProductsEdgeControl({super.key});

  @override
  State<ProductsEdgeControl> createState() => _ProductsEdgeControlState();
}

class _ProductsEdgeControlState extends State<ProductsEdgeControl>
    with SingleTickerProviderStateMixin {
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
      final layout = _work.effective;
      final inCatalog = layout.catalogDominant;
      final canSwitch = _work.canSwitch;
      final count = _work.count;
      final state = s.productsStepLabel(layout.products.percent);
      final label = inCatalog ? s.workTabCart(count) : s.productsTabLabel();
      final semantic = !canSwitch
          ? s.workTabEmptySemantic()
          : inCatalog
          ? s.workTabToCartSemantic(count, shortcut)
          : s.workTabResizeSemantic(state, shortcut);
      final ink = canSwitch || !inCatalog ? c.text : c.muted;
      final wider = _work.canWider;
      final narrower = _work.canNarrower;
      return AnimatedBuilder(
        animation: _flash,
        builder: (context, _) {
          final base = c.card;
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
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Column(
              children: <Widget>[
                _Chevron(
                  icon: AppIcons.chevronRight,
                  semantic: s.workTabWiderSemantic(state),
                  onTap: wider ? _work.wider : null,
                ),
                _Chevron(
                  icon: AppIcons.chevronLeft,
                  semantic: s.workTabNarrowerSemantic(state),
                  onTap: narrower ? _work.narrower : null,
                ),
                const SizedBox(height: AppSpacing.s6),
                _Dots(current: layout.products, enabled: canSwitch),
                const SizedBox(height: AppSpacing.s8),
                Expanded(
                  child: AppPressable(
                    onTap: canSwitch ? _work.edgeTap : null,
                    tooltip: semantic,
                    semanticLabel: semantic,
                    borderRadius: AppRadii.r14,
                    builder: (context, hovered) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: hovered && canSwitch ? c.secondary : null,
                        borderRadius: BorderRadius.circular(AppRadii.r14),
                      ),
                      child: _Body(
                        inCatalog: inCatalog,
                        canSwitch: canSwitch,
                        count: count,
                        label: label,
                        ink: ink,
                        shortcut: shortcut,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.icon,
    required this.semantic,
    required this.onTap,
  });

  final IconData icon;
  final String semantic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      onTap: onTap,
      tooltip: semantic,
      semanticLabel: semantic,
      borderRadius: AppRadii.r8,
      builder: (context, hovered) => Container(
        width: AppDensitySizes.edgeChevronSize,
        height: AppDensitySizes.edgeChevronSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered && onTap != null ? c.secondary : null,
          borderRadius: BorderRadius.circular(AppRadii.r8),
        ),
        child: Icon(
          icon,
          size: AppDensitySizes.productsTabIcon,
          color: onTap == null ? c.border : c.blue,
        ),
      ),
    );
  }
}

/// Three dots for hidden, 25% and 75%; the current step is filled.
class _Dots extends StatelessWidget {
  const _Dots({required this.current, required this.enabled});

  final ProductsStep current;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Column(
        children: <Widget>[
          for (final step in ProductsStep.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
              child: Container(
                width: AppDensitySizes.edgeDot,
                height: AppDensitySizes.edgeDot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step == current ? (enabled ? c.blue : c.muted) : null,
                  border: Border.all(color: enabled ? c.blue : c.border),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.inCatalog,
    required this.canSwitch,
    required this.count,
    required this.label,
    required this.ink,
    required this.shortcut,
  });

  final bool inCatalog;
  final bool canSwitch;
  final int count;
  final String label;
  final Color ink;
  final String shortcut;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
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
                        .of(AppFontSize.s11, height: AppLineHeight.base)
                        .copyWith(color: c.muted),
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
