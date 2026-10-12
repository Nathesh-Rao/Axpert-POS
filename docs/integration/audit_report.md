# Audit report: axpert_pos vs pos_application

Date: 2026-10-12. Branch: `integration`. axpert_pos was read only and never modified.

## Git state
- Git root: `/Users/narasimhanatheshrao/Development/pos_workspace/pos_application`. Current branch `main` = `origin/main` = `d5b2975`, working tree clean.
- Local `integration`: no. `origin/integration`: no (remote has only `main` and `ui-migration`). So STEP 0 = `git switch -c integration` from `main` (current branch is `main`, tree clean), then show `git branch -vv` and `git log --oneline -3`. If the tree is dirty or the branch is not `main` I stop.
- axpert_pos itself: git root has 2 commits (Sep 24: Flutter template; "PHASE 0 COMPLETE — HUMAN REVIEW REQUIRED", docs only). **All real code (lib/app, lib/core, lib/features, lib/shared, tests, assets, ADR-014, ~15 docs) is uncommitted/untracked on disk, about 4 days of work with no commit.** What I audited is the working tree, which is the only copy. Recommend you snapshot it yourself (I will not touch it). One more oddity: `.dart_tool/package_config.json` there is dated Oct 12 08:41 (some tool ran in it recently; not me).

## 1. Audit: axpert_pos (what really exists)
Reviewed: AGENTS.md, README, all 39 docs (14 ADRs + deferred-decisions, api 4, architecture 3, database 2, device, features 6, mock-data, phases/phase-0, security, testing, ui + reference image), all ~97 lib files and 21 test files (bodies of tests only by structure), pubspec/lock/build.yaml/analysis_options/.vscode/.gitignore, build artifacts (listing only). Not read line by line: remaining design tokens, lower halves of catalog_page/cart_panel, payment_success_view, the generated .g.dart.

**Size and phase.** About 6,200 lines of Dart (lib + test). Docs say "Phase 1 foundation in place, core POS not started" but code already holds Phase 2/2.5 (catalog, cart, pricing, sale construction, mock payment). Only phase file is phase-0.md. The README/phase-0 wording is stale (docs inconsistency, not a code problem).

| Area | Status (verified in source) |
|---|---|
| Layers/folders | `lib/app` (bootstrap, bindings, routes, session, lifecycle, device, shell), `lib/core` (database, money, identifiers, network, security, device, errors, result, data, config), `lib/features/<f>/{domain,data,presentation}`, `lib/shared/design_system` |
| catalog | Implemented against mock JSON (3 products, entity has only id/code/name), repository+usecase+DTO+controller+page. Tests. |
| pricing | Implemented, mock (`product_pricing.json`, 5% tax), `CartTotalsCalculator`, exclusive/inclusive both unit-tested, only exclusive+halfUp wired. Tests. |
| cart | In-memory only (immutable `Cart`, usecases, controller, panel). No persistence. Tests. |
| payment | Mock only (`MockPaymentService`, cash/card, succeed/fail). No tendered amount, change, split, refund. Tests. |
| sales | Domain only (`SaleConstruction`, `StartSale`, `CurrentSaleReader`). |
| database | Drift/SQLite, ONE table (`device_context_entries`, schema v2), native + WASM providers via conditional import, committed `drift_worker.js` + `sqlite3.wasm` (Drift 2.34.2 hashes in docs). Generated .g.dart present. No operational tables (ADR-014 gate, 16 unchecked items). |
| API | `DioApiClient` + `Result<ApiResponse>`; no interceptors/auth/retry; registered, unused; no endpoints exist or are invented. |
| auth/session | Interfaces + "unconfigured" implementation; `SessionController` restores nothing; no login UI, no route guard; `SecureCredentialStore` has no implementation. |
| sync/outbox | Not implemented (concepts in docs only). |
| devices | Only `DeviceContext` (UUID v4 + opaque outlet/register). No printer/scanner/drawer/terminal abstractions in code. |
| UI | Placeholder POS shell (drawer/rail, 2 nav items to the same page), catalog grid + "Current order" panel, payment dialog. Material 3 seed theme (not a brand design). |

