# Migration plan (master, short)

React prototype (`reference_react/`) -> Flutter (`pos_application/`). Phase A = one-time port replicating behavior as-is. Phase B = production development in Flutter only (known gaps fixed). Rules: `CLAUDE.md`. Decisions: `decisions.md`. Gaps: `known_gaps.md`. Prototype inventory: `react_audit.md`. Current detailed plan: `plan_phase1.md`.

Status: plan v2 approved 2026-10-07. Nothing implemented yet.

## How we work
- Every step starts in Plan mode, is approved, runs in its own session (start with `/clear`; read only CLAUDE.md and the current plan file), ends with `dart format .`, `flutter analyze` (0 issues), `flutter test`, a run on macOS and Chrome, and a short report (changes, checks, differences vs React, open questions).
- One commit per step, message proposed by the agent, committed only after the user's OK.
- UI comparison: only at the reference viewport (2124x1180 px, light) against `reference_screenshots/`. Everything else is built from CSS/code and marked unverified in `known_gaps.md`.
- Size guide: S < 40k tokens, M 40-100k, L > 100k (L is always split).

## Phases and steps

| Phase | Step | Goal | Size |
|---|---|---|---|
| 1 | 1.1 | Project setup: packages, assets, skeleton, docs, git init | S |
| 1 | 1.2 | Theme tokens + `css_metrics.md` + golden harness | M |
| 1 | 1.3a | Currency, Money, Qty, Rational, rounding strategy, formatter | M |
| 1 | 1.3b | PricingService (both tax modes) + golden vectors from React | M-L |
| 1 | 1.4a | Routing spike (throwaway) -> decision record | S |
| 1 | 1.4b | LocalStore, AppStrings, routes, responsive core (AppMetrics, ResponsiveLayout) | M |
| 1 | 1.4c | Shell UI: top bar, sidebar, summary frame, toast/overlay hosts, shortcuts, placeholder pages | M-L |
| 2 | 2.1 | Buttons and inputs (incl. hold-to-repeat, quantity input, toggles) | M |
| 2 | 2.2 | Chips, cards, badges, segmented, tooltip, stat tiles | M |
| 2 | 2.3 | Overlays: modal, drawer, confirm, popover, toast with Undo | M |
| 2 | 2.4 | Data table, cart-line row, empty/no-results states | S |
| 3 | 3.1 | Data layer: models, repository interfaces, mocks, seeds for products/customers/sales/held/settings | M |
| 3 | 3.2 | POS: catalog (categories, sub chips, filter, grid/list, product cards, search/scan field) | M |
| 3 | 3.3 | POS: cart (lines, qty/price/discount editing, remove + undo, highlight, actions, stat tiles) | M |
| 3 | 3.4 | POS: bill summary and payment (totals, forex card, member card, cash/card/credit) | M |
| 3 | 3.5 | POS: dialogs (hold/recall, discount drawer, price check, scan simulator, customer picker, add customer, receipt, notes, shortcuts help) | M |
| 3 | 3.6 | Customers | S |
| 3 | 3.7 | Products | S |
| 3 | 3.8 | Sales | S |
| 3 | 3.9 | Returns | M |
| 3 | 3.10 | Reports | S |
| 3 | 3.11 | Settings (More) + shift close + profile + signed-out screen | S |
| 3 | 3.12 | Keyboard and focus pass (all shortcuts, focus return, web checks) | M |
| 4 | 4.1 | Responsive pass: media-query rules vs CSS, tablet checks (adds `ios/` only if approved at that time) | M |
| 4 | 4.2 | Web and Windows prep and review (shortcut conflicts, hover/scroll, platform assumptions) | S |
| 4 | 4.3 | Final comparison, performance run with 10k products, then (with explicit OK) remove `reference_react/` and `reference_screenshots/`, move CLAUDE.md into `pos_application` | S |

Each Phase 2-4 step gets its own `plan_phaseX.md` when we reach it.

## Cross-cutting design (summary; details in decisions.md)
- State/DI/routing: GetX; permanent shared controllers in `InitialBinding`; route-bound controllers via `Get.lazyPut`; dialog-scoped controllers; plain Dart services for pricing, checkout, receipt.
- Money: integer minor units + currency registry + tax config; swappable rounding; golden vectors from React's real `calculate()`.
- Theme: `ThemeData` + `ThemeExtension` (colors, typography, spacing, radii, shadows, sizes, motion) + `AppMetrics` for the prototype's `clamp()`/media-query rules; no hardcoded values in widgets.
- Storage: `LocalStore` (JSON key-value) behind mock repositories; strings in `AppStrings`; hardware and outbound features as interfaces with no-op stubs.
- Performance (sales screen): lazy builders, stable keys, scoped rebuilds per product/line, prebuilt barcode/code indexes, debounced filter, no heavy work in `build`, 10k-product debug dataset.

## Open items carried forward
- Routing option (i) confirmed or changed by spike 1.4a.
- Scale between screenshot pixels and CSS px calibrated in 1.2.
- User reviews `test/fixtures/known_ties.json` after 1.3b generates it.
- iOS added only in Phase 4 if approved.
- Revisit bundling fonts at the start of Phase B (google_fonts 6.3.3 is two majors behind; offline first launch). See DEC-044, DEC-055, KG-078.
