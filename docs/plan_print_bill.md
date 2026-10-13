# Plan: system print for the bill + two small fixes

Branch `integration` on top of 117e261. Repo `pos_application` only. axpert_pos and reference_react untouched. No push. Plan copy goes to `docs/plan_print_bill.md`.

## Context (what exists today, read from the code and from React)
- `PrintService` already exists (`lib/core/services/print_service.dart`): `printReceipt(ReceiptDocument)`, only `RecordingPrintService` (records, prints nothing), registered in `initial_binding.dart:450`. `ReceiptController.print()` calls it. React does `window.print()` on the receipt modal's Print button only.
- There is NO print button in the Bill Summary. The printer-icon quick action there is **Reprint** (`quick_actions_grid.dart`): it opens "Recent sales", a row opens the receipt dialog for that sale (same as React). The order menu "Print draft" opens the same receipt dialog with the draft cart. The checkout opens it too.
- There is NO print keyboard shortcut (`ShortcutAction` = cash, card, hold, recall, discount, deleteSelected). Nothing to preserve; I will not invent one. The Print button stays reachable by Tab + Enter.
- Receipt data: `ReceiptBuilder.fromSale` -> `ReceiptDocument` (store name/address/phone/tax id/header/footer, cashier, customer, lines with free/offer notes, subtotal, discount, points, tax label + CGST/SGST parts, total, mode, change). Money is `Money`/`MoneyFormatter`.

## Settled trigger points (Task A)
All printing goes through ONE call, `ReceiptController.print()` (the Print button of the receipt dialog), which now covers:
1. Print of a just-completed sale (receipt dialog after checkout).
2. **Reprint of a completed sale**: Bill Summary "Reprint" -> pick the sale -> receipt dialog -> Print (React flow kept; Reprint does not print by itself).
3. Print draft (order menu) -> receipt dialog -> Print (unpaid draft).
The web check clicks Reprint -> a sale -> Print (and the checkout Print). If you want Reprint to print directly from the list row, say so; I keep the React flow.

## Packages (pin exact; approving this plan approves them)
- `printing: 5.14.3` and `pdf: 3.12.0`. NOT the latest (5.15.1 / 3.13.1): those need Dart >= 3.12 / Flutter >= 3.41, this project is on Flutter 3.38.4 / Dart ^3.10.3 (KG-180).
- Verified on pub.dev (API, today): `printing` 5.14.3 declares plugin platforms android, ios, linux, macos, web, windows; `pdf` 3.12.0 is pure Dart (sdk: dart + flutter, all platforms). `flutter pub add printing:5.14.3 pdf:3.12.0 --dry-run` resolves; new transitive packages: ffi, image, archive, barcode, bidi, path_parsing, pdf_widget_wrapper, xml 6.6.1, posix, qr (xml/archive resolve to older majors than latest; nothing existing changes).
- NOT verifiable here: that these versions actually print on Windows, iPad, Android and a real printer (no Windows machine, no tablet, no paper). macOS needs the sandbox entitlement `com.apple.security.print` in `macos/Runner/{DebugProfile,Release}.entitlements` (added by me). If the package misbehaves on a platform I fall back to the "not available" toast on it.
- Font: the PDF needs a TTF with ₹ and €. Roboto Condensed Regular + Bold (already in `test/fonts`, OFL, checked: contains ₹ € $ £ · —) are copied to `assets/fonts/` and added to the pubspec assets so printing works offline (google_fonts stays UI-only, DEC-044).

## Design (Task A)
- Keep `PrintService` in `core/services/` (where `BeepService`, `ReceiptShareService` live). New contract: `bool get supported`; `Future<PrintOutcome> printReceipt(ReceiptDocument, {required int paperMm})`; `enum PrintOutcome { sent, unsupported, failed }`. `RecordingPrintService` stays for tests (records document + paperMm).
- `core/services/print/`:
  - `receipt_print_model.dart` (plain Dart): `ReceiptDocument` + paper width -> a list of print rows (centered text, two-column row, divider, bold/large flag). Pure data, no Flutter/pdf. Holds all content decisions (India: tax row + CGST/SGST parts; VAT: tax row only; no regime: no tax row; free/gift lines at 0 with their note; store header/footer; Money via `MoneyFormatter`).
  - `receipt_pdf_builder.dart`: model -> PDF bytes with `pdf` (page width = paperMm, height grows with content, 3 mm margins, bundled Roboto Condensed).
  - `system_print_service.dart`: builds the PDF and calls `Printing.layoutPdf` (web: the browser print dialog for the receipt-only PDF, no app chrome; Windows/macOS/Android/iOS: the system dialog). Any exception -> `failed`, never a crash.
  - `unsupported_print_service.dart`: `supported == false`.
  - `print_service_factory.dart` with conditional imports (`_stub` unsupported, `_io` picks System on Windows/macOS/Android/iOS/Linux else Unsupported, `_web` picks System). Binding uses `createPrintService()`.
- `ReceiptController.print()`: builds the document (as today), reads `SettingsController` `printPaperMm`, calls the service once, shows a toast on `unsupported` ("Printing is not available on this platform") and on `failed` ("Could not print"). Strings in `AppStrings`. The view has no print logic.
- Setting: `AppSettings.printPaperMm` (int, default 80), key `print_paper_mm` in the existing `settings` table (via `StorageKeys`, repositories and migrator copy it like the other keys; existing installs read the default when the row is missing). No UI to change it now (Settings page unchanged). Thermal printer, cash drawer, ESC/POS: untouched interfaces only.

