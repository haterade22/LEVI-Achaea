#!/usr/bin/env python3
"""
Convert existing src_new/ Mudlet package to Muddler project format.

Reads the YAML-header Lua files and _groups.yaml hierarchy definitions
from src_new/ and outputs a complete Muddler-compatible project tree.

Usage:
    python convert_to_muddler.py --src ./src_new --output ./muddler_project
    python convert_to_muddler.py --src ./src_new --output ./muddler_project --verbose
    python convert_to_muddler.py --src ./src_new --output ./muddler_project --dry-run
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# Add lib to path
sys.path.insert(0, str(Path(__file__).parent))

from lib.yaml_handler import YAMLHeaderHandler
from lib.hierarchy import HierarchyManager, GroupNode
import yaml

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

PACKAGE_NAME = "Levi_Ataxia"
PACKAGE_TITLE = "LEVI Combat System for Achaea"
PACKAGE_VERSION = "4.1"
PACKAGE_AUTHOR = "Leviticus"

# Only process items under these root group names (skip mudlet-mapper, echo, etc.)
INCLUDE_ROOTS = {"Levi_Ataxia"}

# Muddler type directory names
TYPE_DIRS = {
    "scripts": "scripts",
    "triggers": "triggers",
    "aliases": "aliases",
    "timers": "timers",
    "keys": "keys",
}

# Integer pattern type -> Muddler string name
PATTERN_TYPE_MAP = {
    0: "substring",
    1: "regex",
    2: "startOfLine",
    3: "exactMatch",
    4: "lua",
    5: "spacer",
    6: "color",
    7: "prompt",
}

# Qt key codes -> Muddler key names
KEY_CODE_MAP = {
    16777216: "Escape",
    16777217: "Tab",
    16777219: "Backspace",
    16777220: "Return",
    16777221: "Enter",
    16777222: "Insert",
    16777223: "Delete",
    16777224: "Pause",
    16777225: "Print",
    16777227: "Clear",
    16777232: "Home",
    16777233: "End",
    16777234: "Left",
    16777235: "Up",
    16777236: "Right",
    16777237: "Down",
    16777238: "PageUp",
    16777239: "PageDown",
    16777248: "Shift",
    16777249: "Control",
    16777251: "Alt",
    16777252: "CapsLock",
    16777253: "NumLock",
    16777254: "ScrollLock",
    16777399: "Menu",
    32: "Space",
}

# F1-F35
for _i in range(1, 36):
    KEY_CODE_MAP[16777264 + _i - 1] = f"F{_i}"

# Keypad 0-9
for _i in range(10):
    KEY_CODE_MAP[16777264 + 35 + _i] = f"KP_{_i}"


def key_code_to_string(code: int, modifier: int) -> str:
    """Convert Qt key code + modifier bitmask to Muddler key string."""
    parts = []
    if modifier & 67108864:
        parts.append("ctrl")
    if modifier & 33554432:
        parts.append("shift")
    if modifier & 134217728:
        parts.append("alt")
    if modifier & 268435456:
        parts.append("meta")

    if code in KEY_CODE_MAP:
        parts.append(KEY_CODE_MAP[code])
    elif 32 <= code <= 126:
        parts.append(chr(code))
    else:
        parts.append(str(code))

    return "+".join(parts) if len(parts) > 1 else (parts[0] if parts else str(code))


def fallback_yaml_parse(content: str) -> Tuple[Optional[Dict], str]:
    """Fallback parser for files where YAML parsing fails (e.g., unquoted special chars).

    Extracts the raw YAML text from the header, quotes problematic pattern strings,
    and retries parsing.
    """
    match = re.match(r'^--\[\[mudlet\s*\n(.*?)\n\]\]--\s*\n?', content, re.MULTILINE | re.DOTALL)
    if not match:
        return None, content

    yaml_text = match.group(1)
    lua_code = content[match.end():].lstrip('\n')

    # Fix: quote unquoted pattern values that contain special YAML characters
    # Match lines like "- pattern: ^some(regex)$" and wrap the value in single quotes
    fixed_lines = []
    for line in yaml_text.split('\n'):
        pattern_match = re.match(r'^(\s*-?\s*pattern:\s*)(.+)$', line)
        if pattern_match:
            prefix, value = pattern_match.groups()
            value = value.strip()
            # If not already quoted, wrap in single quotes (escaping existing single quotes)
            if not (value.startswith("'") and value.endswith("'")) and \
               not (value.startswith('"') and value.endswith('"')):
                value = "'" + value.replace("'", "''") + "'"
            fixed_lines.append(prefix + value)
        else:
            fixed_lines.append(line)

    try:
        metadata = yaml.safe_load('\n'.join(fixed_lines))
        return metadata, lua_code
    except yaml.YAMLError:
        return None, lua_code


def sanitize_lua_filename(name: str) -> str:
    """Convert a name to a valid Lua filename (Muddler convention: spaces -> underscores)."""
    name = re.sub(r'[<>:"/\\|?*]', '_', name)
    name = name.replace(' ', '_')
    name = re.sub(r'_+', '_', name)
    name = name.strip('_.')
    return name if name else "unnamed"


def parse_time(time_str: str) -> Dict[str, str]:
    """Parse HH:MM:SS.mmm to Muddler timer fields."""
    match = re.match(r'(\d+):(\d+):(\d+)(?:\.(\d+))?', time_str or "00:00:00.000")
    if not match:
        return {"hours": "0", "minutes": "0", "seconds": "0", "milliseconds": "0"}
    h, m, s, ms = match.groups()
    return {
        "hours": str(int(h)),
        "minutes": str(int(m)),
        "seconds": str(int(s)),
        "milliseconds": str(int(ms or 0)),
    }


# ---------------------------------------------------------------------------
# Converter
# ---------------------------------------------------------------------------

class MuddlerConverter:
    """Convert src_new/ structure to Muddler project."""

    def __init__(self, src_dir: str, output_dir: str, verbose: bool = False, dry_run: bool = False):
        self.src_dir = Path(src_dir)
        self.output_dir = Path(output_dir)
        self.verbose = verbose
        self.dry_run = dry_run
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.stats = defaultdict(int)
        # name -> count per type, for collision detection
        self._name_registry: Dict[str, Dict[str, int]] = defaultdict(lambda: defaultdict(int))

    def log(self, msg: str):
        if self.verbose:
            print(msg)

    # ------------------------------------------------------------------
    # Entry point
    # ------------------------------------------------------------------

    def convert(self) -> bool:
        """Run the full conversion. Returns True on success."""
        print(f"Converting: {self.src_dir} -> {self.output_dir}")
        print()

        if not self.src_dir.exists():
            print(f"ERROR: Source directory not found: {self.src_dir}")
            return False

        # Phase 1: Scan all files and detect name collisions per type
        print("Phase 1: Scanning files and detecting name collisions...")
        all_items: Dict[str, List[Tuple[Path, Dict, str]]] = {}
        for pkg_type in TYPE_DIRS:
            items = self._read_lua_files(pkg_type)
            all_items[pkg_type] = items
            print(f"  {pkg_type}: {len(items)} items")

        # Phase 2: Build collision-free name maps
        print("\nPhase 2: Resolving name collisions...")
        name_maps: Dict[str, Dict[str, str]] = {}  # type -> {original_key -> safe_filename}
        for pkg_type, items in all_items.items():
            name_maps[pkg_type] = self._build_name_map(pkg_type, items)

        # Phase 3: Load hierarchies and build JSON trees
        print("\nPhase 3: Building Muddler hierarchy trees...")
        json_trees: Dict[str, list] = {}
        for pkg_type in TYPE_DIRS:
            tree = self._build_muddler_tree(pkg_type, all_items[pkg_type], name_maps[pkg_type])
            json_trees[pkg_type] = tree
            self.log(f"  {pkg_type}: built tree with {len(tree)} root entries")

        if self.dry_run:
            print("\n[DRY RUN] Would write output to:", self.output_dir)
            self._print_summary()
            return True

        # Phase 4: Write output
        print("\nPhase 4: Writing Muddler project...")
        self._write_output(json_trees, all_items, name_maps)

        self._print_summary()
        return len(self.errors) == 0

    # ------------------------------------------------------------------
    # Phase 1: Read Lua files
    # ------------------------------------------------------------------

    def _read_lua_files(self, pkg_type: str) -> List[Tuple[Path, Dict, str]]:
        """Read all Lua files for a package type, filtering to Levi_Ataxia only."""
        base_dir = self.src_dir / pkg_type
        if not base_dir.exists():
            return []

        items = []
        for lua_file in sorted(base_dir.rglob("*.lua")):
            # Filter: only include files under levi_ataxia/ subdirectory
            rel = lua_file.relative_to(base_dir)
            parts = rel.parts
            if not parts or parts[0] != "levi_ataxia":
                self.log(f"  SKIP (not levi_ataxia): {rel}")
                continue

            try:
                content = lua_file.read_text(encoding='utf-8')
                try:
                    metadata, lua_code = YAMLHeaderHandler.parse(content)
                except ValueError:
                    # YAML parse error - try fallback parser (handles unquoted patterns)
                    metadata, lua_code = fallback_yaml_parse(content)
                    if metadata:
                        self.warnings.append(f"Used fallback YAML parser: {lua_file}")
                if metadata is None:
                    self.warnings.append(f"No YAML header: {lua_file}")
                    continue
                items.append((lua_file, metadata, lua_code))
            except Exception as e:
                self.errors.append(f"Error reading {lua_file}: {e}")

        return items

    # ------------------------------------------------------------------
    # Phase 2: Name collision resolution
    # ------------------------------------------------------------------

    def _build_name_map(self, pkg_type: str, items: List[Tuple[Path, Dict, str]]) -> Dict[str, str]:
        """Build a map from (file_path_str) -> safe Lua filename, handling collisions."""
        # First pass: count occurrences of each name
        name_counts: Dict[str, int] = defaultdict(int)
        file_names: Dict[str, str] = {}  # file_path_str -> original name

        for file_path, metadata, _ in items:
            name = metadata.get("name", "unnamed")
            name_counts[name] += 1
            file_names[str(file_path)] = name

        # Second pass: disambiguate collisions
        result: Dict[str, str] = {}
        used_filenames: Dict[str, int] = defaultdict(int)

        for file_path, metadata, _ in items:
            name = metadata.get("name", "unnamed")
            hierarchy = metadata.get("hierarchy", [])

            if name_counts[name] > 1 and hierarchy:
                # Disambiguate: prepend last hierarchy element
                parent = hierarchy[-1] if hierarchy else ""
                candidate = f"{parent}_{name}" if parent else name
                # If still colliding, try two levels
                if used_filenames.get(sanitize_lua_filename(candidate), 0) > 0 and len(hierarchy) >= 2:
                    candidate = f"{hierarchy[-2]}_{hierarchy[-1]}_{name}"
            else:
                candidate = name

            safe = sanitize_lua_filename(candidate)

            # Final collision guard: append counter
            if used_filenames[safe] > 0:
                counter = used_filenames[safe] + 1
                safe = f"{safe}_{counter}"

            used_filenames[safe] += 1
            result[str(file_path)] = safe

        collisions = sum(1 for c in name_counts.values() if c > 1)
        if collisions:
            print(f"  {pkg_type}: {collisions} name collisions resolved")
        else:
            print(f"  {pkg_type}: no collisions")

        return result

    # ------------------------------------------------------------------
    # Phase 3: Build Muddler JSON tree
    # ------------------------------------------------------------------

    def _build_muddler_tree(
        self,
        pkg_type: str,
        items: List[Tuple[Path, Dict, str]],
        name_map: Dict[str, str],
    ) -> list:
        """Build the Muddler JSON tree for one package type."""
        # Load the _groups.yaml hierarchy
        hmgr = HierarchyManager(self.src_dir / pkg_type, pkg_type)
        hmgr.load()

        # Find the Levi_Ataxia root group(s)
        levi_roots = [g for g in hmgr.root_groups if g.name in INCLUDE_ROOTS]
        if not levi_roots:
            self.warnings.append(f"No '{PACKAGE_NAME}' root group found in {pkg_type} _groups.yaml")
            return []

        # Collect all known group hierarchy paths from _groups.yaml
        known_groups: set = set()
        def collect_known(node: GroupNode, parent: tuple):
            path = parent + (node.name,)
            known_groups.add(path)
            for c in node.children:
                collect_known(c, path)
        for root in levi_roots:
            collect_known(root, ())

        # Auto-create missing intermediate groups in the _groups.yaml tree
        # for items whose hierarchy references groups not in _groups.yaml
        for file_path, metadata, lua_code in items:
            hierarchy = tuple(metadata.get("hierarchy", []))
            if hierarchy and hierarchy not in known_groups and hierarchy[0] in INCLUDE_ROOTS:
                # Walk the hierarchy and create missing nodes
                self._ensure_group_path(levi_roots, hierarchy, known_groups)

        # Index items by hierarchy tuple for fast lookup
        items_by_hierarchy: Dict[tuple, List[Tuple[Path, Dict, str]]] = defaultdict(list)
        for file_path, metadata, lua_code in items:
            hierarchy = tuple(metadata.get("hierarchy", []))
            items_by_hierarchy[hierarchy].append((file_path, metadata, lua_code))

        # Recursively build the JSON tree from the group hierarchy
        result = []
        for root_group in levi_roots:
            json_node = self._group_to_json(root_group, pkg_type, items_by_hierarchy, name_map, [])
            if json_node:
                result.append(json_node)

        return result

    def _ensure_group_path(
        self,
        root_groups: List[GroupNode],
        hierarchy: tuple,
        known_groups: set,
    ):
        """Ensure all group nodes exist along a hierarchy path, creating missing ones."""
        if not hierarchy or hierarchy[0] not in INCLUDE_ROOTS:
            return

        # Find root
        root = next((g for g in root_groups if g.name == hierarchy[0]), None)
        if not root:
            return

        current = root
        for i, name in enumerate(hierarchy[1:], start=1):
            path_so_far = hierarchy[:i + 1]
            if path_so_far in known_groups:
                # Already exists - navigate to it
                child = next((c for c in current.children if c.name == name), None)
                if child:
                    current = child
                    continue
            # Need to create this group node
            child = next((c for c in current.children if c.name == name), None)
            if not child:
                child = GroupNode(name=name, is_active=True)
                current.children.append(child)
                self.log(f"  AUTO-CREATE group: {' > '.join(hierarchy[:i+1])}")
            known_groups.add(path_so_far)
            current = child

    def _group_to_json(
        self,
        group: GroupNode,
        pkg_type: str,
        items_by_hierarchy: Dict[tuple, List],
        name_map: Dict[str, str],
        parent_hierarchy: List[str],
    ) -> Optional[Dict[str, Any]]:
        """Convert a GroupNode and its children to a Muddler JSON dict."""
        current_hierarchy = parent_hierarchy + [group.name]
        hierarchy_key = tuple(current_hierarchy)

        node: Dict[str, Any] = {
            "name": group.name,
            "isActive": "yes" if group.is_active else "no",
            "isFolder": "yes",
        }

        # Group-level inline script
        if group.script and group.script.strip():
            script_text = group.script.strip()
            # Skip placeholder scripts (Mudlet default comments)
            if not script_text.startswith("-------------------------------------------------"):
                node["script"] = script_text

        children_json = []

        # Add child groups first (preserving order)
        for child_group in group.children:
            child_json = self._group_to_json(
                child_group, pkg_type, items_by_hierarchy, name_map, current_hierarchy
            )
            if child_json:
                children_json.append(child_json)

        # Add leaf items that belong to this hierarchy
        leaf_items = items_by_hierarchy.get(hierarchy_key, [])
        for file_path, metadata, lua_code in leaf_items:
            safe_name = name_map.get(str(file_path), sanitize_lua_filename(metadata.get("name", "unnamed")))
            item_json = self._item_to_json(metadata, lua_code, safe_name, pkg_type)
            if item_json:
                children_json.append(item_json)
                self.stats[f"{pkg_type}_items"] += 1

        if children_json:
            node["children"] = children_json

        return node

    def _item_to_json(self, metadata: Dict, lua_code: str, safe_name: str, pkg_type: str) -> Optional[Dict[str, Any]]:
        """Convert a single item's metadata to Muddler JSON."""
        name = metadata.get("name", "unnamed")
        attrs = metadata.get("attributes", {})

        if pkg_type == "triggers":
            return self._trigger_to_json(metadata, lua_code, safe_name)
        elif pkg_type == "scripts":
            return self._script_to_json(metadata, lua_code, safe_name)
        elif pkg_type == "aliases":
            return self._alias_to_json(metadata, lua_code, safe_name)
        elif pkg_type == "timers":
            return self._timer_to_json(metadata, lua_code, safe_name)
        elif pkg_type == "keys":
            return self._key_to_json(metadata, lua_code, safe_name)
        return None

    def _trigger_to_json(self, metadata: Dict, lua_code: str, safe_name: str) -> Dict[str, Any]:
        """Convert trigger metadata to Muddler JSON."""
        attrs = metadata.get("attributes", {})
        result: Dict[str, Any] = {"name": metadata.get("name", "unnamed")}

        # isActive
        is_active = attrs.get("isActive", "yes")
        if is_active != "yes":
            result["isActive"] = is_active

        # Patterns
        patterns = metadata.get("patterns", [])
        if patterns:
            muddler_patterns = []
            for p in patterns:
                ptype_int = p.get("type", 0)
                if isinstance(ptype_int, str):
                    try:
                        ptype_int = int(ptype_int)
                    except ValueError:
                        ptype_int = 0
                ptype_str = PATTERN_TYPE_MAP.get(ptype_int, "substring")
                muddler_patterns.append({
                    "pattern": p.get("pattern", ""),
                    "type": ptype_str,
                })
            result["patterns"] = muddler_patterns

        # Optional trigger attributes (only include non-default values)
        if attrs.get("isMultiline", "no") == "yes":
            result["multiline"] = "yes"
            delta = metadata.get("conditonLineDelta", 0)
            if delta:
                result["multilineDelta"] = int(delta)

        if attrs.get("isFilterTrigger", "no") == "yes":
            result["filter"] = "yes"

        if attrs.get("isColorizerTrigger", "no") == "yes":
            result["highlight"] = "yes"
            fg = metadata.get("mFgColor", "")
            bg = metadata.get("mBgColor", "")
            if fg and fg != "#ff0000":
                result["highlightFG"] = fg
            if bg and bg != "#ffff00":
                result["highlightBG"] = bg

        m_stay_open = metadata.get("mStayOpen", 0)
        if m_stay_open and int(m_stay_open) > 0:
            result["fireLength"] = int(m_stay_open)

        m_command = metadata.get("mCommand", "")
        if m_command:
            result["command"] = m_command

        if attrs.get("isSoundTrigger", "no") == "yes":
            sound = metadata.get("mSoundFile", "")
            if sound:
                result["soundFile"] = sound

        if attrs.get("matchall", "no") == "yes":
            result["matchall"] = "yes"

        # The Lua code will be in a separate file; Muddler auto-reads $name.lua
        # But we need to track the safe_name for file writing
        result["_safe_name"] = safe_name
        result["_lua_code"] = lua_code

        return result

    def _script_to_json(self, metadata: Dict, lua_code: str, safe_name: str) -> Dict[str, Any]:
        """Convert script metadata to Muddler JSON."""
        attrs = metadata.get("attributes", {})
        result: Dict[str, Any] = {"name": metadata.get("name", "unnamed")}

        is_active = attrs.get("isActive", "yes")
        if is_active != "yes":
            result["isActive"] = is_active

        handlers = metadata.get("eventHandlers", [])
        if handlers:
            result["eventHandlerList"] = handlers

        result["_safe_name"] = safe_name
        result["_lua_code"] = lua_code
        return result

    def _alias_to_json(self, metadata: Dict, lua_code: str, safe_name: str) -> Dict[str, Any]:
        """Convert alias metadata to Muddler JSON."""
        attrs = metadata.get("attributes", {})
        result: Dict[str, Any] = {"name": metadata.get("name", "unnamed")}

        is_active = attrs.get("isActive", "yes")
        if is_active != "yes":
            result["isActive"] = is_active

        regex = metadata.get("regex", "")
        if regex:
            result["regex"] = regex

        command = metadata.get("command", "")
        if command:
            result["command"] = command

        result["_safe_name"] = safe_name
        result["_lua_code"] = lua_code
        return result

    def _timer_to_json(self, metadata: Dict, lua_code: str, safe_name: str) -> Dict[str, Any]:
        """Convert timer metadata to Muddler JSON."""
        attrs = metadata.get("attributes", {})
        result: Dict[str, Any] = {"name": metadata.get("name", "unnamed")}

        is_active = attrs.get("isActive", "yes")
        if is_active != "yes":
            result["isActive"] = is_active

        # Parse time
        time_str = metadata.get("time", "00:00:00.000")
        time_parts = parse_time(time_str)
        result.update(time_parts)

        command = metadata.get("command", "")
        if command:
            result["command"] = command

        result["_safe_name"] = safe_name
        result["_lua_code"] = lua_code
        return result

    def _key_to_json(self, metadata: Dict, lua_code: str, safe_name: str) -> Dict[str, Any]:
        """Convert key metadata to Muddler JSON."""
        attrs = metadata.get("attributes", {})
        result: Dict[str, Any] = {"name": metadata.get("name", "unnamed")}

        is_active = attrs.get("isActive", "yes")
        if is_active != "yes":
            result["isActive"] = is_active

        key_code = metadata.get("keyCode", 0)
        key_mod = metadata.get("keyModifier", 0)
        if key_code:
            result["keys"] = key_code_to_string(int(key_code), int(key_mod))

        command = metadata.get("command", "")
        if command:
            result["command"] = command

        result["_safe_name"] = safe_name
        result["_lua_code"] = lua_code
        return result

    # ------------------------------------------------------------------
    # Phase 4: Write output
    # ------------------------------------------------------------------

    def _write_output(
        self,
        json_trees: Dict[str, list],
        all_items: Dict[str, List],
        name_maps: Dict[str, Dict[str, str]],
    ):
        """Write the complete Muddler project directory."""
        # Create directory structure
        self.output_dir.mkdir(parents=True, exist_ok=True)
        (self.output_dir / "src" / "resources").mkdir(parents=True, exist_ok=True)

        # Write mfile
        mfile = {
            "package": PACKAGE_NAME,
            "title": PACKAGE_TITLE,
            "version": PACKAGE_VERSION,
            "author": PACKAGE_AUTHOR,
        }
        mfile_path = self.output_dir / "mfile"
        mfile_path.write_text(json.dumps(mfile, indent=2), encoding='utf-8')
        print(f"  Wrote: {mfile_path}")

        # Write each type
        for pkg_type in TYPE_DIRS:
            tree = json_trees.get(pkg_type, [])
            items = all_items.get(pkg_type, [])
            nmap = name_maps.get(pkg_type, {})

            if not tree and not items:
                continue

            type_dir = self.output_dir / "src" / TYPE_DIRS[pkg_type] / PACKAGE_NAME
            type_dir.mkdir(parents=True, exist_ok=True)

            # Collect all Lua files from the tree (recursively)
            lua_files: Dict[str, str] = {}  # safe_name -> lua_code
            clean_tree = self._extract_lua_files(tree, lua_files)

            # Write JSON
            json_name = f"{TYPE_DIRS[pkg_type]}.json"
            json_path = type_dir / json_name
            json_path.write_text(
                json.dumps(clean_tree, indent=2, ensure_ascii=False),
                encoding='utf-8'
            )
            print(f"  Wrote: {json_path} ({len(clean_tree)} root entries)")

            # Write Lua files
            lua_count = 0
            for safe_name, lua_code in lua_files.items():
                if lua_code.strip():
                    lua_path = type_dir / f"{safe_name}.lua"
                    lua_path.write_text(lua_code, encoding='utf-8')
                    lua_count += 1

            print(f"  Wrote: {lua_count} Lua files to {type_dir}")
            self.stats[f"{pkg_type}_lua_files"] = lua_count

    def _extract_lua_files(self, tree: list, lua_files: Dict[str, str]) -> list:
        """Recursively extract _lua_code/_safe_name from tree nodes, returning clean JSON."""
        clean = []
        for node in tree:
            clean_node = {}
            for key, value in node.items():
                if key == "_lua_code":
                    continue
                elif key == "_safe_name":
                    continue
                elif key == "children":
                    clean_node["children"] = self._extract_lua_files(value, lua_files)
                else:
                    clean_node[key] = value

            # Extract Lua file if present
            safe_name = node.get("_safe_name")
            lua_code = node.get("_lua_code", "")
            if safe_name and lua_code.strip():
                lua_files[safe_name] = lua_code

            clean.append(clean_node)

        return clean

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------

    def _print_summary(self):
        print()
        print("=" * 60)
        print("Conversion Summary")
        print("=" * 60)
        for key, value in sorted(self.stats.items()):
            print(f"  {key}: {value}")

        if self.warnings:
            print(f"\nWarnings ({len(self.warnings)}):")
            for w in self.warnings[:20]:
                print(f"  - {w}")
            if len(self.warnings) > 20:
                print(f"  ... and {len(self.warnings) - 20} more")

        if self.errors:
            print(f"\nErrors ({len(self.errors)}):")
            for e in self.errors[:20]:
                print(f"  - {e}")
            if len(self.errors) > 20:
                print(f"  ... and {len(self.errors) - 20} more")

        if not self.errors:
            print("\nConversion completed successfully!")
        else:
            print(f"\nConversion completed with {len(self.errors)} errors.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Convert src_new/ Mudlet package to Muddler project format"
    )
    parser.add_argument(
        "--src", "-s",
        default="./src_new",
        help="Source directory with extracted files (default: ./src_new)"
    )
    parser.add_argument(
        "--output", "-o",
        default="./muddler_project",
        help="Output Muddler project directory (default: ./muddler_project)"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    parser.add_argument(
        "--dry-run", "-n",
        action="store_true",
        help="Scan and report without writing output"
    )

    args = parser.parse_args()

    converter = MuddlerConverter(
        src_dir=args.src,
        output_dir=args.output,
        verbose=args.verbose,
        dry_run=args.dry_run,
    )

    success = converter.convert()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
