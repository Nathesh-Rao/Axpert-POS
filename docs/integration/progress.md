# Integration progress

Branch `integration` (from `main` d5b2975). axpert_pos is read-only and untouched.

## Batch 1 (docs and pure Dart)
- Stage 0: branch `integration` created, tree was clean.
- Stage 1: docs written (`audit_report`, `integration_plan`, `codex_workflow`, this file); CLAUDE.md updated (integration workflow section).
- Stage 2: ported from axpert_pos into `lib/core/{result,errors,data,config,identifiers}`: `Result<T>`, `AppFailure`/`UnexpectedFailure`/`DataSourceFailure`/`ApiTransportFailure`, `DataSource<T>`, `MockJsonDataSource`, `AppConfig`/`DevelopmentAppConfig`, `UuidGenerator`/`UuidV4Generator`. Tests ported plus a new UUID v4 test (10 tests, pass). Not registered anywhere yet.
- Stage 3: cross-check `test/core/services/pricing/axpert_crosscheck_test.dart` (3000 deterministic carts, both tax modes, scale <= 3, no discounts). Result: the rule sets DIFFER (see below). Stopped for the owner's decision per D1; decided: keep ours. No money/pricing code was changed.

### Stage 3 findings
1. Rounding point: axpert rounds each line's extension and each line's tax half-up and sums the rounded lines; ours computes exact values and rounds once per cart total (prototype-compatible, golden vectors). Results differ by 1 minor unit in many multi-line carts and in some single-line carts with fractional extension (exclusive total: 941 multi-line + 130 single-line of 3000; tax 469 + 10; inclusive tax 480 + 4). They agree for one-line carts with whole-unit quantity.
2. Meaning of `subtotal` in inclusive mode: axpert = net of tax (sum of total - tax); ours = gross value (tax-inclusive). Not a rounding issue; differs in most inclusive carts.
3. Other known differences (by design, not tested): ours has line/bill discount, points, negatives; axpert `multiplyRatio` is non-negative only; `Quantity` scale > 3 is not representable in `Qty`.
Decision (owner): keep our money core exactly as is, no adapter now (DEC-116, KG-183, `money_core_differences.md`).

## Batch 2 (packages, database, wiring)
- Stage 4a (done): `dio` 5.11.1 + `core/network` (ApiClient, DioApiClient) + 3 tests (fake adapter). Unused by features.
- Stage 4b (done): `drift` 2.34.4, `drift_dev` 2.34.0, `build_runner` 2.11.1, `path` 1.9.1, `path_provider` 2.1.6; resolved versions identical to axpert_pos's lock (drift, drift_dev, sqlite3 3.5.2, build_runner, dio, path, path_provider, analyzer). Ported `core/database/**` (single table `device_context_entries`, schema v2), `core/device/**` (DeviceContext, store, id generator, `DeviceContextService`), `build.yaml`. `dart run build_runner build --delete-conflicting-outputs` (32 s, scans the whole project) produced `axpert_database.g.dart` BYTE-IDENTICAL to axpert's. The sqlite3 native-assets hook works on this Mac: 7 database/device tests pass with `NativeDatabase.memory()`.
- Stage 4c (done): official drift-2.34.4 release assets downloaded and verified (size + SHA-256 match the GitHub-published digests) and copied to `web/` (DEC-117). axpert_pos's 2.34.2/2.34.4 mismatch recorded, not touched.
- Stage 5 (done): `core/security/*`, `SessionController`, `AppLifecycleService` ported; `AppInfrastructure` + `StartupDiagnostics`; `InitialBinding(store, infrastructure:)` registers config, ApiClient, DatabaseProvider, DeviceContextService, UuidGenerator, AuthenticationService, SessionController, AppLifecycleService once (guard test); `main()` bootstraps the database before `runApp` with the log-and-continue failure path (DEC-119). Tests: `test/core/bindings` (5), `test/core/session` (2), plus the earlier database/device tests; existing route/shell/cart tests unchanged and green.
- Note for later: a release macOS build needs the `com.apple.security.network.client` entitlement before dio can make requests; entitlements were NOT changed (nothing calls dio yet; DEC-118).

