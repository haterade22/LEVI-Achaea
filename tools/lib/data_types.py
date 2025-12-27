"""
Data types for Mudlet XML elements.

Each element type (Trigger, Timer, Alias, Script, Key) is represented
as a dataclass with all relevant attributes from the XML.
"""

from dataclasses import dataclass, field
from enum import IntEnum
from typing import List, Dict, Any, Optional, Union


class PatternType(IntEnum):
    """Mudlet trigger pattern types."""
    SUBSTRING = 0           # Simple substring match
    PERL_REGEX = 1          # Perl-compatible regex
    BEGIN_OF_LINE = 2       # Substring at start of line
    EXACT_MATCH = 3         # Exact line match
    LUA_FUNCTION = 4        # Lua function pattern
    LINE_SPACER = 5         # Line spacer (multiline)
    COLOR_TRIGGER = 6       # Color-based trigger
    PROMPT = 7              # Prompt pattern
    # Reserved for future Mudlet versions
    RESERVED_8 = 8
    RESERVED_9 = 9
    RESERVED_10 = 10


@dataclass
class Pattern:
    """A trigger pattern with its type."""
    pattern: str
    type: Union[PatternType, int] = PatternType.SUBSTRING

    def to_dict(self) -> Dict[str, Any]:
        return {
            "pattern": self.pattern,
            "type": int(self.type) if isinstance(self.type, PatternType) else self.type
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Pattern":
        ptype = data.get("type", 0)
        try:
            pattern_type = PatternType(ptype)
        except ValueError:
            pattern_type = ptype  # Keep as int if unknown
        return cls(
            pattern=data["pattern"],
            type=pattern_type
        )


@dataclass
class MudletElement:
    """Base class for all Mudlet elements."""
    name: str
    hierarchy: List[str]
    script: str = ""
    is_active: bool = True
    package_name: str = ""

    def get_type(self) -> str:
        """Return the element type name."""
        raise NotImplementedError


@dataclass
class Trigger(MudletElement):
    """A Mudlet trigger with patterns and attributes."""
    patterns: List[Pattern] = field(default_factory=list)

    # Boolean attributes
    is_folder: bool = False
    is_temp_trigger: bool = False
    is_multiline: bool = False
    is_perl_slash_g_option: bool = False
    is_colorizer_trigger: bool = False
    is_filter_trigger: bool = False
    is_sound_trigger: bool = False
    is_color_trigger: bool = False
    is_color_trigger_fg: bool = False
    is_color_trigger_bg: bool = False

    # Integer attributes
    trigger_type: int = 0
    condition_line_delta: int = 0
    m_stay_open: int = 0

    # String attributes
    m_command: str = ""
    m_fg_color: str = "#ff0000"
    m_bg_color: str = "#ffff00"
    m_sound_file: str = ""
    color_trigger_fg_color: str = "#000000"
    color_trigger_bg_color: str = "#000000"

    # Child triggers (for nested triggers)
    children: List["Trigger"] = field(default_factory=list)

    def get_type(self) -> str:
        return "trigger"

    def get_attributes(self) -> Dict[str, str]:
        """Get XML-style attributes dict."""
        return {
            "isActive": "yes" if self.is_active else "no",
            "isFolder": "yes" if self.is_folder else "no",
            "isTempTrigger": "yes" if self.is_temp_trigger else "no",
            "isMultiline": "yes" if self.is_multiline else "no",
            "isPerlSlashGOption": "yes" if self.is_perl_slash_g_option else "no",
            "isColorizerTrigger": "yes" if self.is_colorizer_trigger else "no",
            "isFilterTrigger": "yes" if self.is_filter_trigger else "no",
            "isSoundTrigger": "yes" if self.is_sound_trigger else "no",
            "isColorTrigger": "yes" if self.is_color_trigger else "no",
            "isColorTriggerFg": "yes" if self.is_color_trigger_fg else "no",
            "isColorTriggerBg": "yes" if self.is_color_trigger_bg else "no",
        }


@dataclass
class Timer(MudletElement):
    """A Mudlet timer."""
    time: str = "00:00:00.000"  # HH:MM:SS.mmm format
    command: str = ""

    # Boolean attributes
    is_folder: bool = False
    is_temp_timer: bool = False
    is_offset_timer: bool = False

    def get_type(self) -> str:
        return "timer"

    def get_attributes(self) -> Dict[str, str]:
        return {
            "isActive": "yes" if self.is_active else "no",
            "isFolder": "yes" if self.is_folder else "no",
            "isTempTimer": "yes" if self.is_temp_timer else "no",
            "isOffsetTimer": "yes" if self.is_offset_timer else "no",
        }


@dataclass
class Alias(MudletElement):
    """A Mudlet alias."""
    regex: str = ""
    command: str = ""

    # Boolean attributes
    is_folder: bool = False

    def get_type(self) -> str:
        return "alias"

    def get_attributes(self) -> Dict[str, str]:
        return {
            "isActive": "yes" if self.is_active else "no",
            "isFolder": "yes" if self.is_folder else "no",
        }


@dataclass
class Script(MudletElement):
    """A Mudlet script."""
    event_handlers: List[str] = field(default_factory=list)

    # Boolean attributes
    is_folder: bool = False

    def get_type(self) -> str:
        return "script"

    def get_attributes(self) -> Dict[str, str]:
        return {
            "isActive": "yes" if self.is_active else "no",
            "isFolder": "yes" if self.is_folder else "no",
        }


@dataclass
class Key(MudletElement):
    """A Mudlet key binding."""
    key_code: int = 0
    key_modifier: int = 0
    command: str = ""

    # Boolean attributes
    is_folder: bool = False

    def get_type(self) -> str:
        return "key"

    def get_attributes(self) -> Dict[str, str]:
        return {
            "isActive": "yes" if self.is_active else "no",
            "isFolder": "yes" if self.is_folder else "no",
        }

    @staticmethod
    def key_code_to_name(code: int) -> str:
        """Convert key code to human-readable name."""
        # Function keys F1-F12
        if 16777264 <= code <= 16777275:
            return f"F{code - 16777264 + 1}"
        # Letters A-Z
        if 65 <= code <= 90:
            return chr(code)
        # Numbers 0-9
        if 48 <= 57:
            return str(code - 48)
        # Arrow keys
        arrow_keys = {
            16777234: "Left",
            16777235: "Up",
            16777236: "Right",
            16777237: "Down",
        }
        if code in arrow_keys:
            return arrow_keys[code]
        return str(code)

    @staticmethod
    def modifier_to_names(modifier: int) -> List[str]:
        """Convert modifier bitmask to list of modifier names."""
        names = []
        if modifier & 33554432:
            names.append("Shift")
        if modifier & 67108864:
            names.append("Ctrl")
        if modifier & 134217728:
            names.append("Alt")
        if modifier & 268435456:
            names.append("Meta")
        return names


@dataclass
class Group:
    """A group container (TriggerGroup, TimerGroup, etc.)."""
    name: str
    package_name: str = ""
    is_active: bool = True
    script: str = ""
    hierarchy: List[str] = field(default_factory=list)
    children: List[Any] = field(default_factory=list)  # Groups or elements

    # Directory mapping for file organization
    directory: Optional[str] = None

    def get_attributes(self) -> Dict[str, str]:
        return {
            "isActive": "yes" if self.is_active else "no",
            "isFolder": "yes",
        }
