#!/usr/bin/env python3
"""
Flatten the deeply nested alias hierarchy in _groups.yaml and all .lua files.

Before:  Levi_Ataxia > For Levi > Levi_062424 > Levi > LeviticusREG > Leviticus > BladeMaster (7 levels)
After:   Levi_Ataxia > Classes > Blademaster (3 levels)

Usage:
    python tools/flatten_alias_hierarchy.py --src ./src_new [--dry-run]
"""

import os
import re
import sys
import argparse

# ── Hierarchy mapping: old path (as list) → new path (as list) ──────────────
# Order matters: longer (more specific) prefixes must be checked first.
# The script finds the LONGEST matching old path and replaces it.

# Shorthand for the deep prefix
_LEV = ["Levi_Ataxia", "For Levi", "Levi_062424", "Levi", "LeviticusREG", "Leviticus"]
_LEVI = ["Levi_Ataxia", "For Levi", "Levi_062424", "Levi"]
_ATAXIA = ["Levi_Ataxia", "For Levi", "Levi_062424", "Levi", "Ataxia-DownloadThis", "Ataxia"]

HIERARCHY_MAP = [
    # ── Utility (consolidate scattered echo/deleteOldProfiles) ──
    (["Levi_Ataxia", "deletestuff", "deleteOldProfiles"], ["Levi_Ataxia", "Utility"]),
    (["Levi_Ataxia", "echo"], ["Levi_Ataxia", "Utility"]),
    (["Levi_Ataxia", "For Levi", "echo"], ["Levi_Ataxia", "Utility"]),
    (["Levi_Ataxia", "For Levi", "deleteOldProfiles"], ["Levi_Ataxia", "Utility"]),
    (["Levi_Ataxia", "For Levi", "run-lua-code-v4"], ["Levi_Ataxia", "Utility"]),
    (["Levi_Ataxia", "For Levi", "Levi_062424", "echo"], ["Levi_Ataxia", "Utility"]),
    (["Levi_Ataxia", "For Levi", "Levi_062424", "deleteOldProfiles"], ["Levi_Ataxia", "Utility"]),

    # ── RAGEPULL (disabled) ──
    (_LEVI + ["RAGEPULL"], ["Levi_Ataxia", "RAGEPULL"]),

    # ── Classes: Monk (deepest nesting, must come first) ──
    (_LEV + ["Monks", "Monk", "Monk", "Tekura"], ["Levi_Ataxia", "Classes", "Monk", "Tekura"]),
    (_LEV + ["Monks", "Monk", "Monk", "monkcustomcombo"], ["Levi_Ataxia", "Classes", "Monk", "monkcustomcombo"]),
    (_LEV + ["Monks", "Monk", "telepathy_reporting", "Telepathy Reporting"], ["Levi_Ataxia", "Classes", "Monk", "Telepathy Reporting"]),
    (_LEV + ["Monks", "Monk", "Shikudo"], ["Levi_Ataxia", "Classes", "Monk", "Shikudo"]),
    (_LEV + ["Monks", "Monk", "Kaido"], ["Levi_Ataxia", "Classes", "Monk", "Kaido"]),
    (_LEV + ["Monks", "Monk", "Telepathy"], ["Levi_Ataxia", "Classes", "Monk", "Telepathy"]),
    (_LEV + ["Monks", "ALIASES"], ["Levi_Ataxia", "Classes", "Monk", "ALIASES"]),
    (_LEV + ["Monks", "KAIDO"], ["Levi_Ataxia", "Classes", "Monk", "KAIDO"]),
    (_LEV + ["Monks", "SHIKUDO"], ["Levi_Ataxia", "Classes", "Monk", "SHIKUDO"]),
    (_LEV + ["Monks", "TEKURA"], ["Levi_Ataxia", "Classes", "Monk", "TEKURA"]),
    (_LEV + ["Monks", "TELEPATHY"], ["Levi_Ataxia", "Classes", "Monk", "TELEPATHY"]),
    (_LEV + ["Monks"], ["Levi_Ataxia", "Classes", "Monk"]),

    # ── Classes: Knight ──
    (_LEV + ["Knight", "Infernal", "Oppression"], ["Levi_Ataxia", "Classes", "Knight", "Infernal", "Oppression"]),
    (_LEV + ["Knight", "Infernal", "SNB"], ["Levi_Ataxia", "Classes", "Knight", "Infernal", "SNB"]),
    (_LEV + ["Knight", "Infernal", "2H"], ["Levi_Ataxia", "Classes", "Knight", "Infernal", "2H"]),
    (_LEV + ["Knight", "Infernal", "Dual Blunt"], ["Levi_Ataxia", "Classes", "Knight", "Infernal", "Dual Blunt"]),
    (_LEV + ["Knight", "RUNIE", "SNB"], ["Levi_Ataxia", "Classes", "Knight", "RUNIE", "SNB"]),
    (_LEV + ["Knight", "RUNIE", "2H"], ["Levi_Ataxia", "Classes", "Knight", "RUNIE", "2H"]),
    (_LEV + ["Knight", "RUNIE"], ["Levi_Ataxia", "Classes", "Knight", "RUNIE"]),
    (_LEV + ["Knight"], ["Levi_Ataxia", "Classes", "Knight"]),

    # ── Classes: Psion ──
    (_LEV + ["Psion", "Emulation"], ["Levi_Ataxia", "Classes", "Psion", "Emulation"]),
    (_LEV + ["Psion", "Psionics"], ["Levi_Ataxia", "Classes", "Psion", "Psionics"]),

    # ── Classes: Dragon (note: DRAGON folder has RAGEBLADE, Dragon folder is separate) ──
    (_LEV + ["DRAGON", "RAGEBLADE"], ["Levi_Ataxia", "Artefacts", "Rageblade"]),
    (_LEV + ["DRAGON"], ["Levi_Ataxia", "Classes", "Dragon"]),
    (_LEV + ["Dragon"], ["Levi_Ataxia", "Classes", "Dragon"]),

    # ── Classes: simple mappings ──
    (_LEV + ["APOSTATE"], ["Levi_Ataxia", "Classes", "Apostate"]),
    (_LEV + ["BladeMaster"], ["Levi_Ataxia", "Classes", "Blademaster"]),
    (_LEV + ["DEPTHSWALKER"], ["Levi_Ataxia", "Classes", "Depthswalker"]),
    (_LEV + ["EARTH LORD"], ["Levi_Ataxia", "Classes", "Earth Lord"]),
    (_LEV + ["Mage"], ["Levi_Ataxia", "Classes", "Mage"]),
    (_LEV + ["Serpent"], ["Levi_Ataxia", "Classes", "Serpent"]),
    (_LEV + ["Undead"], ["Levi_Ataxia", "Classes", "Undead"]),
    (_LEV + ["slc"], ["Levi_Ataxia", "Classes", "slc"]),
    (_LEV + ["Shaman System"], ["Levi_Ataxia", "Classes", "Shaman"]),

    # ── General ──
    (_LEV + ["General", "FREEZETAG"], ["Levi_Ataxia", "General", "Freezetag"]),
    (_LEV + ["General", "MOVEMENT"], ["Levi_Ataxia", "General", "Movement"]),
    (_LEV + ["General", "SHOPKEEPING"], ["Levi_Ataxia", "General", "Shopkeeping"]),
    (_LEV + ["General", "TARGETTING"], ["Levi_Ataxia", "General", "Targeting"]),
    # General > Mhaldor — Mhaldor dir is under General in _groups.yaml
    (_LEV + ["General"], ["Levi_Ataxia", "General"]),

    # ── Artefacts ──
    (_LEV + ["Artefacts", "LegendDeck"], ["Levi_Ataxia", "Artefacts", "LegendDeck"]),
    (_LEV + ["Artefacts"], ["Levi_Ataxia", "Artefacts"]),
    (_LEV + ["DRAGON TALISMAN"], ["Levi_Ataxia", "Artefacts", "Dragon Talisman"]),

    # ── Combat ──
    (_LEV + ["Defence"], ["Levi_Ataxia", "Combat", "Defence"]),
    (_LEV + ["limb.1.2", "Limb"], ["Levi_Ataxia", "Combat", "Limb"]),
    (_LEV + ["AzzysEnemyManagement", "Enemy Management"], ["Levi_Ataxia", "Combat", "Enemy Management"]),
    (_LEV + ["EGGHUNT"], ["Levi_Ataxia", "General", "Egghunt"]),
    (_ATAXIA + ["Combat Aliases"], ["Levi_Ataxia", "Combat", "Combat Aliases"]),

    # ── Ataxia config: NDB ──
    (_ATAXIA + ["Ataxia NDB", "Actions", "Notes"], ["Levi_Ataxia", "Ataxia", "NDB", "Notes"]),
    (_ATAXIA + ["Ataxia NDB", "Actions"], ["Levi_Ataxia", "Ataxia", "NDB", "Actions"]),
    (_ATAXIA + ["Ataxia NDB", "Configs"], ["Levi_Ataxia", "Ataxia", "NDB", "Configs"]),
    (_ATAXIA + ["Ataxia NDB"], ["Levi_Ataxia", "Ataxia", "NDB"]),

    # ── Ataxia config: Basher ──
    (_ATAXIA + ["Autobashing", "Configs"], ["Levi_Ataxia", "Ataxia", "Basher", "Configs"]),
    (_ATAXIA + ["Autobashing", "Lists"], ["Levi_Ataxia", "Ataxia", "Basher", "Lists"]),
    (_ATAXIA + ["Autobashing"], ["Levi_Ataxia", "Ataxia", "Basher"]),

    # ── Ataxia config: Defence ──
    (_ATAXIA + ["Defence Stuff", "Configuration Commands"], ["Levi_Ataxia", "Ataxia", "Defence Config"]),

    # ── Ataxia config: Installation / Configuration ──
    (_ATAXIA + ["Installation / Configuration", "Toggles/Settings/Etc."], ["Levi_Ataxia", "Ataxia", "Config", "Toggles"]),
    (_ATAXIA + ["Installation / Configuration", "Custom Prompt Aliases"], ["Levi_Ataxia", "Ataxia", "Config", "Prompt"]),
    (_ATAXIA + ["Installation / Configuration", "Magi Things"], ["Levi_Ataxia", "Ataxia", "Config", "Magi"]),
    (_ATAXIA + ["Installation / Configuration", "Bard Things"], ["Levi_Ataxia", "Ataxia", "Config", "Bard"]),
    (_ATAXIA + ["Installation / Configuration", "Sylvan Things"], ["Levi_Ataxia", "Ataxia", "Config", "Sylvan"]),
    (_ATAXIA + ["Installation / Configuration"], ["Levi_Ataxia", "Ataxia", "Config"]),

    # ── Ataxia config: Other ──
    (_ATAXIA + ["Other stuff", "Crafting/Tradeskill Related", "Inkmilling"], ["Levi_Ataxia", "Ataxia", "Crafting", "Inkmilling"]),
    (_ATAXIA + ["Other stuff", "Crafting/Tradeskill Related"], ["Levi_Ataxia", "Ataxia", "Crafting"]),
    (_ATAXIA + ["Other stuff"], ["Levi_Ataxia", "Ataxia"]),
    (_ATAXIA + ["Fishing"], ["Levi_Ataxia", "Ataxia", "Fishing"]),
    (_ATAXIA + ["Shaman System"], ["Levi_Ataxia", "Ataxia", "Shaman System"]),

    # ── Ataxia catch-all (files directly under Ataxia-DownloadThis > Ataxia) ──
    (_ATAXIA, ["Levi_Ataxia", "Ataxia"]),

    # ── Systems ──
    (_LEVI + ["Gear System"], ["Levi_Ataxia", "Systems", "Gear System"]),
    (_LEVI + ["zData", "zData"], ["Levi_Ataxia", "Systems", "zData"]),
    (_LEVI + ["LeviticusREG", "ZulahGUI - Saonji Edit", "zGUI Redux"], ["Levi_Ataxia", "Systems", "zGUI Redux"]),

    # ── Catch-all: anything still under the deep Leviticus prefix → root ──
    (_LEV, ["Levi_Ataxia"]),
    (_LEVI + ["LeviticusREG"], ["Levi_Ataxia"]),
    (_LEVI, ["Levi_Ataxia"]),
    (["Levi_Ataxia", "For Levi", "Levi_062424"], ["Levi_Ataxia"]),
    (["Levi_Ataxia", "For Levi"], ["Levi_Ataxia"]),
]

