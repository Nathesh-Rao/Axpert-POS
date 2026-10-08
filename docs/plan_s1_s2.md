# Plan S1 + S2: money and shell (detailed); S3 to S7 (summary)

Replan approved 2026-10-08 (DEC-069). Read `CLAUDE.md` and this file only. Approval once per step; checkpoints are commit points with a short report each. Done earlier: 1.1 Setup, 1.2 Theme tokens (tokens, `css_metrics.md`, golden harness).

Standard checks at every checkpoint: `dart format .`, `flutter analyze` (0), `flutter test`; UI checkpoints also run on macOS and Chrome. Comparison policy: pixel comparison only at the reference viewport (2124x1180 px, light; golden 1868.44 x 1034.67 logical at DPR 1.125) against `reference_screenshots/`. Other sizes, dark mode, popovers, modals: regression goldens only, "unverified visually" in `known_gaps.md`.

Order: S1 (own session) -> `/clear` -> S2 (own session).

---

# S1 Money (L)

**Prerequisites:** nothing blocking. The one-off `npx --yes esbuild` is approved for S1 (DEC-053); nothing is installed into either project. Pure Dart, no screenshots.

Money code lives in `lib/core/services/pricing/` and `lib/core/utils/`: no Flutter or GetX imports, no `double`/`num`.

## S1.a Types and formatter (commit "S1.a Money types")
Files: `currency.dart`, `currency_registry.dart` (12 seeds), `money.dart` (immutable, per-currency, `CurrencyMismatch`), `qty.dart` (milli-units), `basis_points.dart`, `rational.dart` (BigInt), `rounding_strategy.dart` (named rounding points), `prototype_rounding.dart` (half-up, `floor(x + 1/2)`), `money_formatter.dart` (lakh vs thousands grouping, exponent, negatives).
Order: Rational -> rounding -> Currency/registry -> Money/Qty/Bp -> formatter -> tests.
Tests: half-up at ties, zero, negatives; exponents 0/2/3 (UGX, INR, TND); formatter for all 12 seeds; cross-currency arithmetic throws; JSON round trip; no-`double` scan; green with `flutter test --platform chrome`.
Done when:
- [ ] Tests green on VM and Chrome
- [ ] No Flutter imports, no `double`/`num` in the pricing folder
- [ ] Standard checks pass

