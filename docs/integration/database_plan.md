# Local database design and sync readiness (Phase B plan)

Date: 2026-10-12. PLAN ONLY: no code, no schema and no persistence change is made by this document. `axpert_pos` was only read and ADR-014 there is not edited. Facts about axpert_pos are in `axpert_db_sync_digest.md` (same folder; rows are cited as "digest N.N"); facts about our data come from a read-only inventory of `LocalStore` and the repositories.

Tags used for every proposed table or column: **[AX-D]** decided in axpert_pos docs/code; **[AX-C]** axpert candidate (proposed there, not approved); **[PROTO]** exists today in the prototype port (our `LocalStore` data); **[NEW]** our proposal, nothing in axpert or the prototype. Everything in sections 2 and 3 is PROPOSED until the owner approves an implementation stage.

## 0. Position on the ADR-014 gate (recommendation, owner decides per stage)
axpert's ADR-014 forbids any operational Drift table until 16 backend/product/security/operations items are resolved (all 16 are open, digest 5). Phase B needs durable local storage now. **Recommendation:** pos_application records its own decision (DEC-124) to build a PROVISIONAL, LOCAL-ONLY operational schema under these conditions, without editing axpert_pos or its ADR:
1. every table and column is marked provisional and nothing in it is a backend contract; no endpoint, DTO or sync call exists;
2. the sync-readiness columns exist but are nullable and unused (section 3);
3. forward-only migrations with automated upgrade tests, preserve-data and stop-safely rules from digest 1.4 to 1.6 are followed from the first table;
4. the migration from `LocalStore` (section 4) cannot lose data;
5. each implementation stage (section 5) still needs its own owner approval; the checkout transaction (5.3) is NOT approved and stays a proposal;
6. any later backend answer (A1 to A12, B1, B2) wins over this document and may force a schema change through a normal forward migration.
The alternative (treat ADR-014 as binding and wait) keeps `LocalStore` as the only persistence and leaves KG-028, KG-101, KG-187 open.

## 1. Inventory of what `LocalStore` stores today
`LocalStore` (`lib/core/services/storage/local_store.dart`): `read/write/remove/has` on decoded JSON; `SharedPrefsLocalStore` writes `jsonEncode(value)` per key as `flutter.<key>` (double-encoded string on web; a corrupt value silently reads as null); `InMemoryLocalStore` for tests. `LocalStoreSeeder.seedIfMissing` writes seeds on first run (products and customers only). There is no versioning, no migration, no reset/clear anywhere.

| Key (`flutter.` prefix in shared_preferences) | Shape | Written by | Read by (when) |
|---|---|---|---|
| `axpert-products` | list of Product | `MockProductRepository.save` (whole list; checkout stock, favourite toggle, returns) | `ProductsController.load` (startup) |
| `axpert-customers` | list of Customer | `MockCustomerRepository.save` (whole list; add customer, points deduction) | `CustomersController.load` (startup) |
| `axpert-cart` | one Cart | `MockCartRepository.save` (coalescing write-behind, flush on demand) | `CartController.load` (startup, last) |
| `axpert-held` | list of HeldBill | `MockHeldBillRepository.save` (whole list, not awaited) | `HeldBillsController.load` (startup) |
| `axpert-sales` | list of Sale | `MockSaleRepository.save` (whole list; checkout, not awaited; returns via `MockReturnRepository`) | `SalesController.load` (startup) |
| `axpert-store`, `-dark`, `-beep`, `-counter`, `-rate` | string, bool, bool, string, int (milli rate) | `SettingsController` (one awaited write per key) | `SettingsController.load` (startup, first) |

Load order: `InitialBinding.loadData`: settings, then products, customers, sales and held bills in parallel, then the cart. Every repository `load/save` first waits 200 to 500 ms (`MockDelay`, zero in tests). Everything is read once into memory; there are no lazy reads.

