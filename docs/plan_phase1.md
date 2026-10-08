# Phase 1 plan: setup, theme, money, routes, responsive shell

Approved 2026-10-07 (plan v2 + answers). Read `CLAUDE.md` and ONLY the section of the current step. Do not start a step without the user's approval. Each step = own session, begin with `/clear`.

Common checks for every step: `dart format .` clean, `flutter analyze` zero issues, `flutter test` passes, app runs on macOS and Chrome without errors, short report (changes, checks, differences vs React, open questions), commit message proposed and committed only after OK.

Comparison policy: pixel comparison only at the reference viewport (2124x1180 px, light) against `reference_screenshots/` (7 light-mode images; see `react_audit.md` section 3). No media query applies there. Other sizes and dark mode: goldens are regression tests only and are marked "unverified visually" in `known_gaps.md`.

| Step | Size | Session note | Proposed commit |
|---|---|---|---|
| 1.1 Setup | S | own session | `1.1 Project setup` |
| 1.2 Theme tokens + golden harness | M | own session | `1.2 Theme tokens` |
| 1.3a Money core | M | own session | `1.3a Money core` |
| 1.3b PricingService + golden vectors | M-L | own session; `/compact` after the golden run is green if the context is large | `1.3b Pricing service` |
| 1.4a Routing spike | S | own session, throwaway code; commit only the decision doc | `1.4a Routing decision` |
| 1.4b LocalStore, strings, routes, responsive core | M | own session | `1.4b Routes and metrics` |
| 1.4c Shell UI | M-L | own session; `/compact` once the top bar is done | `1.4c App shell` |

Run `/clear` between every step. `/compact` only inside 1.3b and 1.4c as noted.

---

## 1.1 Setup (S)

**Prerequisites:**
- The four Roboto Condensed static TTFs placed in `pos_application/assets/fonts/`: `RobotoCondensed-Regular.ttf` (400), `RobotoCondensed-Medium.ttf` (500), `RobotoCondensed-SemiBold.ttf` (600), `RobotoCondensed-Bold.ttf` (700), plus `OFL.txt` (from fonts.google.com "Get font", `static/` folder; verify the exact names in the ZIP).
- Packages approved: `get`, `lucide_icons_flutter`, `shared_preferences`, `google_fonts` 6.3.3 pinned (DEC-044, DEC-055; 8.2.1 has no Roboto Condensed) (added in this step, not before). Flutter stays on 3.38.4 (no `flutter upgrade`).
- No screenshots needed.

**Files created or changed:**
- `pubspec.yaml`: add the three packages with `flutter pub add` (pub picks versions compatible with 3.38.4); remove `cupertino_icons`; declare the font family (weights 400/500/600/700) and `assets/products/`.
- `analysis_options.yaml`: keep `flutter_lints`; add `prefer_const_constructors` and `avoid_print`.
- `lib/main.dart`: minimal `GetMaterialApp` placeholder.
- Folder skeleton (`.gitkeep`): `lib/core/{theme,constants,utils,services,routes,responsive,mock,bindings}`, `lib/shared/{widgets,models}`, `lib/modules/<feature>/{controllers,views,widgets,bindings,models,repository}` for shell, pos, products, customers, sales, returns, reports, settings, shift.
- `assets/products/0.png .. 11.png`: copied from `reference_react/public/products/` (source untouched).
- `lib/core/constants/app_strings.dart`: empty `AppStrings` shell.
- `test/widget_test.dart`: replaced by a smoke test; `test/assets_test.dart`.
- `docs/`: the five docs are already written; adjust only if the step changes them.
- `git init` inside `pos_application` only (not at workspace level); `.gitignore` check.

**Order:** git init -> pubspec and `flutter pub get` -> assets copy -> skeleton -> main.dart and tests -> checks.

**Tests:** app boots; the four font files and 12 images exist and resolve through `rootBundle`; a smoke test pumps the placeholder app.

