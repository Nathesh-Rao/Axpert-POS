# Codex workflow on axpert_pos: what it did, what we adopt

Sources: axpert_pos (AGENTS.md, docs/testing, git history, build artifacts: read only), the Codex session log of 2026-09-24 (`~/.codex/sessions`, read only; ONLY shell command lines and timestamps were extracted, no prompts or code, no auth/config files), and timings measured by running axpert_pos's commands in a COPY under `/tmp` (deleted afterwards; the original was not touched). Everything marked (inference) is not recorded anywhere.

## 1. What Codex actually did (from its own log)
- One session file: 800 `exec` tool calls, 35 tasks (median 22 min; a few minutes to many hours), 231 exec calls ran flutter/dart commands.
- **After almost every change it ran ONE chained command: `dart format --output=none --set-exit-if-changed . ; flutter analyze ; flutter test`** (analyze 67x, full `flutter test` 65x, format check 60x). The baseline three commands from `docs/testing/testing-strategy.md` were the whole loop.
- Targeted runs were the exception (about 30 of ~100 test runs): `flutter test <file(s)>`, `--plain-name`, `--reporter expanded`, mostly while fixing one widget test. Selection by path only (no tags).
- `dart format <touched files>` (plain, rewriting) while editing; the check form only in the chained command.
- `flutter build web --no-pub` 19x (web was the target platform it built; no Windows/Android build), `dart run build_runner build --delete-conflicting-outputs` 11x (only when Drift tables changed), `flutter pub get` 13x, `flutter pub add` for get/dio.
- Reported chained-loop durations when the call finished in one go: 4-20 s (typical 9-10 s) in the early, small project; a final full run late in the session took about 265 s once. (The log records call-to-output time; calls that returned early to a background session show 0.2-1.2 s and are not durations.)
- No goldens, no browser click-through, no layout sweeps, no Chrome tests in the log.
- Commits: 2 in the repo (init, "PHASE 0 COMPLETE — HUMAN REVIEW REQUIRED", docs only); all later work uncommitted. Phase = a doc with acceptance criteria; the human gate is the phase-complete commit.

## 2. Measured today (this machine, 2026-10-12)
| Command | axpert_pos (copy in /tmp, 21 test files, 60 tests) | pos_application (949 tests) |
|---|---|---|
| `flutter pub get` | 2.6 s | not timed |
| `dart format --set-exit-if-changed .` | 0.6 s | 0.6 s |
| `flutter analyze` | 3.4-3.6 s | 1.8-2.6 s |
| full `flutter test` | 41-44 s (cold and warm; mostly sqlite3 native-assets startup and widget tests) | 3:23-3:26 |
| one feature folder | 11 s (`test/features/cart`) | module folders 5-40 s; goldens folder ~37 s; route+semantics guards 7-9 s |
| debug click-through (both modes) | none | about 5-6 min each (estimate) |
So the chained baseline costs about 50 s in axpert_pos today and about 3.5 min in ours; Codex's 10-20 s loop was the smaller early project.

## 3. Bottlenecks
- Ours: the full VM suite (3.5 min), goldens (~40 s), debug click-through (fresh dev server per run), release builds, Chrome-compiled tests (already dropped). Running the FULL suite after every change would be the slow habit; Codex's loop was fast because the full suite was cheap, not because it skipped it.
- axpert_pos: Drift/sqlite3 native-asset startup dominates its test time; first run after `pub get`/hook build is the slowest.

## 4. Command checklist (adopted for the integration stages and in CLAUDE.md)
| Level | When | Commands |
|---|---|---|
| Change | after each edit | `dart format <touched files>`; `flutter analyze` (whole project, ~2 s); `flutter test <touched file or folder>` |
| Feature | a screen/controller/service is done | + the module's whole test folder; `test/layout/route_navigation_test.dart`; `test/layout/semantics_reparent_test.dart` when widget structure changed; goldens of touched screens (byte-identical unless approved); codegen only if Drift tables changed (`dart run build_runner build --delete-conflicting-outputs`) |
| Milestone | end of a batch/stage | `dart format --output=none --set-exit-if-changed .`; `flutter analyze`; full `flutter test` ONCE; debug click-through (both modes) when bindings, bootstrap or widget structure changed; release web build when packages or web assets changed |
| Finish | end of the integration | all of the above + release `web_check` at 950x733 / 1280x720 / 1868x1035 for new screens + macOS debug launch + final report; Windows cannot be built here (say so) |
Never rerun a check on unchanged code; no cache clearing or reinstalls without a reason; never claim a result that was not seen.

## 5. Adopt / adapt / cannot reproduce
- **Adopt as is:** the three baseline commands as the milestone gate; path-targeted tests; tests mirroring `lib/` by layer and feature; pure-unit-first tests with in-memory Drift; stage docs with acceptance criteria and a review gate; decisions recorded as ADR/DEC; generated code committed, never hand-edited; one chained command when all three are needed.
- **Adapt:** use the format CHECK form only at milestones (plain `dart format <files>` while editing); run the full suite at stage/batch ends, not per change (ours is 3.5 min); keep per-checkpoint local commits only when the owner says "commit" (axpert had 4 days of uncommitted work, a poor rollback story).
- **Cannot reproduce / unknown:** Codex's sandbox, approval and parallel tool behaviour (Claude Code tooling differs; any speed it gave is not observable here); its per-task command history beyond what the log shows; its goldens/click-through habits (none existed, our rules require them because they caught real bugs: build-time updates, web semantics).
