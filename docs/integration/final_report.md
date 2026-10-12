# Final report: axpert_pos infrastructure integrated into pos_application

Date: 2026-10-12. Branch `integration` (HEAD after this report: see section 9). `main` and `ui-migration` are untouched at `d5b2975`; nothing was merged and nothing was tagged. axpert_pos was only read.

## 1. Summary
The infrastructure of axpert_pos (Result/failure types, data-source and config conventions, UUID ids, Dio API client, Drift/SQLite database with web assets, device context, session/auth interfaces, lifecycle service, payment seam) is now part of pos_application behind the existing GetX bindings, and the Products module is the first one in the feature-first layout. The UI, theme, routes, shell, money core and all goldens are unchanged. Stage 6 and 7 changed behavior only where the plan said so (the checkout calls a `PaymentService` and new sales carry an optional `saleId`).

## 2. Verification run for this report (everything below was run once and read)
| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | exit 0, 391 files, 0 changes |
| `flutter analyze` | No issues found |
| Full VM suite (`flutter test`, no Chrome tests) | 994 of 994 passed (949 at the start of the integration, 978 after Batch 2) |
| Goldens | `git diff main..integration --stat -- '*.png'` is empty; 32 golden images tracked, none changed; no failure image written by this run (the 56 old files in the git-ignored `test/golden/failures/` are older) |
| Debug click-through, normal mode | 66 of 66 steps, 0 failed, console clean, including the cash checkout step |
| Debug click-through, `--semantics` mode | 66 of 66 steps, 0 failed, console clean, including the cash checkout step |
| Checkout step (both modes) | F2 + Enter completes a cash sale (bill AX000004, total 83.80, cart cleared), the receipt opens (screenshot looked at in the Stage 7 run; read from the semantics DOM here), stored `axpert-sales` has 4 sales: the new one with a UUID v4 `saleId`, the 3 seeded sales without the key |
| Release web build + `tool/web_check/cdp.mjs` at 950x733, 1280x720, 1868x1035 | built; POS page and a populated cart (Lays added, toast, Bill Summary 21.00) rendered at all three sizes (screenshots looked at); console: no output besides bootstrap; overflow errors 0 (release builds do not print overflow errors; the debug click-through covers them) |
| `tool/web_check/drift_check.mjs` at the same three sizes | `drift_worker.js` 200 text/javascript 355222 bytes; `sqlite3.wasm` 200 application/wasm 748686 bytes (the verified drift-2.34.4 assets); IndexedDB `axpert_pos` blocks 4 / files 1; `device_context_entries` row: `singleton_id` 1, `device_id` a UUID v4 (differs per fresh browser profile), `outlet_id` null, `register_id` null; 0 console errors; first Flutter view 4.3 to 5.3 s (headless, cold profile, noisy) |
| macOS debug launch (`flutter run -d macos`) | built and started (Dart VM service up); the sqlite file `axpert_pos.sqlite` exists in the app sandbox container; reading temp copies of it before and after the launch gave the SAME device id (`d77bba11-f549-4244-8640-87692caeeaec`), i.e. the context is restored, not recreated; no app error in the run log. The only matching log line is the Flutter tool's "Failed to foreground app; open returned 1" (it could not bring the window to the front in this environment), not an app error. Temp copies deleted |
| axpert_pos unmodified | `git status --short` hash of axpert_pos is `4dbbb480fffde644d6697ede98654823`, identical to the value recorded before any integration step; only `--no-optional-locks` read commands and one timing run in a deleted `/tmp` copy were used there |

