"""
Hierarchy Manager for Mudlet packages.

Manages group hierarchies stored in _groups.yaml files and handles
mapping between filesystem directories and XML hierarchy paths.
"""

import re
import yaml
from pathlib import Path
from typing import List, Dict, Any, Optional, Set
from dataclasses import dataclass, field


def sanitize_filename(name: str) -> str:
    """Convert a name to a valid filename component."""
    # Replace invalid filename characters
    name = re.sub(r'[<>:"/\\|?*]', '_', name)
    name = re.sub(r'\s+', '_', name)
    name = name.strip('_')
    return name if name else "unnamed"


def sanitize_directory_name(name: str) -> str:
    """Convert a name to a valid directory name."""
    name = sanitize_filename(name).lower()
    # Further simplify for directory use
    name = re.sub(r'_+', '_', name)
    return name


@dataclass
class GroupNode:
    """A node in the group hierarchy tree."""
    name: str
    package_name: str = ""
    is_active: bool = True
    script: str = ""
    attributes: Dict[str, str] = field(default_factory=dict)
    directory: Optional[str] = None
    children: List["GroupNode"] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for YAML serialization."""
        data = {
            "name": self.name,
        }
        if self.package_name:
            data["packageName"] = self.package_name
        if not self.is_active:
            data["isActive"] = False
        if self.script:
            data["script"] = self.script
        if self.attributes:
            # Only include non-default attributes
            non_default = {k: v for k, v in self.attributes.items()
                         if k not in ("isActive", "isFolder")}
            if non_default:
                data["attributes"] = non_default
        if self.directory:
            data["directory"] = self.directory
        if self.children:
            data["children"] = [c.to_dict() for c in self.children]
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "GroupNode":
        """Create from dictionary (YAML deserialization)."""
        return cls(
            name=data.get("name", "unnamed"),
            package_name=data.get("packageName", ""),
            is_active=data.get("isActive", True),
            script=data.get("script", ""),
            attributes=data.get("attributes", {}),
            directory=data.get("directory"),
            children=[cls.from_dict(c) for c in data.get("children", [])],
        )


class HierarchyManager:
    """Manage group hierarchies for package types."""

    def __init__(self, base_dir: Path, package_type: str):
        """
        Initialize hierarchy manager.

        Args:
            base_dir: Base directory for the package type (e.g., src/triggers/)
            package_type: One of 'triggers', 'timers', 'aliases', 'scripts', 'keys'
        """
        self.base_dir = Path(base_dir)
        self.package_type = package_type
        self.groups_file = self.base_dir / "_groups.yaml"
        self.root_groups: List[GroupNode] = []
        self._directory_map: Dict[str, List[str]] = {}  # directory -> hierarchy

    def load(self) -> bool:
        """
        Load hierarchy from _groups.yaml.

        Returns:
            True if loaded successfully, False if file doesn't exist
        """
        if not self.groups_file.exists():
            return False

        with open(self.groups_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)

        if data and "groups" in data:
            self.root_groups = [GroupNode.from_dict(g) for g in data["groups"]]
            self._build_directory_map()
            return True
        return False

    def save(self):
        """Save hierarchy to _groups.yaml."""
        self.base_dir.mkdir(parents=True, exist_ok=True)

        data = {
            "version": 1,
            "packageType": self.package_type,
            "groups": [g.to_dict() for g in self.root_groups],
        }

        with open(self.groups_file, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True,
                     sort_keys=False, width=120)

    def _build_directory_map(self):
        """Build mapping from directories to hierarchies."""
        self._directory_map = {}

        def walk(node: GroupNode, hierarchy: List[str], current_dir: str):
            new_hierarchy = hierarchy + [node.name]
            if node.directory:
                self._directory_map[node.directory] = new_hierarchy
                current_dir = node.directory
            elif current_dir:
                # Inherit parent directory
                self._directory_map[current_dir] = new_hierarchy

            for child in node.children:
                walk(child, new_hierarchy, current_dir)

        for root in self.root_groups:
            walk(root, [], "")

    def add_groups_from_extracted(self, extracted_groups: List[Any]):
        """
        Build hierarchy from extracted groups.

        Args:
            extracted_groups: List of ExtractedGroup objects from XML parser
        """
        # Build tree structure from flat list
        root_map: Dict[str, GroupNode] = {}
        all_hierarchies: Set[tuple] = set()

        for group in extracted_groups:
            hierarchy = tuple(group.hierarchy + [group.name])
            all_hierarchies.add(hierarchy)

        # Sort by length to process parents first
        sorted_hierarchies = sorted(all_hierarchies, key=len)

        for hierarchy in sorted_hierarchies:
            if len(hierarchy) == 1:
                # Root level group
                name = hierarchy[0]
                if name not in root_map:
                    # Find the original group data
                    orig = next((g for g in extracted_groups
                                if g.name == name and not g.hierarchy), None)
                    root_map[name] = GroupNode(
                        name=name,
                        package_name=orig.package_name if orig else "",
                        is_active=orig.is_active if orig else True,
                        script=orig.script if orig else "",
                        attributes=orig.attributes if orig else {},
                    )
            else:
                # Nested group - find or create parent chain
                parent_hierarchy = hierarchy[:-1]
                parent = self._find_or_create_node(root_map, parent_hierarchy, extracted_groups)

                name = hierarchy[-1]
                if parent and not any(c.name == name for c in parent.children):
                    orig = next((g for g in extracted_groups
                                if g.name == name and tuple(g.hierarchy) == parent_hierarchy), None)
                    node = GroupNode(
                        name=name,
                        package_name=orig.package_name if orig else "",
                        is_active=orig.is_active if orig else True,
                        script=orig.script if orig else "",
                        attributes=orig.attributes if orig else {},
                    )
                    parent.children.append(node)

        self.root_groups = list(root_map.values())
        self._assign_directories()

    def _find_or_create_node(
        self,
        root_map: Dict[str, GroupNode],
        hierarchy: tuple,
        extracted_groups: List[Any]
    ) -> Optional[GroupNode]:
        """Find or create a node for the given hierarchy path."""
        if not hierarchy:
            return None

        root_name = hierarchy[0]
        if root_name not in root_map:
            orig = next((g for g in extracted_groups
                        if g.name == root_name and not g.hierarchy), None)
            root_map[root_name] = GroupNode(
                name=root_name,
                package_name=orig.package_name if orig else "",
                is_active=orig.is_active if orig else True,
                script=orig.script if orig else "",
                attributes=orig.attributes if orig else {},
            )

        current = root_map[root_name]

        for name in hierarchy[1:]:
            child = next((c for c in current.children if c.name == name), None)
            if not child:
                parent_hierarchy = hierarchy[:hierarchy.index(name)]
                orig = next((g for g in extracted_groups
                            if g.name == name and tuple(g.hierarchy) == parent_hierarchy), None)
                child = GroupNode(
                    name=name,
                    package_name=orig.package_name if orig else "",
                    is_active=orig.is_active if orig else True,
                    script=orig.script if orig else "",
                    attributes=orig.attributes if orig else {},
                )
                current.children.append(child)
            current = child

        return current

    def _assign_directories(self):
        """Assign directory names to groups based on their hierarchy."""
        def assign_recursive(node: GroupNode, parent_dir: str, depth: int):
            # Create directory name from sanitized group name
            dir_name = sanitize_directory_name(node.name)

            if parent_dir:
                full_dir = f"{parent_dir}/{dir_name}"
            else:
                full_dir = dir_name

            # Only assign directory to leaf groups or significant branches
            # For deep nesting, flatten somewhat
            if depth <= 3 or not node.children:
                node.directory = full_dir

            for child in node.children:
                assign_recursive(child, full_dir if depth <= 2 else parent_dir, depth + 1)

        for root in self.root_groups:
            assign_recursive(root, "", 0)

        self._build_directory_map()

    def get_directory_for_hierarchy(self, hierarchy: List[str]) -> Path:
        """
        Get the filesystem directory for a hierarchy path.

        Args:
            hierarchy: List of group names forming the path

        Returns:
            Path to the directory for items in this hierarchy
        """
        # Find the deepest matching directory
        best_match = ""
        best_depth = 0

        for directory, dir_hierarchy in self._directory_map.items():
            # Check if hierarchy starts with dir_hierarchy
            if len(hierarchy) >= len(dir_hierarchy):
                if hierarchy[:len(dir_hierarchy)] == dir_hierarchy:
                    if len(dir_hierarchy) > best_depth:
                        best_match = directory
                        best_depth = len(dir_hierarchy)

        if best_match:
            return self.base_dir / best_match

        # Fallback: create directory from hierarchy
        if hierarchy:
            dir_parts = [sanitize_directory_name(h) for h in hierarchy[:3]]
            return self.base_dir / "/".join(dir_parts)

        return self.base_dir

    def get_hierarchy_for_file(self, file_path: Path) -> List[str]:
        """
        Get the XML hierarchy for a file based on its path.

        Args:
            file_path: Path to a Lua file

        Returns:
            List of group names forming the hierarchy
        """
        # Get relative path from base
        try:
            rel_path = file_path.parent.relative_to(self.base_dir)
        except ValueError:
            return []

        dir_str = str(rel_path).replace("\\", "/")
        if dir_str in self._directory_map:
            return self._directory_map[dir_str]

        # Try to find closest match
        for directory, hierarchy in sorted(
            self._directory_map.items(),
            key=lambda x: len(x[0]),
            reverse=True
        ):
            if dir_str.startswith(directory):
                return hierarchy

        return []

    def get_all_directories(self) -> Set[str]:
        """Get all assigned directories."""
        return set(self._directory_map.keys())

    def find_node(self, hierarchy: List[str]) -> Optional[GroupNode]:
        """Find a group node by its full hierarchy path."""
        if not hierarchy:
            return None

        current_list = self.root_groups
        node = None

        for name in hierarchy:
            node = next((n for n in current_list if n.name == name), None)
            if not node:
                return None
            current_list = node.children

        return node
