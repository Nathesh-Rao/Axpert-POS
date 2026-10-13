# Plan: cart-first POS layout (collapsible Products panel, slim footer, compact rows)

Branch `integration` on top of e649a63. axpert_pos, reference_react untouched. No push. Copy of this plan goes to `docs/plan_cart_density.md`. No change to cart, pricing, offers or checkout logic.

## Context and BEFORE reference
`reference_screenshots/current_pos_layout.png` (1586x992, an older build: no catalog column, five footer buttons incl. More): rows are ~95 px tall bordered cards (thumbnail 64, qty stepper, two boxed inputs, trash), footer = dashed bar with 5 big buttons, 6 rows visible. In the CURRENT code (checked) the POS page is catalog (flex 2) + cart (flex 3) + Bill Summary; width <= 1700 uses the "stacked" row (qty and inputs on a second line with labels, ~140 px per row); the cart panel ends with a 4-button bar (`CartActionsBar`, 44 px + 12 margin) and the three `StatTiles` (~90 px). Rows visible with 10 items will be measured in step 0 (BEFORE numbers) with a layout test and with release screenshots.

```
BEFORE (desktop)                                  AFTER (desktop, panel collapsed = default)
+--+----------+---------------+--------+         +--+--+-----------------------------+--------+
|SB| catalog  | heading       |  Bill  |         |SB|P | heading  C1 [Cash][Credit] ..|  Bill  |
|  | (2fr)    | customer      | Summary|         |  |r | customer                    | Summary|
|  | tiles    | table head    |        |         |  |o | # | item   qty  price d% tot|        |
|  |          | 140px cards   | (same) |         |  |d |---+---------------------48px-|(same,  |
|  |          | ...           |        |         |  |u | 1 |[ ] Pepsi  -1+  40  0 40 |  25%)  |
|  |          | actions bar   |        |         |  |c | ...12+ rows visible         |        |
|  |          | 3 stat tiles  |        |         |  |t |---------------------------- |        |
+--+----------+---------------+--------+         |  |s | 6 items 7.000 qty ₹360 | Clear Hold Recall Price | 
                                                  +--+--+-----------------------------+--------+
Expanded (Ctrl/Cmd+B): [Products panel 320-460 px, pushes the cart] [cart narrower: compact mode]
```

## 1. Where "desktop" and "tablet" split
- No such split exists today (only width breakpoints 1700/1280/1100, "no phone layout"). New flag `AppMetrics.touch` (true when `defaultTargetPlatform` is Android or iOS; a browser on an iPad reports iOS). Touch keeps TODAY's layout, rows, footer and 44 px targets unchanged; everything below applies when `touch` is false (Windows, macOS, Linux, desktop browsers). Unverified: iPad Safari "desktop site" mode and Windows touch laptops (they get the desktop layout).
- Consequence for tests: `flutter_test` defaults to Android, so all existing tests keep exercising the touch (= current) layout and stay green; the desktop layout is tested with `debugDefaultTargetPlatformOverride = macOS/windows` (the golden tests already set macOS, so POS goldens switch to the new layout, nothing else does).

## 2. Layout (desktop)
- `PosView` (desktop): `Row[ ProductsTab | AnimatedPanel(CatalogPanel, 0 when collapsed) | Expanded(CenterColumn) ]` inside the existing work area; Bill Summary frame, sidebar and top bar unchanged. The cart column is ALWAYS present on desktop (also with an empty cart: heading, customer row, empty table with the hint "Scan a barcode, search, or open Products (Ctrl/Cmd+B)" and an Open Products button); the catalog's own empty-cart header is not shown on desktop.
- `ProductsTab`: slim vertical button on the left edge of the work area, width `AppSizes.productsTabWidth` = 36, full height, panel colors/radius from tokens, icon + rotated "Products" + a small shortcut chip (`Ctrl B` or `Cmd B`, platform aware like the existing Ctrl/Cmd K chip). Tooltip + semantics "Products, press Ctrl+B". Tab order: first in the page.
- Expanded: PUSH, not overlay. Why: the point of opening it is to add items while watching the cart grow; an overlay would hide the left part of the cart (names) exactly where the new row appears, and pushing keeps focus order simple. Width = clamp 320..460 of the work area (`AppSizes.productsPanelMin/Max`, 34 %), animated (`AppMotion`, zero with disableAnimations). The cart switches to "narrow compact" when its width < `AppSizes.cartNarrowBreak` (640): thumbnail and the barcode part of the second line are hidden, inputs shrink. The catalog grid is fixed to 2 columns while pushed.
- Close: tab, Ctrl/Cmd+B again, or Escape (Escape order unchanged: a dialog/menu closes first; with none open it collapses the panel and refocuses search). Adding from the panel works as today; focus returns to the search box (existing behavior).
- Shortcut: **Ctrl+B / Cmd+B** (`ShortcutAction.productsPanel`, fires everywhere like Ctrl+K, no-op on touch). Existing shortcuts: Ctrl/Cmd+K (focus search), F2 cash, F3 card, F4 hold, F5 recall, F6 discount, Esc (close dialog/menu), Delete (remove selected line, not while typing). Browser check: Chrome and Edge have no default for Ctrl+B, Firefox opens the bookmarks sidebar (prevented by the engine, to be confirmed in a real browser: unverified), Cmd+B is free in Safari/Chrome on macOS. Listed in the Keyboard shortcuts dialog (a test already requires help rows to be real bindings).
- View preference: `AppSettings.productsPanelOpen` (bool, default false), key `products_panel_open` in the existing `settings` table through `SettingsController.setProductsPanelOpen`; `ProductsPanelController` (permanent) reads it at start. Not business data; no sync.
- Search/barcode with the panel collapsed: unchanged path (top box and scanner -> `GlobalSearchController` -> cart). Verified by a widget test and by the release check (10+ items added by barcode with the panel collapsed).

