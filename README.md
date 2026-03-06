# LEVI-Achaea

A comprehensive [Mudlet](https://www.mudlet.org/) automation and combat system for [Achaea](https://www.achaea.com/), an Iron Realms Entertainment MUD.

## What's Included

| System | Description |
|--------|-------------|
| **Ataxia Combat System** | Affliction tracking (100+ affs), defense management, automated curing, limb tracking |
| **Class Offense Modules** | Automated combat for 18+ classes (Serpent, Shaman, Blademaster, Infernal DWC, Apostate, Monk, and more) |
| **Mudlet Mapper (mmp)** | Speedwalking, fast travel (wings/tarot/harness), balance-aware movement, multi-game support |
| **Automated Basher** | PvE hunting with 20+ class support, area pathing, flee safety, battlerage rotation |
| **Player Database (ataxiaNDB)** | Achaea API integration, city-based name highlighting, enemy tracking |
| **Custom GUI (ataxiagui)** | Health/mana gauges, map display, tabbed chat, balance indicators |
| **Affliction Tracking V2/V3** | Advanced certainty-based tracking with stack support and cure prediction |

## Quick Install

**Option A** — Use a pre-built package:
1. After building (see below), the package is at `muddler_project/build/Levi_Ataxia.mpackage`
2. Open Mudlet → Package Manager → Install
3. Select the `.mpackage` file

> **Note**: The `packages/` directory contains legacy XML builds. For the current version, always build from source using the steps below.

---

## Building from Source

### Prerequisites

| Requirement | Details |
|-------------|---------|
| **Python 3.8+** | For the conversion script |
| **Java 8+** | For Muddler (the Mudlet package builder) |
| **Muddler** | Download from [demonnic/muddler](https://github.com/demonnic/muddler) |

### Step 1: Convert source to Muddler format

The source code lives in `src_new/` as YAML-header Lua files organized by Mudlet item type. The conversion script strips headers, builds the JSON hierarchy, and outputs a Muddler project.

```bash
cd LEVI-Achaea
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project
```

This reads all `_groups.yaml` hierarchy definitions and `.lua` source files, then generates:
- `muddler_project/src/scripts/Levi_Ataxia/scripts.json` + Lua files
- `muddler_project/src/triggers/Levi_Ataxia/triggers.json` + Lua files
- `muddler_project/src/aliases/Levi_Ataxia/aliases.json` + Lua files
- `muddler_project/src/timers/Levi_Ataxia/timers.json` + Lua files
- `muddler_project/src/keys/Levi_Ataxia/keys.json` + Lua files
- `muddler_project/mfile` (package metadata)

### Step 2: Build with Muddler

```bash
# Set JAVA_HOME to your Java installation
set JAVA_HOME=C:\Path\To\Java

# Run Muddler from the project directory
cd muddler_project
/path/to/muddler/bin/muddle.bat     # Windows
/path/to/muddler/bin/muddle         # Linux/macOS
```

Output: `muddler_project/build/Levi_Ataxia.mpackage`

### Step 3: Install in Mudlet

1. Open Mudlet → Package Manager
2. Install `muddler_project/build/Levi_Ataxia.mpackage`
3. Reconnect to Achaea (GMCP must be enabled under Settings → Protocols)

### Conversion Script Options

```
python tools/convert_to_muddler.py --help

  --src, -s          Source directory (default: ./src_new)
  --output, -o       Output Muddler project directory (default: ./muddler_project)
  --verbose, -v      Enable verbose output
  --dry-run, -n      Scan and report without writing
  --package-name     Package name (default: Levi_Ataxia)
  --package-title    Human-readable title
  --package-version  Version string (default: 4.1)
  --package-author   Author name (default: Leviticus)
  --include-roots    Root group names to include from _groups.yaml
  --include-dirs     Source subdirectory names to scan
```

### Building a Custom Sub-Package

You can build a standalone package from a subset of the source tree:

```bash
python tools/convert_to_muddler.py --src ./src_new --output ./my_package_project \
  --package-name My_Package --package-title "My Package" --include-roots My_Package

cd my_package_project
/path/to/muddler/bin/muddle.bat
```

---

## Repository Structure

```
LEVI-Achaea/
├── src_new/                    # Canonical source (YAML-header Lua files)
│   ├── aliases/                #   Command aliases
│   ├── keys/                   #   Key bindings
│   ├── scripts/                #   Lua script modules
│   │   └── levi_ataxia/levi/
│   │       ├── ataxia/         #     Core combat system, basher, curing, GUI
│   │       └── levi_scripts/   #     Class-specific offense modules (18+ classes)
│   ├── timers/                 #   Timer definitions
│   └── triggers/               #   Game text pattern matching (1800+ triggers)
├── muddler_project/            # Generated Muddler build project
│   ├── mfile                   #   Package metadata
│   ├── src/                    #   Generated JSON + Lua per item type
│   └── build/                  #   Built .mpackage output
├── tools/
│   ├── convert_to_muddler.py  #   Source → Muddler project converter
│   ├── flatten_groups.py       #   Flatten intermediate wrapper groups in _groups.yaml
│   ├── flatten_alias_hierarchy.py  # Bulk alias hierarchy remapping
│   ├── compare_builds.py       #   Compare XML vs Muddler output
│   ├── mudlet_extract.py       #   Extract XML package → src_new format
│   └── lib/                    #   Shared library code (hierarchy, YAML parsing)
├── packages/                   # Pre-built Mudlet packages
├── docs/
│   ├── plans/                  #   Project plans and reviews
│   ├── legend-deck.md          #   Legend Deck card reference
│   └── artefacts-reference.md  #   Artefact effects reference
├── .claude/
│   └── classes/                # 26 class mechanic files + lock_types.md
├── CLAUDE.md                   # Full system documentation (AI assistant guide)
├── GETTING_STARTED.md          # Setup and usage guide
├── CHANGELOG.md                # Change history
└── README.md                   # This file
```

### Source File Format

Each `.lua` file in `src_new/` has a YAML metadata header followed by Lua code:

```lua
--- # YAML header
name: My Script Name
hierarchy: [Levi_Ataxia, System-related, Combat]
isActive: 'yes'
---
-- Lua code starts here
function myFunction()
  -- ...
end
```

Files use numbered prefixes (e.g., `001_`, `002_`) for load ordering within each group.

Group hierarchy is defined in `_groups.yaml` files at each item type root (e.g., `src_new/scripts/_groups.yaml`).

---

## Visual Studio 2022

Open the `LEVI-Achaea/` folder via **File > Open > Folder**. Build tasks are in `.vs/tasks.vs.json`:

| Task | Description |
|------|-------------|
| **Build Levi_Ataxia** | Full convert + Muddler pipeline |
| **Build Levi_Test** | Build the test/distribution package |
| **Convert Only** | Run conversion without building |
| **Convert Only (Dry Run)** | Preview conversion output |
| **Clean Build Output** | Remove `muddler_project/build/` |

Right-click the root folder in Solution Explorer to run any task.

---

## Documentation

| Document | Purpose |
|----------|---------|
| [GETTING_STARTED.md](GETTING_STARTED.md) | Setup guide, system overview, common tasks |
| [CLAUDE.md](CLAUDE.md) | Full technical reference (architecture, APIs, combat mechanics, development guidelines) |
| [CHANGELOG.md](CHANGELOG.md) | Change history with dates and details |
| [docs/legend-deck.md](docs/legend-deck.md) | Legend Deck card reference and PVE guide |
| [.claude/classes/](LEVI-Achaea/.claude/classes/) | Per-class combat mechanic documentation (26 classes) |

---

## Technology

- **Language**: Lua 5.1
- **Platform**: Mudlet MUD Client
- **Build Tool**: Muddler (Java)
- **Conversion**: Python 3
- **Target Game**: Achaea (Iron Realms Entertainment)

## License

Private use.
