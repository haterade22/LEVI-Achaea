#!/usr/bin/env python3
"""
Build Script for LEVI-Achaea Mudlet Package

This script rebuilds the Mudlet XML package from the extracted Lua files.
It reads the Lua files from src/ and generates a fresh packages/Levi_Ataxia.xml

Usage:
    python build_package.py

The script will:
1. Read all .lua files from src/ subdirectories
2. Escape Lua code for XML (< > & etc.)
3. Generate a Mudlet-compatible XML package
4. Write to packages/Levi_Ataxia.xml
"""

import os
import re
from pathlib import Path
from datetime import datetime

# Directories to process in order
DIRECTORIES = [
    ("mmp", "mudlet-mapper", "Mudlet Mapper"),
    ("ataxia", "Ataxia", "Ataxia Combat System"),
    ("ataxiagui", "ataxiagui", "Ataxia GUI"),
    ("ataxiaNDB", "ataxiaNDB", "Player Database"),
    ("ataxiaBasher", "ataxiaBasher", "Auto Basher"),
]

BASE_PATH = Path(__file__).parent / "src"
OUTPUT_PATH = Path(__file__).parent / "packages" / "Levi_Ataxia.xml"


def escape_xml(text: str) -> str:
    """Escape special characters for XML content."""
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")
    return text


def get_script_name(filename: str) -> str:
    """Convert filename to a readable script name."""
    # Remove number prefix and extension: "001_Create_Option_Table.lua" -> "Create Option Table"
    name = re.sub(r"^\d+_", "", filename)
    name = name.replace(".lua", "")
    name = name.replace("_", " ")
    return name


def build_script_element(name: str, lua_code: str, event_handlers: list = None) -> str:
    """Build a single Script XML element."""
    escaped_code = escape_xml(lua_code)

    event_list = ""
    if event_handlers:
        event_list = "\n".join(f"\t\t\t\t\t\t<string>{eh}</string>" for eh in event_handlers)
        event_list = f"\n\t\t\t\t\t<eventHandlerList>\n{event_list}\n\t\t\t\t\t</eventHandlerList>"
    else:
        event_list = "\n\t\t\t\t\t<eventHandlerList />"

    return f"""					<Script isActive="yes" isFolder="no">
						<name>{escape_xml(name)}</name>
						<packageName></packageName>
						<script>{escaped_code}</script>{event_list}
					</Script>"""


def build_script_group(dir_name: str, package_name: str, display_name: str) -> str:
    """Build a ScriptGroup from a directory of Lua files."""
    dir_path = BASE_PATH / dir_name

    if not dir_path.exists():
        print(f"Warning: Directory {dir_path} does not exist, skipping...")
        return ""

    scripts = []
    lua_files = sorted(dir_path.glob("*.lua"))

    for lua_file in lua_files:
        with open(lua_file, "r", encoding="utf-8") as f:
            lua_code = f.read()

        script_name = get_script_name(lua_file.name)

        # Try to detect event handlers from registerAnonymousEventHandler calls
        event_handlers = []
        handler_pattern = r'registerAnonymousEventHandler\s*\(\s*["\']([^"\']+)["\']'
        for match in re.finditer(handler_pattern, lua_code):
            event_handlers.append(match.group(1))

        scripts.append(build_script_element(script_name, lua_code, event_handlers))

    scripts_xml = "\n".join(scripts)

    return f"""				<ScriptGroup isActive="yes" isFolder="yes">
					<name>{escape_xml(display_name)}</name>
					<packageName>{escape_xml(package_name)}</packageName>
					<script></script>
					<eventHandlerList />
{scripts_xml}
				</ScriptGroup>"""


def build_package() -> str:
    """Build the complete Mudlet package XML."""

    # Build all script groups
    script_groups = []
    for dir_name, package_name, display_name in DIRECTORIES:
        group_xml = build_script_group(dir_name, package_name, display_name)
        if group_xml:
            script_groups.append(group_xml)

    groups_xml = "\n".join(script_groups)

    # Build the complete package
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE MudletPackage>
<!--
  LEVI-Achaea Mudlet Package
  Generated: {timestamp}

  This file is auto-generated from src/*.lua files.
  Do not edit directly - edit the .lua files and run build_package.py
-->
<MudletPackage version="1.001">
	<ScriptPackage>
		<ScriptGroup isActive="yes" isFolder="yes">
			<name>For Levi</name>
			<packageName>For Levi</packageName>
			<script></script>
			<eventHandlerList />
{groups_xml}
		</ScriptGroup>
	</ScriptPackage>
</MudletPackage>
"""


def main():
    print("Building LEVI-Achaea Mudlet package...")
    print(f"Source: {BASE_PATH}")
    print(f"Output: {OUTPUT_PATH}")

    # Ensure output directory exists
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    # Build the package
    xml_content = build_package()

    # Write the output
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write(xml_content)

    # Get file size
    size_kb = OUTPUT_PATH.stat().st_size / 1024

    print(f"\nPackage built successfully!")
    print(f"Output: {OUTPUT_PATH}")
    print(f"Size: {size_kb:.1f} KB")
    print(f"\nTo install in Mudlet:")
    print(f"  1. Open Mudlet -> Package Manager")
    print(f"  2. Click 'Install'")
    print(f"  3. Select: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
