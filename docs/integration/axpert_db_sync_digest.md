# axpert_pos digest: database, ids, money, offline and sync

Date: 2026-10-12. Read-only digest of `axpert_pos` (working tree as found; it has uncommitted work and was never modified). Every row has a source (file and section) and a status:

- **DECIDED**: stated as decided or accepted in a doc, or implemented in code.
- **PROPOSED**: candidate, illustrative or "concepts only".
- **OPEN**: unresolved or deferred; the decider is named where the docs name one. NOT STATED means the sources are silent.

Source key (all under `axpert_pos/`): **AGENTS** = AGENTS.md; **DI** = docs/database/database-infrastructure.md; **P3R** = docs/database/phase-3-operational-schema-readiness.md; **BSAR** = docs/api/backend-schema-alignment-request.md; **P3Q** = docs/api/phase-3-backend-contract-questions.md; **BA** = docs/api/backend-assumptions.md; **DCF** = docs/device/device-context-foundation.md; **ASF** = docs/security/authentication-session-foundation.md; **ARCH** = docs/architecture/architecture.md; **DD** = docs/decisions/deferred-decisions.md; **ADR-nnn** = docs/decisions/ADR-nnn-*.md; **PTF** = docs/features/pricing-tax-foundation.md; **TS** = docs/testing/testing-strategy.md. Code paths are given in full.

How to read this next to our plan: `database_plan.md` (same folder) builds on the DECIDED rows and lists every OPEN row it depends on.

## 1. Table and column design, keys, indexes, migrations, versioning

| # | Statement | Source | Status |
|---|---|---|---|
| 1.1 | Drift on SQLite is the persistence engine; `schemaVersion` is 2; the ONLY table is `device_context_entries`. No operational table, DAO, queue or sync class exists. | DI "Schema and migration foundation"; P3R "Current implementation"; `lib/core/database/axpert_database.dart:8-13` | DECIDED (implemented) |
| 1.2 | `device_context_entries` columns: `singleton_id` int, default 1, primary key; `device_id` text not null; `outlet_id` text nullable; `register_id` text nullable. No CHECK constraint enforces the value 1; no timestamps, version, deleted flag or server id. | `lib/core/database/tables/device_context_entries.dart` (verified against the file); DCF "Implementation boundary" | DECIDED (implemented) |
| 1.3 | `onCreate` = `createAll()`; `onUpgrade`: `from < 2 && to >= 2` creates the table; `beforeOpen` runs `PRAGMA foreign_keys = ON`. No other PRAGMA (WAL/journal mode) is set or documented. | `axpert_database.dart:17-28`; DI "Access and lifecycle" | DECIDED (implemented); WAL/journal NOT STATED |
| 1.4 | Migrations are forward-only, with an explicit monotonically increasing `schemaVersion`; automated upgrade tests for every supported deployed version; existing data must not be deleted as a migration strategy. | DI; P3R "Migration and recovery policy" 1-3; ADR-014 | DECIDED |
| 1.5 | Migration fixtures must include representative operational data (unsynced sales, queue work) once those tables exist; local business records and pending/failed/conflict payloads must be preserved through upgrades. | P3R policy 4-5; ADR-014 | DECIDED |
| 1.6 | On migration failure: preserve the database, stop safely, do not continue checkout on an unknown schema; test transaction rollback and upgrade recovery. | P3R policy 8 | DECIDED |
| 1.7 | Never delete or recreate a production database unless the device is proven fully synchronized and an explicit recovery policy allows it; "that exception is not currently defined". | P3R policy 7; ADR-014 | DECIDED (rule); the exception is OPEN (Operations + Security) |
| 1.8 | An application-controlled backup/recovery point before risky migrations "where the approved operational policy permits it"; backup location, security, restore validation and failure behavior are undefined. | P3R policy 6; BSAR A12 | PROPOSED; policy OPEN (Operations + Security, Backend input on unsynced data) |
| 1.9 | Supported production upgrade-version set is not established (no production operational schema exists). | P3R policy 9 | OPEN |
| 1.10 | Native providers use the application-support directory; web uses Drift WASM (OPFS/IndexedDB) with `drift_worker.js` and `sqlite3.wasm`; one `AxpertDatabase`; tests may inject an in-memory executor; the provider is chosen by a conditional import. | DI "Platform"; `lib/core/database/database_provider_factory.dart` | DECIDED (implemented) |
| 1.11 | Codegen: `dart run build_runner build --delete-conflicting-outputs`; manager generator disabled; generated files never hand-edited. | DI; `build.yaml`; AGENTS | DECIDED |
| 1.12 | ~29 candidate entities exist in a "readiness map, not a frozen schema": outlets, registers, users, shifts, device state, categories, units, products, product barcodes, price lists, product prices, taxes, product taxes, customers, sales, sale items, sale taxes, sale discounts, payments, payment attempts, inventory balance, inventory transactions, stock adjustments, sync queue, sync metadata/state, sync errors, entity versions, audit events, app config, printer config. Authority and offline need are listed per entity (server-authoritative master data; POS creates the durable sale and payment events and the server acknowledges; inventory reconciled by the server; customers have NO assigned authority). | P3R "Candidate entity mapping" | PROPOSED |
| 1.13 | Candidate columns `server_id`, `server_version`, `invoice_no`, timestamps, status and sync metadata are "source-document proposals, not approved database columns"; do not infer names, types, nullability, indexes or constraints from illustrative DDL. | P3R "Purpose and gate", L52-57 | PROPOSED |
| 1.14 | Naming convention (snake_case), column types, nullability, index and uniqueness rules for operational tables are not stated (snake_case appears only in examples and mock JSON keys). A unique product-code index is "illustrated, not approved" (A3). Composite identities for product taxes, sync metadata, entity versions, app config and printer config are "not frozen". | P3R; BSAR A3 | OPEN (Backend + Product) |
| 1.15 | Tombstones are recommended by the architecture for synchronized master data; representation and retention are not defined. | BSAR A5, A8 | PROPOSED; OPEN (Backend) |
| 1.16 | Timestamp format and time zone, soft-delete columns, entity version columns: no written rule anywhere. | grep of all docs and code | NOT STATED |
| 1.17 | Web storage has different lifecycle, quota and multi-tab behavior and must not be promised native durability. | DI "Platform and security boundaries"; P3R | DECIDED |
| 1.18 | Retention and cleanup (sync errors, audit events, customer privacy data, backup retention) require operational/security policy. | DI; P3R rows; P3Q Configuration Q2-Q3 | OPEN (Operations, Security, Business) |

