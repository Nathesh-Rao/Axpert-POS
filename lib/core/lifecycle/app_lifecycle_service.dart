import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../database/database_provider.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  /// [observe] false skips the platform observer (VM tests without a widgets
  /// binding); lifecycle changes can still be fed to
  /// [didChangeAppLifecycleState] directly.
  AppLifecycleService({this.observe = true});

  final bool observe;
  final Rxn<AppLifecycleState> state = Rxn<AppLifecycleState>();

  @override
  void onInit() {
    super.onInit();
    if (observe) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    this.state.value = state;
    if (state == AppLifecycleState.detached &&
        Get.isRegistered<DatabaseProvider>()) {
      unawaited(Get.find<DatabaseProvider>().close());
    }
  }

  @override
  void onClose() {
    if (observe) WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
