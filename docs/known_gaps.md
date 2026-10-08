# Known gaps (prototype behavior replicated in Phase A, to fix in Phase B)

Rule (CLAUDE.md): Phase A replicates the prototype as-is. Each gap gets an ID. Deviations that were forced or approved are also recorded in `decisions.md`.
Status values: `replicated` (Flutter does the same), `deviation` (Flutter differs, approved), `unverified` (built from CSS/code only, not compared to a screenshot).

## A. Logic and data

| ID | Gap | Status |
|---|---|---|
| KG-001 | Totals round only at the five outputs (value, discount, tax, points, total); displayed rows may not sum to the total by one minor unit. Line totals, change and refunds are unrounded in React and only rounded at display | replicated |
| KG-002 | Typed quantity with more than 3 decimals is accepted by React. Flutter rounds half-up to 3 decimals on commit (integer milli-units, no doubles) | deviation (approved) |
| KG-003 | Typed precision beyond the integer scales (line discount % beyond 2 decimals -> basis points; price, tendered and flat discount beyond the currency exponent; exchange rate beyond 3 decimals) is rounded half-up at the scale on commit | deviation (approved) |
| KG-004 | Redeem points: React accepts fractional values; Flutter allows whole points only (truncate) | deviation (approved) |
| KG-005 | Flat discount input max is `totals.subtotal` (undiscounted value) while `calculate` caps at the line-discounted subtotal | replicated |
| KG-006 | Forex card: the currency selector (USD/EUR/AED/FC) changes only the label, one rate (8.561) is applied to all, and "FC" appears twice. Converted figure shown with 2 decimals regardless of currency | replicated |
| KG-007 | Refunds do not create a refund record or negative sale, do not reduce sale totals or report totals, do not restore redeemed points, and the Sales page shows no return status | replicated |
| KG-008 | Sale numbers come from `sales.length + 1`; held refs from the last 6 digits of the clock; customer ids from the clock (collisions possible) | replicated |
| KG-009 | No loyalty points are earned, only redeemed (1 point = one currency unit) | replicated |
| KG-010 | Credit sales have no ledger, credit limit or settlement | replicated |
| KG-011 | No split payments (one mode per sale) | replicated |
| KG-012 | No shifts, auth or roles: cashier `MGTCASH3`, stores and counter are hardcoded; Close/Logout shows a summary and a signed-out screen but closes nothing | replicated |
| KG-013 | Recall of a held bill whose product no longer exists crashes in React (`products.find(...)!`) | guarded in Flutter (DEC-003), otherwise replicated |
| KG-014 | F2-F6 fire inside text inputs and while modals are open (e.g. F4 holds a bill under an open dialog) | replicated on purpose |
| KG-015 | On web, F3 / F5 / F6 (and possibly Ctrl+K) can also trigger browser defaults; whether Flutter prevents them is unverified | unverified (check in spike 1.4a) |
| KG-016 | Notifications text and the "3" badge are hardcoded; profile button and kebab button open the same menu | replicated |
| KG-017 | Online/Offline toggle is cosmetic (banner only); no sync | replicated |
| KG-018 | Print button is a silent stub (React calls `window.print()`); Email and WhatsApp are "(demo)" toasts | replicated (Print: stub, no feedback) |
| KG-019 | Subcategory chips for "All Items" and "Favourites" omit Oral Care, Bath & Body, Hair Care, Noodles | replicated |
| KG-020 | "Sold out" styling exists for stock 0 but add is blocked by a stock toast; stock cannot be adjusted anywhere | replicated |
| KG-021 | Products and Customers pages are read-only (no add/edit/stock adjust for products; customers can only be added) | replicated |
| KG-022 | Reports cover today only and ignore refunds (see KG-007); Credit counted in Total but not in the Cash/Card closing summary | replicated |
| KG-023 | Hardcoded values: quick cash amounts 100/500/2000, 5 s toast duration, "MAISON GALAXY"/"Axpert POS" brand text, receipt cashier name | replicated |
| KG-024 | Change Due shows negative values in red when tendered is empty or short (e.g. "-21.00") | replicated |
| KG-025 | `V - S + BD` in React can yield `-0.00` from float noise in rare cases; Flutter is exact and shows `0.00` | deviation (unavoidable) |
| KG-026 | React float artifacts at exact half-minor-unit boundaries: Flutter rounds exactly half-up; accepted 1-unit mismatches are listed in `test/fixtures/known_ties.json` (reviewed by the user) | deviation (approved) |
| KG-027 | One shared `filter` string serves the catalog filter and the Products/Customers/Sales search boxes; cleared only by sidebar clicks, not by browser back | replicated |
| KG-028 | Persistence: React `localStorage` data is not imported; Flutter seeds from mock data on first run via `LocalStore` | deviation (approved) |
| KG-029 | Summary panel width differs between POS (`clamp(300px,24vw,380px)`) and other pages (about 310px) | replicated |
| KG-030 | Prototype has no layout for portrait or very narrow windows (below about 1000px); Flutter adds none (target: desktop and tablet landscape) | not built |

