# Cleanup note: `reference_react/` and `CLAUDE.md` (reduced preparation, 2026-10-09)

Reduced preparation (owner's decision): nothing from `reference_react/` or `reference_screenshots/` was copied into the repository, no tool was repointed, nothing is deleted. The docs that mention the folders carry a note that the generators and the compare tool need them and stop working after removal; the generated fixtures stay committed. A Phase B `CLAUDE.md` for `pos_application/` was proposed to the owner (before/after diff); it is written only after approval, and the workspace one is kept.

## What stops working when `reference_react/` and `reference_screenshots/` are removed
| Tool or file | Needs | Effect after removal |
|---|---|---|
| `tool/golden/gen_vectors.mjs` | `../reference_react/src/data.ts` (transpiled with `npx esbuild`) | cannot regenerate `test/fixtures/pricing_golden.json` and `pricing_golden_data.g.dart` |
| `tool/golden/gen_s6_vectors.mjs` | `../reference_react/src/data.ts` and `App.tsx` | cannot regenerate `test/fixtures/s6_golden.json` and `s6_golden_data.g.dart` |
| `tool/compare/compare_reference.py` | `../reference_screenshots/` | cannot repeat `docs/final_comparison.md` |
| Docs that mention the folders | `docs/css_metrics.md`, `decisions.md` (DEC-010, DEC-025), `migration_plan.md`, `plan_s1_s2.md`, `plan_s3.md`, `plan_s4_0.md`, `react_audit.md` (its line ranges point into `App.tsx` and `index.css`), `final_comparison.md`, `phase_b_backlog.md` | references become dead |

What keeps working: the app, every test (no test reads a file outside `pos_application/`; two comments mention the folders), the committed fixtures, the goldens.

## Moving `CLAUDE.md`
It lives in `pos_workspace/` (outside git). If it is moved into `pos_application/`, the paths with the `pos_application/` prefix and the `reference_*` rules in it must be edited, and the Claude Code memory (keyed to the workspace folder) must be copied for the new project folder. Not done.
