# React prototype audit (source of truth for Phase A)

Purpose: so sessions never re-read all of `reference_react/`. Read only the line ranges listed in section 9 when building a matching screen.
Prototype: `reference_react/` (React 19, Vite 8, TS 5.7, `lucide-react@1.52.0` pinned in pnpm-lock, `react-router` 7). READ-ONLY, outside git.
Status: written during plan v2 approval. Items marked **(inferred)** were not measured directly.

---

## 1. Stack

| Item | Value |
|---|---|
| Entry | `src/main.tsx` -> `src/App.tsx` (one 2620-line component `POSApp`), `src/data.ts` (264 lines: types, seed data, `cartReducer`, `calculate`, `money`, `lineTotal`), `src/index.css` (433 lines, ~57 KB, mostly minified line 5 + `@media screen` blocks) |
| Styling | Tailwind v4 is imported but unused; all styling is hand-written class CSS |
| State | `useReducer(cartReducer)` for the cart, ~40 `useState` hooks in `POSApp` |
| Persistence | `localStorage`, key prefix `axpert-`: cart, products, customers, held, sales, store, dark, beep, counter, rate |
| Routing | `react-router`, one catch-all route `*`. Page is derived from `location.pathname` |
| Icons | `lucide-react` 1.52.0 (45 icons, see section 6) |
| Font | Roboto Condensed 400/500/600/700 (Google Fonts import) |
| Assets | `public/products/0..11.png` (12 product images). Products 12-19 use a CSS placeholder (juice or care) |
| Brand text | "Axpert POS", logo letter "A", store names `MAISON GALAXY - OZONE / CENTRAL / MARINA`, cashier `MGTCASH3` (Cashier), counter default `C3` |

## 2. Routes and screens

| Path | Page | Purpose |
|---|---|---|
| `/` (and any unknown path) | POS | Catalog, cart, inline checkout |
| `/products` | Products | Read-only product table + search |
| `/customers` | Customers | Read-only customer table, Add Customer button |
| `/sales` | Sales | Completed bills, "View receipt" |
| `/returns` | Returns | Find bill, refund and restock |
| `/reports` | Reports | Today's totals + bar chart by payment mode |
| `/more` | "Settings" (title) | Dark mode and Scan beep toggles |
| state `signedOut` | Counter closed | Full-screen card, "Start new shift" |

Persistent on EVERY page: top bar, left sidebar, Bill Summary panel (right), toasts. On non-POS pages the summary column is narrower (about 310 CSS px, from a `310px!important` rule in the minified line 5 and the screenshots) than on POS (`clamp(300px,24vw,380px)`). **(to be confirmed in css_metrics.md)**

Modal ids (single `modal` string state): scan, priceCheck, customers, addCustomer, discount (right drawer 390px), recall, reprint, receipt, settings, profile, shortcuts, counter (rename), note, close (shift summary). Separate: confirm dialog, recall-conflict dialog ("Replace current" / "Hold & recall").

## 3. Reference screenshots (`reference_screenshots/`, outside git)

All 7 files are the same size: **2124 x 1180 px, 144 dpi** (macOS Retina capture), all LIGHT mode. (The user said 5; there are 7.) Each includes a thin dark macOS window-frame border (about 8 px) around the page.

| File | Pixels | Screen | Mode | Notes |
|---|---|---|---|---|
| Screenshot 2026-10-07 at 4.56.50 PM.png | 2124x1180 | POS, empty cart (catalog full width, 7-column grid, 20 products, caption "PRODUCT CATALOG 20 items") | light | Search not focused. Bill Summary all zeros. Cash/Card disabled |
| Screenshot 2026-10-07 at 4.57.09 PM.png | 2124x1180 | POS with 1 line (Lays Classic 52g x1, 3 columns: catalog 2-col grid, cart panel, summary) | light | Search focused. Cart line is the single-row layout. Change Due shows red "-21.00" |
| Screenshot 2026-10-07 at 4.57.21 PM.png | 2124x1180 | Products page | light | Cart still has the line (summary persists) |
| Screenshot 2026-10-07 at 4.57.32 PM.png | 2124x1180 | Customers page | light | |
| Screenshot 2026-10-07 at 4.57.41 PM.png | 2124x1180 | Sales page (empty state) | light | |
| Screenshot 2026-10-07 at 4.57.54 PM.png | 2124x1180 | Returns page (no bill entered) | light | |
| Screenshot 2026-10-07 at 4.58.11 PM.png | 2124x1180 | Reports page (zeros) | light | |

