# Performance and build size (S7)

Date: 2026-10-09. Machine: the development Mac (Apple Silicon, other programs running). Browser numbers come from `tool/web_check/perf.mjs` (headless Chrome 154 over the DevTools protocol, SwiftShader software GL, `flutter build web` release, cache disabled). VM numbers come from the VM tests (`flutter test`). All numbers vary from run to run; the medians of 3 cold starts are given.

## What could and could not be measured
| Asked | Result |
|---|---|
| Time to first paint | measured (cold, 3 runs) |
| Typing in the search box with the dropdown | measured as main-thread frame gaps |
| Scrolling the catalog | measured as frame gaps (software rendering, pessimistic) |
| Adding 50 items | measured with Enter on barcodes; **only the 20 seed products exist in the browser build**, so 50 adds = 20 lines with increasing quantities, not 50 distinct lines |
| Opening Products / Customers / Sales | Products 20 rows, Customers 10,000 rows, Sales 10,000 rows measured in the browser |
| **10,000 products in a real browser** | **not measured**: `LargeDataset` is debug-only (your decision: no code change); the 10k-product numbers are VM numbers only |
| Real GPU, Windows, tablet, touch | not measured (headless Chrome uses SwiftShader) |
| "Dropdown visible" | canvas content is not in the DOM: the metric is the longest main-thread gap after the key press, not a pixel check |
| Memory growth over a long session | not measured (single-session JS heap snapshots only) |

How the browser numbers are taken: a `requestAnimationFrame` recorder runs from page start; a gap longer than 17 ms means the main thread was busy. Each action is bracketed with page-clock marks; the window after the action (500 to 1500 ms) is analysed. Frames counted in a window show how many frames the page managed; with software GL the idle page draws 60 fps but a busy canvas draws far fewer.

## Browser results (1280 x 720, release build)
Cold start (3 runs, cache off, with the page, CanvasKit from `www.gstatic.com` and Roboto Condensed from `fonts.gstatic.com`):

| Metric | 20 products, empty ledgers | + 10,000 customers and 10,000 sales in localStorage |
|---|---|---|
| Flutter view present (`flt-glass-pane`) | 5.2 / 5.9 / 5.6 s, median **5.6 s** | median **4.8 s** |
| First paint = first contentful paint | 9.2 / 10.3 / 9.6 s, median **9.6 s** | 8.9 to 9.3 s, median **9.2 s** |
| JS heap after start | 27 to 29 MB | 48 to 50 MB |
| Network | CanvasKit 1,620 KB, Roboto Condensed 359 KB, app 19 KB (local file sizes are not counted by the probe, see sizes below) | same |

With `--no-web-resources-cdn` (CanvasKit served locally, no CDN download) the median first paint is **9.1 s**: the 9 s is CPU and software rendering in headless Chrome, not the network. Do not read 9 s as a user number; on real hardware it will be far lower, and I cannot give that number here.

Interactions (one session after start, 20 products; the big-data column repeats it with 10,000 customers and sales loaded):

| Action | 20 products / small ledgers | with 10,000 customers and sales |
|---|---|---|
| Type "lays" in the top search (dropdown): longest frame gap per key | 33, 17, 17, 17 ms (no gap over 50 ms) | 33, 17, 17, 17 ms |
| Scroll the catalog, 60 wheel events | 8 to 9 frames in 600 ms, longest gap 183 ms, 2 gaps over 50 ms | same |
| Add 50 items (Enter on barcodes) | 4.7 s total, median 49 ms per add, slowest 410 ms; heap 33 to 52 MB | 3.8 s total, median 44 ms, slowest 161 ms |
| Open Products by sidebar click | 70 frames in 1.5 s, longest gap 117 ms | longest gap 133 ms |
| Open Customers | longest gap 33 ms | **10,000 rows: longest gap 350 ms** (one frame) |
| Open Sales | longest gap 33 ms | **10,000 rows: longest gap 17 ms** |
| Scroll the open Sales table, 60 wheel events | longest gap 17 ms | longest gap 17 ms |
Reading: typing, table opening and table scrolling are smooth (only a lazily built screenful exists); the catalog scroll and the add-to-cart bursts show gaps of 160 to 270 ms in this software-rendered browser. Whether the catalog scroll is raster-bound or Dart-bound needs a real GPU or the profile build with DevTools; I could not separate them here.

