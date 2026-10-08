# Plan S3: POS core (data layer, catalog, cart)

## Context
S1 (money/pricing) and S2 (shell) are done. The POS route is still a placeholder. S3 adds the data layer, the catalog and the cart panel, ported as-is from `data.ts` and `App.tsx` (catalog 846-1087, cart 1088-1330, add/remove/changeQty 305-348, RepeatButton/QuantityInput 2493-2616). Settled decisions from the brief apply unchanged. Plan file after approval: `docs/plan_s3.md`.

## Step 0: Chrome widget-test hang (bounded: 4 probes, no more)
Static review found only 2 timers (ToastController 5 s, SearchFieldController 40 ms), no `Future.delayed` outside MockDelay, and SharedPreferences only in `main()`. Neither causes a hang by itself (pending timers fail a test; they do not hang it). DEC-080 fixed one cause (`*host.dart` names); this is a different one. Probes in order, stop at the first that explains it:
1. Run `flutter test --platform chrome test/widget_test.dart --timeout 60s -r expanded`; see where it stops (loading vs pumpAndSettle).
2. Same test with `pumpWidget` + `pump(Duration)` instead of `pumpAndSettle` (animation or timer that never settles).
3. `bootInWidgetTest` / `FontLoader` on web: check that test font loading and `google_fonts` (`useBundledFonts`) do no network fetch in the browser.
4. Bisect by pumping `AppShell` only, without `PosApp`.
Fix if the change is small (test helper or one lib file); else log KG with cause and move on. One-line report.

## S3.a Data layer (commit "S3.a Data layer")
Files (all under `lib/`):
- Models with `fromJson`/`toJson`: `modules/products/models/product.dart` (priceMinor, `gst` plain number in JSON, `Bp` via `DecimalParser`, stock as integer units, image int, favourite), `modules/customers/models/customer.dart`, `modules/pos/models/cart_line.dart` (keeps the full product snapshot, as the prototype does: the reducer clamps to `line.product.stock`), `cart.dart` (draft fields as the prototype incl. discountType/reason/points/note), `held_bill.dart`, `modules/sales/models/sale.dart`.
- Interfaces + mocks (200-500 ms through `MockDelay`, persisted through `LocalStore` with `StorageKeys`, seeded on first run via `LocalStoreSeeder`): `ProductRepository`, `CustomerRepository`, `CartRepository`, `HeldBillRepository`, `SaleRepository`.
- Seeds: `core/mock/seed_products.dart` (20 products exactly as `data.ts`: barcodes, `stock = index==14 ? 8 : 45+index*3`, `gst = [18,12,5][i%3]`, favourites 0/5/8, images 0..11), `seed_customers.dart` (4). `core/mock/large_dataset.dart`: 10,000 generated products, enabled only with `kDebugMode && --dart-define=LARGE_DATASET=true`.
- `core/services/beep_service.dart`: `BeepService` interface + no-op implementation that checks the beep setting.
- Permanent controllers in `InitialBinding`: `ProductsController` (list, id/barcode/code index maps, stock, favourites), `CustomersController`, `CartController` (reducer rules ported: add blocked at stock, qty clamp to stock, qty<=0 removes, price min 0, discount 0-100, restore, clear; persists on change; totals via `PricingService` once per change). Add `ClockController` (DEC-040 lists a clock; needed for the cart heading in S3.c).
- Tests: JSON round trips; seeds equal `data.ts` values; gst string to Bp; repositories persist and reload through `InMemoryLocalStore`; cart reducer rules including add-at-stock and restore; CartController totals equal the S1 fixtures for the same carts.
- Done when: analyze 0, tests pass on VM and Chrome, app boots on Chrome and macOS with seeded data in the controllers (no visible change yet).

## S3.b Catalog (commit "S3.b Catalog"), then suggest /compact
- Shared widgets in `shared/widgets` (tokens only): `app_chip.dart` (category and sub chips), `segmented_toggle.dart` (grid/list), `app_text_field.dart` (search with clear), `product_card.dart` (+ `product_image.dart` for asset / CSS placeholder, `Image.asset` with cacheWidth and gaplessPlayback), `qty_stepper.dart`, `shortcut_tooltip.dart`. `AppStrings` additions. KG-080 updated.
- `modules/pos/bindings/pos_binding.dart` (`Get.lazyPut`), `controllers/catalog_controller.dart` (category, sub, filter, grid/list, cached filtered list recomputed only on input change, 150 ms debounce, precomputed lowercase "name code" strings; subcategory lists as in React, KG-019 replicated), `controllers/cart_selection_controller.dart` (selected, highlight 1.6 s, scroll request).
- Views: `views/pos_view.dart` (replaces the placeholder for the POS route in `AppPages`; empty-cart and has-cart layouts), `widgets/catalog_panel.dart`, `category_bar.dart` (icons, colors, "next" arrow scrolling 160 px), `subcategory_bar.dart`, `catalog_tools.dart`, `product_grid.dart` (SliverGrid/ListView builder, ValueKey(id), each card listens only to its own cart line), `catalog_footer.dart`, `no_results.dart` ("Reset filters").
- Behaviors: add (stock toast "Available stock: N", success toast, beep, highlight, select, clear top search, refocus), Enter on a focused card adds, star toggles favourite and persists, qty badge, in-cart and sold-out states, stepper minus/plus. Catalog filter text lives in the shared `PageFilterController`.
- Tests: filter/sub/favourites logic; add and stepper flows; widget test with build counters (adding to cart or filtering does not rebuild unrelated cards); empty-cart golden vs screenshot 1 (reference viewport, light).
- Done when: checks green, Chrome and macOS runs clean, screenshot comparison listed.

