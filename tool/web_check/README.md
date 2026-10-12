# Real-browser check (no packages, no pubspec change)

**Entry flow switch.** The app starts on a demo splash and login. Every check that loads the page and expects the POS screen needs a build or run with `--dart-define=SKIP_ENTRY=true` (`flutter build web --dart-define=SKIP_ENTRY=true`, `flutter run ... --dart-define=SKIP_ENTRY=true`); this covers `cdp.mjs`, `debug_check.mjs`, the flow checks, `drift_check.mjs`, `theme_check.mjs`, `startup_check.mjs`, `perf.mjs` and the products checks. To check the real flow, build WITHOUT the define and use `debug_check.mjs ... --entry` (see `entry.mjs`) or screenshots of `/` through `cdp.mjs`.

Drives the served release build in headless Chrome over the DevTools protocol:
clicks, typing, screenshots and the console. Needs macOS Chrome and Node 20+.

```
flutter build web
python3 tool/web_check/serve.py build/web 8098 &          # SPA fallback server
node --experimental-websocket tool/web_check/cdp.mjs \
  http://127.0.0.1:8098/ /tmp/shot \
  '[{"wait":9000},{"move":[275,500]},{"click":[275,500]},{"wait":2500},{"shot":"a"}]'
```

Actions: `wait` (ms), `move` / `click` `[x, y]` (CSS px of the 2124 x 1180
viewport), `type` (text), `key`, `shot` (name; writes `<out>_<name>.png`).
The console (errors, exceptions, logs) is printed at the end. WebGL runs on
SwiftShader; without it headless Chrome draws no images.

Window size: pass `width height` (CSS px) after the actions, e.g. `... '[...]' 1100 700`.
The release build prints no "overflowed" errors; for those use the debug build
(`flutter run -d web-server --web-port=8097`) and the same script on port 8097:
the script prints how many overflow errors the console showed.

## Debug-build click-through (`debug_check.mjs`)
Release builds hide debug-only errors ("setState() or markNeedsBuild() called during build", overflow reports, error widgets). `debug_check.mjs` drives a DEBUG `flutter run -d web-server` session through every route and dialog with seeded data and fails on any console error or red screen:

```
flutter run -d web-server --web-port=8170 --web-hostname=127.0.0.1    # wait for "is being served"
node --experimental-websocket tool/web_check/debug_check.mjs http://127.0.0.1:8170/ /tmp/dbg_out
```
The debug dev server serves ONE page load per `flutter run`: start a fresh server for every run and stop it afterwards. Exit code 1 on any failure; `FAIL_*.log` and a screenshot per step are written to the output folder.

## Drift flow checks (D1 to D5)
`drift_check.mjs` (worker, wasm, schema version and every table's marker; `--seed-duplicates`), `customers_flow_check.mjs`, `held_flow_check.mjs`, `products_flow_check.mjs`, `sales_flow_check.mjs` (a member's cash sale and two refunds through the UI, then the rebuilt SQLite file and the LocalStore mirrors) and the timeline checks `products_10k_check.mjs` (10,000 products, checkout receipt, transaction and mirror timings) and `startup_check.mjs` need `flutter build web` (timeline checks: `--dart-define=STARTUP_TIMELINE=true -o build/web_timeline`) served with `serve.py`; each starts a fresh Chrome profile and exits 1 on a mismatch.

