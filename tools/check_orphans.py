#!/usr/bin/env python3
"""Fail when an ACTIVE trigger/alias/timer/key calls a global that ONLY an INACTIVE script defines.

Why this exists (v4.7.261)
--------------------------
`scripts/.../levi_scripts/slc/001_functions.lua` was deliberately switched off (`isActive: 'no'`)
when the old SLC was superseded by `lb` -- but its 23 sibling `hit` triggers were left ACTIVE.
Each carried the pattern `^.*$`, so on every single line of game output Mudlet evaluated them and
threw:

    [ERROR:] object:<hit> function:<Trigger2153>
      <[string "Trigger: hit"]:2: attempt to call global 'SLC_blocked' (a nil value)>

Nothing in the pipeline could see it. The Lua syntax check passes -- the code is valid, the
callee simply does not exist at runtime. The unit tests do not load triggers. The build succeeds,
because a disabled script still ships; it just never runs. So the only symptom was a runtime error
storm in the user's client, and it survived for as long as nobody read the error window.

That is this codebase's signature failure mode -- not a crash, a feature that quietly never fires
-- and this is the cheapest possible detector for it.

Deliberately conservative
-------------------------
Only two definition forms count, both unambiguous at file scope:
    function NAME(...)          NAME = function(...)
Namespaced definitions (`function ataxia.foo()`) are ignored: the namespace table is usually
created by a DIFFERENT, active file, so absence of the method is not provable from the header
alone. A symbol defined by ANY active script is never reported, even if an inactive one also
defines it -- the active definition is what runtime sees.

False positives here would be worse than a few misses: this gate blocks the build, and a noisy
gate gets disabled, which is how a guard becomes decoration.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src_new")

# Item types that RUN code and can therefore be a caller.
CALLER_DIRS = ("triggers", "aliases", "timers", "keys")

HEADER_RE = re.compile(r"^--\[\[mudlet\s*(.*?)^\]\]--", re.S | re.M)
ACTIVE_RE = re.compile(r"^\s*isActive:\s*'?(\w+)'?\s*$", re.M)
DEF_RE = re.compile(r"^\s*function\s+([A-Za-z_]\w*)\s*\(", re.M)
DEF_ASSIGN_RE = re.compile(r"^\s*([A-Za-z_]\w*)\s*=\s*function\s*\(", re.M)
CALL_RE = re.compile(r"\b([A-Za-z_]\w*)\s*\(")

# --- CHECK 2: a namespace FIELD that is called but never assigned anywhere ------------------
#
# Added v4.7.281, after the third instance of the same failure reached the user's client:
#
#     [ERROR:] object:<Shin Augment> function:<Alias2759>
#       <[string "Script: Shin Augment Probe"]:284: attempt to call field 'echo' (a nil value)>
#
# `ataxia.echo` does not exist -- the helper is the global `ataxiaEcho` -- so every echoing
# branch of `bash shinprobe`, `bash augment` and `bash inlineinfuse` had been dead since it
# shipped, along with all nine echoes in `ataxiabars`. The same sweep found `shaman.help()`,
# called unguarded by `sp help` and never defined at all.
#
# Check 1 above cannot see any of this: it reasons about GLOBALS defined by INACTIVE scripts,
# and these are table FIELDS that were never defined by anything. Same for the v4.7.264 `zgui`
# family, which was a table INDEX rather than a call.
#
# Only namespaces this repo OWNS are listed. `mmp` is deliberately absent: the mapper is a
# separate package whose ~220 functions live outside src_new, so including it would report
# hundreds of false positives -- and a noisy gate gets switched off, which is how a guard
# becomes decoration.
NAMESPACES = (
    "ataxia", "ataxiaBasher", "ataxiaNDB", "ataxiagui", "ataxiaTables", "ataxiaTemp",
    "selfLimbDamage", "blademaster", "shaman", "psion", "apostate", "tekura", "tekura6",
    "infernalDWC", "ldm", "bashStats", "gearAudit", "itemCatalog", "classDetect", "leviSetup",
)
_NS = "(?:" + "|".join(NAMESPACES) + ")"
FIELD_CALL_RE = re.compile(r"\b(" + _NS + r")((?:\.[A-Za-z_]\w*)+)\s*\(")
FIELD_DEF_FN_RE = re.compile(r"function\s+(" + _NS + r")((?:[.:][A-Za-z_]\w*)+)")
FIELD_DEF_EQ_RE = re.compile(r"\b(" + _NS + r")((?:\.[A-Za-z_]\w*)+)\s*=[^=]")


def split(path):
    """Return (is_active, body). Files with no header are treated as active."""
    text = open(path, encoding="utf-8", errors="replace").read()
    m = HEADER_RE.search(text)
    if not m:
        return True, text
    flag = ACTIVE_RE.search(m.group(1))
    active = True if not flag else flag.group(1).lower() in ("yes", "true")
    return active, text[m.end():]


def walk(*subdirs):
    for sub in subdirs:
        base = os.path.join(SRC, sub)
        for dirpath, _, names in os.walk(base):
            for n in sorted(names):
                if n.endswith(".lua"):
                    yield os.path.join(dirpath, n)


def rel(p):
    return os.path.relpath(p, ROOT).replace(os.sep, "/")


def walk_all():
    """Every source file that can define or call, including the group inline scripts."""
    for dirpath, _, names in os.walk(SRC):
        if os.sep + "tests" in dirpath:
            continue
        for n in sorted(names):
            if n.endswith(".lua") or n.endswith(".yaml"):
                yield os.path.join(dirpath, n)


def strip_comments(body):
    """Drop line comments. Without this, prose like `-- Set ataxiaBasher.fleeTimeout (seconds)`
    reads as a call to a field that does not exist."""
    out = []
    for line in body.splitlines():
        i = line.find("--")
        out.append(line if i < 0 else line[:i])
    return "\n".join(out)


def check_missing_fields():
    """CHECK 2: NS.field(...) where NS.field is assigned nowhere in the tree."""
    assigned, called = set(), {}
    for path in walk_all():
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        # Definitions are searched in the RAW text: the group inline scripts in _groups.yaml
        # carry Lua as escaped YAML strings, and that is where several namespaces are built.
        for m in FIELD_DEF_FN_RE.finditer(text):
            assigned.add(m.group(1) + m.group(2).replace(":", "."))
        for m in FIELD_DEF_EQ_RE.finditer(text):
            assigned.add(m.group(1) + m.group(2))
        if not path.endswith(".lua"):
            continue
        _active, body = split(path)
        # Report REAL file line numbers: split() drops the YAML header, so body line 1 is not
        # file line 1, and a finding you cannot jump to is a finding you will not act on.
        offset = len(text) - len(body)
        header_lines = text[:offset].count("\n")
        lines = strip_comments(body).splitlines()
        for i, line in enumerate(lines):
            for m in FIELD_CALL_RE.finditer(line):
                name = m.group(1) + m.group(2)
                # A guarded call cannot throw. Unlike check 1 this looks at the two PRECEDING
                # lines as well, because the idiom this tree actually uses for optional FIELDS
                # puts the test on its own line:
                #     if ataxia and ataxia.decho then
                #         ataxia.decho("...")
                #     end
                # Check 1 is per-line because it guards against a real orphan slipping through;
                # here the same strictness would report six safe call sites in one file, and a
                # gate that cries wolf gets switched off.
                window = "\n".join(lines[max(0, i - 2):i + 1])
                if re.search(r"\b%s\s+(?:and|then)\b" % re.escape(name), window):
                    continue
                called.setdefault(name, []).append((rel(path), header_lines + i + 1))

    def covered(name):
        # Assigning any PREFIX covers the leaf: `ataxia.mnemosyne = M` defines every method on it.
        parts = name.split(".")
        return any(".".join(parts[:i]) in assigned for i in range(2, len(parts) + 1))

    return {n: sites for n, sites in called.items() if not covered(n)}


def main():
    live, dead = set(), {}

    for path in walk("scripts"):
        active, body = split(path)
        names = set(DEF_RE.findall(body)) | set(DEF_ASSIGN_RE.findall(body))
        if active:
            live |= names
        else:
            for n in names:
                dead.setdefault(n, rel(path))

    # An active definition anywhere wins: runtime does not care where it came from.
    orphaned = {n: f for n, f in dead.items() if n not in live}
    if not orphaned:
        print("check_orphans: no inactive-script globals defined; nothing to check.")
        return report_missing_fields()

    findings = []
    for path in walk(*CALLER_DIRS):
        active, body = split(path)
        if not active:
            continue  # a disabled caller of a disabled callee is consistent -- that IS the fix
        for line in body.splitlines():
            stripped = line.strip()
            if stripped.startswith("--"):
                continue
            for name in sorted(set(CALL_RE.findall(line))):
                if name not in orphaned:
                    continue
                # A call guarded by an existence check cannot throw. Both idioms already used
                # in this tree count, and both put the guard on the SAME line as the call:
                #     if NAME then NAME(...) end
                #     if NAME and NAME(...) == false then
                # Checked per-line rather than per-file on purpose -- a guard somewhere else in
                # the file does not protect this call, and treating it as if it did would let a
                # real orphan through, which is the failure this gate exists to prevent.
                guarded = re.search(r"\b%s\s+and\s+%s\s*\(" % (name, name), line) or \
                          re.search(r"\bif\s+%s\s+then\b" % name, line)
                if not guarded:
                    findings.append((rel(path), name, orphaned[name]))

    if not findings:
        print("check_orphans: OK -- %d global(s) defined only by inactive scripts, none called "
              "by an active item." % len(orphaned))
        return report_missing_fields()

    print("=== ORPHANED CALLS: active items call globals only an INACTIVE script defines ===")
    print("These will throw 'attempt to call global (a nil value)' on every match, at runtime,")
    print("with no build or test failure to warn you.\n")
    for caller, name, definer in findings:
        print("  %s\n      calls %s(), defined only by INACTIVE %s" % (caller, name, definer))
    print("\nFix by disabling the caller (isActive: 'no') if the feature is genuinely retired,")
    print("or by re-activating the script if it is not. Do not leave them disagreeing.")
    print("\n%d orphaned call site(s)." % len(findings))
    report_missing_fields()
    return 1


def report_missing_fields():
    missing = check_missing_fields()
    if not missing:
        print("check_orphans: OK -- no namespace field is called without being defined.")
        return 0
    print("\n=== MISSING NAMESPACE FIELDS: called, but assigned nowhere in the tree ===")
    print("These throw \"attempt to call field 'x' (a nil value)\" every time the line runs,")
    print("with no build or test failure to warn you.\n")
    for name in sorted(missing):
        sites = missing[name]
        print("  %s()  -- %d call site(s)" % (name, len(sites)))
        for f, ln in sites[:4]:
            print("      %s:%d" % (f, ln))
        if len(sites) > 4:
            print("      ... and %d more" % (len(sites) - 4))
    print("\nEither define it, point the call at the real helper, or guard it")
    print("(`if NS.field then NS.field(...) end`) if it is genuinely optional.")
    print("\n%d undefined field(s)." % len(missing))
    return 1


if __name__ == "__main__":
    sys.exit(main())
