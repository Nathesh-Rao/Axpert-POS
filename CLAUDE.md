# CLAUDE.md: pos_application

## Project

POS (point of sale) application: `pos_application`.

- Phase A (done, git tag `phase-a-complete`): one-time conversion of the React prototype (UI + mechanics) into Flutter. History: `docs/migration_plan.md`, `docs/decisions.md`, `docs/known_gaps.md`.
- Phase B (now): production POS development in Flutter only. Known prototype gaps (`docs/known_gaps.md`, bucketed in `docs/phase_b_backlog.md`) get fixed here.

## Repository layout

- This folder (`pos_application/`) is the Flutter app and the git repo. All code and docs are written here.
- `docs/`: migration_plan.md, plan_*.md, known_gaps.md, decisions.md, phase_b_backlog.md, react_audit.md and css_metrics.md (historical, describe the React prototype), cleanup_checklist.md.
- `tool/web_check/` (browser checks), `tool/golden/` and `tool/compare/` (Phase A tools; they need `reference_react/` and `reference_screenshots/`, which sit next to this folder until the owner deletes them, and stop working after that; the generated fixtures in `test/fixtures` stay).

## Platforms

- Developer machine: macOS. Targets: Windows desktop (final), Web, Tablet (Android/iPad), macOS (local run).
- Windows cannot be built locally. Every package MUST support Windows, macOS and web. Flag any that don't BEFORE adding.
- Shortcuts must work with both Ctrl and Cmd. Displayed labels are platform-aware (Cmd+K on macOS, Ctrl+K elsewhere).
- Target: desktop and tablet landscape. No phone layout, no layout the prototype does not have.

## Working rules (agent behavior)

1. ALWAYS start each task (feature, fix or gap from the backlog) in Plan mode. Present the plan and WAIT for explicit approval once per task before writing code. Checkpoints inside an approved task need no further approval; report at each checkpoint and continue.
2. One task at a time. Never start the next task without approval. Stop and ask at any checkpoint if the plan cannot be followed as written.
3. Be token-economical: read only what you need, never echo large code back, summarize. Read only the files and docs the task needs.
4. Never add a package without asking. Verify Windows + macOS + web support and maintenance on pub.dev first. Desktop-style packages (window managers, menu bars, etc.) always need approval.
5. After every change: `dart format .`, `flutter analyze` (zero issues), `flutter test`.
6. If a requirement is ambiguous or a deviation from the approved plan is needed, STOP and ask.
7. Record decisions in `docs/decisions.md` and prototype gaps in `docs/known_gaps.md`.
8. End each checkpoint with a short report (one line per item) and each task with the full report: what changed, checks run and results, open questions.

## Working rules (standing)

1. Never run Chrome tests (`flutter test --platform chrome`) unless I explicitly ask.
2. After every commit, remind me to fully restart `flutter run` (a hot restart is not enough).
3. Never name a Dart file `*host.dart`.
4. Every commit ends with these two trailers:
   `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`
   `Claude-Session: https://claude.ai/code/session_01Ht6ZfVLgoUbcN2eKphKPqq`
5. The debug click-through starts a fresh `flutter run -d web-server` for every run (one page load per run) and cleans up afterwards: `pkill -f "flutter_tools.snapshot run"; pkill -f "headless=new"`.
6. Look at screenshots and describe them honestly; I am the final visual judge.
7. Plan mode first for any task. No cleanup, tagging or deletion (including `reference_react/` and `reference_screenshots/`) without my explicit OK.

## Change rule (Phase B)

- The port-as-is rule of Phase A is dropped: known gaps are fixed on request, one task at a time. Each fix removes or updates its `KG-` entry, records a `DEC-` entry, updates the tests, fixtures and goldens it changes and says so in the report.
- Behavior that is not part of the task is not changed silently. Tax, discount, points and rounding behavior (see Money rules) changes only on explicit request, with the golden-vector fixtures updated in the same task.
- Where a color is the same in light and dark mode (KG list), do not invent dark variants unless asked.