**Done when:**
- [ ] Git repo exists in `pos_application` only
- [ ] Dependencies resolve on Flutter 3.38.4; no `cupertino_icons`; no `ios/` added
- [ ] Fonts and images load in a test
- [ ] Format, analyze (0), tests pass; runs on macOS and Chrome
- [ ] Docs present

---

## 1.2 Theme tokens + golden harness (M)

**Prerequisites:**
- 1.1 done (fonts and Lucide package in place).
- Screenshots are available (not blocking): compare token swatches and the type specimen against cropped regions of the light-mode screenshots at the reference viewport. Dark tokens come from the 13 `.dark` rules only and are "unverified visually".

**Files created or changed:**
- `docs/css_metrics.md`: cascade-resolved table (in file block order, later rule wins) of colors, typography, radii, shadows, layout sizes and every `clamp(vw/vh)` rule; the screenshot scale calibration (see below); which clamps change between logical widths 1900-2124; media-query rule inventory (documentation only).
- `lib/core/theme/tokens/`: `app_colors.dart` (light + dark `ThemeExtension`), `app_typography.dart`, `app_spacing.dart`, `app_radii.dart`, `app_shadows.dart` (CSS blur radius -> `BoxShadow.blurRadius`, sigma = radius/2), `app_sizes.dart`, `app_motion.dart`.
- `lib/core/theme/app_theme.dart`, `lib/core/theme/theme_x.dart` (`context.colors`, `context.text`, `context.space`, ...).
- `test/golden/harness.dart` (load Roboto Condensed + Lucide fonts via `FontLoader`, set window size and DPR, tolerance comparator) and a swatch/type specimen golden.
- `assets`/fonts declared in 1.1 are used here.

**Scale calibration:** measure fixed CSS-size elements in the screenshots (top bar 64 CSS px, summary panel max 380, sidebar 80) with `sips` crops + viewing (no image tool installed); measured scale 1.125 (done in 1.2, `css_metrics.md` section 1); golden logical size 1868.44 x 1034.67 at DPR 1.125 = 2102x1164 px page area.

**Order:** extract and resolve CSS -> write `css_metrics.md` -> light tokens -> dark tokens (13 rules; everything else identical in both modes and listed in `known_gaps.md` section C) -> ThemeData/extensions/helpers -> golden harness -> specimen golden -> checks.

**Tests:** every token value asserted against `css_metrics.md`; extension `copyWith`/`lerp`; light/dark differ only where React overrides; font family and four weights resolve; golden harness renders text with the real font (not test boxes).

**Done when:**
- [ ] Every token traces to a CSS line in `css_metrics.md`
- [ ] No hardcoded styling values outside the token files
- [ ] Specimen compared to screenshot crops at the reference viewport; differences listed
- [x] Scale 1.125 recorded (DEC-062 corrected); harness produces the 2102x1164 px page area (crop offset 10,8)
- [ ] Standard checks pass

---

## 1.3a Money core (M)

**Prerequisites:** 1.1 done. No screenshots, no packages, no npx needed. Pure Dart.

**Files** (`lib/core/services/pricing/` and `lib/core/utils/`, no Flutter or GetX imports):
`currency.dart`, `currency_registry.dart` (12 seeds), `money.dart` (immutable, per-currency, `CurrencyMismatch`), `qty.dart` (milli-units extension type), `basis_points.dart`, `rational.dart` (BigInt), `rounding_strategy.dart` (interface with named rounding points), `prototype_rounding.dart` (half-up, `floor(x + 1/2)`), `money_formatter.dart` (lakh vs thousands grouping, exponent, negatives).

**Order:** Rational -> rounding -> Currency/registry -> Money/Qty/Bp -> formatter -> tests.

