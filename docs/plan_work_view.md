# Plan: POS work area shows ONE view at a time (catalog or cart)

Branch `integration` on top of 9c0af52. axpert_pos, reference_react untouched. No push. Copy of this plan: `docs/plan_work_view.md`. Desktop/web only; touch layouts unchanged. No change to cart, pricing, offers, checkout or the Bill Summary.

## Behavior (derived, nothing persisted)
`PosWorkViewController` (replaces `ProductsPanelController`) exposes `view` = CATALOG when the cart is empty, otherwise the user's choice (`chosen`, default CART).

| Event | Result |
|---|---|
| start, clear cart, checkout completes, last bill held, last line removed | cart empty -> CATALOG (chosen reset by `ever(cart.active)`) |
| add via top search/barcode box (pick, Enter, scan simulator, random scan) | `showCart()` -> CART |
| click a product tile (`catalog_product_card` onAdd) | `addFromCatalog`: if the add succeeded (`CartActionsController.add` returns bool) chosen = CATALOG, tab count updates, tab pulses once; stays in CATALOG (several picks in a row) |
| recall a held bill | `showCart()` |
| edge tab click, Ctrl+B / Cmd+B | toggle CATALOG <-> CART; no-op (tab shown disabled) while the cart is empty |
| Esc | dialog or menu first; else CATALOG with items -> CART; empty cart: nothing |
Focus after a switch (post-frame): CATALOG -> search box (`SearchFieldController.refocus`); CART -> a `FocusNode` on the cart list (`cartFocus`, held by the controller, attached by `CartCompactTable`).

