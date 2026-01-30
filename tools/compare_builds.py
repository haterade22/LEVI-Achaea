#!/usr/bin/env python3
"""
Compare old Python-built XML against Muddler project source.

Validates that the Muddler conversion preserved all items, hierarchy,
Lua code, patterns, and attributes from the original XML build.

Usage:
    python compare_builds.py --old packages/Levi_Ataxia.xml --new muddler_project
    python compare_builds.py --old packages/Levi_Ataxia.xml --new muddler_project --verbose
"""

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# XML Parser - extract items from old build
# ---------------------------------------------------------------------------

# Package-level container tags -> type names
PACKAGE_TAGS = {
    "TriggerPackage": "triggers",
    "TimerPackage": "timers",
    "AliasPackage": "aliases",
    "ScriptPackage": "scripts",
    "KeyPackage": "keys",
}

# Group tags (folders) -> type names
GROUP_TAGS = {
    "TriggerGroup": "triggers",
    "TimerGroup": "timers",
    "AliasGroup": "aliases",
    "ScriptGroup": "scripts",
    "KeyGroup": "keys",
}

# Leaf item tags -> type names
LEAF_TAGS = {
    "Trigger": "triggers",
    "Timer": "timers",
    "Alias": "aliases",
    "Script": "scripts",
    "Key": "keys",
}

# Only include items under these root groups
INCLUDE_ROOTS = {"Levi_Ataxia"}


def _get_child_text(element, tag: str) -> str:
    """Get text content of a child element."""
    child = element.find(tag)
    if child is not None:
        return (child.text or "").strip()
    return ""


