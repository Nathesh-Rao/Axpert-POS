# Plan: DB-driven demo POS + offers (branch `integration`)

## Context
Today the app runs on hardcoded business data: one store name in `AppSettings`, a fake cashier, 20 seed products and 4 customers in `lib/`, INR as a compile-time default, and a login that accepts anything. This task moves business data into Drift, seeded once by a `DemoSeeder`, adds users/stores/counters with a real login, and adds three automatic offer types (discount, buy-1-get-1 half price, free item by cart value). Pricing stays byte-identical for carts without offers. `axpert_pos/` and `reference_react/` are not touched.

Findings that shape the plan (from exploring the code):
- Schema is v8 (`axpert_database.dart:40`), stepwise transactional `_upgrade`; 6 Drift repositories (settings, customers, held, products, sales, cart) all dual-write a LocalStore mirror and fall back to it on failure.
- No users/stores/counters/categories/currency tables exist. A store is the string `AppSettings.store`; the counter is `axpert-counter` = `'C3'`; the cashier is the constant `MGTCASH3` (`receipt_builder.dart:10`).
- `PricingService` is exact `Rational`, rounded once per total field (value, subtotal, discount, tax, points, total) in `calculate()` (`pricing_service.dart:25-45`). It is constructed `const PricingService()` in `CartController` (`cart_controller.dart:24`), the single hook for offers (`totalsOf`, line 116).
- Cart is one line per `product.id`; cart JSON is stored whole, so offers derived at calc time need no cart-schema change.
- `crypto` 3.0.7 is already in `pubspec.lock` (transitive); it only becomes a direct dependency (approved for this task; supports Windows/macOS/web).

## STEP 0: push `integration` (first action after approval)
1. `git status`. Currently clean and level with `origin/integration`, so: `git commit --allow-empty` with message `before seeding db data v1` plus the two trailers (`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`, `Claude-Session: https://claude.ai/code/session_01Ht6ZfVLgoUbcN2eKphKPqq`). If it turns out to be dirty, commit the changes with the same message instead.
2. `git push origin integration` (plain push, no force, not main).
3. `git log -1` and `git status -sb` to verify; report the hash.
4. `git tag pre-promotions` on that commit, `git push origin pre-promotions`. (Tag does not exist yet.)
No other commits afterwards; everything else stays uncommitted.

## 1. Hardcoded-data inventory

| Item | Where now | Owning table | When |
|---|---|---|---|
| Store name `MAISON GALAXY - OZONE`, store list (3 names) | `app_settings.dart:16`, `en_app_strings.dart:106`, `top_bar.dart:109` | `stores` | now |
| Store address, phone, tax id, receipt header/footer | nowhere (receipt brand `AXPERT POS`, tagline, footer in `en_app_strings.dart:716-761`) | `stores` (new columns) | now (receipt uses store row; labels stay in code) |
| Counter `C3` (`axpert-counter`) | `app_settings.dart:19`, `StorageKeys.counter` | `counters` (belong to a store) | now; picked after login, setting key removed from use |
| Cashier `MGTCASH3`, role `Cashier` | `en_app_strings.dart:158,161`, `receipt_builder.dart:10` | `users` (+ `user_access`) | now |
| Login accepts any input | `login_controller.dart` | `users` (salted SHA-256) | now |
| Currency (INR default, symbol, exponent, grouping) | `CurrencyRegistry` (12 entries), `TaxConfig.india`, INR fallbacks in `sale_rows.dart:593`, `sale.dart`, `cart.dart`, `shift_summary.dart`, `product.dart` | `currencies` row referenced by `stores.currency_code` | now. Registry stays only as a fallback for legacy rows and tests; `sale_rows.dart:593` is fixed to use the stored code |
| `Flat amount ₹` | `en_app_strings.dart:617` | active currency row symbol (parameterized string) | now |
| Quick cash amounts `[100,500,2000]` | `cash_panel.dart:25` | `currencies.quick_cash` | now |
| Products (20) + barcodes/stock/favourites | `seed_products.dart`, `large_dataset.dart` | `products` (+ `store_id`) | now; code moves into the seeder |
| Categories / subcategories | `CatalogCategory` enum, `catalog_taxonomy.dart` | `categories` (names, parent, position; icon key maps to Lucide in code) | now |
| Variants | none | `products.variant_group/variant_label` (siblings; no new UI) | now |
| Customers (4) | `core/mock/seed_customers.dart` | `customers` (existing) | now; seed only |
| Sales history | none (3 test sales only) | `sales`, `sale_lines`, `payments` | now; seed ~30 |
| Held bills | runtime only | `held_bills` (+ `store_id`) | store scoping now |
| Offers | none | new `offers` | now |
| Member-lookup hint `MG1001..` , search hints `BDV001`, `Coca Cola` | `en_app_strings.dart:538,655-675` | UI hints | later (strings; no data effect); flagged in known gaps |
| Forex list `USD/EUR/AED/FC`, `$` label, rate `8561` | `forex_controller.dart:16`, `app_settings.dart:20` | settings / currencies | later (Batch 2b with regional tax; KG-107) |
| Tax slabs 0/5/12/18, label `GST`, exclusive mode | `tax_config.dart:18` | stores `region` + tax config | later (Batch 2b). `stores.currency_code`/`region` columns exist now; `TaxConfig.india` with the store's currency swapped in is used until then |
| Payment modes Cash/Card/Credit | `checkout_service.dart:10`, `payment_method.dart` | logic enums | stays (behavior, not data) |
| Sale number prefix `AX` | `checkout_service.dart:71` | later (KG-008) | later |
| `MockDelay`, `ToastController.maxVisible`, search limit | code constants | n/a | stays (UI/behavior) |
| UI labels, theme, icons, shortcuts, layout | code | n/a | stays |