## Tests (Task A)
- `ReceiptBuilder`/print model unit tests: India (GST + CGST/SGST, odd minor unit goes to SGST), VAT store (VAT only, no GST text), no regime (no tax row), free-item line at 0 with its note, discount line, odd amounts, UGX (no decimals), INR lakh grouping.
- Fake `PrintService` test: Print in the receipt dialog calls it exactly once with the right document and paper width; the same through Reprint -> row -> Print and through Print draft; `unsupported`/`failed` show the toast and do not throw.
- Platform fallback: factory/unsupported service returns `unsupported`; controller toasts.
- PDF builder: bytes start with `%PDF`, MediaBox width = 80 mm (226.77 pt) and 58 mm for the other setting.
- Golden: ONE new golden, `print_receipt_80mm_light`, of the print model drawn by a small Flutter preview widget in `test/support` at 80 mm width (light only). It checks content and row structure, not PDF pixels (PDF rasterising needs the native plugin, not available in VM tests). No existing golden changes from Task A.

## Task B1: KG-218, compact CGST/SGST row
- Bill Summary tax block becomes: `GST Amount ... ₹34.91` (unchanged row) then ONE row with two equal columns inside the same card padding: left `CGST  ₹17.45`, right `SGST  ₹17.46`. Each column is label (muted, `rowFont`, same style as the other labels) on the left and bold value (`rowValueFont`) right-aligned in its half; values scale down instead of overflowing. VAT / no split: unchanged (no row). Generic for N split parts (N equal columns).
- Height: a new metric `splitRowHeight` per density (normal 22, compact 20, tight 18; the 13 px font needs about 16), smaller than the 28 px normal row, because one full row cannot fit at 1280x720 (the column was already full there). Receipt and print layout keep CGST and SGST as separate rows (paper width has room).
- Acceptance: a layout test at 1280x720 (and the existing summary layout matrix) asserts the India Bill Summary has no vertical scroll and the quick actions are fully visible. If after shrinking the row towards 16 px it still does not fit at 1280x720 I STOP and report the exact overflow in px (no other layout change is allowed).
- Goldens regenerated (only those that show the India Bill Summary tax block; diff area = the tax block and everything below it in the right panel, shifted up): the same 33 India goldens that changed last time except those with no summary, i.e. `shell_pos_*`, `pos_one_line_*`, `shell_{customers,products,sales,reports,returns,returns_matched,settings}_light`, `offers_*` (6), dialogs over the POS (`add_customer`, `counter_dialog`, `customer_picker`, `dialog_profile`, `dialog_shift_close`, `discount_drawer`, `price_check`, `recall_dialog`, `reprint`, `scan_dialog`, `search_results`, `shortcuts`, `shell_dialog_toast`). The exact list and a measured diff box for each go in the report. The VAT/no-forex goldens must stay byte-identical; any golden whose diff leaves the right panel (except dialogs drawn over it) = STOP.

## Task B2: hardcoded currency leftovers
- "Flat amount ₹": already uses the active currency symbol (`discountTabFlat(form.currencySymbol)`, DEC-132); I add a test with a UGX cart ("Flat amount USh") and change nothing in lib.
- Total Value tile: `StatTile` gets an optional text glyph. Currency code -> Lucide glyph map in `AppIcons` (INR indianRupee, USD dollarSign, EUR euro, GBP poundSterling) so INR/USD/EUR keep an icon (INR golden byte-identical); any other currency (UGX, KES, AED...) draws the symbol from the `currencies` row as text in the same size and colour. No other tile change.
- Docs: KG-219 loses the rupee-icon part (the INR fallback part stays, so the entry is rewritten, not deleted). KG-208 is NOT fully fixed by this (eyebrow, receipt brand, search hints, sale prefix, payment modes remain): I drop only its already-fixed items (forex list, tax label) and keep it.

## Checks
- `dart format`, `flutter analyze` clean after each part; tests per touched folder; full VM suite once at the end; no Chrome tests.
- Debug click-through, normal and `--semantics`, 66 steps each (the summary scroll workaround added to `debug_check.mjs` last time is removed if the row now fits).
- Release web build (`DEMO_SEED`, cashier1): click Print in the receipt dialog after a checkout and in Reprint -> sale -> Print. The browser print dialog cannot open headless, so the check injects (Page.addScriptToEvaluateOnNewDocument, all frames) a hook on `window.print` and counts calls; I report whether exactly one call was seen and whether the generated PDF iframe was present. If the package's iframe is not observable I say so. Not checked: Windows, iPad/Android, macOS dialog (entitlement added but not exercised), real paper, thermal printers.

## Docs and commit
decisions (print model, packages and why not latest, paper setting, trigger points, no print shortcut exists, compact split row), known_gaps (no paper-width UI, print golden covers the model not PDF pixels, Reprint needs two clicks, receipt print uses current regime KG-216, packages not verified on Windows/tablet), progress, plan doc. Commit locally, no push, exact message:
```
Add system print for the bill
Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Ht6ZfVLgoUbcN2eKphKPqq
```
Final report: what prints from where, per-platform behavior, packages added, what was not verified.

## Stop rules
A package fails the Windows/macOS/web rule; an unrelated golden changes; the compact row cannot make 1280x720 fit; a trigger point conflicts with how the app works in a way not settled above.
