"""
Mudlet XML Parser

Parses Mudlet XML packages and extracts all element types with their
full attributes and hierarchy information.
"""

import xml.etree.ElementTree as ET
import html
import re
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple, Iterator
from dataclasses import dataclass, field

from .data_types import (
    Trigger, Timer, Alias, Script, Key, Group,
    Pattern, PatternType
)


def unescape_html(text: str) -> str:
    """Convert HTML entities back to normal characters."""
    if not text:
        return ""
    return html.unescape(text)


def escape_xml(text: str) -> str:
    """Escape special characters for XML content."""
    if not text:
        return ""
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")
    return text


def get_element_text(element: ET.Element, tag: str, default: str = "") -> str:
    """Get text content of a child element, unescaping HTML entities."""
    child = element.find(tag)
    if child is not None and child.text:
        return unescape_html(child.text)
    return default


def get_bool_attr(element: ET.Element, attr: str, default: bool = False) -> bool:
    """Get boolean attribute value."""
    value = element.get(attr, "no" if not default else "yes")
    return value.lower() == "yes"


def get_int_element(element: ET.Element, tag: str, default: int = 0) -> int:
    """Get integer text content of a child element."""
    child = element.find(tag)
    if child is not None and child.text:
        try:
            return int(child.text)
        except ValueError:
            return default
    return default


@dataclass
class ExtractedGroup:
    """A group with its hierarchy path and children."""
    name: str
    hierarchy: List[str]
    package_name: str
    is_active: bool
    script: str
    attributes: Dict[str, str]
    children: List[Any] = field(default_factory=list)


