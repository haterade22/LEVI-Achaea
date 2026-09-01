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

TAG = re.compile(r'<([a-z_][a-z_0-9]*)(?::([a-z_][a-z_0-9]*))?>')
FG = re.compile(r'\bfg\(\s*"([a-z_][a-z_0-9]*)"')
FIELD = re.compile(r'colour\s*=\s*"([a-z_0-9]+)"')
TABLEVAL = re.compile(r'_COLOUR\s*=\s*\{(.*?)\n\}', re.S)
VAL = re.compile(r'=\s*"([a-z_0-9]+)"')

# cecho understands these structurally; they are not palette entries.
STRUCTURAL = {"reset", "b", "/b", "i", "/i", "u", "/u", "n"}


def names_in(text):
    found = set(FG.findall(text)) | set(FIELD.findall(text))
    for m in TAG.finditer(text):
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
            if "orange" in n:
                orange.append((path, n))
        print("%-72s %2d colour names" % (path, len(found)))
    for p, n in bad:
        print("MISSING FROM PALETTE: %s -> %s" % (p, n))
    for p, n in orange:
        print("RESERVED ORANGE:      %s -> %s" % (p, n))
    return 1 if (bad or orange) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
