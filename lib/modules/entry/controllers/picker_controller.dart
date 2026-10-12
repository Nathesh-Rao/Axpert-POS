import 'package:get/get.dart';

import '../../../features/session/domain/entities/session_entities.dart';
import '../../../features/session/presentation/controllers/active_session.dart';

/// Store and counter choice after sign-in, from the user's access rows.
class PickerController extends GetxController {
  PickerController({required this.session, required this.onDone});

  final ActiveSession session;
  final void Function(bool reducedMotion) onDone;

  final Rxn<StoreAccess> store = Rxn<StoreAccess>();
  final Rxn<CounterInfo> counter = Rxn<CounterInfo>();
  final RxBool loading = false.obs;

  /// Set by the view from `MediaQuery.disableAnimations`.
  bool reducedMotion = false;

  List<StoreAccess> get stores => session.access;

  @override
  void onInit() {
    super.onInit();
    if (stores.isNotEmpty) selectStore(stores.first.store.name);
  }

  void selectStore(String name) {
    final entry = stores.firstWhereOrNull((a) => a.store.name == name);
    if (entry == null) return;
    store.value = entry;
    counter.value = entry.counters.isEmpty ? null : entry.counters.first;
  }

  void selectCounter(String name) {
    counter.value = store.value?.counters.firstWhereOrNull(
      (c) => c.name == name,
    );
  }

  Future<void> submit() async {
    final entry = store.value;
    if (loading.value || entry == null) return;
    loading.value = true;
    await session.begin(entry.store, counter.value);
    if (isClosed) return;
    onDone(reducedMotion);
  }
}
