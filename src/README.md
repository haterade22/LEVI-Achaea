# LEVI Achaea Scripts - Source Directory

This directory contains all Lua code extracted from the Mudlet XML package, organized into a modular structure.

## Directory Structure

### mmp/ (134 files)
Mudlet Mapper system - handles all navigation, pathfinding, and speedwalking functionality.
- Map features and utilities
- Wings and fast travel
- Speedwalking engine
- Game-specific handlers (Achaea, Lusternia, Imperian, etc.)
- Area locking and room tracking
- Map update checking

### ataxia/ (301 files)
Core Ataxia combat system - main affliction tracking and combat logic.
- Affliction tracking and management
- Defense tracking and reporting
- Curing priorities and queue management
- Balance/equilibrium tracking
- Class-specific combat logic (Alchemist, Depthswalker, Bard, Magi, etc.)
- Limb counting for multiple classes
- Rift management
- Priority swaps and management
- Combat utilities and helpers

### ataxiagui/ (5 files)
Ataxia GUI using Geyser - visual interface elements.
- GUI creation and layout
- Map and chat windows
- Chat capture
- Vitals bars and displays
- Responsive UI for different window sizes

### ataxiaNDB/ (7 files)
Ataxia NDB (Name Database) - player database with API integration.
- Player information lookup
- City/faction tracking
- Enemy highlighting
- Mark and army rank tracking
- API for retrieving player data

### ataxiaBasher/ (12 files)
Automated hunting/bashing system.
- Experience tracking database
- Movement and navigation
- Target selection
- Class-specific bashing attacks
- Auto-engagement/disengagement
- Bash statistics tracking
- Area management

## Loading the Scripts

Use `loader.lua` to load all scripts in the correct order:

```lua
dofile(getMudletHomeDir() .. "/LEVI-Achaea/src/loader.lua")
```

The loader loads directories in this order:
1. mmp (mapper first - core navigation)
2. ataxia (core combat system)
3. ataxiagui (GUI overlays)
4. ataxiaNDB (player database)
5. ataxiaBasher (automated hunting)

## File Naming Convention

Files are numbered sequentially (001, 002, etc.) to maintain load order within each directory. Each file includes a header comment showing its original hierarchy in the XML package.

Example:
```lua
-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Create Option Table
```

## Total Statistics

- **Total Files**: 466 Lua files (459 scripts + loader + README + extraction script + old dirs)
- **Total Size**: ~3.1 MB of Lua code
- **Source**: Extracted from Scripts_Levi.xml (2MB, 65,145 lines)

## Extraction Process

The code was extracted using `extract_mudlet_xml.py`, which:
1. Parses the Mudlet XML package
2. Extracts Lua code from `<script>` tags
3. Converts HTML entities (&lt;, &gt;, &amp;) back to normal characters
4. Organizes scripts by system based on hierarchy
5. Creates numbered files with descriptive names
6. Generates the loader with proper load order

## Original Structure

The XML package had this hierarchy:
```
For Levi
├── mudlet-mapper
│   └── Mudlet Mapper (scripts for mmp system)
└── Levi_062424
    └── leviticus
        └── LeviAtaxia
            └── Ataxia-DownloadThis
                └── Ataxia
                    ├── Gui Stuff (GUI scripts)
                    ├── Gmcp Related (GMCP handlers)
                    ├── Ataxia NDB (player database)
                    └── Basher (automated hunting)
```

## Notes

- All original code logic has been preserved
- HTML entities have been properly decoded
- File organization follows the original system boundaries
- Each file is standalone but may have dependencies on other files in the same or earlier-loaded directories