Not covered by any screenshot: More/Settings page, dark mode, all modals/drawers/popovers/toasts, hover/focus/disabled states beyond what is visible, Credit sale, card flow, offline banner, receipt, signed-out screen, list view, other viewport sizes.

### Reference viewport and media queries

Per the user's decision, the measured pixel size 2124 x 1180 is THE reference viewport, used for all pixel comparisons (light mode). Treated as CSS px (scale 1):

| Query | Threshold | Applies at 2124x1180? |
|---|---|---|
| max-width 1700 | 2124 > 1700 | no |
| max-width 1280 | | no |
| max-width 1100 | | no |
| max-height 960 | 1180 > 960 | no |
| max-height 820 | | no |
| max-height 719 | | no |

=> **No width or height media query applies at the reference viewport; only the base (unconditional `@media screen`) rules apply.**

Visual cross-check (the screenshots agree): the cart line is the single-row layout (the stacked layout exists only at width <= 1700), the sidebar shows icons plus labels at full size, the member card is expanded (collapses only at height <= 719), summary rows are about 34 CSS px tall (the height <= 960 rule would compact them to 28), and the catalog shows 7 product columns.

Caveat **(inferred)**: if the capture were read as 2x Retina CSS px (1062 x 590), the <=1100 and <=719 queries would apply, which the screenshots contradict. The measured on-screen sizes (summary panel about 424 px vs CSS 380 max; top bar about 71 px vs CSS 64) suggest about 1.11 image pixels per CSS px, i.e. a CSS viewport near 1900 x 1050 inside the window frame. Same query set either way, and nearly all `clamp()` values saturate at their max, but a few `vw`-based clamps differ by 1-2 %. Step 1.2 calibrates the scale from fixed-size elements (top bar 64, summary 380, sidebar 80) and records it in `css_metrics.md` before the golden size is fixed.

## 4. Design tokens (from `index.css`; cascade-resolved values go in `css_metrics.md`, step 1.2)

**Cascade warning:** later rules override earlier ones at equal specificity, including across media blocks. Block order in the file: line 5 (minified base) -> `@media screen` (line 8) -> `<=1280` (171) -> `<=1100` (190) -> `<=height 820` (206) -> `@media screen` (236, overrides several base values) -> `<=1700` (342) -> `<=1100` (364) -> `<=height 960` (377) -> `<=height 820` (401) -> `<=height 719` (426) -> print (433). Example: the `<=1280` rule `.line-product img{display:none}` is overridden by the later base `display:block`.

### Colors, light

| Token | Value |
|---|---|
| background | `#eff4f9` |
| card | `#ffffff` |
| secondary | `#f3f6fa` |
| text | `#102047` |
| muted | `#7585a4` |
| border | `#e4ebf4` |
| blue | `#0061ff` |
| primary button | `#0968ee` (text white) |
| focus ring | `#78aaff`, 2px, offset 2px |
| action blue | bg `#edf5ff`, fg `#0060ff` |
| action red | bg `#fff0f3`, fg `#ff2036` |
| action purple | bg `#f1edff`, fg `#7a20ff` |
| action orange | bg `#fff6eb`, fg `#db7900` |
| action neutral (dark) | bg `#303b4e`, fg text |
| pay-cash | gradient `#2caa78` -> `#05945d`; unpressed: card bg, `#078b5c`, border `#acd9c7` |
| pay-card | gradient `#4796ff` -> `#0860ef`; unpressed: card bg, `#166ee3`, border `#b1cdf4`; pressed outline `#94bdfa` |
| green | button `#049667`, icon `#019354`, cash-chosen `#00824c` on `#e2f5ed`, terminal approved `#079567`, declined `#df354d` |
| stock ok / low (<10) | `#078255` on `#e2f6ed` / `#b76b02` on `#fff0d8` |
| toast | left border `#13a274`, icon `#08a575` |
| star / favourite | `#f3a400` |
| qty badge | `#0063ff` on `#e8f2ff` |
| sidebar active | gradient `#dfeaff` -> `#e8f3ff`, 2px blue left bar |
| selected cart line | bg `#f0f6ff`, border `#adcbf5`, shadow `0 3px 12px #2076df0c` |
| qty button | `#edf2f8` on `#38567f`; hover `#dbeaff`/`#0061ee`; remove `#ffedf1`/`#e62d49` |
| trash | `#fff0f3`, hover `#ffe0e8` |
| line-edit input | border `#dce5f2`, bg secondary |
| discount dot | `#f02b4a` |
| action tooltip | bg `#142746`, text white |
| modal overlay | `#10213b55` + `backdrop-filter: blur(4px)` |

