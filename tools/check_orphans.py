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

The checks, in the order they print
-----------------------------------
    1   an active trigger, alias, timer or key calls a global only an inactive script defines
    1b  an active SCRIPT does the same (v4.7.419)
    2   NS.field(...) is called, and NS.field is assigned nowhere in the tree
    2b  active code calls NS.field(...), and only switched-off files assign it
Every check fails CI. 1b and 2b landed report-only, behind STRICT_SCRIPT_CALLERS and
STRICT_INACTIVE_FIELDS; both were made strict in v4.7.419 once their reports were clean. A new
check should start the same way, report-only until its report is clean.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src_new")

# Item types that RUN code and can therefore be a caller.
CALLER_DIRS = ("triggers", "aliases", "timers", "keys")

# --- CHECK 1b: an active SCRIPT is a caller too (v4.7.419) -----------------------------------
#
# Check 1 was built for the v4.7.261 storm, whose callers were triggers, so it never read a script
# as a caller -- and a script makes far more calls than a trigger. Its first run over them
# (2026-10-12; line numbers as of 7b7704ac) found five call sites in four files, among them
# `misc_scripts/001_Queue_Scanning.lua:30` calling `shikudo_findCombo` for every queued monk combo
# and `shikudo/009_CC_Shikudo_GodMode.lua:745` calling `shikudo_breakPoint(5000)` on the first
# tick of every GodMode round (v4.7.419 has since switched 009 off). Only the switched-off
# `008_CC_Shikudo_Offense_ALL.lua` defines either.
#
# Scripts get a scan of their own (`script_orphan_calls`) rather than joining CALLER_DIRS: a script
# is long code, not a one-line trigger body, so the scan has to tell a field from a global, a local
# from a global, and a guard on the line above from no guard at all.
SCRIPT_CALLER_DIRS = ("scripts",)

# A new check lands REPORT-ONLY: it prints every finding but leaves the exit status alone. Set its
# flag to True once its report is clean, and from then on a new finding fails CI like checks 1
# and 2. A gate that fails CI on its first day gets switched off, which is how a guard becomes
# decoration.
STRICT_SCRIPT_CALLERS = True    # check 1b
STRICT_INACTIVE_FIELDS = True   # check 2b

HEADER_RE = re.compile(r"^--\[\[mudlet\s*(.*?)^\]\]--", re.S | re.M)
ACTIVE_RE = re.compile(r"^\s*isActive:\s*'?(\w+)'?\s*$", re.M)
DEF_RE = re.compile(r"^\s*function\s+([A-Za-z_]\w*)\s*\(", re.M)
DEF_ASSIGN_RE = re.compile(r"^\s*([A-Za-z_]\w*)\s*=\s*function\s*\(", re.M)
CALL_RE = re.compile(r"\b([A-Za-z_]\w*)\s*\(")

# The same two definition forms inside a group inline script in _groups.yaml. Those scripts are
# escaped YAML strings, where a Lua newline is the two characters \n, so one of those may stand
# right before the definition -- and the n of that escape must not be read as the start of the
# name (`\nfoo = function` defines foo, not nfoo). `local function` is not a global.
YAML_DEF_RE = re.compile(
    r"(?:(?<=\\[nt])|(?<![\w.:\\]))(?<!local\s)function\s+([A-Za-z_]\w*)\s*\(")
YAML_DEF_ASSIGN_RE = re.compile(
    r"(?:(?<=\\[nt])|(?<![\w.:\\]))(?<!local\s)([A-Za-z_]\w*)\s*=\s*function\s*\(")

