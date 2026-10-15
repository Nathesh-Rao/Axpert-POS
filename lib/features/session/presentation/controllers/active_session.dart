import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../core/services/pricing/basis_points.dart';
import '../../../../core/services/pricing/currency.dart';
import '../../../../core/services/pricing/currency_registry.dart';
import '../../../../core/services/pricing/pricing_service.dart';
import '../../../../core/services/pricing/tax_config.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../../core/session/store_scope.dart';
import '../../domain/entities/session_entities.dart';
import '../../domain/repositories/session_repositories.dart';

enum SignInFailure { invalid, noAccess }

class SignInResult {
  const SignInResult.ok(this.access) : failure = null;
  const SignInResult.failed(this.failure) : access = const <StoreAccess>[];

  final SignInFailure? failure;
  final List<StoreAccess> access;

  bool get ok => failure == null;
}

/// The signed-in user, store and counter (permanent). The store's currency row
/// drives money formatting and pricing for the whole session (DEC-132).
class ActiveSession extends GetxController {
  ActiveSession({
    required UserRepository users,
    required StoreRepository stores,
    required StoreScope scope,
    PasswordHasher hasher = const PasswordHasher(),
  }) : _users = users,
       _stores = stores,
       _scope = scope,
       _hasher = hasher;

  /// A session that is already open, for tests and previews. The scope stays
  /// empty (unscoped, legacy mode), so no row is filtered or stamped.
  ActiveSession.fixed({
    required AppUser user,
    required StoreInfo store,
    required CounterInfo counter,
    required List<StoreAccess> access,
    required Map<String, List<int>> quickCash,
    TaxRegimeInfo? regime,
    List<ForexRate> forex = const <ForexRate>[],
    UserRepository? users,
    StoreRepository? stores,
  }) : _users = users ?? _noUsers,
       _stores = stores ?? _noStores,
       _scope = StoreScope(),
       _hasher = const PasswordHasher() {
    this.user.value = user;
    this.store.value = store;
    this.counter.value = counter;
    this.access.assignAll(access);
    _quickCash.addAll(quickCash);
    this.regime.value = regime;
    this.forex.assignAll(forex);
  }

  static final UserRepository _noUsers = _EmptyUsers();
  static final StoreRepository _noStores = _EmptyStores();

  final UserRepository _users;
  final StoreRepository _stores;
  final StoreScope _scope;
  final PasswordHasher _hasher;

  final Rxn<AppUser> user = Rxn<AppUser>();
  final Rxn<StoreInfo> store = Rxn<StoreInfo>();
  final Rxn<CounterInfo> counter = Rxn<CounterInfo>();

  /// The tax regime of the active store's region; null = no regime (zero
  /// tax, no label).
  final Rxn<TaxRegimeInfo> regime = Rxn<TaxRegimeInfo>();

  /// Active foreign currencies of the active store (empty hides the forex
  /// panel).
  final RxList<ForexRate> forex = <ForexRate>[].obs;

  /// Stores (with counters) the signed-in user may open.
  final RxList<StoreAccess> access = <StoreAccess>[].obs;

  final Map<String, List<int>> _quickCash = <String, List<int>>{};

  /// Reloads everything scoped to the store (set by the binding). Runs after
  /// the scope changed and before the session is announced.
  Future<void> Function(StoreInfo store)? onActivate;

  /// Runs first on sign-out, while the user and store are still set (set by
  /// the binding).
  Future<void> Function()? beforeSignOut;

  /// Runs last on sign-out: reset controllers, go to the login screen (set by
  /// the binding).
  void Function()? onSignedOut;

  bool get isSignedIn => user.value != null;

  String get displayName => user.value?.displayName ?? '';

  /// First letter of the display name (the avatar).
  String get initial =>
      displayName.isEmpty ? '' : displayName.substring(0, 1).toUpperCase();

  /// True once a database store is open (rows are scoped and stamped).
  bool get scoped => _scope.scoped;

  /// True when the database has stores (scoped mode).
  Future<bool> hasStores() => _stores.hasStores();

  /// True when at least one user exists (otherwise the login shows an empty
  /// state).
  Future<bool> hasUsers() => _users.hasUsers();

  /// Reads the `currencies` rows into the registry (call before any data that
  /// carries a currency code is read).
  Future<void> loadCurrencies() async {
    final rows = await _stores.loadCurrencies();
    CurrencyRegistry.register([for (final r in rows) r.currency]);
    _quickCash.addAll({for (final r in rows) r.currency.code: r.quickCash});
  }

  /// The active store's currency, or null before a store is chosen.
  Currency? get currency {
    final s = store.value;
    return s == null ? null : CurrencyRegistry.byCode(s.currencyCode);
  }

  /// Tax name of the active store's regime (`GST`, `VAT`); empty without one.
  String get taxLabel => regime.value?.taxName ?? '';

  /// Caption of a product's tax (`GST 18%`, or the slab name of a store slab);
  /// empty when the store has no tax name.
  String taxCaption(Bp rate) {
    final r = regime.value;
    if (r == null) return '';
    final slab = r.slabFor(rate.value);
    if (slab != null && slab.components.isNotEmpty && slab.label.isNotEmpty) {
      return slab.label;
    }
    final name = r.taxName;
    return name.isEmpty
        ? ''
        : AppStrings.current.taxRateLabel(
            name,
            DecimalText.scaled(rate.value, 2),
          );
  }

  /// Components the total tax is split into (`CGST`, `SGST`); empty = one line.
  List<String> get taxSplitParts =>
      regime.value?.splitParts ?? const <String>[];

