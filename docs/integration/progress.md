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
