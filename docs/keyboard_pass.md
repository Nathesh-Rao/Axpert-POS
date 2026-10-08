# S6 keyboard and focus pass

Source of truth: React `App.tsx` (global `keydown` 506-535; Enter handlers at the barcode search, product card, member input, Amount Tendered, scan dialog, price check; line quantity inputs blur on Enter; native DOM Tab order; `close()` returns focus to the global search). Tests: `test/core/shortcuts/shortcuts_test.dart`, `test/keyboard/keyboard_pass_test.dart` (28 tests), plus the flow tests named below. VM only; browser-level behaviour is in `web_key_conflicts.md`.

| Screen / dialog | Keys | Behaviour | Status |
|---|---|---|---|
| Every page | Tab, Shift+Tab | regions in DOM order: top bar, sidebar (POS to More), page, Bill Summary; reading order inside a region; POS: whole catalog, then the cart | fixed in S6 (was interleaving sidebar and page); tested on all 7 routes |
| Every page | Ctrl+K, Cmd+K | focus the top-bar search, also from inputs | OK, tested (shortcuts_test, keyboard_pass_test) |
| Every page | F2 F3 F4 F5 F6 | cash, card, hold, recall, discount; fire inside inputs and with dialogs open (KG-014) | OK, tested |
| Every page | Esc | closes menu and dialog, focus back to the search | OK, tested for all 14 dialog ids |
| Every page | Delete | removes the selected cart line outside inputs and with no dialog | OK, tested |
| Sidebar | Tab, Enter, Space | navigate; Enter tested | OK |
| Top bar | Tab, Enter | store select, search, barcode, online, bell, profile, menu | OK (order checked) |
| POS catalog | Tab, Enter on a card | card adds | OK (catalog_view_test) |
| POS cart / summary | Tab, Enter, hold-to-repeat | line inputs blur on Enter; Amount Tendered Enter pays cash; member Enter | OK (payment_flow_test, cart tests) |
| Products | Tab | search box only (rows are not focusable, as React) | OK |
| Customers | Tab, Enter | search, Add Customer; email cell has a tooltip (hover) | OK |
| Sales | Tab, Enter | search, "View receipt" per row | OK |
| Returns | Tab, Enter, F-keys | bill box, one quantity box per line, Refund & restock; no Enter handler (React) | new, tested |
| Reports | Tab | nothing focusable | OK |
| Settings page and dialog | Tab, Space | one stop per row (the checkbox); a click anywhere on the row toggles | fixed in S6 (was two stops per row) |
| Profile | Tab, Esc | close button only | OK |
| Shift close | Tab, Enter, Esc | Confirm; Enter confirms; Esc closes | OK |
| Counter closed | Enter | "Start new shift" is focused (KG-160) | OK |
| Scan | Enter, Esc | Enter scans (first stop is the input) | OK (search_pickers_flow_test) |
| Price check | Enter, Esc | Enter looks up | OK |
| Customer picker | Up, Down, Enter, Esc | arrows are an addition (KG-133) | OK |
| Add Customer | Tab, Esc | no Enter handler (React) | OK |
| Recall, Reprint | Tab, Enter, Esc | rows are buttons | OK |
| Receipt | Tab, Enter, Esc | Print, Email, WhatsApp, New Sale are Tab stops; Enter activates | OK, tested |
| Rename counter, Add note | Tab, Esc | no Enter handler (React) | OK |
| Discount drawer | Tab, Esc | segmented buttons, input, Remove, Apply; no Enter handler (React) | OK |
| Shortcuts help | Tab, Esc | close only | OK |
| Confirm | Tab, Esc | Cancel, Confirm | OK |

Visible hints (as React, nothing added): the `⌘K` / `Ctrl+K` chip in the search, tooltips "Hold (F4)", "Recall (F5)", "Discount (F6)" on the quick actions, the Shortcuts help (9 rows, platform-aware, each checked against the real bindings by a test).

Known deviations (KG-168/169): a Flutter dialog keeps Tab inside itself (React lets Tab run behind the dialog); at the last control Tab wraps inside the app (a browser would move to the address bar: needs a manual test).
