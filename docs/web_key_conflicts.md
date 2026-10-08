# Web key conflicts (S6)

Engine fact (Flutter SDK `keyboard_binding.dart`): when the framework handles a key-down the engine calls `preventDefault()`. All our bindings return "handled" (including Esc and Delete only when they act). Whether a browser OBEYS preventDefault is the browser's choice; `tool/web_check` sends synthetic DevTools key events, which cannot trigger browser-level shortcuts, so every row below is **needs manual test in real Chrome** (and Edge/Firefox if used). No binding was changed (rule: ask first).

| Key | Browser / OS default | preventDefault can stop it? | Windows desktop app | If it fails on web |
|---|---|---|---|---|
| F5 | reload | yes in Chrome, Edge, Firefox, Safari in practice | no conflict | options A/B |
| F6 | focus address bar / next pane | probably in Chrome, less certain elsewhere | none | options A/B |
| F3 | find next / find bar | yes in Chrome and Firefox | none | options A/B |
| F4 | none in the page (Alt+F4 / Ctrl+F4 are other chords) | n/a | none | none |
| F2 | none | n/a | none | none |
| Ctrl+K | Chrome and Edge on Windows/Linux: address-bar search; Firefox: search bar | yes | none | none |
| Cmd+K | none in Chrome/Safari on macOS | n/a | n/a | none |
| Esc | stops loading, leaves fullscreen | harmless | none | none |
| Delete | none | n/a | none | none |
| Tab (last control) | browser focus moves to the address bar | Flutter keeps focus in its own order; behaviour at the ends untested | none | none |
| F1 to F12 on laptops (web and macOS desktop) | media keys unless Fn is held or "Use F keys as standard" is on | no | same on Windows laptops with Fn-lock | user setting, or options |

Options (choose after the manual test): **A** keep the F-keys and add a help note ("on laptops hold Fn"); **B** web only: accept an alternate chord next to the F-key (for example Alt+1 to Alt+5 for cash, card, hold, recall, discount), shown in the help and tooltips so the hints match the real binding; F-keys stay on Windows, macOS and tablet; **C** web only: Ctrl/Cmd+Shift+letter chords. Recommendation: A now, B only for the keys that fail.

## Manual test list (real Chrome, production build, focus inside the page)
1. F5 with items in the cart: the Recall dialog opens and the page does NOT reload.
2. F6: the discount drawer opens and the address bar is NOT focused.
3. F3: the card payment dialog opens and the find bar does NOT appear.
4. F2: cash payment dialog; F4: "Hold" toast (or "Add items before holding a bill").
5. Ctrl+K (Cmd+K on macOS): the search box is focused, the browser's address-bar search does NOT open; also from inside another input.
6. Esc closes a dialog; Delete removes the selected cart line (not while typing).
7. Tab from the last control of a page: focus stays inside the app (or note where it goes).
8. Repeat 1 to 3 with the cursor inside the search box and inside a dialog input.
9. Repeat 1 to 5 in Edge and Firefox if you use them; on a laptop check F-keys with and without Fn.
