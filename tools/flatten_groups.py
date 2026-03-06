#!/usr/bin/env python3
"""
Flatten intermediate wrapper groups in _groups.yaml files.

Removes redundant nesting like:
  Levi_Ataxia > LEVI > Ataxia > Ataxia > content
  Levi_Ataxia > For Levi > leviticus > content

Flattens to:
  Levi_Ataxia > content
"""

import yaml
import sys
from pathlib import Path
from copy import deepcopy


def flatten_scripts(groups):
    """Flatten scripts: Levi_Ataxia > LEVI > Ataxia > Ataxia > content"""
    for root in groups:
        if root.get("name") != "Levi_Ataxia":
            continue

        old_children = root.get("children", [])
        new_children = []

        for child in old_children:
            if child.get("name") == "LEVI":
                # LEVI > Ataxia > Ataxia > content  AND  LEVI > Levi Scripts > content
                for levi_child in child.get("children", []):
                    if levi_child.get("name") == "Ataxia" and levi_child.get("packageName") == "Ataxia-DownloadThis":
                        # Ataxia > Ataxia > content
                        for ataxia_child in levi_child.get("children", []):
                            if ataxia_child.get("name") == "Ataxia" and ataxia_child.get("script"):
                                # This is the inner Ataxia with the init script
                                # Move its script to the root and promote its children
                                root["script"] = ataxia_child["script"]
                                new_children.extend(ataxia_child.get("children", []))
                            else:
                                new_children.append(ataxia_child)
                    elif levi_child.get("name") == "Levi  Scripts":
                        # Levi Scripts > content - promote children
                        new_children.extend(levi_child.get("children", []))
                    else:
                        new_children.append(levi_child)
            else:
                new_children.append(child)

        root["children"] = new_children
    return groups


def flatten_triggers(groups):
    """Flatten triggers: Levi_Ataxia > For Levi > leviticus > content"""
    for root in groups:
        if root.get("name") != "Levi_Ataxia":
            continue

        old_children = root.get("children", [])
        new_children = []

        for child in old_children:
            if child.get("name") == "For Levi":
                for fl_child in child.get("children", []):
                    if fl_child.get("name") == "leviticus":
                        # Promote leviticus children directly
                        new_children.extend(fl_child.get("children", []))
                    else:
                        new_children.append(fl_child)
            else:
                new_children.append(child)

        root["children"] = new_children
    return groups


def flatten_timers(groups):
    """Flatten timers: Levi_Ataxia > For Levi > Levi_062424 > leviticus > Levi Ataxia > content"""
    # Named intermediate groups to dissolve (promote their children)
    INTERMEDIATES = {"For Levi", "Levi_062424", "leviticus", "Levi Ataxia"}

    def dissolve_intermediates(children):
        """Recursively dissolve named intermediate groups, promoting their children."""
        result = []
        for child in children:
            if child.get("name") in INTERMEDIATES:
                # Dissolve: promote this group's children (recursively checking them too)
                promoted = dissolve_intermediates(child.get("children", []))
                result.extend(promoted)
            else:
                result.append(child)
        return result

    for root in groups:
        if root.get("name") != "Levi_Ataxia":
            continue

        root["children"] = dissolve_intermediates(root.get("children", []))
    return groups


def flatten_keys(groups):
    """Flatten keys: Levi_Ataxia > Levitax > content"""
    for root in groups:
        if root.get("name") != "Levi_Ataxia":
            continue

        old_children = root.get("children", [])
        new_children = []

        for child in old_children:
            if child.get("name") == "Levitax":
                # Promote Levitax children
                new_children.extend(child.get("children", []))
            else:
                new_children.append(child)

        root["children"] = new_children
    return groups


def process_file(file_path, flatten_func):
    """Load, flatten, and save a _groups.yaml file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)

    if not data or "groups" not in data:
        print(f"  Skipping {file_path}: no groups found")
        return

    original_groups = deepcopy(data["groups"])
    data["groups"] = flatten_func(data["groups"])

    if data["groups"] == original_groups:
        print(f"  No changes needed: {file_path}")
        return

    with open(file_path, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True,
                  sort_keys=False, width=120)

    print(f"  Flattened: {file_path}")


def main():
    src_dir = Path(__file__).parent.parent / "src_new"

    print("Flattening _groups.yaml intermediate groups...")

    process_file(src_dir / "scripts" / "_groups.yaml", flatten_scripts)
    process_file(src_dir / "triggers" / "_groups.yaml", flatten_triggers)
    process_file(src_dir / "timers" / "_groups.yaml", flatten_timers)
    process_file(src_dir / "keys" / "_groups.yaml", flatten_keys)
    # aliases already flat, no changes needed

    print("\nDone! Run convert_to_muddler.py to verify the output.")


if __name__ == "__main__":
    main()
