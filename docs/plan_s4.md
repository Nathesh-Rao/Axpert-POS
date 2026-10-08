# Plan S4: POS checkout (approved 2026-10-08) - COMPLETE (S4.0, S4.a to S4.d committed; see DEC-095 to DEC-104)

Checkpoints are commit points: S4.a Totals and payment, S4.b Hold, recall, discount, S4.c Pickers and search, S4.d Receipt and help. `/compact` suggested after S4.b. S4.0 (narrow-window cart, density metrics) is done (f051362).

## Scope findings
- Bill Summary also holds the 8-button quick-actions grid (Discount, Price Check, Hold, Clear Hold, Recall, Reprint, Clear, Close; tooltips, held badge, discount dot). Built in S4.a; Close stays a placeholder until S5, Reprint until S4.d.
- Summary and F2-F6 exist on every page, so PaymentController, SalesController, HeldBillsController are permanent (supersedes DEC-040 wording).
- DialogLayer gets a registry (id -> builder, modal or right drawer).
- `applyDiscount*` summary metrics have no JSX element (dead CSS): not built.

## S4.a Totals and payment
PaymentController (permanent), CheckoutService (plain Dart, injected clock), SalesController, ForexController (rate in milli-units), MemberController, OrderMenuController. Widgets: summary panel, totals card, forex card, member card, payment buttons, cash and card panels, quick-actions grid, sale toggle, customer row, customer chip row, order menu, note line, credit validation. F2/F3 real. Other dialogs open the placeholder until their checkpoint.
Tests: CheckoutService, PaymentController (fake timer), forex rounding, member lookup/points clamp, widget states, layout matrix helper (widths 1000-1900, heights 600-1000; line counts, min widths, clipping, no overflow), Chrome copy, goldens at reference viewport.

## S4.b Hold, recall, discount (done)
HeldBillsController, RecallController (stock re-validation, missing product guarded, conflict dialog), DiscountFormController, text dialog controller (note, rename). Recall dialog, conflict dialog, discount drawer (390), note, counter. F4/F5/F6 real. Notifications count wired.

## S4.c Pickers and search (done)
PriceCheck, ScanSimulator, CustomerPicker, AddCustomerForm controllers and dialogs; top-bar matches dropdown (max 6, Enter adds first or scans), scan button opens simulator.

## S4.d Receipt and help (done)
ReceiptDocument, ReceiptBuilder (Sale or draft), ReceiptPrinter + no-op stub, receipt dialog (80 mm look), reprint list, print draft, shortcuts help (platform-aware labels).

## Every checkpoint
format, analyze 0, flutter test, Chrome tests, `flutter run -d chrome` + served release build with tool/web_check, screenshots at 1000/1280/1440/1700/1868 viewed, commit with trailers, report with "what to look at yourself", remind to fully restart `flutter run`.

## Assumptions accepted
Quick amounts write `String(amount)` text, F2 writes toFixed(2), labels use Indian grouping; negative Change Due shown as in screenshot; FC and $ rows show the same converted amount; Reprint/Print draft placeholders until S4.d.


## Status (closed)
- S4.0 f051362, S4.a 1c9b272 + b3ed92a + c91e357 (spacing and inner padding fixes), S4.b 92eb16e, S4.c c113978, S4.d d7d47fc.
- Full Chrome suite: not run for S4.b to S4.d; Chrome tests dropped from the routine by the user (DEC-104, KG-145).
- Open placeholders after S4: only Close (shift summary), S5.