class MudletXMLParser:
    """Parse Mudlet XML packages into structured data."""

    def __init__(self, xml_path: str):
        """
        Initialize parser with XML file path.

        Args:
            xml_path: Path to the Mudlet XML package file
        """
        self.xml_path = Path(xml_path)
        self.tree = ET.parse(str(xml_path))
        self.root = self.tree.getroot()

    def _parse_trigger(self, element: ET.Element, hierarchy: List[str]) -> Trigger:
        """Parse a single Trigger element."""
        name = get_element_text(element, "name", "unnamed")

        # Parse patterns
        patterns = []
        regex_list = element.find("regexCodeList")
        prop_list = element.find("regexCodePropertyList")

        if regex_list is not None:
            pattern_texts = [s.text or "" for s in regex_list.findall("string")]
            pattern_types = []
            if prop_list is not None:
                pattern_types = [
                    int(i.text or "0") for i in prop_list.findall("integer")
                ]

            for i, text in enumerate(pattern_texts):
                ptype = pattern_types[i] if i < len(pattern_types) else 0
                # Handle unknown pattern types gracefully
                try:
                    pattern_type = PatternType(ptype)
                except ValueError:
                    pattern_type = ptype  # Store as int if not in enum
                patterns.append(Pattern(
                    pattern=unescape_html(text),
                    type=pattern_type
                ))

        # Parse child triggers
        children = []
        for child in element:
            if child.tag == "Trigger":
                children.append(self._parse_trigger(child, hierarchy + [name]))

        return Trigger(
            name=name,
            hierarchy=hierarchy,
            script=get_element_text(element, "script"),
            is_active=get_bool_attr(element, "isActive", True),
            package_name=get_element_text(element, "packageName"),
            patterns=patterns,
            is_folder=get_bool_attr(element, "isFolder"),
            is_temp_trigger=get_bool_attr(element, "isTempTrigger"),
            is_multiline=get_bool_attr(element, "isMultiline"),
            is_perl_slash_g_option=get_bool_attr(element, "isPerlSlashGOption"),
            is_colorizer_trigger=get_bool_attr(element, "isColorizerTrigger"),
            is_filter_trigger=get_bool_attr(element, "isFilterTrigger"),
            is_sound_trigger=get_bool_attr(element, "isSoundTrigger"),
            is_color_trigger=get_bool_attr(element, "isColorTrigger"),
            is_color_trigger_fg=get_bool_attr(element, "isColorTriggerFg"),
            is_color_trigger_bg=get_bool_attr(element, "isColorTriggerBg"),
            trigger_type=get_int_element(element, "triggerType"),
            condition_line_delta=get_int_element(element, "conditonLineDelta"),
            m_stay_open=get_int_element(element, "mStayOpen"),
            m_command=get_element_text(element, "mCommand"),
            m_fg_color=get_element_text(element, "mFgColor", "#ff0000"),
            m_bg_color=get_element_text(element, "mBgColor", "#ffff00"),
            m_sound_file=get_element_text(element, "mSoundFile"),
            color_trigger_fg_color=get_element_text(element, "colorTriggerFgColor", "#000000"),
            color_trigger_bg_color=get_element_text(element, "colorTriggerBgColor", "#000000"),
            children=children,
        )

    def _parse_timer(self, element: ET.Element, hierarchy: List[str]) -> Timer:
        """Parse a single Timer element."""
        name = get_element_text(element, "name", "unnamed")

        return Timer(
            name=name,
            hierarchy=hierarchy,
            script=get_element_text(element, "script"),
            is_active=get_bool_attr(element, "isActive", True),
            package_name=get_element_text(element, "packageName"),
            time=get_element_text(element, "time", "00:00:00.000"),
            command=get_element_text(element, "command"),
            is_folder=get_bool_attr(element, "isFolder"),
            is_temp_timer=get_bool_attr(element, "isTempTimer"),
            is_offset_timer=get_bool_attr(element, "isOffsetTimer"),
        )

    def _parse_alias(self, element: ET.Element, hierarchy: List[str]) -> Alias:
        """Parse a single Alias element."""
        name = get_element_text(element, "name", "unnamed")

        return Alias(
            name=name,
            hierarchy=hierarchy,
            script=get_element_text(element, "script"),
            is_active=get_bool_attr(element, "isActive", True),
            package_name=get_element_text(element, "packageName"),
            regex=get_element_text(element, "regex"),
            command=get_element_text(element, "command"),
            is_folder=get_bool_attr(element, "isFolder"),
        )

    def _parse_script(self, element: ET.Element, hierarchy: List[str]) -> Script:
        """Parse a single Script element."""
        name = get_element_text(element, "name", "unnamed")

        # Parse event handlers
        event_handlers = []
        handler_list = element.find("eventHandlerList")
        if handler_list is not None:
            event_handlers = [
                s.text for s in handler_list.findall("string")
                if s.text
            ]

        return Script(
            name=name,
            hierarchy=hierarchy,
            script=get_element_text(element, "script"),
            is_active=get_bool_attr(element, "isActive", True),
            package_name=get_element_text(element, "packageName"),
            event_handlers=event_handlers,
            is_folder=get_bool_attr(element, "isFolder"),
        )

    def _parse_key(self, element: ET.Element, hierarchy: List[str]) -> Key:
        """Parse a single Key element."""
        name = get_element_text(element, "name", "unnamed")

        return Key(
            name=name,
            hierarchy=hierarchy,
            script=get_element_text(element, "script"),
            is_active=get_bool_attr(element, "isActive", True),
            package_name=get_element_text(element, "packageName"),
            key_code=get_int_element(element, "keyCode"),
            key_modifier=get_int_element(element, "keyModifier"),
            command=get_element_text(element, "command"),
            is_folder=get_bool_attr(element, "isFolder"),
        )

    def _extract_from_group(
        self,
        element: ET.Element,
        hierarchy: List[str],
        group_tag: str,
        item_tag: str,
        parser_func,
    ) -> Tuple[List[ExtractedGroup], List[Any]]:
        """
        Recursively extract items and groups from an element.

        Returns:
            Tuple of (groups list, items list)
        """
        groups = []
        items = []

        name = get_element_text(element, "name", "unnamed")
        current_hierarchy = hierarchy + [name]

        # Collect attributes for group
        attributes = {
            "isActive": element.get("isActive", "yes"),
            "isFolder": element.get("isFolder", "yes"),
        }
        for attr in element.attrib:
            attributes[attr] = element.get(attr)

        group = ExtractedGroup(
            name=name,
            hierarchy=hierarchy,
            package_name=get_element_text(element, "packageName"),
            is_active=get_bool_attr(element, "isActive", True),
            script=get_element_text(element, "script"),
            attributes=attributes,
        )

        # Process children
        for child in element:
            if child.tag == group_tag:
                # Nested group
                child_groups, child_items = self._extract_from_group(
                    child, current_hierarchy, group_tag, item_tag, parser_func
                )
                groups.extend(child_groups)
                items.extend(child_items)
            elif child.tag == item_tag:
                # Item (Trigger, Timer, etc.)
                item = parser_func(child, current_hierarchy)
                items.append(item)
                group.children.append(item)

        groups.append(group)
        return groups, items

    def extract_triggers(self) -> Tuple[List[ExtractedGroup], List[Trigger]]:
        """
        Extract all triggers with their group hierarchy.

        Returns:
            Tuple of (groups list, triggers list)
        """
        all_groups = []
        all_triggers = []

        trigger_package = self.root.find(".//TriggerPackage")
        if trigger_package is None:
            return all_groups, all_triggers

        for group_elem in trigger_package.findall("TriggerGroup"):
            groups, triggers = self._extract_from_group(
                group_elem, [], "TriggerGroup", "Trigger", self._parse_trigger
            )
            all_groups.extend(groups)
            all_triggers.extend(triggers)

        return all_groups, all_triggers

    def extract_timers(self) -> Tuple[List[ExtractedGroup], List[Timer]]:
        """Extract all timers with their group hierarchy."""
        all_groups = []
        all_timers = []

        timer_package = self.root.find(".//TimerPackage")
        if timer_package is None:
            return all_groups, all_timers

        for group_elem in timer_package.findall("TimerGroup"):
            groups, timers = self._extract_from_group(
                group_elem, [], "TimerGroup", "Timer", self._parse_timer
            )
            all_groups.extend(groups)
            all_timers.extend(timers)

        return all_groups, all_timers

    def extract_aliases(self) -> Tuple[List[ExtractedGroup], List[Alias]]:
        """Extract all aliases with their group hierarchy."""
        all_groups = []
        all_aliases = []

        alias_package = self.root.find(".//AliasPackage")
        if alias_package is None:
            return all_groups, all_aliases

        for group_elem in alias_package.findall("AliasGroup"):
            groups, aliases = self._extract_from_group(
                group_elem, [], "AliasGroup", "Alias", self._parse_alias
            )
            all_groups.extend(groups)
            all_aliases.extend(aliases)

        return all_groups, all_aliases

    def extract_scripts(self) -> Tuple[List[ExtractedGroup], List[Script]]:
        """Extract all scripts with their group hierarchy."""
        all_groups = []
        all_scripts = []

        script_package = self.root.find(".//ScriptPackage")
        if script_package is None:
            return all_groups, all_scripts

        for group_elem in script_package.findall("ScriptGroup"):
            groups, scripts = self._extract_from_group(
                group_elem, [], "ScriptGroup", "Script", self._parse_script
            )
            all_groups.extend(groups)
            all_scripts.extend(scripts)

        return all_groups, all_scripts

    def extract_keys(self) -> Tuple[List[ExtractedGroup], List[Key]]:
        """Extract all keys with their group hierarchy."""
        all_groups = []
        all_keys = []

        key_package = self.root.find(".//KeyPackage")
        if key_package is None:
            return all_groups, all_keys

        for group_elem in key_package.findall("KeyGroup"):
            groups, keys = self._extract_from_group(
                group_elem, [], "KeyGroup", "Key", self._parse_key
            )
            all_groups.extend(groups)
            all_keys.extend(keys)

        return all_groups, all_keys

    def extract_all(self) -> Dict[str, Tuple[List[ExtractedGroup], List[Any]]]:
        """
        Extract all package types.

        Returns:
            Dictionary mapping package type to (groups, items) tuple
        """
        return {
            "triggers": self.extract_triggers(),
            "timers": self.extract_timers(),
            "aliases": self.extract_aliases(),
            "scripts": self.extract_scripts(),
            "keys": self.extract_keys(),
        }