JSON shapes (money `...Minor` integer minor units, quantities `...Milli` integers, rates basis points; currency is NOT stored and every `fromJson` assumes INR):
- **Product**: `id` int, `name`, `code`, `barcode`, `priceMinor`, `category`, `sub`, `stock` (whole units), `gst` (percent number, e.g. 18 or 5.5, parsed to basis points), `image` (asset index, -1 = none), `favourite`. No nullable field.
- **Customer**: `id` string (`walk`, `1`..`3`, then clock milliseconds), `name`, `phone`, `email`, `member` (`MG` + 5 clock digits), `points`.
- **Cart**: `lines[]`, `customer` (id), `saleType` (Cash/Credit), `discountType` (flat/percent), `billDiscountBp`, `billDiscountMinor`, `reason`, `points`, `note`. **CartLine**: `product` (a FULL Product snapshot), `qtyMilli`, `priceMinor`, `discountBp`.
- **HeldBill**: `ref` (`H` + last 6 digits of epoch ms), `time` (UTC ISO), `cart` (full Cart).
- **Sale**: `number` (`AX` + 6 digits from list length + 1), `saleId` (UUID v4, present only on sales created since Stage 7, key omitted otherwise), `date` (UTC ISO), `store` (a NAME), `customer` (a NAME), `cart` (full snapshot incl. bill discount, reason, note, customer id), `totals` (`items`, `qtyMilli`, `valueMinor`, `subtotalMinor`, `discountMinor`, `taxMinor`, `pointsMinor`, `totalMinor`), `mode` (Cash/Card/Credit), `tenderedMinor`, `changeMinor`, `returned` (map product id to qtyMilli).
- **Settings**: five scalars with per-key defaults.

Volumes: 20 seed products (about 4 KB), 4 customers, sales and held bills unbounded (a 5-line sale about 2 KB; 1,000 sales about 2 MB rewritten in full per sale), debug large dataset 10,000 products about 2 MB (`LARGE_DATASET`, forces a re-seed on every load).
Identity and links: product ids are indexes; the cart line carries a product snapshot, not an id reference; a sale's `returned` map is keyed by product id; `Sale.customer` is a name, the customer id lives only inside `cart.customer`; sale numbers are unique only while sales are never deleted; held refs and customer ids can collide (KG-125, KG-132, KG-008).
Read-time behavior: the cart is silently reset to empty on any error; a bad record in products, customers, sales or held aborts startup; recall drops held lines whose product disappeared and clamps quantities to stock (the controller ignores the "missing products" list).
Seeding in tests/tools: 14 test files use `InMemoryLocalStore`, 11 seed or inspect `axpert-*` JSON by hand; `tool/web_check/debug_check.mjs` seeds three sales without `saleId`.

## 2. Proposed tables (provisional, local, SQLite/Drift)
Conventions (all PROPOSED): primary key `id` TEXT = UUID v4 [AX-D]; the existing human number or legacy id stays as a separate unique column [PROTO]; money INTEGER minor units [AX-D] with `currency_code` TEXT on every money-bearing row [NEW; axpert: currency OPEN]; quantities INTEGER milli-units, rates INTEGER basis points [NEW scale; PROTO values; axpert quantity scale OPEN]; timestamps TEXT in UTC ISO 8601 [NEW; axpert: format NOT STATED; the prototype already stores UTC ISO text]; snake_case names [AX-C examples only; convention NOT STATED]. Booleans are INTEGER 0/1. Foreign keys are enforced (`PRAGMA foreign_keys = ON` already runs, [AX-D]).

