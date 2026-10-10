#!/usr/bin/env python3
"""Compare a live `CURING PRIORITY LIST` against the priorities our code sends.

The server's curingset is the truth about what SSC will do; `ataxia_defaultCuringPrios()`
(ataxia/001) is what we BELIEVE it holds. Nothing in the package parses the server's answer to a
`curing priority` write, so a rejected write, a stale row, or a runtime swap that never got
restored is invisible until someone lists the set. This tool lists the differences.

    python tools/kb_prio_diff.py kb/raw/live/curing-priority-list_normal_2026-10-10.txt
    python tools/kb_prio_diff.py <file> --bash     # compare against the PvE bash set instead
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ATAXIA = os.path.join(ROOT, "src_new", "scripts", "levi_ataxia", "levi", "ataxia", "ataxia")


def lua_prios(path, func):
    text = open(path, encoding="utf-8").read()
    body = text.split("function " + func, 1)[1].split("\nend", 1)[0]
    return {k: int(v) for k, v in re.findall(r'\["(\w+)"\]\s*=\s*(\d+)', body)}


def parse_live(path):
    """'N:  a, b, burning(5)' with server-wrapped continuation lines -> {aff: N}."""
    out, cur = {}, None
    for raw in open(path, encoding="utf-8", errors="replace"):
        line = raw.rstrip()
        m = re.match(r"^(\d+):\s*(.*)$", line)
        if m:
            cur, rest = int(m.group(1)), m.group(2)
        elif cur is not None and line.strip() and not line.startswith("Affs with"):
            rest = line
        else:
            continue
        for name in re.split(r",\s*", rest.strip().rstrip(",")):
            name = name.strip()
            if not name:
                continue
            name = re.sub(r"\((\d+)\)$", r"\1", name)  # burning(5) -> burning5
            out[name] = cur
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("file")
    ap.add_argument("--bash", action="store_true", help="expect the PvE bash set (PvP + bash delta)")
    args = ap.parse_args()

    want = lua_prios(os.path.join(ATAXIA, "001_Default_Curing_Prios.lua"), "ataxia_defaultCuringPrios")
    if args.bash:
        want.update(lua_prios(os.path.join(ATAXIA, "008_Bash_Curing_Profile.lua"), "ataxia_bashCuringPrios"))
    live = parse_live(args.file)
    if not live:
        sys.exit("No priority rows found in " + args.file)

    differ = sorted((k, want[k], live[k]) for k in want if k in live and want[k] != live[k])
    code_only = sorted(k for k in want if k not in live)
    live_only = sorted((k, live[k]) for k in live if k not in want)

    print(f"{len(live)} afflictions in the live set, {len(want)} in our table.\n")
    print(f"DIFFERENT PRIORITY ({len(differ)}):  aff  ours -> live")
    for k, w, l in differ:
        print(f"  {k:24} {w:>3} -> {l:<3} {'(live cures it SOONER)' if l < w else '(live cures it LATER)'}")
    print(f"\nIN OUR TABLE, NOT IN THE LIVE LIST ({len(code_only)}): {', '.join(code_only) or '-'}")
    print(f"\nIN THE LIVE LIST, NOT IN OUR TABLE ({len(live_only)}): "
          + (", ".join(f"{k}={v}" for k, v in live_only) or "-"))


if __name__ == "__main__":
    main()
