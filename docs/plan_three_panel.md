# Plan: three-panel POS work area (Products | Cart | Billing)

Branch `integration`, on top of c22de22. axpert_pos and reference_react untouched. No push. Desktop/web only (`!metrics.touch`); touch layout unchanged. No change to cart, pricing, offers or checkout logic. Plan copy goes to `docs/plan_three_panel.md`.

## 0. Starting state (read before approving)
The working tree is DIRTY with changes that are not mine (sidebar sizes in `app_metrics.dart`, `cartFooterHeight` 40 -> 50, `cartRowGap`, cart row/table/footer edits). I build on them and do not revert them. Step 0 of the run: run the golden suite once on the untouched tree. Goldens that already fail there are pre-existing, are listed in the report, and do not trigger the STOP rule. Only a golden outside my list that flips AFTER my changes does. The commit includes the dirty files I also touch (cart_footer, cart_compact_*, app_density_sizes) because they cannot be split cleanly; say so in the report.

## 1. Model
`PosWorkViewController` (existing, permanent) becomes the layout controller. A pure Dart `PosPanelLayout` (new, `modules/pos/models/`, no Flutter) holds the math.

- `ProductsStep { off=0, narrow=25, wide=75 }`, `billingOpen` (bool). Cart share = remainder.
- State: `chosen` (products step, billing) = what the user picked; `lastCart` = last (products, billing) with products <= 25 (default P0/B25); `effective` = what is drawn.
- `effective`: cart empty -> products forced to 75 (billing keeps its state); else `chosen`. Then fitted to the window (section 3).
- "P75" below = catalog-dominant layout (cart 0% or 25%). Rules 3 and 4 use it, not only the cart-0% case.

## 2. Width math (desktop, W = window width)
Page area = W - sidebar (80, or 64 at W <= 1280) - 16 (rail gap) - 16 (right padding) - billing - 16 (gap) when billing is open.
Billing open width = `summaryWidth(isPos: true)` (clamp(300, 24vw, 380)), unchanged. This is the nominal "25%": it must stay as today so the default looks identical. Real ratio at 1280 is 26%, at 1868 it is 21%. Panel tests therefore check the products : cart ratio, not billing against 25% of the window.
Panels share U = page area - 36 (edge control) - 8 (its gap) and, when products and cart are both visible, a further 16 gap.

| State | Products | Cart | Billing | Note |
|---|---|---|---|---|
| P0/B25 | 0 | U | open | cart "75%", today's cart view |
| P25/B25 | U/3 | 2U/3 | open | NEW, all three |
| P75/B25 | U | 0 | open | today's catalog view |
| P0/B0 | 0 | U | 0 | cart 100% |
| P25/B0 | U/4 | 3U/4 | 0 | |
| P75/B0 | 3U/4 | U/4 | 0 | |

Examples (U after gaps): 1280x720 P25/B25: products 267, cart 534. 1868x1035: products 433, cart 867. 1280 P25/B0: 281 / 843. 1868 P75/B0: cart about 330.