  /// Currency and tax of the active store, from its currency and regime rows.
  TaxConfig get taxConfig {
    final r = regime.value;
    final base = r == null
        ? TaxConfig.none
        : TaxConfig(
            country: r.region,
            currency: TaxConfig.none.currency,
            // Never shown: only "has a regime" (the heading uses taxName).
            label: r.taxName.isEmpty ? 'tax' : r.taxName,
            mode: r.inclusive ? TaxMode.inclusive : TaxMode.exclusive,
            slabsBp: <Bp>[
              for (final s in r.slabs)
                if (s.enabled && s.scheme == TaxScheme.standard) Bp(s.rateBp),
            ],
            splitParts: r.splitParts,
          );
    final c = currency;
    return c == null ? base : base.copyWith(currency: c);
  }

  PricingService get pricing => PricingService(config: taxConfig);

  /// Quick cash buttons of the active currency, whole units.
  List<int> get quickCash {
    final s = store.value;
    return s == null
        ? const <int>[]
        : _quickCash[s.currencyCode] ?? const <int>[];
  }

  Future<SignInResult> signIn(String username, String password) async {
    final credential = await _users.findByUsername(username.trim());
    if (credential == null ||
        !_hasher.verify(
          salt: credential.salt,
          password: password,
          expected: credential.passwordHash,
        )) {
      return const SignInResult.failed(SignInFailure.invalid);
    }
    final granted = await _users.accessFor(credential.user.id);
    if (granted.isEmpty) {
      return const SignInResult.failed(SignInFailure.noAccess);
    }
    user.value = credential.user;
    access.assignAll(granted);
    return SignInResult.ok(granted);
  }

  /// `SKIP_ENTRY`: opens the first active user's first store and counter.
  /// Returns false on an empty database (the app then shows empty states).
  Future<bool> autoSignIn({String? username}) async {
    final credential = username == null
        ? await _users.firstActive()
        : await _users.findByUsername(username);
    if (credential == null) return false;
    final granted = await _users.accessFor(credential.user.id);
    if (granted.isEmpty) return false;
    user.value = credential.user;
    access.assignAll(granted);
    final first = granted.first;
    await begin(
      first.store,
      first.counters.isEmpty ? null : first.counters.first,
    );
    return true;
  }

  /// The picker is skipped when there is exactly one store and one counter.
  (StoreInfo, CounterInfo?)? get onlyChoice {
    if (access.length != 1) return null;
    final only = access.single;
    if (only.counters.length > 1) return null;
    return (only.store, only.counters.isEmpty ? null : only.counters.single);
  }

  /// Opens [store] and [counter]: sets the scope, reloads the scoped data.
  Future<void> begin(StoreInfo store, CounterInfo? counter) async {
    _scope.set(
      storeId: store.id,
      counterId: counter?.id,
      userId: user.value?.id,
      userName: user.value?.displayName,
      currency: CurrencyRegistry.byCode(store.currencyCode),
    );
    this.store.value = store;
    this.counter.value = counter;
    // Tax regime and forex rows follow the store before its data loads.
    regime.value = await _stores.loadTaxRegime(store.region, storeId: store.id);
    forex.assignAll(await _stores.loadForex(store.id));
    await onActivate?.call(store);
  }

  /// Takes the saved store configuration (name, country, currency, state) and
  /// reloads the tax setup and forex of the open store. Applies to new sales;
  /// nothing already sold is touched.
  Future<void> applyConfiguration(StoreInfo next) async {
    final current = store.value;
    if (current == null || current.id != next.id) return;
    _scope.currency = CurrencyRegistry.byCode(next.currencyCode);
    store.value = next;
    regime.value = await _stores.loadTaxRegime(next.region, storeId: next.id);
    forex.assignAll(await _stores.loadForex(next.id));
  }

  /// Switches the store from the top bar (the caller checks the cart).
  Future<void> switchStore(StoreInfo next) async {
    final entry = access.firstWhereOrNull((a) => a.store.id == next.id);
    await begin(
      next,
      entry == null || entry.counters.isEmpty ? null : entry.counters.first,
    );
  }

  Future<void> renameCounter(String name) async {
    final c = counter.value;
    if (c == null) return;
    await _stores.renameCounter(c.id, name);
    counter.value = CounterInfo(id: c.id, storeId: c.storeId, name: name);
  }

  /// The one logout (DEC-150). Runs [beforeSignOut] (the binding flushes the
  /// pending cart save), clears the user, store, counter and scope, then runs
  /// [onSignedOut] (the binding resets the session-scoped controllers and
  /// navigates to the login screen). Saved data is never deleted. Does nothing
  /// when nobody is signed in.
  Future<void> signOut() async {
    if (!isSignedIn) return;
    await beforeSignOut?.call();
    _scope.clear();
    user.value = null;
    store.value = null;
    counter.value = null;
    regime.value = null;
    forex.clear();
    access.clear();
    onSignedOut?.call();
  }
}

class _EmptyUsers implements UserRepository {
  @override
  Future<bool> hasUsers() async => false;
  @override
  Future<UserCredential?> findByUsername(String username) async => null;
  @override
  Future<List<StoreAccess>> accessFor(String userId) async =>
      const <StoreAccess>[];
  @override
  Future<UserCredential?> firstActive() async => null;
}

class _EmptyStores implements StoreRepository {
  @override
  Future<bool> hasStores() async => false;
  @override
  Future<List<CurrencyRow>> loadCurrencies() async => const <CurrencyRow>[];
  @override
  Future<List<ForexRate>> loadForex(String storeId) async =>
      const <ForexRate>[];
  @override
  Future<TaxRegimeInfo?> loadTaxRegime(
    String region, {
    String storeId = '',
  }) async => null;
  @override
  Future<void> renameCounter(String counterId, String name) async {}
}
