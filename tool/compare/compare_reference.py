#!/usr/bin/env python3
"""Structural comparison of the 7 reference screenshots with the goldens (S7).

Standard library only (no PIL, no numpy). The golden viewport (2102x1164 at
1.125) equals the page area of the screenshots (crop x 10..2112, y 8..1172 of
the 2124x1180 image). The reference uses real font rendering and the goldens
the bundled test font, so the comparison is on structure, not on raw pixels:
panel edges (white runs), text bands (rows with ink) and their x extents per
region, plus a mismatch percentage and a diff image.

usage: python3 tool/compare/compare_reference.py [outdir]

NOTE: needs ../reference_screenshots/ (outside git). It stops working when
that folder is deleted after Phase A; docs/final_comparison.md stays as the
record of the last run.
"""
import struct, sys, zlib, os

REF = '../reference_screenshots/'
GOLD = 'test/golden/goldens/'
PAIRS = [
    ('POS empty cart', '4.56.50', 'shell_pos_light.png'),
    ('POS one line', '4.57.09', 'pos_one_line_light.png'),
    ('Products', '4.57.21', 'shell_products_light.png'),
    ('Customers', '4.57.32', 'shell_customers_light.png'),
    ('Sales (empty)', '4.57.41', 'shell_sales_light.png'),
    ('Returns (empty)', '4.57.54', 'shell_returns_light.png'),
    ('Reports (zeros)', '4.58.11', 'shell_reports_light.png'),
]
CROP = (10, 8, 2102, 1164)  # x, y, w, h inside the 2124x1180 reference


def find_ref(stamp):
    """macOS puts a narrow no-break space before PM: match on the time stamp."""
    for name in sorted(os.listdir(REF)):
        if stamp in name:
            return REF + name
    raise FileNotFoundError(stamp)


def read_png(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    pos, idat, w = 8, b'', None
    while pos < len(data):
        n, t = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if t == b'IHDR':
            w, h, depth, ctype, _, _, inter = struct.unpack('>IIBBBBB', body)
            assert depth == 8 and inter == 0 and ctype in (2, 6), (depth, ctype, inter)
        elif t == b'IDAT':
            idat += body
        pos += 12 + n
    ch = 3 if ctype == 2 else 4
    raw = zlib.decompress(idat)
    stride = w * ch
    rows, prev = [], bytearray(stride)
    p = 0
    for _ in range(h):
        f = raw[p]; line = bytearray(raw[p + 1:p + 1 + stride]); p += 1 + stride
        for i in range(stride):
            a = line[i - ch] if i >= ch else 0
            b = prev[i]
            c = prev[i - ch] if i >= ch else 0
            if f == 1: line[i] = (line[i] + a) & 255
            elif f == 2: line[i] = (line[i] + b) & 255
            elif f == 3: line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        rows.append(line); prev = line
    return w, h, ch, rows


def to_luma(img, crop=None):
    w, h, ch, rows = img
    x0, y0, cw, chh = crop or (0, 0, w, h)
    out = []
    for y in range(y0, y0 + chh):
        r = rows[y]
        out.append([(r[(x0 + x) * ch] * 299 + r[(x0 + x) * ch + 1] * 587 + r[(x0 + x) * ch + 2] * 114) // 1000 for x in range(cw)])
    return out


def write_png(path, w, h, rows_rgb):
    raw = b''.join(b'\x00' + bytes(r) for r in rows_rgb)
    def chunk(t, b): return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 6)) + chunk(b'IEND', b''))


def runs(values, pred, min_len=20):
    out, start = [], None
    for i, v in enumerate(values):
        if pred(v):
            if start is None: start = i
        elif start is not None:
            if i - start >= min_len: out.append((start, i - 1))
            start = None
    if start is not None and len(values) - start >= min_len: out.append((start, len(values) - 1))
    return out


def panels(luma):
    """White (>=250) runs along the middle row and a column through the page."""
    h, w = len(luma), len(luma[0])
    row = luma[h // 2]
    col = [luma[y][w // 2 - 300] for y in range(h)]
    return runs(row, lambda v: v >= 250, 60), runs(col, lambda v: v >= 250, 60)


def bands(luma, x0, x1, y0=0, y1=None, ink=175, gap=3):
    """Text-like bands: groups of rows with ink in [x0, x1): (top, bottom, left, right)."""
    y1 = y1 or len(luma)
    out, cur = [], None
    for y in range(y0, y1):
        xs = [x for x in range(x0, x1) if luma[y][x] < ink]
        if xs:
            if cur and y - cur[1] <= gap:
                cur = [cur[0], y, min(cur[2], xs[0]), max(cur[3], xs[-1])]
            else:
                if cur: out.append(tuple(cur))
                cur = [y, y, xs[0], xs[-1]]
    if cur: out.append(tuple(cur))
    return [b for b in out if b[1] - b[0] >= 3 and b[3] - b[2] >= 6]


REGIONS = {'sidebar': (0, 100), 'page': (100, 1560), 'summary': (1560, 2102)}


def compare(name, ref_png, gold_png, outdir):
    ref = to_luma(read_png(find_ref(ref_png)), CROP)
    gw, gh, gch, grows = read_png(GOLD + gold_png)
    gold = to_luma((gw, gh, gch, grows))
    h, w = min(len(ref), len(gold)), min(len(ref[0]), len(gold[0]))
    diff, bad = [], 0
    for y in range(h):
        line = bytearray()
        for x in range(w):
            d = abs(ref[y][x] - gold[y][x])
            if d > 40: bad += 1; line += b'\xe0\x20\x20'
            else: g = 255 - min(255, d * 3) if False else ref[y][x]; line += bytes((g, g, g))
        diff.append(line)
    write_png(os.path.join(outdir, 'diff_' + gold_png), w, h, diff)
    rp, rc = panels(ref); gp, gc = panels(gold)
    lines = [f'### {name}', f'- reference screenshot {ref_png}, golden `{gold_png}` ({gw}x{gh}); pixels differing by more than 40 luma: **{100.0 * bad / (w * h):.2f} %** (font rendering and test-font noise included)',
             f'- white panel runs along the middle row (x): reference {rp}, golden {gp}',
             f'- white panel runs down a page column (y): reference {rc}, golden {gc}']
    for region, (a, b) in REGIONS.items():
        rb, gb = bands(ref, a, b), bands(gold, a, b)
        n = min(len(rb), len(gb))
        dy = [abs(rb[i][0] - gb[i][0]) for i in range(n)]
        dl = [abs(rb[i][2] - gb[i][2]) for i in range(n)]
        lines.append(f'- {region}: text bands reference {len(rb)}, golden {len(gb)}; matched in order: {n}; median |dy| {sorted(dy)[len(dy)//2] if dy else "-"} px, max |dy| {max(dy) if dy else "-"} px, median |dx left| {sorted(dl)[len(dl)//2] if dl else "-"} px, max |dx left| {max(dl) if dl else "-"} px')
    return '\n'.join(lines)


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '/tmp/x/compare'
    os.makedirs(out, exist_ok=True)
    for name, r, g in PAIRS:
        print(compare(name, r, g, out)); print()
