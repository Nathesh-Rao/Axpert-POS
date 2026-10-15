import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/pricing/currency_registry.dart';
import '../../../../core/session/permissions.dart';
import '../../../../modules/pos/controllers/cart_controller.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../../../shared/controllers/toast_controller.dart';
import '../../../session/domain/entities/session_entities.dart';
import '../../../session/presentation/controllers/active_session.dart';
import '../../domain/entities/store_config.dart';
import '../../domain/repositories/store_config_repository.dart';
import '../../domain/services/currency_change_guard.dart';
import '../../domain/services/store_config_validator.dart';
import '../../domain/services/tax_presets.dart';
import '../../domain/services/tax_preview.dart';
import 'store_config_drafts.dart';

/// The Store configuration page of the active store: country, currency,
/// exchange rates and tax components. Admin edits, a manager views, a cashier
/// has no access; every command re-checks the role before it does anything.
class StoreConfigController extends GetxController {
  StoreConfigController({
    required this.repository,
    required this.session,
    required this.overlay,
    required this.toasts,
    required this.cart,
  });

  final StoreConfigRepository repository;
  final ActiveSession session;
  final OverlayController overlay;
  final ToastController toasts;
  final CartController cart;

  /// Marks the "Custom" entry of the component picker.
  static const String customEntry = '\u0000custom';

  final TextEditingController name = TextEditingController();
  final TextEditingController state = TextEditingController();

  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final RxString country = ''.obs;
  final RxString currency = ''.obs;

  /// Bumped by every edit so the sample bill and the totals follow the text
  /// fields (the drafts hold plain controllers).
  final RxInt revision = 0.obs;

  final RxList<SlabDraft> slabs = <SlabDraft>[].obs;
  final RxList<ForexDraft> forex = <ForexDraft>[].obs;
  final RxList<ConfigIssue> issues = <ConfigIssue>[].obs;

  /// Index of the slab the sample bill uses; -1 = the default slab.
  final RxInt previewIndex = (-1).obs;

  bool hasSales = false;
  bool inclusive = false;
  Map<int, int> productCounts = const <int, int>{};

  String? get _role => session.user.value?.role;

  bool get canView => StoreConfigPermissions.canView(_role);
  bool get canEdit => StoreConfigPermissions.canEdit(_role);

