#!/usr/bin/env python3
"""Project verifier for Noah's Playroom.

Runs one or more checks and prints a readable report. Exits non-zero if any
check fails. Intended to be run from the repo root (or via the opencode
`verify` tool):

    python3 scripts/verify.py [all|syntax|sprites|logic|smoke]

Checks:
    syntax  - every src/**/*.lua (plus main.lua/conf.lua) parses in LuaJIT
    sprites - sprite sheets in src/data/sprites.lua match their grid config
              (dimensions + non-empty cells; dots sheets are dot-counted)
    logic   - runs scripts/tests/numbers_harness.lua
    smoke   - runs scripts/tests/app_smoke.lua
"""

from __future__ import annotations

import re
import subprocess
import sys
from collections import deque
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    Image = None

ROOT = Path(__file__).resolve().parent.parent

GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"


def ok(msg: str) -> None:
    print(f"{GREEN}OK{RESET}   {msg}")


def fail(msg: str) -> None:
    print(f"{RED}FAIL{RESET} {msg}")


def warn(msg: str) -> None:
    print(f"{YELLOW}WARN{RESET} {msg}")


def skip(msg: str) -> None:
    print(f"{YELLOW}SKIP{RESET} {msg}")


# --------------------------------------------------------------------------- #
# Lua syntax
# --------------------------------------------------------------------------- #

def lua_files() -> list[Path]:
    files = sorted((ROOT / "src").rglob("*.lua"))
    for extra in ("main.lua", "conf.lua"):
        p = ROOT / extra
        if p.exists():
            files.append(p)
    return files