About 70 distinct hex values exist in the CSS; the full list is built into the token classes in step 1.2.

### Colors, dark (`.dark`, all rules in the file)

Variables: background `#162134`, card `#1d2b41`, secondary `#26344a`, text `#e4ecfa`, muted `#a4b4ce`, border `#35445e`.

Rules (13): `.cart-line.selected-line` bg `#283a55` (line 5) and again `#273c58` (line 337, later wins); `.invoice, .apply-discount, .action.blue` bg `#233b60`; `.summary-rows>div, .membership>label` color muted; `.product-image img` mix-blend-mode normal + radius 4px; `.action.red` bg `#492838`; `.action.purple` bg `#362c59`; `.action.orange` bg `#493822`; `.action.neutral` bg `#303b4e` color text; `.cart-line` bg card; `.qty-control button, .inline-payment .quick-amounts button` bg `#2d4260`; `.quick-actions .action:hover` brightness 1.2; `.line-edit input` border-color border.

Everything else has no dark override and stays identical in dark (see `known_gaps.md`, dark section). (Plan v2 text said "6 variables and 4 rules": that was wrong; this list is correct.)

### Typography
Roboto Condensed 400-700. Root font-size 14px; on screens `clamp(11px, .85vw, 14px)`. Sizes seen: 9, 10, 11, 12 (most common), 13, 14, 15, 16, 17, 18, 20 (h2), 25 (modal h2), 26 (brand), plus many `clamp()` fluid sizes. `small` = 12px muted. No spacing scale: ad hoc px and `clamp()` (panel pad and layout gap are fixed at 16px by the line-236 block, overriding the earlier clamps).

### Radii
4, 5, 6, 7, **8 (most used)**, 9, 10, 11 (`--radius` base), 12, 14 (panels, summary cards, `--radius` after line 236), 16 (modal), 22 (pill toggles), 50%.

### Shadows
modal `0 25px 80px #0d203844`; popover `0 12px 40px #10204720`; toast `0 6px 30px #17294a25`; floating member panel `0 8px 32px #10204730`; product card hover `0 4px 15px #276ed810`; summary card `0 2px 9px #193b6710`; plus about 8 subtler variants (inset highlights on buttons).

### Layout constants (base, screen)
Top bar 64 (56 at <=1280); sidebar 80 (64 at <=1280); summary `clamp(300px,24vw,380px)` on POS, about 310 on other pages; modal 460 wide; drawer 390; toast min-width 290; control heights 43 (primary/secondary), 44-52 (actions), 31-36 (inline payment); POS main grid: no cart = catalog + summary; with cart = `2fr 3fr summary`.

## 5. Media queries and what each changes (effective, summary)

| Query | Changes | Planned Flutter rule |
|---|---|---|
| base `@media screen` blocks | fluid `clamp(vw/vh)` sizes; fixed 16px panel pad / layout gap; radius 14 | `AppMetrics` from window logical size |
| width <= 1700 | cart line becomes stacked 2-row (152px qty cell, price/discount second row, total and trash absolutely positioned); cart actions stack icon over label; smaller stat tiles | `CartLineLayout.stacked` |
| width <= 1280 | top bar 56, sidebar 64; hide kbd hint and catalog caption; product grid 2 columns when cart present; cart heading wraps (time on own row); smaller profile/add-customer/sale-toggle | `AppMetrics` switch + flags |
| width <= 1100 | hide line barcode and image; brand/store select shrink (store 160); stat tiles vertical, no icons; 12px paddings; customer-row icon hidden | flags |
| height <= 960 | summary compaction (rows 24-28, inputs 28, payment 46, quick actions 44px squares) | `SummaryDensity.compact` |
| height <= 820 | further compaction (rows 21, inputs 22, payment 34-38, invoice 42) | `SummaryDensity.tight` |
| height <= 719 | member card collapses to a one-line header; form opens as fixed floating panel | `memberCollapsed` |
| print | hide everything except the receipt (80mm, 5mm padding, 11px) | `ReceiptDocument` preview |
| prefers-reduced-motion | disable animation/transition on `.main`, `.center-column`, `.toast`, `.modal` | `AppMotion` zero duration |