## Layout
- `_DesktopPos` = `Row[ WorkTab (36 px, same place and style), gap, Expanded(_WorkArea) ]`. The push/overlay code, the panel width tokens and `cartMinWidth` are deleted.
- `_WorkArea`: a `TweenAnimationBuilder<double>` t (1 = catalog, 0 = cart) over the full work width W: catalog pane = `ClipRect(Align(left, widthFactor t, SizedBox(W, catalog)))`, cart pane = `ClipRect(Align(right, widthFactor 1-t, SizedBox(W, cart)))` in a Row. So the work area expands/shrinks smoothly with no reflow of the content (clipping only), duration `AppMotion.buttonMs` (180), zero under `disableAnimations`. Both panes stay mounted (catalog scroll, category and search text survive switching; this supersedes KG-225); the hidden one gets `IgnorePointer`, `ExcludeFocus`, `ExcludeSemantics` and `TickerMode(false)` once t reaches 0.
- CATALOG view = `CatalogPanel` over the whole 75 % (grid uses the extra width; with an empty cart it keeps the prototype header with customer and sale type, restored by reverting last commit's `|| !m.touch` line; with items the header stays hidden as before). CART view = `DesktopCartColumn` (compact rows, slim footer) over the whole 75 %.
- Tab (`WorkTab`, replaces `ProductsTab`): CATALOG view reads `Cart (n)` (n = `cart.totals.items`) with a count badge on the cart icon and a one-shot highlight (`pulse` counter, `AppMotion.highlightMs`, `c.highlightBg`); CART view reads `Products` with the grid icon; both show the `Ctrl B`/`⌘B` chip; semantics: "Show the cart, n items, press Ctrl+B" / "Show products, press Ctrl+B" / "Cart, empty".
- Removed: `CartEmptyState` and its strings, `AppSettings.productsPanelOpen`, `StorageKeys.productsPanelOpen`, the settings repository key entry and `SettingsController.setProductsPanelOpen` (settings count 6 -> 5). Migration safety: an existing `products_panel_open` row in a device's settings table is simply never read or written again (left in place, harmless); `AppSettings.fromJson` ignores unknown keys, the settings copy marker is not recomputed.
- Shortcut action renamed `ShortcutAction.productsPanel` -> `switchWorkView` (same keys Ctrl/Cmd+B); the shortcuts dialog row becomes "Switch between Products and Cart".

## Files
New: `modules/pos/controllers/pos_work_view_controller.dart`, `modules/pos/widgets/work_tab.dart`, tests below, `tool/web_check/work_view_check.mjs` (replaces `cart_first_check.mjs`), `docs/plan_work_view.md`. Deleted: `products_panel_controller.dart`, `products_tab.dart`, `cart_empty_state.dart`, `products_shortcut_label.dart` (kept if the tab still needs it; renamed `work_shortcut_label.dart` otherwise).
Changed: `pos_view.dart`, `catalog_panel.dart`, `catalog_product_card.dart`, `global_search_controller.dart`, `scan_controller.dart`, `hold_recall_controller.dart`, `cart_compact_table.dart` (focus node, no empty state), `core/shortcuts/*`, `initial_binding.dart`, `app_density_sizes.dart`, strings, settings model/keys/controller/repository list, `tool/web_check/debug_check.mjs` (only if a coordinate moved), docs.

## Tests
- Rewrite `desktop_products_panel_test` as `desktop_work_view_test`: starts in CATALOG with an empty cart; add via search -> CART; tile click adds and stays in CATALOG, tab count and pulse; switch by tab and by Ctrl and Cmd+B; clear cart, hold last bill, checkout (cash) each -> CATALOG; recall -> CART; Esc order (dialog, then CATALOG -> CART, empty cart: nothing); focus (search in CATALOG, cart list in CART); tab semantics labels; tab disabled while empty; touch layout unchanged.
- `desktop_cart_layout_test`: CART view rows (48 px, 9 at 1280x720, 14 at 1868x1035, footer <= 44), CATALOG view fills the work width (catalog rect width == work width, cart rect width 0), transitions settle with no overflow at 950x733, 1280x720, 1868x1035 light and dark, and the transition is instant under `disableAnimations`.
- `desktop_cart_rows_test`: switch through the tab instead of the old panel; narrow case at 950.
- Settings tests (count 5, no `productsPanelOpen`), shortcut help tests (new label), route navigation walk (both layouts).
- Goldens: only POS work-area goldens regenerate: `shell_pos_*` (now the full catalog), `pos_one_line_*` and `offers_cart_*` (cart view), `offers_tiles_*` (catalog, no panel open call), dialogs drawn over POS (`add_customer`, `counter_dialog`, `customer_picker`, `dialog_profile`, `dialog_shift_close`, `discount_drawer`, `price_check`, `recall_dialog`, `receipt*`, `reprint`, `scan_dialog`, `search_results`, `shell_dialog_toast`, `shortcuts`), `summary_*`. `cart_density_*` is redefined: cart view 1280 and 1868 light and dark plus 950 light, catalog view with 12 items 1280 and 1868 light, catalog empty 1280 light (old `*_collapsed_*`, `*_expanded_*`, `*_overlay_*` files git-removed). Diff boxes are measured; Customers, Products, Sales, Reports, Returns, Settings page goldens must stay byte-identical, otherwise STOP.

## Verification order
dart format, analyze, tests per folder (`test/modules/pos`, `test/core`, `test/modules/shell`, `test/modules/sales`, `test/layout`, goldens), full VM suite once, debug click-through normal and `--semantics` (66 steps), release build (`DEMO_SEED`, cashier1) and `work_view_check.mjs` at 1280x720: empty cart shows the full catalog, tile clicks keep the catalog and update the tab count, tab shows the dense cart, search add switches to the cart, Ctrl/Cmd+B and Esc, clear returns to the catalog; screenshots of both views at 1280x720 and 1868x1035 viewed and saved to `docs/integration/screens/work_view/`.

## Docs
`decisions.md`: DEC-139 (supersedes DEC-138's push/overlay/persisted-panel/empty-state decisions; everything else of DEC-138 stands); `known_gaps.md`: update KG-224 (no overlay any more; narrow rule stays) and KG-225 (catalog state now kept), add the migration note; `progress.md`.
Commit (exact):
```
Switch POS work area between catalog and cart view
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Ht6ZfVLgoUbcN2eKphKPqq
```
Final report: behavior implemented, goldens regenerated, screenshot paths, known gaps.

## Settled here
- "Item count" = number of cart lines (as the old stat tile `Total Items`).
- A tile click that fails (out of stock) does not change the view.
- Stop rules: unrelated golden change or a needed package.

Update (DEC-140): a tile click into an EMPTY cart now shows the cart; later tile clicks stay in the catalog.
