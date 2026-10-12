#!/usr/bin/env python3
"""Move Dart files with `git mv` and rewrite every import that points at them.

Usage (from the repository root, clean working tree, on a feature branch):
  python3 tool/integration/move_feature.py tool/integration/products_moves.json --dry
  python3 tool/integration/move_feature.py tool/integration/products_moves.json

The JSON file has {"moves": {"old/path.dart": "new/path.dart", ...},
"remove": ["old/.gitkeep", ...]} with paths relative to the repository root.
For every .dart file under lib/, test/ and tool/ each import/export/part
directive is resolved against the file's OLD location, mapped through the move
table, and rewritten relative to the file's NEW location (or as
`package:pos_application/...` where it already was). Nothing else is touched.
--dry prints how many files and import lines would change and which files.
After a real run: check that only import lines changed
  git diff -U0 HEAD -M | grep -E '^[+-]' | grep -vE '^(\\+\\+\\+|---)' | grep -vE '^[+-]\\s*(import|export|part) '
(no output expected), then `dart format --output=none --set-exit-if-changed .`,
`flutter analyze` and the tests. Used for the Products move (DEC-120).
"""
import json
import os
import re
import subprocess
import sys

args = [a for a in sys.argv[1:] if not a.startswith('--')]
dry = '--dry' in sys.argv
if len(args) != 1:
    sys.exit(__doc__)
spec = json.load(open(args[0]))
MOVES = spec['moves']
REMOVE = spec.get('remove', [])

all_files = []
for base in ('lib', 'test', 'tool'):
    for dirpath, _, names in os.walk(base):
        all_files += [os.path.join(dirpath, n) for n in names if n.endswith('.dart')]
for old in MOVES:
    if old not in all_files:
        sys.exit(f'not a known Dart file: {old}')
new_of = {f: MOVES.get(f, f) for f in all_files}
directive = re.compile(r"^(\s*(?:import|export|part)\s+)'([^']+)'(.*)$")
PKG = 'package:pos_application/'

changes = {}
for old in all_files:
    new = new_of[old]
    out, touched = [], 0
    for line in open(old).read().split('\n'):
        m = directive.match(line)
        if not m:
            out.append(line)
            continue
        pre, path, post = m.groups()
        if path.startswith('dart:') or (path.startswith('package:') and not path.startswith(PKG)):
            out.append(line)
            continue
        is_pkg = path.startswith(PKG)
        target = 'lib/' + path[len(PKG):] if is_pkg else os.path.normpath(os.path.join(os.path.dirname(old), path))
        new_target = MOVES.get(target, target)
        new_path = PKG + new_target[len('lib/'):] if is_pkg else os.path.relpath(new_target, os.path.dirname(new))
        if new_path != path:
            touched += 1
            line = f"{pre}'{new_path}'{post}"
        out.append(line)
    if touched or old != new:
        changes[old] = ('\n'.join(out), touched)

lines = sum(t for _, t in changes.values())
print(f'files to move: {len(MOVES)}; files with import edits: '
      f'{sum(1 for _, t in changes.values() if t)}; import lines changed: {lines}')
if dry:
    for f, (_, t) in sorted(changes.items()):
        if t:
            print(f'  {t:2d} {f}')
    sys.exit(0)
for old, new in MOVES.items():
    os.makedirs(os.path.dirname(new), exist_ok=True)
    subprocess.check_call(['git', 'mv', old, new])
for path in REMOVE:
    if os.path.exists(path):
        subprocess.check_call(['git', 'rm', '-q', path])
for old, (content, _) in changes.items():
    open(new_of[old], 'w').write(content)
print('done')
