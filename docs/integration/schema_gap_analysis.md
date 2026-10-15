# Schema gap analysis (design doc vs axpert_pos vs pos_application)

Date 2026-10-13. Analysis only: no schema change. Sources: Axpert_POS_SQLite_Database_Design (1).docx (design), `axpert_pos/lib/core/database` (axpert), `pos_application/lib/core/database` (ours, schema v10). Backend question ids: `axpert_pos/docs/api/backend-schema-alignment-request.md` (there is no A9).

## 1. Headline
- axpert_pos has ONE table (`device_context_entries`, schema v2); ADR-014 forbids operational tables until the 16 gate items are answered. It implements 1 of 41 doc tables (device_state in part).
- pos_application has 22 tables (v10), built as a provisional local-only schema (DEC-124, DEC-132, DEC-136). It matches about 9 doc tables by purpose (partly) and has none of the 8 "first" items below as a real table.
- Global differences (not repeated per table): timestamps: DONE in v11 (DEC-147), ours is now INTEGER UTC ms like the doc (domain models and the mirror still use ISO text, KG-240); ours quantity is `qty_milli` (scale 3), the doc `quantity_scaled` (precision not frozen, A6); ours has no `sync_status`; `server_version` is INTEGER in ours, TEXT in the doc (A8); no `search_name`; ours are scoped by `store_id` columns (nullable) instead of required `outlet_id`/`register_id` FKs.

## 2. Phase 1 minimum schema (doc section 17), status
| Doc table | axpert_pos | pos_application | Column differences (ours vs doc) |
|---|---|---|---|
| outlets | no | `stores` (partial) | ours: address, phone, tax_id, receipt_header/footer, currency_code, region; missing: server_id, code, timezone, server_version |
| registers | no | `counters` (partial) | ours: store_id, name, active; missing: server_id, code, server_version |
| users | no | `users` (partial) | ours has salt, password_hash, hash_algo and one `role` text (doc: no passwords locally, cached_auth_policy; section 16); missing server_id, server_version |
| categories | no | `categories` (partial) | ours: store_id, icon_key, position; missing: server_id, code, active, server_version |
| units | no | NO | products carry no unit; qty has no unit |
| products | no | `products` (partial) | ours merges barcode (single), price_minor, currency, stock, gst_bp, image, favourite, variant_*, category/sub as text; has server_id, server_version, device_id, deleted_at; missing: search_name, brand_id, unit_id, is_weighted, track_inventory, active; price/tax/stock must leave the row |
| product_barcodes | no | NO (one `barcode` column) | whole table; quantity_factor, unit |
| price_lists | no | NO | whole table |
| product_prices | no | NO (`products.price_minor`) | whole table (price list, outlet override, valid_from/to, cost) |
| taxes | no | `tax_regimes` + `tax_slabs` (different shape) | ours: region regime, label, price_mode, split_parts, slabs in bp; doc: tax codes with rate_bp/components and valid dates |
| product_taxes | no | NO (`products.gst_bp`) | whole table (product to tax, valid dates) |
| customers | no | `customers` (partial) | ours: legacy_id, member_no, points, position; has server_id, server_version, device_id; missing: customer_code, tax_number, price_list_id, credit_allowed, active |
| shifts | no | NO (shift screen computes from sales; no table) | whole table |
| sales | no | `sales` (partial) | ours is a flat snapshot with store_name, customer_name, mode, sale_type, bill discount fields, points; missing: invoice_no (ours `number` from list length, KG-008), business_date, shift_id, status (HELD/COMPLETED/VOIDED), currency on header (ours currency_code ok), rounding_minor, paid_minor, sync_status; has tendered/change |
| sale_items | no | `sale_lines` (partial) | ours snapshots product columns and offer_*; missing: unit_id, gross/net/tax per line, tax_snapshot_json, price_source, voided; qty_milli vs quantity_scaled |
| payments | no | `payments` (partial) | ours: method (text), amount_minor, currency, status, occurred_at; missing: method_id FK, provider_reference, user_id, sync_status; only cash and card sales write rows |
| inventory_balance | no | NO (`products.stock` integer) | whole table (per outlet, on_hand/reserved scaled) |
| inventory_transactions | no | NO | whole table (stock changes are in-place updates today) |
| sync_queue | no | NO | whole table |
| sync_state | no | NO | whole table |
| sync_errors | no | NO | whole table |
| audit_events | no | NO | whole table |
| app_config | no | `settings` (partial) | key/value JSON; doc: typed config |
| printer_config | no | NO (only `print_paper_mm` in `settings`) | whole table |
| device_state | `device_context_entries` (device_id, outlet_id, register_id only) | `device_context_entries` (same, copied) | missing: registration_id, last_sync_at, schema_version |

## 3. Doc tables outside Phase 1 minimum
| Doc table | axpert_pos | pos_application | Note |
|---|---|---|---|
| organizations | no | no (store row holds name/tax id) | B2 |
| roles, permissions, role_permissions, user_roles | no | no (`users.role`; `user_access` = user to store/counter, close to scoped user_roles) | needed for audit approvers |
| brands | no | no | A6 |
| suppliers | no | no | purchases not in scope |
| payment_methods | no | no (`payments.method` text) | local config, no backend dependency for a first cut |
| sale_taxes, sale_discounts | no | no (sale has tax_minor, bill discount fields, offer_* on lines) | tax split by component lives only in display |
| payment_attempts | no | no | A11 (idempotency_key) |
| returns, return_items | no | no (`sale_lines.returned_qty_milli`, `sales.returned_order`; refunds ignore tax, KG-165) | |
| cash_movements | no | no | needs shifts |
| held_sales | no | `held_bills` (cart JSON) | doc allows HELD status on sales instead |
| entity_versions | no | no | A8 |
| ours only (not in doc) | | `currencies`, `store_forex`, `offers`, `current_cart`, `held_bills`, `seed_manifest`, `migration_state`, `tax_regimes/slabs` | keep; map `offers` to sale_discounts later |

