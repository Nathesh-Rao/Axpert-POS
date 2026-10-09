# Responsive pass (S7)

Date: 2026-10-09. Tests: `test/layout/full_sweep_test.dart` (full matrix) and `test/layout/touch_targets_test.dart` (tablet touch audit, report only). Both are VM tests; the touch audit loads the real Roboto Condensed so `FittedBox` scale-downs match the app (the default test font is much wider).

## 1. Full layout matrix (run once)
- Sizes: widths 900, 950, 1000, 1100, 1101, 1280, 1281, 1440, 1700, 1701, 1868, 1900 x heights 600, 719, 720, 733, 820, 900, 960, 1000 = **96 sizes**.
- Screens at every size: the 7 routes (POS with cart lines and a held bill, Products, Customers, Sales with a sale with lines, Returns with a matched bill, Reports, Settings), the 15 dialogs (settings, profile, close, shortcuts, scan, priceCheck, customers, addCustomer, recall, discount, counter, note, reprint, receipt, confirm) and the Counter closed screen.
- Per screen and size: no framework exception (a RenderFlex overflow is one), every page panel and every dialog card inside the window, the Counter closed texts inside the window.
- **Result: 12 of 12 tests (one per width, 96 sizes x 23 screens) pass, 0 failures, 0 fixes needed.** The older full-matrix suites (summary, dialogs, pickers, receipt) stay in the suite and pass.
- What this does not prove: it does not check text readability or spacing (those are the feature layout suites), and the plain-test font is wider than the real one, so it is stricter than the app.

## 2. Below the floor (768 x 576)
The matrix floor is 900 (KG-030, KG-088: the prototype has no layout under about 1000 and the shell has no minimum window size). At **768 x 576** every page except POS lays out without an overflow error. The **POS page overflows** (the framework reports overflows of 10 to 27 px on the right in debug) and the cart column is cramped: item name truncated to "La", table header cells overlapping ("Pric Disc Tota"), Clear Cart / Price Check labels cut. Nothing was changed: it is outside the matrix and needs your decision (a minimum window size in the Windows runner, or a narrow layout, which the prototype does not have).

## 3. Tablet touch targets (report only, as decided)
Rule used: an interactive element is at least 44 px (48 px preferred) in both directions. Sizes: tablet landscape 1024x768, 1100x733, 1180x820, 1194x834, 1280x800 (the table shows the smallest over those); the sizes are the painted size after any scale-down.
- Distinct controls found on all routes and dialogs: **87**. Reaching 44 px at every tablet size: **30**. Reaching 48 px: **18**. Under 44 px at some tablet size: **57**.
- At the 900 x 600 floor 268 control instances are under 44 px.
- Nothing was changed: these are the React sizes (Phase A copies them). Phase B should decide per control between a larger hit area (invisible padding where neighbours allow it) and a tablet-specific size.
- Text inputs: the audit measures the editable text area; the surrounding box is larger (for example the search box is 46 px high), so inputs are listed for completeness only.

