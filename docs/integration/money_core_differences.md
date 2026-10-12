# Money core: differences to axpert_pos (Stage 3, decision D1)

Decision (owner, 2026-10-12): keep our money core exactly as is (`Money` with currency, `Qty`, `Bp`, `PricingService`, golden vectors). No adapter now. Recorded as DEC-116 and KG-183.

| Topic | axpert_pos | pos_application |
|---|---|---|
| Rounding point | each line's extension and each line's tax rounded half-up, totals are sums of rounded lines | exact values (rational); rounded once per cart total (prototype `calculate()` compatible) |
| Inclusive-mode `subtotal` | net of tax (sum of line total - tax) | gross value (tax included); tax is informational |
| Quantity | `Quantity(coefficient, scale)`, any scale, non-negative | `Qty` milli-units: scale <= 3 only |
| `multiplyRatio` / amounts | non-negative only; no discount, points or negatives | line and bill discounts, points, negative amounts (returns) |
| Currency | none in `Money` | `Money(minor, Currency)` per-currency exponent |

Measured (cross-check test, 3000 carts, scale <= 3, no discounts): exclusive total differs in 941 multi-line and 130 single-line carts, exclusive tax in 469 + 10, inclusive tax in 480 + 4, inclusive subtotal in most carts. Both agree for one-line carts with whole-unit quantity (asserted).

When an adapter is needed: only if a backend contract defines the rounding point, the quantity scale, or the meaning of subtotal/identifiers. Until then nothing converts between the two models. `RoundingStrategy` is already swappable, which is the smallest future change. The cross-check test is a characterisation: if it ever finds no difference the services were aligned and the test must be revisited.