### Batch 2 end-of-batch checks (2026-10-12, all run and read)
- `dart format --output=none --set-exit-if-changed .` rc 0, `flutter analyze` no issues.
- Full VM suite: 978 tests pass (949 existing + 29 new: network 3, database/device 7, bindings 5, session 2, security/ids 10 earlier, cross-check 2). No existing test or golden changed (goldens were not regenerated; none ran red).
- Debug click-through (fresh `flutter run -d web-server` each): normal 65/65 steps clean, `--semantics` 65/65 clean (includes the beep step).
- Release web build + new `tool/web_check/drift_check.mjs` (served by `serve.py`, headless Chrome, 1280x720, 950x733, 1868x1035): `drift_worker.js` 200 text/javascript 355222 bytes, `sqlite3.wasm` 200 application/wasm 748686 bytes (sizes equal the verified 2.34.4 assets), IndexedDB `axpert_pos` created with records (blocks 4, files 1), 0 console errors. First Flutter view (headless, cold profile, local server, noisy): baseline `main` build 3.5-4.3 s vs now 4.0-5.3 s, about +0.7 s on average.
- macOS debug launch: the app ran, `axpert_pos.sqlite` was created in the sandbox container (`~/Library/Containers/com.agile.posApplication/Data/Library/Application Support/com.agile.posApplication/`), no errors in the run log.
- Not verified: Windows build (cannot build here), sqlite3 hook on Windows, Android/iOS/tablet, real-browser OPFS vs IndexedDB choice (headless used IndexedDB), the device-context ROW contents on web (only that the database file has data), UI screenshots of the three sizes were not compared again (no UI file changed).
- Deviations from the ported axpert code are listed in DEC-119.