| Control | Kind | Smallest (px) | Largest of the smallest side | At 1024x768 | At 1280x800 | Where |
|---|---|---|---|---|---|---|
| input(text) | input | 12 | 24 | 50×12 | 50×12 | /, /customers, /more … |
| Online | pressable | 16 | 16 | 47×16 | 47×16 | /, /customers, /more … |
| Conversion currency | pressable | 17 | 19 | 23×17 | 23×17 | /, /customers, /more … |
| Customer | pressable | 17 | 17 | 185×17 | 268×17 | / |
| input | input | 17 | 21 | 435×17 | 623×17 | /, /customers, /more … |
| Find customer | pressable | 19 | 19 | 27×19 | 29×19 | / |
| Find member | pressable | 19 | 19 | 19×19 | 19×19 | /, /customers, /more … |
| Remove one <product> (cart −) | pressable | 20 | 20 | 20×20 | 20×20 | / |
| Toggle favourite | pressable | 21 | 21 | 21×21 | 21×21 | / |
| View receipt | pressable | 21 | 42 | 48×42 | 71×21 | /sales |
| Cash Sale | pressable | 23 | 30 | 60×23 | 78×30 | / |
| Credit Sale | pressable | 23 | 30 | 64×23 | 83×30 | / |
| Add <product> (card +) | pressable | 23 | 147 | 23×23 | 23×23 | / |
| Scan simulator | pressable | 23 | 23 | 23×23 | 23×23 | /, /customers, /more … |
| 100 | pressable | 24 | 28 | 58×24 | 60×24 | /, /customers, /more … |
| 2,000 | pressable | 24 | 28 | 58×24 | 60×24 | /, /customers, /more … |
| 500 | pressable | 24 | 28 | 58×24 | 60×24 | /, /customers, /more … |
| Exact | pressable | 24 | 28 | 58×24 | 60×24 | /, /customers, /more … |
| Store | pressable | 25 | 25 | 160×25 | 192×25 | /, /customers, /more … |
| Grid view | pressable | 26 | 27 | 26×27 | 27×28 | / |
| List view | pressable | 26 | 27 | 26×27 | 27×28 | / |
| All | pressable | 29 | 31 | 29×32 | 31×32 | / |
| Card | pressable | 30 | 40 | 123×30 | 127×30 | /, /customers, /more … |
| Cash | pressable | 30 | 40 | 123×30 | 127×30 | /, /customers, /more … |
| Clear | pressable | 30 | 40 | 30×30 | 30×30 | /, /customers, /more … |
| Clear Hold | pressable | 30 | 40 | 30×30 | 30×30 | /, /customers, /more … |
| Close | pressable | 30 | 40 | 30×30 | 30×30 | /, /customers, /more … |
| Discount (F6) | pressable | 30 | 40 | 30×30 | 30×30 | /, /customers, /more … |
| Hold (F4) | pressable | 30 | 40 | 30×30 | 30×30 | /, /customers, /more … |
| M | pressable | 30 | 31 | 38×30 | 39×31 | /, /customers, /more … |
| Price Check | pressable | 30 | 44 | 30×30 | 30×30 | /, /customers, /more … |
| Recall (F5) | pressable | 30 | 40 | 30×30 | 30×30 | /, /customers, /more … |
| Reprint | pressable | 30 | 40 | 30×30 | 30×30 | /, /customers, /more … |
| Close dialog | pressable | 31 | 31 | 31×31 | 31×31 | dlg addCustomer, dlg close, dlg confirm … |
| - | checkbox | 32 | 32 | 32×32 | 32×32 | /more, dlg settings |
| Biscuits | pressable | 32 | 33 | 56×32 | 58×32 | / |
| Chips | pressable | 32 | 33 | 44×32 | 46×32 | / |
| Confectionery | pressable | 32 | 33 | 85×32 | 87×32 | / |
| Juices | pressable | 32 | 33 | 48×32 | 50×32 | / |
| Order options | pressable | 32 | 32 | 32×32 | 32×32 | / |
| Soft Drinks | pressable | 32 | 33 | 71×32 | 73×32 | / |
| Water | pressable | 32 | 33 | 45×32 | 47×32 | / |
| Add Customer | pressable | 32 | 45 | 90×34 | 116×35 | /, /customers, dlg customers |
| More categories | pressable | 34 | 34 | 34×35 | 34×36 | / |
| All Items | pressable | 34 | 36 | 85×35 | 87×36 | / |
| Beverages | pressable | 34 | 36 | 92×35 | 94×36 | / |
| Favourites | pressable | 34 | 36 | 93×35 | 95×36 | / |
| Personal Care | pressable | 34 | 36 | 110×35 | 112×36 | / |
| Snacks | pressable | 34 | 36 | 77×35 | 79×36 | / |
| More options | pressable | 36 | 36 | 36×36 | 36×36 | /, /customers, /more … |
| Notifications | pressable | 36 | 36 | 36×36 | 36×36 | /, /customers, /more … |
| Remove item | pressable | 40 | 40 | 40×40 | 40×40 | / |
| Email | pressable | 43 | 43 | 159×43 | 156×43 | dlg receipt |
| Flat amount ₹ | pressable | 43 | 43 | 168×43 | 163×43 | dlg discount |
| Percentage % | pressable | 43 | 43 | 168×43 | 163×43 | dlg discount |
| Print | pressable | 43 | 43 | 159×43 | 156×43 | dlg receipt |
| WhatsApp | pressable | 43 | 43 | 159×43 | 156×43 | dlg receipt |
| Clear Cart | pressable | 44 | 44 | 76×44 | 111×44 | / |
| Decrease quantity | pressable | 44 | 44 | 44×44 | 44×44 | / |
| Hold | pressable | 44 | 44 | 76×44 | 111×44 | / |
| Increase quantity | pressable | 44 | 44 | 44×44 | 44×44 | / |
| Recall | pressable | 44 | 44 | 76×44 | 111×44 | / |
| Apply discount | pressable | 45 | 45 | 170×45 | 165×45 | dlg discount |
| Confirm | pressable | 45 | 45 | 205×45 | 200×45 | dlg confirm |
| Confirm & close counter | pressable | 45 | 45 | 419×45 | 409×45 | dlg close |
| New Sale | pressable | 45 | 45 | 489×45 | 479×45 | dlg receipt |
| Refund & restock | pressable | 45 | 45 | 550×45 | 550×45 | /returns |
| Save | pressable | 45 | 45 | 419×45 | 409×45 | dlg counter, dlg note |
| Save customer | pressable | 45 | 45 | 419×45 | 409×45 | dlg addCustomer |
| Customers | pressable | 54 | 54 | 54×61 | 54×64 | /, /customers, /more … |
| More | pressable | 54 | 54 | 54×61 | 54×64 | /, /customers, /more … |
| POS | pressable | 54 | 54 | 54×61 | 54×64 | /, /customers, /more … |
| Products | pressable | 54 | 54 | 54×61 | 54×64 | /, /customers, /more … |
| Reports | pressable | 54 | 54 | 54×61 | 54×64 | /, /customers, /more … |
| Returns | pressable | 54 | 54 | 54×61 | 54×64 | /, /customers, /more … |
| Sales | pressable | 54 | 54 | 54×61 | 54×64 | /, /customers, /more … |
| Cancel | pressable | 65 | 65 | 205×65 | 200×65 | dlg confirm |
| Remove | pressable | 65 | 65 | 170×65 | 165×65 | dlg discount |
| Scan random product | pressable | 65 | 65 | 205×65 | 200×65 | dlg scan |
| Ananya Sharma | pressable | 79 | 79 | 419×79 | 409×79 | dlg customers |
| H396974 · 1 items | pressable | 79 | 79 | 419×79 | 409×79 | dlg recall |
| Priya Nair | pressable | 79 | 79 | 419×79 | 409×79 | dlg customers |
| Rahul Mehta | pressable | 79 | 79 | 419×79 | 409×79 | dlg customers |
| Walk-in Customer | pressable | 79 | 79 | 419×79 | 409×79 | dlg customers |
| bill row <number> | pressable | 79 | 79 | 419×79 | 409×79 | dlg reprint |
| Dark mode | inkwell | 87 | 87 | 570×87 | 600×87 | /more, dlg settings |
| Scan beep | inkwell | 87 | 87 | 570×87 | 600×87 | /more, dlg settings |

Reading the table: "Smallest" is the smallest of min(width, height) over the five tablet sizes; the control passes when it is at least 44. Dialog buttons (Confirm, Cancel, Save, New Sale) and the sidebar buttons are the controls that already pass; the product-card add button (23 px), the cart minus button (20 px), the favourite star (21 px), the quick amounts (24 px), the sale-type pills (23 px high at 1024), "Online" (16 px) and the scan simulator (23 px), the Cash and Card pay buttons at the tight density (30 px, heights up to 820) and every dialog's close button (31 px) are the clearest failures. The product card itself is large and tappable; only its small buttons fail.

## 4. Findings to decide in Phase B
1. Tiny controls above (hit area enlargement vs larger controls on tablet widths).
2. A minimum window size for the Windows runner (or a narrow layout) for widths under 900.
3. Nothing found by the full sweep needed a fix.
