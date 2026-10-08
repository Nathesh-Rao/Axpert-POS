# css_metrics.md: cascade-resolved tokens and metrics (step 1.2)

Source of truth: `reference_react/src/index.css` (read in full), resolved in file block order (later rule wins at equal specificity, including across media blocks; `!important` and higher specificity win regardless of order). Values are the EFFECTIVE values at the reference viewport (section 1), where no media query applies.

Tables marked `<!-- table:... -->` are parsed by `test/core/theme/css_metrics_test.dart` and compared with the Dart tokens, so the code and this document cannot drift apart. Colors: CSS `#rrggbb`, or `#rrggbbaa` (alpha last, CSS order).

## 1. Scale and reference viewport (measured)

Measured with a stdlib PNG reader on `Screenshot ... 4.56.50 PM.png` (POS, empty cart) at exact pixel boundaries. The page is surrounded by a dark window frame: left 10 px, right 12 px, top 8 px, bottom 8 px; the page area is x 10..2111, y 8..1171 (2102 x 1164 px).

| Element | CSS value (resolved) | Measured px | Ratio |
|---|---|---|---|
| Top bar (border included, box-sizing border-box) | 64 (`--topbar-height`) | 72 (y 8..79) | 1.125 |
| Sidebar column + layout gap to first card | 80 + 16 = 96 | 108 (x 10..117) | 1.125 |
| Gap between panels | 16 | 18 (x 1650..1667) | 1.125 |
| Bottom page padding | 16 | 18 (y 1154..1171) | 1.125 |
| Right page padding | 16 | 18 (x 2094..2111) | 1.125 |
| Summary panel (POS, saturated clamp) | 380 | 426 | 1.121 (edge anti-aliasing) |
| Summary panel (Products page, `.alternate-main`) | 310 | 348 | 1.123 |

**Scale = 1.125 image pixels per CSS px (9/8).** DEC-062 corrected (was "about 1.11").

- CSS viewport = page area / 1.125 = **2102/1.125 x 1164/1.125 = 1868.44 x 1034.67 CSS px** (about 1868 x 1035). The whole screenshot (frame included) would be 1888 x 1049.
- Cross-check: catalog width measured 1532 px (x 118..1649) vs predicted (1868.44 - 96 - 16 - 380 - 16) x 1.125 = 1530.5 px.
- Media queries at 1868 x 1035: width <= 1700 no, <= 1280 no, <= 1100 no, height <= 960 no, <= 820 no, <= 719 no. Only base rules apply (DEC-060 confirmed).
- Golden harness: physical size 2102 x 1164, devicePixelRatio 1.125, logical size 1868.44 x 1034.67 (fractional on purpose, DEC-066). A golden then equals the screenshot crop at offset (10, 8), size 2102 x 1164.
- `vw` = 18.684 px and `vh` = 10.347 px at this viewport. Fluid clamps that are NOT saturated here are marked "fluid" in section 10; if the real window differs by even a few px those values move by that fraction.

## 2. Cascade order (block order in the file)

line 5 (minified base) -> `@media screen` (line 8) -> `<=1280` (171) -> `<=1100` (190) -> `<=height 820` (206) -> `@media screen` (236, overrides several base and earlier-screen values) -> `<=1700` (342) -> `<=1100` (364) -> `<=height 960` (377) -> `<=height 820` (401) -> `<=height 719` (426) -> print (433). The `prefers-reduced-motion` block (line 7) disables animation/transition on `.main, .center-column, .toast, .modal`.

### Dead and overridden rules (do NOT port these values)

| Rule | Why it is dead / what wins |
|---|---|
| `.topbar{height:70px; padding 0 22px; gap 17px}` (line 5) | line 10/12: height `--topbar-height` = 64, padding/gap are clamps |
| `.sidebar{width:84px}`, `.sidebar button{width:73px; min-height:75px}` | screen block: width 100% of an 80 px column, button height `clamp(48,8vh,76)` |
| `.workspace{padding:11px 12px 18px 0; gap:14px}`, `.main{310px}` | screen block: grid, padding/gap `--layout-gap` = 16 (line 237) |
| `--radius:11px` (line 5) | line 237 sets 14 |
| `.catalog{padding:12px}`, `.cart-panel{padding:15px 14px 12px}` | line 238: 16 |
| `.cart-line` base look (secondary bg, 7px radius, margin 7) | line 236 block: card bg, 1px border, 12px radius, shadow, margin-bottom 12 |
| `.dark .cart-line.selected-line{background:#283a55}` (line 5) | later `#273c58` (line 337) wins |
| `.line-product img{display:none}` at `<=1280` | later base `display:block` at line 236 wins |
| `.payment-buttons button` base border/box-shadow, `[aria-pressed=true]{outline:2px solid #94bdfa}` | line 236: border `1.5px solid transparent`, shadow none, pressed = `outline:none` + `box-shadow: 0 3px 8px #125eae20, inset 0 1px 1px #ffffff40`; so `#94bdfa` is never visible |
| `.catalog-footer` | `display:none` in the screen block: the footer (and `.tiny-dot`) is never shown |
| `.summary-foot`, `.summary-toggle` | `display:none` in the screen block |
| `.app{min-height:650px}` | screen block sets `min-height:0` |
| `.product-grid{repeat(6,...)}` / `.has-cart{repeat(4,...)}` | screen block: `repeat(auto-fill, minmax(clamp(130,11vw,170), 1fr))`; only `<=1280` forces 2 columns (higher specificity) |