## 3. What was integrated and how the UI connects
| axpert_pos component | In pos_application | How it connects |
|---|---|---|
| `Result<T>`, `AppFailure` family, `ApiTransportFailure` | `lib/core/result`, `lib/core/errors` | used by the API client, `PaymentService`, `MockJsonDataSource` |
| `DataSource<T>`, `MockJsonDataSource`, `AppConfig`, UUID v4 generator | `lib/core/data`, `lib/core/config`, `lib/core/identifiers` | `AppConfig` and `UuidGenerator` registered in `InitialBinding`; the data source is ported and tested but no feature uses it yet (Stage 6b) |
| `ApiClient` / `DioApiClient` | `lib/core/network` | registered, called by nothing yet |
| Drift database, `DatabaseProvider` (native/web conditional import), `device_context_entries` v2, `DeviceContextService`, web assets | `lib/core/database`, `lib/core/device`, `web/` | `main()` calls `AppInfrastructure.bootstrap()` before `runApp`; failure is logged in `StartupDiagnostics` and the app still starts (DEC-119) |
| Authentication interfaces, `SessionController`, `AppLifecycleService` | `lib/core/security`, `lib/core/session`, `lib/core/lifecycle` | registered by `InitialBinding`; auth is unconfigured; no UI; separate from the prototype's `ShiftController` |
| Payment boundary | `lib/features/payment` | `PaymentController` (modules/pos) calls `PaymentService` for cash and card sales; credit bypasses it; failure shows 'Payment failed' |
| Sale identity | `Sale.saleId` | UUID v4 generated in `PaymentController`, same id in the `PaymentRequest` and the stored sale |
| Feature-first layout | `lib/features/products/{domain,data,presentation}` | other modules import `Product` and `ProductsController` from there; `AppShell` stays in `modules/shell` (DEC-122) |
Wiring point: `InitialBinding(store, infrastructure:, audio:, payments:)` registers everything idempotently with its existing `_put`; `main.dart` builds the infrastructure; routes, `GetPages`, shell and widgets are unchanged.

