# Integration progress

Branch `integration` (from `main` d5b2975). axpert_pos is read-only and untouched.

## Batch 1 (docs and pure Dart)
- Stage 0: branch `integration` created, tree was clean.
- Stage 1: docs written (`audit_report`, `integration_plan`, `codex_workflow`, this file); CLAUDE.md updated (integration workflow section).
- Stage 2: ported from axpert_pos into `lib/core/{result,errors,data,config,identifiers}`: `Result<T>`, `AppFailure`/`UnexpectedFailure`/`DataSourceFailure`/`ApiTransportFailure`, `DataSource<T>`, `MockJsonDataSource`, `AppConfig`/`DevelopmentAppConfig`, `UuidGenerator`/`UuidV4Generator`. Tests ported plus a new UUID v4 test (10 tests, pass). Not registered anywhere yet.
- Stage 3: cross-check `test/core/services/pricing/axpert_crosscheck_test.dart` (3000 deterministic carts, both tax modes, scale <= 3, no discounts). Result: the rule sets DIFFER (see below). Per decision D1 work stopped here for the owner's decision. No money/pricing code was changed.

### Stage 3 findings
1. Rounding point: axpert rounds each line's extension and each line's tax half-up and sums the rounded lines; ours computes exact values and rounds once per cart total (prototype-compatible, golden vectors). Results differ by 1 minor unit in many multi-line carts and in some single-line carts with fractional extension (exclusive total: 941 multi-line + 130 single-line of 3000; tax 469 + 10; inclusive tax 480 + 4). They agree for one-line carts with whole-unit quantity.
2. Meaning of `subtotal` in inclusive mode: axpert = net of tax (sum of total - tax); ours = gross value (tax-inclusive). Not a rounding issue; differs in most inclusive carts.
3. Other known differences (by design, not tested): ours has line/bill discount, points, negatives; axpert `multiplyRatio` is non-negative only; `Quantity` scale > 3 is not representable in `Qty`.
Open question for the owner: keep ours as is and document the differences (golden vectors untouched), or define an adapter for any axpert-facing contract later.
