"""A trigger pattern must be able to fit on ONE physical line.

Achaea wraps server-side at the player's width, so a long game line reaches Mudlet as two or more
rows and a trigger sees each row on its own. This user's width measures 119-124 columns (from the
break points in their own pastes, v4.7.351). A pattern that can never fit on one row can never
match -- and fails silently: no error, no echo, the state it maintains simply never changes.

That happened three times in one week (v4.7.336-347): the belch "room is fouled" refusal, the
soulstorm landing for long mob names, and the gravehands confirmation, which made every Apostate
room cast its summon twice. See CHANGELOG v4.7.351.

WHAT THIS CATCHES: an anchored full-line regex (`^...$`) or a plain substring whose SHORTEST
possible text is wider than the wrap. That class can never match a wrapped line.

WHAT IT CANNOT CATCH: a short fragment that straddles the break (the gravehands case -- 61
characters, but starting at column 88 of a 148-character line). That needs the full line, so it
lives in src_new/tests/test_trigger_wrap.lua, which wraps known lines and runs the real patterns.

ALLOWLIST: pre-existing triggers flagged when this check was written. Several are probably real
(Meteorite, Calcify, the Aeonic distortion proc); they are listed so the check can guard every NEW
pattern today without silently changing old ones in the same release. Remove an entry when it is
fixed -- the check fails on a stale entry, so the list cannot rot.
"""
import io
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRIGGERS = ROOT / 'src_new' / 'triggers'
WIDTH = 118  # one below the measured 119 minimum

ALLOWLIST = {
    'levi_ataxia/for_levi/leviticus/635_WRENCH_TORSO.lua',
    'levi_ataxia/for_levi/leviticus/colours/001_Deathblow.lua',
    'levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/005_Mobs_Misc_(wont_track).lua',
    'levi_ataxia/for_levi/leviticus/general/022_Resonance_Afflictions.lua',
    'levi_ataxia/for_levi/leviticus/general/024_Meteorite.lua',
    'levi_ataxia/for_levi/leviticus/general/026_Calcify.lua',
    'levi_ataxia/for_levi/leviticus/highlighting/048_Aeonic_Distortion_Proc.lua',
    'levi_ataxia/for_levi/leviticus/monk/002_Kai_Surge.lua',
}


def min_len(p):
    """Shortest text a (simple) regex can match, as a character count. Deliberately generous --
    every uncertain construct counts as zero or one -- so a flag is never a false alarm."""
    s = p
    s = re.sub(r'\\[dDwWsS][+]\??', 'x', s)
    s = re.sub(r'\\[dDwWsS][*?]\??', '', s)
    s = re.sub(r'\\[dDwWsS]', 'x', s)
    s = re.sub(r'\((?:\?:)?[^()]*\)[?*]', '', s)
    s = re.sub(r'\([^()]*\|[^()]*\)', 'x', s)        # alternation: count as one char
    s = re.sub(r'\[[^\]]*\][+*]?', 'x', s)
    s = re.sub(r'\.\{\d+,\d+\}', '', s)
    s = re.sub(r'\.[+]\??', 'x', s)
    s = re.sub(r'\.[*]\??', '', s)
    s = re.sub(r'\\(.)', lambda m: m.group(1), s)
    s = re.sub(r'[()|?^$]', '', s)
    return len(s)


def patterns(text):
    header = text.split(']]--')[0]
    for m in re.finditer(r"- pattern: ('(?:[^']|'')*'|[^\n]*)\n\s+type: (\d)", header):
        raw, typ = m.group(1), m.group(2)
        if raw.startswith("'"):
            raw = re.sub(r'\s*\n\s*', ' ', raw[1:-1]).replace("''", "'")
        yield raw, typ


def offenders(path):
    text = io.open(path, encoding='utf-8', errors='replace').read()
    out = []
    for raw, typ in patterns(text):
        if typ == '1':
            if raw.startswith('^') and raw.endswith('$') and min_len(raw) > WIDTH:
                out.append((min_len(raw), raw))
        elif typ in ('0', '2', '3') and len(raw) > WIDTH:  # substring, startOfLine, exactMatch
            out.append((len(raw), raw))
    return out


def main():
    new, seen = [], set()
    for path in sorted(TRIGGERS.rglob('*.lua')):
        rel = path.relative_to(TRIGGERS).as_posix()
        found = offenders(path)
        if not found:
            continue
        seen.add(rel)
        if rel not in ALLOWLIST:
            new.extend((rel, n, p) for n, p in found)
    stale = sorted(ALLOWLIST - seen)
    if new:
        print('check_wrap: FAIL -- %d pattern(s) can never fit on one %d-column line:' % (len(new), WIDTH))
        for rel, n, p in new:
            print('  %s  (%d chars)  %s' % (rel, n, p[:90]))
        print('Match an EARLY fragment of the line instead -- see src_new/tests/test_trigger_wrap.lua.')
    if stale:
        print('check_wrap: FAIL -- allowlisted but no longer too wide (remove from ALLOWLIST):')
        for rel in stale:
            print('  ' + rel)
    if new or stale:
        return 1
    print('check_wrap: OK -- no trigger pattern is wider than %d columns (%d pre-existing allowlisted).'
          % (WIDTH, len(ALLOWLIST)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