**Conventions to match.** Feature-first with Presentation→Domain→Repository→DataSource; repository contracts live in the feature domain; `Result<T>`/`AppFailure` instead of throwing; `DataSource<T>`/`MockJsonDataSource` (asset JSON, snake_case keys, DTOs separate from entities, "mock is not a contract"); GetX only (no GoRouter): `Get.put(permanent)` for app services in `AppBindings`, `Get.lazyPut` per feature binding, `GetView<Controller>` for pages, Rx + Obx, `showDialog` for dialogs; UUID v4 text ids; money integer minor units; Quantity scaled integer; controllers never touch Drift/Dio/hardware; no packages unless the task needs them; never edit generated files; do not implement later phases; ADRs for decisions.

**Decided vs deferred in docs.** Decided: Drift/SQLite, UUID ids, integer minor-unit money, fractional product-dependent quantity, GetX, forward-only migrations, no DB encryption in MVP, offline for previously authenticated users, ~15-min sync target, mock payment behind abstraction. Deferred/blocked on backend: currency/exponent/locale, tax model/inclusivity, discount order, rounding mode/point, invoice numbering, endpoints/auth/sync contracts, server ids, inventory authority, backup/retention, hardware vendors, telemetry, deployment. (A1-A12/B1-B2 backend request is send-ready, unanswered.)

**Money/pricing facts (source).** `Money(int minorUnits)`, no currency, no negation/negative support (`multiplyRatio` halfUp is wrong for negatives); line extension rounded per line, tax per line (`bps/10000`, inclusive `bps/(10000+bps)`), totals = sums of rounded lines; no discounts/points/promotions; `Quantity(coefficient, scale)` unbounded scale, non-negative, normalized (exact only to 2^53 on web). Display: plain 2 decimals, no symbol (provisional).

## 2. Audit: pos_application (summary)
248 lib files, 74 test files (949 VM tests, ~30 goldens), 9 modules (shell, pos, products, customers, sales, returns, reports, settings, shift) with bindings/controllers/views/widgets/models/repository(+services). Routing: GetX `GetPages`, 7 named routes, each view wraps `AppShell`, no transitions. DI: `InitialBinding` idempotent permanent registrations + module `lazyPut`. Data: abstract repository + `Mock*Repository` (200-500 ms delay) over `LocalStore` (JSON KV, shared_preferences, seeded from Dart mock constants). Money core: `Money(minor, Currency)`, `Qty` (milli-units), `Bp`, rates in basis points, one plain-Dart `PricingService` (exclusive/inclusive, line discount first, bill discount proportional, points after tax, swappable rounding), ~300 golden vectors from React (+S6), `AudioService`/`BeepService`, print/receipt-share stubs. Theme: tokens + `ThemeExtension`, `AppIcons` (Lucide), `AppStrings`, responsive core with `ResponsiveLayout`. Packages: get, google_fonts (exact 6.3.3), lucide_icons_flutter, shared_preferences, flutter_web_plugins. Tools: `tool/web_check` (cdp, debug_check, perf), 2 guard tests (route navigation, semantics reparent).

