import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'dialog_registry.dart';
import 'placeholder_dialog.dart';

/// Shows the dialog for [OverlayController.modal] on the ROOT navigator, so
/// the dim layer (scrim + 4 px blur) covers the whole window including the top
/// bar and sidebar. Lives above the Navigator, in `GetMaterialApp.builder`.
class DialogLayer extends StatefulWidget {
  const DialogLayer({super.key});

  @override
  State<DialogLayer> createState() => _DialogLayerState();
}

class _DialogLayerState extends State<DialogLayer> {
  late final Worker _worker;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _worker = ever<String?>(Get.find<OverlayController>().modal, _sync);
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  void _sync(String? id) {
    if (id != null && !_showing) {
      _show(id);
    } else if (id == null && _showing) {
      _showing = false;
      Get.key.currentState?.pop();
    }
  }

  void _show(String id) {
    _showing = true;
    final scrim = context.colors.modalOverlay;
    final overlay = Get.find<OverlayController>();
    final confirmText = overlay.confirmation?.text ?? '';
    Get.generalDialog<void>(
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: scrim,
      transitionDuration: const Duration(milliseconds: AppMotion.cardMs),
      pageBuilder: (context, animation, secondary) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppSizes.modalBlur,
                sigmaY: AppSizes.modalBlur,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // The content follows the dialog id: one modal can swap into
          // another (the picker's Add Customer button), as in the prototype.
          Obx(() {
            final current = overlay.modal.value ?? id;
            return current == OverlayController.confirmId
                ? ConfirmDialog(text: overlay.confirmation?.text ?? confirmText)
                : (DialogRegistry.build(current) ??
                      PlaceholderDialog(id: current));
          }),
        ],
      ),
      transitionBuilder: (context, animation, secondary, child) {
        final t = CurvedAnimation(parent: animation, curve: Curves.ease);
        return FadeTransition(
          opacity: t,
          child: AnimatedBuilder(
            animation: t,
            builder: (context, child) => Transform.translate(
              offset: Offset((1 - t.value) * AppMotion.slideInOffset, 0),
              child: child,
            ),
            child: child,
          ),
        );
      },
    ).then((_) {
      if (_showing) {
        _showing = false;
        Get.find<OverlayController>().close();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