## 4. Recommended migration stages (to the Phase 1 minimum)
Each stage = one transactional Drift step plus a migration test (v(n-1) data survives, forced failure rolls back), as in v9/v10. Order follows your priority; sync last.
| Stage | Adds / changes | Why here | Backend answers it depends on |
|---|---|---|---|
| S1 inventory (DONE v12, DEC-148) | `inventory_balance`, `inventory_transactions`; checkout writes a SALE movement and the balance in the existing checkout transaction; backfill balance from `products.stock`; keep `products.stock` as a derived cache until retired | local, high value, fixes in-place stock updates | A6 (quantity semantics, unit); A8 only for the `server_version` column type (keep nullable) |
| S2 shifts | `shifts` (+ `sales.shift_id`, `cash_movements` optional); shift close from real rows | the shift screen is derived today | none to start (register id from counters); A12 for retention |
| S3 payment_methods | `payment_methods`; `payments.method_id` FK, `provider_reference`, `user_id` | removes the free-text method | none for local config; A7 only if methods map to backend codes |
| S4 audit_events | `audit_events`; write for discount override, void, refund, price override, shift close, stock adjust | enterprise traceability, local only | none to start; approver needs roles (S9) |
| S5 pricing and tax | `price_lists`, `product_prices`, `taxes`, `product_taxes`; migrate `products.price_minor/gst_bp` and `tax_regimes/slabs` into them; keep PricingService and the 300 vectors untouched | the doc's deterministic offline pricing; biggest change | A7 (money, currency, selection, tax and rounding), A1 to A6 (product shape) |
| S6 returns | `returns`, `return_items` (+ refund payment rows, inventory RETURN movement, tax on refunds) | needs S1 and S3; fixes KG-165 | A7 (refund rounding/tax), A11 later |
| S7 catalog shape | `units`, `brands`, `product_barcodes`, product columns (`search_name`, `brand_id`, `unit_id`, `is_weighted`, `track_inventory`, `active`), category `code/active` | scan and search structure | A1 to A6 (identity, code uniqueness, names, lifecycle, relationships) |
| S8 context and identity | `organizations`, `outlets/registers` aliases or renames (add `server_id`, `code`, `timezone`), roles/permissions tables, `user_roles`, drop local password hashes when real auth exists, `device_state`, `printer_config`, `app_config` | align names with the backend | A2 (id mapping), B2 (bootstrap source), A12 (security/recovery) |
| S9 sales header and lines | `sales`: `invoice_no`, `business_date`, `status`, `rounding_minor`, `paid_minor`; `sale_items`: gross/net/tax, snapshots, `price_source`, `voided`; `sale_taxes`, `sale_discounts`, `payment_attempts` | historical immutability | A7, A11 (idempotency), invoice numbering (ADR-011) |
| S10 sync (last) | `sync_queue`, `sync_state`, `sync_errors`, `entity_versions`; `sync_status` on sales, payments, shifts, inventory, audit, returns; (timestamp type already epoch ms since v11) | needs every entity above to exist | A8, A10 (cursor, tombstones), A11 (idempotency, conflicts), B1 (envelopes, ordering, retry), A12 |

## 5. Backend answers: what blocks what
| Id | Topic | Blocks stage | Can start without it? |
|---|---|---|---|
| A1, A2 | product identity, local UUID vs server id | S7, S8 | yes (provisional ids already UUID v4) |
| A3, A4 | code uniqueness scope, name fields | S7 | yes (keep current columns) |
| A5 | activation, deletion, replacement | S7, S10 | yes (tombstone `deleted_at` exists) |
| A6 | category, unit, brand relations, quantity semantics | S1 (scale), S7 | S1 yes with milli scale |
| A7 | money, currency, effective prices, tax, rounding | S5, S6, S9 | S5 only as our own provisional design |
| A8 | version/ETag and deletion markers | S10 (type of `server_version`) | yes (nullable int today) |
| A10 | cursor and tombstones for master data | S10 | yes |
| A11 | idempotency, duplicates, acks, conflicts | S9 (`payment_attempts`), S10 | S10 no |
| B1 | outbound envelopes, ordering, retry codes | S10 | S10 no |
| B2 | bootstrap source, assigned outlet/register | S8 | yes (seed assets) |
| A12 | migration, backup, recovery, unsynced retention | every stage once real data exists; S10 | yes for demo data only |
Stages S1 to S4 need no backend answer to start. S5 to S9 can be built provisionally (as DEC-124) but must be re-checked when A7, A1 to A6 and A11 arrive. S10 cannot be finished before A8, A10, A11, B1, A12.

## 6. Open points for the owner
- Timestamp type: DONE, epoch ms in schema v11 (S0, 2026-10-15, DEC-147).
- Rename `stores`/`counters` to `outlets`/`registers` or keep and map (S8).
- ADR-014 in axpert_pos still forbids operational tables; our schema stays provisional and local-only (DEC-124) until its 16 items are closed.
