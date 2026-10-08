# Migration plan (master, short)

React prototype (`reference_react/`) -> Flutter (`pos_application/`). Phase A = one-time port replicating behavior as-is. Phase B = production development in Flutter only (known gaps fixed). Rules: `CLAUDE.md`. Decisions: `decisions.md`. Gaps: `known_gaps.md`. Prototype inventory: `react_audit.md`. Current detailed plan: `plan_s1_s2.md`.

Status: 7 large steps (DEC-069, 2026-10-08). Done: S1 Money, S2 Shell, S3 POS core (S3.a-d, see `plan_s3.md`). S4.0 Narrow-window cart layout and density (see `plan_s4_0.md`). Next: S4 POS checkout (not started).

## How we work
- Each STEP is planned in Plan mode and approved once. Checkpoints inside an approved step need no extra approval; each ends with a short report and a commit (message proposed, committed after the user's OK).
- One session per step: `/clear` between steps; `/compact` only at the marked points. Read only CLAUDE.md and the current plan file.
- Every checkpoint (from S5, user decision, DEC-104): `dart format .`, `flutter analyze` (0 issues), VM tests of the touched module (plus `core/pricing` for money code), the smaller layout matrix for new screens (widths 900/1100/1280/1500/1900 x heights 600/733/900/1000), release build + `tool/web_check` at 950x733, 1280x720 and 1868x1035 for new screens. Never Chrome tests. The full layout sweep runs once in S7.
- **A build is not a run (DEC-079).** Every checkpoint includes a real Chrome run that reads the console: `flutter run -d chrome` (debug, DDC; add `--web-browser-flag=--headless=new` when no window is wanted, errors then print in the terminal) AND `flutter build web` served locally with an SPA fallback and opened in headless Chrome (`--enable-logging=stderr --screenshot=...`, deep link such as `/customers` included). The report states what was seen in the console and what could not be seen.
- Real interactions in Chrome: `tool/web_check/` (clicks, typing, screenshots, console; DEC-090).
- UI comparison: only at the reference viewport (2124x1180 px, light) against `reference_screenshots/`. Everything else is built from CSS/code and marked unverified in `known_gaps.md`.
- Size guide: S < 40k tokens, M 40-100k, L > 100k.

## Steps and checkpoints

| Step | Goal | Checkpoints (commit points) | Size | `/compact` | User provides |
|---|---|---|---|---|---|
| S1 Money | Currency registry, Money/Qty/Bp, rounding, formatter, PricingService (both tax modes), ~300 golden vectors from React `calculate()` | S1.a types + formatter; S1.b golden vectors + exclusive mode; S1.c inclusive mode + helpers | L | after S1.b | npx esbuild OK (DEC-053) |
| S2 Shell | LocalStore, AppStrings, 7 routes (+ fall-through to POS), AppMetrics, ResponsiveLayout, top bar, sidebar, summary frame, toast/overlay hosts, shortcuts, theme toggle; delete swatch page (DEC-065) | S2.a foundations; S2.b responsive core + top bar/sidebar; S2.c frame + hosts; S2.d shortcuts, theme toggle, cleanup, goldens | L | after S2.b | nothing blocking |
| S3 POS core | Models, repository interfaces, mocks, controllers, catalog, cart table with editing and Undo | S3.a data; S3.b catalog; S3.c cart table; S3.d controllers + compare | L | after S3.b | nothing blocking |
| S4 POS checkout | Bill summary totals, cash/card/credit, hold/recall, discount drawer, price check, scan simulator, customer picker, add customer, receipt preview, note, rename, shortcuts help | S4.a totals + payment; S4.b hold/recall, discount, note; S4.c pickers; S4.d receipt + help | L | after S4.b | optional screenshots of drawer, receipt, picker |
| S5 Secondary pages | Products, Customers, Sales, Reports, Settings, profile, shift close, signed-out | S5.a Products + Customers; S5.b Sales + Reports; S5.c Settings + profile + shift close + signed-out | L | after S5.b | optional screenshots of Settings, shift, signed-out |
| S6 Returns and keyboard | Returns flow; shortcut and focus-return pass; web key-conflict check | S6.a Returns; S6.b shortcuts + focus; S6.c web key conflicts | M-L | after S6.a | nothing blocking |
| S7 Polish | Responsive pass, web and Windows review, 10k-product performance, final comparison, cleanup | S7.a responsive; S7.b web/Windows review; S7.c performance; S7.d final comparison + cleanup | L | after S7.b | side-by-side React check; explicit OK for cleanup |

Only S1 and S2 are detailed (`plan_s1_s2.md`). S3 to S7 get their own detailed plan when reached.

## Cross-cutting design (summary; details in decisions.md)
- State/DI/routing: GetX; permanent shared controllers in `InitialBinding`; route-bound controllers via `Get.lazyPut`; dialog-scoped controllers; plain Dart services for pricing, checkout, receipt. Routing option (i), per-page `AppShell` wrapper (DEC-041, final).
- Money: integer minor units + currency registry + tax config; swappable rounding; golden vectors from React's real `calculate()`.
- Theme: `ThemeData` + `ThemeExtension` (colors, typography, spacing, radii, shadows, sizes, motion) + `AppMetrics` for the prototype's `clamp()`/media-query rules; no hardcoded values in widgets.
- Storage: `LocalStore` (JSON key-value) behind mock repositories; strings in `AppStrings`; hardware and outbound features as interfaces with no-op stubs.
- Performance (sales screen): lazy builders, stable keys, scoped rebuilds, prebuilt indexes, debounced filter, no heavy work in `build`, 10k-product debug dataset.

## Deferred or dropped (see DEC-069)
Routing spike (dropped); web key-default check (S6.c, KG-015); tie review and 2000 vectors (KG-079); Phase 2 shared-widget block (KG-080, KG-081); iOS only if approved in S7; font bundling in Phase B (KG-078, DEC-044, DEC-055).

## Open items carried forward
- Scale between screenshot pixels and CSS px is calibrated (1.125, DEC-062).
- Revisit bundling fonts at the start of Phase B (KG-078).
