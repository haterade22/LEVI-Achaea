"""Every colour NAME these files choose must exist in our own palette.

`007_Custom_Colour_Table.lua` WHOLESALE REPLACES Mudlet's palette, so a name that is perfectly
valid in stock Mudlet -- `silver` is the one that bit us, CHANGELOG v4.7.136 -- is absent here and
makes the render throw. In a panel that redraws on every claim, that kills the whole window.

Two things are scanned, and the second is the one that matters:
  * `<tag>` / `fg("name")`      -- what the RENDERER writes.
  * `colour = "name"` and the values of any `*_COLOUR` table -- what an AGGREGATOR chooses.
A colour name travels as a plain STRING whenever the module that picks it is separate from the
module that draws it (`011_Bonuses` -> `012_Bonuses_Window`), so scanning tags alone audits the
renderer and misses every name the picker chose. That is exactly where `silver` would have got in.

The ORANGE family is reserved by the user for new code. Existing sites are grandfathered, so this
runs only against files named on the command line -- never as a tree-wide sweep.

NOT CI-ENFORCED, and that is a decision rather than an omission. Usage strings put placeholder
syntax inside real echo calls -- `M.echo("Usage: mnem token <token>")` -- and no regex separates a
placeholder from a colour name, because the only difference is whether the word happens to be in
the palette, which is the very thing being tested. A tree-wide gate therefore fails on files that
are perfectly correct, and a gate that cries wolf gets switched off (v4.7.281). Run it against the
files you are adding or changing; treat a hit on a usage string as the known false positive it is.

Usage: python tools/check_colours.py <file.lua> [file.lua ...]
"""
import io
import re
import sys

TABLE = ("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/"
         "007_Custom_Colour_Table.lua")

src = io.open(TABLE, encoding="utf-8", errors="replace").read()
known = set(re.findall(r'\["([a-zA-Z_0-9]+)"\]\s*=', src))
known |= set(re.findall(r'^\s*([a-zA-Z_][a-zA-Z_0-9]*)\s*=\s*\{', src, re.M))

# CASE MATTERS AND THESE USED TO REQUIRE LOWERCASE. The palette legitimately defines names in both
# forms, and `<NavajoWhite>` -- used twice in the very release this tool was written for -- matched
# nothing at all, so a CamelCase typo would have passed with "0 missing". A checker silent on half
# the namespace it guards is decoration.
TAG = re.compile(r'<([A-Za-z_][A-Za-z_0-9]*)(?::([A-Za-z_][A-Za-z_0-9]*))?>')
FG = re.compile(r'\bfg\(\s*"([A-Za-z_][A-Za-z_0-9]*)"')
FIELD = re.compile(r'colour\s*=\s*"([A-Za-z_0-9]+)"')
TABLEVAL = re.compile(r'_COLOUR\s*=\s*\{(.*?)\n\}', re.S)
VAL = re.compile(r'=\s*"([A-Za-z_0-9]+)"')

# COMMENTS ARE STRIPPED FIRST. Without this the scanner reads prose: a comment writing
# `tailored to <x> Boons` or `<pet> recall` yields "x" and "pet" as missing colours. A gate that
# cries wolf gets switched off, which is how a guard becomes decoration -- `check_orphans.py`
# learned exactly this in v4.7.281, and the note is repeated because the two tools are independent
# and the next scanner will need it too.
BLOCK_COMMENT = re.compile(r'--\[(=*)\[.*?\]\1\]', re.S)
LINE_COMMENT = re.compile(r'--[^\r\n]*')

# cecho understands these structurally; they are not palette entries.
STRUCTURAL = {"reset", "b", "/b", "i", "/i", "u", "/u", "n"}


def strip_lua_comments(text):
    text = BLOCK_COMMENT.sub(" ", text)
    return LINE_COMMENT.sub(" ", text)


# A `<word>` IS ONLY A COLOUR IN A COLOUR CONTEXT. Command help strings are full of placeholder
# syntax -- `mnem boss <name>`, `mnem ripple <n>`, `<text>` -- and scanning every angle-bracket
# token in a file reports those as missing colours. Six of them in one dispatcher was enough to
# make a tree-wide run useless, which is the cry-wolf failure this tool must not have.
#
# So tags are read only from lines that also carry a colour-emitting call. The tradeoff is
# deliberate and worth stating: a cecho whose tag sits on a CONTINUATION line is not scanned, so
# this can MISS a bad name. It is a lint, not a proof -- and a lint that is wrong out loud gets
# switched off, while one that is occasionally silent still catches the common case.
COLOUR_CALL = re.compile(r'\b(c?echo|decho|hecho|cinsertText|fg|setFgColor)\s*\(')


def names_in(text):
    text = strip_lua_comments(text)
    found = set(FG.findall(text)) | set(FIELD.findall(text))
    for ln in text.splitlines():
        if not COLOUR_CALL.search(ln):
            continue
        for m in TAG.finditer(ln):
            found.add(m.group(1))
            if m.group(2):
                found.add(m.group(2))
    for m in TABLEVAL.finditer(text):
        found |= set(VAL.findall(m.group(1)))
    return found - STRUCTURAL


def main(paths):
    print("palette names: %d" % len(known))
    bad, orange = [], []
    for path in paths:
        found = names_in(io.open(path, encoding="utf-8", errors="replace").read())
        for n in sorted(found):
            if n not in known:
                bad.append((path, n))
            if "orange" in n.lower():
                orange.append((path, n))
        print("%-72s %2d colour names" % (path, len(found)))
    for p, n in bad:
        print("MISSING FROM PALETTE: %s -> %s" % (p, n))
    for p, n in orange:
        print("RESERVED ORANGE:      %s -> %s" % (p, n))
    return 1 if (bad or orange) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