  String get storeCurrencyBase => currency.value;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    final store = session.store.value;
    if (!canView || store == null) {
      loading.value = false;
      return;
    }
    loading.value = true;
    final config = await repository.load(store.id);
    hasSales = await repository.storeHasSales(store.id);
    productCounts = await repository.productCountsByRate(store.id);
    _fill(config);
    loading.value = false;
  }

  void _fill(StoreConfig config) {
    final oldSlabs = slabs.toList();
    final oldForex = forex.toList();
    _disposeAfterFrame(() {
      for (final s in oldSlabs) {
        s.dispose();
      }
      for (final f in oldForex) {
        f.dispose();
      }
    });
    name.text = config.name;
    state.text = config.stateCode;
    country.value = config.countryCode;
    currency.value = config.currencyCode;
    inclusive = config.inclusive;
    slabs.assignAll([
      for (final s in config.slabs)
        SlabDraft(
          id: s.id,
          name: s.label,
          scheme: s.scheme,
          enabled: s.enabled,
          isDefault: s.isDefault,
          components: [
            for (final c in s.components)
              ComponentDraft(
                label: c.label,
                rateBp: c.rateBp,
                enabled: c.enabled,
                custom: !TaxPresets.all.contains(c.label),
              ),
          ],
        ),
    ]);
    forex.assignAll([
      for (final f in config.forex)
        ForexDraft(
          code: f.code,
          rateMicro: f.rateMicro,
          active: f.active,
          updatedAtMs: f.updatedAtMs,
        ),
    ]);
    issues.clear();
    previewIndex.value = -1;
    revision.value++;
  }

  void touch() => revision.value++;

  /// A removed row may still be on screen for one frame: its text controllers
  /// are disposed after it.
  void _disposeAfterFrame(void Function() dispose) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => dispose());

  // Store and currency.

  List<String> get countryCodes => [
    for (final c in CountryHints.countries) c.code,
  ];

  String countryName(String code) => CountryHints.byCode(code)?.name ?? code;

  List<String> get currencyCodes => [
    for (final c in CurrencyRegistry.all) c.code,
  ];

  void setCountry(String code) {
    if (!_allowed()) return;
    final previous = CountryHints.defaultCurrency(country.value);
    country.value = code;
    final next = CountryHints.defaultCurrency(code);
    // The currency follows the country only while it was the old default.
    if (next != null && currency.value == previous) _setCurrency(next);
    touch();
  }

  void setCurrency(String code) {
    if (!_allowed()) return;
    _setCurrency(code);
    touch();
  }

  void _setCurrency(String code) {
    if (CurrencyChangeGuard.isBlocked(
      currentCode: currency.value,
      newCode: code,
      hasSales: hasSales,
    )) {
      toasts.show(AppStrings.current.scCurrencyLocked(), kind: ToastKind.error);
      return;
    }
    if (code != currency.value && cart.active.value) {
      toasts.show(
        AppStrings.current.scCurrencyCartOpen(),
        kind: ToastKind.error,
      );
      return;
    }
    currency.value = code;
  }

  /// True when the store currency is not the usual one of its country (a
  /// non-blocking hint).
  bool get currencyMismatch {
    final usual = CountryHints.defaultCurrency(country.value);
    return usual != null && usual != currency.value;
  }

  String? get usualCurrency => CountryHints.defaultCurrency(country.value);

  bool get currencyLocked => hasSales;

  // Exchange rates.

  void addForex() {
    if (!_allowed()) return;
    final used = {for (final f in forex) f.code, currency.value};
    final free = currencyCodes.where((c) => !used.contains(c));
    if (free.isEmpty) return;
    forex.add(ForexDraft(code: free.first));
    touch();
  }

  void setForexCode(int index, String code) {
    if (!_allowed()) return;
    forex[index].code = code;
    forex.refresh();
    touch();
  }

  void removeForex(int index) {
    if (!_allowed()) return;
    final removed = forex.removeAt(index);
    _disposeAfterFrame(removed.dispose);
    touch();
  }

  // Tax slabs and components.

  void addSlab({bool interState = false}) {
    if (!_allowed()) return;
    final slab = SlabDraft(
      scheme: interState ? TaxScheme.interState : TaxScheme.standard,
      isDefault: !interState && !slabs.any((s) => s.isDefault),
      components: [ComponentDraft(label: _firstPreset())],
    );
    slabs.add(slab);
    touch();
  }

  String _firstPreset() => CountryHints.presetsFor(country.value).first;

  void removeSlab(int index) {
    if (!_allowed()) return;
    final removed = slabs.removeAt(index);
    _disposeAfterFrame(removed.dispose);
    if (removed.isDefault) {
      final next = slabs.firstWhereOrNull(
        (s) => s.scheme == TaxScheme.standard && s.enabled,
      );
      next?.isDefault = true;
    }
    previewIndex.value = -1;
    slabs.refresh();
    touch();
  }

  void makeDefault(int index) {
    if (!_allowed()) return;
    if (slabs[index].scheme != TaxScheme.standard) return;
    for (final s in slabs) {
      s.isDefault = false;
    }
    slabs[index].isDefault = true;
    slabs.refresh();
    touch();
  }

  void setSlabEnabled(int index, bool value) {
    if (!_allowed()) return;
    slabs[index].enabled = value;
    slabs.refresh();
    touch();
  }

  void addComponent(int slab) {
    if (!_allowed()) return;
    final labels = {
      for (final c in slabs[slab].components) c.label.text.trim().toLowerCase(),
    };
    final next = CountryHints.presetsFor(
      country.value,
    ).firstWhere((p) => !labels.contains(p.toLowerCase()), orElse: () => '');
    slabs[slab].components.add(
      ComponentDraft(label: next, custom: next.isEmpty),
    );
    slabs.refresh();
    touch();
  }

  void removeComponent(int slab, int index) {
    if (!_allowed()) return;
    final removed = slabs[slab].components.removeAt(index);
    _disposeAfterFrame(removed.dispose);
    slabs.refresh();
    touch();
  }

  void setComponentEnabled(int slab, int index, bool value) {
    if (!_allowed()) return;
    slabs[slab].components[index].enabled = value;
    slabs.refresh();
    touch();
  }

  /// The picker entries: presets (the country's first) and "Custom".
  List<String> get pickerEntries => [
    ...CountryHints.presetsFor(country.value),
    customEntry,
  ];

  /// What the picker shows for [component].
  String pickerValue(ComponentDraft component) =>
      component.custom ? customEntry : component.label.text;

  /// The admin picked [entry] for a component. An Indian tax name outside
  /// India asks first (non-blocking: Continue applies it).
  void pickComponent(int slab, int index, String entry) {
    if (!_allowed()) return;
    final component = slabs[slab].components[index];
    void apply() {
      if (entry == customEntry) {
        component.custom = true;
        component.label.text = '';
      } else {
        component.custom = false;
        component.label.text = entry;
      }
      slabs.refresh();
      touch();
    }

    if (entry != customEntry &&
        CountryHints.warnsIndianLabel(country.value, entry)) {
      overlay.openConfirm(AppStrings.current.scConfirmIndian(entry), apply);
      return;
    }
    apply();
  }

  /// Components of a slab share this many percent points (live total).
  String totalPercent(SlabDraft slab) {
    final total = slab.toSlab().rateBp;
    return _percentText(total);
  }

  static String _percentText(int bp) {
    final whole = bp ~/ 100;
    final frac = bp % 100;
    if (frac == 0) return '$whole';
    final f = frac.toString().padLeft(2, '0').replaceFirst(RegExp(r'0+$'), '');
    return '$whole.$f';
  }

  /// Products of this store taxed at the total of [slab].
  int productsAt(SlabDraft slab) => productCounts[slab.toSlab().rateBp] ?? 0;

  // Sample bill.

  SlabDraft? get previewSlab {
    final list = slabs.toList();
    if (previewIndex.value >= 0 && previewIndex.value < list.length) {
      return list[previewIndex.value];
    }
    return list.firstWhereOrNull((s) => s.isDefault && s.enabled) ??
        list.firstWhereOrNull((s) => s.enabled);
  }

  /// Tax heading of the sample bill: the label of the single enabled
  /// component, else empty (read "Tax Amount"), like the Bill Summary.
  String get previewHeading {
    final slab = previewSlab;
    if (slab == null) return '';
    final on = [
      for (final c in slab.components)
        if (c.enabled) c.label.text.trim(),
    ];
    return on.length == 1 ? on.single : '';
  }

  void setPreview(int index) {
    previewIndex.value = index;
    touch();
  }

  TaxPreview? get preview {
    final slab = previewSlab;
    if (slab == null) return null;
    final c = CurrencyRegistry.byCode(currency.value);
    var unit = 1;
    for (var i = 0; i < c.exponent; i++) {
      unit *= 10;
    }
    final valid = slab.components.every((x) {
      final bp = x.toComponent().rateBp;
      return bp >= 0 && bp <= StoreConfigValidator.maxRateBp;
    });
    if (!valid) return null;
    return TaxPreview.of(
      slab: slab.toSlab(),
      currency: c,
      priceMinor: 1000 * unit,
      inclusive: inclusive,
    );
  }

  // Save and cancel.

  StoreConfig draft() => StoreConfig(
    storeId: session.store.value?.id ?? '',
    name: name.text,
    countryCode: country.value,
    stateCode: state.text.trim(),
    currencyCode: currency.value,
    inclusive: inclusive,
    forex: [for (final f in forex) f.toRow()],
    slabs: [for (final s in slabs) s.toSlab()],
  );

  /// Enter: validates, then asks for the confirmation (new sales only).
  void requestSave() {
    if (!_allowed() || saving.value || loading.value) return;
    final found = StoreConfigValidator.validate(draft());
    issues.assignAll(found);
    if (found.isNotEmpty) {
      toasts.show(AppStrings.current.scFixIssues(), kind: ToastKind.error);
      return;
    }
    overlay.openConfirm(AppStrings.current.scConfirmSave(), _save);
  }

  Future<void> _save() async {
    if (!_allowed()) return;
    final config = draft();
    final store = session.store.value;
    if (store == null) return;
    saving.value = true;
    try {
      await repository.save(config);
      await session.applyConfiguration(
        store.copyWith(
          name: config.name.trim(),
          currencyCode: config.currencyCode,
          region: config.countryCode,
          stateCode: config.stateCode,
        ),
      );
      toasts.show(AppStrings.current.scSaved());
      await load();
    } on Object {
      toasts.show(AppStrings.current.scSaveFailed(), kind: ToastKind.error);
    } finally {
      saving.value = false;
    }
  }

  /// Esc: leaves the page without saving.
  void cancel() => Get.offAllNamed<void>(AppRoutes.more);

  /// The role gate every command passes first.
  bool _allowed() {
    if (canEdit) return true;
    toasts.show(AppStrings.current.scNoPermission(), kind: ToastKind.error);
    return false;
  }

  /// Text of a validation problem.
  String issueText(ConfigIssue issue) {
    final s = AppStrings.current;
    return switch (issue.kind) {
      ConfigIssueKind.nameRequired => s.scIssueName(),
      ConfigIssueKind.slabNameRequired => s.scIssueSlabName(),
      ConfigIssueKind.slabNeedsComponent => s.scIssueNeedsComponent(
        issue.subject,
      ),
      ConfigIssueKind.labelRequired => s.scIssueLabel(issue.subject),
      ConfigIssueKind.duplicateLabel => s.scIssueDuplicateLabel(issue.subject),
      ConfigIssueKind.rateOutOfRange => s.scIssueRate(issue.subject),
      ConfigIssueKind.slabTotalTooHigh => s.scIssueTotalHigh(issue.subject),
      ConfigIssueKind.duplicateTotal => s.scIssueDuplicateTotal(issue.subject),
      ConfigIssueKind.noDefaultSlab => s.scIssueNoDefault(),
      ConfigIssueKind.forexRateInvalid => s.scIssueForexRate(issue.subject),
      ConfigIssueKind.forexDuplicate => s.scIssueForexDuplicate(issue.subject),
    };
  }

  @override
  void onClose() {
    name.dispose();
    state.dispose();
    for (final s in slabs) {
      s.dispose();
    }
    for (final f in forex) {
      f.dispose();
    }
    super.onClose();
  }
}
