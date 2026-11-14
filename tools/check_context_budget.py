"""A byte budget for CLAUDE.md, and a proof that a move out of it lost nothing (docs/adrs/002).

    python -B tools/check_context_budget.py                  # budget: each file is within its ceiling
    python -B tools/check_context_budget.py --lower          # after a move: lower each ceiling to size + headroom
    python -B tools/check_context_budget.py --moves --base <commit> [--deleted "## Heading" ...]

BUDGET. tools/context_budget.json names each budgeted file and its ceiling in bytes (line ends
counted as LF). A file over its ceiling is a finding. While "strict" is false the finding is
printed and the exit status stays 0 (report-only, as every new gate here starts); when true it is 1.
A ceiling only goes down: --lower never raises one. Why: CLAUDE.md grew from 72 KB to 450 KB in
five months, and Claude Code delivers only the start of a large file (docs/reference/harness-facts.md).

MOVES (run it yourself before the push; it needs the base commit, which CI's shallow checkout lacks).
It compares the file at <commit> with the file on disk. Every line that left must be found, verbatim,
in a Markdown file that changed since <commit>. A section you removed on purpose is named with
--deleted: its lines may vanish, but every `backticked` identifier in them must still exist in a
tracked text file. The check proves that the text exists in its new home. It does not prove that
anyone will read it there.

Exit status: 0 = pass (or a report-only finding), 1 = a finding, 2 = NOT RUN (nothing to check).
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG = os.path.join(ROOT, "tools", "context_budget.json")
TEXT_SUFFIXES = (".md", ".lua", ".py", ".json", ".yaml", ".yml", ".txt", ".sh")
SKIP_FOLDERS = ("kb/raw/", "muddler_project/", "levi_test_project/", "my_package_project/", "packages/", ".git/")


def size_of(path):
    """Bytes with every line end counted as LF, so Windows and Linux agree."""
    with open(path, "rb") as fh:
        return len(fh.read().replace(b"\r\n", b"\n"))


# ---------------------------------------------------------------------------------------------
# Budget
# ---------------------------------------------------------------------------------------------


def budget_rows(config, root=ROOT):
    """[(path, size or None, ceiling, over)] for each budgeted file. size None = the file is missing."""
    rows = []
    for path, rule in sorted(config.get("files", {}).items()):
        full = os.path.join(root, *path.split("/"))
        size = size_of(full) if os.path.isfile(full) else None
        rows.append((path, size, rule["ceiling"], size is None or size > rule["ceiling"]))
    return rows


def check_budget(config, root=ROOT, out=print):
    rows = budget_rows(config, root)
    if not rows:
        out("check_context_budget: NOT RUN -- tools/context_budget.json names no file")
        return 2
    strict = bool(config.get("strict"))
    status = 0
    for path, size, ceiling, over in rows:
        if size is None:
            out("check_context_budget: FAIL -- %s is missing; correct tools/context_budget.json" % path)
            status = 1
        elif over:
            label = "" if strict else " (report-only)"
            out("check_context_budget: OVER%s -- %s is %d bytes, ceiling %d (+%d). New detail belongs in its one home "
                "(docs/adrs/002-knowledge-delivery-tiers.md), not in this file." % (label, path, size, ceiling, size - ceiling))
            if strict:
                status = 1
        else:
            target = config["files"][path].get("target")
            goal = ", target %d" % target if target else ""
            out("check_context_budget: OK -- %s is %d bytes, ceiling %d (%d under%s)" % (path, size, ceiling, ceiling - size, goal))
    return status


def lower_ceilings(config, root=ROOT, out=print):
    """Each ceiling becomes size + headroom when that is LOWER. Returns True when the config changed."""
    headroom = int(config.get("headroom", 0))
    changed = False
    for path, size, ceiling, _ in budget_rows(config, root):
        if size is None:
            continue
        wanted = max(size + headroom, config["files"][path].get("target", 0))
        if wanted < ceiling:
            config["files"][path]["ceiling"] = wanted
            out("check_context_budget: ceiling of %s lowered %d -> %d (size %d)" % (path, ceiling, wanted, size))
            changed = True
        else:
            out("check_context_budget: ceiling of %s stays %d (size %d); a ceiling is never raised" % (path, ceiling, size))
    return changed


# ---------------------------------------------------------------------------------------------
# Moves
# ---------------------------------------------------------------------------------------------


def rows_of(text):
    return [row.strip() for row in text.replace("\r\n", "\n").split("\n") if row.strip()]


def removed_rows(base_text, now_text):
    """The rows that left, with their counts: base minus now, as multisets of non-blank stripped rows."""
    return collections.Counter(rows_of(base_text)) - collections.Counter(rows_of(now_text))


def section_rows(text, heading):
    """The non-blank rows of one section: its heading row to the row before the next heading of the same or a higher level."""
    rows = text.replace("\r\n", "\n").split("\n")
    level = len(heading) - len(heading.lstrip("#"))
    start = None
    in_fence = False
    block = []
    for row in rows:
        if row.lstrip().startswith("```"):
            in_fence = not in_fence
        if start is None:
            if row.strip() == heading.strip():
                start = True
                block.append(row)
            continue
        found = re.match(r"^(#{1,6}) ", row) if not in_fence else None
        if found and len(found.group(1)) <= level:
            break
        block.append(row)
    return [row.strip() for row in block if row.strip()] if start else None


def identifiers(rows):
    return sorted({token for row in rows for token in re.findall(r"`([^`\n]{2,120})`", row)})


def judge_moves(base_text, now_text, destination_rows, deleted_sections=(), corpus=""):
    """How each row that left is accounted for.

    destination_rows: a set of the non-blank stripped rows of the files that could hold moved text.
    deleted_sections: lists of rows (from section_rows on the BASE text) that were removed on purpose.
    corpus: the text in which an identifier of a deleted row must still be found.
    """
    gone = removed_rows(base_text, now_text)
    allowed = collections.Counter()
    for block in deleted_sections:
        allowed.update(block)
    moved, deleted, lost = [], [], []
    for row, count in gone.items():
        if row in destination_rows:
            moved.append(row)
        elif allowed[row] >= count:
            deleted.append(row)
        else:
            lost.append(row)
    missing = [token for token in identifiers(deleted) if token not in corpus]
    return {"left": sum(gone.values()), "moved": moved, "deleted": deleted, "lost": lost, "missing_identifiers": missing}


def git(root, *args):
    done = subprocess.run(["git", "-C", root] + list(args), stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL)
    return done.stdout.decode("utf-8", "replace") if done.returncode == 0 else None


def read_text(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def check_moves(base, path, deleted_headings, root=ROOT, out=print):
    base_text = git(root, "show", "%s:%s" % (base, path))
    if base_text is None:
        out("check_context_budget: NOT RUN -- cannot read %s at %s" % (path, base))
        return 2
    now_text = read_text(os.path.join(root, *path.split("/")))
    changed = (git(root, "diff", "--name-only", base) or "").split("\n")
    changed += (git(root, "ls-files", "--others", "--exclude-standard") or "").split("\n")
    homes = sorted({name for name in changed if name.endswith(".md") and name not in (path, "CHANGELOG.md")
                    and os.path.isfile(os.path.join(root, *name.split("/")))})
    destination_rows = set()
    for name in homes:
        destination_rows.update(rows_of(read_text(os.path.join(root, *name.split("/")))))
    blocks = []
    for heading in deleted_headings:
        block = section_rows(base_text, heading)
        if block is None:
            out("check_context_budget: FAIL -- no section %r in %s at %s" % (heading, path, base))
            return 1
        blocks.append(block)
    corpus = ""
    if blocks:
        tracked = (git(root, "ls-files") or "").split("\n")
        parts = []
        for name in tracked:
            if name.endswith(TEXT_SUFFIXES) and not name.startswith(SKIP_FOLDERS) and os.path.isfile(os.path.join(root, *name.split("/"))):
                parts.append(read_text(os.path.join(root, *name.split("/"))))
        corpus = "\n".join(parts)
    verdict = judge_moves(base_text, now_text, destination_rows, blocks, corpus)
    if not verdict["left"]:
        out("check_context_budget: NOT RUN -- no row left %s since %s" % (path, base))
        return 2
    out("check_context_budget: %d rows left %s since %s: %d moved verbatim, %d deleted by declaration, %d lost"
        % (verdict["left"], path, base, len(verdict["moved"]), len(verdict["deleted"]), len(verdict["lost"])))
    if homes:
        out("  homes read: %s" % ", ".join(homes))
    for row in verdict["lost"][:20]:
        out("  LOST: %s" % row[:200])
    if len(verdict["lost"]) > 20:
        out("  ... and %d more" % (len(verdict["lost"]) - 20))
    for token in verdict["missing_identifiers"][:20]:
        out("  IDENTIFIER GONE (was in a deleted section, is in no tracked file): `%s`" % token)
    return 1 if verdict["lost"] or verdict["missing_identifiers"] else 0


# ---------------------------------------------------------------------------------------------


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lower", action="store_true", help="lower each ceiling to size + headroom (never raises)")
    ap.add_argument("--moves", action="store_true", help="prove that the rows which left the file since --base exist elsewhere")
    ap.add_argument("--base", help="the commit to compare with (for --moves)")
    ap.add_argument("--file", default="CLAUDE.md", help="the file the rows left (for --moves)")
    ap.add_argument("--deleted", action="append", default=[], metavar="HEADING", help="a section removed on purpose, by its heading row")
    args = ap.parse_args(argv)
    if args.moves:
        if not args.base:
            print("check_context_budget: NOT RUN -- --moves needs --base <commit>")
            return 2
        return check_moves(args.base, args.file, args.deleted)
    try:
        with open(CONFIG, encoding="utf-8") as fh:
            config = json.load(fh)
    except (OSError, ValueError) as exc:
        print("check_context_budget: NOT RUN -- cannot read tools/context_budget.json: %s" % exc)
        return 2
    if args.lower:
        if lower_ceilings(config):
            with open(CONFIG, "w", encoding="utf-8", newline="\n") as fh:
                json.dump(config, fh, indent=2)
                fh.write("\n")
        return 0
    return check_budget(config)


if __name__ == "__main__":
    sys.exit(main())
