#!/usr/bin/env python3
"""
Extract Lua code from Mudlet XML package and organize into directory structure.
"""

import xml.etree.ElementTree as ET
import html
import os
import re
from pathlib import Path

def unescape_html(text):
    """Convert HTML entities back to normal characters."""
    if not text:
        return ""
    return html.unescape(text)

def sanitize_filename(name):
    """Convert a script name to a valid filename."""
    # Remove or replace invalid filename characters
    name = re.sub(r'[<>:"/\\|?*]', '_', name)
    name = re.sub(r'\s+', '_', name)
    name = name.strip('_')
    return name if name else "unnamed"

def get_script_path(names_hierarchy):
    """Determine the target directory based on script hierarchy."""
    hierarchy_str = ' > '.join(names_hierarchy).lower()

    # Map script groups to directories
    if 'mudlet-mapper' in hierarchy_str or 'mudlet mapper' in hierarchy_str:
        return 'mmp'
    elif 'ataxia ndb' in hierarchy_str:
        return 'ataxiaNDB'
    elif 'gui stuff' in hierarchy_str or 'creation/layout' in hierarchy_str or 'map and chat' in hierarchy_str or 'chat capture' in hierarchy_str or 'vitals related' in hierarchy_str or 'small map' in hierarchy_str:
        return 'ataxiagui'
    elif 'basher' in hierarchy_str:
        return 'ataxiaBasher'
    elif 'ataxia' in hierarchy_str or 'levi' in hierarchy_str:
        return 'ataxia'
    else:
        return 'core'

def extract_scripts(element, names_hierarchy=None, scripts_data=None):
    """Recursively extract scripts from XML element."""
    if names_hierarchy is None:
        names_hierarchy = []
    if scripts_data is None:
        scripts_data = []

    # Get the name of current element
    name_elem = element.find('name')
    current_name = name_elem.text if name_elem is not None and name_elem.text else "unnamed"

    # Add current name to hierarchy
    new_hierarchy = names_hierarchy + [current_name]

    # Check if this is a Script (not ScriptGroup)
    if element.tag == 'Script':
        script_elem = element.find('script')
        if script_elem is not None and script_elem.text:
            script_code = unescape_html(script_elem.text)

            # Only save if there's actual code
            if script_code.strip():
                scripts_data.append({
                    'name': current_name,
                    'hierarchy': new_hierarchy,
                    'code': script_code,
                    'target_dir': get_script_path(new_hierarchy)
                })

    # Recursively process children
    for child in element:
        if child.tag in ['ScriptGroup', 'Script']:
            extract_scripts(child, new_hierarchy, scripts_data)

    return scripts_data

def organize_scripts_by_directory(scripts_data):
    """Organize scripts into directory structure."""
    organized = {}

    for script in scripts_data:
        target_dir = script['target_dir']
        if target_dir not in organized:
            organized[target_dir] = []
        organized[target_dir].append(script)

    return organized

def write_scripts_to_files(organized_scripts, base_dir):
    """Write organized scripts to files."""
    base_path = Path(base_dir)

    # Create directory structure
    for dir_name in organized_scripts.keys():
        dir_path = base_path / dir_name
        dir_path.mkdir(parents=True, exist_ok=True)

    # Write scripts to files
    file_counts = {}

    for dir_name, scripts in organized_scripts.items():
        dir_path = base_path / dir_name
        file_counts[dir_name] = 0

        for i, script in enumerate(scripts):
            # Create a filename based on script name
            base_filename = sanitize_filename(script['name'])
            filename = f"{i+1:03d}_{base_filename}.lua"
            file_path = dir_path / filename

            # Add header comment with hierarchy
            header = f"-- {' > '.join(script['hierarchy'])}\n\n"

            # Write the file
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(header)
                f.write(script['code'])

            file_counts[dir_name] += 1
            print(f"Written: {file_path}")

    return file_counts

def create_loader(base_dir, file_counts):
    """Create a loader.lua that loads all files in correct order."""
    base_path = Path(base_dir)

    # Define load order
    load_order = ['core', 'mmp', 'ataxia', 'ataxiagui', 'ataxiaNDB', 'ataxiaBasher']

    loader_content = """-- Auto-generated loader for LEVI Achaea scripts
-- This file loads all Lua scripts in the correct order

local base_path = getMudletHomeDir() .. "/LEVI-Achaea/src/"

-- Helper function to load a directory of scripts
local function load_directory(dir_name)
    local dir_path = base_path .. dir_name
    print(string.format("Loading %s scripts...", dir_name))

    -- Get all lua files in directory
    local files = {}
    for _, filename in ipairs(lfs.dir(dir_path) or {}) do
        if filename:match("%.lua$") and filename ~= "init.lua" then
            table.insert(files, filename)
        end
    end

    -- Sort files to ensure consistent load order
    table.sort(files)

    -- Load each file
    for _, filename in ipairs(files) do
        local file_path = dir_path .. "/" .. filename
        local success, err = pcall(dofile, file_path)
        if not success then
            print(string.format("Error loading %s: %s", filename, err))
        end
    end
end

-- Load directories in order
"""

    for dir_name in load_order:
        if dir_name in file_counts and file_counts[dir_name] > 0:
            loader_content += f'load_directory("{dir_name}")\n'

    loader_content += '\nprint("LEVI Achaea scripts loaded successfully!")\n'

    # Write loader
    loader_path = base_path / 'loader.lua'
    with open(loader_path, 'w', encoding='utf-8') as f:
        f.write(loader_content)

    print(f"\nCreated loader: {loader_path}")

def main():
    xml_file = r"C:\Users\mikew\OneDrive\Desktop\Scripts_Levi.xml"
    output_dir = r"c:\Users\mikew\source\repos\Achaea\LEVI-Achaea\src"

    print(f"Parsing XML file: {xml_file}")
    print(f"Output directory: {output_dir}")
    print()

    # Parse XML
    tree = ET.parse(xml_file)
    root = tree.getroot()

    # Find all ScriptPackage elements
    all_scripts = []
    for script_package in root.findall('.//ScriptPackage'):
        scripts = extract_scripts(script_package)
        all_scripts.extend(scripts)

    print(f"Found {len(all_scripts)} scripts with code")
    print()

    # Organize by directory
    organized = organize_scripts_by_directory(all_scripts)

    print("Scripts organized by directory:")
    for dir_name, scripts in organized.items():
        print(f"  {dir_name}: {len(scripts)} scripts")
    print()

    # Write to files
    file_counts = write_scripts_to_files(organized, output_dir)

    print()
    print("Summary:")
    for dir_name, count in file_counts.items():
        print(f"  {dir_name}: {count} files")

    # Create loader
    create_loader(output_dir, file_counts)

if __name__ == "__main__":
    main()
