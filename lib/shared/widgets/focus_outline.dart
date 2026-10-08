import 'package:flutter/widgets.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_sizes.dart';

/// Draws the prototype's input focus outline (2 px, offset 2) around [child]
/// while [focusNode] has focus. The ring is painted outside the child's box.
class FocusOutline extends StatelessWidget {
  const FocusOutline({
    required this.focusNode,
    required this.child,
    this.borderRadius = 0,
    super.key,
  });

  final FocusNode focusNode;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            child,
            if (focusNode.hasFocus)
              Positioned(
                left: -AppSizes.focusRingOffset,
                top: -AppSizes.focusRingOffset,
                right: -AppSizes.focusRingOffset,
                bottom: -AppSizes.focusRingOffset,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        borderRadius + AppSizes.focusRingOffset,
                      ),
                      border: Border.all(
                        color: context.colors.focusRing,
                        width: AppSizes.focusRingWidth,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