## 3. Thresholds and fallback (rule 6)
Tokens in `AppDensitySizes` (names: `cartMinWide` 480, `cartMinNarrow` 280, `productsMinNarrow` 248 = 2 compact columns + panel padding).
- Cart visible at 50% or more (P25/B25, P25/B0, P0/B0): cart >= 480.
- Cart at 25% (P75/B0): cart >= 280.
- P0/B25 (cart 75%, today's default) is exempt from the 480 rule, so the default look does not change at 900 to 935 px. Flag: applying 480 literally would auto-collapse Billing below W about 936, which changes today's default at those sizes. I propose the exemption and list it in decisions.
- P75/B25 always fits (cart 0).
- Billing never gets narrower than its current width.
- Resulting thresholds: P25/B25 needs W >= about 1195. P25/B0 needs W >= about 700. P0/B0 always fits. P75/B0 needs W >= about 1200 (cart 280).
- Fallback loop: while not fitting: billing open -> close it; else products 75 -> 25 -> 0. The preference in `chosen` is never overwritten by a fallback. Example: P25/B25 at 950 shows P25/B0; widening the window brings the stored layout back.
- Cycling and chevrons skip steps that resolve to the same effective layout.

## 4. Controls
**Edge control** (replaces `WorkTab`, same 36 px column and card style, new widget `ProductsEdgeControl`):
```
 +--+
 | >|  wider   (chevron-right, disabled at 75)
 | <|  narrower (chevron-left, disabled at 0)
 | .|  3 step dots: 0 / 25 / 75, current filled
 |[]|  cart icon + count badge (flashes on tile add at P75)
 | P|  rotated label "Products" (P75 with items: "Cart (n)")
 | r|  + chip "Ctrl B" / "Cmd B"
 +--+
```
- Chevrons set the step exactly. Clicking the body, or Ctrl/Cmd+B, cycles 0 -> 25 -> 75 -> 0. At P75 with items the body click goes back to `lastCart`, as the tab does today.
- Disabled (greyed, as today) while the cart is empty.
- Semantics per button: "Make products wider (now 25%)", "Make products narrower", "Resize products, Ctrl+B". Tooltips carry the key. The visible hint is the chip plus the step dots.
- Focus after a change: P75 -> search box, otherwise the cart list (`cartFocus`), as today.

**Billing**
- Collapse button (panel-right-close icon) at the right end of the Bill Summary title row, POS page only. Tooltip and semantics include the shortcut.
- Footer chip (`BillingTotalChip`, in `CartFooter`, only when billing is closed): bold invoice total from `PaymentController.total` (same data as the Bill Summary), `MoneyFormatter`, with a chevron icon. Tap or Enter expands Billing to 25%. Semantics: "Invoice total 1,234.00. Show billing".
- Footer below about 360 px inner width (cart at 25%, P75/B0 at 1280): two rows (row 1: totals plus chip, row 2: four icon actions). New token `cartFooterHeightStacked`. At and above 360 it is the current single row, so default goldens are unchanged.
- **Shortcut: Ctrl/Cmd+. (period)**, `ShortcutAction.toggleBilling`.
  - Existing shortcuts: Ctrl/Cmd+K (search), Ctrl/Cmd+B (products cycle), F2 cash, F3 card, F4 hold, F5 recall, F6 discount, Esc, Delete, Enter in search.
  - Browser clashes avoided: Ctrl+J, Ctrl+Shift+B, Ctrl+D, Ctrl+L, Ctrl+M (Cmd+M minimizes on macOS), Ctrl+\ (needs AltGr on some layouts).
  - `Ctrl/Cmd+.` has no binding in Chrome, Edge, Firefox or Safari-less Flutter web. The release check confirms the key reaches the app.
  - Added to `AppShortcuts.bindings` and to `ShortcutHelp` (new row, "Show or hide Billing"; the Ctrl+B row text becomes "Resize Products (0, 25, 75%)"). The existing test that every help key has a binding covers it.
- Pay shortcuts F2 and F3 (and the footer's payment path): handlers call `work.openBilling()` first, then `payment()` as today. Billing unhides (focus, pointer, semantics) from the first frame of the animation so the 40 ms tendered-field focus still lands.

## 5. Automatic rules (supersede DEC-139/140; new DEC-141)
1. Cart becomes empty (clear, checkout complete, last bill held, last line removed) -> effective products 75. Billing untouched. `lastCart` is kept.
2. First add to an empty cart, by any route -> `lastCart` layout. If the user changed Billing meanwhile it uses the current Billing, and a P75/B25 pair (cart 0) is replaced by P0.
3. Cart visible (not P75): tile clicks add and stay. P75: a top-search or scanner add switches to `lastCart`. A tile click adds and stays, and the edge control flashes the count. A recalled held bill switches to `lastCart`.
4. Esc: dialogs and menus first, else from P75 with items -> `lastCart` (this counts as a user choice and is persisted), else nothing.
5. Persistence: the user's own actions (chevrons, cycle, collapse button, chip, shortcuts, Esc) write `posProductsStep` and `posBillingOpen` through `SettingsController` (`AppSettings` + `StorageKeys` + repository list), per device, view preference only. The empty-cart override and window fallback never write. Loaded in `loadData` before `runApp`. Old rows are unaffected.
6. Narrow windows: section 3.

## 6. Animation and mounting
`_WorkArea` generalizes to three slots (Products, Cart, Billing) driven by a `TweenAnimationBuilder` over three animated widths (180 ms `AppMotion.buttonMs`, 0 under `disableAnimations`). Each panel is laid out at its target width inside an `Align(widthFactor)` plus `ClipRect`. A closed panel (width 0) is `IgnorePointer`, `ExcludeFocus`, `ExcludeSemantics` and `TickerMode(false)` but stays mounted. The catalog keeps its scroll and search text, and the cart keeps its scroll. Billing moves from `AppShell` into the POS page region on POS only (other pages keep the 310 px frame), so `AppShell` gets a `billing` slot for POS.

## 7. Narrow content
- **Catalog at 25%:** `ProductGrid` gets a compact mode when the panel is narrower than the normal two-column minimum: 1 to 2 columns, `compactColumnMin` token (104), max 2 at 25%. `CatalogProductCard` gets a compact variant (same badges: discount, Buy 1 Get 1, Free gift; price; stock state; image shrinks, name 2 lines). Search and category chips already scroll. The catalog header with customer chip and sale toggle stays hidden with items, as today. No overflow at 248 px.
- **Cart columns:** `CartCompactColumns` gets a third tier `veryNarrow` below `cartVeryNarrowBreak` (440): item, qty (compact stepper 72), total (64), delete (24), no discount or price columns (these stay on the 2nd line as at the narrow tier). Tiers: >= 640 full, 440 to 640 existing narrow, < 440 very narrow. Minimums: 25% = 280 panel (inner about 248, item about 76 px), 50% >= 480, 75% and 100% fill. `CartCompactHead`, row and gift row read the same instance.

## 8. Files
New: `modules/pos/models/pos_panel_layout.dart` (pure math, fit and fallback), `modules/pos/widgets/products_edge_control.dart`, `billing_total_chip.dart`, `docs/plan_three_panel.md`, tests below, `tool/web_check/three_panel_check.mjs` (extends `work_view_check.mjs`).
Changed: `pos_work_view_controller.dart`, `pos_view.dart`, `modules/shell/views/app_shell.dart`, `bill_summary_frame.dart`, `desktop_cart_column.dart`, `cart_footer.dart`, `cart_compact_columns.dart`/`_head`/`_row`/`_gift_row`/`_table`, `catalog_panel.dart`, `product_grid.dart`, `catalog_product_card.dart`, `app_shortcuts.dart`, `shortcut_controller.dart`, `shortcut_help.dart`, `initial_binding.dart` (handlers: F2/F3 open Billing, toggleBilling), `global_search_controller`/`scan_controller`/`hold_recall_controller` (unchanged call `showCart()`, now means `lastCart`), settings model/keys/controller/repository, `app_density_sizes.dart`, `app_strings.dart` + `en_app_strings.dart`, `app_icons.dart` (chevrons, panel-right-close if missing in the Lucide set already used), docs (`decisions.md` DEC-141 supersedes DEC-139/140, `known_gaps.md`, `docs/integration/progress.md`). Deleted: `work_tab.dart` (replaced). No package added.

## 9. Tests
- `test/modules/pos/three_panel_layout_test.dart` (new): `PosPanelLayout` units (widths for all six states, thresholds, fallback order, cycle skipping); widget tests for all six states at 1280x720, 1440x900, 1868x1035, light and dark: no overflow, products : cart ratio within 1 px, Billing width equals `summaryWidth`, chip visible when Billing is 0, tap on the chip opens Billing, the collapse button closes it, Ctrl and Cmd + `.`, Ctrl and Cmd + B cycle, F2 with Billing closed opens it then shows the cash panel, rules 1 to 6 transitions (empty-cart override with billing kept, first add, search add at P75, tile add pulse, Esc order, persistence write and reload, fallback at 950 and 1100 keeps the stored preference), instant transition under `disableAnimations`.
- Update: `desktop_work_view_test`, `desktop_cart_layout_test`, `desktop_cart_rows_test` (very narrow tier, 280 and 480), settings tests (two new keys), shortcut help tests, `route_navigation_test` (new states), `semantics_reparent_test`.
- Goldens: all POS goldens change only in the edge-control strip (x: rail + 16, width 36, full panel height) and the Bill Summary title row (right 40 px). List: `shell_pos_*`, `pos_one_line_*`, `offers_cart_*`, `offers_tiles_*`, `cart_density_*`, `summary_*`, and dialog goldens drawn over POS (`add_customer`, `counter_dialog`, `customer_picker`, `dialog_profile`, `dialog_shift_close`, `discount_drawer`, `price_check`, `recall_dialog`, `receipt*`, `reprint`, `scan_dialog`, `search_results`, `shell_dialog_toast`, `shortcuts`; the `shortcuts` golden also gains the new row). Each is regenerated one by one with its measured diff box. NEW goldens: P25/B25 and Billing-collapsed (chip visible) at 1280x720 and 1868x1035 light, and dark at 1280x720. Non-POS page goldens (Customers, Products, Sales, Reports, Returns, Settings) must stay byte-identical, otherwise STOP.

## 10. Verification order
`dart format .`, `flutter analyze` (zero issues), tests per touched folder (`test/modules/pos`, `test/core`, `test/modules/shell`, `test/layout`, goldens), then the full VM suite once at the end (no Chrome tests). Debug click-through, normal and `--semantics`, via `debug_check.mjs` (new steps: cycle products, collapse and expand billing, F2 with billing closed). Release web check with DEMO_SEED (cashier1) at 1280x720 and 1868x1035: cycle all six states, tile clicks at P25, add via search, collapse and expand Billing from the footer chip, cash checkout with Billing collapsed then expanded. Screenshots of all six states at both sizes to `docs/integration/screens/three_panel/`, and I view each one.

## 11. Commit and report
One commit, message exactly:
```
Add three-panel POS layout with collapsible products and billing
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Ht6ZfVLgoUbcN2eKphKPqq
```
Final report: states, thresholds, shortcuts, goldens changed, screenshot paths, known gaps (stop rules: unrelated golden change, package needed, or a state unreadable at the thresholds).

## Decisions to flag
- Billing "25%" is its current clamp width, not a literal 25% of the window.
- P0/B25 is exempt from the 480 minimum.
- Ctrl/Cmd+B wraps 75 -> 0.
- "P75" covers cart 0% and 25%.