## 2. Identifiers, device, outlet, register

| # | Statement | Source | Status |
|---|---|---|---|
| 2.1 | Local/client-generated identifiers are UUIDs; version 4, stored as text, for new local technical records. Do not substitute integer ids or ULIDs. | ADR-003; P3R "Confirmed conventions"; BSAR "Identifiers"; DI | DECIDED |
| 2.2 | A local UUID is not a server id and not an invoice or document number. | P3R; BSAR; ADR-011 | DECIDED |
| 2.3 | Server id format/scope, whether the local UUID is the durable cross-system key or is mapped to a server id, and the mapping rules. | ADR-003 deferred; BSAR A2; P3Q Identity Q1-Q4 | OPEN (Backend) |
| 2.4 | Entity version / ETag / change token semantics. | BSAR A8; P3Q Identity Q3 | OPEN (Backend) |
| 2.5 | Invoice numbering is deferred; the UUID stays the technical identity; "implementations must not present a locally invented sequence as production numbering". Who allocates numbers online/offline, uniqueness, gaps, reconciliation are unanswered. | ADR-011; P3R "Invoice numbering"; P3Q Sales Q4 | DECIDED (deferral); numbering policy OPEN (Backend + Business, owner itself undefined) |
| 2.6 | Device id: a v4 UUID from a cryptographically secure random source (`UuidV4Generator`, `Random.secure()`), restored or created once by `DeviceContextService`; no OS serial number or fingerprint is read. | DCF; `lib/core/identifiers/uuid_v4_generator.dart` | DECIDED (implemented) |
| 2.7 | Outlet and register are optional opaque strings; saving them locally does not claim backend assignment or validation. | DCF; DI | DECIDED (implemented) |
| 2.8 | Device registration, server ids for devices, assignment validation, revocation, secret rotation, auth headers. | DCF "Deferred"; P3Q Device Q1-Q2 | OPEN (Backend, Security) |
| 2.9 | In code, ids are plain `String` fields (`CatalogProduct.id`, `SaleConstruction.saleId`, `PaymentRequest.paymentId/saleId`); a new sale UUID is generated once by `StartSale`; `PayCurrentSale` generates a new `paymentId` on every call (a retry makes a new id: no idempotency). The `DEMO-####` order reference is an in-memory counter, not stored and not an id. | `lib/features/sales/domain/usecases/start_sale.dart`; `payment/domain/usecases/pay_current_sale.dart`; `payment_controller.dart` | DECIDED (implemented, demo) |
| 2.10 | Idempotency key / client transaction id per outbound operation. | BSAR A11; P3Q Sync Q5, Payments Q4, Inventory Q4 | OPEN (Backend) |

