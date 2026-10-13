# Plan: store-driven forex and tax (schema v10)

Branch `integration` (on 9c7eab0), repo `pos_application` only. axpert_pos, reference_react untouched. New plan doc: `docs/plan_store_forex_tax.md` (copy of this).

## Context
Bill Summary still has hardcoded forex (USD/EUR/AED/FC list, `$` label, rate 8561 in `AppSettings.rateMilli` / `ForexController`) and `ActiveSession.pricing` uses `TaxConfig.india` for every store. Both must come from the active store's DB rows. Reuses `docs/integration/currency_tax_design.md` (B3 `TaxRegime` split on top of `PricingService`, largest-remainder, `stores.region` as plug point).

## Decisions settled in this plan (owner answers)
- CGST/SGST do not exist in lib/ today (only in the design doc). India gets NEW CGST + SGST rows (each half of the rounded total tax, odd minor unit to SGST, flagged for accountant) under the tax row on Bill Summary and on the receipt. **This changes India goldens that show tax; owner approved regeneration** (overrides the "no golden may change" stop rule). I list every regenerated golden in the report; any other golden change = STOP.
- Demo rates (micro units, 1 foreign = X store currency): India: USD 83.20, EUR 90.50, AED 22.65 INR. Kampala (UGX): USD 3,700, EUR 4,000, KES 28.50. Currencies seed gets USD, EUR, KES rows (AED/INR/UGX exist).
- No regime (empty DB / store with unknown region): tax 0, tax row, label and split hidden; no slabs invented in code. No active store_forex rows: forex panel hidden entirely.

## 1. Schema v10 (`lib/core/database/`)
New tables (files in `tables/`, registered in `axpert_database.dart`, `schemaVersion => 10`):
- `store_forex`: id, store_id (FK stores), foreign_currency_code (FK currencies), rate_micro int (never double), active, position, created/updated; unique (store_id, code).
- `tax_regimes`: id, region (unique key, e.g. `IN`, `UG`), label (`GST`/`VAT`), price_mode (`exclusive`/`inclusive`, CHECK), split_parts (text, e.g. `CGST,SGST`, empty = none).
- `tax_slabs`: id, regime_id (FK), rate_bp, label, position.
Migration `from < 10`: ONE `transaction` creating the 3 tables; existing v9 data untouched. Tests (`test/core/database/`): v9 DB with rows upgrades intact; forced failure (injected throw inside the step) rolls back, version stays 9.

## 2. Seed (`assets/seed/*.json`, `demo_seeder.dart`)
- Add `store_forex.json`, `tax_regimes.json` (IN: GST exclusive CGST,SGST, slabs 0/500/1200/1800; UG: VAT exclusive, no split, slabs 0 and 1800 "Standard 18%"), tax slabs nested in regimes; extend `currencies.json` (USD, EUR, KES).
- Kampala products: `gstBp` values become VAT slab values (0 or 1800), product tax comes from a slab of the store's regime (product row keeps the rate; seeder validates it exists in the regime, test asserts it).
- Marker `demo_seed_v2`; seeded ids recorded in `seed_manifest`. A v1-seeded DB (marker v1 present) with `RESEED_DEMO=true`: delete only manifest rows, re-insert, user-made rows kept; without reseed a v1 DB still gets the new rows added additively (insert missing manifest-tracked forex/regime/slab/currency rows). Tests for both paths.

## 3. Forex from DB
- Repository: extend `StoreRepository` (`features/session/domain`) with `loadForex(storeId)` + `loadTaxRegime(region)`; Drift impl in `drift_session_repositories.dart`, in-memory impl for tests (default test session: no forex rows, India regime test-support).
- `ForexController`: loads active store's rows on `ActiveSession.onActivate` (`initial_binding._activate`), `currency` = selected code (first row), `rateMicro` from the row; remove `currencies` const, `settingsRate`, `commitRate`, `rateMilli`, and `AppSettings.rateMilli` / rate key / `forexCurrencyLabel` `$` special-case / `forexFc()` ("FC" label = selected code). The rate field edits are removed from settings persistence (rate is DB data; editing it is a known gap).
- `PricingHelpers.forexConvert...`: integer/Rational: `foreignMinor = round_half_up(totalMinor * 1e6 * 10^fexp / (10^exp * rateMicro))`, rounded once. Old milli helper stays only if tests need it, else replaced; new unit vectors (exponents 0/2/3, rounding, zero rate).
- `ForexCard` hidden (no empty box, also zero height in layout metrics) when no active rows; selector lists only the store's codes.