**Empty state (DB empty, `DEMO_SEED` off):** no seed fallback anywhere in `lib/` (the `products_migrator`/`customers_migrator`/`LocalStoreSeeder` fallback seeding is removed; mock repositories default to empty lists). Login shows an empty state ("No users are set up on this device", no hint of credentials). With `SKIP_ENTRY` and an empty DB the shell opens with store label "No store", empty catalog message, no demo anything. Legacy installs: rows already in Drift/LocalStore keep working (while `stores` is empty, repositories behave as today, unscoped).

## 2. Schema v9 (one transactional step in `_upgrade`, then migration tests)
New tables (all with `created_at/updated_at/deleted_at`; ids are text UUIDs): `currencies` (code PK, name, symbol, exponent, grouping, quick_cash), `stores` (name, address, phone, tax_id, receipt_header, receipt_footer, `currency_code` FK, `region`, active), `counters` (store_id FK, name, active), `users` (username unique, display_name, role, `salt`, `password_hash`, `hash_algo`, active), `user_access` (user_id, store_id, counter_id null = any counter), `categories` (store_id null = all, name, parent_id, icon_key, position), `offers` (below), `seed_manifest` (table_name, row_id).
`offers`: id, kind (`discount|promotion|gift_tier`), name, store_id (null = all), product_id (discount/promotion), percent_bp, fixed_amount_minor, currency_code, min_cart_minor, gift_product_id, starts_at, ends_at, active, priority. CHECK constraints per kind. Drift-only, no LocalStore mirror.
Altered (additive, nullable): `products` + `store_id, category_id, variant_group, variant_label`; `held_bills` + `store_id`; `sales` + `store_id, counter_id, user_id, user_name`; `sale_lines` + `offer_kind, offer_name, offer_saving_minor, is_gift`.
Mirror rule: when `stores` is non-empty (scoped mode), products/sales/held repositories do not write the LocalStore mirror or use the stale-fallback (one store's list must not overwrite another's). Legacy mode is unchanged.
Tests: v8 DB with existing products/sales/cart/held rows upgrades to v9 with all rows intact and defaults null; migration is atomic (forced failure rolls back); fresh install `createAll`; seeded-store scoping.

## 3. Offers and pricing (pure Dart, additive)
New `OfferEngine` (plain Dart, `core/services/offers/`, no GetX/Flutter, integer/Rational only): input = cart lines, active offers, store currency, clock; output = per-line resolved `LineInput` fields + per-line offer label/saving + gift rows (locked/unlocked) + `offerSaving` total. Called from `CartController.totalsOf`; with no offers its output equals today's input exactly.

`LineInput` gets ONE new optional field `unitOff` (Money, default zero). `PricingService` is otherwise untouched; percentages and the 50% promo reuse the existing line `discount` Bp.

**Per-line math** (q = qty milli/1000, p = unit price minor, all exact `Rational`, rate t in Bp):
- gross = q·p (unchanged; `value` stays gross at the original price, so the saving appears in the Discount line)
- Discount offer percent b: net = gross·(1 − b/10000). Fixed amount f per unit: net = q·max(0, p − f).
- **Buy 1 Get 1: net = gross·(1 − 5000/10000) = gross/2.** Every unit, from the first; no pairing, so odd and fractional quantities are the same linear formula.
- tax_i = net_i·ratio·t (ratio from the existing proportional bill-discount allocation); payable, points, total exactly as today.
- **Rounding happens once**, in `calculate()` at the existing six points, half-up on the exact total (prototype rule). No per-line rounding. The cart row's displayed line total keeps the existing `LineMath.lineTotal` (rounds once per line, display only), so displayed parts may differ from the total by 1 minor unit, same as today.