**Tests:** half-up at ties, zero and negatives; exponents 0/2/3 (UGX, INR, TND); formatter for all 12 seeds (grouping, negative, zero, large values); cross-currency arithmetic throws; JSON round trip; the no-double scan over `core/services/pricing`; everything also green with `flutter test --platform chrome`.

**Done when:**
- [ ] All tests green on VM and Chrome
- [ ] No Flutter imports in the pricing folder; no `double`/`num`
- [ ] Standard checks pass

---

## 1.3b PricingService + golden vectors (M-L)

**Prerequisites:**
- 1.3a done.
- Approval for the one-off `npx --yes esbuild` (granted for this step only; nothing installed into either project). Node 20.14 is available; `reference_react` has no `node_modules`.
- The user reviews `test/fixtures/known_ties.json` after it is generated.

**Files created or changed:**
- `lib/core/services/pricing/`: `tax_config.dart`, `pricing_models.dart` (`CartInput`, `LineInput`, `CartTotals`, per-line breakdown), `pricing_service.dart`.
- `tool/golden/gen_vectors.mjs` (outside `reference_react`): transpiles React's unmodified `data.ts` to a temp `.mjs` in the scratchpad, imports it, generates the vectors with a seeded PRNG: hand-written edge cases (empty cart, 100% discount, flat above subtotal, points above payable, fractional qty, all slabs 0/5/12/18) and about 2000 random carts (0-8 lines, qty milli, prices at most 2 decimals, discounts at most 2 decimals, percent or flat bill discount, points).
- `test/fixtures/pricing_golden.json`, `test/fixtures/known_ties.json`.
- Tests: golden equality (all output fields exact; at detected exact ties only a 1-minor-unit mismatch is accepted and must be listed in `known_ties.json`), exclusive mode, inclusive mode (DEC-022 invariants), change due, refund share, forex convert, points clamp, flat/percent bill discount clamp, swap test with a stub rounding strategy.

**Order:** generate vectors and report the tie rate -> implement exclusive mode until golden is green -> user reviews ties -> implement inclusive mode -> helpers -> checks. If the context gets large, split into "1.3b-i golden + exclusive" and "1.3b-ii inclusive + helpers".

**Done when:**
- [ ] Golden vectors match exactly except approved, listed ties
- [ ] Both tax modes covered; strategy seam proven
- [ ] Green on VM and Chrome; no `double`/`num` in the pricing folder
- [ ] Standard checks pass

---

## 1.4a Routing spike (S, throwaway)

**Prerequisites:** 1.1 done (`get` available). No screenshots. The spike lives in the scratchpad outside `pos_application`; it is deleted afterwards. Only the decision record is kept.

**What it builds:** a tiny Flutter app with `get`, three fake routes, a search field in a shared shell, one dialog, one drawer, a toast host in `GetMaterialApp.builder`, global F-key and Ctrl/Cmd+K shortcuts. Run on Chrome and macOS.

**Checks (pass/fail each):** dialog and drawer dim the whole window including top bar and sidebar; search text and focus survive navigation (permanent controller owns `FocusNode` and text controller); browser URL and back/forward on web (path URL strategy); toast above an open dialog; F-keys reach handlers while a dialog is open and a text field has focus; whether F5, F3, F6 and Ctrl+K are prevented from triggering browser defaults.

**Output:** a decision record appended to `decisions.md` (DEC-041 confirmed or changed) and KG-015 updated.

**Done when:**
- [ ] Every check has a recorded result
- [ ] Routing option chosen with the user's approval; spike code deleted

---

## 1.4b LocalStore, strings, routes, responsive core (M)

**Prerequisites:** 1.2 done (tokens, scale S recorded), 1.3a done, 1.4a decision approved. `shared_preferences` added in 1.1.

