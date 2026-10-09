# Axpert-POS

Point-of-sale application (Flutter, GetX) for Windows desktop, web, tablet and macOS.
Phase A, the one-to-one migration of the React prototype, is complete (tag
`phase-a-complete`); Phase B, production development, continues from there.

## Where to look

- `CLAUDE.md`: working rules and conventions
- `docs/`: migration plan, decisions (`decisions.md`), known gaps (`known_gaps.md`), Phase B backlog
- `tool/web_check/`: browser checks (debug click-through, release checks)

## Run

```
flutter pub get
flutter run -d chrome        # or macos / windows
flutter analyze && flutter test
```