Worked vectors (INR, GST 18% exclusive, p = 100.00):
- 1 unit: gross 10000, net 5000, tax 900, total 5900, saving 5000.
- 2 units: 20000 / 10000 / 1800 / 11800. 3 units: 30000 / 15000 / 2700 / 17700.
- 1.500 units at 99.99: gross 14998.5 → 14999, net 7499.25, discount 7499, tax 1349.865 → 1350, total 8849.115 → 8849 (rounded fields do not re-sum, like the prototype).
- Free-item tier X = 500.00: cart value 499.99 locked; 500.00 unlocked (≥); drop back to 499.99 relocks; gift line price 0, totals unchanged by it.

**Rules (decided here, ambiguity settled):**
1. Automatic offers never stack on one product. Priority promotion > discount. A manual line discount (cashier-typed, > 0) overrides: no automatic offer on that line.
2. Only offers inside `starts_at..ends_at`, `active`, store match (or null) and matching currency (for money fields) apply.
3. Free-item tiers use cart value = Σ line nets after discounts/promotions and manual line discounts, before bill discount, points and tax (so a bill discount cannot revoke a gift). Gift lines are 0 so there is no circularity. Each tier is independent: every tier whose threshold is reached unlocks its own item (qty 1). A gift whose stock is 0 is not offered.
4. Gifts are derived, not stored in the cart: `Cart` and held-bill JSON are unchanged. At checkout, unlocked gifts are materialised as `price 0` lines in the sale snapshot (so stock is deducted, the receipt shows them, refund weight is 0 and refunds 0 through the existing gross-weighted `PricingHelpers.refund`).
5. Sale lines persist `offer_kind/offer_name/offer_saving_minor/is_gift`. A promo line refunds by the existing gross-weighted formula (same behaviour as manual line discounts, KG-165); logged as a known gap, helper not changed.
6. Badge on a tile: one only, priority promotion > discount > gift. **Decision: text pills, no icons**: `-20%` / `-₹50` (currency symbol from the active currency), `Buy 1 Get 1`, `Free gift`. Discount tile also shows the original price struck through beside the new price.
7. Cart line shows offer name and `saved <amount>` under the name. Locked gift row: lock icon, name, "Add <amount> more to unlock", not editable. Unlocked: price 0, "Free gift" label, not editable or removable. All text through `AppStrings`, styling through tokens.
New optional params on `ProductCard` (`strikePrice`, `offerLabel`) default to null so existing goldens are unchanged.

**Pricing tests:** the 300 vectors and the s6 fixtures are not edited (stop rule (a)). New fixture `test/fixtures/offers_golden.json` (hand-derived, plus a test that re-derives each with an independent BigInt computation): 1/2/3 units, fractional, with tax (both tax modes), tier crossing up and down, discount percent and fixed, priority, no-stacking, expired/future offers. A property test asserts offer-free carts produce results identical to the pre-change service.

## 4. Seed (`DemoSeeder`)
`lib/core/seed/` (the only place in `lib/` that knows demo data: loader, seeder, perf generator moved from `large_dataset.dart`) + JSON in `assets/seed/` (registered in `pubspec.yaml`): `currencies, stores, counters, users, user_access, categories, products, customers, offers, sales`.
- 2 stores in different currencies (INR with lakh grouping, and one 0- or 3-decimal currency to exercise exponent), 2-3 counters each, 4 users (admin: both stores; manager: store 1; cashier A: one store, one counter so the picker is skipped; cashier B: store 2), ~60 products with categories and variants (per-store catalogs, prices in the store currency), 6 discounts, 4 half-price promotions, 3 free-item tiers, ~30 sales (dates as "days ago", totals computed with `PricingService`), a few customers.
- Seeding: `--dart-define=DEMO_SEED=true`, one transaction, writes marker `demo_seed_v1` in `migration_state` and every inserted id in `seed_manifest`. `RESEED_DEMO=true` deletes only manifest rows (sales first, nulling FK references from user-made rows) and re-runs. Without the flag nothing is seeded.
- Demo passwords sit in `assets/seed/users.json` as plaintext demo values (as requested, listed in assets/seed and the final report); they are hashed with a random salt at seed time, never logged, never in code. Logged as a known gap (bundled with the app; slow KDF later).
- Existing demo data removed from `lib/`: `seed_products.dart`, `seed_customers.dart`, default store/counter/cashier values. Tests get them from `test/support/` fixtures (copies), injected into `MockProductRepository`/`MockCustomerRepository` and the test session (store `MAISON GALAXY - OZONE`, counter `C3`, cashier `MGTCASH3`) so existing goldens stay byte-identical.