## VM numbers with 10,000 rows (Dart VM, same Mac, one suite at a time)
| Action | Time |
|---|---|
| Products: decode and index 10,000 | 74 ms |
| Catalog controller init (index and first filter) | 8 ms |
| Catalog text filter | 1.7 ms |
| Category switch | 0.8 ms |
| Add to cart (reducer, totals, notify) | 0.6 ms |
| Favourite toggle in memory / persisted | 3.4 ms / 37 ms (UI thread) |
| Open Products page (10,000 rows, index and first frame) | 250 ms (170 ms in S5.a) |
| Open Customers (10,000) | 140 ms |
| Open Sales (10,000) | 260 ms, 8 rows built |
| Open Reports (10,000 sales) | 150 ms |
| Filters on those tables | 1 to 5 ms |
| Returns bill lookup per keystroke | 0.01 ms (index built once: 455 ms with the page under load) |
| ShiftSummary over 10,000 sales | 12 to 22 ms |
Rows built stay under 60 of 10,000 everywhere (lazy lists).

## Release web build size (`flutter build web`, 3.38.4)
| Part | Size |
|---|---|
| `build/web` total | 33 MB |
| `main.dart.js` | 2.80 MB raw, 819 KB gzip -9, **635 KB brotli** |
| `canvaskit/` (all renderer variants shipped) | 26.8 MB: `canvaskit.wasm` 7.08 MB, `chromium/canvaskit.wasm` 5.71 MB, `skwasm.wasm` 3.55 MB, `skwasm_heavy.wasm` 5.05 MB (a browser downloads one variant: canvaskit.wasm 7.08 MB raw, 2.2 MB brotli, 2.85 MB gzip) |
| `assets/` | 4.4 MB: `lucide_icons_flutter` fonts 2.9 MB (see below), `NOTICES` 1.34 MB, product images 188 KB, Material icons font 7.7 KB |
| Lucide icon font used by the app | **14,300 bytes** (tree-shaken from 910,776 bytes, 98.4 %) |
| Six variable Lucide fonts `LucideVariable-w100..w600.ttf` | 2.9 MB in the build output although the app never loads them (the package declares them as assets); a browser never downloads them, they only add to the folder and to installers |
| Material icons font | 7,736 bytes (from 1,645,184, tree-shaken) |
| Roboto Condensed (runtime, google_fonts) | about 359 KB over the network per cold start (not in the build) |
| CanvasKit from the CDN | 1.6 MB over the network at start (unless built with `--no-web-resources-cdn`) |

## Proposed reductions (NOT applied)
1. Bundle Roboto Condensed as an asset (the 359 KB fetched at start is the size to expect for the weights in use) and drop the runtime fetch: needed for offline use anyway (KG-175); removes `google_fonts`, `path_provider` and with them `jni` from the Windows build.
2. Build with `--no-web-resources-cdn` for kiosk or offline installs, and serve with brotli (main.dart.js 2.8 MB -> 635 KB, canvaskit.wasm 7.1 MB -> 2.2 MB).
3. Keep only the renderer variant needed: delete `skwasm*` and `chromium/` from the deployed folder (about 14 MB) if the skwasm renderer stays unused.
4. Product images: re-encode the 12 PNGs (188 KB) as WebP; small gain.
5. The six unused variable Lucide fonts (2.9 MB in the output): ask the package for an opt-out, fork it, or replace the package with a trimmed icon font generated from the 41 icons in `AppIcons`.
6. `--pwa-strategy=none` if offline caching is not wanted, and remove `assets/NOTICES` licences only if the licence terms allow it (they do not by default: keep).
7. Consider the WebAssembly build (`--wasm`, skwasm) for faster first paint where the target browsers support it; needs a measurement on the real target.
8. Defer rarely used dialogs (receipt, Returns, Reports) with deferred imports if the 635 KB brotli main bundle ever matters.
