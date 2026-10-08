import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_colors.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../controllers/search_field_controller.dart';
import '../controllers/toast_controller.dart';
import 'app_pressable.dart';

/// Toast stack, bottom center, above the Navigator (and so above dialogs).
/// It owns a small [Overlay] because it sits outside the Navigator and its
/// buttons use tooltips.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key});

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => const _ToastStack(),
  );

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Overlay(initialEntries: <OverlayEntry>[_entry]),
    );
  }
}

class _ToastStack extends StatelessWidget {
  const _ToastStack();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ToastController>();
    return Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSizes.toastBottom,
          child: Obx(() {
            final items = controller.toasts.toList();
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.9,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (var i = 0; i < items.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: AppSpacing.s8),
                        _ToastCard(
                          key: ValueKey<int>(items[i].id),
                          item: items[i],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

Color _kindColor(AppColors c, ToastKind kind) => switch (kind) {
  ToastKind.success => c.toastSuccess,
  ToastKind.error => c.toastError,
  ToastKind.warning => c.toastWarning,
  ToastKind.info => c.toastInfo,
};

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.item, super.key});

  final ToastItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final controller = Get.find<ToastController>();
    final textStyle = context.text.of(AppFontSize.s14).copyWith(color: c.text);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: AppMotion.cardMs),
      curve: Curves.ease,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((1 - t) * AppMotion.slideInOffset, 0),
          child: child,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: AppSizes.toastMinWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.r8),
            boxShadow: AppShadows.toast.boxShadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.r8),
            child: ColoredBox(
              color: _kindColor(c, item.kind),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border(
                      top: BorderSide(color: c.border),
                      right: BorderSide(color: c.border),
                      bottom: BorderSide(color: c.border),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s17,
                      vertical: AppSpacing.s13,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          LucideIcons.check,
                          size: 17,
                          color: c.toastSuccessIcon,
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Flexible(child: Text(item.text, style: textStyle)),
                        if (item.onUndo != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.s12),
                          AppPressable(
                            borderRadius: AppRadii.r4,
                            onTap: () {
                              controller.undo(item.id);
                              Get.find<SearchFieldController>().refocus();
                            },
                            builder: (context, hovered) => Text(
                              s.toastUndo(),
                              style: context.text
                                  .of(
                                    AppFontSize.s14,
                                    weight: AppFontWeight.semiBold,
                                  )
                                  .copyWith(color: c.blue),
                            ),
                          ),
                        ],
                        const SizedBox(width: AppSpacing.s12),
                        AppPressable(
                          tooltip: s.toastDismissTooltip(),
                          borderRadius: AppRadii.r4,
                          onTap: () => controller.dismiss(item.id),
                          builder: (context, hovered) =>
                              Icon(LucideIcons.x, size: 14, color: c.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
