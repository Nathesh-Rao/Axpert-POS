# Final comparison with the reference screenshots (S7)

Date: 2026-10-09. Seven React screenshots (2124x1180, light mode, `reference_screenshots/`) against the goldens at the reference viewport (2102x1164 at 1.125, which is exactly the screenshot's page area: crop x 10..2112, y 8..1172). Tool: `python3 tool/compare/compare_reference.py [outdir]` (standard library only): it crops each screenshot, aligns it 1:1 with the golden and measures structure (panel edges, text bands and their x extents per region, column positions) plus a pixel mismatch percentage and a diff image. I also looked at every reference screenshot and at the goldens and diff images myself.

Since the reference pages 4.57.21 to 4.58.11 were taken with one "Lays Classic 52g" line in the cart (the Bill Summary shows 20.00 / 21.00), the goldens of Products, Customers, Sales, Returns and Reports now add that line too, so the Bill Summary is comparable.

## Summary
| Screen | Reference | Golden | Pixels differing by more than 40 luma | Page region (text bands matched in order) | Verdict |
|---|---|---|---|---|---|
| POS empty cart | 4.56.50 | `shell_pos_light` | 3.5 % | 17 of 17, median 1 px, max 3 px | matches; see differences 1 to 4 |
| POS one line | 4.57.09 | `pos_one_line_light` | 4.1 % | 20 of 21 (the 21st is the 4 px sliver of the next card row), median 2 px, max 4 px | matches after the two fixes below |
| Products | 4.57.21 | `shell_products_light` | 3.5 % | 15 of 15, median 2 px, max 5 px | matches except the table width (scrollbar gutter, KG-173) |
| Customers | 4.57.32 | `shell_customers_light` | 2.2 % | 8 of 8, median 1 px, max 3 px | matches; columns within 1 to 2 px |
| Sales (empty) | 4.57.41 | `shell_sales_light` | 1.9 % | 8 of 8, median 1 px, max 3 px | matches; columns within 1 to 3 px |
| Returns (empty) | 4.57.54 | `shell_returns_light` | 1.9 % | 6 of 6, median 2 px, max 3 px | matches |
| Reports (zeros) | 4.58.11 | `shell_reports_light` | 2.0 % | 10 of 10, median 1 px, max 3 px | matches; tiles and bars within 1 px |

The pixel percentage is mostly text: the reference uses Chrome's text rendering, the goldens the bundled test font (KG-075, KG-077). Sidebar (14 text bands) and Bill Summary (20 to 22 bands) match in every pair: median 1 to 2 px, max 6 px in x or y.

## Defects found by this comparison and fixed in S7
1. **Cart heading at the reference viewport (POS with a line).** The Cash Sale and Credit Sale pills were drawn about 20 % too small (82 x 30 px against 102 x 40 px, text 12 px against 14 px) and the "..." menu sat about 80 px left of the panel's right edge. Cause: the sale toggle and the clock were `Flexible` children next to two `Spacer`s, so the toggle was scaled down to a quarter of the free space even when there was plenty of room. Now the heading follows the CSS (toggle never shrinks, the clock and the menu share the free space equally; where the row is too narrow the whole row scales down). After: pills 836-917 and 941-1031 against 836-913 and 941-1024 in the reference (within 7 px), clock 1256-1371 against 1263-1373, menu dots at the right edge.
2. **Catalog header of the empty cart.** "PRODUCT CATALOG / 20 items" was about 290 px left of the right edge (same `Flexible` plus `Spacer` cause). After: its right edge is at x 1559 in both images (the text is 10 px wider in the golden: font).
Goldens refreshed for the screens that include these headings; the layout and keyboard tests pass.

## Remaining measured differences (all logged)
| # | Where | Measured | Cause | Log |
|---|---|---|---|---|
| 1 | Products table | the reference has a classic scrollbar (about 28 px incl. padding) because the table is taller than the panel, so its columns are narrower: header x in the reference 152, 621, 900, 1179, 1305, 1493 against 153, 631, 914, 1198, 1327, 1518 in the golden (+10 to +25 px). Customers and Sales (no scrollbar) match to 1 to 3 px | React's `overflow:auto` shows the browser scrollbar and takes its width; Flutter shows no scrollbar | KG-173 (new) |
| 2 | Top bar, right cluster | online, bell, avatar and profile text 5 to 7 px right of the reference, the barcode icon 14 px (the chip is wider because the test font has no `⌘` glyph and draws a box) | test font and glyph metrics | KG-077, KG-084 |
| 3 | Saturated colours | the disabled Cash button is (152,197,170) in the reference and (120,197,167) in the golden: 26 to 32 in the red channel; neutrals match to 1 to 3 | the screenshots were captured in the display colour profile (P3), only saturated colours move noticeably | KG-076 |
| 4 | Search focus ring | the golden ring on the top search extends about 15 px further right than in the reference (ring 590-1540 against 590-1520 on a 2000 px view) | the `⌘K` chip position, same as 2 | KG-103, KG-084 |
| 5 | Text size on the new pages | the 13 px "Find a bill to return items", the empty-state texts and "Sales by payment method" were measured from the screenshots (text widths within about 2 %) | no font-size rule found in `index.css` | KG-154, KG-171 |
| 6 | Row pitch of the product grid | the third card row is 2 px lower in the golden (600-819 against 599-817) | rounding of card heights | KG-119 |
| 7 | Dark mode, all other window sizes, dialogs, drawers, receipt, the Sales table with rows, Reports with data, Settings, Profile, shift close, Counter closed, the matched Returns bill | no screenshot exists | built from CSS | KG-046 to KG-049, KG-070, KG-083, KG-094, KG-099, KG-105, KG-126, KG-135, KG-143, KG-148, KG-153, KG-163, KG-171 |

## Per screen: what matches
- **POS empty cart:** top bar (brand, store select, search, icons), sidebar (7 buttons, active item), catalog header (customer chip, Cash/Credit Sale pills, add button, caption), category chips, subcategory chips, search box and view toggle, the 7-column grid of 20 cards (image, name, code, price, add button, favourite star) and the Bill Summary (all 21 text bands).
- **POS one line:** the three-column layout, the cart panel (heading, customer row, table header, the single-row cart line with image, quantity control, price, discount, total, trash), the stat tiles, the cart actions, the catalog with the "x1" badge and minus button on the Lays card, the Bill Summary with 20.00, 1.00 and 21.00, red Change Due.
- **Products:** heading, search box, header band, rows (name, code with the small barcode, category, GST, price, green stock chip), row pitch (reference 76 px rows: white runs at 351-430, 432-510 ... against 352-430, 432-509 ...). Only the table width differs (difference 1).
- **Customers:** heading, Add Customer button, search box, header band, four rows with the dash cells.
- **Sales (empty):** heading, search box, header band with the five column titles, the document icon with its two texts.
- **Returns (empty):** heading, "Find a bill to return items", search box 550 px wide, "Enter a completed bill number to begin."
- **Reports (zeros):** three tiles (label above 27 px value), "Sales by payment method", three empty bars with their right-aligned amounts, the footer line.

## Not compared (and why)
Only the seven screenshots exist, all light mode at one viewport. Every other size, dark mode, hover and focus states, the dialogs and the pages with data are built from the CSS and the React code and stay "unverified visually" in `known_gaps.md`.