## 4. Tax from DB
- `TaxRegimeConfig` (plain Dart, `core/services/pricing/`): label, mode, slabs, `splitParts`, built from DB rows. `ActiveSession.pricing` builds `PricingService(config: TaxConfig(...regime...))`; no regime -> zero-tax config with label hidden. `TaxConfig.india` moves to `test/support/` (test support only; `lib/` has none).
- `TaxSplit` (plain Dart): splits the rounded `totals.tax` across `splitParts` by largest remainder, sums exactly. PricingService internals unchanged (additive only if needed).
- Mid-session store switch (empty cart only, existing rule): `_activate` reloads forex, regime, slabs; cart totals recompute with the new `PricingService`.
- Label wiring: `summaryTaxAmount` -> "<label> Amount"? Keep "Tax Amount" row wording rule: row label `Tax Amount` stays for India (as today, golden-safe) and uses `<label>` for VAT stores ("VAT Amount"); to be consistent I will use `Tax Amount (GST)`-free scheme: **India "Tax Amount" unchanged, non-India "<label> Amount"**. Cart line caption `gstLabel`, receipt `receiptTax`, products `colGst`, price-check/search-hit strings become `taxLabel`-parameterized from the active regime. No "GST/CGST/SGST/IGST" literal remains in `en_app_strings.dart` or any widget.
- UI: `totals_card` + `receipt_totals` + `ReceiptDocument` gain `taxParts` (list of label+Money); India renders CGST/SGST rows, VAT one line. Sale snapshot stores split lines as computed at sale time (receipt/reprint use them; old sales fall back to a single line).

## 5. Tests
- New VAT vectors (exclusive and inclusive, UGX exponent 0, multi-slab) and forex vectors as own fixtures (`test/fixtures/vat_golden.json`, `forex_golden.json`); the 300 vectors, s6 fixtures, offers_golden untouched and passing.
- Unit: `TaxSplit` sums, regime builder (empty -> zero tax), forex controller, repositories, route-navigation test updated for both stores.
- Goldens: new Bill Summary (VAT + forex shown; no forex / hidden) light + dark. Regenerated (approved): India goldens that render tax rows. Everything else must stay byte-identical; otherwise STOP.
- Order: dart format, flutter analyze, per-folder tests while working, full VM suite once at end (no Chrome tests).

## 6. Web checks
Release build with `DEMO_SEED=true` + `tool/web_check`: cashier1 (India) GST, CGST/SGST, forex selector + rates; cashier2 (Kampala) VAT everywhere including receipt, no GST/CGST/SGST, own forex list and rates; screenshots of Bill Summary for both viewed. Debug-mode `debug_check.mjs` normal and `--semantics`, per CLAUDE.md.

## 7. Docs and commit
Update decisions (DEC: forex/tax from DB, split convention, no-regime behaviour, demo_seed_v2), known_gaps (forex rate not editable, odd-minor convention unconfirmed, receipts of old sales single-line, no IGST), `docs/integration/progress.md`, new plan doc. Commit locally, no push, exact message:
```
Make forex and tax store-driven from the DB
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Ht6ZfVLgoUbcN2eKphKPqq
```
Final report: what moved, hardcoded business data left, test counts, golden changes, known gaps.

## Stop rules (unchanged)
STOP only if an unapproved golden or a vector changes, a new package is needed, v10 migration fails on existing data, or the design doc conflicts in an unsettled way.