Only the base rules can be compared visually (reference viewport). All query rows are "unverified visually" (see known_gaps.md).

## 6. Reusable components (implemented as CSS classes, not React components)

| Component | Variants / states |
|---|---|
| Buttons | primary, secondary, green, text-button, icon button, `.action` (blue/red/purple/orange/neutral; small badge, discount dot, clear-hold clock), `.pay-cash`/`.pay-card` (pressed/unpressed/disabled), `RepeatButton` (hold-to-repeat: 500 ms delay, then every 140 ms) |
| Button states | hover brightness .97, active translateY(1px) (scale .95 on actions), disabled opacity .45 + not-allowed, `:focus-visible` ring |
| Inputs | text, number (spinners hidden), select (native look), `QuantityInput` (draft string, `toFixed(3)`, commits on change when > 0, 0 commits on blur, Enter blurs), checkbox toggles, `.field` (icon + input + trailing button), `.modal-input` |
| Chips | category chips (selected, per-icon colors, scroll-next arrow), subcategory chips, sale-type radio pills |
| Segmented | percent/flat (discount drawer); grid/list view toggle |
| Cards | product card (grid and list variants; in-cart, sold-out, hover, focus; favourite star; qty badge x{n}; stepper), summary cards, stat tiles |
| Tables | cart table (header + lines with selected/highlight animation), data tables (Products, Customers, Sales), receipt table |
| Overlays | modal, right drawer, confirm, recall-conflict; overlay click and Esc close; popovers (notifications, user menu, order menu) |
| Toasts | success/warning/error/info; 5 s auto-dismiss, max 4 shown, optional Undo, dismiss X, bottom center |
| Tooltip | `ActionButton` portal tooltip (hover, focus, long-press 500 ms on touch, hides after 1.8 s) with shortcut hint, e.g. "Hold (F4)" |
| Misc | badges/dots (notification count "3", held count on Recall, online dot/offline dot, discount dot), spinner, empty states, no-results block, offline banner (20px), kbd chip, avatar, bar chart (`chart-track`) |

Lucide icons used (45): ShoppingCart, ShoppingBag, Users, FileText, Undo2, ChartNoAxesColumnIncreasing, MoreHorizontal, Search, Barcode, Bell, MoreVertical, ChevronDown, ChevronRight, Star, CupSoda, Cookie, BottleWine, LayoutGrid, List, Plus, Minus, Trash2, UserRound, CreditCard, Banknote, Percent, PauseCircle, RotateCcw, Printer, X, Power, Package, IndianRupee, Check, Settings, Volume2, Wifi, Clock, Mail, Smartphone, LogOut, Keyboard. (All verified present in `lucide_icons_flutter` 3.1.22 = Lucide 1.52.0.)

## 7. Mechanics and business logic

### Entities (`data.ts`)

| Entity | Fields |
|---|---|
| Product | id, name, code, barcode, price, category, sub, stock, gst (percent int), image (index or -1), favourite |
| Customer | id ("walk", "1".."3"), name, phone, email, member, points |
| Line | product, qty (fractional), price (editable), discount (% 0-100) |
| Cart | lines, customer (id), saleType "Cash"/"Credit", billDiscount, discountType "percent"/"flat", reason, points, note |
| Held | ref ("H" + last 6 digits of Date.now()), time (ISO), cart |
| Sale | number ("AX" + 6-digit sales.length+1), date (ISO), store, customer (NAME), cart, totals, mode ("Cash"/"Card"/"Credit"/"Unpaid" for draft), tendered, change, returned {productId: qty} |
| Totals | items, qty, value, subtotal, discount, tax, points, total |
| Settings-ish | dark, beep, store, counter ("C3"), rate (8.561, FC), currency label (USD default; not persisted), notifications (hardcoded) |

