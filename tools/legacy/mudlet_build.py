#!/usr/bin/env python3
"""
Mudlet XML Package Builder

Builds a Mudlet XML package from extracted Lua files with YAML metadata headers.

Usage:
    python mudlet_build.py --src ./src_new --output packages/Levi_Ataxia.xml
    python mudlet_build.py --src ./src_new --validate
    python mudlet_build.py --src ./src_new --output packages/Levi_Ataxia.xml --verbose
"""

import argparse
import sys
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from collections import defaultdict

# Add lib to path
sys.path.insert(0, str(Path(__file__).parent))

from lib.yaml_handler import YAMLHeaderHandler
from lib.hierarchy import HierarchyManager
from lib.data_types import PatternType


def escape_xml(text: str) -> str:
    """Escape special characters for XML content."""
    if not text:
        return ""
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")
    return text


class MudletBuilder:
    """Build Mudlet XML package from extracted files."""

    def __init__(self, src_dir: str, output_path: str = None, verbose: bool = False):
        """
        Initialize builder.

        Args:
            src_dir: Source directory containing extracted files
            output_path: Output XML file path (optional for validation-only)
            verbose: Enable verbose output
        """
        self.src_dir = Path(src_dir)
        self.output_path = Path(output_path) if output_path else None
        self.verbose = verbose
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def log(self, msg: str):
        """Print message if verbose mode enabled."""
        if self.verbose:
            print(msg)

    def _read_lua_files(self, package_type: str) -> List[Tuple[Path, Dict[str, Any], str]]:
        """
        Read all Lua files for a package type.

        Args:
            package_type: One of 'triggers', 'timers', 'aliases', 'scripts', 'keys'

        Returns:
            List of (file_path, metadata, lua_code) tuples
        """
        base_dir = self.src_dir / package_type
        if not base_dir.exists():
            return []

        files = []
        for lua_file in sorted(base_dir.rglob("*.lua")):
            try:
                content = lua_file.read_text(encoding='utf-8')
                metadata, lua_code = YAMLHeaderHandler.parse(content)

                if metadata is None:
                    self.warnings.append(f"No YAML header in {lua_file}")
                    continue

                # Map plural folder name to singular type
                type_map = {
                    "triggers": "trigger",
                    "timers": "timer",
                    "aliases": "alias",
                    "scripts": "script",
                    "keys": "key",
                }
                expected_type = type_map.get(package_type, package_type.rstrip("s"))
                if metadata.get("type") != expected_type:
                    # Type mismatch (e.g., trigger file in timers folder)
                    actual = metadata.get("type", "unknown")
                    self.warnings.append(
                        f"Type mismatch in {lua_file}: expected '{expected_type}', got '{actual}'"
                    )

                files.append((lua_file, metadata, lua_code))
                self.log(f"  Read: {lua_file}")

            except Exception as e:
                self.errors.append(f"Error reading {lua_file}: {e}")

        return files

    def _build_group_structure(
        self,
        hierarchy_mgr: HierarchyManager,
        tag_prefix: str
    ) -> Tuple[ET.Element, Dict[Tuple[str, ...], ET.Element]]:
        """
        Build XML group structure from hierarchy manager.

        Args:
            hierarchy_mgr: HierarchyManager with loaded groups
            tag_prefix: Tag prefix ('Trigger', 'Timer', etc.)

        Returns:
            Tuple of (root element, path-to-element mapping)
        """
        group_tag = f"{tag_prefix}Group"
        path_map: Dict[Tuple[str, ...], ET.Element] = {}

        def build_group(node, parent_elem: Optional[ET.Element]) -> ET.Element:
            """Recursively build group elements."""
            elem = ET.SubElement(parent_elem, group_tag) if parent_elem is not None else ET.Element(group_tag)

            # Set attributes
            elem.set("isActive", "yes" if node.is_active else "no")
            elem.set("isFolder", "yes")

            # Add child elements
            ET.SubElement(elem, "name").text = node.name
            ET.SubElement(elem, "script").text = escape_xml(node.script) if node.script else ""
            if tag_prefix == "Trigger":
                # Triggers have extra default elements
                ET.SubElement(elem, "triggerType").text = "0"
                ET.SubElement(elem, "conditonLineDelta").text = "0"
                ET.SubElement(elem, "mStayOpen").text = "0"
                ET.SubElement(elem, "mCommand").text = ""
            elif tag_prefix == "Timer":
                ET.SubElement(elem, "command").text = ""
                ET.SubElement(elem, "time").text = "00:00:00.000"
            elif tag_prefix == "Alias":
                ET.SubElement(elem, "command").text = ""
                ET.SubElement(elem, "regex").text = ""
            elif tag_prefix == "Key":
                ET.SubElement(elem, "command").text = ""
                ET.SubElement(elem, "keyCode").text = "0"
                ET.SubElement(elem, "keyModifier").text = "0"

            ET.SubElement(elem, "packageName").text = node.package_name

            # Build children recursively
            for child in node.children:
                build_group(child, elem)

            return elem

        # Build all root groups
        root = None
        for group in hierarchy_mgr.root_groups:
            if root is None:
                root = build_group(group, None)
                path_map[(group.name,)] = root
            else:
                path_map[(group.name,)] = build_group(group, root)

        return root, path_map

    def _find_or_create_group(
        self,
        package_elem: ET.Element,
        hierarchy: List[str],
        tag_prefix: str
    ) -> ET.Element:
        """
        Find or create group elements for a hierarchy path.

        Args:
            package_elem: Package element to search/modify
            hierarchy: List of group names
            tag_prefix: Tag prefix ('Trigger', 'Timer', etc.)

        Returns:
            The deepest group element
        """
        group_tag = f"{tag_prefix}Group"
        current = package_elem

        for name in hierarchy:
            # Look for existing group
            found = None
            for child in current:
                if child.tag == group_tag:
                    name_elem = child.find("name")
                    if name_elem is not None and name_elem.text == name:
                        found = child
                        break

            if found is not None:
                current = found
            else:
                # Create new group
                new_group = ET.SubElement(current, group_tag)
                new_group.set("isActive", "yes")
                new_group.set("isFolder", "yes")
                ET.SubElement(new_group, "name").text = name
                ET.SubElement(new_group, "script").text = ""
                ET.SubElement(new_group, "packageName").text = ""

                if tag_prefix == "Trigger":
                    new_group.set("isTempTrigger", "no")
                    new_group.set("isMultiline", "no")
                    new_group.set("isPerlSlashGOption", "no")
                    new_group.set("isColorizerTrigger", "no")
                    new_group.set("isFilterTrigger", "no")
                    new_group.set("isSoundTrigger", "no")
                    new_group.set("isColorTrigger", "no")
                    new_group.set("isColorTriggerFg", "no")
                    new_group.set("isColorTriggerBg", "no")
                    ET.SubElement(new_group, "triggerType").text = "0"
                    ET.SubElement(new_group, "conditonLineDelta").text = "0"
                    ET.SubElement(new_group, "mStayOpen").text = "0"
                    ET.SubElement(new_group, "mCommand").text = ""
                    ET.SubElement(new_group, "mFgColor").text = "#ff0000"
                    ET.SubElement(new_group, "mBgColor").text = "#ffff00"
                    ET.SubElement(new_group, "mSoundFile").text = ""
                    ET.SubElement(new_group, "colorTriggerFgColor").text = "#000000"
                    ET.SubElement(new_group, "colorTriggerBgColor").text = "#000000"
                    ET.SubElement(new_group, "regexCodeList")
                    ET.SubElement(new_group, "regexCodePropertyList")
                elif tag_prefix == "Timer":
                    new_group.set("isTempTimer", "no")
                    new_group.set("isOffsetTimer", "no")
                    ET.SubElement(new_group, "command").text = ""
                    ET.SubElement(new_group, "time").text = "00:00:00.000"
                elif tag_prefix == "Alias":
                    ET.SubElement(new_group, "command").text = ""
                    ET.SubElement(new_group, "regex").text = ""
                elif tag_prefix == "Key":
                    ET.SubElement(new_group, "command").text = ""
                    ET.SubElement(new_group, "keyCode").text = "0"
                    ET.SubElement(new_group, "keyModifier").text = "0"

                current = new_group

        return current

    def _create_trigger_element(self, metadata: Dict[str, Any], lua_code: str) -> ET.Element:
        """Create a Trigger XML element from metadata and code."""
        elem = ET.Element("Trigger")

        # Set attributes
        attrs = metadata.get("attributes", {})
        for attr in ["isActive", "isFolder", "isTempTrigger", "isMultiline",
                     "isPerlSlashGOption", "isColorizerTrigger", "isFilterTrigger",
                     "isSoundTrigger", "isColorTrigger", "isColorTriggerFg", "isColorTriggerBg"]:
            elem.set(attr, attrs.get(attr, "no"))

        # Add child elements
        ET.SubElement(elem, "name").text = metadata.get("name", "unnamed")
        ET.SubElement(elem, "script").text = escape_xml(lua_code)
        ET.SubElement(elem, "triggerType").text = str(metadata.get("triggerType", 0))
        ET.SubElement(elem, "conditonLineDelta").text = str(metadata.get("conditonLineDelta", 0))
        ET.SubElement(elem, "mStayOpen").text = str(metadata.get("mStayOpen", 0))
        ET.SubElement(elem, "mCommand").text = metadata.get("mCommand", "")
        ET.SubElement(elem, "packageName").text = metadata.get("packageName", "")
        ET.SubElement(elem, "mFgColor").text = metadata.get("mFgColor", "#ff0000")
        ET.SubElement(elem, "mBgColor").text = metadata.get("mBgColor", "#ffff00")
        ET.SubElement(elem, "mSoundFile").text = metadata.get("mSoundFile", "")
        ET.SubElement(elem, "colorTriggerFgColor").text = metadata.get("colorTriggerFgColor", "#000000")
        ET.SubElement(elem, "colorTriggerBgColor").text = metadata.get("colorTriggerBgColor", "#000000")

        # Add patterns
        patterns = metadata.get("patterns", [])
        regex_list = ET.SubElement(elem, "regexCodeList")
        prop_list = ET.SubElement(elem, "regexCodePropertyList")

        for pattern in patterns:
            ET.SubElement(regex_list, "string").text = escape_xml(pattern.get("pattern", ""))
            ET.SubElement(prop_list, "integer").text = str(pattern.get("type", 0))

        return elem

    def _create_timer_element(self, metadata: Dict[str, Any], lua_code: str) -> ET.Element:
        """Create a Timer XML element from metadata and code."""
        elem = ET.Element("Timer")

        attrs = metadata.get("attributes", {})
        elem.set("isActive", attrs.get("isActive", "yes"))
        elem.set("isFolder", attrs.get("isFolder", "no"))
        elem.set("isTempTimer", attrs.get("isTempTimer", "no"))
        elem.set("isOffsetTimer", attrs.get("isOffsetTimer", "no"))

        ET.SubElement(elem, "name").text = metadata.get("name", "unnamed")
        ET.SubElement(elem, "script").text = escape_xml(lua_code)
        ET.SubElement(elem, "command").text = metadata.get("command", "")
        ET.SubElement(elem, "packageName").text = metadata.get("packageName", "")
        ET.SubElement(elem, "time").text = metadata.get("time", "00:00:00.000")

        return elem

    def _create_alias_element(self, metadata: Dict[str, Any], lua_code: str) -> ET.Element:
        """Create an Alias XML element from metadata and code."""
        elem = ET.Element("Alias")

        attrs = metadata.get("attributes", {})
        elem.set("isActive", attrs.get("isActive", "yes"))
        elem.set("isFolder", attrs.get("isFolder", "no"))

        ET.SubElement(elem, "name").text = metadata.get("name", "unnamed")
        ET.SubElement(elem, "script").text = escape_xml(lua_code)
        ET.SubElement(elem, "command").text = metadata.get("command", "")
        ET.SubElement(elem, "packageName").text = metadata.get("packageName", "")
        ET.SubElement(elem, "regex").text = metadata.get("regex", "")

        return elem

    def _create_script_element(self, metadata: Dict[str, Any], lua_code: str) -> ET.Element:
        """Create a Script XML element from metadata and code."""
        elem = ET.Element("Script")

        attrs = metadata.get("attributes", {})
        elem.set("isActive", attrs.get("isActive", "yes"))
        elem.set("isFolder", attrs.get("isFolder", "no"))

        ET.SubElement(elem, "name").text = metadata.get("name", "unnamed")
        ET.SubElement(elem, "packageName").text = metadata.get("packageName", "")
        ET.SubElement(elem, "script").text = escape_xml(lua_code)

        # Event handlers
        handlers = metadata.get("eventHandlers", [])
        handler_list = ET.SubElement(elem, "eventHandlerList")
        if handlers:
            for handler in handlers:
                ET.SubElement(handler_list, "string").text = handler

        return elem

    def _create_key_element(self, metadata: Dict[str, Any], lua_code: str) -> ET.Element:
        """Create a Key XML element from metadata and code."""
        elem = ET.Element("Key")

        attrs = metadata.get("attributes", {})
        elem.set("isActive", attrs.get("isActive", "yes"))
        elem.set("isFolder", attrs.get("isFolder", "no"))

        ET.SubElement(elem, "name").text = metadata.get("name", "unnamed")
        ET.SubElement(elem, "packageName").text = metadata.get("packageName", "")
        ET.SubElement(elem, "script").text = escape_xml(lua_code)
        ET.SubElement(elem, "command").text = metadata.get("command", "")
        ET.SubElement(elem, "keyCode").text = str(metadata.get("keyCode", 0))
        ET.SubElement(elem, "keyModifier").text = str(metadata.get("keyModifier", 0))

        return elem

    def _build_package(
        self,
        package_type: str,
        tag_prefix: str,
        create_element_func
    ) -> Optional[ET.Element]:
        """
        Build a package element from extracted files.

        Args:
            package_type: 'triggers', 'timers', etc.
            tag_prefix: 'Trigger', 'Timer', etc.
            create_element_func: Function to create item elements

        Returns:
            Package element or None if no files found
        """
        print(f"Building {package_type}...")

        files = self._read_lua_files(package_type)
        if not files:
            print(f"  No {package_type} files found")
            return None

        print(f"  Found {len(files)} {package_type}")

        package = ET.Element(f"{tag_prefix}Package")

        # Group files by hierarchy
        by_hierarchy = defaultdict(list)
        for file_path, metadata, lua_code in files:
            hierarchy = tuple(metadata.get("hierarchy", []))
            by_hierarchy[hierarchy].append((file_path, metadata, lua_code))

        # Process each hierarchy
        for hierarchy, items in sorted(by_hierarchy.items()):
            if hierarchy:
                parent = self._find_or_create_group(package, list(hierarchy), tag_prefix)
            else:
                parent = package

            for file_path, metadata, lua_code in items:
                elem = create_element_func(metadata, lua_code)
                parent.append(elem)

        return package

    def build(self) -> bool:
        """
        Build the complete XML package.

        Returns:
            True if successful, False if errors occurred
        """
        if not self.output_path:
            print("Error: No output path specified")
            return False

        print(f"Building package from: {self.src_dir}")
        print(f"Output: {self.output_path}")
        print()

        # Create root element
        root = ET.Element("MudletPackage")
        root.set("version", "1.001")

        # Build each package type
        trigger_pkg = self._build_package("triggers", "Trigger", self._create_trigger_element)
        timer_pkg = self._build_package("timers", "Timer", self._create_timer_element)
        alias_pkg = self._build_package("aliases", "Alias", self._create_alias_element)
        action_pkg = ET.Element("ActionPackage")  # Always empty
        script_pkg = self._build_package("scripts", "Script", self._create_script_element)
        key_pkg = self._build_package("keys", "Key", self._create_key_element)

        # Add packages in correct order
        if trigger_pkg is not None:
            root.append(trigger_pkg)
        else:
            root.append(ET.Element("TriggerPackage"))

        if timer_pkg is not None:
            root.append(timer_pkg)
        else:
            root.append(ET.Element("TimerPackage"))

        if alias_pkg is not None:
            root.append(alias_pkg)
        else:
            root.append(ET.Element("AliasPackage"))

        root.append(action_pkg)

        if script_pkg is not None:
            root.append(script_pkg)
        else:
            root.append(ET.Element("ScriptPackage"))

        if key_pkg is not None:
            root.append(key_pkg)
        else:
            root.append(ET.Element("KeyPackage"))

        # Check for errors
        if self.errors:
            print()
            print("Errors encountered:")
            for error in self.errors:
                print(f"  - {error}")
            return False

        # Write output
        self.output_path.parent.mkdir(parents=True, exist_ok=True)

        # Pretty print XML
        self._indent(root)

        # Write with XML declaration
        tree = ET.ElementTree(root)
        with open(self.output_path, 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
            f.write('<!DOCTYPE MudletPackage>\n')
            tree.write(f, encoding='unicode')

        # Get file size
        size_kb = self.output_path.stat().st_size / 1024

        print()
        print(f"Package built successfully!")
        print(f"Output: {self.output_path}")
        print(f"Size: {size_kb:.1f} KB")

        if self.warnings:
            print()
            print("Warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")

        return True

    def _indent(self, elem: ET.Element, level: int = 0):
        """Add indentation to XML elements for pretty printing."""
        indent = "\n" + "\t" * level
        if len(elem):
            if not elem.text or not elem.text.strip():
                elem.text = indent + "\t"
            if not elem.tail or not elem.tail.strip():
                elem.tail = indent
            for child in elem:
                self._indent(child, level + 1)
            if not child.tail or not child.tail.strip():
                child.tail = indent
        else:
            if level and (not elem.tail or not elem.tail.strip()):
                elem.tail = indent

    def validate(self) -> bool:
        """
        Validate extracted files without building.

        Returns:
            True if valid, False if errors found
        """
        print(f"Validating: {self.src_dir}")
        print()

        total_files = 0
        for pkg_type in ["triggers", "timers", "aliases", "scripts", "keys"]:
            files = self._read_lua_files(pkg_type)
            print(f"  {pkg_type}: {len(files)} files")
            total_files += len(files)

        print()
        print(f"Total files: {total_files}")

        if self.errors:
            print()
            print("Errors:")
            for error in self.errors:
                print(f"  - {error}")
            return False

        if self.warnings:
            print()
            print("Warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")

        print()
        print("Validation passed!" if not self.errors else "Validation failed!")
        return not self.errors


def main():
    parser = argparse.ArgumentParser(
        description="Build Mudlet XML package from extracted Lua files"
    )
    parser.add_argument(
        "--src", "-s",
        default="./src_new",
        help="Source directory with extracted files (default: ./src_new)"
    )
    parser.add_argument(
        "--output", "-o",
        help="Output XML file path"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate files without building"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )

    args = parser.parse_args()

    # Validate source directory
    src_path = Path(args.src)
    if not src_path.exists():
        print(f"Error: Source directory not found: {src_path}")
        sys.exit(1)

    builder = MudletBuilder(args.src, args.output, args.verbose)

    if args.validate:
        success = builder.validate()
    else:
        if not args.output:
            print("Error: --output required for building (use --validate for validation only)")
            sys.exit(1)
        success = builder.build()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
