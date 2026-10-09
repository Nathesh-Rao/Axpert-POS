# Phase B backlog (S7)

Source: `known_gaps.md` (**154 entries**, KG-001 to KG-177 with unused numbers) and `decisions.md` (**85 entries**, DEC-001 to DEC-108 with unused numbers), triaged on 2026-10-09. Every id appears once in the tables at the end (checked by a script).

## Buckets
- **MUST**: must be fixed or built in Phase B (the prototype behaviour is wrong or missing for a real POS).
- **QUIRK-DROP**: a React quirk that was copied (port-as-is) and should be dropped or changed in Phase B.
- **QUIRK-KEEP**: a React behaviour worth keeping on purpose.
- **ACCEPT**: an accepted or approved deviation, or a policy: nothing to do unless the product owner reopens it.
- **UNVERIFIED**: built from CSS and code only, with no screenshot (light mode at one viewport was the only reference): verify visually or by a user test.
- **DONE**: resolved, superseded, or a temporary note.

Priority: **P0** POS-critical (money, data safety, fiscal and cashier safety), **P1** needed for a real store, **P2** later, **P3** low or none.

Counts, KG: ACCEPT 46, DONE 8, MUST 39, QUIRK-DROP 17, QUIRK-KEEP 6, UNVERIFIED 38. DEC: ACCEPT 56, DONE 7, MUST 11, QUIRK-KEEP 4, UNVERIFIED 7.

## 1. Priority order

### P0 POS-critical (do first, in this order)
| Id | Bucket | What to do |
|---|---|---|
| KG-001 | MUST | displayed rows may differ from the total by one unit: decide the rounding policy per country with the tax rules and test it |
| KG-028 | MUST | data lives in localStorage-style mock storage: real offline-first database, migration, no data loss |
| KG-017 | MUST | online/offline toggle is cosmetic: real connectivity state and sync queue |
| KG-175 | MUST | fonts and CanvasKit are fetched at runtime: bundle fonts and engine for offline start |
| DEC-042 | MUST | LocalStore (JSON key-value) is the mock: replace with the offline database (KG-028) |
| DEC-044 | MUST | Roboto Condensed via google_fonts at runtime: bundle the fonts (KG-175) |
| KG-128 | MUST | held bills that cannot be restored are dropped silently: tell the cashier what was lost, never lose lines |
| DEC-003 | MUST | recall guard drops missing lines: keep the guard, add a visible report (KG-128) |
| KG-160 | MUST | while the counter is closed shortcut handlers still act on the hidden app: block them |
| KG-165 | MUST | refund by gross share ignores line discount, bill discount and points: refund what was paid |
| KG-007 | MUST | refunds create no record, do not reduce sale totals or reports, do not restore points: add refund records and a refund-aware ledger |
| KG-022 | MUST | Reports ignore refunds and Credit in the closing summary: fix with the refund ledger |
| KG-132 | MUST | customer id and membership number come from the clock: server or sequence generated, unique |
| KG-008 | MUST | sale numbers from list length, held refs from the clock: gapless server or device sequence |
| KG-125 | MUST | held references can collide in the same millisecond: unique references |
| KG-012 | MUST | no auth, roles or shifts: users, PINs/roles, shift open/close with cash count and audit log |
| KG-159 | MUST | close counter closes nothing: real shift close record with cash reconciliation |
| KG-010 | MUST | credit sales have no ledger, limit or settlement: customer credit ledger |
| KG-018 | MUST | Print is a silent stub: real receipt printing (ESC/POS or spooler) |
| KG-138 | MUST | Print records the call only; Email/WhatsApp are demo toasts: real print, email, WhatsApp |
| DEC-032 | MUST | Print, Email, WhatsApp, beep stay stubs: implement (KG-018, KG-138) |
| KG-124 | MUST | a held bill total uses the customer current points and recall does not restore redeemed points: store the totals and points with the bill |

### P1 needed for a real store
| Id | Bucket | What to do |
|---|---|---|
| KG-009 | MUST | no loyalty points are earned: earning rules |
| KG-011 | MUST | no split payments: allow several tenders per sale |
| KG-014 | MUST | F-keys fire inside inputs and under open dialogs (F4 holds a bill under a dialog): decide the rule with cashiers |
| KG-016 | MUST | notifications and badge are hard-coded: real notifications or remove |
| KG-021 | MUST | Products and Customers are read-only: product, stock and customer maintenance |
| KG-023 | MUST | hard-coded quick amounts, brand, store, cashier: configuration |
| KG-106 | MUST | stock is whole units, fractional sold quantity rounds up: units of measure |
| KG-137 | MUST | receipt texts and cashier are hard-coded: configuration and real cashier |
| KG-145 | MUST | Chrome and full web test suites were dropped: reinstate CI on web and Windows |
| KG-146 | MUST | tables are read-only (no edit, sort, credit view): maintenance screens |
| KG-150 | MUST | Today on Reports is hard-wired (no date range, cashier or store filter): reporting module |
| KG-162 | MUST | cashier id, role, avatar, brand hard-coded: user profile |
| KG-167 | MUST | stock is whole units and fractional returns round up: decide units of measure |
| KG-176 | MUST | POS overflows below 900 px and the Windows window has no minimum size: set a minimum size or add a narrow layout |
| KG-177 | MUST | 57 of 87 controls are under 44 px on tablets: enlarge hit areas or sizes |
| DEC-005 | MUST | F2-F6 fire in inputs and under dialogs (port as-is): decide the rule (KG-014) |
| DEC-104 | MUST | Chrome tests dropped from the routine: reinstate CI (KG-145) |

