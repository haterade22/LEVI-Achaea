#!/usr/bin/env python3
"""
Mudlet Package Validator

Validates extracted Mudlet package files for correctness.

Usage:
    python mudlet_validate.py ./src
    python mudlet_validate.py ./src --strict
    python mudlet_validate.py ./src --type triggers
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

# Add lib to path
sys.path.insert(0, str(Path(__file__).parent))

from lib.yaml_handler import YAMLHeaderHandler


class Severity(Enum):
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"


@dataclass
class ValidationIssue:
    """A validation issue found in a file."""
    file_path: Path
    severity: Severity
    message: str
    line: Optional[int] = None

    def __str__(self):
        loc = f"{self.file_path}"
        if self.line:
            loc += f":{self.line}"
        return f"[{self.severity.value.upper()}] {loc}: {self.message}"


class MudletValidator:
    """Validate Mudlet package files."""

    # Required fields by type
    REQUIRED_FIELDS = {
        "trigger": ["name", "hierarchy", "patterns"],
        "timer": ["name", "hierarchy", "time"],
        "alias": ["name", "hierarchy", "regex"],
        "script": ["name", "hierarchy"],
        "key": ["name", "hierarchy", "keyCode"],
    }

    # Valid attribute keys by type
    VALID_ATTRIBUTES = {
        "trigger": [
            "isActive", "isFolder", "isTempTrigger", "isMultiline",
            "isPerlSlashGOption", "isColorizerTrigger", "isFilterTrigger",
            "isSoundTrigger", "isColorTrigger", "isColorTriggerFg", "isColorTriggerBg"
        ],
        "timer": ["isActive", "isFolder", "isTempTimer", "isOffsetTimer"],
        "alias": ["isActive", "isFolder"],
        "script": ["isActive", "isFolder"],
        "key": ["isActive", "isFolder"],
    }

    def __init__(self, src_dir: str, strict: bool = False):
        """
        Initialize validator.

        Args:
            src_dir: Source directory to validate
            strict: Enable strict validation (treat warnings as errors)
        """
        self.src_dir = Path(src_dir)
        self.strict = strict
        self.issues: List[ValidationIssue] = []

    def _add_issue(
        self,
        file_path: Path,
        severity: Severity,
        message: str,
        line: int = None
    ):
        """Add a validation issue."""
        self.issues.append(ValidationIssue(file_path, severity, message, line))

    def _validate_yaml_header(
        self,
        file_path: Path,
        content: str
    ) -> Optional[Dict[str, Any]]:
        """
        Validate YAML header syntax.

        Returns:
            Parsed metadata or None if invalid
        """
        try:
            metadata, code = YAMLHeaderHandler.parse(content)
            if metadata is None:
                self._add_issue(
                    file_path, Severity.ERROR,
                    "Missing YAML header (should start with --[[mudlet)"
                )
                return None
            return metadata
        except ValueError as e:
            self._add_issue(file_path, Severity.ERROR, f"Invalid YAML: {e}")
            return None

    def _validate_required_fields(
        self,
        file_path: Path,
        metadata: Dict[str, Any],
        element_type: str
    ):
        """Validate that required fields are present."""
        required = self.REQUIRED_FIELDS.get(element_type, [])

        for field in required:
            if field not in metadata:
                self._add_issue(
                    file_path, Severity.ERROR,
                    f"Missing required field: '{field}'"
                )
            elif metadata[field] is None or metadata[field] == "":
                if field == "patterns":
                    # Patterns can be empty list but not missing
                    if not isinstance(metadata[field], list):
                        self._add_issue(
                            file_path, Severity.ERROR,
                            f"Field '{field}' must be a list"
                        )
                elif field != "regex":  # regex can be empty for alias groups
                    self._add_issue(
                        file_path, Severity.WARNING,
                        f"Field '{field}' is empty"
                    )

    def _validate_attributes(
        self,
        file_path: Path,
        metadata: Dict[str, Any],
        element_type: str
    ):
        """Validate attribute values."""
        attrs = metadata.get("attributes", {})
        valid_attrs = self.VALID_ATTRIBUTES.get(element_type, [])

        for attr, value in attrs.items():
            if attr not in valid_attrs:
                self._add_issue(
                    file_path, Severity.WARNING,
                    f"Unknown attribute: '{attr}'"
                )
            elif value not in ("yes", "no"):
                self._add_issue(
                    file_path, Severity.WARNING,
                    f"Attribute '{attr}' should be 'yes' or 'no', got '{value}'"
                )

    def _validate_trigger_patterns(
        self,
        file_path: Path,
        metadata: Dict[str, Any]
    ):
        """Validate trigger patterns."""
        patterns = metadata.get("patterns", [])

        for i, pattern in enumerate(patterns):
            if not isinstance(pattern, dict):
                self._add_issue(
                    file_path, Severity.ERROR,
                    f"Pattern {i+1} is not a dictionary"
                )
                continue

            if "pattern" not in pattern:
                self._add_issue(
                    file_path, Severity.ERROR,
                    f"Pattern {i+1} missing 'pattern' field"
                )

            pattern_type = pattern.get("type", 0)
            # Valid types: 0-7 (known), 8-10 (reserved for future)
            if not isinstance(pattern_type, int) or pattern_type < 0 or pattern_type > 10:
                self._add_issue(
                    file_path, Severity.WARNING,
                    f"Pattern {i+1} has invalid type: {pattern_type}"
                )

            # Try to validate regex patterns (type 1)
            if pattern_type == 1:
                try:
                    re.compile(pattern.get("pattern", ""))
                except re.error as e:
                    self._add_issue(
                        file_path, Severity.WARNING,
                        f"Pattern {i+1} has invalid regex: {e}"
                    )

    def _validate_timer_time(self, file_path: Path, metadata: Dict[str, Any]):
        """Validate timer time format."""
        time_str = metadata.get("time", "")
        if time_str:
            # Expected format: HH:MM:SS.mmm
            time_pattern = r"^\d{2}:\d{2}:\d{2}\.\d{3}$"
            if not re.match(time_pattern, time_str):
                self._add_issue(
                    file_path, Severity.WARNING,
                    f"Time format should be HH:MM:SS.mmm, got '{time_str}'"
                )

    def _validate_alias_regex(self, file_path: Path, metadata: Dict[str, Any]):
        """Validate alias regex pattern."""
        regex = metadata.get("regex", "")
        if regex:
            try:
                re.compile(regex)
            except re.error as e:
                self._add_issue(
                    file_path, Severity.ERROR,
                    f"Invalid regex pattern: {e}"
                )

    def _validate_key_codes(self, file_path: Path, metadata: Dict[str, Any]):
        """Validate key code and modifier."""
        key_code = metadata.get("keyCode", 0)
        key_modifier = metadata.get("keyModifier", 0)

        if not isinstance(key_code, int):
            self._add_issue(
                file_path, Severity.ERROR,
                f"keyCode must be an integer, got {type(key_code).__name__}"
            )

        if not isinstance(key_modifier, int):
            self._add_issue(
                file_path, Severity.ERROR,
                f"keyModifier must be an integer, got {type(key_modifier).__name__}"
            )

    def _validate_hierarchy(self, file_path: Path, metadata: Dict[str, Any]):
        """Validate hierarchy field."""
        hierarchy = metadata.get("hierarchy", [])

        if not isinstance(hierarchy, list):
            self._add_issue(
                file_path, Severity.ERROR,
                f"Hierarchy must be a list, got {type(hierarchy).__name__}"
            )
            return

        for i, item in enumerate(hierarchy):
            if not isinstance(item, str):
                self._add_issue(
                    file_path, Severity.ERROR,
                    f"Hierarchy item {i+1} must be a string"
                )

    def validate_file(self, file_path: Path) -> bool:
        """
        Validate a single Lua file.

        Returns:
            True if valid (no errors), False otherwise
        """
        try:
            content = file_path.read_text(encoding='utf-8')
        except Exception as e:
            self._add_issue(file_path, Severity.ERROR, f"Cannot read file: {e}")
            return False

        # Validate YAML header
        metadata = self._validate_yaml_header(file_path, content)
        if metadata is None:
            return False

        # Get element type
        element_type = metadata.get("type")
        if not element_type:
            self._add_issue(file_path, Severity.ERROR, "Missing 'type' field")
            return False

        if element_type not in self.REQUIRED_FIELDS:
            self._add_issue(
                file_path, Severity.ERROR,
                f"Unknown type: '{element_type}'"
            )
            return False

        # Validate required fields
        self._validate_required_fields(file_path, metadata, element_type)

        # Validate attributes
        self._validate_attributes(file_path, metadata, element_type)

        # Validate hierarchy
        self._validate_hierarchy(file_path, metadata)

        # Type-specific validation
        if element_type == "trigger":
            self._validate_trigger_patterns(file_path, metadata)
        elif element_type == "timer":
            self._validate_timer_time(file_path, metadata)
        elif element_type == "alias":
            self._validate_alias_regex(file_path, metadata)
        elif element_type == "key":
            self._validate_key_codes(file_path, metadata)

        # Check for errors in this file
        file_errors = [
            i for i in self.issues
            if i.file_path == file_path and i.severity == Severity.ERROR
        ]
        return len(file_errors) == 0

    def validate_directory(self, package_type: str) -> Tuple[int, int, int]:
        """
        Validate all files in a package type directory.

        Args:
            package_type: One of 'triggers', 'timers', 'aliases', 'scripts', 'keys'

        Returns:
            Tuple of (files_checked, errors, warnings)
        """
        base_dir = self.src_dir / package_type
        if not base_dir.exists():
            return 0, 0, 0

        files_checked = 0
        start_issues = len(self.issues)

        for lua_file in sorted(base_dir.rglob("*.lua")):
            self.validate_file(lua_file)
            files_checked += 1

        new_issues = self.issues[start_issues:]
        errors = sum(1 for i in new_issues if i.severity == Severity.ERROR)
        warnings = sum(1 for i in new_issues if i.severity == Severity.WARNING)

        return files_checked, errors, warnings

    def validate_all(self) -> bool:
        """
        Validate all package types.

        Returns:
            True if valid (no errors, or no errors and no warnings in strict mode)
        """
        print(f"Validating: {self.src_dir}")
        print()

        total_files = 0
        total_errors = 0
        total_warnings = 0

        for pkg_type in ["triggers", "timers", "aliases", "scripts", "keys"]:
            files, errors, warnings = self.validate_directory(pkg_type)
            if files > 0:
                status = "OK" if errors == 0 else f"{errors} errors"
                if warnings > 0:
                    status += f", {warnings} warnings"
                print(f"  {pkg_type}: {files} files - {status}")
            total_files += files
            total_errors += errors
            total_warnings += warnings

        print()
        print(f"Total: {total_files} files, {total_errors} errors, {total_warnings} warnings")

        # Print issues
        if self.issues:
            print()
            print("Issues found:")
            for issue in sorted(self.issues, key=lambda i: (i.severity.value, str(i.file_path))):
                print(f"  {issue}")

        print()
        if total_errors > 0:
            print("Validation FAILED")
            return False
        elif total_warnings > 0 and self.strict:
            print("Validation FAILED (strict mode)")
            return False
        else:
            print("Validation PASSED")
            return True

    def validate_type(self, package_type: str) -> bool:
        """
        Validate a specific package type.

        Returns:
            True if valid
        """
        print(f"Validating {package_type}: {self.src_dir / package_type}")
        print()

        files, errors, warnings = self.validate_directory(package_type)

        print(f"Files checked: {files}")
        print(f"Errors: {errors}")
        print(f"Warnings: {warnings}")

        if self.issues:
            print()
            print("Issues found:")
            for issue in self.issues:
                print(f"  {issue}")

        print()
        if errors > 0:
            print("Validation FAILED")
            return False
        elif warnings > 0 and self.strict:
            print("Validation FAILED (strict mode)")
            return False
        else:
            print("Validation PASSED")
            return True


def main():
    parser = argparse.ArgumentParser(
        description="Validate Mudlet package files"
    )
    parser.add_argument(
        "src_dir",
        help="Source directory to validate"
    )
    parser.add_argument(
        "--type", "-t",
        choices=["triggers", "timers", "aliases", "scripts", "keys"],
        help="Validate only a specific package type"
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as errors"
    )

    args = parser.parse_args()

    # Validate source directory
    src_path = Path(args.src_dir)
    if not src_path.exists():
        print(f"Error: Directory not found: {src_path}")
        sys.exit(1)

    validator = MudletValidator(args.src_dir, args.strict)

    if args.type:
        success = validator.validate_type(args.type)
    else:
        success = validator.validate_all()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
