"""Convert Mudlet HTML log exports in kb/raw/logs/ into the text files the KB keeps as evidence.

Put an HTML export in kb/raw/logs/ and run this. It writes one .txt per fight beside it. Each <br> is
one row, tags are dropped, entities are decoded, and nothing else changes (kb/raw/logs/README.md).

    python tools/kb_log_import.py              # convert every new export, print a manifest
    python tools/kb_log_import.py --dry-run    # manifest only, write nothing
    python tools/kb_log_import.py --check      # compare each export with its filed text
    python tools/kb_log_import.py some.html    # these exports only

The export is never moved or edited. An export is skipped when a filed text already holds its lines,
so a copy such as "x (1).html", or a text that was renamed later, does not file the fight twice.
New files are named <date>_<logger>_unknown-vs-unknown_<win|loss|noresult>_<id>.txt. The tool cannot
tell classes, so rename a file when a read of the log shows them. The skip does not use the name.
"""
import argparse
import glob
import html
import os
import re
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGS = os.path.join(ROOT, "kb", "raw", "logs")
BR = re.compile(r"<br\s*/?>", re.I)
TAG = re.compile(r"<[^>]+>", re.S)
BODY = re.compile(r"<body[^>]*>", re.I)
GENERIC_PROFILE = "achaea"     # a profile with this name does not tell who logged the fight
LONG_ROW = 25                  # shorter rows (prompts, "ql") repeat between fights, so they prove nothing
SAME_FIGHT = 0.90              # filed fights overlap at 99-100%; the highest different fight is 18%
SLAIN_BY = re.compile(r"^You have been slain by (.+?)\.")
SLAIN = re.compile(r"^You have slain (.+?)\.")
ARENA_WON = "You have been victorious and leave the Arena"
ARENA_LOST = "You have been defeated and are thrown out of the Arena"
STAMP_MS = re.compile(r"\b\d{1,2}:\d{2}:\d{2}[:.]\d{3}\b")


def read(path):
    with open(path, encoding="utf-8", errors="replace", newline="") as fh:
        return fh.read()


def to_rows(raw):
    """The export's rows. A newline in the HTML source is layout, not game text, so it goes."""
    body = BODY.split(raw)[-1]
    return [html.unescape(TAG.sub("", part)).replace("\r", "").replace("\n", "") for part in BR.split(body)]


def long_rows(rows):
    return {r.strip() for r in rows if len(r.strip()) > LONG_ROW}


def filed_texts():
    """{file name: its rows}, for every text already in kb/raw/logs/."""
    filed = {}
    for path in glob.glob(os.path.join(LOGS, "*.txt")):
        filed[os.path.basename(path)] = read(path).replace("\r", "").split("\n")
    return filed


def best_overlap(rows, filed):
    """The filed text that holds the most of these rows, and the share it holds."""
    mine = long_rows(rows)
    best, share = None, 0.0
    for name, theirs in filed.items():
        s = len(mine & long_rows(theirs)) / max(1, len(mine))
        if s > share:
            best, share = name, s
    return best, share


def logger_of(raw):
    m = re.search(r"from (.+?) profile", raw[:3000])
    name = m.group(1).split()[0].lower() if m else ""
    return "unknown" if not name or name == GENERIC_PROFILE else name


def result_of(rows):
    """The last result line decides, because one log can hold several kills. Returns (result, name).
    An arena verdict prints after the kill line, so the search continues for the name."""
    result = "noresult"
    for row in reversed(rows):
        text = row.strip()
        by, won = SLAIN_BY.match(text), SLAIN.match(text)
        if by or won:
            if result == "noresult":
                result = "loss" if by else "win"
            return result, (by or won).group(1)
        if result == "noresult" and text.startswith(ARENA_WON):
            result = "win"
        elif result == "noresult" and text.startswith(ARENA_LOST):
            result = "loss"
    return result, "?"


def log_id(path):
    """The export's id: "Vr.NkCGD (2).html" is the id Vr.NkCGD."""
    stem = os.path.splitext(os.path.basename(path))[0]
    return re.sub(r" \(\d+\)$", "", stem)


def target_name(path, raw, rows):
    date = time.strftime("%Y-%m-%d", time.localtime(os.path.getmtime(path)))
    result = result_of(rows)[0]
    return f"{date}_{logger_of(raw)}_unknown-vs-unknown_{result}_{log_id(path)}.txt"


def manifest_row(path, rows, note):
    result, name = result_of(rows)
    stamps = len(STAMP_MS.findall("\n".join(rows)))
    print(f"{log_id(path):<12} {len(rows):>6} rows  {stamps:>5} ms stamps  {result:<8} {name[:28]:<28} {note}")


def check(paths):
    """Every export must match a filed text exactly, or be a fight filed earlier."""
    filed = filed_texts()
    exact = {}
    for name, rows in filed.items():
        exact["\n".join(r for r in rows)] = name
    failed = 0
    for path in paths:
        rows = to_rows(read(path))
        text = "\n".join(rows)
        name = exact.get(text) or exact.get(text + "\n")
        if name:
            manifest_row(path, rows, f"EXACT {name}")
            continue
        best, share = best_overlap(rows, filed)
        if share >= SAME_FIGHT:
            manifest_row(path, rows, f"filed earlier, {share:.0%} of rows in {best}")
        else:
            failed += 1
            manifest_row(path, rows, "NOT FILED")
    print(f"\n{len(paths)} export(s), {failed} not filed.")
    return failed


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("logs", nargs="*", help="HTML exports (default: every kb/raw/logs/*.html)")
    ap.add_argument("--dry-run", action="store_true", help="print the manifest, write nothing")
    ap.add_argument("--check", action="store_true", help="compare each export with its filed text")
    args = ap.parse_args()

    paths = sorted(args.logs or glob.glob(os.path.join(LOGS, "*.html")))
    if not paths:
        sys.exit("No HTML exports in kb/raw/logs/.")
    if args.check:
        sys.exit(1 if check(paths) else 0)

    filed = filed_texts()
    written = skipped = 0
    for path in paths:
        raw = read(path)
        rows = to_rows(raw)
        best, share = best_overlap(rows, filed)
        if share >= SAME_FIGHT:
            skipped += 1
            manifest_row(path, rows, f"skip, {share:.0%} of rows in {best}")
            continue
        name = target_name(path, raw, rows)
        if not args.dry_run:
            with open(os.path.join(LOGS, name), "w", encoding="utf-8", newline="\n") as fh:
                fh.write("\n".join(rows))
        filed[name] = rows      # a copy later in this run must see this fight, in a dry run too
        written += 1
        manifest_row(path, rows, name)
    verb = "would write" if args.dry_run else "wrote"
    print(f"\n{len(paths)} export(s): {verb} {written}, {skipped} already filed.")


if __name__ == "__main__":
    main()