## 3. Cart footer (desktop)
`CartFooter` replaces `CartActionsBar` + `StatTiles`: ONE row, height `AppSizes.cartFooterHeight` = 40 (+ `AppSpacing` 8 above, 1 px hairline): left = totals line from the same `cart.totals` (items, quantity with `QtyFormatter`, value with `MoneyFormatter`; small icon + number each, labelled by tooltip/semantics "Total items/qty/value"; value uses `AppIcons.currencyGlyph` or the symbol text from the last fix); right = Clear Cart, Hold, Recall, Price Check as compact icon+label buttons (`ActionButton` with a new `dense` height 36, same tones, F-key hint in the tooltip: Hold F4, Recall F5). When the cart is narrower than 640 the labels collapse to icons (semantics keep the text). Heading, sale toggle, time and "..." order menu are unchanged. Touch keeps StatTiles + CartActionsBar.

## 4. Cart rows (desktop)
One layout for every width (replaces the wide/stacked pair on desktop): `CartCompactRow`, height `AppSizes.cartRowHeight` = 48, hairline bottom divider (`c.border`, `AppSizes.hairline`), no card border/shadow/margin; hover = `c.secondary`, selected = existing `selectedLineBg` with a 2 px left accent in `selectedLineBorder`; newly added highlight kept. Columns shared by head and rows through one list (`CartCompactColumns` in `AppMetrics`, widths in `AppSizes`): `# 28 | thumb 36 (34 px image, hidden when narrow or height <= 719) | item flex | qty 112 (stepper 28 px buttons, quantity field) | price 84 | disc % 64 | total 96 right | delete 32`, gaps 8; price/disc inputs 30 px high; numbers right aligned in the head too; the total never ellipsizes (min width via `FittedBox`). Item cell: name on line one (14 px semibold, ellipsis), line two (12 px muted): barcode, `GST 18%` (label from the regime), and the offer text in the offer accent (`Oreo Buy 1 Get 1 · saved ₹35.00`; discounted unit price shown struck-through in the price cell's tooltip and in the second line when there is room). Gift rows (`CartCompactGiftRow`): same 48 px, locked = lock icon + "Add ₹X more to unlock" muted, unlocked = gift icon + "Free gift" label + FREE value, not editable, no delete. Keep: hold-to-repeat qty buttons, hover/focus rings, disabled states, keyboard navigation (Tab order per row, Delete), Semantics labels, `findChildIndexCallback`, line-id keyed rebuilds. 44 px hit areas stay on touch only (the 28-36 px desktop targets get a 44 px invisible hit slop only on touch).
- Capacity targets: window 1280x720 -> cart panel ~632 px high; fixed chrome (padding 32 + heading ~40 + customer ~60 + head 28 + gaps 16 + footer ~52) ~ 228 -> about 404 px of rows = **8 rows** (8 x 48 = 384). Window 1868x1035 -> ~930 px panel -> about 688 px = **14 rows**. If 8 rows at 720 is missed by a few px I tighten only the customer caption/margins (pre-approved), and report the measured numbers either way.

## 5. Tokens and metrics
New in `app_sizes.dart` (and its token map): `cartRowHeight 48`, `cartRowThumb 34`, `cartFooterHeight 40`, `cartCompactQtyWidth 112`, `cartCompactPriceWidth 84`, `cartCompactDiscWidth 64`, `cartCompactTotalWidth 96`, `cartCompactIndexWidth 28`, `cartCompactDeleteWidth 32`, `productsTabWidth 36`, `productsPanelMin 320`, `productsPanelMax 460`, `cartNarrowBreak 640`, `hairline 1`. Colors, radii, text styles, motion and spacing all reuse existing tokens; no literals in widgets. `AppMetrics`: `touch`, `cartCompactColumns`, `showCompactThumb`.

## 6. Files
New: `lib/modules/pos/widgets/{products_tab,cart_compact_row,cart_compact_gift_row,cart_compact_head,cart_footer,cart_empty_state}.dart`, `lib/modules/pos/controllers/products_panel_controller.dart`, `tool/web_check/cart_density_shots.mjs`, `docs/plan_cart_density.md`, tests below.
Changed: `modules/pos/views/pos_view.dart`, `center_column.dart`, `cart_table.dart` (desktop branch), `catalog_panel.dart` (no empty header on desktop, 2-column grid when pushed), `core/responsive/{app_metrics,app_metrics_scope}.dart`, `core/theme/tokens/app_sizes.dart`, `shared/widgets/action_button.dart` (dense), `core/shortcuts/{app_shortcuts,shortcut_controller,shortcut_help}.dart`, `shared/controllers` Escape handler, `modules/shell/models/app_settings.dart` + `storage_keys.dart` + `settings_controller.dart` + settings repository key list, `core/constants/{app_strings,en_app_strings}.dart`, `core/bindings/initial_binding.dart`, `tool/web_check/{debug_check,demo_check}.mjs` (coordinates), docs (decisions DEC-138, known_gaps, progress). Touch code paths (`cart_line_row.dart`, `cart_gift_row.dart`, `cart_actions_bar.dart`, `stat_tiles.dart`) stay as they are, except sharing small helpers (qty control, trash button) with a `dense` flag.

## 7. Tests
- Layout (desktop override, light and dark, no overflow): collapsed and expanded states at 950x733, 1280x720, 1868x1035; row height = 48 and rows visible with 14 lines >= 8 at 1280x720 and >= 12 at 1868x1035 (the numbers are printed and reported); footer height <= 44; head and rows share column x positions; total text never ellipsized; empty-cart state.
- Behavior: Ctrl+B and Cmd+B toggle, Esc order (dialog first, then panel), tab click toggles, preference persists across a rebuilt controller, add from panel adds one line and refocuses search, barcode/search add with the panel collapsed, locked and unlocked gift rows, BOGO row, hold/recall and checkout through the desktop layout (the existing flow tests re-run with the macOS override), selection + Delete, qty hold-to-repeat in the compact row, semantics labels, route navigation test run with the desktop override too.
- Touch regression: the existing suite (Android default) must pass untouched.
- Goldens: ONLY goldens that draw the POS page, cart or products panel regenerate (expected: `shell_pos_*`, `pos_one_line_*`, `offers_*`, the dialogs drawn over the POS page, `receipt_*`/`reprint`/`price_check`/`scan`/`recall`/`search_results`/`shortcuts`/`shell_dialog_toast`, `summary_vat_*`/`summary_no_forex_*`); each is listed with a measured diff box and must differ only in the work area (between sidebar and Bill Summary) or behind a dialog. New goldens: cart-first desktop at 1280x720 and the reference viewport, collapsed and expanded, light and dark. Customers, Products, Sales, Reports, Returns, Settings page goldens must stay byte-identical: if any other golden changes I STOP.

## 8. Order of work and checks
0. BEFORE: release web build (DEMO_SEED, cashier1) and `cart_density_shots.mjs`: 10+ items by barcode incl. Oreo (Buy 1 Get 1), a discount line and the free-gift tier; screenshots at 950x733, 1280x720, 1868x1035, light and dark (6) -> `docs/integration/screens/cart_density/before_*.png`; rows visible measured by a layout test on the current layout. View them.
1. Settings key, controller, shortcut, strings, tokens, metrics (`touch`). 2. Products tab and PosView desktop branch. 3. Footer. 4. Compact rows, head, gift rows, empty state. 5. Tests and goldens. 6. `dart format`, `flutter analyze`, tests per touched folder, full VM suite once, debug click-through normal and `--semantics` (coordinates updated), release check: add 10+ items (BOGO + gift tier), hold, recall, checkout, Ctrl+B open/close, Esc. 7. AFTER screenshots (same 6), viewed, saved as `after_*.png`. 8. Docs and commit (message exactly as specified below).

Commit message:
```
Cart-first POS layout with collapsible products panel
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Ht6ZfVLgoUbcN2eKphKPqq
```
Final report (short): layout changes, rows visible before vs after, goldens regenerated, before/after screenshot paths, known gaps.

## Open points settled here (tell me if you disagree)
- Desktop vs tablet = platform (Android/iOS = touch), not width.
- Empty cart on desktop shows the cart column with an empty state (the catalog no longer fills the page by default).
- Push (not overlay) for the expanded panel; Ctrl/Cmd+B as the shortcut.
- The footer drops the three stat tiles in favor of one totals line (same data).
## Stop rules
An unrelated golden changes; a package is needed (none planned); the collapse/shortcut design conflicts with existing behavior in a way not settled above.
