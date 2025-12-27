#!/usr/bin/env python3
"""
Mudlet XML Package Extractor

Extracts all package types (triggers, timers, aliases, scripts, keys) from
a Mudlet XML package into editable Lua files with YAML metadata headers.

Usage:
    python mudlet_extract.py input.xml --output-dir ./src
    python mudlet_extract.py input.xml --type triggers --output-dir ./src/triggers
    python mudlet_extract.py input.xml --verbose
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional

# Add lib to path
sys.path.insert(0, str(Path(__file__).parent))

from lib.xml_parser import MudletXMLParser
from lib.yaml_handler import YAMLHeaderHandler
from lib.hierarchy import HierarchyManager, sanitize_filename
from lib.data_types import Trigger, Timer, Alias, Script, Key, Pattern


class MudletExtractor:
    """Extract Mudlet XML packages into editable file structure."""

    def __init__(self, xml_path: str, output_dir: str, verbose: bool = False):
        """
        Initialize extractor.

        Args:
            xml_path: Path to input XML file
            output_dir: Base output directory
            verbose: Enable verbose output
        """
        self.xml_path = Path(xml_path)
        self.output_dir = Path(output_dir)
        self.verbose = verbose
        self.parser = MudletXMLParser(xml_path)
        self.file_counts: Dict[str, int] = {}
        self.name_counters: Dict[str, Dict[str, int]] = {}  # Track duplicate names

    def log(self, msg: str):
        """Print message if verbose mode enabled."""
        if self.verbose:
            print(msg)

    def _get_unique_filename(self, directory: Path, base_name: str, ext: str = ".lua") -> str:
        """
        Generate a unique filename, handling duplicates.

        Args:
            directory: Target directory
            base_name: Base filename without extension
            ext: File extension

        Returns:
            Unique filename
        """
        dir_key = str(directory)
        if dir_key not in self.name_counters:
            self.name_counters[dir_key] = {}

        counters = self.name_counters[dir_key]
        safe_name = sanitize_filename(base_name)

        if safe_name not in counters:
            counters[safe_name] = 0
            return f"{safe_name}{ext}"

        counters[safe_name] += 1
        return f"{safe_name}_{counters[safe_name]}{ext}"

    def _write_lua_file(
        self,
        directory: Path,
        item: Any,
        metadata: Dict[str, Any],
        order: int
    ) -> Path:
        """
        Write a Lua file with YAML header.

        Args:
            directory: Target directory
            item: The element (Trigger, Timer, etc.)
            metadata: YAML metadata dictionary
            order: File order number

        Returns:
            Path to written file
        """
        directory.mkdir(parents=True, exist_ok=True)

        # Generate filename with order prefix
        base_name = sanitize_filename(item.name)
        unique_name = self._get_unique_filename(directory, base_name)
        filename = f"{order:03d}_{unique_name}"
        file_path = directory / filename

        # Combine metadata and code
        content = YAMLHeaderHandler.serialize(metadata, item.script)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        self.log(f"  Written: {file_path}")
        return file_path

    def _create_trigger_metadata(self, trigger: Trigger) -> Dict[str, Any]:
        """Create metadata dictionary for a trigger."""
        patterns = [
            {"pattern": p.pattern, "type": int(p.type)}
            for p in trigger.patterns
        ]

        return {
            "type": "trigger",
            "name": trigger.name,
            "hierarchy": trigger.hierarchy,
            "attributes": {
                "isActive": "yes" if trigger.is_active else "no",
                "isFolder": "yes" if trigger.is_folder else "no",
                "isTempTrigger": "yes" if trigger.is_temp_trigger else "no",
                "isMultiline": "yes" if trigger.is_multiline else "no",
                "isPerlSlashGOption": "yes" if trigger.is_perl_slash_g_option else "no",
                "isColorizerTrigger": "yes" if trigger.is_colorizer_trigger else "no",
                "isFilterTrigger": "yes" if trigger.is_filter_trigger else "no",
                "isSoundTrigger": "yes" if trigger.is_sound_trigger else "no",
                "isColorTrigger": "yes" if trigger.is_color_trigger else "no",
                "isColorTriggerFg": "yes" if trigger.is_color_trigger_fg else "no",
                "isColorTriggerBg": "yes" if trigger.is_color_trigger_bg else "no",
            },
            "triggerType": trigger.trigger_type,
            "conditonLineDelta": trigger.condition_line_delta,
            "mStayOpen": trigger.m_stay_open,
            "mCommand": trigger.m_command,
            "packageName": trigger.package_name,
            "mFgColor": trigger.m_fg_color,
            "mBgColor": trigger.m_bg_color,
            "mSoundFile": trigger.m_sound_file,
            "colorTriggerFgColor": trigger.color_trigger_fg_color,
            "colorTriggerBgColor": trigger.color_trigger_bg_color,
            "patterns": patterns,
        }

    def _create_timer_metadata(self, timer: Timer) -> Dict[str, Any]:
        """Create metadata dictionary for a timer."""
        return {
            "type": "timer",
            "name": timer.name,
            "hierarchy": timer.hierarchy,
            "attributes": {
                "isActive": "yes" if timer.is_active else "no",
                "isFolder": "yes" if timer.is_folder else "no",
                "isTempTimer": "yes" if timer.is_temp_timer else "no",
                "isOffsetTimer": "yes" if timer.is_offset_timer else "no",
            },
            "time": timer.time,
            "command": timer.command,
            "packageName": timer.package_name,
        }

    def _create_alias_metadata(self, alias: Alias) -> Dict[str, Any]:
        """Create metadata dictionary for an alias."""
        return {
            "type": "alias",
            "name": alias.name,
            "hierarchy": alias.hierarchy,
            "attributes": {
                "isActive": "yes" if alias.is_active else "no",
                "isFolder": "yes" if alias.is_folder else "no",
            },
            "regex": alias.regex,
            "command": alias.command,
            "packageName": alias.package_name,
        }

    def _create_script_metadata(self, script: Script) -> Dict[str, Any]:
        """Create metadata dictionary for a script."""
        metadata = {
            "type": "script",
            "name": script.name,
            "hierarchy": script.hierarchy,
            "attributes": {
                "isActive": "yes" if script.is_active else "no",
                "isFolder": "yes" if script.is_folder else "no",
            },
            "packageName": script.package_name,
        }
        if script.event_handlers:
            metadata["eventHandlers"] = script.event_handlers
        return metadata

    def _create_key_metadata(self, key: Key) -> Dict[str, Any]:
        """Create metadata dictionary for a key binding."""
        return {
            "type": "key",
            "name": key.name,
            "hierarchy": key.hierarchy,
            "attributes": {
                "isActive": "yes" if key.is_active else "no",
                "isFolder": "yes" if key.is_folder else "no",
            },
            "keyCode": key.key_code,
            "keyModifier": key.key_modifier,
            "command": key.command,
            "packageName": key.package_name,
        }

    def extract_triggers(self):
        """Extract all triggers to src/triggers/"""
        print("Extracting triggers...")
        base_dir = self.output_dir / "triggers"

        groups, triggers = self.parser.extract_triggers()
        print(f"  Found {len(triggers)} triggers in {len(groups)} groups")

        if not triggers:
            return

        # Set up hierarchy manager
        hierarchy_mgr = HierarchyManager(base_dir, "triggers")
        hierarchy_mgr.add_groups_from_extracted(groups)

        # Write trigger files
        dir_counters: Dict[str, int] = {}

        for trigger in triggers:
            directory = hierarchy_mgr.get_directory_for_hierarchy(trigger.hierarchy)
            dir_key = str(directory)
            dir_counters[dir_key] = dir_counters.get(dir_key, 0) + 1

            metadata = self._create_trigger_metadata(trigger)
            self._write_lua_file(directory, trigger, metadata, dir_counters[dir_key])

            # Handle nested child triggers
            for i, child in enumerate(trigger.children):
                child_metadata = self._create_trigger_metadata(child)
                dir_counters[dir_key] += 1
                self._write_lua_file(directory, child, child_metadata, dir_counters[dir_key])

        # Save hierarchy
        hierarchy_mgr.save()
        self.file_counts["triggers"] = sum(dir_counters.values())
        print(f"  Extracted {self.file_counts['triggers']} trigger files")

    def extract_timers(self):
        """Extract all timers to src/timers/"""
        print("Extracting timers...")
        base_dir = self.output_dir / "timers"

        groups, timers = self.parser.extract_timers()
        print(f"  Found {len(timers)} timers in {len(groups)} groups")

        if not timers:
            return

        hierarchy_mgr = HierarchyManager(base_dir, "timers")
        hierarchy_mgr.add_groups_from_extracted(groups)

        dir_counters: Dict[str, int] = {}

        for timer in timers:
            directory = hierarchy_mgr.get_directory_for_hierarchy(timer.hierarchy)
            dir_key = str(directory)
            dir_counters[dir_key] = dir_counters.get(dir_key, 0) + 1

            metadata = self._create_timer_metadata(timer)
            self._write_lua_file(directory, timer, metadata, dir_counters[dir_key])

        hierarchy_mgr.save()
        self.file_counts["timers"] = sum(dir_counters.values())
        print(f"  Extracted {self.file_counts['timers']} timer files")

    def extract_aliases(self):
        """Extract all aliases to src/aliases/"""
        print("Extracting aliases...")
        base_dir = self.output_dir / "aliases"

        groups, aliases = self.parser.extract_aliases()
        print(f"  Found {len(aliases)} aliases in {len(groups)} groups")

        if not aliases:
            return

        hierarchy_mgr = HierarchyManager(base_dir, "aliases")
        hierarchy_mgr.add_groups_from_extracted(groups)

        dir_counters: Dict[str, int] = {}

        for alias in aliases:
            directory = hierarchy_mgr.get_directory_for_hierarchy(alias.hierarchy)
            dir_key = str(directory)
            dir_counters[dir_key] = dir_counters.get(dir_key, 0) + 1

            metadata = self._create_alias_metadata(alias)
            self._write_lua_file(directory, alias, metadata, dir_counters[dir_key])

        hierarchy_mgr.save()
        self.file_counts["aliases"] = sum(dir_counters.values())
        print(f"  Extracted {self.file_counts['aliases']} alias files")

    def extract_scripts(self):
        """Extract all scripts to src/scripts/"""
        print("Extracting scripts...")
        base_dir = self.output_dir / "scripts"

        groups, scripts = self.parser.extract_scripts()
        print(f"  Found {len(scripts)} scripts in {len(groups)} groups")

        if not scripts:
            return

        hierarchy_mgr = HierarchyManager(base_dir, "scripts")
        hierarchy_mgr.add_groups_from_extracted(groups)

        dir_counters: Dict[str, int] = {}

        for script in scripts:
            directory = hierarchy_mgr.get_directory_for_hierarchy(script.hierarchy)
            dir_key = str(directory)
            dir_counters[dir_key] = dir_counters.get(dir_key, 0) + 1

            metadata = self._create_script_metadata(script)
            self._write_lua_file(directory, script, metadata, dir_counters[dir_key])

        hierarchy_mgr.save()
        self.file_counts["scripts"] = sum(dir_counters.values())
        print(f"  Extracted {self.file_counts['scripts']} script files")

    def extract_keys(self):
        """Extract all keys to src/keys/"""
        print("Extracting keys...")
        base_dir = self.output_dir / "keys"

        groups, keys = self.parser.extract_keys()
        print(f"  Found {len(keys)} keys in {len(groups)} groups")

        if not keys:
            return

        hierarchy_mgr = HierarchyManager(base_dir, "keys")
        hierarchy_mgr.add_groups_from_extracted(groups)

        dir_counters: Dict[str, int] = {}

        for key in keys:
            directory = hierarchy_mgr.get_directory_for_hierarchy(key.hierarchy)
            dir_key = str(directory)
            dir_counters[dir_key] = dir_counters.get(dir_key, 0) + 1

            metadata = self._create_key_metadata(key)
            self._write_lua_file(directory, key, metadata, dir_counters[dir_key])

        hierarchy_mgr.save()
        self.file_counts["keys"] = sum(dir_counters.values())
        print(f"  Extracted {self.file_counts['keys']} key files")

    def extract_all(self):
        """Extract all package types."""
        print(f"Extracting from: {self.xml_path}")
        print(f"Output directory: {self.output_dir}")
        print()

        self.extract_triggers()
        self.extract_timers()
        self.extract_aliases()
        self.extract_scripts()
        self.extract_keys()

        print()
        print("Summary:")
        total = 0
        for pkg_type, count in self.file_counts.items():
            print(f"  {pkg_type}: {count} files")
            total += count
        print(f"  Total: {total} files")

    def extract_type(self, pkg_type: str):
        """Extract a specific package type."""
        extractors = {
            "triggers": self.extract_triggers,
            "timers": self.extract_timers,
            "aliases": self.extract_aliases,
            "scripts": self.extract_scripts,
            "keys": self.extract_keys,
        }

        if pkg_type not in extractors:
            print(f"Error: Unknown package type '{pkg_type}'")
            print(f"Valid types: {', '.join(extractors.keys())}")
            sys.exit(1)

        print(f"Extracting from: {self.xml_path}")
        print(f"Output directory: {self.output_dir}")
        print()

        extractors[pkg_type]()


def main():
    parser = argparse.ArgumentParser(
        description="Extract Mudlet XML package into editable Lua files"
    )
    parser.add_argument(
        "input",
        help="Input XML file path"
    )
    parser.add_argument(
        "--output-dir", "-o",
        default="./src",
        help="Output directory (default: ./src)"
    )
    parser.add_argument(
        "--type", "-t",
        choices=["triggers", "timers", "aliases", "scripts", "keys"],
        help="Extract only a specific package type"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )

    args = parser.parse_args()

    # Validate input file
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}")
        sys.exit(1)

    extractor = MudletExtractor(args.input, args.output_dir, args.verbose)

    if args.type:
        extractor.extract_type(args.type)
    else:
        extractor.extract_all()


if __name__ == "__main__":
    main()