**Files created or changed:**
- `lib/core/services/storage/`: `local_store.dart` (interface), `shared_prefs_local_store.dart`, `in_memory_local_store.dart`, seeding helper (seed on first run only).
- `lib/modules/shell/`: `models/app_settings.dart`, `repository/settings_repository.dart` + `mock_settings_repository.dart` (200-500 ms delay, persists via `LocalStore`).
- `lib/core/routes/`: `app_routes.dart`, `app_pages.dart` (7 named routes: `/`, `/products`, `/customers`, `/sales`, `/returns`, `/reports`, `/more`; unknown paths fall through to POS).
- `lib/core/responsive/`: `breakpoints.dart` (1700, 1280, 1100 widths; 960, 820, 719 heights), `app_metrics.dart` (clamp(vw/vh) rules from `css_metrics.md`, density flags), `responsive_layout.dart`.
- `lib/core/constants/app_strings.dart`: shell strings (top bar, sidebar, search placeholder, notifications, menus, toasts used in the shell).
- `lib/core/bindings/initial_binding.dart`: permanent controllers that exist so far (settings, toast, search field, overlay).
- Tests: strings guard (views must not pass string literals to `Text`), `AppMetrics` values at the reference viewport and at the other documented sizes (regression only), LocalStore round trip and first-run seeding, route table, `ResponsiveLayout` widget test.

**Order:** LocalStore -> settings repo -> routes -> metrics -> strings -> bindings -> tests.

**Done when:**
- [ ] Seven routes resolve; unknown path -> POS
- [ ] Settings persist across restarts (macOS and Chrome)
- [ ] `AppMetrics` matches `css_metrics.md`; unverified rules marked in `known_gaps.md`
- [ ] Standard checks pass

---

## 1.4c Shell UI (M-L)

**Prerequisites:**
- 1.2, 1.4b done.
- Screenshots available (not blocking): compare the shell (top bar, sidebar, Bill Summary frame) at the reference viewport in light mode against the POS (empty and one-line), Products, Customers, Sales, Returns and Reports screenshots. Dark, other sizes, popovers, menus and toasts are built from CSS/code (unverified visually).

**Files** (`lib/modules/shell/{views,widgets,controllers}` and `lib/shared/widgets`, only what the shell needs; fuller shared widgets come in Phase 2):
- Top bar: brand mark, store select, global search field (`FocusNode` from `SearchFieldController`) with platform-aware shortcut hint and scan button, online chip, notifications popover with badge, profile and kebab menu (same menu opened by both).
- Sidebar: 7 items (POS, Products, Customers, Sales, Returns, Reports, More) with active gradient + 2px bar, hover, focus.
- Offline banner; Bill Summary frame (static layout, correct width on POS vs other pages, no data yet); toast host (above dialogs, via builder); overlay host; placeholder pages for the 7 routes; dark-mode toggle wiring via `SettingsController`; shortcut skeleton (`Shortcuts`/`Actions` above the Navigator, Ctrl and Cmd bindings for K, F2-F6, Esc, Delete) with platform-aware labels.

**Delete in this step (DEC-065):** the TEMPORARY debug token swatch page `lib/core/theme/debug/`, its `?swatch` / `SWATCH` hook in `main.dart`, and `test/golden/specimen_golden_test.dart` plus its goldens (replaced by real shell goldens).

**Order:** top bar -> sidebar -> summary frame -> toast and overlay hosts -> shortcuts -> placeholders -> goldens (reference viewport light for comparison; other sizes and dark as regression).

**Tests:** widget tests for navigation, sidebar active state, theme toggle, both-modifier shortcuts, label per platform, search text/focus surviving navigation, toast above a dialog; goldens as described.

**Done when:**
- [ ] Shell matches the screenshots at the reference viewport; differences listed in the step report
- [ ] Search field text and focus survive navigation; toasts above dialogs
- [ ] Differences/unverified items added to `known_gaps.md`
- [ ] Standard checks pass

---

## After Phase 1
Next: `plan_phase2.md` (shared widgets), written and approved before any Phase 2 work. No Phase 1 implementation starts until the user says go for step 1.1.
