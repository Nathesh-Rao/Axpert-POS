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