**`products`** (catalog; axpert: server-authoritative candidate): `id`; `legacy_id` INTEGER unique [PROTO]; `code`, `barcode`, `name`, `category`, `sub_category` TEXT [PROTO]; `price_minor`; `currency_code`; `gst_bp` [PROTO value, stored as basis points per our rule]; `stock_units` INTEGER whole units [PROTO; inventory authority is axpert OPEN, P3R inventory row]; `image_index`; `favourite`; common columns (below). Indexes: `code`, `barcode`, `legacy_id`. Uniqueness of `code`/`barcode` is local only and provisional (axpert A3 open).
**D4 as built (DEC-128):** indexes only on `legacy_id` (unique) and `position`; the `code` and `barcode` indexes listed above were NOT created (owner decision D): search is the in-memory index and nothing queries by them yet, so they would only slow every stock write; add them when a query needs them (forward-only migration).
**`categories`** [AX-C, optional later]: not created at first; `category` and `sub_category` stay text on `products` (the prototype has no category entity).
**`customers`**: `id`; `legacy_id` TEXT unique (`walk`, `1`, clock ids) [PROTO]; `name`, `phone`, `email`, `member_no`, `points` INTEGER [PROTO]; common columns. The walk-in customer is a normal row with `legacy_id = 'walk'`. Authority is not assigned in axpert (digest 1.12).
**`sales`** (immutable once written, [AX-D] principle): `id` (= the `saleId` of new sales; a generated UUID v4 for migrated sales); `number` TEXT unique, DISPLAY ONLY, never a key or an invoice number (ADR-011) [PROTO]; `occurred_at`; `store_name` snapshot [PROTO] and `store_id` nullable [OPEN: store profile]; `customer_id` nullable (from `cart.customer`) and `customer_name` snapshot [PROTO]; `mode`; `sale_type`; bill-discount snapshot (`bill_discount_type`, `bill_discount_bp`, `bill_discount_minor`, `discount_reason`, `points_redeemed`, `note`) from the cart [PROTO]; totals `items`, `qty_milli`, `value_minor`, `subtotal_minor`, `discount_minor`, `tax_minor`, `points_minor`, `total_minor` [PROTO]; `tendered_minor`, `change_minor` [PROTO]; `currency_code`; origin `device_id`, `outlet_id`, `register_id` copied from `device_context_entries` [AX-C attribution]; `server_id`, `server_version` nullable [AX-C]; `created_at`. No `deleted_at` (sales are never deleted; corrections are void/return events, OPEN).
**`sale_lines`**: `id`; `sale_id` FK; `line_no`; `product_id` nullable FK; `product_legacy_id` INTEGER (keeps the `returned` key meaningful if the product row is later gone) [PROTO]; snapshot columns `product_code`, `product_name`, `barcode`, `gst_bp`, `unit_price_minor` (the line price), `qty_milli`, `discount_bp` [PROTO + AX-D snapshot principle; the field set is axpert OPEN]; `returned_qty_milli` INTEGER default 0 (replaces the `returned` map) [PROTO]; `legacy_snapshot_json` nullable, filled only for migrated rows to guarantee a byte-exact reprint and a verifiable round trip [NEW].
**`payments`** [AX-C "payments", semantics OPEN]: `id` (= `paymentId`); `sale_id` FK; `method` (cash/card); `amount_minor` (the amount due, DEC-123), `currency_code`; `status` (succeeded/failed); `occurred_at`. Rows exist only for NEW sales that went through `PaymentService`; credit sales have none; migrated sales get NO fabricated payment rows (their `mode`, `tendered_minor`, `change_minor` stay authoritative). Whether a payment row is created for a failed attempt is OPEN.
**`held_bills`** (device-local, never synced, owner decision; built in D3, DEC-127): `id` UUID v4; `ref` TEXT, NOT unique (refs come from the clock and can collide, KG-125); `position`; `held_at`; `cart_json` TEXT (the working cart snapshot; normalizing it is not worth it for temporary state); `created_at`, `updated_at`, `deleted_at` (tombstones, never DELETE). No sync-readiness columns.
**`current_cart`** (device-local, never synced): one row, `id = 1` like `device_context_entries`; `cart_json`; `updated_at`.
**`settings`** (device-local, never synced): `key` TEXT primary key, `value_json`, `updated_at` (store name, dark, beep, counter, milli rate) [PROTO]. The STORE PROFILE (currency, region, state, GSTIN) is OPEN: it may come from the backend, so it is not defined here (see `currency_tax_design.md`).
**`migration_state`** [NEW]: `key`, `value`: the LocalStore migration marker, per-table counts and content checksums (section 4).
Not created: units, barcodes, price lists, taxes, inventory, shifts, users, audit, printer config, config (axpert candidates whose semantics are open).

