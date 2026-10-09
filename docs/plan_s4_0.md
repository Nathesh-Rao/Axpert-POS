# Plan S4.0: narrow-window cart layout and density rules

> **Phase A cleanup note:** `reference_react/` and `reference_screenshots/` are a read-only reference kept outside git and are deleted after Phase A (only with the owner's OK). After that the golden-vector generators (`tool/golden/gen_vectors.mjs`, `tool/golden/gen_s6_vectors.mjs`) and `tool/compare/compare_reference.py` stop working, and references to React source lines or screenshots in this file become historical. The generated fixtures (`test/fixtures`), the goldens, the tests and the app keep working.

## Context
Your screenshot (Chrome window about 1000 CSS px wide) shows the S3.c cart line, which is built only for the wide single-row layout, squeezed into a few pixels: the name column collapses ("RIGHT OVERFLOWED BY 55 PIXELS") and the header cells no longer sit over the row cells. KG-097 already lists this. S4.0 builds the width <= 1700 and <= 1100 rules for the cart and catalog, exposes the height-density rules as metrics for S4.a, and fixes the search ring height. Nothing from S4.a starts.

## Findings from the CSS (resolved in file order, as DEC-076 did)
- Later rules win at equal specificity, so several narrow rules are dead: `.line-product img{display:none}` at <= 1280 (line 184) is overridden by `display:block` at line 311, so the image and the barcode are still shown at <= 1280; they hide only at <= 1100 (lines 365/366). `.stat-tiles strong` 16 px at <= 1100 (line 202) is overridden by the <= 1700 clamp (line 362). `.cart-actions .action{min-height:38px}` at height <= 820 (line 233) and `.stat-tiles > div` padding at <= 820 (line 234) are overridden by lines 330 and 333.
- The table header does NOT align with the stacked lines in React: at <= 1700 the header keeps 6 columns `18 | 1.4fr | 1.3fr | .8fr | .8fr | 1fr | 0` while each line becomes `152 | 1fr | 1fr` over two rows. That is the prototype's behavior.
- Search focus ring: React draws `input:focus{outline:2px solid #78aaff;outline-offset:2px}` on the INPUT, not the wrapper, and `.global-search input{height:100%}` makes that input fill the field. So React also shows a rectangular ring inside the field box (visible in the reference screenshot 2, about 46 px tall). Ours is only one text line tall. Match: make the input fill the field height (top bar and catalog field); log "ring replicated" in known_gaps.md.

## Scope (in)
1. **Cart line layouts** (`CartLineLayout` stays `single` / `stacked`; new `AppMetrics` getters):
   - **single (> 1700, current):** columns `20 | 1.6fr | 144 | 76 | 76 | .8fr | 40`, gap 8; header identical. Header and rows share one `CartColumns` definition so they always align.
   - **stacked (<= 1700):** padding 12, grid `152 | 1fr | 1fr`, rows `minmax(52,auto) / auto`, gap 12 x 8; product block spans the row (padding-left 20, padding-right 120); line number absolute (left 12, top 18, 12 px); total absolute (right 60, top 23, 16 px bold); trash absolute (right 12, top 12); row 2: qty cell (label "Qty" above, control 152 x 44, buttons 44, input 64), price and discount (label above, input max 76 x 44, bottom aligned); labels 12 px muted, line-height 14, margin-bottom 4. Header uses the CSS stacked columns (decorative, not aligned: replicate, see decision 1).
   - **<= 1100 on top of stacked:** product image and barcode hidden (GST stays), line-edit font 13, cart heading icon 19 and counter 16, stat tiles vertical.
   - New getters: `cartLineLayout` (exists), `cartHeaderColumns`, `showLineImage` (false at <= 1100), `showLineBarcode` (false at <= 1100), `lineEditFont` (14, 13 at <= 1100), `lineEditHeight` (36 single, 44 stacked), `cartHeadingIconSize/Font` (19/16 at <= 1100), `cartTimeOnOwnRow` (<= 1280: time wraps to its own full-width row, padding 2 0).
2. **Stat tiles:** <= 1700: icon 21, gap 5, tile padding 14 x 5, value font `clamp(18,1.5vw,24)`; <= 1100: padding 12 x 5 on tiles, tiles column-direction with left-aligned content, icon hidden, container padding 8 and gap 8. Getters `statTileIconSize`, `statTileGap`, `statTilePad`, `statTileVertical`, `showStatTileIcon`, `statTilesPad/Gap`.
3. **Cart actions <= 1700 (and <= 1280):** icon above label, gap 3 (2 at <= 1280 only where not overridden), height stays 44; content is centered and may exceed the 6 px padding (CSS lets it overflow invisibly; Flutter must not raise an overflow error). Getter `cartActionsStacked`.
4. **Catalog bits in the same media blocks:** 2-column grid when the cart is present at <= 1280 (`catalogGridColumnsWithCart`), product price font 11 and stepper gap 2 at <= 1100. Heights: `cartHeadingMinHeight` 30 at <= 820.
5. **Density metrics for S4.a (metrics and tests only, no panel):** `memberCollapsed` (height <= 719), `summaryDensity` (exists) and a pure-Dart `SummaryMetrics` (`core/responsive/summary_metrics.dart`) holding, per density, the resolved values of lines 207-234 and 378-424 (panel padding/gap, title height/font, card padding, row height/fonts, invoice height/fonts, currency row, rate label, membership inputs and labels, checkout section, payment buttons, tendered, quick amounts, complete payment, terminal, decline, quick actions size/gap). Documented as a new table in `docs/css_metrics.md` section 13 and asserted by `css_metrics_test`.
6. **Search ring:** input fills the field height in the top bar and the catalog field; `known_gaps.md` entry (ring replicated, drawn on the input as in React).
7. **Docs:** decisions DEC-091.. (cascade resolution, header behavior, density metrics, search ring), KG-097 updated (resolved except what stays), KG-040..045 marked "built from CSS, unverified visually".

## Stays for later
- Customer row, sale toggle, add-customer and order-menu rules at <= 1280/<= 1100 (S4.b/c). The summary panel itself and its density use (S4.a). Top bar/sidebar narrow rules are already done in S2.

## Tests
- `app_metrics_test`: widths 1868 / 1700 / 1440 / 1280 / 1100 and heights 960 / 820 / 719 for every new getter and `SummaryMetrics`; boundary values (1700 vs 1701, 1100 vs 1101, 960/961, 820/821, 719/720).
- Widget tests of `CartLineRow` and `CartTable` at 1868, 1440, 1100 and 1000 wide: no overflow or RenderFlex error, name text not wrapped per character, image/barcode visibility, tiles and actions variant, heading time row; header/row alignment: at the wide layout each header cell has the same left/right edges as its row cell; at stacked the header columns follow the CSS proportions (test documents the intended non-alignment).
- Search field: ring height equals the field's content height.
- All of them run with `flutter test --platform chrome` (no dart:io).
- Regression goldens (light, cart with one line) at 1440 x 900 and 1100 x 700, marked "unverified visually"; the reference-viewport goldens must not change.

## Verification
- `dart format .`, `flutter analyze` (0), `flutter test`, Chrome tests.
- `tool/web_check/cdp.mjs` gets a viewport size argument (tool file only). Debug server (`flutter run -d web-server`) for the console check, because release builds do not print "overflowed" errors; served release build for screenshots. Windows: about 1000, 1100, 1280, 1440, 1700 and 2124 wide; add products, edit qty/price/discount, remove, clear. Report what the console showed and what could not be seen.
- Commit "S4.0 Narrow-window cart layout and density" with the two trailers, then short report and STOP.

## Interactions for you to try afterwards
Resize the window to about 1000, 1100, 1280, 1440, 1700: add 2 products; check the line (name not wrapped, qty buttons, price and discount boxes, total and trash top right); type a qty over stock; hold + and -; use the stat tiles and the four action buttons; scroll the table with 6+ lines; click in the top search field and compare its ring with React.

## Decisions for you (defaults in bold)
1. At <= 1700 the header strip does not line up with the stacked lines in React. **Replicate React exactly (header per CSS, wide layout always aligned).** Alternative: hide or adapt the header at <= 1700 (a deviation that needs your approval).
2. A React screenshot at about 1440 and about 1000 CSS px would let me compare the stacked line; optional, I will flag everything as unverified without it.
3. **Include the 2-column catalog grid at <= 1280 and the 11 px price at <= 1100** (they are in the same media blocks).
4. **Extend `tool/web_check` with a viewport-size argument.**

## As built (2026-10-08)
- Approved with the defaults (header replicated exactly, catalog rules included, `tool/web_check` size argument). No React screenshots at 1440 or 1000 px exist in `reference_screenshots/`, so everything is flagged unverified (KG-105).
- Decisions DEC-091 to DEC-094; `css_metrics.md` section 13; KG-097 resolved (except S4 parts), KG-103 to KG-105.