### Seed data
Products (index = id). Barcode: ids 0-9 = `8901234567890 + id`; ids 10-19 = `8901234567800 + id - 10`. Stock: id 14 = 8, else `45 + id*3`. GST: `[18,12,5][id % 3]`. Favourite: ids 0, 5, 8.

| id | name | code | price | category | sub | image |
|---|---|---|---|---|---|---|
| 0 | Coca Cola 500ml | BDV001 | 40 | Beverages | Soft Drinks | 0 |
| 1 | Pepsi 500ml | BDV002 | 40 | Beverages | Soft Drinks | 1 |
| 2 | Sprite 500ml | BDV003 | 40 | Beverages | Soft Drinks | 2 |
| 3 | Fanta 500ml | BDV004 | 40 | Beverages | Soft Drinks | 3 |
| 4 | Kinley Water 1L | WTR001 | 20 | Beverages | Water | 4 |
| 5 | Lays Classic 52g | CHP001 | 20 | Snacks | Chips | 5 |
| 6 | Lays Masala 52g | CHP002 | 20 | Snacks | Chips | 6 |
| 7 | Oreo Biscuit 120g | BSC001 | 35 | Snacks | Biscuits | 7 |
| 8 | Dairy Milk 40g | CHC001 | 40 | Snacks | Confectionery | 8 |
| 9 | KitKat 4 Finger | CHD002 | 30 | Snacks | Confectionery | 9 |
| 10 | Maggi Noodles | NOD001 | 14 | Snacks | Noodles | 10 |
| 11 | Closeup 150g | PER001 | 85 | Personal Care | Oral Care | 11 |
| 12 | Real Mango Juice 1L | JUC001 | 110 | Beverages | Juices | -1 |
| 13 | Tropicana Orange 1L | JUC002 | 125 | Beverages | Juices | -1 |
| 14 | Paper Boat Aam 200ml | JUC003 | 30 | Beverages | Juices | -1 |
| 15 | Dove Soap 100g | PER002 | 65 | Personal Care | Bath & Body | -1 |
| 16 | Dettol Handwash 200ml | PER003 | 99 | Personal Care | Bath & Body | -1 |
| 17 | Colgate Total 100g | PER004 | 90 | Personal Care | Oral Care | -1 |
| 18 | Good Day Cookies 100g | BSC002 | 25 | Snacks | Biscuits | -1 |
| 19 | Himalaya Shampoo 200ml | PER005 | 155 | Personal Care | Hair Care | -1 |

Customers: walk "Walk-in Customer" (no phone/email/member, 0 pts); "1" Ananya Sharma 9876543210 ananya@example.com MG1001 250 pts; "2" Rahul Mehta 9876543211 rahul@example.com MG1002 120; "3" Priya Nair 9876543212 priya@example.com MG1003 400.

Placeholder images (id -1): juice (Beverages: first word of name + "100% JUICE") or care (others: first word + "DAILY CARE").

### `cartReducer`
- addItem: no-op if `existing.qty + 1 > stock`; else add line (qty 1, price = product price, discount 0) or qty+1.
- increaseQty / decreaseQty / setQty / setPrice / setLineDiscount: apply to the line by product id. setPrice = `max(0, value||0)`; setLineDiscount = clamp 0..100; qty = `min(stock, max(0, qty))`; lines with qty <= 0 are removed. No rounding anywhere.
- removeLine; restoreLine (only if not already present, appended at end); clearCart and holdCart both return the empty cart; recallCart replaces; metadata merges a patch.

### `calculate(cart, availablePoints)` (exact formulas; see decisions DEC-002)
`L_i = qty*price*(1 - disc/100)`; `V = sum(qty*price)`; `S = sum(L_i)`; `BD = min(S, percent ? S*bd/100 : bd)`; `ratio = S ? (S-BD)/S : 0`; `T = sum(L_i*ratio*gst/100)`; `P = min(cart.points, available, S-BD+T)`.
Output: items = lines.length (not rounded); qty = sum qty (not rounded); value = R(V); subtotal = R(V) (gross, NOT discounted); discount = R(V - S + BD); tax = R(T); points = R(P); total = R(max(0, S - BD + T - P)), computed from the unrounded values.
`R(x) = Math.round((x + Number.EPSILON) * 100) / 100`. Displayed rows may not sum to total by one minor unit. `lineTotal` is not rounded (display only, via `Intl` 2 decimals). `money(x)` = "₹" + en-IN grouping with exactly 2 decimals.