### P2 later
| Id | Bucket | What to do |
|---|---|---|
| KG-005 | QUIRK-DROP | flat discount limit is the gross subtotal: cap at the payable amount |
| KG-006 | QUIRK-DROP | forex selector changes only the label, one rate, FC twice: real currency table or remove |
| KG-019 | MUST | subcategory chips omit four subcategories for All Items and Favourites: fix data rule |
| KG-020 | MUST | sold-out cards have no styling: add sold-out state |
| KG-024 | QUIRK-DROP | Change Due shows negative values in red: show the missing amount instead |
| KG-025 | MUST | -0.00 float noise: not applicable with exact money; keep exact |
| KG-027 | QUIRK-DROP | one shared filter text for four pages: per-page filters |
| KG-030 | MUST | no portrait or narrow layout: product decision for tablets |
| KG-101 | MUST | every favourite toggle saves the whole product list (37 ms for 10k): per-row persistence |
| KG-107 | QUIRK-DROP | forex selector changes only the label, one rate, FC twice: real currency table or remove |
| KG-121 | QUIRK-DROP | flat discount limit is the gross subtotal: cap at the payable amount |
| KG-173 | MUST | no scrollbar gutter on Products: decide whether to show scrollbars |
| DEC-014 | MUST | Flutter pinned at 3.38.4: plan the upgrade |
| DEC-015 | MUST | iOS skipped until Phase 4: add iOS/iPad when tablets ship |
| DEC-020 | MUST | currency registry seeds: complete per target country |
| DEC-021 | MUST | tax config: inclusive mode has no React spec: validate with the tax rules per country |
| DEC-022 | MUST | inclusive-tax spec invented in Phase A: validate with accountants |

### Unverified areas to check with real users or screenshots
Dark mode and every window size other than the reference viewport, hover and focus states, dialogs and drawers, the receipt, Sales with rows, Reports with data, Settings, Profile, Close counter, Counter closed, the matched Returns bill and Phase B screens. Ids: KG-040, KG-041, KG-042, KG-043, KG-044, KG-045, KG-046, KG-047, KG-048, KG-049, KG-050, KG-060, KG-061, KG-062, KG-063, KG-070, KG-071, KG-072, KG-083, KG-094, KG-099, KG-105, KG-109, KG-110, KG-115, KG-119, KG-120, KG-126, KG-135, KG-136, KG-143, KG-148, KG-152, KG-153, KG-154, KG-163, KG-170, KG-171.