## S1.b Golden vectors + exclusive mode (commit "S1.b Pricing golden")
Files: `tax_config.dart`, `pricing_models.dart` (`CartInput`, `LineInput`, `CartTotals`, per-line breakdown), `pricing_service.dart` (exclusive); `tool/golden/gen_vectors.mjs` (outside `reference_react`: transpiles React's unmodified `data.ts` to a temp `.mjs` in the scratchpad, imports it, seeded PRNG); `test/fixtures/pricing_golden.json`.
Vectors (about 300): hand-written edge cases (empty cart, 100% discount, flat above subtotal, points above payable, fractional qty, slabs 0/5/12/18) plus seeded random carts (0-8 lines, qty milli, prices and discounts at most 2 decimals, percent or flat bill discount, points).
Ties: a 1-minor-unit mismatch at an exact tie is recorded in `known_gaps.md` (KG-079) and accepted. No review file.
Done when:
- [ ] Golden equality for all fields, except listed ties
- [ ] Exclusive mode green on VM and Chrome
- [ ] Standard checks pass
`/compact` here if the context is large.

## S1.c Inclusive mode + helpers (commit "S1.c Inclusive tax and helpers")
Inclusive mode per DEC-022 invariants; change due, refund share, forex convert, points clamp, flat/percent bill discount clamp; stub rounding strategy proves the swap seam.
Done when:
- [ ] Both tax modes covered; invariants asserted
- [ ] Seam test green; VM and Chrome green
- [ ] Standard checks pass

---

# S2 Shell (L)

**Prerequisites:** S1 done (not strictly required by the shell, but formatters are used by the summary frame), tokens from 1.2, packages from 1.1 (`get`, `lucide_icons_flutter`, `shared_preferences`, `google_fonts` 6.3.3). Screenshots available for the shell at the reference viewport (light). Dark, other sizes, popovers, menus, toasts: built from CSS/code (unverified).
Routing option (i): per-page `AppShell` wrapper, permanent controllers (DEC-041). No spike.

## S2.a Foundations (commit "S2.a Storage, strings, routes")
- `lib/core/services/storage/`: `local_store.dart` (interface), `shared_prefs_local_store.dart`, `in_memory_local_store.dart`, seed-on-first-run helper.
- `lib/modules/shell/`: `models/app_settings.dart`, `repository/settings_repository.dart` + `mock_settings_repository.dart` (200-500 ms delay, persists via `LocalStore`).
- `lib/core/routes/`: `app_routes.dart`, `app_pages.dart` (`/`, `/products`, `/customers`, `/sales`, `/returns`, `/reports`, `/more`; unknown paths -> POS).
- `lib/core/constants/app_strings.dart`: shell strings (parameterized functions, no concatenation in views).
- `lib/core/bindings/initial_binding.dart`: permanent controllers (settings, toast, search field, overlay).
Tests: strings guard (no string literals in `Text`), LocalStore round trip and first-run seeding, route table.
Done when:
- [ ] Seven routes resolve; unknown path -> POS
- [ ] Settings persist across restarts (macOS and Chrome)
- [ ] Standard checks pass

## S2.b Responsive core + top bar + sidebar (commit "S2.b Responsive core, top bar, sidebar")
- `lib/core/responsive/`: `breakpoints.dart` (widths 1700/1280/1100; heights 960/820/719), `app_metrics.dart` (clamp(vw/vh) rules from `css_metrics.md` section 10, density flags), `responsive_layout.dart`.
- Top bar: brand mark, store select, global search field (`FocusNode` owned by the search controller) with platform-aware shortcut hint and scan button, online chip, notifications popover with badge, profile and kebab menu.
- Sidebar: 7 items, active gradient + 2px bar, hover, focus.
Tests: `AppMetrics` values at the reference viewport and documented other sizes (regression only); `ResponsiveLayout`; sidebar active state; label per platform.
Done when:
- [ ] Top bar and sidebar match the screenshots at the reference viewport; differences listed
- [ ] `AppMetrics` matches `css_metrics.md`; unverified rules in `known_gaps.md`
- [ ] Standard checks pass
`/compact` here.

## S2.c Frame + hosts (commit "S2.c Summary frame and hosts")
Offline banner; Bill Summary frame (static, width 380 on POS vs 310 elsewhere per KG-029); toast host (above dialogs, in the `GetMaterialApp.builder`); overlay host (dims the whole window); placeholder pages for the 7 routes.
Tests: search text and focus survive navigation; toast above a dialog; overlay dims top bar and sidebar.
Done when:
- [ ] Frame matches screenshots at the reference viewport
- [ ] Focus/text survive navigation; toasts above dialogs
- [ ] Standard checks pass

## S2.d Shortcuts, theme toggle, cleanup (commit "S2.d Shortcuts, theme toggle, shell goldens")
Shortcuts skeleton (`Shortcuts`/`Actions` above the Navigator; Ctrl and Cmd for K, F2-F6, Esc, Delete; F-keys fire in inputs and with modals open); dark-mode toggle via `SettingsController`; shell goldens (reference viewport light for comparison, others/dark regression).
**Delete (DEC-065):** `lib/core/theme/debug/`, the `?swatch`/`SWATCH` hook in `main.dart`, `test/golden/specimen_golden_test.dart` and its goldens.
Tests: both-modifier shortcuts, theme toggle, F-keys with a dialog open and a focused field.
Done when:
- [ ] Swatch page, hook and specimen golden removed
- [ ] Shell goldens exist; differences vs React listed in the report; unverified items in `known_gaps.md`
- [ ] Standard checks pass; runs on macOS and Chrome

---

# S3 to S7 (summary; each gets its own detailed plan when reached)

- **S3 POS core (L):** S3.a data (models with `fromJson`/`toJson`, repository interfaces, mocks with seeds, 10k-product debug dataset); S3.b catalog (categories, sub chips, search/filter, grid/list, product card); S3.c cart table (qty/price/discount editing, hold-to-repeat, remove + 5 s Undo, highlight, stat tiles); S3.d controllers and comparison. Shared widgets built when first needed.
- **S4 POS checkout (L):** S4.a totals + cash/card/credit; S4.b hold/recall (guarded), discount drawer, note, rename; S4.c price check, scan simulator, customer picker, add customer; S4.d receipt preview (`ReceiptDocument` + `ReceiptPrinter` stub), shortcuts help.
- **S5 Secondary pages (L):** S5.a Products + Customers; S5.b Sales + Reports; S5.c Settings + profile; S5.d shift close + signed-out.
- **S6 Returns and keyboard (M-L):** S6.a Returns; S6.b shortcut and focus-return pass; S6.c web key-conflict check (F5/F3/F6/Ctrl+K, KG-015).
- **S7 Polish (L):** S7.a responsive pass; S7.b web and Windows review; S7.c performance with 10k products; S7.d final comparison and cleanup (remove `reference_react/` and `reference_screenshots/`, move CLAUDE.md only with explicit OK).

No S1 work starts until the user says go.