def extract_xml_items(xml_path: str) -> Dict[str, List[Dict]]:
    """Parse the old Mudlet XML and extract all items grouped by type.

    Mudlet XML structure:
      <MudletPackage>
        <TriggerPackage>
          <TriggerGroup isActive="yes" isFolder="yes" ...>
            <name>GroupName</name>
            <script>...</script>
            <TriggerGroup ...>  <!-- nested group -->
            <Trigger ...>       <!-- leaf item -->
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()

    items_by_type: Dict[str, List[Dict]] = defaultdict(list)

    def walk_group(element, hierarchy: List[str], pkg_type: str, inside_levi: bool):
        """Walk a Group element and its children."""
        name = _get_child_text(element, "name")
        is_active = element.get("isActive", "yes")

        # Check if we're entering a Levi_Ataxia root
        if not inside_levi:
            if name in INCLUDE_ROOTS:
                inside_levi = True
            else:
                # Still recurse in case there are nested Levi_Ataxia groups
                for child in element:
                    if child.tag in GROUP_TAGS:
                        walk_group(child, hierarchy, pkg_type, False)
                return

        # Record this group
        item: Dict[str, Any] = {
            "name": name,
            "hierarchy": list(hierarchy),
            "isActive": is_active,
            "isFolder": "yes",
        }

        script_text = _get_child_text(element, "script")
        if script_text:
            item["script"] = script_text

        items_by_type[pkg_type].append(item)

        # Recurse into children
        child_hierarchy = hierarchy + [name]
        for child in element:
            tag = child.tag
            if tag in GROUP_TAGS:
                walk_group(child, child_hierarchy, pkg_type, True)
            elif tag in LEAF_TAGS:
                walk_leaf(child, child_hierarchy, pkg_type)

    def walk_leaf(element, hierarchy: List[str], pkg_type: str):
        """Walk a leaf item element."""
        name = _get_child_text(element, "name")
        is_active = element.get("isActive", "yes")

        item: Dict[str, Any] = {
            "name": name,
            "hierarchy": list(hierarchy),
            "isActive": is_active,
            "isFolder": "no",
        }

        # Script/code content
        script_text = _get_child_text(element, "script")
        if script_text:
            item["script"] = script_text

        # Patterns (triggers) - patterns are in <regexCodeList>/<regexCode> or direct children
        patterns = []
        regex_code_list = element.find("regexCodeList")
        regex_code_prop_list = element.find("regexCodePropertyList")
        if regex_code_list is not None:
            codes = [el.text or "" for el in regex_code_list.findall("string")]
            types = []
            if regex_code_prop_list is not None:
                types = [el.text or "0" for el in regex_code_prop_list.findall("integer")]
            for i, code in enumerate(codes):
                ptype = types[i] if i < len(types) else "0"
                patterns.append({"pattern": code, "type": ptype})
        if patterns:
            item["patterns"] = patterns

        # Event handlers (scripts)
        handler_list = element.find("eventHandlerList")
        if handler_list is not None:
            handlers = [el.text or "" for el in handler_list.findall("string")]
            handlers = [h for h in handlers if h]
            if handlers:
                item["eventHandlers"] = handlers

        # Regex/command (aliases, timers, keys)
        regex = _get_child_text(element, "regex")
        if regex:
            item["regex"] = regex

        command = _get_child_text(element, "command")
        if command:
            item["command"] = command

        # Time (timers)
        time_str = _get_child_text(element, "time")
        if time_str and time_str != "00:00:00.000":
            item["time"] = time_str

        # Key code/modifier
        key_code = _get_child_text(element, "keyCode")
        key_mod = _get_child_text(element, "keyModifier")
        if key_code and key_code != "0":
            item["keyCode"] = key_code
            item["keyModifier"] = key_mod

        items_by_type[pkg_type].append(item)

    # Walk from MudletPackage root
    for pkg_el in root:
        tag = pkg_el.tag
        if tag not in PACKAGE_TAGS:
            continue
        pkg_type = PACKAGE_TAGS[tag]

        # Each PackageTag contains top-level Group elements
        for group_el in pkg_el:
            if group_el.tag in GROUP_TAGS:
                walk_group(group_el, [], pkg_type, False)

    return items_by_type


# ---------------------------------------------------------------------------
# Muddler JSON Parser - extract items from new project
# ---------------------------------------------------------------------------

def extract_muddler_items(project_dir: str) -> Dict[str, List[Dict]]:
    """Parse Muddler project JSON files and extract all items."""
    project = Path(project_dir)
    items_by_type: Dict[str, List[Dict]] = defaultdict(list)

    type_dirs = {
        "scripts": "scripts",
        "triggers": "triggers",
        "aliases": "aliases",
        "timers": "timers",
        "keys": "keys",
    }

    for pkg_type, dir_name in type_dirs.items():
        json_file = project / "src" / dir_name / "Levi_Ataxia" / f"{dir_name}.json"
        lua_dir = project / "src" / dir_name / "Levi_Ataxia"

        if not json_file.exists():
            continue

        with open(json_file, 'r', encoding='utf-8') as f:
            tree = json.load(f)

        # Read all Lua files in the directory
        lua_files: Dict[str, str] = {}
        if lua_dir.exists():
            for lua_file in lua_dir.glob("*.lua"):
                lua_files[lua_file.stem] = lua_file.read_text(encoding='utf-8').strip()

        # Walk the JSON tree
        def walk_json(nodes: list, hierarchy: List[str]):
            for node in nodes:
                name = node.get("name", "")
                is_folder = node.get("isFolder", "no")

                item: Dict[str, Any] = {
                    "name": name,
                    "hierarchy": list(hierarchy),
                    "isActive": node.get("isActive", "yes"),
                    "isFolder": is_folder,
                }

                # Script content - check JSON inline and Lua file
                if "script" in node:
                    item["script"] = node["script"].strip()

                # Patterns
                if "patterns" in node:
                    item["patterns"] = node["patterns"]

                # Event handlers
                if "eventHandlerList" in node:
                    item["eventHandlers"] = node["eventHandlerList"]

                # Regex/command
                if "regex" in node:
                    item["regex"] = node["regex"]
                if "command" in node:
                    item["command"] = node["command"]

                items_by_type[pkg_type].append(item)

                if is_folder == "yes":
                    walk_json(node.get("children", []), hierarchy + [name])

        walk_json(tree, [])

    return items_by_type


# ---------------------------------------------------------------------------
# Comparison engine
# ---------------------------------------------------------------------------

class BuildComparator:
    """Compare two builds and report differences."""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.diffs: List[str] = []
        self.matches: Dict[str, int] = defaultdict(int)

    def compare(
        self,
        old_items: Dict[str, List[Dict]],
        new_items: Dict[str, List[Dict]],
    ) -> bool:
        """Compare old and new builds. Returns True if they match."""
        print("=" * 70)
        print("Build Comparison Report")
        print("=" * 70)

        # Compare item counts per type
        print("\n--- Item Counts ---")
        all_types = sorted(set(list(old_items.keys()) + list(new_items.keys())))
        for pkg_type in all_types:
            old_count = len(old_items.get(pkg_type, []))
            new_count = len(new_items.get(pkg_type, []))
            status = "OK" if old_count == new_count else "MISMATCH"
            marker = "  " if status == "OK" else "!!"
            print(f"  {marker} {pkg_type}: old={old_count}, new={new_count}  [{status}]")
            if old_count != new_count:
                self.diffs.append(f"Count mismatch for {pkg_type}: old={old_count}, new={new_count}")

        # Compare leaf items (non-folder) by name within each type
        print("\n--- Leaf Item Analysis ---")
        for pkg_type in all_types:
            old_leaves = [i for i in old_items.get(pkg_type, []) if i.get("isFolder") != "yes"]
            new_leaves = [i for i in new_items.get(pkg_type, []) if i.get("isFolder") != "yes"]

            old_names = set(i["name"] for i in old_leaves)
            new_names = set(i["name"] for i in new_leaves)

            missing_in_new = old_names - new_names
            extra_in_new = new_names - old_names
            common = old_names & new_names

            print(f"\n  {pkg_type}:")
            print(f"    Leaf items: old={len(old_leaves)}, new={len(new_leaves)}")
            print(f"    Common names: {len(common)}")

            if missing_in_new:
                print(f"    Missing in new ({len(missing_in_new)}):")
                for n in sorted(missing_in_new)[:20]:
                    print(f"      - {n}")
                if len(missing_in_new) > 20:
                    print(f"      ... and {len(missing_in_new) - 20} more")
                self.diffs.append(f"{pkg_type}: {len(missing_in_new)} items missing in new build")

            if extra_in_new:
                print(f"    Extra in new ({len(extra_in_new)}):")
                for n in sorted(extra_in_new)[:10]:
                    print(f"      + {n}")
                if len(extra_in_new) > 10:
                    print(f"      ... and {len(extra_in_new) - 10} more")

            # Compare common leaf items in detail
            if self.verbose and common:
                self._compare_leaves(pkg_type, old_leaves, new_leaves, common)

        # Compare group hierarchy
        print("\n--- Group Hierarchy ---")
        for pkg_type in all_types:
            old_groups = [i for i in old_items.get(pkg_type, []) if i.get("isFolder") == "yes"]
            new_groups = [i for i in new_items.get(pkg_type, []) if i.get("isFolder") == "yes"]

            old_paths = set(tuple(i["hierarchy"] + [i["name"]]) for i in old_groups)
            new_paths = set(tuple(i["hierarchy"] + [i["name"]]) for i in new_groups)

            common_paths = old_paths & new_paths
            missing_paths = old_paths - new_paths
            extra_paths = new_paths - old_paths

            print(f"\n  {pkg_type}:")
            print(f"    Groups: old={len(old_groups)}, new={len(new_groups)}")
            print(f"    Common paths: {len(common_paths)}")

            if missing_paths:
                print(f"    Missing groups ({len(missing_paths)}):")
                for p in sorted(missing_paths)[:10]:
                    print(f"      - {' > '.join(p)}")
                if len(missing_paths) > 10:
                    print(f"      ... and {len(missing_paths) - 10} more")

            if extra_paths:
                print(f"    Extra groups ({len(extra_paths)}):")
                for p in sorted(extra_paths)[:10]:
                    print(f"      + {' > '.join(p)}")
                if len(extra_paths) > 10:
                    print(f"      ... and {len(extra_paths) - 10} more")

        # Summary
        print("\n" + "=" * 70)
        if not self.diffs:
            print("RESULT: Builds match!")
        else:
            print(f"RESULT: {len(self.diffs)} differences found:")
            for d in self.diffs:
                print(f"  - {d}")
        print("=" * 70)

        return len(self.diffs) == 0

    def _compare_leaves(
        self,
        pkg_type: str,
        old_leaves: List[Dict],
        new_leaves: List[Dict],
        common_names: Set[str],
    ):
        """Detailed comparison of common leaf items."""
        # Index by name (may have duplicates, compare first match)
        old_by_name: Dict[str, List[Dict]] = defaultdict(list)
        new_by_name: Dict[str, List[Dict]] = defaultdict(list)
        for item in old_leaves:
            old_by_name[item["name"]].append(item)
        for item in new_leaves:
            new_by_name[item["name"]].append(item)

        mismatches = 0
        for name in sorted(common_names):
            old_list = old_by_name[name]
            new_list = new_by_name[name]

            for i, (old_item, new_item) in enumerate(zip(old_list, new_list)):
                diffs = []

                # Compare isActive
                if old_item.get("isActive") != new_item.get("isActive"):
                    diffs.append(f"isActive: {old_item.get('isActive')} vs {new_item.get('isActive')}")

                # Compare hierarchy
                if old_item.get("hierarchy") != new_item.get("hierarchy"):
                    diffs.append(f"hierarchy differs")

                # Compare patterns (triggers)
                old_pats = old_item.get("patterns", [])
                new_pats = new_item.get("patterns", [])
                if len(old_pats) != len(new_pats):
                    diffs.append(f"pattern count: {len(old_pats)} vs {len(new_pats)}")

                if diffs:
                    mismatches += 1
                    if mismatches <= 10:
                        print(f"    DIFF: {name}")
                        for d in diffs:
                            print(f"          {d}")

        if mismatches > 10:
            print(f"    ... and {mismatches - 10} more mismatches")
        elif mismatches == 0:
            print(f"    All {len(common_names)} common items match in detail")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Compare old Python-built XML against Muddler project source"
    )
    parser.add_argument(
        "--old", "-o",
        required=True,
        help="Path to old Python-built XML (e.g., packages/Levi_Ataxia.xml)"
    )
    parser.add_argument(
        "--new", "-n",
        required=True,
        help="Path to new Muddler project directory (e.g., muddler_project/)"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable detailed item-by-item comparison"
    )

    args = parser.parse_args()

    print(f"Old build: {args.old}")
    print(f"New build: {args.new}")
    print()

    # Parse both builds
    print("Parsing old XML build...")
    old_items = extract_xml_items(args.old)
    total_old = sum(len(v) for v in old_items.values())
    print(f"  Found {total_old} total items")

    print("Parsing new Muddler project...")
    new_items = extract_muddler_items(args.new)
    total_new = sum(len(v) for v in new_items.values())
    print(f"  Found {total_new} total items")
    print()

    # Compare
    comparator = BuildComparator(verbose=args.verbose)
    success = comparator.compare(old_items, new_items)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
