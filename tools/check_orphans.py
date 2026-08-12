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
        return 0

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
        return 0

    print("=== ORPHANED CALLS: active items call globals only an INACTIVE script defines ===")
    print("These will throw 'attempt to call global (a nil value)' on every match, at runtime,")
    print("with no build or test failure to warn you.\n")
    for caller, name, definer in findings:
        print("  %s\n      calls %s(), defined only by INACTIVE %s" % (caller, name, definer))
    print("\nFix by disabling the caller (isActive: 'no') if the feature is genuinely retired,")
    print("or by re-activating the script if it is not. Do not leave them disagreeing.")
    print("\n%d orphaned call site(s)." % len(findings))
    return 1


if __name__ == "__main__":
    sys.exit(main())
