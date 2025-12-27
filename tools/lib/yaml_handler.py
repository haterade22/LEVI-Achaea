"""
YAML Header Handler for Mudlet Lua files.

Handles parsing and serialization of YAML metadata headers embedded
in Lua files using the --[[mudlet ... ]]-- comment format.
"""

import re
import yaml
from typing import Dict, Any, Tuple, Optional


class YAMLHeaderHandler:
    """Handle YAML headers embedded in Lua files."""

    HEADER_START = "--[[mudlet"
    HEADER_END = "]]--"

    # Regex to match the entire header block
    HEADER_PATTERN = re.compile(
        r'^--\[\[mudlet\s*\n(.*?)\n\]\]--\s*\n?',
        re.MULTILINE | re.DOTALL
    )

    @classmethod
    def parse(cls, lua_content: str) -> Tuple[Optional[Dict[str, Any]], str]:
        """
        Parse YAML header from Lua file content.

        Args:
            lua_content: The full content of a Lua file

        Returns:
            Tuple of (metadata dict or None, remaining Lua code)
        """
        match = cls.HEADER_PATTERN.match(lua_content)

        if not match:
            # No header found, return None and original content
            return None, lua_content

        yaml_content = match.group(1)
        lua_code = lua_content[match.end():]

        # Strip leading newlines from code but preserve internal formatting
        lua_code = lua_code.lstrip('\n')

        try:
            metadata = yaml.safe_load(yaml_content)
            return metadata, lua_code
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML header: {e}")

    @classmethod
    def serialize(cls, metadata: Dict[str, Any], lua_code: str) -> str:
        """
        Combine metadata and Lua code into file content.

        Args:
            metadata: Dictionary of metadata to serialize as YAML
            lua_code: The Lua code to follow the header

        Returns:
            Complete file content with YAML header and Lua code
        """
        # Custom YAML formatting for readability
        yaml_content = yaml.dump(
            metadata,
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
            width=120,
        )

        # Build the complete file
        lines = [
            cls.HEADER_START,
            yaml_content.rstrip(),
            cls.HEADER_END,
            "",  # Empty line between header and code
        ]

        # Add Lua code if present
        if lua_code.strip():
            lines.append(lua_code)

        return "\n".join(lines)

    @classmethod
    def has_header(cls, lua_content: str) -> bool:
        """Check if content has a YAML header."""
        return lua_content.strip().startswith(cls.HEADER_START)

    @classmethod
    def create_trigger_metadata(
        cls,
        name: str,
        hierarchy: list,
        patterns: list,
        attributes: dict = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Create metadata dict for a trigger."""
        metadata = {
            "type": "trigger",
            "name": name,
            "hierarchy": hierarchy,
            "attributes": attributes or {
                "isActive": "yes",
                "isFolder": "no",
                "isTempTrigger": "no",
                "isMultiline": "no",
                "isPerlSlashGOption": "no",
                "isColorizerTrigger": "no",
                "isFilterTrigger": "no",
                "isSoundTrigger": "no",
                "isColorTrigger": "no",
                "isColorTriggerFg": "no",
                "isColorTriggerBg": "no",
            },
            "patterns": patterns,
        }

        # Add optional fields
        optional_fields = [
            "triggerType", "conditonLineDelta", "mStayOpen",
            "mCommand", "packageName", "mFgColor", "mBgColor",
            "mSoundFile", "colorTriggerFgColor", "colorTriggerBgColor"
        ]
        for field in optional_fields:
            if field in kwargs:
                metadata[field] = kwargs[field]

        return metadata

    @classmethod
    def create_timer_metadata(
        cls,
        name: str,
        hierarchy: list,
        time: str = "00:00:00.000",
        attributes: dict = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Create metadata dict for a timer."""
        return {
            "type": "timer",
            "name": name,
            "hierarchy": hierarchy,
            "attributes": attributes or {
                "isActive": "yes",
                "isFolder": "no",
                "isTempTimer": "no",
                "isOffsetTimer": "no",
            },
            "time": time,
            "command": kwargs.get("command", ""),
            "packageName": kwargs.get("packageName", ""),
        }

    @classmethod
    def create_alias_metadata(
        cls,
        name: str,
        hierarchy: list,
        regex: str,
        attributes: dict = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Create metadata dict for an alias."""
        return {
            "type": "alias",
            "name": name,
            "hierarchy": hierarchy,
            "attributes": attributes or {
                "isActive": "yes",
                "isFolder": "no",
            },
            "regex": regex,
            "command": kwargs.get("command", ""),
            "packageName": kwargs.get("packageName", ""),
        }

    @classmethod
    def create_script_metadata(
        cls,
        name: str,
        hierarchy: list,
        event_handlers: list = None,
        attributes: dict = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Create metadata dict for a script."""
        metadata = {
            "type": "script",
            "name": name,
            "hierarchy": hierarchy,
            "attributes": attributes or {
                "isActive": "yes",
                "isFolder": "no",
            },
            "packageName": kwargs.get("packageName", ""),
        }
        if event_handlers:
            metadata["eventHandlers"] = event_handlers
        return metadata

    @classmethod
    def create_key_metadata(
        cls,
        name: str,
        hierarchy: list,
        key_code: int,
        key_modifier: int = 0,
        attributes: dict = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Create metadata dict for a key binding."""
        return {
            "type": "key",
            "name": name,
            "hierarchy": hierarchy,
            "attributes": attributes or {
                "isActive": "yes",
                "isFolder": "no",
            },
            "keyCode": key_code,
            "keyModifier": key_modifier,
            "command": kwargs.get("command", ""),
            "packageName": kwargs.get("packageName", ""),
        }