Common columns on synced-in-future tables (`products`, `customers`, `sales`, `sale_lines`, `payments`): `created_at`, `updated_at` (sales and lines: `created_at` only), `deleted_at` nullable (tombstone, [AX-C A5/A8], not for sales), `server_id` nullable, `server_version` nullable [AX-C].

## 3. Sync-readiness (schema room only, no sync code, no network)
Everything below is OUR proposal: axpert says "do not invent a field name, format, endpoint or DTO" (digest 4.10), so each item needs a Backend decision before it is used, and all of it stays nullable or empty and unused until then.
| Item | Proposed shape | Basis | Decider |
|---|---|---|---|
| Row identity | UUID v4 `id` on every table; `server_id` nullable | AX-D ids; AX-C `server_id` | Backend (A2) |
| Change tracking | `created_at`, `updated_at`, `deleted_at` tombstone, `server_version` nullable | AX-C | Backend (A5, A8, A10) |
| Origin | `device_id`, `outlet_id`, `register_id` on sales | AX-C attribution, AX-D device context | Backend |
| `outbox` table | `id`, `entity_type`, `entity_id`, `operation`, `payload_json` (immutable original), `idempotency_key` (client transaction id), `state` (PENDING, SYNCING, SYNCED, FAILED, CONFLICT), `retry_count`, `next_attempt_at`, `last_error` (sanitized), `ack_ref`, `created_at`, `acked_at` | AX-C concepts, digest 4.3; the five states are the documented concepts | Backend (A11, B1), Security (sanitized errors) |
| `sync_state` table | `stream`, `cursor`, `last_success_at` | AX-C "per-stream checkpoint", digest 4.3 | Backend (A10) |
| Atomic enqueue | an outbox row is inserted in the SAME transaction as the sale and payment | AX-C proposal (digest 4.3) | Backend |
Device-local tables (`held_bills`, `current_cart`, `settings`, `migration_state`) never get sync columns. No outbox row is written until a sync contract exists (an empty table is allowed).

## 4. Migration from `LocalStore` to Drift (cannot lose data)
Principles: LocalStore data is never deleted or rewritten by the migration; the copy is one-way, transactional and verified; the old store keeps working until you approve its retirement; every step is reversible.
1. **Gate and approval.** DEC-124 and your approval of the schema and of this migration (stage 0). Nothing below runs before that.
2. **Schema in place, repositories unchanged.** Add the tables with a normal forward migration (schemaVersion 3) and migration tests; repositories still read and write LocalStore.
3. **Copy at start-up, once.** If `migration_state` has no marker: read every LocalStore key RAW (not through the repositories), parse each record with the existing `fromJson`, and collect problems instead of dropping records (duplicate `number`, duplicate legacy id, unparsable record, unknown product in `returned`). If any problem exists the copy does not run, the marker stays unset, LocalStore stays authoritative and the problem list is logged (`StartupDiagnostics`) for you. If clean: write all tables in ONE Drift transaction, then write the marker with per-table counts and a content checksum.
4. **Verification, before the switch.** Read back from Drift and compare: row counts per table; sum of every money column per table; for every sale, product, customer and held bill the JSON rebuilt from Drift rows equals the original JSON under canonical encoding (this is what `legacy_snapshot_json` and the stored columns make possible). A failed check rolls the transaction back and keeps LocalStore authoritative.
5. **Dual-read, then dual-write period.** After a verified copy the repositories read from Drift and every write goes to Drift AND is mirrored to the same LocalStore key in the old JSON shape (including `saleId` when present). A start-up consistency check compares counts and checksums and logs differences. Rollback during this period is a flag flip back to LocalStore with no data loss, because the mirror kept it current.
6. **Retiring the mirror.** After an agreed number of releases and your explicit OK the mirror stops; the LocalStore keys are still not deleted automatically (a separate, explicitly approved cleanup).
7. **Old sales without `saleId`.** They get a UUID v4 as `sales.id` during step 3. The copy is transactional and marker-guarded, so the ids are stable once written; if a failed copy is rolled back and repeated, new ids may be generated, which is acceptable because nothing has referenced the first set (no sync exists). The mirror (step 5) never writes these ids into the LocalStore JSON of legacy sales, so DEC-123's rule "records stored before `saleId` are never rewritten" still holds there; new sales keep their `saleId` in both stores. A nullable `sale_uuid` column was the rejected alternative.
8. **Clock ids and duplicates.** Unique constraints on `number`, `ref` and `legacy_id` reject duplicates that LocalStore tolerated; the copy reports them and waits for your decision instead of renumbering.