# Check 1b reads a bare NAME( as a call to the global: `obj.NAME(` and `obj:NAME(` call a field.
SCRIPT_CALL_RE = re.compile(r"(?<![.:\w])([A-Za-z_]\w*)\s*\(")
# Names a file binds itself -- locals, parameters, loop variables. Calling one is not calling the
# global of the same name.
LOCAL_RE = re.compile(r"\blocal\s+(?:function\s+)?([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)")
PARAMS_RE = re.compile(r"\bfunction\b[^(\n]*\(([^)]*)\)")
FOR_RE = re.compile(r"\bfor\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*(?:=|in\b)")

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
#
# `monk` is the one exception: no script we ship defines it, yet 14 Shikudo triggers called
# monk.shikudo.limb_hit() and threw on every strike they matched (fixed v4.7.414 by guarding
# them, in case another installed package provides it). Listing it means every call into it must
# stay guarded.
#
# `shikudo` and `shikudoLock` (v4.7.419): `vv` called `shikudo.setMode("godmode")`
# (aliases/.../153_Fourth_Attack_(All_Classes).lua:29 as of 7b7704ac), which only the
# switched-off `008_CC_Shikudo_Offense_ALL.lua:67` defines, so every press on a Shikudo threw.
# Listing the namespace alone would NOT have caught it: this check counts a definition in a
# switched-off file as a definition. Check 2b (`check_missing_fields`) is the one that sees it.
NAMESPACES = (
    "ataxia", "ataxiaBasher", "ataxiaNDB", "ataxiagui", "ataxiaTables", "ataxiaTemp",
    "selfLimbDamage", "blademaster", "shaman", "psion", "apostate", "tekura", "tekura6",
    "infernalDWC", "ldm", "bashStats", "gearAudit", "itemCatalog", "classDetect", "leviSetup",
    "monk", "shikudo", "shikudoLock", "shikudoLedger",
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


LONG_COMMENT_RE = re.compile(r"--\[(=*)\[.*?\]\1\]", re.S)


def strip_comments(body):
    """Drop comments. Without this, prose like `-- Set ataxiaBasher.fleeTimeout (seconds)`
    reads as a call to a field that does not exist.

    Long comments (`--[[ ... ]]`) go first (v4.7.414): the line pass only sees their first line,
    so a header block naming `.claude/classes/monk.md (class mechanics)` read as a call to
    `monk.md()`. Each block keeps its line breaks, so reported line numbers stay right."""
    body = LONG_COMMENT_RE.sub(lambda m: "\n" * m.group(0).count("\n"), body)
    out = []
    for line in body.splitlines():
        i = line.find("--")
        out.append(line if i < 0 else line[:i])
    return "\n".join(out)


def guarded(name, lines, i):
    """True when lines[i], or one of the two lines above it, tests that `name` exists. Checks 1b,
    2 and 2b share it; check 1 keeps its own per-line rule (see `report_item_callers`).

    A guarded call cannot throw. Unlike check 1 this looks at the two PRECEDING lines as well,
    because the idiom this tree actually uses for optional FIELDS puts the test on its own line:
        if ataxia and ataxia.decho then
            ataxia.decho("...")
        end
    Check 1 is per-line because it guards against a real orphan slipping through; here the same
    strictness would report six safe call sites in one file, and a gate that cries wolf gets
    switched off. A script guards a GLOBAL the same way, or with `type(NAME) == "function"`
    (misc_scripts/025_KB_Capture.lua:70)."""
    window = "\n".join(lines[max(0, i - 2):i + 1])
    pat = re.escape(name)
    return bool(re.search(r"\b%s\s+(?:and|then)\b" % pat, window) or
                re.search(r"\btype\(\s*%s\s*\)\s*[=~]=\s*[\"']function[\"']" % pat, window))


def yaml_globals():
    """Globals the group inline scripts in _groups.yaml define. They run like any script, so a
    global defined there is live: before v4.7.419 check 1 read .lua files only, and such a global
    would have read as orphaned the day an inactive script also defined it (none does today)."""
    names = set()
    for path in walk_all():
        if path.endswith(".yaml"):
            text = open(path, encoding="utf-8", errors="replace").read()
            names |= set(YAML_DEF_RE.findall(text)) | set(YAML_DEF_ASSIGN_RE.findall(text))
    return names


def bound_names(code):
    """Names a file binds itself: locals, function parameters and loop variables.

    Read file-wide, not per scope. That can hide an orphan in a file which also has a local of the
    same name, but it never reports a call to a local as a call to the global -- and in a gate a
    false alarm costs more than a miss."""
    names = set()
    for rx in (LOCAL_RE, PARAMS_RE, FOR_RE):
        for group in rx.findall(code):
            names.update(n.strip() for n in group.split(","))
    return names


def script_orphan_calls(orphaned):
    """CHECK 1b: (caller, line, name, definer) for each unguarded call from an ACTIVE script to a
    global that only an INACTIVE script defines.

    More careful than check 1's per-line scan, because a script is long code: comments are
    stripped (long ones too), `obj.NAME(` is a field, a name the file binds itself is not the
    global, and the guard may sit on either of the two lines above (see `guarded`)."""
    findings = []
    for path in walk(*SCRIPT_CALLER_DIRS):
        active, body = split(path)
        if not active:
            continue  # a disabled caller of a disabled callee is consistent -- that IS the fix
        text = open(path, encoding="utf-8", errors="replace").read()
        header_lines = text[:len(text) - len(body)].count("\n")
        code = strip_comments(body)
        own = bound_names(code)
        lines = code.splitlines()
        for i, line in enumerate(lines):
            for name in sorted(set(SCRIPT_CALL_RE.findall(line))):
                if name in orphaned and name not in own and not guarded(name, lines, i):
                    findings.append((rel(path), header_lines + i + 1, name, orphaned[name]))
    return findings


def field_definitions(text):
    """(name, offset) for each NS.field the text assigns, in either form check 2 reads."""
    for m in FIELD_DEF_FN_RE.finditer(text):
        yield m.group(1) + m.group(2).replace(":", "."), m.start()
    for m in FIELD_DEF_EQ_RE.finditer(text):
        yield m.group(1) + m.group(2), m.start()


def covered(name, assigned):
    # Assigning any PREFIX covers the leaf: `ataxia.mnemosyne = M` defines every method on it.
    parts = name.split(".")
    return any(".".join(parts[:i]) in assigned for i in range(2, len(parts) + 1))


def check_missing_fields():
    """CHECK 2: NS.field(...) where NS.field is assigned nowhere in the tree.

    CHECK 2b: NS.field(...) in an ACTIVE file where only switched-off files assign NS.field. The
    definition ships but never runs, so the call throws exactly as a missing one does -- and
    check 2 cannot see it, because it counts a switched-off definition as a definition. That is
    how `vv` shipped calling `shikudo.setMode` (see NAMESPACES).

    Returns (missing, inactive_only, inactive_defs): the first two map a field to its call sites
    [(file, line), ...]; the third maps an assigned name to its first switched-off definition."""
    assigned, assigned_active, inactive_defs = set(), set(), {}
    called, called_active = {}, {}
    for path in walk_all():
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        # A _groups.yaml counts as active even though a group can be switched off: reading a
        # definition as live can only hide a finding, never invent one.
        active, body = split(path) if path.endswith(".lua") else (True, None)
        # Definitions are searched in the RAW text: the group inline scripts in _groups.yaml
        # carry Lua as escaped YAML strings, and that is where several namespaces are built.
        for name, pos in field_definitions(text):
            assigned.add(name)
            if active:
                assigned_active.add(name)
            else:
                inactive_defs.setdefault(name, (rel(path), text.count("\n", 0, pos) + 1))
        if body is None:
            continue
        # Report REAL file line numbers: split() drops the YAML header, so body line 1 is not
        # file line 1, and a finding you cannot jump to is a finding you will not act on.
        offset = len(text) - len(body)
        header_lines = text[:offset].count("\n")
        lines = strip_comments(body).splitlines()
        for i, line in enumerate(lines):
            for m in FIELD_CALL_RE.finditer(line):
                name = m.group(1) + m.group(2)
                if guarded(name, lines, i):
                    continue
                site = (rel(path), header_lines + i + 1)
                called.setdefault(name, []).append(site)
                if active:
                    # A disabled caller of a disabled definition is consistent -- that IS the fix.
                    called_active.setdefault(name, []).append(site)

    missing = {n: sites for n, sites in called.items() if not covered(n, assigned)}
    inactive_only = {n: sites for n, sites in called_active.items()
                     if covered(n, assigned) and not covered(n, assigned_active)}
    return missing, inactive_only, inactive_defs


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
    live |= yaml_globals()  # a group inline script defines live globals too

    # An active definition anywhere wins: runtime does not care where it came from.
    orphaned = {n: f for n, f in dead.items() if n not in live}
    if not orphaned:
        print("check_orphans: no inactive-script globals defined; nothing to check.")
        return report_missing_fields()

    status = report_item_callers(orphaned)
    status |= report_script_callers(orphaned)
    return report_missing_fields() | status


def report_item_callers(orphaned):
    """CHECK 1: active triggers, aliases, timers and keys. Returns 1 on any finding."""
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
                safe = re.search(r"\b%s\s+and\s+%s\s*\(" % (name, name), line) or \
                       re.search(r"\bif\s+%s\s+then\b" % name, line)
                if not safe:
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


def report_script_callers(orphaned):
    """CHECK 1b's report. Fails (returns 1) only once STRICT_SCRIPT_CALLERS is set."""
    findings = script_orphan_calls(orphaned)
    if not findings:
        print("check_orphans: OK -- no active script calls a global only an inactive script "
              "defines.")
        return 0
    label = "" if STRICT_SCRIPT_CALLERS else " (report-only)"
    print("\n=== ORPHANED SCRIPT CALLS%s: active SCRIPTS call globals only an INACTIVE script "
          "defines ===" % label)
    print("These throw 'attempt to call global (a nil value)' whenever the line runs.")
    if not STRICT_SCRIPT_CALLERS:
        print("Report-only until this list is clean: then set STRICT_SCRIPT_CALLERS and it fails")
        print("CI like the check above.")
    print()
    for caller, line, name, definer in sorted(findings):
        print("  %s:%d\n      calls %s(), defined only by INACTIVE %s"
              % (caller, line, name, definer))
    print("\nSwitch the caller off if its feature is retired, guard the call")
    print("(`if NAME then NAME(...) end`) if it is optional, or re-activate the definer.")
    print("\n%d call site(s)%s." % (len(findings), label))
    return 1 if STRICT_SCRIPT_CALLERS else 0


def report_missing_fields():
    """Checks 2 and 2b, in that order. Returns 1 when either fails."""
    missing, inactive_only, inactive_defs = check_missing_fields()
    status = report_undefined_fields(missing)
    return report_inactive_fields(inactive_only, inactive_defs) | status


def report_undefined_fields(missing):
    """CHECK 2's report."""
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


def report_inactive_fields(inactive_only, inactive_defs):
    """CHECK 2b's report. Fails (returns 1) only once STRICT_INACTIVE_FIELDS is set."""
    if not inactive_only:
        print("check_orphans: OK -- no active code calls a field that only switched-off files "
              "assign.")
        return 0
    label = "" if STRICT_INACTIVE_FIELDS else " (report-only)"
    print("\n=== FIELDS DEFINED ONLY WHEN SWITCHED OFF%s: active code calls them ===" % label)
    print("The definition ships but never runs, so each call throws \"attempt to call field 'x'")
    print("(a nil value)\" just as if it had never been written.")
    if not STRICT_INACTIVE_FIELDS:
        print("Report-only until this list is clean: then set STRICT_INACTIVE_FIELDS and it fails")
        print("CI like the check above.")
    print()
    for name in sorted(inactive_only):
        # The covering assignment may be a prefix: `ataxia.mnemosyne = M` covers its methods.
        parts = name.split(".")
        prefixes = (".".join(parts[:i]) for i in range(2, len(parts) + 1))
        definer = next(inactive_defs[p] for p in prefixes if p in inactive_defs)
        print("  %s()  -- assigned only in INACTIVE %s:%d" % ((name,) + definer))
        for f, ln in sorted(inactive_only[name]):
            print("      %s:%d" % (f, ln))
    print("\nSwitch the caller off if its feature is retired, guard it")
    print("(`if NS.field then NS.field(...) end`) if it is optional, or move the definition into")
    print("an active file.")
    print("\n%d field(s), %d call site(s)%s." % (
        len(inactive_only), sum(len(s) for s in inactive_only.values()), label))
    return 1 if STRICT_INACTIVE_FIELDS else 0


if __name__ == "__main__":
    sys.exit(main())