## B. Visual verification status

Only light mode at the reference viewport (2124x1180 px, see `react_audit.md` section 3) can be compared to screenshots: POS (empty, with one line), Products, Customers, Sales, Returns, Reports.

| ID | Area | Status |
|---|---|---|
| KG-040 | Media rule width <= 1700 (stacked cart line, stacked cart actions, stat tile sizes) | unverified |
| KG-041 | Media rule width <= 1280 (top bar 56, sidebar 64, hidden hint/caption, 2-column grid with cart, wrapped cart heading) | unverified |
| KG-042 | Media rule width <= 1100 (hidden line image/barcode, brand/store sizes, vertical stat tiles) | unverified |
| KG-043 | Media rule height <= 960 (summary compaction) | unverified |
| KG-044 | Media rule height <= 820 (tight summary) | unverified |
| KG-045 | Media rule height <= 719 (collapsed member card and floating panel) | unverified |
| KG-046 | Fluid `clamp(vw/vh)` values at any size other than the reference viewport | unverified |
| KG-047 | `@media print` receipt layout (80mm) and reduced-motion rule | unverified |
| KG-048 | Dark mode, all screens and components (built from the 13 `.dark` rules only) | unverified |
| KG-049 | All modals, drawer, popovers, toasts, tooltips, receipt, confirm dialogs, signed-out screen, More/Settings page | unverified (built from CSS and code; user may supply screenshots per step) |
| KG-050 | Hover, focus, active, disabled states other than those visible in the 7 screenshots | unverified |
| KG-051 | Browser-native `<select>` look, thin scrollbars, `backdrop-filter` blur and text anti-aliasing cannot match Chrome pixel for pixel in Flutter goldens | accepted limit |

## C. Dark mode: components with no React override

Rule: where React does not override a color in `.dark`, Flutter keeps the same value in both modes. The only dark overrides in the CSS are the 6 variables plus these rules: `.cart-line` bg card; `.cart-line.selected-line` bg `#273c58`; `.invoice`, `.apply-discount` and `.action.blue` bg `#233b60`; `.action.red` bg `#492838`; `.action.purple` bg `#362c59`; `.action.orange` bg `#493822`; `.action.neutral` bg `#303b4e`; `.qty-control button` and `.inline-payment .quick-amounts button` bg `#2d4260`; `.summary-rows>div` and `.membership>label` color muted; `.product-image img` blend normal + radius 4; `.quick-actions .action:hover` brightness 1.2; `.line-edit input` border = border token.

Components that will therefore look the same as light (to be completed per component while building, one row each):

| ID | Component (no dark override) | Status |
|---|---|---|
| KG-060 | Hardcoded light tints and text: stock pills, qty badge, cash-chosen toggle, sale-toggle pills (`#647694`), category/selection chips that use fixed hex | to confirm per component |
| KG-061 | Pay buttons (cash/card gradients and unpressed outline colors), terminal state colors, toast border/icon, favourite star | to confirm per component |
| KG-062 | Sidebar active gradient (`#dfeaff`->`#e8f3ff`), qty button hover/remove colors, trash button tint, discount dot, tooltip, modal overlay | to confirm per component |
| KG-063 | Input/select/field backgrounds that use variables follow the dark variables; any fixed hex backgrounds do not | to confirm per component |

Rows KG-060..063 are placeholders; each phase 2/3 step adds concrete component rows here.