## 5. Replacing each `Mock*Repository` behind the same interface
Each stage adds a `Drift*Repository` implementing the existing interface, switched by a binding flag, with the Mock kept for tests. Order by blast radius (test files that touch the controller are from the inventory):
| Stage | Repository | Notes | Test files touching the controller |
|---|---|---|---|
| R1 | Settings | smallest; device-local | 7 (D1 done: DEC-125) |
| R2 | Customers | walk-in row; points deduction becomes a row update | 6 (D2 done: DEC-126) |
| R3 | Held bills | device-local JSON column | 2 |
| R4 | Products | per-row writes remove KG-101's whole-list save; stock deltas become row updates | 22 |
| R5 | Sales + Returns together | one transaction for sale, lines and returned quantities (today `MockReturnRepository` saves sales and products non-atomically although its comment says "one unit") | 13 and 6 |
| R6 | Cart | last; keep the coalescing writer; decide whether an unreadable cart still resets silently | 11 |
### 5.3 Checkout as ONE awaited transaction (PROPOSAL ONLY, not approved)
Today checkout does three fire-and-forget whole-list writes (`sales.add`, `products.applyStockDeltas`, `customers.deductPoints`, KG-187). With Drift the natural design is one awaited transaction (sale, lines, payment, stock, points, later the outbox row). That changes behavior (the receipt would wait for the write and a failure needs a UI outcome), so it is documented here and needs its own approval and plan.
### Effect on tests
The 994-test suite stays on the fast path: `bootTestApp` keeps the Mock repositories over `InMemoryLocalStore`, so no sqlite startup. New tests: a repository CONTRACT suite run against the Mock AND the Drift implementation (in-memory `NativeDatabase`); migration tests (prior-version fixtures, rollback, failure leaves LocalStore authoritative, duplicate reporting); a few end-to-end checkout tests on Drift; debug click-through and `drift_check.mjs` extended. Only the database-specific files load the sqlite3 hook (axpert's full suite took about 41 s on this machine mostly because of that hook).

## 6. Risks
- Web: OPFS/IndexedDB durability and quota; no native-durability promise (digest 1.17); headless Chrome used IndexedDB, a real browser/OPFS is unverified.
- Multi-tab writes on web: unverified; sales numbers could collide across tabs or devices.
- 10,000 products: loading all rows into the in-memory index at start-up must be measured on web; keep the precomputed search index, do not query per keystroke.
- Migration: the dual-write mirror must not drift; checksum differences must be loud; a half-written copy must never become authoritative.
- Unique constraints will reject duplicates LocalStore silently tolerated (clock ids, KG-008, KG-125, KG-132).
- `Sale.customer` is a name: legacy rows can only link to a customer through `cart.customer` (may be missing/ambiguous): `customer_id` is nullable.
- Backup, restore, retention and corruption recovery have no policy (digest 1.8, 1.18).
- Unverified on Windows: the sqlite3 build hook; macOS sandbox path is verified only for the device-context file.
- Backend answers may change numbering, currency, quantity scale or tax storage, forcing forward migrations.

## 7. Open questions
| # | Question | Decider |
|---|---|---|
| 1 | Approve DEC-124 (provisional local-only schema) and each stage R1..R6, one by one | Owner |
| 2 | Checkout as one awaited transaction (behavior change, failure UI) | Owner |
| 3 | Store profile (currency, region/state, GSTIN): source of truth (backend or local setting) and where it is stored | TBD by project owner (Backend input) |
| 4 | Server id format and local-to-server mapping, version/ETag, tombstones (A2, A5, A8, A10) | Backend (owner TBD by project owner) |
| 5 | Invoice numbering and who allocates numbers online/offline (ADR-011); until then `number` is display only | Backend + Business (TBD by project owner) |
| 6 | Currency per record/outlet/price list and exponent; money wire format (A7) | Backend + Product (TBD by project owner) |
| 7 | Persisted quantity scale/unit conversion (A6); our proposal is 3-decimal milli-units | Backend + Product (TBD by project owner) |
| 8 | Tax and rounding storage; per-line vs per-total rounding (KG-183) | Backend (TBD by project owner) |
| 9 | Sale snapshot field set; sale lifecycle (completed, void, return) | Backend + Business (TBD by project owner) |
| 10 | Payment persistence (failed attempts, idempotency, provider reference) | Backend + Product (TBD by project owner) |
| 11 | Inventory authority: is local `stock_units` a cache of server stock | Backend + Product (TBD by project owner) |
| 12 | Sync: push envelope, ordering, idempotency, cursor, acknowledgement, conflict, retry, trigger (A10, A11, B1, B2) | Backend (TBD by project owner) |
| 13 | Backup, restore, retention, corruption recovery; DB encryption beyond the MVP | Operations + Security (TBD by project owner) |
| 14 | Web as a first-class offline target and its multi-tab guarantee | Product (TBD by project owner) |
| 15 | Timestamp format confirmation (proposed UTC ISO 8601 text) and naming convention | TBD by project owner |
| 16 | Do migrated sales get payment rows (proposed: no) and does `customer_id` stay nullable | Owner |
| 17 | How many releases the dual-write mirror stays on | Owner |
No dates are set (owners and dates "TBD by project owner").

## 8. DECIDED vs OPEN, in short
**DECIDED (axpert docs/code, or owner decisions already recorded):** Drift/SQLite; schema v2 with only `device_context_entries`; forward-only migrations with tests and preserve-data rules; text UUID v4 ids, never integers or ULIDs; a local UUID is not a server id or invoice number; money as integer minor units; fractional product-dependent quantity; completed sales immutable; no secrets in ordinary columns; no encryption for the MVP; offline use for previously authenticated users; sync about every 15 minutes behind abstractions; no invented sync contracts; web durability not promised; held bills, current cart and settings are device-local and never synced (owner); `saleId` is an additive UUID v4 on new sales (DEC-123); our money core stays (DEC-116).
**PROPOSED (this document, needs approval):** provisional local-only schema (DEC-124); currency_code on every money-bearing row; 3-decimal milli-unit quantities; UTC ISO 8601 text timestamps; the tables in section 2; the sync-readiness columns and `outbox`/`sync_state` in section 3; the migration plan; the repository replacement order; checkout as one awaited transaction (NOT approved).
**OPEN (blocked on others):** all 16 ADR-014 gate items, the backend alignment request A1 to A8 and A10 to A12 (A9 does not exist) and B1, B2, the 48 phase-3 contract questions, the store profile, backup/recovery policy, web offline scope, naming/index/WAL conventions. Owners: "TBD by project owner"; no dates.