## Batch 3 (Products pilot)
- Step 0 (`3343f68`): `tool/web_check/drift_check.mjs` rebuilds the Drift database file from the IndexedDB blocks (store `files` {name:'/database', length}, store `blocks` keyed [fileId, byteOffset], 4096-byte buffers) into a temp copy, reads `device_context_entries` with the `sqlite3` CLI and deletes the copy. Result in the release build at 1280x720, 950x733 and 1868x1035: one row, `singleton_id` 1, `device_id` a UUID v4 (different per fresh browser profile), `outlet_id` null, `register_id` null; 0 console errors. First attempt decoded the layout.
- Stage 6 (`fc77244`): Products moved to `features/products` (DEC-120). Checks: format and analyze clean; touched folders then the full VM suite 978/978; no golden or PNG changed (no new failure images); debug click-through 65/65 clean in normal and `--semantics`. The three moved tests contained no golden paths, `File(...)`, asset or fixture references (only `../../support/...` imports, same depth after the move), so no path edits beyond package imports.
- Lessons for the other modules (imports from OTHER lib files / OTHER test files): customers 11/13, sales 15/14, shell 16/9, pos 13/16, shift 7/3, settings 2/3, returns 1/4, reports 1/2. Easiest next: reports, returns, settings; hardest: pos (65 files), shell, sales, customers.
  - `AppShell` (`modules/shell/views/app_shell.dart`) is imported by every page; `features/products/presentation/pages/products_view.dart` now imports `modules/shell/...` (a feature depending on a module). It works, but the shell must stay reachable or move to `core`/`shared` before more pages move; decide before Stage 7.
  - Permanent controllers registered in `InitialBinding` (`ProductsController`) and shared entities (`Product`, used by cart, returns, search) create cross-feature imports of `domain/entities`; this matches axpert's cart using the catalog entity.
  - The scripted rewrite (resolve every import against the file's old location, map through the move table, rewrite relative to the new location) handled 113 lines in 67 files with no manual edits; it is reusable with a different move table (kept in the session scratchpad, not in the repo).
  - Moves of files with persisted JSON or seeds (Stage 6b, D4) must keep `axpert-products` JSON identical.

## Batch 3 decisions (owner, 2026-10-12)
- Batch 3 accepted. DEC-121: no further module migration until Phase B work changes a module. DEC-122: `AppShell` stays in `modules/shell` as app chrome any page may import; `shell/widgets/search_results.dart` depends on the products feature (`Product`). The import-rewrite script is saved under `tool/integration/` for future moves.

## Stage 7 (PaymentService and saleId, 2026-10-12)
- Commits: `c50e551` 7a (feature `features/payment`: interface, entities, `MockPaymentService`, 2 tests), `9fb2476` 7b (additive `Sale.saleId`, `CheckoutService` carries it, 4 + 1 tests), `326280f` 7c (`PaymentController` async via `PaymentService`, UUID ids, guard in `finally`, 'Payment failed' string, `InitialBinding(payments:)`, 9 tests), `e8f1d26` tool step in `debug_check.mjs`; docs commit follows. DEC-123, KG-185 to KG-188.
- Checks: format/analyze clean at every step; `payment_flow_test`, `receipt_flow_test`, `summary_layout_test` and `cart_actions_test` (119 tests with summary layout) passed UNCHANGED; touched folders 7b: 717 tests, 7c: 520 tests; full VM suite 994/994 (978 before + 16 new); no PNG changed, no new failure image (goldens byte-identical, not regenerated).
- Debug click-through with the new checkout step, 66/66 steps in normal and in `--semantics` mode: F2 + Enter completes a cash sale (bill AX000004, total 83.80, cart cleared), the receipt opens (looked at the screenshot; read from the semantics DOM, switched on only after the sale in normal mode), and the stored `axpert-sales` has 4 sales: the new one with a UUID v4 `saleId`, the 3 seeded ones untouched (no `saleId` key).
- Not verified: a real asynchronous provider (only the mock exists), a failed payment in the browser (unit-tested only), card flow in the browser, Windows/tablet, behavior with a persistence failure (KG-187).

## Stage 8 (final verification, 2026-10-12)
Run and read: format and analyze clean; full VM suite 994/994; no PNG changed versus main; debug click-through 66/66 in normal and `--semantics`; release web build with `web_check` at 950x733, 1280x720, 1868x1035 and `drift_check.mjs` (worker, wasm, content types, device-context row); macOS debug launch (database file present, same device id before and after); axpert_pos status hash unchanged. Details and open items: `final_report.md`.

## Database and sync planning (2026-10-12, documents only)
`axpert_db_sync_digest.md` (what axpert_pos decides, proposes and leaves open about tables, ids, money, offline and sync, with sources) and `database_plan.md` (LocalStore inventory, provisional tables, sync-readiness columns, no-data-loss migration, repository replacement order, risks, open questions) written; DEC-124 records the recommended provisional local-only schema. No code, schema or persistence changed; axpert_pos untouched; the owner has not yet approved any implementation stage.

## Stage D1 (settings in Drift, 2026-10-12)
- Commits on `integration`: D1.a schema v3 (`83502c9`), D1.b migrator (`8c48f0d`), D1.c repository, flag and binding (`08420a5`), D1.d contract suite (`2995e93`), D1.e web check, durable transaction, docs. Details and rollback: DEC-125.
- No UI, money, pricing, golden or other-repository change; no new package.

## Stage D2 (customers in Drift, 2026-10-12)
- Commits on `integration`: D2.a schema v4 (`610e774`), D2.b migrator (`62ee145`), D2.c repository, flag and binding (`2d57f0e`), D2.d contract suite (`039714b`), D2.e web checks and docs. Details and rollback: DEC-126.
- No UI, money, pricing, golden or other-repository change; no new package.

## Stage D3 (held bills in Drift, 2026-10-12)
- Commits on `integration`: D3.a schema v5 (`34c6ad3`), D3.b rows and migrator (`d49177d`), D3.c repository, flag and binding, D3.d contract suite, D3.e start-up timeline (`a39cc9b`), D3.f web checks and docs. Details and rollback: DEC-127.
- No UI, money, pricing, golden or other-repository change; no new package. Start-up measurement only (flag off by default); KG-189 and KG-190 logged.

## Stage D4 (products in Drift, 2026-10-12)
- Commits on `integration`: D4.a schema v6 (`eba8f80`), D4.b rows and migrator (`1f6191a`), D4.c repository, flag and binding (`f3c4fd3`), D4.d contract suite and tests (`6532986`), D4.e performance test and labels (`31a32e2`), D4.f web checks, docs and budget proposal (`9501782`).
- DEC-128; KG-191, KG-192, KG-193 logged; KG-101 updated. No UI, money, pricing or golden change; no new package; start-up order unchanged. `UuidV4Generator` is faster (4 draws per UUID).
- Start-up table (release web, headless Chrome, timeline build, 5 runs, medians, ms; D3 value in brackets where it changes). COLD / WARM: `load products` 25 / 3 [D3: 322 / 370, MockDelay]; `products drift copy` 23 / 1 (20 seed products); `products drift read` 1 / 2; `load customers` 27 / 4; `load held bills` 27 / 4; `load sales` 279 / 394 (MockDelay 275 / 391); `load cart` 341 / 380 (MockDelay 338 / 377); `loadData` 664 / 742 [767 / 751], estimate without MockDelay 39 / 10; runApp called at 873 / 835 [941 / 855]; first frame built 1096 / 940 [1159 / 961]; rasterized 3983 / 3516 [4140 / 3572]; JS and engine boot before main 6865 / 4207 (machine noise, outside our code).
- 10,000 products (injected list, release web): copy 665 to 913 ms, read about 100 ms, reload `load products` about 140 ms, checkout Drift write 524 ms first after reload / 78 ms steady, mirror 49 to 106 ms (DEC-128 item 9).
- PROPOSED start-up budget (for owner approval, not enforced by any check yet; headless SwiftShader numbers, compare only): with the 20 seed products: `load products` cold under 100 ms and warm under 20 ms; `loadData` without MockDelay under 100 ms cold; runApp called under 1.2 s after main start; first frame built under 1.5 s cold and 1.2 s warm. With 10,000 products: first-start copy under 2 s, warm `load products` under 300 ms, `loadData` without MockDelay under 500 ms. Once the Mock sales and cart repositories lose their MockDelay the `loadData` budget becomes the whole budget. Candidates (each needs approval, none done): open SharedPreferences and the database in parallel, start the sales and cart loads without waiting for each other.

## Stage D5 (sales and returns in Drift, 2026-10-12)
- Commits on `integration`: D5.a schema v7 (`67a2d61`), D5.b rows and migrator (`f4e509c`), D5.c repository, flag, shared queue (`676da81`), D5.d contract suite (`906f89a`), D5.e checkout and refund transactions (`b2b2c79`), D5.f web checks and docs. Details and rollback: DEC-129.
- Owner decisions: checkout option b2 (memory first) with the b1 switch (`CheckoutPolicy`), `sales.deleted_at`, `number` not unique, `toastSaveFailed`, stop-the-copy cases, one shared queue. KG-187 reduced; KG-194 to KG-197 logged. No UI layout, money, pricing or golden change; no new package; start-up order unchanged.
- Checks run and read: format and analyze clean; full VM suite 1351 tests pass (994 before the integration plus the database stages; no golden or PNG changed); debug click-through 66/66 in normal and `--semantics`; release web build: `sales_flow_check.mjs`, `drift_check.mjs` (1280x720, 950x733, 1868x1035, plain and `--seed-duplicates`), `held_flow_check.mjs`, `products_flow_check.mjs`, `customers_flow_check.mjs`, `products_10k_check.mjs` x3, `startup_check.mjs` (D6 reports the final table).
- 10,000 products (release web): receipt 5.8 to 10.5 ms; checkout transaction first write after a reload 1,001 / 4,822 / 213 ms, steady 151 / 184 / 72 ms; three mirrors 54 to 236 ms (KG-196).
- Not verified: Windows, real-browser OPFS, multi-tab, a credit sale in the browser (unit tested), a real failed commit in the browser (fault injection is unit tested), macOS (skipped by request).

## Stage D6 (the cart in Drift, 2026-10-12)
- Commits on `integration`: D6.a characterization tests (`c0ec5d4`), D6.b schema v8 and migrator (`e97f546`), D6.c repository, flag and binding (`15541ba`), D6.d contract suite and interaction tests (`0924816`), D6.e web checks and docs. Details and rollback: DEC-130. The machine restarted during D6.e; the audit found D5 pushed, D6.a to D6.d committed, only the web-check script edits and the docs missing.
- No UI, money, pricing or golden change; no new package; start-up order unchanged. KG-198, KG-199 logged.
- Checks run and read: format and analyze clean; full VM suite 1429 tests pass (after the restart); debug click-through 66/66 in normal and `--semantics`; release web: `cart_flow_check.mjs`, `drift_check.mjs` (1280x720, 950x733, 1868x1035, plain and `--seed-duplicates`), `sales_flow_check.mjs`, `held_flow_check.mjs`, `products_flow_check.mjs`, `customers_flow_check.mjs`, `theme_check.mjs`, `products_10k_check.mjs`, `startup_check.mjs`.
- Start-up table (release web, headless Chrome, timeline build, 5 runs, medians, ms). COLD / WARM: JS and engine boot before main 6191 / 2476; LocalStore open 2 / 1; database open 150 / 103 (schema create 46 / 0); device context 5 / 2; `dependencies()` 4 / 2; load settings 11 / 3; load products 30 / 3; load customers 31 / 5; load held bills 31 / 6; load sales 32 / 8; load cart 4 / 1 (D5: 356 / 2 with the MockDelay of the cart; no Mock repository with a delay is left); `loadData` 47 / 12 (D4: 664 / 742); runApp called at 211 / 120 after main start (D4: 873 / 835); first frame built 417 / 226 (D4: 1096 / 940); first frame rasterized 3308 / 2824 (headless software rendering, not representative).
- 10,000 products (release web, injected list): receipt (memory update to receipt open) 4.7 to 13.6 ms; checkout transaction first write after a reload 1,001 / 4,822 / 213 / 170 ms, steady 151 / 184 / 72 / 65 ms (4 runs, noisy shared machine); three mirrors 54 to 236 ms.
- PROPOSED start-up budget (for owner approval, not enforced by any check; headless SwiftShader numbers, compare only). All stores are Drift now and nothing waits for a simulated delay. With the 20 seed products: `loadData` under 100 ms cold and 50 ms warm; runApp called under 300 ms (cold) and 200 ms (warm) after main start; first frame built under 600 ms cold and 400 ms warm. With 10,000 products: first-start copy under 2 s, warm `load products` under 300 ms, `loadData` under 500 ms. Interaction: checkout receipt under 50 ms; checkout transaction steady under 300 ms and first write after a reload under 1.5 s (the 4.8 s outlier shows this one needs more runs on quiet hardware before it is enforced); cart write steady under 100 ms, first write of a session under 1 s. Candidates (each needs approval, none done): open SharedPreferences and the database in parallel, a warm-up statement after the database opens to cut the first-write cost (KG-196, KG-198), coalesced mirror writes.
- Not verified: Windows, real-browser OPFS, multi-tab, tablet, a credit sale and a real failed commit in the browser (unit and fault-injection tested), power-loss durability (only reload and SIGKILL samples), macOS (skipped by request).


## Demo data in the database and offers (2026-10-12, uncommitted after tag `pre-promotions`)
- Step 0: `4dea19e` ("before seeding db data v1", empty commit, tree was clean) pushed to `origin/integration`, tag `pre-promotions` pushed. Everything below is uncommitted.
- Plan and decisions: `docs/plan_demo_offers.md`, DEC-132 to DEC-135, KG-202 to KG-209. Schema v9, `crypto` added, `assets/seed/` added to the pubspec.
- Checks run and read: `dart format --output=none --set-exit-if-changed .` clean, `flutter analyze` no issues, full VM suite 1526 passed and 1 failed in the full run (`products_drift_performance_test`, a timing threshold under load; passes alone in 2 s); no existing PNG changed (6 new offer goldens added); the 300 pricing vectors and the s6 fixtures untouched and passing.
- Release web (`tool/web_check/demo_check.mjs`, 1280x720): Ozone 8/8 (seed once, reload keeps the data and does not seed again, checkout with Buy 1 Get 1, a 20 % discount and an unlocked free item writes a stamped sale with its offer lines); Kampala 4/4 (own store name, `USh` with no decimals, no rupee sign, its own 12 sales); 0 console errors.
- Debug click-through (`debug_check.mjs`): SKIP_ENTRY normal 66/66, SKIP_ENTRY `--semantics` 66/66 (one earlier run failed only the beep-duration assertion, 0.074 s against 0.08 s, timing jitter), real login (`--entry`, user cashier1) 70/70 after the checkout assertion was made generic; `--entry --semantics` does not log in (typing into the semantics text field does not land: script limitation, no console error). Console clean in all runs.
- Not verified: Windows, tablet, macOS launch, other window sizes for the offer UI, dark mode in the browser, the picker page visually (VM test only).
- Pre-commit re-run: full VM suite 1528 of 1528 passed; the earlier single failure is KG-210 (timing threshold, same on origin/integration). Picker screenshots (light and dark, release, 1280x720) taken and viewed (KG-211).

## Forex and tax from the database (2026-10-13, on top of 9c7eab0)
- Plan `docs/plan_store_forex_tax.md`, DEC-136, KG-213 to KG-219. Schema v10 (store_forex, tax_regimes, tax_slabs), seed `demo_seed_v2`.
- Checks: `dart format` clean, `flutter analyze` no issues, full VM suite 1554 passed. New tests: `schema_v10_test` (upgrade keeps v9 rows, forced failure rolls back), seeder v1->v2 upgrade and reseed, `vat_forex_test` (VAT exclusive/inclusive, forex vectors, tax split). 300 vectors, s6 fixtures and offers fixtures untouched.
- Goldens: 37 existing goldens regenerated (every one that shows the Bill Summary or a receipt/reprint: the new CGST/SGST rows and the forex label), 4 new (`summary_vat_forex_*`, `summary_no_forex_*`, light and dark).
- Release web (`demo_check.mjs`, 1280x720): cashier1 (India) 12/12 (GST Amount, CGST, SGST, forex USD/EUR/AED, rate 83.2, receipt with CGST/SGST); cashier2 (Kampala) 8/8 (VAT Amount, no GST/CGST/SGST anywhere including the receipt, forex USD/EUR/KES, rate 3700). Debug click-through normal 66/66 and `--semantics` 66/66 (`debug_check.mjs` scrolls the summary before the quick-action clicks, see KG-218).

## System print and small fixes (2026-10-13, on top of 117e261; KG-218 left open by the owner)
- Plan `docs/plan_print_bill.md`, DEC-137, KG-218 (open), KG-219 (rewritten), KG-220, KG-221. Packages `printing` 5.14.3, `pdf` 3.12.0 (+ `image` 4.8.0 override).
- Tests: new `receipt_print_model_test`, `receipt_pdf_builder_test`, `print_flow_test` (receipt, Reprint, draft, paper setting, unsupported, failed), `summary_split_fit_test`, `currency_symbol_test`; goldens: 36 India goldens regenerated (diff only in the Bill Summary tax block and below, plus the receipt clock text), 1 new (`print_receipt_80mm_light`).
- Release web (`print_check.mjs`, 1280x1100): receipt Print -> one `window.print` from a blob PDF iframe, Reprint -> sale -> Print -> one more, nothing printed by Reprint itself, 0 console errors. Debug click-through normal 66/66 and `--semantics` 66/66.

## Cart-first POS layout (2026-10-13, on top of e649a63)
- Plan `docs/plan_cart_density.md`, DEC-138, KG-222 to KG-225. Desktop only (touch keeps today's page). Settings key `products_panel_open`.
- Rows fully visible with 14 lines, before to after: 950x733 1 to 9, 1280x720 1 to 9, 1868x1035 4 to 14 (layout test `desktop_cart_layout_test`, light and dark, 48 px rows, footer <= 44 px).
- Goldens: 35 existing goldens regenerated (the POS page and every dialog drawn over it; diffs measured inside the work area between sidebar and Bill Summary), 7 new `cart_density_*`. Customers, Products, Sales, Reports, Returns and Settings page goldens are byte-identical.
- Release web (`cart_first_check.mjs`, cashier1, 1280x720): 13/13 (13 scans with the panel collapsed incl. Buy 1 Get 1 and the free-gift tier, Ctrl+B, Escape, Cmd+B, hold, recall, cash checkout). Debug click-through normal 66/66 and `--semantics` 66/66. Screenshots: `docs/integration/screens/cart_density/{before,after}_*.png`.

## Work area: catalog or cart (2026-10-13, on top of 9c0af52)
- Plan `docs/plan_work_view.md`, DEC-139 (supersedes the panel part of DEC-138), KG-224 to KG-227. Setting `products_panel_open` removed from the code (row left in old databases).
- Goldens: 34 existing goldens regenerated (the POS work area and every dialog drawn over it), the `cart_density_*` set redefined (8 new, 7 removed). Customers, Products, Sales, Reports, Returns and Settings page goldens are byte-identical.
- Release web (`work_view_check.mjs`, cashier1, 1280x720): 12/12. Debug click-through normal 66/66 and `--semantics` 66/66. Screenshots: `docs/integration/screens/work_view/`.

## First add shows the cart, customer row height (2026-10-13)
- DEC-140 (supersedes the tile-click rule of DEC-139). `addFromCatalog` switches to the cart when the cart was empty. `CustomerRow`: field, search segment and Add Customer button all `fieldHeight` tall; new `test/modules/pos/customer_row_height_test.dart`. Tile gap unchanged (already 6 to 11 px).
- Goldens regenerated (customer row only; diffs are one 30 to 45 px strip, plus the live clock text): `cart_density_*_cart_*` (5), `pos_one_line_light*` (4), `offers_cart_*` (4), `summary_*` (4), `discount_drawer_light`, `receipt_draft_light`. Catalog goldens unchanged.
- Release web (`work_view_check.mjs`, cashier1): all 13 at 1280x720; at 1868x1035 and 950x733 the behaviour checks pass and the failures are click coordinates of the script (grid rows differ by width).