## 3. Money, quantity, tax, rounding storage rules

| # | Statement | Source | Status |
|---|---|---|---|
| 3.1 | Money is integer minor units; binary floating point is never the canonical representation; formatted strings must not be stored as amounts. | ADR-004; P3R "Money and quantity"; DI | DECIDED |
| 3.2 | `Money(int minorUnits)` has no currency and no formatting; `multiplyRatio` rounds `down` or `halfUp` and is correct only for non-negative amounts; no negation, no discount support. | `lib/core/money/money.dart`; PTF | DECIDED (implemented, mock) |
| 3.3 | Currency per record / outlet / price list, currency code and minor-unit exponent to store and transmit. | P3R gate item "Currency confirmed"; BSAR A7; P3Q Pricing Q2 | OPEN (Backend + Product) |
| 3.4 | Money wire serialization (minor units vs decimal strings vs other). | BSAR A7; P3Q Pricing Q3 | OPEN (Backend + Product); storage rule DECIDED |
| 3.5 | Quantity supports fractions and is product/unit-dependent; no global precision is assumed. | ADR-004; P3R | DECIDED |
| 3.6 | `Quantity` is a non-negative scaled integer (`coefficient`, `scale`) that normalizes by stripping trailing zeros, so 1.50 equals 1.5 and the entered scale is not preserved. | `lib/features/cart/domain/value_objects/quantity.dart:17-21` | DECIDED (implemented); persisted scale and unit conversion OPEN (BSAR A6; Backend + Product) |
| 3.7 | Tax representation (rate vs components, jurisdiction, inclusive/exclusive, exemptions, effective dates, product-tax mapping). The mock uses non-negative integer `tax_rate_basis_points`. | P3R "Taxes"; PTF; BSAR A7; P3Q Pricing Q5; `tax_rate.dart` | OPEN (Backend + Product); mock only |
| 3.8 | Rounding mode and point (per line vs per total, fractional-quantity extension, tax allocation) and discount order/allocation: deferred. The demo policy is exclusive tax, per-line half-up, sums of rounded lines, and is "not production policy". | ADR-004; DD "Backend rounding rules"; PTF "Temporary mock behavior"; `cart_totals_calculator.dart` | OPEN (Backend); demo implemented |
| 3.9 | Pricing selection precedence, effective dates, time zones, offline price changes. | P3Q Pricing Q1, Q4, Q6; P3R gate | OPEN (Backend + Product) |
| 3.10 | Completed sales keep an immutable snapshot (product code/name, effective price, quantity, tax, applicable discount); later master-data updates must not rewrite completed-sale history. The exact snapshot fields are unapproved. | P3R "Sale immutability"; ADR-014; BSAR | DECIDED (principle); field set OPEN (Backend + Business) |
| 3.11 | Display: mock amounts show as plain two-decimal numbers without currency (`DemoMoneyDisplay` divides by 100); the format is "provisional"; currency, exponent and locale are unapproved. | `mock-payment-presentation.md`; `demo_money_display.dart` | OPEN |

## 4. Offline-first rules and the sync model