## 5. Login, session, store/counter
- `crypto` becomes a direct dependency. Password hash = `sha256(salt ‖ password)` hex, random 16-byte salt per user, `hash_algo` column for a future KDF. Constant-time compare. Wrong credentials: generic error, no username enumeration; no passwords in logs.
- `UsersRepository` (interface + Drift impl, controllers use only the interface) and `AuthenticationService` implementation replace `UnconfiguredAuthenticationService`; `LoginController` validates against `users`.
- After login: stores/counters the user may access come from `user_access`. If exactly one store and one counter: skip the picker; otherwise a new picker page (route `/select-session`, module `entry`). A permanent `ActiveSession` controller holds user, store, counter, currency; `CurrencyRegistry` is loaded from the `currencies` rows at start and the store's currency drives `PricingService` config (`TaxConfig.india.copyWith(currency)`), `MoneyFormatter`, `Flat amount <symbol>`, quick-cash amounts, receipt header/footer/address/phone and the cashier name. Products, held bills and offers are loaded scoped to the store; switching store in the top bar is allowed only with an empty cart (toast otherwise).
- `SKIP_ENTRY=true` keeps working: it auto-creates a session for the first active user/store/counter in the DB (empty DB: no session, empty states). Tests use an in-memory seeded DB (`NativeDatabase.memory()` plus `DemoSeeder`) for the new tests; existing tests keep their fixtures via test support. Debug/web check scripts (`entry.mjs`, `debug_check.mjs --entry`) are updated with the seed credentials.
- Roles are stored and shown, not enforced (later; known gap).

## 6. Execution order (one uninterrupted run, checkpoints internal)
0. Step 0 push and tag.
1. Pricing `unitOff` + `OfferEngine` + new vectors, run the 300 + s6 vectors immediately (fail fast on stop rule (a)).
2. Schema v9, tables, migration tests (stop rule (c)).
3. Currencies/stores/session/formatter wiring; removal of INR defaults from business paths.
4. Users, crypto, login, picker, `SKIP_ENTRY`.
5. Seeder and assets; remove demo data from `lib/`; test-support fixtures; empty states.
6. Offers repository + controller, tile badges, cart rows, checkout/receipt persistence.
7. New goldens, docs, checks, report.

## 7. Checks
- Per checkpoint: `dart format` on touched files, `flutter analyze` clean, tests of touched folders. Once at the end: `dart format --output=none --set-exit-if-changed .`, full VM suite. No Chrome tests.
- Goldens: all existing goldens byte-identical; if any changes, stop and report. New goldens (light and dark): discount badge tile, Buy 1 Get 1 tile, locked gift row, unlocked gift row. `route_navigation_test` gains the picker route; `semantics_reparent_test` run since widget structure changes.
- Release web check: build with `DEMO_SEED=true`, reload and confirm data persists (marker, no re-seed), offers on tiles and in the cart, a checkout with an offer gives the right sale and receipt (`drift_check.mjs` reads the rows), a second store shows its own currency symbol/digits; `web_check` at 950x733, 1280x720, 1868x1035. Debug click-through in normal and `--semantics` modes (fresh `flutter run` per run, cleanup after).
- Docs: `decisions.md` (new DEC entries: session/scoping, offers rules, mirror rule, seed manifest, password hashing), `known_gaps.md` (new KG entries from KG-202: plaintext demo passwords in assets, single-round SHA-256, promo refund weighting, roles not enforced, forex/tax/hint strings later, legacy-mode fallbacks), `docs/integration/progress.md`, and this plan saved as `docs/plan_demo_offers.md`.

## Stop rules (as given)
Stop and ask only if: an existing golden or vector changes; a package other than `crypto` is needed; the v9 migration fails on existing data; the half-price rule hits an ambiguity not settled above. No commits beyond Step 0; work is left uncommitted.

## Final report (short)
Inventory with what moved/stayed, test counts, golden changes (expected: none to existing), known gaps, demo credentials, how to run with `DEMO_SEED`.


## Deviations from this plan (found while building)
- The `OfferEngine` lives in `features/offers/domain/services` (it uses the `Product` entity), not `core/services/offers`.
- Categories are created and seeded but the catalog chip row is still the `CatalogCategory` enum (KG-202). Variants are seeded as sibling SKUs.
- Goldens: three scenes (catalog tiles with the three badges, cart with a locked free item, cart with an unlocked free item) in light and dark = 6 PNGs; the discount and Buy 1 Get 1 badges share the tiles scene.
- `route_navigation_test` now also walks login to the picker to the landing page with the no-error checks; `entry_session_test.dart` covers the picker, the wrong-password error and the empty-users state.
- Seed JSON is grouped (counters inside `stores.json`, access inside `users.json`) instead of one file per table.
- `SKIP_ENTRY_USER` (dart-define) picks the user `SKIP_ENTRY` signs in.
- Fixed a bug found by the Kampala check: the shift summary defaulted to INR (`ShiftController` now passes the store's currency).