### Flows (logic lives in `POSApp`, lines in section 9)
- **add(product)**: stock check (+toast "Available stock: N", kind warning), dispatch addItem, highlight + scroll to bottom (1.6 s), select, toast "{name} added", beep, clear search, refocus search (after 40 ms).
- **scanProduct(value)**: match barcode (trimmed) or code (case-insensitive) -> add; else toast error "Product not found for barcode {value}".
- **Top-bar search**: if text is non-numeric, show up to 6 name/code matches; Enter adds the first match, otherwise treats as scan.
- **changeQty(line, qty)**: qty > stock -> toast "Only N available in stock" (warning), no change; qty <= 0 -> remove; else setQty.
- **remove(line)**: removeLine + toast "{name} removed" (kind info) with Undo (restoreLine); toast lasts 5 s.
- **hold()**: needs items (else toast "Add items before holding a bill"); appends Held, resets cart, toast "Bill held. Ready for a new sale."
- **recall(bill, holdCurrent)**: optionally hold current; re-reads products by id (CRASHES if a product is missing; guarded in Flutter, DEC-003), clamps qty to current stock, drops zero-qty lines, removes the bill from held, closes modal, toast "Bill {ref} recalled". If a cart is active, a confirm dialog offers "Replace current" / "Hold & recall".
- **clear()**: clearCart + member input cleared + refocus. **askClear** shows confirm "Clear all items and start a new sale?". Clear Hold: confirm "Delete all N held bills?", toast "Held bills cleared".
- **payment(mode)**: Credit sale needs a non-walk-in customer (toast warning "Select a customer for a credit sale"), then confirm "Save {total} on credit for {name}?" -> `complete("Credit", 0)`. Cash: sets paymentMode cash, tendered = total.toFixed(2), focuses tendered. Card: sets mode card, terminal "waiting", decline false. Card simulation: after 2 s terminal becomes "approved" (or "declined" if the Simulate Decline checkbox is on); Retry resets.
- **canPay** = has lines AND (Cash sale OR customer is not walk-in).
- **complete(mode, amount)**: re-checks stock vs current product stock (toast error "Stock changed. Please adjust your quantities."); builds Sale; `number = "AX" + (sales.length+1) padded 6`; `change = mode==="Cash" ? max(0, amount - total) : 0`; appends sale; decrements stock; deducts redeemed points from the customer; clears cart; opens the receipt modal; toast "Saved on credit" or "Payment completed".
- **Cash inline**: quick amounts [Exact(total), 100, 500, 2000]; Enter in tendered completes when tendered >= total; Complete button enabled when tendered >= total (or Credit); change due = tendered - total (can show negative, red).
- **saveCustomer**: requires name, phone matching `^\+?[\d\s-]{7,15}$`, optional email matching `^[^\s@]+@[^\s@]+\.[^\s@]+$` (else toast "Enter a name, valid phone and email"); id = Date.now(), member "MG" + last 5 digits of Date.now(), points 0; selects the new customer; toast "Customer added".
- **memberLookup**: exact case-insensitive match on member number auto-selects the customer (toast "Welcome, {name}"), resets cart points to 0. Enter with unknown number: toast warning "Member not found. Try MG1001, MG1002 or MG1003". Changing customer resets cart points to 0. Points redeemed are clamped 0..customer points.
- **Discount drawer**: type percent/flat, value clamp 0..(100 or totals.subtotal), reason; Remove sets billDiscount 0 and reason ""; Apply stores them. Opened via F6, Discount button.
- **Returns / refund**: lookup by bill number (case-insensitive); per-line qty up to (sold - already returned); refund amount = `sum(total * ((line.qty*line.price)/sale.totals.value) * qty / line.qty)`; confirm "Refund {amount} and restock selected items?"; on confirm adds qty back to product stock and increments the sale's `returned` map; toast "Refund completed: {amount}". Errors: "Select items to refund"; "Refund quantity exceeds remaining sold quantity".
- **Reports**: today's sales (same calendar day as `now`): sum of totals, count, average, per-mode (Cash/Card/Credit) bars as share of the total. Refunds are not reflected.
- **Shift close** (Logout/Close): shows total sales, Cash, Card, number of bills (today); "Confirm & close counter" sets `signedOut`; "Start new shift" returns. Nothing is actually closed.
- **Other**: rename counter, add order note (shown as "Note: ..." in the cart), Print draft (receipt with number "DRAFT", mode "Unpaid"), store switcher (toast "Store switched"), online/offline toggle (banner "Offline mode – bills will sync later"), FC converter: `converted = total / rate`, shown with `toFixed(2)`; currency select USD ($) / EUR / AED / FC only changes the label.
- **Notifications popover** (hardcoded): "Paper Boat stock is running low", "All bills successfully synced", "{held} held bills waiting"; opening clears the "3" unread badge.