| # | Statement | Source | Status |
|---|---|---|---|
| 4.1 | Local transaction work is intended to support offline operation and later synchronization. Previously authenticated users may operate offline for the MVP; no offline PIN or cached password. | ARCH; ADR-005; ASF | DECIDED (direction) |
| 4.2 | Sync target about every 15 minutes, behind abstractions; application code must not depend on an assumed transport or payload. Trigger/frequency/platform limits are unanswered. | ADR-006; BA; P3Q Sync Q9 | DECIDED (target); mechanism OPEN (Backend) |
| 4.3 | Queue lifecycle concepts PENDING, SYNCING, SYNCED, FAILED, CONFLICT; idempotency key / client transaction id; server reference and version; change cursor/checkpoint; retry count and scheduling; sanitized error info; the immutable original business payload; acknowledgement and conflict details; the queue entry "should be atomically enqueued with the completed sale". "Concepts only, not approved columns." | P3R "Sync metadata readiness", sync queue row | PROPOSED |
| 4.4 | Push envelope, command ordering and dependencies, bootstrap streams, incremental changes, paging, batch limits, tombstones. | P3Q Sync Q1-Q3; BSAR B1, B2, A10 | OPEN (Backend) |
| 4.5 | When a local checkpoint may advance; acknowledgement contract (accepted, rejected, duplicate, conflicting); when an item may become SYNCED. | BSAR A10, A11; P3Q Sync Q4, Sales Q6 | OPEN (Backend) |
| 4.6 | Conflict policy per entity (automatic vs operator-mediated; customers: "version check plus merge" per the architecture, authority not assigned). | P3Q Sync Q7; P3R customers row; BSAR A11 | OPEN (Backend) |
| 4.7 | Retry: retryable failure classes, backoff, terminal policy. | P3Q Sync Q6; BSAR B1 | OPEN (Backend) |
| 4.8 | Authority split: server owns master data, pricing, tax, permissions and sync contracts; POS creates the durable sale and payment events; the server acknowledges; inventory is server-reconciled. | P3R authority column | DECIDED (master data); PROPOSED (the rest) |
| 4.9 | Completed sales are immutable business events changed only by explicit void/return workflows; which event completes a sale and whether a server update can alter it are unanswered; returns/voids/refunds are out of scope for the current phase. | P3R; ADR-014; P3Q Sales Q2, Q3, Q5 | DECIDED (immutability); lifecycle OPEN (Backend + Business) |
| 4.10 | Every "sync is deferred or blocked" statement: ADR-006 (endpoints, payloads, cursors, acknowledgements, conflict responses, retry), ADR-014 ("operational offline checkout and production synchronization remain unavailable until the gate passes"), DD ("synchronization protocol", "server identifiers and version semantics"), DI, BA "deferred backend contracts", ARCH ("protocol specifics deferred"), DCF, P3R ("do not invent a field name, format, endpoint or DTO"), AGENTS ("do not invent ... synchronization contracts"), BSAR B2 (do not simulate bootstrap as sync). | the cited files | DECIDED (blocked / prohibition) |
| 4.11 | The API client has no auth, retry, logging or pagination; no endpoint exists; `ApiClient` is registered and unused. | docs/api/api-client-infrastructure.md; `lib/core/network/` | DECIDED (implemented) |
| 4.12 | Code evidence: zero hits for outbox, queue (as a sync term), idempotency, cursor, checkpoint, tombstone, soft delete, created_at, updated_at, timestamp, `DateTime`, ULID, `sale_id`, offline, entity version in `lib/` and `test/` (the only `conflict` hit is SQL `insertOnConflictUpdate`; `retry` is UI-only). | grep over `lib`, `test`, AGENTS, README | NOT STATED in code |
| 4.13 | Web offline and multi-tab guarantees. | P3Q Configuration Q4 | OPEN (Product) |

## 5. The ADR-014 / schema-freeze gate (16 items) and the backend request

Rule: "Drift tables must not be introduced until every item in the schema-freeze gate is resolved" (P3R L8 and L186; ADR-014, Accepted). Allowed meanwhile: documentation, contract review, migration test strategy, and code that commits to neither operational schema nor backend semantics (P3R L207-209). "No item is checked by the existence of a mock, candidate column, example DDL, or assumption." BSAR states the frontend "will not silently narrow" the gate and that narrowing needs a formal ADR revision by the project owners.