## 3. Comparison (overlap / conflict)
| Topic | axpert_pos | pos_application | Verdict |
|---|---|---|---|
| Folders | `features/<f>/{domain,data,presentation}`, `app/`, `core/`, `shared/design_system` | `modules/<m>/{controllers,views,widgets,bindings,models,repository,services}`, `core/`, `shared/` | Conflict. Needs decision D2. |
| State/DI/routing | GetX; `Get.put(permanent)` + feature `lazyPut`; `GetView`; nested `GetRouterOutlet` shell | GetX; `InitialBinding` permanent + module `lazyPut`; `GetView`; `GetPages`, each view wraps `AppShell` | Compatible (same framework, same lifetimes). Shell stays ours; their nested outlet is a placeholder UI, not ported. |
| Errors | `Result<T>`, `AppFailure` | exceptions/plain futures | New convention to adopt at repository boundaries. |
| Models/ids | UUID v4 text, DTO vs entity, snake_case JSON | int product ids, string customer ids, `AX000001` sale numbers from list length (KG), `toJson/fromJson` camelCase | Conflict, D3/D4. |
| Money | `Money(int)`, no currency, no negatives | `Money(minor, Currency)`, negatives (refunds), registry, lakh grouping | Ours is a superset. D1. |
| Quantity | `coefficient+scale` unbounded | milli-units (3 decimals) | Compatible for scale<=3; scale>3 not representable. D1. |
| Tax/discount/rounding | per-line half-up, exclusive wired, inclusive tested, no discounts | exclusive+inclusive, line+bill discount, points, prototype rounding strategy | Ours covers theirs; must prove equality on their inputs (compat test). D1. |
| Persistence | Drift: only device-context table; ADR-014 forbids operational tables until 16 items resolved | `LocalStore` JSON KV holds everything | No conflict while the gate is closed: LocalStore stays the isolated mock persistence; Drift added for device context only. D5. |
| Mock data | JSON assets + `MockJsonDataSource` | Dart seed constants + `LocalStoreSeeder` | Convention conflict, D4. |
| Services | `PaymentService` abstraction + `PayCurrentSale`; `CurrentSaleReader`; `SaleConstruction` with UUID | payment/totals logic in controllers + `PricingService`; sales ledger | Same names, different responsibilities: do NOT merge by name. Adapt behind interfaces (stage 7). |
| Auth/session | interfaces + unconfigured impl | `ShiftController` (prototype counter open/close, "Counter closed") | Different concepts; keep both, no mapping. |
| Platforms | Windows, macOS, Android, Web (no iOS folder) | + tablet (Android/iPad); folders: android, macos, web, windows | Compatible. |
| Lints | `flutter_lints ^6` empty rules | same + `prefer_const_constructors`, `avoid_print` | Equivalent in practice. |
| Tests | 21 files, mostly pure unit, in-memory Drift, no goldens/tags | 949 VM tests, goldens, layout matrix, guards | Port theirs; keep ours. |

**Dependencies.** Overlap: `get ^4.7.3`, `flutter_lints ^6.0.0`, `flutter_test`, SDK `^3.10.3`: identical, no resolver conflict. Only in axpert: `dio ^5.11.1`, `drift ^2.34.4`, `path ^1.9.1`, `path_provider ^2.1.6`, `cupertino_icons ^1.0.8` (unused), dev `drift_dev` (exact 2.34.0), `build_runner` (exact 2.11.1). Only in ours: google_fonts, lucide_icons_flutter, shared_preferences, flutter_web_plugins.
Windows/macOS/web (pub.dev page fetches on 2026-10-12, via agent): dio yes/yes/yes; drift yes/yes/yes (web needs wasm + worker matching the drift version, `.wasm` served as application/wasm); path yes; get yes (slow cadence, 5.0 RC exists); drift_dev/build_runner are host tools (web N/A); **path_provider: no web support** (pub.dev lists no Web). axpert isolates it behind a conditional import (`dart.library.io` vs `js_interop`), so it is a rule violation only on paper; I must keep it import-isolated and flag it for your approval. Pins: `drift_dev 2.34.0` vs `drift ^2.34.4` is fragile (latest drift 2.35.2 / drift_dev 2.35.1; build_runner 2.16.2); committed web assets are Drift 2.34.2 vs locked 2.34.4. Could NOT verify: transitive `sqlite3` platform pages, `dio_web_adapter`; and (unrelated to this task) our own packages' pub.dev pages were not re-fetched; whether `flutter test` on the VM can load the sqlite3 native-assets hook here (will be tested at the Drift stage before relying on it).

**AGENTS.md vs our CLAUDE.md conflicts.** None blocking. Differences to record: AGENTS uses `dart format --output=none --set-exit-if-changed`, we use `dart format .`; AGENTS has no Chrome-test ban, no debug click-through, no layout rules, no commit trailers; AGENTS "add a package only if the task needs it" vs ours "ask first, one at a time" (ours stricter, wins); phase-level human-review commit vs our per-checkpoint commit after OK (ours wins). CLAUDE.md governs.

## Stage 3 cross-check result (added during implementation)
See `progress.md` and `test/core/services/pricing/axpert_crosscheck_test.dart`: the two rule sets are not identical (per-line vs cart-level rounding; inclusive-mode `subtotal` meaning). Owner decision: keep our money core, no adapter (DEC-116, `money_core_differences.md`).
