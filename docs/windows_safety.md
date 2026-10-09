# Windows and web safety review (S7)

Date: 2026-10-09. This Mac cannot build Windows (`flutter build windows` runs on Windows only), so everything below is a static review plus what the web and VM runs prove. Items marked "not verified here" must be checked on a Windows machine with the checklist at the end.

## 1. Platform-specific code in `lib/`
Grep of the whole of `lib/` for `dart:io`, `Platform`, `File(`, `Directory`, `path`, `kIsWeb`, `dart:html`, `dart:js`, `package:web`, window management, printing and file access:

| Use | Where | Web behaviour | Windows behaviour | Verdict |
|---|---|---|---|---|
| `dart:io`, `Platform.*`, `File`, `Directory`, `path` | nowhere in `lib/` | n/a | n/a | none to review |
| `kIsWeb`, `dart:html`, `dart:js`, `package:web` | nowhere in `lib/` | n/a | n/a | none |
| `defaultTargetPlatform` | `core/shortcuts/shortcut_help.dart:31`, `modules/shell/widgets/top_bar.dart:132,187`, `modules/shell/widgets/shortcuts_dialog.dart:22` | derived from the browser user agent: `⌘K` on macOS, `Ctrl+K` elsewhere | `Ctrl+K` | safe, label only; both Ctrl and Cmd work everywhere |
| Conditional import `core/routes/url_strategy.dart` -> `dart.library.js_interop ? url_strategy_web.dart : url_strategy_stub.dart` | `lib/main.dart` calls `configureUrlStrategy()` | path URLs (`/products`) via `flutter_web_plugins` | stub, no-op | safe; `flutter_web_plugins` is imported only in the web file |
| Persistence | `SharedPrefsLocalStore` (`shared_preferences`) | localStorage, keys prefixed `flutter.` | `%APPDATA%\com.agile\pos_application\shared_preferences.json` (company and product name from `windows/runner/Runner.rc`: `com.agile`, `pos_application`) | safe; the data folder follows those names, set the final ones before real use |
| Fonts | `AppTypography` -> `google_fonts` (Roboto Condensed) | downloaded from fonts.gstatic.com at start (about 358 KB measured) | downloaded once and cached with `path_provider` | **offline risk**: a first start without internet falls back to another font (KG-175); bundling is a one-file change (DEC-044) |
| Printing | `PrintService` interface, `RecordingPrintService` stub | no print | no print | no platform code to review; real printing is Phase B (needs a Windows spooler or `window.print()` implementation) |
| Email / WhatsApp | `ReceiptShareService` stub | demo toast | demo toast | none |
| Window management | none (no window manager package) | browser window | Win32 runner default 1280x720, title "pos_application", **no minimum size** | the user can shrink the window under 900 px: overflow, see `responsive_report.md`; a minimum size needs runner C++ (`WM_GETMINMAXINFO`) or a window package (approval needed) |
| Audio (scan beep) | `NoopBeepService` stub | none | none | none |

Placeholders left from the project scaffold (not code risks): `windows/runner/main.cpp` window title "pos_application"; `web/manifest.json` has `orientation: portrait-primary`, description "A new Flutter project." and theme colour `#0175C2` (the target is landscape: change before installing the web app as a PWA).

## 2. Packages (versions locked in `pubspec.lock`; latest and platforms from the pub.dev API on 2026-10-09)