## 2. All known gaps (KG), each once
| Id | Bucket | Prio | What to do or the gap |
|---|---|---|---|
| KG-001 | MUST | P0 | displayed rows may differ from the total by one unit: decide the rounding policy per country with the tax rules and test it |
| KG-002 | ACCEPT | P3 | precision and rounding-tie decisions (accepted, 1 tie in 300 / 317 vectors) |
| KG-003 | ACCEPT | P3 | precision and rounding-tie decisions (accepted, 1 tie in 300 / 317 vectors) |
| KG-004 | ACCEPT | P3 | precision and rounding-tie decisions (accepted, 1 tie in 300 / 317 vectors) |
| KG-005 | QUIRK-DROP | P2 | flat discount limit is the gross subtotal: cap at the payable amount |
| KG-006 | QUIRK-DROP | P2 | forex selector changes only the label, one rate, FC twice: real currency table or remove |
| KG-007 | MUST | P0 | refunds create no record, do not reduce sale totals or reports, do not restore points: add refund records and a refund-aware ledger |
| KG-008 | MUST | P0 | sale numbers from list length, held refs from the clock: gapless server or device sequence |
| KG-009 | MUST | P1 | no loyalty points are earned: earning rules |
| KG-010 | MUST | P0 | credit sales have no ledger, limit or settlement: customer credit ledger |
| KG-011 | MUST | P1 | no split payments: allow several tenders per sale |
| KG-012 | MUST | P0 | no auth, roles or shifts: users, PINs/roles, shift open/close with cash count and audit log |
| KG-013 | DONE | P3 | guarded in Flutter (DEC-003) |
| KG-014 | MUST | P1 | F-keys fire inside inputs and under open dialogs (F4 holds a bill under a dialog): decide the rule with cashiers |
| KG-015 | DONE | P3 | superseded by KG-170 |
| KG-016 | MUST | P1 | notifications and badge are hard-coded: real notifications or remove |
| KG-017 | MUST | P0 | online/offline toggle is cosmetic: real connectivity state and sync queue |
| KG-018 | MUST | P0 | Print is a silent stub: real receipt printing (ESC/POS or spooler) |
| KG-019 | MUST | P2 | subcategory chips omit four subcategories for All Items and Favourites: fix data rule |
| KG-020 | MUST | P2 | sold-out cards have no styling: add sold-out state |
| KG-021 | MUST | P1 | Products and Customers are read-only: product, stock and customer maintenance |
| KG-022 | MUST | P0 | Reports ignore refunds and Credit in the closing summary: fix with the refund ledger |
| KG-023 | MUST | P1 | hard-coded quick amounts, brand, store, cashier: configuration |
| KG-024 | QUIRK-DROP | P2 | Change Due shows negative values in red: show the missing amount instead |
| KG-025 | MUST | P2 | -0.00 float noise: not applicable with exact money; keep exact |
| KG-026 | ACCEPT | P3 | precision and rounding-tie decisions (accepted, 1 tie in 300 / 317 vectors) |
| KG-027 | QUIRK-DROP | P2 | one shared filter text for four pages: per-page filters |
| KG-028 | MUST | P0 | data lives in localStorage-style mock storage: real offline-first database, migration, no data loss |
| KG-029 | QUIRK-KEEP | P3 | Summary panel width differs between POS (`clamp(300px,24vw,380px)` = 380 at the reference viewport) and other pages (310px). CONFIRMED in step 1.2: `.… |
| KG-030 | MUST | P2 | no portrait or narrow layout: product decision for tablets |
| KG-040 | UNVERIFIED | P3 | Media rule width <= 1700 (stacked cart line, stacked cart actions, stat tile sizes) |
| KG-041 | UNVERIFIED | P3 | Media rule width <= 1280 (top bar 56, sidebar 64, hidden hint/caption, 2-column grid with cart, wrapped cart heading) |
| KG-042 | UNVERIFIED | P3 | Media rule width <= 1100 (hidden line image/barcode, brand/store sizes, vertical stat tiles) |
| KG-043 | UNVERIFIED | P3 | Media rule height <= 960 (summary compaction) |
| KG-044 | UNVERIFIED | P3 | Media rule height <= 820 (tight summary) |
| KG-045 | UNVERIFIED | P3 | Media rule height <= 719 (collapsed member card and floating panel) |
| KG-046 | UNVERIFIED | P3 | Fluid `clamp(vw/vh)` values at any size other than the reference viewport |
| KG-047 | UNVERIFIED | P3 | `@media print` receipt layout (80mm) and reduced-motion rule |
| KG-048 | UNVERIFIED | P3 | Dark mode, all screens and components (built from the 13 `.dark` rules only) |
| KG-049 | UNVERIFIED | P3 | All modals, drawer, popovers, toasts, tooltips, receipt, confirm dialogs, signed-out screen, More/Settings page |
| KG-050 | UNVERIFIED | P3 | Hover, focus, active, disabled states other than those visible in the 7 screenshots |
| KG-051 | ACCEPT | P3 | Browser-native `<select>` look, thin scrollbars, `backdrop-filter` blur and text anti-aliasing cannot match Chrome pixel for pixel in Flutter goldens |
| KG-060 | UNVERIFIED | P3 | Hardcoded light tints and text: stock pills, qty badge, cash-chosen toggle, sale-toggle pills (`#647694`), category/selection chips that use fixed hex |
| KG-061 | UNVERIFIED | P3 | Pay buttons (cash/card gradients and unpressed outline colors), terminal state colors, toast border/icon, favourite star |
| KG-062 | UNVERIFIED | P3 | Sidebar active gradient (`#dfeaff`->`#e8f3ff`), qty button hover/remove colors, trash button tint, discount dot, tooltip, modal overlay |
| KG-063 | UNVERIFIED | P3 | Input/select/field backgrounds that use variables follow the dark variables; any fixed hex backgrounds do not |
| KG-070 | UNVERIFIED | P3 | ALL dark values (`AppColors.dark`, the 13 `.dark` rules and their specificity quirks, `css_metrics.md` section 4) |
| KG-071 | UNVERIFIED | P3 | Tokens for modals, drawers, popovers, toasts, tooltips, receipt, More/Settings (colors, shadows, sizes) |
| KG-072 | UNVERIFIED | P3 | Fluid `clamp(vw/vh)` values and every media-query rule (`css_metrics.md` sections 10, 11); fluid ones marked "fluid" move with the exact window size |
| KG-073 | ACCEPT | P3 | Inset box-shadows (pay-button pressed highlight, qty control ring, quick-action hover ring) cannot be a Flutter `BoxShadow`; drawn by widgets later |
| KG-074 | ACCEPT | P3 | Dark `.product-image img` `mix-blend-mode: normal` and 4px radius are kept as `AppColors` flags (`productImageMultiply`, `productImageRadius`); multip… |
| KG-075 | ACCEPT | P3 | Roboto Condensed text anti-aliasing and sub-pixel positioning differ between Chrome/macOS and Flutter; the specimen golden compares colors and type on… |
| KG-076 | ACCEPT | P3 | Screenshot colors are shifted by 1-3 per channel against the CSS hex (macOS capture colour profile), e.g. page bg `#f0f4f8` vs `#eff4f9`, red action t… |
| KG-077 | ACCEPT | P3 | Flutter text runs about 1-3 % wider/narrower than Chrome for the same string (hinting, sub-pixel advance), e.g. "Subtotal" 49 px vs 47 px ink width at… |
| KG-078 | ACCEPT | P3 | Fonts are fetched at runtime via `google_fonts` 6.3.3; offline first launch falls back to the system font; brief fallback flash on web; macOS `com.app… |
| KG-079 | ACCEPT | P3 | precision and rounding-tie decisions (accepted, 1 tie in 300 / 317 vectors) |
| KG-080 | ACCEPT | P3 | Shared widgets (buttons, inputs, chips, cards, tables, overlays) are built when first needed in S2-S5 instead of a dedicated Phase 2; no separate widg… |
| KG-081 | ACCEPT | P3 | Shared widgets have no standalone goldens; they are covered by screen tests and goldens at the reference viewport (light). Other sizes and dark mode r… |
| KG-082 | ACCEPT | P3 | Store select: the native `<select>` list cannot be matched in Flutter; the closed state follows the prototype, the open list is a custom popup (same i… |
| KG-083 | UNVERIFIED | P3 | Shell parts without screenshots, built from CSS and code: notifications popover, user menu, store list, toasts, dialog scrim and blur, offline banner,… |
| KG-084 | ACCEPT | P3 | Brand mark "A" and avatar letter use Arial like the prototype; the test environment has no Arial, so goldens draw boxes for them (the "⌘" glyph also f… |
| KG-085 | ACCEPT | P3 | Button press feedback (`translateY(1px)`), global `brightness(.97)` hover and button transitions are not ported; toast slide-in is a simple fade and 1… |
| KG-086 | DONE | P3 | resolved or temporary placeholder note |
| KG-087 | ACCEPT | P3 | Settings toggles use the Material `Checkbox` (not the native checkbox); the full Settings page arrives in S5 |
| KG-088 | ACCEPT | P3 | The shell has no minimum window size (no window manager package); below 1100 px width only the prototype's own media rules apply |
| KG-089 | ACCEPT | P3 | Placeholder POS panel was zero-sized (invisible) until the real-browser screenshot showed it; fixed. Import cycle `app_strings.dart` <-> `en_app_strin… |
| KG-090 | DONE | P3 | resolved or temporary placeholder note |
| KG-091 | QUIRK-KEEP | P3 | Product placeholder art (juice carton and care bottle) uses fixed CSS colors with no dark override: same in both modes (`AppProductArt`). The juice ca… |
| KG-092 | ACCEPT | P3 | Filled stars (favourite, Favourites chip) are a polygon traced from the Lucide path under the outline glyph, not the exact SVG fill |
| KG-093 | ACCEPT | P3 | A focused product card also activates with Space (React: Enter only) |
| KG-094 | UNVERIFIED | P3 | Unverified visually (built from CSS): list view, cards with qty badge, in-cart and hover states, 2-column grid beside the cart (checked against screen… |
| KG-095 | ACCEPT | P3 | Search text is debounced 150 ms (React filters on every keystroke); cards are built lazily so a screenshot-free review is needed for 10k products (S3.… |
| KG-096 | DONE | P3 | resolved or temporary placeholder note |
| KG-097 | DONE | P3 | resolved in S4/S7 |
| KG-098 | QUIRK-DROP | P3 | cart line selects on pointer down |
| KG-099 | UNVERIFIED | P3 | Unverified visually: cart line states (selected, highlight animation, hover on qty buttons and trash, remove state of the minus button), confirm dialo… |
| KG-100 | ACCEPT | P3 | Number inputs allow `0-9 . -` only (React type=number also allows `e`); empty text commits nothing and resets on leaving the field (React resets it on… |
| KG-101 | MUST | P2 | every favourite toggle saves the whole product list (37 ms for 10k): per-row persistence |
| KG-102 | ACCEPT | P3 | Shared widgets built in S3 (`AppChip`, `SegmentedToggle`, `SearchTextField`, `ProductCard`, `ProductImage`, `StarIcon`, `HoldToRepeatButton`, `Quantit… |
| KG-103 | QUIRK-KEEP | P3 | Search focus ring: React draws a rectangular outline on the input inside the field box (as tall as the field content); Flutter now draws the same (DEC… |
| KG-104 | QUIRK-DROP | P3 | cart table header misaligned with stacked lines under 1700 px |
| KG-105 | UNVERIFIED | P3 | S4.0 compared against no React screenshot at 1440 or 1000 px (none exist); stacked line, header, tiles and actions are built from CSS and unverified v… |
| KG-106 | MUST | P1 | stock is whole units, fractional sold quantity rounds up: units of measure |
| KG-107 | QUIRK-DROP | P2 | forex selector changes only the label, one rate, FC twice: real currency table or remove |
| KG-108 | ACCEPT | P3 | Redeemed points are whole numbers; a redeemed amount capped by a total with minor units (for example 21.50) is deducted rounded half-up from the custo… |
| KG-109 | UNVERIFIED | P3 | Member card at height <= 719: the collapsed header and its floating form are approximated with the shared popover (right aligned below the header, wid… |
| KG-110 | UNVERIFIED | P3 | Bill Summary, quick-action tooltips (dark label above the tile; here the shared tooltip), disabled opacities, the rate field underline (solid here, da… |
| KG-111 | ACCEPT | P3 | At small windows the cart heading, the empty-cart chip and the sidebar buttons scale their content down where the prototype wraps (heading) or overflo… |
| KG-112 | DONE | P3 | resolved or temporary placeholder note |
| KG-113 | ACCEPT | P3 | Bill Summary spacing deviates from the React media rules by user approval (DEC-099): minimum gap 8 (CSS 3 to 4 at compact/tight), free height spread u… |
| KG-114 | ACCEPT | P3 | (re-checked in S4.a fix 2: at 950x733 the panel now fits without scrolling) At window heights where the content plus minimum gaps exceeds the panel (f… |
| KG-115 | UNVERIFIED | P3 | Unverified visually: all densities (compact, tight), the collapsed member header, the card terminal, the credit state, the decline checkbox (Material … |
| KG-116 | ACCEPT | P3 | Bill Summary inner padding deviates from the React tight and compact values by user approval (DEC-100): card padding at least 8, label gap at least 4,… |
| KG-117 | ACCEPT | P3 | The "Exchange rate" value sits about 3 px lower than its label in Chrome (the rate `TextField` baseline differs from the prototype's `input`) |
| KG-118 | ACCEPT | P3 | The decline checkbox in the card panel and the other checkboxes are Material checkboxes (blue), not the prototype's native ones (see KG-110) |
| KG-119 | UNVERIFIED | P3 | Row and card heights differ by 1 to 2 px from React in places. Likely cause found in S4.a fix 2: a Flutter `DecoratedBox` border does not take space (… |
| KG-120 | UNVERIFIED | P3 | Unverified visually: the inner padding of every card and the reduced Cash/Card, Complete and quick-tile sizes at compact and tight, checked only by ge… |
| KG-121 | QUIRK-DROP | P2 | flat discount limit is the gross subtotal: cap at the payable amount |
| KG-122 | QUIRK-DROP | P3 | discount tab switch keeps unclamped numbers, emptied field shows 0 |
| KG-123 | QUIRK-DROP | P3 | discount tab switch keeps unclamped numbers, emptied field shows 0 |
| KG-124 | MUST | P0 | a held bill total uses the customer current points and recall does not restore redeemed points: store the totals and points with the bill |
| KG-125 | MUST | P0 | held references can collide in the same millisecond: unique references |
| KG-126 | UNVERIFIED | P3 | Recall dialog, "You have an active cart" question and the Bill discount drawer have no React screenshot: built from the CSS and the code (`.modal`, `.… |
| KG-127 | ACCEPT | P3 | Widget tests draw with the wide test font, so "one line" is not asserted for the dialogs' long texts in the layout matrix (only min width per characte… |
| KG-128 | MUST | P0 | held bills that cannot be restored are dropped silently: tell the cashier what was lost, never lose lines |
| KG-129 | QUIRK-DROP | P3 | digits-only text never opens the dropdown |
| KG-130 | QUIRK-DROP | P3 | scan trims, Price Check does not |
| KG-131 | QUIRK-DROP | P3 | picker search text and Add Customer form kept between openings |
| KG-132 | MUST | P0 | customer id and membership number come from the clock: server or sequence generated, unique |
| KG-133 | ACCEPT | P3 | Arrow-key navigation in the search dropdown and the customer picker is an addition to the prototype (it has none); Enter without arrows is identical t… |
| KG-134 | ACCEPT | P3 | A customer row's title is one line with an ellipsis (React wraps long names); the second line wraps as in CSS |
| KG-135 | UNVERIFIED | P3 | Unverified visually: the results dropdown, the scan simulator, Price Check (found and not found), the customer picker and Add Customer have no React s… |
| KG-136 | UNVERIFIED | P3 | Dark mode, looked at in Chrome at 1280x720 for the S4.b recall dialog and discount drawer and all S4.c surfaces: all text is readable and nothing clip… |
| KG-137 | MUST | P1 | receipt texts and cashier are hard-coded: configuration and real cashier |
| KG-138 | MUST | P0 | Print records the call only; Email/WhatsApp are demo toasts: real print, email, WhatsApp |
| KG-139 | QUIRK-DROP | P3 | Rename counter and note dialogs have no Enter handler, name stored untrimmed |
| KG-140 | ACCEPT | P3 | Reprint and Recall list dates use the app's `dd/mm/yyyy hh:mm:ss`; React uses the browser locale (`toLocaleString()`); the receipt uses the explicit e… |
| KG-141 | ACCEPT | P3 | The receipt, Rename counter, Add note and shortcuts dialogs scroll when the window is shorter than the content; React clips them (`.modal{overflow:hid… |
| KG-142 | QUIRK-DROP | P3 | shortcuts help omits the arrow keys |
| KG-143 | UNVERIFIED | P3 | Unverified visually: the receipt (1 line and long lists), Reprint, Rename counter, Add note, Print draft and the shortcuts help have no React screensh… |
| KG-144 | ACCEPT | P3 | At window heights up to about 740 the receipt (1 line) is taller than the card (`height - 32`): Print, Email, WhatsApp and New Sale sit at the bottom … |
| KG-145 | MUST | P1 | Chrome and full web test suites were dropped: reinstate CI on web and Windows |
| KG-146 | MUST | P1 | tables are read-only (no edit, sort, credit view): maintenance screens |
| KG-147 | QUIRK-KEEP | P3 | The search box of the management pages has no clear button (React has a bare input); the Products and Customers pages scroll as one page (header, sear… |
| KG-148 | UNVERIFIED | P3 | Unverified visually: Products and Customers were compared with the reference screenshots at the reference viewport only (golden `shell_products_light`… |
| KG-149 | ACCEPT | P3 | In a narrow table column the numbers, codes, phones, barcodes and table headers stay on one line and scale down (`FittedBox`), where the browser's aut… |
| KG-150 | MUST | P1 | Today on Reports is hard-wired (no date range, cashier or store filter): reporting module |
| KG-151 | ACCEPT | P3 | Sales table date: React prints `toLocaleString()` (browser locale, e.g. `10/8/2026, 11:16:04 AM` in en-US); the app prints the en-GB form with a comma… |
| KG-152 | UNVERIFIED | P3 | The Sales column shares (206/240/374/267/190/181) were measured from the empty-table screenshot, where React's auto table layout sizes the columns fro… |
| KG-153 | UNVERIFIED | P3 | Unverified visually: the Sales table with rows (Date, Mode, Total, View receipt) and the Reports tiles and bars with data have no React screenshot (Re… |
| KG-154 | UNVERIFIED | P3 | The empty-state texts, the "Sales by payment method" line and the footer are 13 px in the app (measured from the screenshots: text widths 83 to 95 % o… |
| KG-155 | ACCEPT | P3 | The bar width is an integer share in basis points (`ShiftSummary.barBasisPoints`, half up) of the day's total; React uses the float `value / total * 1… |
| KG-156 | ACCEPT | P3 | The Reports tile values (27 px) scale down to fit a narrow tile; React's grid keeps the font and the number overflows or wraps. At 950 px a very large… |
| KG-157 | ACCEPT | P3 | The average bill is the exact `total / count` rounded half up to a minor unit (integer arithmetic, `ShiftSummary.average`); React divides floats and f… |
| KG-158 | QUIRK-KEEP | P3 | Sales and Reports are reached by the sidebar only; the Reports page refreshes when a sale is added and when the local day changes (the clock ticks whi… |
| KG-159 | MUST | P0 | close counter closes nothing: real shift close record with cash reconciliation |
| KG-160 | MUST | P0 | while the counter is closed shortcut handlers still act on the hidden app: block them |
| KG-161 | QUIRK-KEEP | P3 | The Settings page (`/more`) and the Settings dialog show the same two rows (Dark mode, Scan beep) from one widget; React duplicates them through `Sett… |
| KG-162 | MUST | P1 | cashier id, role, avatar, brand hard-coded: user profile |
| KG-163 | UNVERIFIED | P3 | Unverified visually: the Settings page, the Settings, Profile and shift-close dialogs and the "Counter closed" card have no React screenshot; they are… |
| KG-164 | QUIRK-DROP | P3 | Returns lookup is exact bill number only, no list or search |
| KG-165 | MUST | P0 | refund by gross share ignores line discount, bill discount and points: refund what was paid |
| KG-166 | ACCEPT | P3 | precision and rounding-tie decisions (accepted, 1 tie in 300 / 317 vectors) |
| KG-167 | MUST | P1 | stock is whole units and fractional returns round up: decide units of measure |
| KG-168 | ACCEPT | P3 | Dead duplicates removed: `PricingHelpers.clampPoints` (floored the payable amount, unlike React and unlike the live `PricingService`) is deleted; `for… |
| KG-169 | QUIRK-DROP | P3 | Tab order and wrap at the last control |
| KG-170 | UNVERIFIED | P3 | key test passed in real Chrome on 2026-10-09; Edge, Firefox, Safari and laptop Fn-lock still untested |
| KG-171 | UNVERIFIED | P3 | Unverified visually: the Returns page with a matched bill (summary line, return lines, quantity boxes, "Refund & restock"), "No matching bill found.",… |
| KG-172 | ACCEPT | P3 | Customers table: a long email stays on one line cut with an ellipsis and shows in full in a tooltip (React's table would grow wider); every column has… |
| KG-173 | MUST | P2 | no scrollbar gutter on Products: decide whether to show scrollbars |
| KG-174 | DONE | P3 | resolved in S4/S7 |
| KG-175 | MUST | P0 | fonts and CanvasKit are fetched at runtime: bundle fonts and engine for offline start |
| KG-176 | MUST | P1 | POS overflows below 900 px and the Windows window has no minimum size: set a minimum size or add a narrow layout |
| KG-177 | MUST | P1 | 57 of 87 controls are under 44 px on tablets: enlarge hit areas or sizes |

## 3. All decisions (DEC), each once
| Id | Bucket | Prio | Note |
|---|---|---|---|
| DEC-001 | QUIRK-KEEP | P3 | port-as-is policy and the quirks it keeps (revisit with the KG list) |
| DEC-002 | ACCEPT | P3 | Money = integer minor units with per-currency exponent (0/2/3); quantity = integer milli-units; percentages and tax rates = integer basis points; neve… |
| DEC-003 | MUST | P0 | recall guard drops missing lines: keep the guard, add a visible report (KG-128) |
| DEC-004 | ACCEPT | P3 | Pricing internals use `BigInt` rationals because Dart ints on web are JS numbers (exact only to 2^53) and qty x price x bp x bp can exceed that. Publi… |
| DEC-005 | MUST | P1 | F2-F6 fire in inputs and under dialogs (port as-is): decide the rule (KG-014) |
| DEC-007 | ACCEPT | P3 | approved deviations and policies: keep |
| DEC-010 | ACCEPT | P3 | Git repo exists inside `pos_application` only (git init happens in step 1.1). All docs live in `pos_application/docs/`. `CLAUDE.md` stays in `pos_work… |
| DEC-011 | ACCEPT | P3 | One commit per phase step; the agent proposes the message and commits only after the user's OK |
| DEC-012 | ACCEPT | P3 | Plans are saved as `docs/plan_phaseX.md` after approval; `docs/migration_plan.md` is the short master plan; `react_audit.md` replaces re-reading `App.… |
| DEC-013 | ACCEPT | P3 | Phase 1 steps split: 1.1, 1.2, 1.3a, 1.3b, 1.4a (spike), 1.4b, 1.4c, each in its own session |
| DEC-014 | MUST | P2 | Flutter pinned at 3.38.4: plan the upgrade |
| DEC-015 | MUST | P2 | iOS skipped until Phase 4: add iOS/iPad when tablets ship |
| DEC-016 | ACCEPT | P3 | `cupertino_icons` removed from pubspec |
| DEC-020 | MUST | P2 | currency registry seeds: complete per target country |
| DEC-021 | MUST | P2 | tax config: inclusive mode has no React spec: validate with the tax rules per country |
| DEC-022 | MUST | P2 | inclusive-tax spec invented in Phase A: validate with accountants |
| DEC-023 | ACCEPT | P3 | Mock/JSON keeps the prototype's `gst` shape (plain percent number); converted to basis points by decimal-string parsing, not a float multiply. Prices … |
| DEC-024 | ACCEPT | P3 | Forced precision deviation: typed values beyond the integer scale are rounded half-up at the scale on commit (see KG-002/003). Redeem points: whole po… |
| DEC-025 | ACCEPT | P3 | Golden vectors: `tool/golden/gen_vectors.mjs` (outside `reference_react`) transpiles React's unmodified `data.ts` with a one-off `npx --yes esbuild` (… |
| DEC-026 | DONE | P3 | Chrome pricing tests superseded by DEC-104 |
| DEC-030 | ACCEPT | P3 | approved deviations and policies: keep |
| DEC-031 | ACCEPT | P3 | approved deviations and policies: keep |
| DEC-032 | MUST | P0 | Print, Email, WhatsApp, beep stay stubs: implement (KG-018, KG-138) |
| DEC-033 | QUIRK-KEEP | P3 | port-as-is policy and the quirks it keeps (revisit with the KG list) |
| DEC-034 | ACCEPT | P3 | All user-facing strings in `AppStrings`: abstract class, one method per message with named params, values pre-formatted outside, no plural logic (Reac… |
| DEC-040 | ACCEPT | P3 | A module may have several single-responsibility controllers. Shared state (cart, products, customers, held, sales ledger, toasts, search field, overla… |
| DEC-041 | ACCEPT | P3 | Routing: option (i) per-page `AppShell` wrapper with permanent controllers (owning the search `FocusNode`/text), dialogs on the root Navigator overlay… |
| DEC-042 | MUST | P0 | LocalStore (JSON key-value) is the mock: replace with the offline database (KG-028) |
| DEC-043 | DONE | P3 | superseded by DEC-044 |
| DEC-044 | MUST | P0 | Roboto Condensed via google_fonts at runtime: bundle the fonts (KG-175) |
| DEC-050 | ACCEPT | P3 | `get` |
| DEC-051 | ACCEPT | P3 | `lucide_icons_flutter` |
| DEC-052 | ACCEPT | P3 | `shared_preferences` |
| DEC-053 | ACCEPT | P3 | one-off `npx --yes esbuild` |
| DEC-054 | UNVERIFIED | P3 | visual comparison method and viewport decisions: valid only for the 7 screenshots |
| DEC-055 | ACCEPT | P3 | `google_fonts` |
| DEC-060 | UNVERIFIED | P3 | visual comparison method and viewport decisions: valid only for the 7 screenshots |
| DEC-061 | UNVERIFIED | P3 | visual comparison method and viewport decisions: valid only for the 7 screenshots |
| DEC-062 | UNVERIFIED | P3 | visual comparison method and viewport decisions: valid only for the 7 screenshots |
| DEC-063 | UNVERIFIED | P3 | visual comparison method and viewport decisions: valid only for the 7 screenshots |
| DEC-064 | ACCEPT | P3 | Shadows: `AppShadows` keeps each CSS layer as a `ShadowSpec` (dx, dy, blur, spread, color, inset). CSS blur radius maps 1:1 to `BoxShadow.blurRadius`.… |
| DEC-065 | DONE | P3 | temporary swatch page, executed in DEC-078 |
| DEC-066 | UNVERIFIED | P3 | visual comparison method and viewport decisions: valid only for the 7 screenshots |
| DEC-067 | ACCEPT | P3 | Token files: colors (`AppColors`, light + dark `ThemeExtension`, 128 tokens), radii, spacing, sizes (fixed values only), motion, shadows are `const` c… |
| DEC-068 | ACCEPT | P3 | `ThemeData`: Material 3 with a `ColorScheme` mapped from `AppColors`, no ink splash (the prototype has none), `scaffoldBackgroundColor` = background, … |
| DEC-069 | DONE | P3 | replan to 7 steps, done |
| DEC-070 | ACCEPT | P3 | S1.b golden test loads `test/fixtures/pricing_golden_data.g.dart` (generated copy of `pricing_golden.json`, written by the same script) so it runs on … |
| DEC-071 | QUIRK-KEEP | P3 | port-as-is policy and the quirks it keeps (revisit with the KG list) |
| DEC-072 | QUIRK-KEEP | P3 | port-as-is policy and the quirks it keeps (revisit with the KG list) |
| DEC-073 | ACCEPT | P3 | S2 answers (plan approved 2026-10-08): `flutter_web_plugins` SDK entry added for path URLs; shortcut chip "⌘K" on macOS and "Ctrl+K" elsewhere; Bill S… |
| DEC-074 | ACCEPT | P3 | S2.a: permanent controllers in `InitialBinding` (idempotent): Settings, Toast (last 4, 5 s), SearchField (FocusNode + text, 40 ms `refocus()`), PageFi… |
| DEC-075 | ACCEPT | P3 | `AppStrings` is an abstract class with `AppStrings.current` (English implementation `EnAppStrings`); views read it through `context.strings`. A VM-onl… |
| DEC-076 | ACCEPT | P3 | S2.b/c: top bar, sidebar, banner, summary frame, toast host and dialog host built from CSS (`css_metrics.md`) plus the React JSX. Profile gap 8 and pa… |
| DEC-077 | ACCEPT | P3 | S2.d shortcuts: `Shortcuts`/`Actions` above the Navigator with a fallback `Focus`. Ctrl+K and Cmd+K focus search (also inside the field on macOS, veri… |
| DEC-078 | DONE | P3 | executed |
| DEC-079 | DONE | P3 | web startup crash fixed |
| DEC-080 | DONE | P3 | Chrome test hang explained |
| DEC-081 | ACCEPT | P3 | S3.a data layer. JSON shapes keep the prototype's fields with integer scales: `Product.priceMinor`, `gst` as the plain percent number (parsed by decim… |
| DEC-082 | ACCEPT | P3 | S3 controllers: `ProductsController` (id/barcode/code maps, lowercase "name code" search keys), `CustomersController`, `CartController` (reducer rules… |
| DEC-083 | ACCEPT | P3 | S3.b catalog. `CatalogController` is registered by `PosBinding` once and kept (`Get.put(..., permanent: true)`, not `Get.lazyPut`): in the prototype c… |
| DEC-084 | UNVERIFIED | P3 | visual comparison method and viewport decisions: valid only for the 7 screenshots |
| DEC-085 | ACCEPT | P3 | Icons added to `AppIcons` for S3: star, cupSoda, cookie, bottleWine, chevronRight, layoutGrid, list, plus, minus (S3.b) and trash2, pauseCircle, rotat… |
| DEC-086 | ACCEPT | P3 | S3.c cart panel (single-row layout, widths above 1700): `CenterColumn` = cart panel over stat tiles. Table head and lines use `20 |
| DEC-087 | ACCEPT | P3 | Inputs ported from `QuantityInput` and the number inputs: quantity shows 3 decimals, every positive valid edit is committed at once through `CartActio… |
| DEC-088 | ACCEPT | P3 | Confirm dialog: `OverlayController.openConfirm(text, onConfirm)` opens the id `confirm`; `ConfirmDialog` ("Confirm action", Cancel, Confirm) reproduce… |
| DEC-089 | ACCEPT | P3 | S3.d performance with 10,000 products (VM, this Mac; Chrome in brackets): decode and index the list 60 ms; catalog init (entries + first filter) 4.5-6… |
| DEC-090 | ACCEPT | P3 | `tool/web_check/` (Node script + SPA server, no packages) drives the served release build in headless Chrome with clicks and screenshots, so checkpoin… |
| DEC-091 | ACCEPT | P3 | S4.0 narrow-window cart. The cart line has two layouts chosen by `AppMetrics.cartLineLayout`: single (width > 1700, unchanged) and stacked (<= 1700): … |
| DEC-092 | ACCEPT | P3 | The table header keeps its own columns at <= 1700 (`18 1.4fr 1.3fr .8fr .8fr 1fr 0`, gap 4) while the lines are stacked: in React they do not line up … |
| DEC-093 | ACCEPT | P3 | Density metrics for S4.a only (no panel yet): `SummaryMetrics.of(density, ClampRule)` holds the cascade-resolved Bill Summary sizes for normal, compac… |
| DEC-094 | ACCEPT | P3 | approved deviations and policies: keep |
| DEC-095 | ACCEPT | P3 | S4 controllers (supersedes the DEC-040 wording that put payment state in the route binding): the Bill Summary and F2-F6 exist on every page, so `Payme… |
| DEC-096 | ACCEPT | P3 | Checkout rules ported as-is: card terminal timer is an effect over (mode, active cart, terminal, decline), so ticking "Simulate Decline" while Waiting… |
| DEC-097 | ACCEPT | P3 | Bill Summary layout: top group (title, totals, forex, member) and bottom group (checkout section, quick actions) are pushed apart (`margin-top:auto`) … |
| DEC-098 | ACCEPT | P3 | Icons added to `AppIcons` in S4.a: banknote, creditCard, percent, printer, power, clock, mail, smartphone (mail and smartphone are for the S4.d receip… |
| DEC-099 | ACCEPT | P3 | approved deviations and policies: keep |
| DEC-100 | ACCEPT | P3 | approved deviations and policies: keep |
| DEC-101 | ACCEPT | P3 | S4.b structure. `DialogRegistry` (shell) maps a dialog id to its widget; ids without an entry keep the placeholder. A dialog lays itself out with `App… |
| DEC-102 | ACCEPT | P3 | S4.c structure. Plain-Dart `ProductSearch` (digits-only text is a barcode, first 6 matches in list order, lazy scan that stops at the sixth) and `Cust… |
| DEC-103 | ACCEPT | P3 | S4.d structure. Receipt: plain-Dart `ReceiptDocument` and `ReceiptBuilder.fromSale` (stored `SaleTotals`, change and mode are copied, only the line to… |
| DEC-104 | MUST | P1 | Chrome tests dropped from the routine: reinstate CI (KG-145) |
| DEC-105 | ACCEPT | P3 | S5 structure. Checks from S5 on follow DEC-104 plus the smaller layout sweep (widths 900/1100/1280/1500/1900 x heights 600/733/900/1000; the full swee… |
| DEC-106 | ACCEPT | P3 | S5.b structure. Plain-Dart `ShiftSummary` (`modules/shift/services`): `dailySales` by local calendar day, total, count, exact half-up average, per-mod… |
| DEC-107 | ACCEPT | P3 | approved deviations and policies: keep |
| DEC-108 | ACCEPT | P3 | S6 structure. Returns: `RefundService` (plain Dart: find, checks in the prototype's order, amount through the single `PricingHelpers.refund`, applied … |