### Keyboard (window `keydown`, re-registered every render)
Ctrl/Cmd+K focus search; F2 cash payment; F3 card payment; F4 hold; F5 recall; F6 discount; Esc closes modal and menus; Delete removes the selected line (only when not in an input, no modal open, a line selected). F-keys fire even inside inputs and with modals open (replicated on purpose, KG-014). Product card: Enter adds. Tendered field: Enter completes. Focus returns to the search input after nearly every action. The "kbd" hint on the search bar is hardcoded "⌘K" (Flutter: platform-aware, DEC-007).
Shortcuts dialog lists: ⌘ / Ctrl + K "Focus barcode search"; Enter "Add scanned product"; F2 "Cash payment"; F3 "Card payment"; F4 "Hold bill"; F5 "Recall bill"; F6 "Apply discount"; Delete "Remove selected line"; Esc "Close dialog".

### Responsive/visual behaviors worth knowing
Product list/grid toggle; catalog filter text is a single shared state used by the catalog filter and the Products/Customers/Sales search boxes, cleared on sidebar clicks; category change resets sub to "All"; subcategory chips per category (Personal Care: Oral Care, Bath & Body, Hair Care; Snacks: Chips, Biscuits, Confectionery, Noodles; Beverages: Soft Drinks, Juices, Water; All/Favourites: Soft Drinks, Juices, Water, Chips, Biscuits, Confectionery).

## 8. Open questions / oddities
See `known_gaps.md` (IDs KG-xxx) and `decisions.md` (DEC-xxx). Not repeated here.

## 9. Line index (read only the matching range when building a screen)

`src/App.tsx`: imports 1-67; persistence helpers 69-84; nav/store constants 85-98; `POSApp` state 106-175; derived/memo 173-231; helpers (toast, close, open) 232-252; effects 253-287; beep 288-304; add/scan/remove/changeQty 305-348; hold/recall/clear/payment/complete 349-468; saveCustomer/memberLookup 469-503; keydown handler 504-535; openDiscount/saleToggle/customerSelect/actionButton 536-592; shift/refund 593-662; signed-out screen 664-682; top bar 685-813; offline banner 814-818; sidebar 820-836; POS catalog 846-1088; cart panel 1089-1333; Products 1362; Customers 1405; Sales 1435; Returns 1488; Reports 1550; More 1602; Bill Summary 1612-1792; toasts 1795-1825; modals: shell 1826-1850, confirm 1850, recall-conflict 1871, scan 1895, priceCheck 1950, customers 1992, addCustomer 2044, discount 2073, recall/reprint 2177, receipt 2253, settings 2351, profile 2362, shortcuts 2380, counter/note 2401, close 2431; `RepeatButton` 2493; `ActionButton` 2521; `SettingsContent` 2561; `QuantityInput` 2604.
`src/data.ts`: types 1-13, seed rows 14-51, customers 52-93, cart types 94-119, reducer 129-202, `money`/`lineTotal` 203-210, `calculate` 211-247, Held/Sale types 248-264.
`src/index.css`: line 5 = minified base (components + `.dark` + a `310px!important` rule); line 8 `@media screen` base fluid layout (to ~170); 171 `<=1280`; 190 `<=1100`; 206 `<=h820`; 236 `@media screen` overrides (panels, cart line, qty control, `.dark` 336-340); 342 `<=1700`; 364 `<=1100`; 377 `<=h960`; 401 `<=h820`; 426 `<=h719`; 433 print.