## S3.c Cart panel (commit "S3.c Cart panel")
- Shared: `hold_to_repeat_button.dart` (500 ms, then 140 ms; click only if no repeat fired), `quantity_field.dart` (draft text with 3 decimals, commit on change if >0, 0 on blur removes, Enter blurs; integer milli-units), `number_field.dart` (price, discount), `stat_tile.dart`, `confirm_dialog.dart` (through the existing dialog layer), `action_button.dart`.
- `widgets/cart_panel.dart` (heading: cart icon, counter from settings, clock; table head; `cart_table.dart` ListView.builder, stable keys, scoped Obx per line, auto-scroll to the bottom on add; selected and highlight styles; `cart_line_row.dart`), `cart_actions.dart`, `stat_tiles.dart` (Total Items, Total Qty with 3 decimals, Total Value from `CartController` totals).
- Remove: toast with Undo for 5 s restoring the line (`ToastController` gets an undo action if it has none; check first), focus back to search. Delete key removes the selected line (not in inputs, not with a dialog open). Clear Cart opens the confirm dialog ("Clear all items and start a new sale?"). Qty above live stock: toast "Only N available in stock".
- Tests: hold-to-repeat timing (fake async), quantity field edge cases (clamp, 0, over stock), price/discount clamps, remove + Undo within and after 5 s, clear confirm, Delete key, selection and highlight; golden for the one-line state vs screenshot 2.

## S3.d Controllers hardening, performance, comparison (commit "S3.d Performance and comparison")
- Performance tests with the 10k dataset: filtering and adding do not rebuild unrelated cards (build counters); timing test prints filter and search times (no threshold). First-screen image precache.
- Goldens (reference viewport, light) for empty cart and one line, compared with the two screenshots; regression goldens at 1700/1280/1100 widths and dark are marked unverified.
- Docs: decisions.md (new DEC entries), known_gaps.md (KG-080 shared widgets; new KGs for unverified areas, S4-owned parts missing from the screens, dark-mode rows KG-060..063 for stock pills, qty badge, favourite star, chips), `plan_s3.md`, migration_plan.md status.
- Final S3 report: files, tests, 10k timing numbers, differences, unverified areas. Then STOP; no S4.

## Scope boundaries I will follow (say if you disagree)
- In the cart panel S3 draws: heading (cart icon, counter, clock), table, Clear Cart (working), Hold / Recall / Price Check buttons (they belong to the cart panel; clicks show the same placeholder behavior as F4 and the placeholder dialog until S4), stat tiles.
- Left to S4 and listed as visible differences vs the screenshots: Cash/Credit sale toggle, the "..." order menu, the Customer label + dropdown + search + Add Customer row, note line and credit validation, the customer chip row in the empty-cart catalog header (the "PRODUCT CATALOG N items" caption is drawn in that row), the top-bar matches dropdown / Enter-to-add / scan (S4.c scan simulator).
- No package added. `reference_react/` untouched. No `double`/`num` for money or quantity outside layout code.

## Verification at each checkpoint
`dart format .`, `flutter analyze` (0), `flutter test`, `flutter test --platform chrome test/core test/modules test/widget_test.dart`, `flutter run -d chrome` console check plus `flutter build web` served with SPA fallback (DEC-079), macOS run; short checkpoint report with "what to look at yourself", commit with the two trailers; continue without waiting.

## Decisions for you
1. Scope boundaries above (S4-owned parts of the cart panel and catalog header omitted in S3): OK?
2. Add `ClockController` as a permanent controller now (heading clock): OK?
3. 10k dataset switch via `--dart-define=LARGE_DATASET=true`, debug builds only: OK?
4. Chrome-hang probes are run first as step 0 (I did not run them in plan mode): OK?


## As built (2026-10-08)
- S3.a `ee6006b`, S3.b `21b7218`, S3.c `de12638`, S3.d (this commit). Step 0 (Chrome hang) was skipped on request: already fixed by DEC-080.
- Deviations from this plan: `CartSelectionController` and `CatalogController` are permanent (DEC-082, DEC-083); `CartActionsController` and `ClockController` added; the stacked cart line (<= 1700 px) is not built (KG-097, S7.a).
- Decisions DEC-081 to DEC-090, gaps KG-090 to KG-102.
