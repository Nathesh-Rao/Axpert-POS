# Cleanup checklist: removing `reference_react/` and moving `CLAUDE.md` (NOT executed)

Written 2026-10-09 in S7. **Nothing below has been done.** Each step needs your explicit OK. Sizes: `reference_react/` 424 KB (no `node_modules`), `reference_screenshots/` 2.5 MB (7 PNG files).

## 1. What reads the React sources or the screenshots
| What | Where | Needs the files at run time? |
|---|---|---|
| Tests | `test/golden/shell_golden_test.dart:2`, `test/modules/pos/seed_test.dart:6` | **No** (comments only; no test opens a file outside `pos_application/`) |
| Golden vector generator (pricing) | `tool/golden/gen_vectors.mjs` (lines 5 and 7: `../reference_react/src/data.ts`, transpiled with `npx esbuild`) | Yes, only to REGENERATE `test/fixtures/pricing_golden.json` and `pricing_golden_data.g.dart` |
| Golden vector generator (S6) | `tool/golden/gen_s6_vectors.mjs` (lines 5, 7, 24: `data.ts` for `calculate()` and `money()`, `App.tsx` to assert the inline refund and forex expressions still exist) | Yes, only to regenerate `test/fixtures/s6_golden.json` and `s6_golden_data.g.dart` |
| Comparison tool | `tool/compare/compare_reference.py:15` (`../reference_screenshots/`) | Yes, to re-run the final comparison |
| Fixtures | `test/fixtures/*.json`, `*.g.dart` | No: already committed; deleting React only blocks regenerating them |
| Docs that mention the folders | `docs/css_metrics.md:3` (source of truth `reference_react/src/index.css`), `docs/decisions.md:11,30` (DEC-010, DEC-025), `docs/migration_plan.md:3,13`, `docs/plan_s1_s2.md:5,27,98`, `docs/plan_s3.md:47`, `docs/plan_s4_0.md:49`, `docs/react_audit.md:3,4,40` (the audit's line ranges in section 9 point into `App.tsx` and `index.css`), `docs/final_comparison.md:3`, `docs/phase_b_backlog.md` (copies DEC-025) | No (text only), but the references become dead |
| Product images | `reference_react/public/products/*.png` = the 12 images of `assets/products/` (188 KB each side) | No: the app has its own copy |

## 2. Keep before deleting (copy into `pos_application/`, then commit)
1. **React sources for the generators and the CSS audit** (about 160 KB): `reference_react/src/data.ts` (7 KB), `src/App.tsx` (99 KB), `src/index.css` (57 KB), `src/main.tsx`, `package.json`, `index.html` -> `pos_application/tool/golden/react_src/` (or `docs/reference/react_src/`; one location). Read-only, marked "snapshot of the Phase A prototype, do not edit".
2. **The 7 reference screenshots** (2.5 MB) -> `pos_application/docs/reference/` (your decision on repository size; without them `final_comparison.md` and `compare_reference.py` cannot be repeated and the "compare against the screenshot" rule loses its source).
3. **`react_audit.md` line ranges** stay valid only if the snapshot keeps the same files unchanged: copy byte for byte.

## 3. Edits to make (in this order, after step 2)
1. `tool/golden/gen_vectors.mjs` and `gen_s6_vectors.mjs`: change `../reference_react/src/...` to the snapshot path (`tool/golden/react_src/`), update the usage comments and the "Nothing is written into reference_react" lines.
2. `tool/compare/compare_reference.py`: `REF = '../reference_screenshots/'` -> `docs/reference/`.
3. Comments: `test/golden/shell_golden_test.dart:2`, `test/modules/pos/seed_test.dart:6`.
4. Docs: replace "reference_react/" by the snapshot path in `css_metrics.md`, `react_audit.md`, `migration_plan.md`, `plan_*.md`, `decisions.md` (DEC-010, DEC-025: add a new decision rather than rewriting history, for example DEC-110 "reference moved into the repository"), `final_comparison.md`; mark `known_gaps.md` unchanged.
5. **Verification before deleting** (all must pass): `flutter analyze` 0; `flutter test` (full VM suite); regenerate both fixtures from the SNAPSHOT (`npx --yes esbuild tool/golden/react_src/data.ts --format=esm --outfile=$TMP/data.mjs`, then both generators) and `git diff --stat test/fixtures` must be empty; run `python3 tool/compare/compare_reference.py` and compare the numbers with `final_comparison.md`.
6. Only then, with your explicit OK: delete `reference_react/` and `reference_screenshots/` from the workspace (they are outside git, so this is not undoable from git; keep an archive copy outside the repo until Phase B has started).

## 4. Moving `CLAUDE.md` into `pos_application/`
Current file: `pos_workspace/CLAUDE.md` (outside git). Lines that change:
- Title and workspace block (lines 1 to 16): the "Workspace layout" with `pos_application/`, `reference_react/`, `reference_screenshots/` disappears; the repo root becomes the project root; delete lines 14 to 16 (the `reference_*` bullets and "After Phase A ... delete ... move this file").
- Working rules: rule 3 (line 29, "Use docs/react_audit.md instead of re-reading all of reference_react") and rule 7 (line 33, "Never modify `reference_react/`") become "the React snapshot under `tool/golden/react_src/` is read-only".
- UI fidelity (line 69): "Screenshot comparison happens ONLY against `reference_screenshots/`" -> `docs/reference/`.
- Paths written with the `pos_application/` prefix (lines 12, 13, 58, 88, 108): drop the prefix (`docs/`, `lib/`, `test/fixtures`).
- Git section (line 119): "Repo is `pos_application` only" -> "this repository".
- The verification and testing-speed rules (no Chrome tests, reduced matrix, web_check sizes) stay as they are.
Side effects to know:
- The Claude Code memory (`~/.claude/projects/-Users-narasimhanatheshrao-Development-pos-workspace/memory/`) is keyed to the workspace folder. If you open Claude Code from `pos_application/` the memory folder is a different one: copy `feedback_no_chrome_tests.md` and `MEMORY.md` (and the checkpoint-rules note) to the new project's memory folder, or keep opening the workspace folder.
- `pos_workspace/.vscode/settings.json` stays or moves with the folder you open.
- Anything that opens `pos_workspace/CLAUDE.md` by path (editor tabs, scripts) must point to the new file.

## 5. After cleanup
Update `docs/migration_plan.md` (S7 done, cleanup done), `known_gaps.md` (nothing), and `decisions.md` (the new DEC). Commit with the usual trailers.
