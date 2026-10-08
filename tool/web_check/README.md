# Real-browser check (no packages, no pubspec change)

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