| # | Gate item (verbatim, P3R L189-204) | Status | Decider (BSAR "owner" table) |
|---|---|---|---|
| 1 | Backend entity mapping reviewed. | OPEN | Backend + Product |
| 2 | Local/server identifier strategy confirmed. | OPEN (rule "UUID v4 locally" is decided; server mapping is not) | Backend + Product (A2) |
| 3 | Money serialization confirmed. | OPEN (minor-unit storage decided; wire format not) | Backend + Product (A7) |
| 4 | Quantity scale/precision confirmed. | OPEN | Backend + Product (A6) |
| 5 | Currency confirmed. | OPEN | Backend + Product (A7) |
| 6 | Tax representation confirmed. | OPEN | Backend + Product (A7) |
| 7 | Pricing selection rules confirmed. | OPEN | Backend + Product (A7) |
| 8 | Invoice numbering strategy confirmed. | OPEN (ADR-011 defers) | Backend + Product |
| 9 | Sale immutability and historical snapshot policy confirmed. | OPEN (principle decided, fields not) | Backend + Product |
| 10 | Payment persistence semantics confirmed. | OPEN | Backend + Product |
| 11 | Inventory authority/reconciliation confirmed. | OPEN | Backend + Product |
| 12 | Sync idempotency contract confirmed. | OPEN | Backend (A11) |
| 13 | Sync cursor/version semantics confirmed. | OPEN | Backend (A8, A10) |
| 14 | Acknowledgement contract confirmed. | OPEN | Backend (A10/A11) |
| 15 | Conflict policy confirmed. | OPEN | Backend (A11) |
| 16 | Migration, backup, and recovery policy approved. | OPEN | Operations + Security, Backend input on unsynced retention (A12) |

Satisfied so far (evidence, not gate items): schema v2 explicit; v1 to v2 migration test; transaction rollback test; FK pragma (DI, `test/core/database/native_database_provider_test.dart`).

Backend alignment request (BSAR): A1 canonical product identity and minimum fields; A2 local UUID vs server id; A3 product code meaning and uniqueness; A4 name/description; A5 activation, deletion, correction, replacement; A6 category/unit relations and fractional precision; A7 price, currency, effective date, tax, rounding, snapshot (blocking schema freeze); A8 change identification, deletion markers, server version; **A9 does not exist** (numbering jumps from A8 to A10); A10 version/change cursor and tombstones; A11 idempotency and conflict guarantees; A12 backup/recovery and unsynced-work retention; B1 outbound push envelope and acknowledgement; B2 bootstrap source and outlet/register catalog scope. A1-A6 are labelled "blocking Phase 3.2" (first catalog table), A7, A8, A10-A12 "blocking schema freeze", B1 and B2 "important, may be deferred" (but not for the broader operational gate unless ADR-014 is revised). All OPEN; owners per the table above; BSAR asks for an owner and expected decision date for each unanswered item.

Phase-3 contract-question register (P3Q), all OPEN (Backend, Product, Security): Identity 4, Catalog 5, Pricing 6, Sales 6, Payments 5, Inventory 4, Synchronization 9, Device and session 5, Configuration and operations 4 = 48 questions.

## 6. Security rules affecting storage

| # | Statement | Source | Status |
|---|---|---|---|
| 6.1 | No passwords, refresh tokens, card numbers, CVV or terminal secrets in ordinary SQLite columns, preferences, JSON, config or logs. | DI; ASF; DCF | DECIDED |
| 6.2 | No database encryption scheme for the MVP ("do not over-engineer"); the enterprise requirement is deferred. | ADR-010; DD | DECIDED (MVP); OPEN (Security) |
| 6.3 | `SecureCredentialStore` is the boundary for device secrets and opaque credentials; no implementation selected; `flutter_secure_storage` is only a recommendation needing review (web properties). | ASF | DECIDED (boundary); OPEN (implementation, Security) |
| 6.4 | Only the non-secret device UUID and opaque outlet/register references live in Drift; `SessionController` keeps only a status and an opaque marker. | ASF; DCF | DECIDED (implemented) |
| 6.5 | Cached users/roles/permissions offline, audit events (mandatory set, retention), sanitized sync-error messages, backup security. | P3Q Device Q4, Config Q3; P3R rows | OPEN (Backend, Security, Business) |

## 7. Contradictions and drift

**Doc against doc**