# Sort by longest old path first (most specific match wins)
HIERARCHY_MAP.sort(key=lambda x: len(x[0]), reverse=True)


def parse_hierarchy(content):
    """Extract hierarchy list from YAML header."""
    m = re.search(r'hierarchy:\n((?:- .+\n)+)', content)
    if not m:
        return None
    lines = m.group(1).strip().split('\n')
    return [line.strip().lstrip('- ') for line in lines]


def map_hierarchy(old_path):
    """Find the best matching mapping and return the new path."""
    for old_prefix, new_prefix in HIERARCHY_MAP:
        if len(old_path) >= len(old_prefix) and old_path[:len(old_prefix)] == old_prefix:
            # Replace the prefix, keep any suffix
            suffix = old_path[len(old_prefix):]
            return new_prefix + suffix
    return old_path  # No mapping found, keep as-is


def update_hierarchy_in_content(content, new_path):
    """Replace the hierarchy section in YAML header."""
    hierarchy_yaml = "hierarchy:\n" + "\n".join(f"- {name}" for name in new_path) + "\n"
    return re.sub(r'hierarchy:\n(?:- .+\n)+', hierarchy_yaml, content, count=1)


def main():
    parser = argparse.ArgumentParser(description="Flatten alias hierarchy")
    parser.add_argument("--src", required=True, help="Source directory (src_new)")
    parser.add_argument("--dry-run", action="store_true", help="Show changes without writing")
    args = parser.parse_args()

    alias_dir = os.path.join(args.src, "aliases", "levi_ataxia")
    if not os.path.isdir(alias_dir):
        print(f"ERROR: {alias_dir} not found")
        sys.exit(1)

    changed = 0
    unchanged = 0
    unmapped = []

    for root, dirs, files in os.walk(alias_dir):
        for f in files:
            if not f.endswith('.lua'):
                continue
            filepath = os.path.join(root, f)
            with open(filepath, 'r', encoding='utf-8') as fh:
                content = fh.read()

            old_path = parse_hierarchy(content)
            if old_path is None:
                continue

            new_path = map_hierarchy(old_path)

            if old_path == new_path:
                unchanged += 1
                continue

            if args.dry_run:
                print(f"  {' > '.join(old_path)}")
                print(f"  -> {' > '.join(new_path)}")
                print()
            else:
                new_content = update_hierarchy_in_content(content, new_path)
                with open(filepath, 'w', encoding='utf-8') as fh:
                    fh.write(new_content)

            changed += 1

    print(f"\nSummary: {changed} files {'would be ' if args.dry_run else ''}changed, {unchanged} unchanged")

    if unmapped:
        print(f"\nWARNING: {len(unmapped)} unmapped paths:")
        for p in sorted(set(unmapped)):
            print(f"  {p}")


if __name__ == "__main__":
    main()
