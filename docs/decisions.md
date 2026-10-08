# Decisions log

Format: ID, decision, why, date. Newest decisions append at the bottom of their section. Gaps live in `known_gaps.md`.
Dates: plan v2 approved 2026-10-07.

## Scope and process

| ID | Decision | Why |
|---|---|---|
| DEC-001 | Phase A = one-time port of the React prototype (UI + mechanics) to Flutter, replicating behavior as-is including quirks. Gaps are logged (`known_gaps.md`) and fixed in Phase B. Only crashes are guarded (DEC-003) | CLAUDE.md port-as-is rule |
| DEC-010 | Git repo exists inside `pos_application` only (git init happens in step 1.1). All docs live in `pos_application/docs/`. `CLAUDE.md` stays in `pos_workspace` until the end of Phase A. `reference_react/` and `reference_screenshots/` stay outside git | D12 |
| DEC-011 | One commit per phase step; the agent proposes the message and commits only after the user's OK | D17 |
| DEC-012 | Plans are saved as `docs/plan_phaseX.md` after approval; `docs/migration_plan.md` is the short master plan; `react_audit.md` replaces re-reading `App.tsx` | CLAUDE.md |
| DEC-013 | Phase 1 steps split: 1.1, 1.2, 1.3a, 1.3b, 1.4a (spike), 1.4b, 1.4c, each in its own session | approved |
| DEC-014 | Flutter stays on 3.38.4; do NOT run `flutter upgrade`. pub resolves package versions compatible with it | approved |
| DEC-015 | iOS platform is skipped until Phase 4 (`ios/` not added in 1.1) | D13 |
| DEC-016 | `cupertino_icons` removed from pubspec | D14 |

## Money, rounding, tax, currency

| ID | Decision | Why |
|---|---|---|
| DEC-002 | Money = integer minor units with per-currency exponent (0/2/3); quantity = integer milli-units; percentages and tax rates = integer basis points; never `double`. Rounding is a swappable `RoundingStrategy`; default `PrototypeRounding` rounds exactly where React's `calculate()` rounds: value, discount (= V - S + BD), tax, points, total, half-up on the EXACT value (`floor(x + 1/2)` at minor units); `subtotal` output = rounded gross value; line totals, change and refunds are not rounded by the service (display rounding half-up). Per-line rounding is a later option, not built now | D1, D2 |
| DEC-004 | Pricing internals use `BigInt` rationals because Dart ints on web are JS numbers (exact only to 2^53) and qty x price x bp x bp can exceed that. Public API stays int/Money based; no `double` or `num` in `core/services/pricing` (enforced by a source-scan test) | A6 item 1 |
| DEC-020 | Currency registry seeds: INR, USD, EUR, AED, KES, NGN, GHS, ZAR, UGX, RWF, XOF, TND (exponent 2 except UGX/RWF/XOF = 0, TND = 3). INR groups by lakh (`1,23,456.00`), others by thousands. `Money` carries its currency; mixing throws `CurrencyMismatch` | D9 |
| DEC-021 | `TaxConfig` per country: label (GST/VAT), mode (exclusive/inclusive), rate slabs in basis points. Default = INR + GST + exclusive (reproduces the prototype). BOTH modes implemented and unit-tested now; UI exposes only exclusive/INR | D9 |
| DEC-022 | Inclusive-tax spec (React has none): unit price includes tax; bill discount allocated proportionally on gross line amounts; per-line tax = gross * r / (100 + r); total = gross after discount - points; tax is informational; points capped at the discounted gross; same rounding points as exclusive mode | approved (A1) |
| DEC-023 | Mock/JSON keeps the prototype's `gst` shape (plain percent number); converted to basis points by decimal-string parsing, not a float multiply. Prices stored as `priceMinor` ints (seeded from the prototype's rupee values) | D9 |
| DEC-024 | Forced precision deviation: typed values beyond the integer scale are rounded half-up at the scale on commit (see KG-002/003). Redeem points: whole points only, truncate (KG-004) | approved |
| DEC-025 | Golden vectors: `tool/golden/gen_vectors.mjs` (outside `reference_react`) transpiles React's unmodified `data.ts` with a one-off `npx --yes esbuild` (approved for step 1.3b only; nothing installed into either project) and runs the real `calculate()`/`lineTotal`/`cartReducer`. Fixtures: `test/fixtures/pricing_golden.json`; tests assert exact equality. Exact-tie vectors where JS floats land on the other side are listed in `test/fixtures/known_ties.json` (user reviews it when it exists); only 1-minor-unit mismatches at detected ties are accepted | D1, ties approved |
| DEC-026 | Pricing tests also run with `flutter test --platform chrome` (BigInt/int behavior differs on web) | A1 |

## Behavior and UI

