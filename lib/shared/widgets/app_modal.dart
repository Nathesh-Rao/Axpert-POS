import 'package:flutter/material.dart';

import '../../core/responsive/app_metrics_scope.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';

/// `.modal`: 460 wide card, 16 px radius, modal shadow, 25 px bold title.
class AppModal extends StatelessWidget {
  const AppModal({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    return Padding(
      padding: EdgeInsets.all(m.modalOverlayPad),
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.modalWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(AppRadii.r16),
                boxShadow: AppShadows.modal.boxShadows,
              ),
              child: Padding(
                padding: EdgeInsets.all(m.modalPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpacing.s20,
                        bottom: AppSpacing.s12,
                      ),
                      child: Text(
                        title,
                        style: context.text
                            .of(AppFontSize.s25, weight: AppFontWeight.bold)
                            .copyWith(color: c.text),
                      ),
                    ),
                    ...children,
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