### Dark-mode specificity quirks (replicate, do not "fix")

- `.quick-actions .action.red:hover` etc. (specificity 0,4,0) beat `.dark .action.red`, so hover backgrounds are the LIGHT hover colors in dark too. `.dark .quick-actions .action:hover{filter:brightness(1.2)}` still applies on top.
- `.dark .qty-control button` and `.dark .inline-payment .quick-amounts button` have the same specificity as their `:hover` rules and come later, so in dark the hover background equals the normal dark background (only `color` hover and the global `brightness(.97)` apply). `.remove-quantity` (0,3,1) stays light in dark.
- `.dark .cart-line` background = card (same rule as light after line 236: card).

## 3. Colors, light (`:root` + rules, resolved)

<!-- table:colors-light -->
| Token | CSS value | Source rule |
|---|---|---|
| `background` | `#eff4f9` | :root / .dark |
| `card` | `#ffffff` | :root / .dark |
| `secondary` | `#f3f6fa` | :root / .dark |
| `text` | `#102047` | :root / .dark |
| `muted` | `#7585a4` | :root / .dark |
| `border` | `#e4ebf4` | :root / .dark |
| `blue` | `#0061ff` | :root --blue |
| `white` | `#ffffff` | literal #fff / white |
| `summaryRowText` | `#526584` | .summary-rows>div, .membership>label; .dark rule -> muted |
| `labelText` | `#526584` | .customer-label |
| `placeholder` | `#8a99b4` | input::placeholder |
| `globalSearchFg` | `#536584` | .global-search color |
| `fieldIcon` | `#506483` | .field svg |
| `searchFieldFg` | `#526581` | .search-field |
| `focusRing` | `#78aaff` | input:focus / button:focus-visible outline |
| `primary` | `#0968ee` | .primary |
| `primaryGreen` | `#049667` | .primary.green |
| `actionBlueBg` | `#edf5ff` | .action; .dark .action.blue |
| `actionBlueFg` | `#0060ff` | .action |
| `actionBlueHover` | `#dbeaff` | .quick-actions .action.blue:hover (same in dark: higher specificity) |
| `actionRedBg` | `#fff0f3` | .action.red; .dark .action.red |
| `actionRedFg` | `#ff2036` | .action.red |
| `actionRedHover` | `#ffe1e8` | .quick-actions .action.red:hover |
| `actionPurpleBg` | `#f1edff` | .action.purple; .dark .action.purple |
| `actionPurpleFg` | `#7a20ff` | .action.purple |
| `actionPurpleHover` | `#e6dcff` | .quick-actions .action.purple:hover |
| `actionOrangeBg` | `#fff6eb` | .action.orange; .dark .action.orange |
| `actionOrangeFg` | `#db7900` | .action.orange |
| `actionOrangeHover` | `#ffecd1` | .quick-actions .action.orange:hover |
| `actionNeutralBg` | `#eff0f3` | .action.neutral; .dark .action.neutral |
| `actionNeutralFg` | `#14203b` | .action.neutral; .dark .action.neutral color text |
| `actionNeutralHover` | `#dfe4ed` | .quick-actions .action.neutral:hover |
| `actionHoverRing` | `#729bd433` | .quick-actions .action:hover inset ring (CSS #rrggbbaa) |
| `smallBadge` | `#743df2` | .small-badge |
| `discountDot` | `#f02b4a` | .discount-dot |
| `clearHoldClock` | `#fff0f3` | .clear-hold-clock |
| `invoiceBg` | `#edf5ff` | .invoice; .dark .invoice |
| `invoiceFg` | `#005cff` | .invoice |
| `applyDiscountBg` | `#edf5ff` | .apply-discount; .dark .apply-discount |
| `payCashTop` | `#2caa78` | .pay-cash gradient |
| `payCashBottom` | `#05945d` | .pay-cash gradient |
| `payCashIdleFg` | `#078b5c` | .pay-cash[aria-pressed=false] |
| `payCashIdleBorder` | `#acd9c7` | .pay-cash[aria-pressed=false] |
| `payCardTop` | `#4796ff` | .pay-card gradient |
| `payCardBottom` | `#0860ef` | .pay-card gradient |
| `payCardIdleFg` | `#166ee3` | .pay-card[aria-pressed=false] |
| `payCardIdleBorder` | `#b1cdf4` | .pay-card[aria-pressed=false] |
| `completeDisabledBg` | `#dbe7e3` | .complete-payment:disabled |
| `completeDisabledFg` | `#71847d` | .complete-payment:disabled |
| `completeDisabledBorder` | `#ccdbd5` | .complete-payment:disabled |
| `quickAmountBg` | `#f0f6ff` | .inline-payment .quick-amounts button; .dark rule |
| `quickAmountHover` | `#d9eaff` | hover; in dark the later .dark rule wins (same specificity), so no hover change |
| `changeDueGreen` | `#03965d` | .change-due b |
| `shortChangeRed` | `#d92f4a` | .change-due.short-payment b |
| `terminalApproved` | `#079567` | .inline-terminal.approved |
| `terminalDeclined` | `#df354d` | .inline-terminal.declined |
| `terminalDeclinedModal` | `#ec354d` | .terminal.declined (modal) |
| `terminalApprovedModal` | `#079567` | .terminal.approved (modal) |
| `selectedLineBg` | `#f0f6ff` | .cart-line.selected-line (line 236); .dark = #273c58 (line 337 beats #283a55 on line 5) |
| `selectedLineBorder` | `#adcbf5` | .cart-line.selected-line |
| `qtyButtonBg` | `#edf2f8` | .qty-control button; .dark rule |
| `qtyButtonFg` | `#38567f` | .qty-control button |
| `qtyButtonHoverBg` | `#dbeaff` | hover; in dark the .dark rule wins (same specificity) |
| `qtyButtonHoverFg` | `#0061ee` | .qty-control button:hover |
| `qtyRemoveBg` | `#ffedf1` | .remove-quantity (higher specificity, same in dark) |
| `qtyRemoveFg` | `#e62d49` | .remove-quantity |
| `qtyRing` | `#dbe5f3` | .qty-control inset ring |
| `trashFg` | `#ff263c` | .trash |
| `trashBg` | `#fff0f3` | .cart-line .trash |
| `trashHoverBg` | `#ffe0e8` | .cart-line .trash:hover |
| `lineEditBorder` | `#dce5f2` | .line-edit input; .dark -> var(--border) |
| `qtyBadgeBg` | `#e8f2ff` | .qty-badge |
| `qtyBadgeFg` | `#0063ff` | .qty-badge |
| `highlightBg` | `#dcf0ff` | @keyframes highlight 0-35% |
| `highlightBorder` | `#69b1ff` | @keyframes highlight 0-35% |
| `sidebarActiveTop` | `#dfeaff` | .sidebar button.active gradient |
| `sidebarActiveBottom` | `#e8f3ff` | .sidebar button.active gradient |
| `sidebarHover` | `#dfeaff77` | .sidebar button:hover (CSS #rrggbbaa) |
| `onlineDot` | `#05a76c` | .online i |
| `offlineDot` | `#edab24` | .online i.offline-dot |
| `notificationDot` | `#ff293e` | .notification-dot |
| `avatarBg` | `#657793` | .avatar |
| `avatarBorder` | `#edf4ff` | .avatar |
| `brandMark` | `#0d63bb` | .brand-mark |
| `brandMarkShadow` | `#b6d6ff` | .brand-mark text-shadow |
| `offlineBannerBg` | `#fff1c8` | .offline-banner |
| `offlineBannerFg` | `#8d5c00` | .offline-banner |
| `categoryStar` | `#f3a400` | .categories button:nth-child(2) svg |
| `categoryIcon3` | `#502299` | .categories button:nth-child(3) svg |
| `categoryIcon4` | `#b87516` | .categories button:nth-child(4) svg |
| `categoryIcon5` | `#673bc7` | .categories button:nth-child(5) svg |
| `categorySelectedTop` | `#4b98ff` | .categories button.selected gradient |
| `categorySelectedBottom` | `#2e7cf7` | .categories button.selected gradient |
| `selectedTabBg` | `#e4efff` | .subcategories .selected, .view-toggle .selected |
| `viewToggleFg` | `#45658f` | .view-toggle button |
| `productHoverBorder` | `#95baff` | .product-card:hover |
| `productInCartBorder` | `#abcaff` | .product-card.in-cart |
| `productStepperBg` | `#eaf3ff` | .product-stepper button |
| `favouriteFg` | `#92a3bf` | .favourite |
| `favouriteActive` | `#e5ae24` | .is-favourite |
| `favouriteFill` | `#f9cb45` | .is-favourite svg fill |
| `scrollThumb` | `#dbe4f1` | .product-grid / .cart-table scrollbar-color |
| `scrollThumbCart` | `#c5d5ec` | .cart-table-body scrollbar-color |
| `stockOkBg` | `#e2f6ed` | .stock-ok |
| `stockOkFg` | `#078255` | .stock-ok |
| `stockLowBg` | `#fff0d8` | .stock-low |
| `stockLowFg` | `#b76b02` | .stock-low |
| `greenIcon` | `#019354` | .green-icon |
| `saleToggleIdleFg` | `#647694` | .sale-toggle button |
| `radioBorder` | `#94a4be` | .radio |
| `cashChosenFg` | `#00824c` | .sale-toggle .chosen.cash-choice |
| `cashChosenBg` | `#e2f5ed` | .sale-toggle .chosen.cash-choice |
| `creditChosenFg` | `#1665db` | .sale-toggle .chosen:not(.cash-choice) |
| `creditChosenBg` | `#e4efff` | .sale-toggle .chosen:not(.cash-choice) |
| `validation` | `#ce6d09` | .validation |
| `toastSuccess` | `#13a274` | .toast border-left |
| `toastSuccessIcon` | `#08a575` | .toast>svg |
| `toastError` | `#ef3548` | .toast.error |
| `toastWarning` | `#edab24` | .toast.warning |
| `toastInfo` | `#3c8cff` | .toast.info |
| `tooltipBg` | `#142746` | .action-tooltip |
| `modalOverlay` | `#10213b55` | .modal-overlay (CSS #rrggbbaa; blur 4px) |
| `modalSymbolBg` | `#e8f2ff` | .modal-symbol |
| `modalSymbolGreenBg` | `#e5f7ee` | .modal-symbol.green |
| `modalSymbolGreenFg` | `#06986a` | .modal-symbol.green |
| `spinnerTrack` | `#deebff` | .spinner |
| `chartTop` | `#479bff` | .chart-track>div gradient |
| `chartBottom` | `#0870ed` | .chart-track>div gradient |

Gradients are composed in widgets from these tokens: top bar `linear-gradient(110deg, background, card, background)`, fields `linear-gradient(120deg, secondary, card)`, stat tiles `linear-gradient(130deg, secondary, background)`, pay buttons top to bottom, sidebar active `120deg`, categories selected `135deg`.

## 4. Colors, dark (the 13 `.dark` rules, resolved) - UNVERIFIED VISUALLY

Only these tokens differ from light; everything else is identical in dark (DEC-031, `known_gaps.md` section C). No screenshot of dark mode exists.

<!-- table:colors-dark -->
| Token | CSS value | Source rule |
|---|---|---|
| `background` | `#162134` | :root / .dark |
| `card` | `#1d2b41` | :root / .dark |
| `secondary` | `#26344a` | :root / .dark |
| `text` | `#e4ecfa` | :root / .dark |
| `muted` | `#a4b4ce` | :root / .dark |
| `border` | `#35445e` | :root / .dark |
| `summaryRowText` | `#a4b4ce` | .summary-rows>div, .membership>label; .dark rule -> muted |
| `actionBlueBg` | `#233b60` | .action; .dark .action.blue |
| `actionRedBg` | `#492838` | .action.red; .dark .action.red |
| `actionPurpleBg` | `#362c59` | .action.purple; .dark .action.purple |
| `actionOrangeBg` | `#493822` | .action.orange; .dark .action.orange |
| `actionNeutralBg` | `#303b4e` | .action.neutral; .dark .action.neutral |
| `actionNeutralFg` | `#e4ecfa` | .action.neutral; .dark .action.neutral color text |
| `invoiceBg` | `#233b60` | .invoice; .dark .invoice |
| `applyDiscountBg` | `#233b60` | .apply-discount; .dark .apply-discount |
| `quickAmountBg` | `#2d4260` | .inline-payment .quick-amounts button; .dark rule |
| `quickAmountHover` | `#2d4260` | hover; in dark the later .dark rule wins (same specificity), so no hover change |
| `selectedLineBg` | `#273c58` | .cart-line.selected-line (line 236); .dark = #273c58 (line 337 beats #283a55 on line 5) |
| `qtyButtonBg` | `#2d4260` | .qty-control button; .dark rule |
| `qtyButtonHoverBg` | `#2d4260` | hover; in dark the .dark rule wins (same specificity) |
| `lineEditBorder` | `#35445e` | .line-edit input; .dark -> var(--border) |

Mode behaviours (not colors): `productImageMultiply` light = true / dark = false (`mix-blend-mode`), `productImageRadius` light = 0 / dark = 4 (`.dark .product-image img`), `quickActionHoverBrightness` light = 1 (`filter:none`) / dark = 1.2.

## 5. Typography

Family Roboto Condensed (400/500/600/700, `font-synthesis:none`). Root `font-size:14px`; `:root` is `clamp(11px,.85vw,14px)` on screens, which resolves to 14 at the reference viewport. Weights follow the UA defaults (`b`, `strong`, `h1`-`h3` bold = 700) plus explicit 500/600 in rules. Sizes in `AppFontSize` are all px sizes that appear after the cascade at the reference viewport; fluid ones are rounded to the nearest listed size only when the raw value is within 0.5 px, otherwise the nearest `clamp` result is kept in section 10 for AppMetrics (1.4b).

| Role (resolved) | Size | Weight | Source |
|---|---|---|---|
| Brand name | 26 | 700, tracking -0.6 | `.brand strong` (clamp saturated) |
| Management page title `h1` | 30 | 700 | `.management h1` |
| Modal title `h2` | 25 | 700 | `.modal h2` |
| Cart title, summary title | 22 | 700 | `.cart-heading h2`, `.bill-summary h2` (clamps saturated) |
| Default `h2` | 20 | 700 | `h2` |
| Invoice total | 25.87 (fluid vh) | 700, tracking -0.5 | `.invoice b` (236) |
| Payment amount (drawer) | 38 | 700 | `.payment-amount` |
| Price result `h1` | 36 | 700 | `.price-result h1` |
| Body / buttons / inputs | 14 | 400 | `:root` |
| Field and tab text | 14 | 400 | `.field input`, `.categories button` (236 clamp saturated at 14) |
| Summary rows label / value | 13 / 16 | 400 / 700 | `.summary-rows>div` (236) |
| Small text | 12 | 400, muted | `small` |
| Captions, badges | 9-11 | 400-700 | `.catalog-caption` 9 (screen block), `.qty-badge` 11 |

### Tracking (parsed)

<!-- table:tracking -->
| Token | Value | Source |
|---|---|---|
| `brand` | -0.6 | .brand strong letter-spacing |
| `catalogCaption` | 1.1 | .catalog-caption |
| `managementEyebrow` | 1.2 | .management-heading p |
| `invoiceTotal` | -0.5 | .invoice b |
| `receiptBrand` | 3 | .receipt-brand |

Line heights: summary title 1.1 (`.bill-summary h2`), cart line name 1.3 (`.line-product>span`), line small text 1.2, modal paragraph 1.5.

## 6. Radii (parsed)

<!-- table:radii -->
| Token | Value | Source |
|---|---|---|
| `r4` | 4 | .qty-control 4px, .global-search kbd |
| `r5` | 5 | .product-image, .qty-badge, .chart-track |
| `r6` | 6 | .membership input (base), .popover button |
| `r7` | 7 | .customer-chip, .field (base), .categories button |
| `r8` | 8 | .action, .primary, .secondary, .segmented (most used) |
| `r9` | 9 | .global-search, .product-card, .search-results |
| `r10` | 10 | .popover, payment buttons (236), .invoice (236), .complete-payment |
| `r11` | 11 | .stat-tiles; `--radius` base (dead: 236 sets 14) |
| `r12` | 12 | .cart-line (236), quick-action tiles (236) |
| `r14` | 14 | .panel, .summary-card, `--radius` (236), .modal-symbol |
| `r16` | 16 | .modal, .sign-card, .drawer (left corners) |
| `r22` | 22 | .sale-toggle pills, .qty-control (236) |
| `full` | 9999 | border-radius:50% (circles: avatar, dots, badges, trash, qty buttons) |

## 7. Spacing (parsed)

The prototype has no spacing scale: ad hoc px and `clamp()`. `panelPad` and `layoutGap` are 16 (line 237 overrides the clamps).

<!-- table:spacing -->
| Token | Value | Source |
|---|---|---|
| `s2` | 2 | px values used by padding/margin/gap in index.css |
| `s3` | 3 | px values used by padding/margin/gap in index.css |
| `s4` | 4 | px values used by padding/margin/gap in index.css |
| `s5` | 5 | px values used by padding/margin/gap in index.css |
| `s6` | 6 | px values used by padding/margin/gap in index.css |
| `s7` | 7 | px values used by padding/margin/gap in index.css |
| `s8` | 8 | px values used by padding/margin/gap in index.css |
| `s9` | 9 | px values used by padding/margin/gap in index.css |
| `s10` | 10 | px values used by padding/margin/gap in index.css |
| `s11` | 11 | px values used by padding/margin/gap in index.css |
| `s12` | 12 | px values used by padding/margin/gap in index.css |
| `s13` | 13 | px values used by padding/margin/gap in index.css |
| `s14` | 14 | px values used by padding/margin/gap in index.css |
| `s15` | 15 | px values used by padding/margin/gap in index.css |
| `s16` | 16 | px values used by padding/margin/gap in index.css |
| `s17` | 17 | px values used by padding/margin/gap in index.css |
| `s18` | 18 | px values used by padding/margin/gap in index.css |
| `s19` | 19 | px values used by padding/margin/gap in index.css |
| `s20` | 20 | px values used by padding/margin/gap in index.css |
| `s21` | 21 | px values used by padding/margin/gap in index.css |
| `s22` | 22 | px values used by padding/margin/gap in index.css |
| `s23` | 23 | px values used by padding/margin/gap in index.css |
| `s24` | 24 | px values used by padding/margin/gap in index.css |
| `s25` | 25 | px values used by padding/margin/gap in index.css |
| `s27` | 27 | px values used by padding/margin/gap in index.css |
| `s28` | 28 | px values used by padding/margin/gap in index.css |
| `s30` | 30 | px values used by padding/margin/gap in index.css |
| `s32` | 32 | px values used by padding/margin/gap in index.css |
| `panelPad` | 16 | --panel-pad (236 overrides the clamp) |
| `layoutGap` | 16 | --layout-gap (236 overrides the clamp) |

## 8. Fixed sizes (parsed) and shadows (parsed)

Fixed sizes only; fluid `clamp(vw/vh)` sizes are in section 10 (AppMetrics, step 1.4b). KG-029 CONFIRMED: `.alternate-main{grid-template-columns:minmax(0,1fr) 310px!important}` (line 5) beats `.main.alternate-main{... var(--summary-width)}` (screen block), so the Bill Summary is 310 CSS px on every non-POS page (348 px measured) and 380 on POS (426 px measured). Documented in `known_gaps.md` KG-029.

<!-- table:sizes -->
| Token | Value | Source |
|---|---|---|
| `topbarHeight` | 64 | --topbar-height (56 at <=1280) |
| `sidebarWidth` | 80 | --sidebar-width (64 at <=1280) |
| `summaryWidthMax` | 380 | --summary-width clamp(300px,24vw,380px) max; saturated at the reference viewport |
| `summaryWidthMin` | 300 | --summary-width clamp min |
| `summaryWidthAlternate` | 310 | .alternate-main !important (KG-029): non-POS pages |
| `modalWidth` | 460 | .modal |
| `receiptModalWidth` | 530 | .receipt-modal |
| `drawerWidth` | 390 | .drawer |
| `toastMinWidth` | 290 | .toast |
| `popoverMinWidth` | 170 | .popover |
| `notificationsMinWidth` | 290 | .notifications |
| `controlMinHeight` | 43 | .primary, .secondary |
| `modalInputHeight` | 46 | .modal-input |
| `qtyControlWidth` | 144 | .qty-control (236) |
| `qtyControlHeight` | 40 | .qty-control (236) |
| `qtyButtonSize` | 40 | .qty-control button (236) |
| `qtyInputWidth` | 64 | .qty-control input (236) |
| `lineEditWidth` | 76 | .line-edit |
| `lineEditHeight` | 36 | .line-edit input (236) |
| `trashSize` | 40 | .cart-line .trash (236) |
| `cartActionHeight` | 44 | .cart-actions .action (236) |
| `quickActionMin` | 44 | .quick-actions .action min size (236) |
| `quickActionIcon` | 22 | .quick-actions .action>svg (236) |
| `paymentIcon` | 26 | .payment-buttons svg (236) |
| `completePaymentHeight` | 48 | .complete-payment (236; 36/34 at height<=960/820) |
| `inlineTenderedHeight` | 44 | .inline-tendered (236; 34/32 at height<=960/820) |
| `quickAmountHeight` | 36 | .inline-payment .quick-amounts button (236) |
| `inlineTerminalHeight` | 90 | .inline-terminal (236) |
| `inlineDeclineHeight` | 54 | .inline-decline (236) |
| `currencyRowHeight` | 40 | .currency-row>div (236) |
| `membershipFieldHeight` | 38 | .membership input/.field (236) |
| `rateLabelHeight` | 14 | .rate-label (236) |
| `billSummaryTitleHeight` | 24 | .bill-summary h2 (236) |
| `cartLineImage` | 48 | .line-product img (236) |
| `cartLineCheckbox` | 20 | cart-line first grid column (236) |
| `cartQtyColumn` | 144 | cart grid column 3 (236) |
| `cartPriceColumn` | 76 | cart grid column 4 (236) |
| `cartDiscountColumn` | 76 | cart grid column 5 (236) |
| `cartTotalMinColumn` | 80 | cart grid column 6 minmax(80px,.8fr) |
| `cartTrashColumn` | 40 | cart grid column 7 (236) |
| `cartLineGap` | 8 | cart-line grid gap (236) |
| `cartLineMargin` | 12 | .cart-line margin-bottom (236) |
| `borderWidth` | 1 | 1px solid var(--border) everywhere |
| `focusRingWidth` | 2 | input:focus outline |
| `focusRingOffset` | 2 | input:focus outline-offset |
| `onlineDot` | 10 | .online i |
| `tinyDot` | 6 | .catalog-footer .tiny-dot (dead: footer hidden) |
| `notificationDot` | 13 | .notification-dot |
| `discountDot` | 8 | .discount-dot (236) |
| `smallBadgeQuick` | 19 | .quick-actions .small-badge (236) |
| `productStepperBase` | 30 | .product-stepper button max |
| `searchResultsTop` | 48 | .search-results top |
| `popoverOffset` | 12 | .popover top: calc(100% + 12px) |
| `toastBottom` | 23 | .toast-stack bottom |
| `modalOverlayPad` | 25 | .modal-overlay padding max |
| `modalPad` | 32 | .modal padding max |
| `modalSymbol` | 57 | .modal-symbol |
| `modalBlur` | 4 | .modal-overlay backdrop-filter blur |
| `appMinHeight` | 650 | .app min-height (dead: 236 screen block sets 0) |

Shadows. CSS blur radius maps to `BoxShadow.blurRadius`; Flutter converts it to a Gaussian sigma of blur/2 itself (the CSS and Flutter definitions coincide). Flutter cannot draw `inset` shadows: inset layers are kept as data and drawn by widgets (DEC-064). The payment-button base shadows (`inset 0 2px 8px #ffffff40, 0 3px 6px #114c9510`) are dead (line 236 sets `box-shadow:none`).

<!-- table:shadows -->
| Token | dx dy blur spread #color [inset] | Source |
|---|---|---|
| `panel` | 0 2 16 0 #bdcde00a | .panel |
| `modal` | 0 25 80 0 #0d203844 | .modal |
| `popover` | 0 12 40 0 #10204720 | .popover |
| `searchResults` | 0 10 30 0 #12294b20 | .search-results |
| `toast` | 0 6 30 0 #17294a25 | .toast |
| `memberPanel` | 0 8 32 0 #10204730 | .member-card.member-open .membership (height<=719) |
| `productHover` | 0 4 15 0 #276ed810 | .product-card:hover |
| `summaryCard` | 0 2 9 0 #193b6710 | .summary-card |
| `cartLine` | 0 2 8 0 #21416b08 | .cart-line (236) |
| `cartLineSelected` | 0 3 12 0 #2076df0c | .cart-line.selected-line (236) |
| `tooltip` | 0 4 18 0 #14274630 | .action-tooltip |
| `signCard` | 0 15 50 0 #12345610 | .sign-card |
| `segmentedSelected` | 0 1 4 0 #00000011 | .segmented .selected (CSS #0001 = #000000 at 0x11 alpha) |
| `payPressed` | 0 3 8 0 #125eae20 ; 0 1 1 0 #ffffff40 inset | .payment-buttons button[aria-pressed=true] (236); second layer is inset |
| `quickActionHoverRing` | 0 0 0 1 #729bd433 inset | .quick-actions .action:hover (inset ring) |
| `qtyControlRing` | 0 0 0 1 #dbe5f3 inset | .qty-control (236) (inset ring) |

Also: `backdrop-filter: blur(4px)` on the modal overlay (`modalBlur` in sizes), `discount-dot` ring `0 0 0 2px var(--card)` (spread ring in `card` color, drawn as a border).

## 9. Motion (parsed)

<!-- table:motion -->
| Token | Value | Source |
|---|---|---|
| `buttonMs` | 180 | button transition .18s |
| `cardMs` | 200 | .product-card transition .2s; .toast/.modal slide-in .2s |
| `slideInMs` | 250 | .center-column slide-in .25s ease; .main grid transition .25s |
| `qtyButtonMs` | 150 | .qty-control button transition .15s |
| `highlightMs` | 1600 | .cart-line.highlight-line animation 1.6s |
| `spinMs` | 1000 | .spinner 1s linear infinite |
| `slideInOffset` | 18 | @keyframes slide-in translateX(18px) (px, not ms) |
| `pressTranslate` | 1 | button:active translateY(1px) (px) |

Easing: CSS default `ease` for transitions, `ease` for `slide-in .25s`, `linear` for the spinner. Hold-to-repeat timing (500 ms then 140 ms) is behaviour, not CSS (DEC in pricing/POS steps). `prefers-reduced-motion: reduce` sets animation and transition to none on `.main, .center-column, .toast, .modal`; AppMotion consumers must use zero durations then.

## 10. Fluid clamp rules at the reference viewport (1868.44 x 1034.67)

Computed from the formulas. "max"/"min" = saturated (identical for any larger/smaller window); "fluid" = depends on the exact window size. Only a representative selection; AppMetrics (step 1.4b) will translate every rule. At widths 1868 to 2124 CSS px the `vw`-based rules still saturated (everything not marked fluid) do not change; the fluid `vw` ones (top bar padding/gap, brand gap, brand mark width, search margin, stat tile numbers) grow by up to 14 % at 2124 until they hit their max, the fluid `vh` ones depend on window HEIGHT only.

| Selector | Property | clamp() | Raw value | Resolved at reference viewport |
|---|---|---|---|---|
| `:root` | font-size | `clamp(11px, 0.85vw, 14px)` | 15.88 | **14.00** (max) |
| `.topbar` | padding-x | `clamp(10px, 1vw, 20px)` | 18.68 | **18.68** (fluid) |
| `.topbar` | gap | `clamp(8px, 0.8vw, 16px)` | 14.95 | **14.95** (fluid) |
| `.brand` | gap | `clamp(9px, 1.25vw, 24px)` | 23.36 | **23.36** (fluid) |
| `.brand strong` | font-size | `clamp(19px, 1.65vw, 26px)` | 30.83 | **26.00** (max) |
| `.brand-mark` | width | `clamp(30px, 3vw, 58px)` | 56.05 | **56.05** (fluid) |
| `.brand-mark` | font-size | `clamp(32px, 2.7vw, 42px)` | 50.45 | **42.00** (max) |
| `.store` | width | `clamp(160px, 15vw, 250px)` | 280.27 | **250.00** (max) |
| `.store` | font-size | `clamp(11px, 0.85vw, 14px)` | 15.88 | **14.00** (max) |
| `.global-search` | height | `clamp(36px, 4.7vh, 44px)` | 48.63 | **44.00** (max) |
| `.global-search` | margin-x | `clamp(2px, 0.8vw, 16px)` | 14.95 | **14.95** (fluid) |
| `.global-search input / .online / .profile b` | font-size | `clamp(11px, 0.85vw, 14px)` | 15.88 | **14.00** (max) |
| `.avatar` | size | `clamp(30px, 2.4vw, 38px)` | 44.84 | **38.00** (max) |
| `.sidebar` | gap | `clamp(8px, 2.3vh, 24px)` | 23.80 | **23.80** (fluid) |
| `.sidebar button` | height | `clamp(48px, 8vh, 76px)` | 82.77 | **76.00** (max) |
| `.sidebar button svg` | size | `clamp(21px, 1.7vw, 26px)` | 31.76 | **26.00** (max) |
| `.empty-customer` | margin-bottom | `clamp(8px, 1.1vh, 13px)` | 11.38 | **11.38** (fluid) |
| `.empty-customer` | padding-bottom | `clamp(8px, 1vh, 12px)` | 10.35 | **10.35** (fluid) |
| `.customer-chip select` | width | `clamp(105px, 12vw, 175px)` | 224.21 | **175.00** (max) |
| `.customer-chip select` | font-size | `clamp(11px, 0.8vw, 13px)` | 14.95 | **13.00** (max) |
| `.sale-toggle button` | padding-y | `clamp(5px, 0.8vh, 9px)` | 8.28 | **8.28** (fluid) |
| `.sale-toggle button` | padding-x | `clamp(6px, 0.55vw, 10px)` | 10.28 | **10.00** (max) |
| `.categories button` | padding-y | `clamp(7px, 1.1vh, 12px)` | 11.38 | **11.38** (fluid) |
| `.categories button` | padding-x | `clamp(8px, 0.7vw, 13px)` | 13.08 | **13.00** (max) |
| `.subcategories` | margin-top | `clamp(8px, 1.1vh, 12px)` | 11.38 | **11.38** (fluid) |
| `.subcategories button` | padding-y | `clamp(7px, 0.9vh, 10px)` | 9.31 | **9.31** (fluid) |
| `.subcategories button` | padding-x | `clamp(8px, 0.7vw, 13px)` | 13.08 | **13.00** (max) |
| `.catalog-tools` | margin-y | `clamp(9px, 1.4vh, 15px)` | 14.49 | **14.49** (fluid) |
| `.field` | height | `clamp(32px, 4.4vh, 42px)` | 45.53 | **42.00** (max) |
| `.field` | gap | `clamp(5px, 0.7vw, 11px)` | 13.08 | **11.00** (max) |
| `.field` | padding-x | `clamp(7px, 0.8vw, 13px)` | 14.95 | **13.00** (max) |
| `.view-toggle button` | width | `clamp(26px, 2.1vw, 36px)` | 39.24 | **36.00** (max) |
| `.view-toggle button` | height | `clamp(27px, 3.5vh, 35px)` | 36.21 | **35.00** (max) |
| `.product-grid` | min column width | `clamp(130px, 11vw, 170px)` | 205.53 | **170.00** (max) |
| `.product-grid` | gap | `clamp(6px, 0.65vw, 11px)` | 12.14 | **11.00** (max) |
| `.product-card` | padding | `clamp(7px, 0.6vw, 11px)` | 11.21 | **11.00** (max) |
| `.product-image` | height | `clamp(70px, 9.6vh, 84px)` | 99.33 | **84.00** (max) |
| `.product-bottom > b` | font-size | `clamp(12px, 0.85vw, 15px)` | 15.88 | **15.00** (max) |
| `.product-stepper button` | size | `clamp(23px, 1.8vw, 30px)` | 33.63 | **30.00** (max) |
| `.product-stepper first-child` | size | `clamp(20px, 1.6vw, 25px)` | 29.90 | **25.00** (max) |
| `.cart-heading` | min-height | `clamp(32px, 4.5vh, 44px)` | 46.56 | **44.00** (max) |
| `.cart-heading` | gap | `clamp(5px, 0.5vw, 9px)` | 9.34 | **9.00** (max) |
| `.cart-heading h2` | font-size | `clamp(17px, 1.25vw, 22px)` | 23.36 | **22.00** (max) |
| `.cart-heading > svg` | width | `clamp(21px, 1.7vw, 26px)` | 31.76 | **26.00** (max) |
| `.customer-label` | margin-top | `clamp(7px, 1vh, 12px)` | 10.35 | **10.35** (fluid) |
| `.cart-table` | margin-top | `clamp(8px, 1.2vh, 13px)` | 12.42 | **12.42** (fluid) |
| `.cart-line` | min-height (236) | `clamp(84px, 10vh, 96px)` | 103.47 | **96.00** (max) |
| `.stat-tiles strong (236)` | font-size | `clamp(20px, 1.45vw, 28px)` | 27.09 | **27.09** (fluid) |
| `.bill-summary (236)` | padding | `clamp(14px, 1.6vh, 20px)` | 16.55 | **16.55** (fluid) |
| `.bill-summary (236)` | gap | `clamp(8px, 0.75vh, 12px)` | 7.76 | **8.00** (min) |
| `.bill-summary h2 (236)` | font-size | `clamp(18px, 1.25vw, 22px)` | 23.36 | **22.00** (max) |
| `.summary-card (236)` | padding | `clamp(6px, 0.8vh, 10px)` | 8.28 | **8.28** (fluid) |
| `.summary-rows > div (236)` | height | `clamp(28px, 3.2vh, 34px)` | 33.11 | **33.11** (fluid) |
| `.summary-rows > div b (236)` | font-size | `clamp(13px, 0.95vw, 16px)` | 17.75 | **16.00** (max) |
| `.invoice (236)` | height | `clamp(52px, 5.6vh, 68px)` | 57.94 | **57.94** (fluid) |
| `.invoice strong (236)` | font-size | `clamp(14px, 0.9vw, 17px)` | 16.82 | **16.82** (fluid) |
| `.invoice b (236)` | font-size | `clamp(25px, 2.5vh, 32px)` | 25.87 | **25.87** (fluid) |
| `.checkout-section (236)` | padding | `clamp(10px, 1.3vh, 16px)` | 13.45 | **13.45** (fluid) |
| `.checkout-section / .inline-payment (236)` | gap | `clamp(8px, 0.75vh, 12px)` | 7.76 | **8.00** (min) |
| `.payment-buttons button (236)` | height | `clamp(46px, 6.5vh, 56px)` | 67.25 | **56.00** (max) |
| `.payment-buttons button (236)` | font-size | `clamp(16px, 1.1vw, 20px)` | 20.55 | **20.00** (max) |
| `.inline-tendered input (236)` | font-size | `clamp(18px, 1.25vw, 22px)` | 23.36 | **22.00** (max) |
| `.quick-actions (236)` | row/tile size | `clamp(44px, 5.2vh, 52px)` | 53.80 | **52.00** (max) |

## 11. Media-query inventory (documentation only; UNVERIFIED VISUALLY, no screenshots)

| Query | Effect (see `react_audit.md` section 5 for the Flutter rule names) |
|---|---|
| width <= 1700 | stacked 2-row cart line, stat tile sizing, cart action icons above labels |
| width <= 1280 | `--topbar-height` 56, `--sidebar-width` 64, hide kbd hint, 2-column product grid when cart present, cart heading wraps |
| width <= 1100 | hide line barcode/image, brand and store shrink, stat tiles vertical, 12 px panel padding |
| height <= 960 | summary compaction (rows 24-28, inputs 28, payment 46, quick actions 44) |
| height <= 820 | further compaction (rows 21, inputs 22, payment 34-38, invoice 42) |
| height <= 719 | member card collapses to a one-line header, floating form |
| print | receipt only (80 mm, 5 mm padding, 11 px) |
| prefers-reduced-motion | animations and transitions off |

## 12. Golden comparison limits

Golden vs screenshot compares colors and type only at the reference viewport in light mode; known limits: text anti-aliasing and sub-pixel positioning differ between Chrome/macOS and Flutter's renderer, shadow blur differs slightly, `backdrop-filter`, native `select` and scrollbars cannot be matched pixel for pixel (KG-051). Dark mode and other sizes are regression-only.