| ID | Decision | Why |
|---|---|---|
| DEC-003 | Only logic deviation: `recall()` of a held bill with a missing product is guarded (the line is dropped) instead of crashing; logged here, gap KG-013 | D3 |
| DEC-005 | F2-F6 keep firing in inputs and with modals open (no F-key suppression), global `Shortcuts` is placed above the Navigator | D3, D7 |
| DEC-007 | Only approved UI deviation: platform-aware shortcut labels (Cmd+K on macOS, Ctrl+K elsewhere); both modifiers always work | D7 |
| DEC-030 | No new sidebar collapse, no phone layout, no layout the prototype does not have. Everything the prototype's own media queries do is replicated per the translation table in `react_audit.md` section 5 | D7, CLAUDE.md |
| DEC-031 | Dark mode: replicate exactly where React overrides (13 rules); everywhere else the same value in both modes, listed in `known_gaps.md` section C. No invented dark variants | D15 |
| DEC-032 | Print button stays a silent stub (port as-is); Email/WhatsApp stay "(demo)" toasts; beep, printing, email, WhatsApp are interfaces with no-op stubs. `ReceiptDocument` (UI-independent, printer-agnostic) + `ReceiptPrinter` interface; the receipt preview UI is built on `ReceiptDocument` | D10, approved |
| DEC-033 | Forex card ported as-is (known gap KG-006) | D9 |
| DEC-034 | All user-facing strings in `AppStrings`: abstract class, one method per message with named params, values pre-formatted outside, no plural logic (React has none), no concatenation in views; method names are future ARB keys so `gen_l10n` can replace it with the same signatures. A test fails if views pass string literals to `Text` | D16 |

## Structure, state, routing

| ID | Decision | Why |
|---|---|---|
| DEC-040 | A module may have several single-responsibility controllers. Shared state (cart, products, customers, held, sales ledger, toasts, search field, overlays, settings, clock, page filter) lives in permanent controllers in `InitialBinding`; POS-only controllers (catalog, selection, payment, member) are route-bound with `Get.lazyPut`; dialogs get dialog-scoped controllers. Plain Dart services: `PricingService`, `CheckoutService`, `ReceiptBuilder` | D8 |
| DEC-041 | Routing: option (i) per-page `AppShell` wrapper with permanent controllers (owning the search `FocusNode`/text), dialogs on the root Navigator overlay, toast host and global shortcuts in `GetMaterialApp.builder` above the Navigator. Subject to the result of spike 1.4a; the decision record is added here after the spike | D6, item 8 |
| DEC-042 | Storage: `LocalStore` interface (async JSON string key-value) with `SharedPrefsLocalStore` (real) and `InMemoryLocalStore` (tests). Same data/keys as the prototype (cart, products, customers, held, sales, store, dark, beep, counter, rate); seeded from mock data on first run; mock repositories read/write through it, after a 200-500 ms simulated delay | D5 |
| DEC-043 | SUPERSEDED by DEC-044. (Was: Roboto Condensed bundled as asset files, no `google_fonts`) | D4 |
| DEC-044 | Fonts: Roboto Condensed 400/500/600/700 via the `google_fonts` package, accessed ONLY through `core/theme/tokens/app_typography.dart` (no widget imports `google_fonts`). Runtime fetching for now; bundling later is a one-file change. Network access: `com.apple.security.network.client` in both macOS entitlements files, `INTERNET` in the Android main manifest. Tests use committed TTFs under `test/fonts/` with `OFL.txt` (placed by the user before 1.2) | D4 |

## Packages

| ID | Package | Decision |
|---|---|---|
| DEC-050 | `get` | Approved (4.7.3 on pub.dev, last published 2025-11-24, all 6 platforms, 140/160 points) |
| DEC-051 | `lucide_icons_flutter` | Approved; add in step 1.1 (3.1.22 = Lucide 1.52.0 = the prototype's pin; all 45 icons verified; all platforms). Rejected: `flutter_lucide` (no `trash_2`), `lucide_flutter` (low adoption, unverified set), `lucide_icons` (Dart < 3) |
| DEC-052 | `shared_preferences` | Approved; add in step 1.1, let pub pick the version compatible with Flutter 3.38.4 (latest needs Flutter 3.41). Rejected/alternative: `get_storage` (Dart < 3), `hive_ce` (later option), `localstorage` (low adoption) |
| DEC-053 | one-off `npx --yes esbuild` | Approved for step 1.3b only; nothing installed into either project |
| DEC-054 | Computed-style probe (headless browser) and image-diff tool | Skipped for now; ask again later if needed |
| DEC-055 | `google_fonts` | Approved, pinned at exactly 8.2.1 (no caret) until a Flutter upgrade; DEC-044 |

## UI comparison workflow (D11, updated)

| ID | Decision |
|---|---|
| DEC-060 | Reference screenshots: 7 files, all 2124x1180 px, 144 dpi, light mode only (see `react_audit.md` section 3). The measured pixel size is THE reference viewport; no media query applies at it (width > 1700, height > 960). Pixel comparisons happen only at this viewport, in light mode, for: POS (empty, one line), Products, Customers, Sales, Returns, Reports |
| DEC-061 | Goldens at the reference viewport in light mode are compared against the screenshots (visually, cropped regions). Goldens at other sizes and in dark mode are regression tests only and are marked "unverified visually" in `known_gaps.md`. Modals, drawers, popovers and More/Settings have no screenshots: built from CSS and code, user supplies screenshots per step if needed |
| DEC-062 | The scale between screenshot pixels and CSS px is about 1.11 (inferred). Step 1.2 calibrates it from fixed-size elements and records it in `css_metrics.md`; the golden harness then uses logical size = screenshot size / scale at DPR = scale so goldens come out 2124x1180 px |
| DEC-063 | Golden harness loads the bundled fonts with `FontLoader` (test fonts would render boxes) and the Lucide font; known limits (anti-aliasing, blur, native select, scrollbars) are listed in KG-051 |