| Package | Locked | Latest (published) | Windows | macOS | Web | Android | iOS | Role |
|---|---|---|---|---|---|---|---|---|
| get | 4.7.3 | 4.7.3 (2025-11-24) | yes | yes | yes | yes | yes | state, routes, DI. Latest is 10 months old: maintenance watch |
| google_fonts | 6.3.3 | 9.0.0 (2026-09-28) | yes | yes | yes | yes | yes | Roboto Condensed (3 majors behind; upgrade when fonts are bundled) |
| lucide_icons_flutter | 3.1.22 | 3.1.22 (2026-10-05) | yes | yes | yes | yes | yes | icons (font, tree-shaken in release) |
| shared_preferences | 2.5.5 | 2.5.6 (2026-10-05) | yes | yes | yes | yes | yes | LocalStore |
| flutter_web_plugins | SDK | SDK | web file only | web file only | yes | web file only | web file only | URL strategy (conditional import) |
| flutter_lints (dev) | 6.0.0 | n/a | n/a | n/a | n/a | n/a | n/a | lints |
| shared_preferences_windows | 2.4.1 | 2.4.1 (2024-08-09) | yes | | | | | pure Dart plugin, JSON file |
| shared_preferences_foundation | 2.5.7 | 2.5.7 (2026-08-28) | | yes | | | yes | |
| shared_preferences_web | 2.4.3 | 2.4.3 (2025-02-18) | | | yes | | | |
| shared_preferences_android | 2.4.23 | 2.4.28 (2026-08-28) | | | | yes | | |
| shared_preferences_linux | 2.4.1 | 2.4.1 (2024-08-09) | | | | | | Linux only |
| path_provider (via google_fonts) | 2.1.6 | 2.1.6 (2026-06-15) | yes | yes | no (google_fonts does not call it on web) | yes | yes | font cache |
| path_provider_windows | 2.3.0 | 2.3.0 (2024-07-09) | yes (FFI) | | | | | |
| path_provider_android | 2.3.1 | 2.3.1 (2026-04-08) | | | | yes | | pulls `jni` |
| path_provider_foundation | 2.6.0 | 2.6.0 (2026-01-15) | | yes | | | yes | pulls `objective_c` |
| jni | 1.1.0 | 1.1.0 (2026-10-01) | yes (FFI plugin) | no | no | yes | no | transitive (via path_provider_android); builds natively on Windows: **not verified here** |
| jni_flutter | 1.0.4+1 | 1.0.4+1 (2026-10-06) | no | no | no | yes | no | Android only |
| objective_c | 9.5.0 | 9.6.2 (2026-10-01) | yes | yes | no web build needed | yes | yes | Apple FFI, transitive |
| ffi | 2.2.0 | 2.2.0 (2026-02-11) | yes | yes | no | yes | yes | |
| http, crypto | 1.6.0, 3.0.7 | same | yes | yes | yes | yes | yes | google_fonts |

Platform support is the pub.dev platform tag of each package; "current" is the publish date above. Nothing needed to be flagged as unmaintained; `get` is the slowest (10 months).

## 3. Is Windows enabled in the project?
- `windows/` is in git (runner, CMake, `flutter/` registrants); `.metadata` lists `platform: windows`.
- `windows/flutter/generated_plugin_registrant.cc` registers no native plugins (correct: `shared_preferences_windows` and `path_provider_windows` are Dart/FFI only) and `generated_plugins.cmake` lists the FFI plugin `jni`. These files are regenerated by `flutter pub get` on Windows.
- `flutter config` on this Mac shows `enable-windows-desktop` not set (it only applies on a Windows host); `flutter devices` lists only macOS and Chrome here.
- Risk to confirm first on Windows: the `jni` FFI plugin is pulled in only because `path_provider_android` depends on it, but the Windows build still compiles it. If it fails, the options are a `dependency_overrides` pin or replacing `google_fonts` with bundled fonts (which removes `path_provider` and so `jni`).

## 4. Checklist to run on a Windows machine
1. Install Flutter 3.38.x (the version used here is 3.38.4) and Visual Studio 2022 with "Desktop development with C++"; `flutter doctor` must show Windows (Visual Studio) green.
2. In `pos_application/`: `flutter config --enable-windows-desktop`, `flutter pub get`, `flutter analyze` (expect 0 issues), `flutter test` (expect the full suite to pass; the tests are VM tests).
3. `flutter build windows --release`: expect no error from `jni`; note any. Then `flutter run -d windows`.
4. Click through: POS add items (catalog click and top-bar search), F2 cash payment with Exact, receipt dialog; F4 hold, F5 recall; F6 discount; Esc closes; Ctrl+K focuses search (label shows `Ctrl+K`); Customers (Add Customer), Products, Sales ("View receipt"), Returns (refund a bill), Reports, Settings (dark mode and beep), Profile, Close counter -> Counter closed -> Start new shift.
5. Quit and start again: dark mode, cart, held bills, sales persist (file under `%APPDATA%\com.agile\pos_application\`).
6. Fonts: start once online (Roboto Condensed downloads), then once with the network off: note the fallback font.
7. Resize the window from 1900 wide down to 900 and below: nothing may overflow at 900 or more; below 900 the POS page overflows (known, `responsive_report.md`).
8. Keys: F-keys work without Fn on a desktop keyboard; check on a laptop with and without Fn-lock.