def run_syntax() -> bool:
    print("== Lua syntax ==")
    if not _have("luajit"):
        skip("luajit not found; cannot check Lua syntax")
        return True

    passed = True
    for path in lua_files():
        proc = subprocess.run(
            ["luajit", "-e", f"assert(loadfile({str(path)!r}))"],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            passed = False
            fail(f"{path.relative_to(ROOT)}")
            if proc.stderr.strip():
                print("       " + proc.stderr.strip().replace("\n", "\n       "))
    if passed:
        ok(f"{len(lua_files())} Lua files parse")
    return passed


# --------------------------------------------------------------------------- #
# Sprite sheets
# --------------------------------------------------------------------------- #

SPRITE_KEYS = ("path", "columns", "rows", "spriteWidth", "spriteHeight")


def parse_sprite_sheets() -> dict[str, dict]:
    text = (ROOT / "src/data/sprites.lua").read_text()
    sheets: dict[str, dict] = {}
    for match in re.finditer(r"(\w+)\s*=\s*\{([^{}]*)\}", text):
        name, body = match.group(1), match.group(2)
        if "path" not in body or "spriteWidth" not in body:
            continue
        entry: dict[str, object] = {}
        for key in SPRITE_KEYS:
            found = re.search(key + r'\s*=\s*"?([^",\s]+)"?', body)
            if found:
                entry[key] = found.group(1).strip('"')
        if all(key in entry for key in SPRITE_KEYS):
            entry["columns"] = int(entry["columns"])  # type: ignore[arg-type]
            entry["rows"] = int(entry["rows"])  # type: ignore[arg-type]
            entry["spriteWidth"] = int(entry["spriteWidth"])  # type: ignore[arg-type]
            entry["spriteHeight"] = int(entry["spriteHeight"])  # type: ignore[arg-type]
            entry["optional"] = bool(re.search(r"optional\s*=\s*true", body))
            sheets[name] = entry
    return sheets


def _cell_has_content(img, x0: int, y0: int, x1: int, y1: int) -> bool:
    alpha = img.getchannel("A")
    px = alpha.load()
    count = 0
    for y in range(y0, y1):
        for x in range(x0, x1):
            if px[x, y] > 16:
                count += 1
                if count > 20:
                    return True
    return False


def _count_dots(img, y0: int, y1: int, x0: int, x1: int) -> int:
    """Count brown dot blobs in a cell (borders filtered by shape/size)."""
    px = img.load()
    w = x1 - x0
    h = y1 - y0
    dark = [[False] * w for _ in range(h)]
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b, a = px[x, y]
            if a > 120 and r > g > b and 50 < r < 170 and g < 120 and b < 95:
                dark[y - y0][x - x0] = True

    core = [[False] * w for _ in range(h)]
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if dark[y][x] and all(
                dark[y + dy][x + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)
            ):
                core[y][x] = True

    seen = [[False] * w for _ in range(h)]
    count = 0
    for y in range(h):
        for x in range(w):
            if not core[y][x] or seen[y][x]:
                continue
            queue = deque([(x, y)])
            seen[y][x] = True
            area = 0
            min_x = max_x = x
            min_y = max_y = y
            while queue:
                cx, cy = queue.popleft()
                area += 1
                min_x, max_x = min(min_x, cx), max(max_x, cx)
                min_y, max_y = min(min_y, cy), max(max_y, cy)
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and core[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True
                        queue.append((nx, ny))
            bw = max_x - min_x + 1
            bh = max_y - min_y + 1
            if area >= 20 and 10 <= bw <= 45 and 10 <= bh <= 45 and 0.6 <= bw / bh <= 1.6:
                count += 1
    return count


def validate_sheet(name: str, cfg: dict) -> bool:
    path = ROOT / str(cfg["path"])
    columns = int(cfg["columns"])
    rows = int(cfg["rows"])
    cw = int(cfg["spriteWidth"])
    ch = int(cfg["spriteHeight"])

    if not path.exists():
        if cfg.get("optional"):
            warn(f"{name}: optional sheet not delivered yet ({cfg['path']})")
            return True
        fail(f"{name}: missing {cfg['path']}")
        return False

    with Image.open(path) as raw:
        img = raw.convert("RGBA")
        size = img.size
        expected = (cw * columns, ch * rows)
        if size != expected:
            fail(
                f"{name}: {size[0]}x{size[1]} != {expected[0]}x{expected[1]} "
                f"({columns}x{rows} of {cw}x{ch})"
            )
            return False

        empty_cells = []
        for col in range(columns):
            for row in range(rows):
                x0 = col * cw
                y0 = row * ch
                if not _cell_has_content(img, x0, y0, x0 + cw, y0 + ch):
                    empty_cells.append((row + 1, col + 1))
        if empty_cells:
            warn(f"{name}: {len(empty_cells)} empty cell(s) {empty_cells[:5]}")

        if "dot" in name.lower():
            bad = []
            for col in range(columns):
                for row in range(rows):
                    value = row * columns + col + 1
                    x0 = col * cw
                    y0 = row * ch
                    found = _count_dots(img, y0, y0 + ch, x0, x0 + cw)
                    if found != value:
                        bad.append((value, found))
            if bad:
                fail(f"{name}: dot counts mismatched {bad[:10]}")
                return False

    ok(f"{name}: {columns}x{rows} of {cw}x{ch} ({size[0]}x{size[1]})")
    return True


def run_sprites() -> bool:
    print("== Sprite sheets ==")
    if Image is None:
        skip("Pillow not installed; cannot validate sprite sheets")
        return True

    sheets = parse_sprite_sheets()
    if not sheets:
        fail("no sprite sheet entries parsed from src/data/sprites.lua")
        return False

    passed = True
    for name, cfg in sheets.items():
        if not validate_sheet(name, cfg):
            passed = False
    return passed


# --------------------------------------------------------------------------- #
# Lua harnesses
# --------------------------------------------------------------------------- #

def _have(binary: str) -> bool:
    from shutil import which

    return which(binary) is not None


def run_harness(title: str, script: str) -> bool:
    print(f"== {title} ==")
    path = ROOT / script
    if not path.exists():
        fail(f"missing {script}")
        return False
    if not _have("luajit"):
        skip("luajit not found; cannot run harness")
        return True

    proc = subprocess.run(
        ["luajit", str(path)], cwd=ROOT, capture_output=True, text=True
    )
    out = (proc.stdout or "").strip()
    if out:
        print(out)
    if proc.returncode != 0:
        fail(f"{title} (exit {proc.returncode})")
        err = (proc.stderr or "").strip()
        if err:
            print("       " + err.replace("\n", "\n       "))
        return False
    return True


LOGIC_HARNESSES = (
    ("Numbers harness", "scripts/tests/numbers_harness.lua"),
    ("Farm harness", "scripts/tests/farm_harness.lua"),
)


def run_logic() -> bool:
    return all(run_harness(f"Game logic ({name})", path) for name, path in LOGIC_HARNESSES)


def run_smoke() -> bool:
    return run_harness("App smoke (boot -> menu -> modules)", "scripts/tests/app_smoke.lua")


# --------------------------------------------------------------------------- #
# Entry point
# --------------------------------------------------------------------------- #

def main(argv: list[str]) -> int:
    target = argv[1] if len(argv) > 1 else "all"
    checks = {
        "syntax": run_syntax,
        "sprites": run_sprites,
        "logic": run_logic,
        "smoke": run_smoke,
    }

    if target == "all":
        selected = list(checks.values())
    elif target in checks:
        selected = [checks[target]]
    else:
        print(f"unknown target '{target}'. Use: all|{'|'.join(checks)}")
        return 2

    results = [check() for check in selected]
    print()
    if all(results):
        print(f"{GREEN}ALL CHECKS PASSED{RESET}")
        return 0
    print(f"{RED}CHECKS FAILED{RESET}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