## 4. What was preserved
Money core (`Money` with currency, `Qty`, `Bp`, `PricingService`, rounding strategy, all golden vectors; DEC-116/KG-183 document the differences to axpert's rules); all 32 golden images; the 7 routes and `GetPages`; `AppShell`, theme tokens, strings (one new string, 'Payment failed'); `LocalStore` as the only persistence for application data; existing stored sales load unchanged; the four checkout test files passed unchanged.

## 5. Deviations and decisions (this branch; earlier ones are on `main`)
DEC-115 integration decisions D1 to D10; DEC-116 money core kept, no adapter; DEC-117 Drift web assets from the official drift-2.34.4 release, hashes verified; DEC-118 packages (dio, drift, drift_dev, build_runner, path, path_provider) and the `path_provider` web exception; DEC-119 infrastructure wiring and the log-and-continue bootstrap failure path; DEC-120 Products moved; DEC-121 no further module migration until Phase B changes a module; DEC-122 `AppShell` stays as app chrome; DEC-123 `PaymentService` seam and optional `saleId`. Known gaps added: KG-183 (rounding point and inclusive subtotal differ from axpert), KG-184 (Drift web storage, Windows hook, macOS entitlement), KG-185 to KG-188 (mock payment; cart changing during a real async payment; payment succeeding while the sale persist fails; `saleId` unused for lookups). Deviations from the ported axpert code are listed in DEC-119.

## 6. Outstanding issues and not done
Not done (by decision or still to plan):
- Stage 6b: split `Product` into entity and DTO and load seeds from JSON assets with `MockJsonDataSource` (D4); must keep the stored `axpert-products` JSON identical.
- Batch 2b: multi-currency and regional tax (CGST/SGST/IGST, GSTIN, HSN/SAC, per-currency cash rounding): design only in `docs/integration/currency_tax_design.md`; needs its own plan and approvals; schema, persistence and UI changes need approval.
- System print for the bill on every platform (receipt printing beyond the on-screen `ReceiptDocument`): design pending the owner's approval.
- Other modules stay in `lib/modules` per DEC-121 (migrate only when Phase B changes them; `tool/integration/move_feature.py` does the move).
- Operational Drift tables, sync/outbox, backend contracts: blocked by axpert ADR-014 and the unanswered backend questions.
Unverified:
- Windows (nothing can be built here, including the sqlite3 build hook), Android, iOS, tablet.
- A real browser with OPFS (headless Chrome used IndexedDB); multi-tab behavior of the web database.
- A real asynchronous payment provider, a failed payment and the card flow in a browser (only unit-tested).
Open items and risks:
- macOS release build needs the `com.apple.security.network.client` entitlement before dio can make requests; entitlements were NOT changed (nothing calls dio yet).
- KG-185 to KG-188 (mock payment, cart change during async payment, payment vs failed sale persist, `saleId` unused).
- Existing gaps unchanged: sale numbers from list length (KG-008), clock-based held refs and customer ids (KG-125, KG-132).
- `path_provider` has no web support (isolated behind the conditional import, DEC-118); `drift_dev` and `build_runner` are exact-pinned to axpert's versions.
- First web paint is about 0.7 s slower in the headless comparison (noisy).

## 7. Current branch and remote state
Branch `integration` at the commit listed in section 9, pushed to `origin/integration` (see the push result in the report message). `origin/main` = `origin/ui-migration` = `d5b2975`; tag `phase-a-complete` = `580097f`. No merge into `main`, no new tag.

## 8. Files changed
`git diff main..integration --shortstat`: 158 files changed, 16962 insertions(+), 150 deletions(-). Status counts: 71 A;    6 D;   69 M;   12 R (A added, D deleted, M modified, R renamed). Full `--stat` is in the appendix.

## 9. Commits on `integration` (oldest first, above `main`)
1. 57a0623 Integration stage 0-1: branch, integration docs, workflow rules
2. 20b063c Integration stage 2: port core result, errors, data source, config, uuid
3. 7c21b7b Integration stage 3: money cross-check test and decision docs
4. 635e434 Integration stage 4a: dio and network client
5. ab48458 Integration stage 4b: drift database, device context, build runner
6. 173068a Integration stage 4c: Drift 2.34.4 web assets
7. 1f25df4 Integration stage 5: infrastructure wiring and bootstrap
8. b53d292 Integration batch 2: Drift web check tool and end-of-batch results
9. 3343f68 Integration: drift_check reads the device_context_entries row
10. fc77244 Integration stage 6: move Products to features/products
11. f38dbbf Integration stage 6 docs: Products pilot decision, progress and layout note
12. 392e52e Integration docs: module migration policy and AppShell as app chrome
13. 9ce36fd Integration: save the move-and-rewrite-imports script under tool/integration
14. c50e551 Integration stage 7a: PaymentService interface and mock
15. 9fb2476 Integration stage 7b: optional saleId on new sales
16. 326280f Integration stage 7c: checkout goes through PaymentService and creates the saleId
17. e8f1d26 Integration: debug_check completes a cash sale and checks the stored saleId
18. 302586e Integration stage 7 docs: PaymentService and saleId decision, gaps, progress
19. (this report and the progress note, committed after this list was generated)

## 10. Pointers
`docs/integration/`: audit_report.md, integration_plan.md, codex_workflow.md, money_core_differences.md, currency_tax_design.md, progress.md, final_report.md. Tools: `tool/web_check/{debug_check,drift_check}.mjs`, `tool/integration/move_feature.py`.

## Appendix: `git diff main..integration --stat` (before this report)
```
CLAUDE.md                                          |    10 +
 build.yaml                                         |     6 +
 docs/decisions.md                                  |     9 +
 docs/integration/audit_report.md                   |    63 +
 docs/integration/codex_workflow.md                 |    42 +
 docs/integration/currency_tax_design.md            |    32 +
 docs/integration/integration_plan.md               |    27 +
 docs/integration/money_core_differences.md         |    15 +
 docs/integration/progress.md                       |    49 +
 docs/known_gaps.md                                 |     6 +
 docs/phase_b_backlog.md                            |     8 +
 lib/core/bindings/app_infrastructure.dart          |    73 +
 lib/core/bindings/initial_binding.dart             |    55 +-
 lib/core/bindings/startup_diagnostics.dart         |    27 +
 lib/core/config/app_config.dart                    |    22 +
 lib/core/constants/app_strings.dart                |     1 +
 lib/core/constants/en_app_strings.dart             |     3 +
 lib/core/data/data_source.dart                     |     5 +
 lib/core/data/mock_json_data_source.dart           |    42 +
 lib/core/database/axpert_database.dart             |    30 +
 lib/core/database/axpert_database.g.dart           |   333 +
 lib/core/database/database_config.dart             |    10 +
 lib/core/database/database_provider.dart           |     8 +
 lib/core/database/database_provider_factory.dart   |    10 +
 lib/core/database/database_provider_stub.dart      |    15 +
 lib/core/database/drift_device_context_store.dart  |    42 +
 lib/core/database/managed_database_provider.dart   |    39 +
 lib/core/database/native_database_provider.dart    |    35 +
 .../database/tables/device_context_entries.dart    |    15 +
 lib/core/database/web_database_provider.dart       |    26 +
 lib/core/device/device_context.dart                |    28 +
 lib/core/device/device_context_service.dart        |    57 +
 lib/core/device/device_context_store.dart          |     8 +
 lib/core/device/device_id_generator.dart           |    18 +
 lib/core/errors/api_transport_failure.dart         |    12 +
 lib/core/errors/app_failure.dart                   |    18 +
 lib/core/errors/data_source_failure.dart           |     9 +
 lib/core/identifiers/uuid_generator.dart           |     3 +
 lib/core/identifiers/uuid_v4_generator.dart        |    22 +
 lib/core/lifecycle/app_lifecycle_service.dart      |    37 +
 lib/core/network/api_client.dart                   |     7 +
 lib/core/network/api_method.dart                   |     1 +
 lib/core/network/api_request.dart                  |    17 +
 lib/core/network/api_response.dart                 |    11 +
 lib/core/network/dio_api_client.dart               |    63 +
 lib/core/result/result.dart                        |    38 +
 lib/core/routes/app_pages.dart                     |     4 +-
 lib/core/security/authenticated_session.dart       |     7 +
 lib/core/security/authentication_request.dart      |     5 +
 lib/core/security/authentication_service.dart      |    14 +
 lib/core/security/secure_credential_store.dart     |    11 +
 .../unconfigured_authentication_service.dart       |    24 +
 lib/core/session/session_controller.dart           |    56 +
 .../data/services/mock_payment_service.dart        |    29 +
 .../payment/domain/entities/payment_method.dart    |     3 +
 .../payment/domain/entities/payment_request.dart   |    19 +
 .../payment/domain/entities/payment_result.dart    |    24 +
 .../payment/domain/entities/payment_status.dart    |     1 +
 .../payment/domain/services/payment_service.dart   |    10 +
 .../products/data/datasources}/large_dataset.dart  |     8 +-
 .../products/data/datasources}/seed_products.dart  |     8 +-
 .../repositories}/mock_product_repository.dart     |    14 +-
 .../products/domain/entities}/product.dart         |    12 +-
 .../domain/repositories}/product_repository.dart   |     2 +-
 .../presentation}/bindings/products_binding.dart   |     2 +-
 .../controllers/products_controller.dart           |     4 +-
 .../controllers/products_page_controller.dart      |     4 +-
 .../presentation/pages}/products_view.dart         |    20 +-
 lib/main.dart                                      |     7 +-
 lib/modules/pos/bindings/pos_binding.dart          |     2 +-
 .../pos/controllers/cart_actions_controller.dart   |     4 +-
 lib/modules/pos/controllers/cart_controller.dart   |     2 +-
 .../pos/controllers/catalog_controller.dart        |     4 +-
 .../pos/controllers/global_search_controller.dart  |     4 +-
 .../pos/controllers/hold_recall_controller.dart    |     2 +-
 .../pos/controllers/payment_controller.dart        |   111 +-
 .../pos/controllers/price_check_controller.dart    |     4 +-
 lib/modules/pos/controllers/scan_controller.dart   |     2 +-
 lib/modules/pos/models/cart.dart                   |     2 +-
 lib/modules/pos/models/cart_line.dart              |     2 +-
 lib/modules/pos/services/checkout_service.dart     |     2 +
 lib/modules/pos/services/hold_recall_service.dart  |     2 +-
 lib/modules/pos/services/product_search.dart       |     2 +-
 lib/modules/pos/widgets/catalog_panel.dart         |     2 +-
 lib/modules/pos/widgets/catalog_product_card.dart  |     4 +-
 lib/modules/pos/widgets/product_grid.dart          |     2 +-
 lib/modules/products/bindings/.gitkeep             |     0
 lib/modules/products/controllers/.gitkeep          |     0
 lib/modules/products/models/.gitkeep               |     0
 lib/modules/products/repository/.gitkeep           |     0
 lib/modules/products/views/.gitkeep                |     0
 lib/modules/products/widgets/.gitkeep              |     0
 lib/modules/returns/bindings/returns_binding.dart  |     4 +-
 .../returns/controllers/returns_controller.dart    |     2 +-
 .../returns/repository/mock_return_repository.dart |     2 +-
 .../returns/repository/return_repository.dart      |     2 +-
 lib/modules/sales/models/sale.dart                 |     8 +
 lib/modules/shell/widgets/search_results.dart      |     2 +-
 pubspec.lock                                       |   308 +-
 pubspec.yaml                                       |     6 +
 test/core/bindings/infrastructure_test.dart        |   105 +
 test/core/config/app_config_test.dart              |    12 +
 test/core/data/mock_json_data_source_test.dart     |    90 +
 .../database/native_database_provider_test.dart    |    92 +
 test/core/device/device_context_service_test.dart  |    98 +
 test/core/errors/app_failure_test.dart             |    26 +
 test/core/identifiers/uuid_v4_generator_test.dart  |    28 +
 test/core/network/dio_api_client_test.dart         |   115 +
 test/core/result/result_test.dart                  |    30 +
 test/core/routes/app_pages_test.dart               |     2 +-
 .../services/pricing/axpert_crosscheck_test.dart   |   159 +
 test/core/session/session_controller_test.dart     |    62 +
 .../payment/mock_payment_service_test.dart         |    49 +
 .../products/management_layout_test.dart           |     4 +-
 .../products/management_performance_test.dart      |     4 +-
 .../products/products_page_test.dart               |     4 +-
 test/golden/shell_golden_test.dart                 |     2 +-
 test/layout/full_sweep_test.dart                   |     2 +-
 test/layout/route_navigation_test.dart             |     2 +-
 test/layout/semantics_reparent_test.dart           |     2 +-
 test/layout/touch_targets_test.dart                |     2 +-
 test/modules/pos/cart_controller_test.dart         |     2 +-
 test/modules/pos/cart_layout_test.dart             |     2 +-
 test/modules/pos/cart_rules_test.dart              |     2 +-
 test/modules/pos/cart_view_test.dart               |     2 +-
 test/modules/pos/catalog_view_test.dart            |     2 +-
 test/modules/pos/checkout_service_test.dart        |    10 +-
 test/modules/pos/dialogs_layout_test.dart          |     2 +-
 test/modules/pos/hold_recall_flow_test.dart        |     2 +-
 test/modules/pos/hold_recall_service_test.dart     |     2 +-
 test/modules/pos/models_test.dart                  |     4 +-
 test/modules/pos/payment_flow_test.dart            |     2 +-
 test/modules/pos/payment_service_flow_test.dart    |   231 +
 test/modules/pos/performance_test.dart             |     2 +-
 test/modules/pos/repositories_test.dart            |     6 +-
 test/modules/pos/search_performance_test.dart      |     4 +-
 test/modules/pos/search_services_test.dart         |     2 +-
 test/modules/pos/seed_test.dart                    |     2 +-
 test/modules/pos/summary_layout_test.dart          |     2 +-
 test/modules/returns/refund_service_test.dart      |     2 +-
 test/modules/returns/returns_layout_test.dart      |     4 +-
 test/modules/returns/returns_page_test.dart        |     2 +-
 test/modules/sales/receipt_flow_test.dart          |     2 +-
 test/modules/sales/receipt_layout_test.dart        |     2 +-
 test/modules/sales/receipt_units_test.dart         |     2 +-
 test/modules/sales/sale_id_test.dart               |    64 +
 test/modules/shift/shift_flow_test.dart            |     2 +-
 test/shared/modal_actions_pair_test.dart           |     2 +-
 test/support/pos_support.dart                      |     2 +-
 test/support/sale_fixtures.dart                    |     2 +
 test/support/test_app.dart                         |    10 +-
 test/support/test_infrastructure.dart              |    66 +
 tool/integration/move_feature.py                   |    85 +
 tool/integration/products_moves.json               |    25 +
 tool/web_check/debug_check.mjs                     |    20 +
 tool/web_check/drift_check.mjs                     |    81 +
 web/drift_worker.js                                | 13386 +++++++++++++++++++
 web/sqlite3.wasm                                   |   Bin 0 -> 748686 bytes
 158 files changed, 16962 insertions(+), 150 deletions(-)
```