## Tech rules

- State, routing, DI: GetX. One binding per module, `Get.lazyPut`, named routes via `GetPages`.
- A module may have several single-responsibility controllers (no god controllers). State shared across modules (e.g. the cart, which the Bill Summary shows on every page) lives in permanent controllers registered in an initial binding.
- Null safety, `const` constructors, small focused widgets. No business logic in views.
- Central light/dark theme with `ThemeData` + `ThemeExtension`. No hardcoded colors, text styles, sizes, spacing, radii or shadows in widgets.
- Responsive helper with explicit breakpoints and a `ResponsiveLayout` widget. The prototype's `clamp()/vw/vh` rules and media queries (width 1700/1280/1100, height 960/820/719) are translated into explicit Flutter rules, documented in plan_phase files.
- Fonts: Roboto Condensed via the google_fonts package, accessed ONLY through core/theme/tokens/app_typography.dart (no widget imports google_fonts). Runtime fetching for now; bundling later is a one-file change. See DEC-044.
- Icons: Lucide, via a verified, maintained Flutter package (approval required).
- All user-facing strings in one place (`AppStrings`, parameterized functions, no concatenation in views) so translations can be added later. UI is English only for now.

## Folder structure (feature-first)

```
pos_application/lib/
  core/        theme, constants, utils, services, routes, responsive, mock, bindings
  shared/      shared widgets, shared models
  modules/<feature>/
    controllers/  views/  widgets/  bindings/  models/  repository/
```

## UI rules

- The UI follows the current app. A visual change needs the user's approval; list the changes at the end of each task.
- All spacing, padding, sizes, radii, colors, text styles and shadows come from tokens (AppSpacing, AppSizes, AppCheckoutSizes, AppManagementSizes, `context.colors`, `context.text`). No literals in widgets.
- Layout rules: inside every card at least 8 px padding, at least 4 px between a label and its input, at least 8 px between cards (user-approved S4.a deviations, DEC-099 and DEC-100; every value comes from a token). Paired buttons use `ModalActions`: equal height, the same top and bottom edges and a shared label baseline (DEC-112); do not add per-button margins.
- Goldens (reference viewport, light mode; other sizes and dark mode) are regression tests. A golden is regenerated only for an intended visual change, and the new image is looked at before it is committed. Areas without a golden or a check stay listed as "unverified visually" in `docs/known_gaps.md`; the user is the visual judge.

## Data, mock and storage (no backend yet)

- No HTTP package and no API calls yet.
- Each module has an abstract repository interface plus `MockXRepository` with realistic data and a small simulated delay (200 to 500 ms). Controllers depend ONLY on the interface (injected in the binding).
- Models implement `fromJson` / `toJson`.
- localStorage is replaced by a `LocalStore` interface (JSON key-value) with one implementation behind it, seeded from mock data on first run. Mock repositories persist through it.

## Money, currency and tax rules