| # | Contradiction | Sources |
|---|---|---|
| 7.1 | ADR-003 says "UUIDs"; P3R/BSAR say v4 and forbid ULIDs; DI and DCF note the upstream database design "permits UUID/ULID-style" ids (flagged as an unresolved documentation difference). UUID v4 controls. | ADR-003; P3R; BSAR; DI; DCF |
| 7.2 | Phase labels collide: README says Phase 0 complete and Phase 1 in place; code and docs also describe Phase 2/2.5 (catalog, cart, pricing, payment); ADR-014 and P3R are "Phase 3"; BSAR uses "Phase 3.1 gate" and "Phase 3.2"; DI/DCF/ASF use "Task 1.8/1.9"; `docs/phases/` has only phase-0.md. | README; phase-0.md; payment-foundation.md; ADR-014; BSAR |
| 7.3 | BSAR marks A1-A6 as "blocking Phase 3.2" and B1/B2 as deferrable, while the gate (ADR-014) blocks every operational table until all 16 items pass; the gate dominates. A9 is missing. | BSAR; P3R |
| 7.4 | The architecture names the device table `device_state`; the implemented table is `device_context_entries` ("partial foundation"). | DCF; P3R |
| 7.5 | The 15-minute sync target is a decided goal while production sync is blocked and its trigger is an open question. | ADR-006; ADR-014; P3Q Sync Q9 |
| 7.6 | Offline use is allowed for previously authenticated users (ADR-005) but the token lifecycle and offline policy are undefined. | ADR-005; ASF; P3Q Device Q3 |
| 7.7 | Money storage is decided (minor units) while its wire serialization is reopened by P3Q Pricing Q3. | ADR-004; P3Q |
| 7.8 | P3R lists "Currency confirmed" as open while `Money` carries no currency at all. | P3R; `money.dart` |

**Doc against code (axpert_pos)**

| # | Contradiction | Sources |
|---|---|---|
| 7.9 | The pricing doc says cart values show as "minor-unit counts"; the code and tests show two-decimal strings (`4.50`), hard-coding exponent 2 while currency/exponent are unapproved. | PTF; `demo_money_display.dart` |
| 7.10 | Catalog, sale-construction, pricing, mock-data docs say cart, checkout, sale and payment are not implemented; the code implements an in-memory cart, sale construction and mock payment. phase-0.md says the repository holds template code only. | catalog-foundation.md; sale-construction.md; phase-0.md |
| 7.11 | TS says migration tests apply "when persistence and migration policy are implemented"; a v1 to v2 migration test exists. | TS; native_database_provider_test.dart |
| 7.12 | Web assets are documented as Drift 2.34.2 while drift 2.34.4 is locked (fixed in OUR repo only, DEC-117). | DI; `pubspec.lock` |
| 7.13 | `Quantity` drops the entered scale; docs say "no persisted scale decision" and never mention it. `Money.multiplyRatio` is wrong for negatives; docs say nothing. | `quantity.dart`; `money.dart` |
| 7.14 | The singleton row is enforced only by the primary key default, not by a CHECK. | `device_context_entries.dart` |

**Against pos_application (this repository)**

| # | Difference | Our side | axpert side |
|---|---|---|---|
| 7.15 | Sale numbers | `AX000001` from `sales.length + 1` (KG-008) | ADR-011: a locally invented sequence must not be presented as production numbering |
| 7.16 | Currency | `Money` carries a `Currency`; JSON stores only `...Minor` and always loads as INR | Currency OPEN; `Money` has none |
| 7.17 | Quantity | fixed milli-units (3 decimals) | per-product/unit scale OPEN; scaled integer with trailing-zero normalization |
| 7.18 | Rounding, inclusive subtotal | cart-level rounding of exact values; inclusive subtotal is gross | per-line half-up; subtotal net of tax (DEC-116, KG-183) |
| 7.19 | Sale snapshot | `Sale.cart` embeds full product snapshots; `Sale.customer` stores the customer NAME, `Sale.store` a name | snapshot principle decided, fields OPEN; ids are UUIDs |
| 7.20 | Ids | int product ids, clock-based customer ids and held refs | UUID v4 for local technical records |
| 7.21 | Seeds | 20 demo products and 4 customers written to the real store on first run | "Do not persist mock values as production"; mock fixtures satisfy no gate item |
| 7.22 | Persistence | whole-list JSON rewrites, fire-and-forget at checkout (KG-187) | atomic enqueue with the sale is the proposed rule |