- NEVER use `double` for money, quantity, percentages or rates.
- Money = integer minor units with a per-currency exponent (0, 2 or 3 decimals). Never mix currencies. Currency and tax come from configuration per country (Currency registry, TaxConfig: GST/VAT label, inclusive/exclusive mode, rate slabs in basis points). Default config = INR + GST exclusive, which reproduces the prototype.
- Quantity = integer milli-units (3 decimals). Percentages and tax rates = integer basis points.
- Number formatting is per currency/country (INR uses lakh grouping, others thousands grouping).
- Tax, discount, points and total logic lives in ONE plain Dart service (no GetX, no Flutter imports). Rounding is a swappable strategy; the default is prototype-compatible.
- About 300 golden vectors (generated once from the prototype's `calculate()`) are stored as fixtures in `test/fixtures` and asserted in unit tests; they are the regression baseline for the pricing service. Both tax modes are unit-tested. The generators need the React folders and stop working once they are deleted.

## POS and hardware rules

- Sales screen must stay fast with large lists: lazy builders, stable keys, `const` widgets, scoped rebuilds, precomputed search/index maps, no heavy work in `build`.
- Keyboard-first checkout: every core action reachable by keyboard.
- Design for later, interfaces and stubs only now: offline-first local DB, receipt printing (`ReceiptDocument` model + `ReceiptPrinter` interface; build the receipt preview UI), barcode scanner input, cash drawer, payment terminals, beep, email/WhatsApp receipts (demo toasts like the prototype), roles/permissions, shifts, reports, audit logs.

## Plans and docs

- Every plan is saved to `docs/plan_<task>.md` after I approve it, so it survives /clear and is tracked in git. Phase A plans (plan_s1_s2.md to plan_s4_0.md, migration_plan.md) are history.
- At the start of a session, read this file and only the plan file for the current task.

## Verification (every checkpoint)

- `dart format .` clean, `flutter analyze` zero issues, VM tests of the touched module pass (plus `core/pricing` when money code changes); never run Chrome tests (see the testing speed rule at the end)
- New screens: a release build served and checked with `tool/web_check` at 950x733, 1280x720 and 1868x1035 (console and overflow counts, screenshots described)
- Debug-build click-through (standing rule, added after the Reports/Customers "markNeedsBuild() called during build" bug that release builds cannot show): every checkpoint also runs the app in DEBUG mode (`flutter run -d web-server --web-port=<p> --web-hostname=127.0.0.1`, wait for "is being served") and `node --experimental-websocket tool/web_check/debug_check.mjs http://127.0.0.1:<p>/ <outDir>` for the touched screens (the script covers every route and dialog with seeded data; add steps for new screens). Any console error, "setState() or markNeedsBuild()", "EXCEPTION CAUGHT", "Another exception was thrown" or red error screen fails the checkpoint. One `flutter run` serves one page load: start a fresh one per run and stop it afterwards. It runs in TWO modes: normal, and with `--semantics` (web accessibility ON, what pressing Tab at load does); the console must be clean in both (KG-180: Flutter 3.38.4 web semantics engine bug; `test/layout/semantics_reparent_test.dart` is its VM guard and runs with the touched-module tests whenever widget structure changes).
- Route-navigation VM test: `test/layout/route_navigation_test.dart` (real state: cart with items, customer with points, stored sales) is part of every checkpoint's VM tests; add new routes and dialogs to it. It asserts no framework error, no `ErrorWidget` and `RxInterface.proxy == null` after every step.
- Rule for code: never write an observable (Rx value or list, controller method that sets one) during build, in `initState`, in a getter called from `build`, or while a lazily created controller is being created inside build or inside an `Obx`; create page controllers in plain build code; do not hide such errors with try/catch.
- UI changes: goldens regenerated and looked at; anything unverifiable is flagged in `docs/known_gaps.md`

## Git

- One commit per checkpoint (messages like "Fix web semantics assertion"). The agent proposes the message and commits only after my OK. Never commit without telling me.

## Definition of done (per module)

Binding + controllers + view + repository interface + mock repository + models + route registered; no hardcoded styling; strings in AppStrings; responsive per the plan; keyboard support where relevant; analyze clean; tests pass; goldens updated for intended changes; gaps logged.

Testing speed rule: never run `flutter test --platform chrome` (the debug-build browser click-through above is not a Chrome test run and is required). Per checkpoint run only dart format, flutter analyze, VM tests for touched modules (plus core/pricing when money code changes), and the layout matrix for new screens with the smaller sweep (widths 900, 1100, 1280, 1500, 1900 x heights 600, 733, 900, 1000); the full sweep (900-1900 x 600-1000) runs once before a release or when the layout core changes.
Visual checks: release build plus tool/web_check at 950x733, 1280x720 and 1868x1035 for new screens only. The user is the visual judge.
