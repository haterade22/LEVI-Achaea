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
4. Run the in-game setup wizard (see below)

---

## Getting Started In-Game

After installing the package and connecting to Achaea, use the built-in setup wizard to configure everything:

```
levi setup
```

### First-Time Install

Run these three commands to initialise the subsystems:

| Step | Command | What it does |
|------|---------|-------------|
| 1 | `atinstall` | Configures server-side curing (priorities, sipping, batching), prompt, and loads defaults. Type it twice within 5s to confirm. |
| 2 | `abinstall` | Initialises the basher (target lists, flee thresholds, shield timers) |
| 3 | `aninstall` | Sets up the player database (API integration, city-based name highlighting) |

Or use `levi setup install` for a guided walkthrough.

### Configuration Guide

After installing, `levi setup guide` shows every configurable option across all three subsystems:

| Command | Section |
|---------|---------|
| `levi setup guide ataxia` | Separator, system toggle, custom prompt, defence profiles, curing priorities, item highlighting, sipping, room shortening, GUI, raid mode |
| `levi setup guide basher` | Target lists, flee/shield thresholds, danger mobs, ignore lists, gold pack, shield swap/timer, rageraze, tree blackout |
| `levi setup guide ndb` | City highlight colours, highlight toggle/priority, enemy formatting, player notes, whois lookup |

### Quick Reference

| Command | Purpose |
|---------|---------|
| `levi setup` | Main menu — all setup categories |
| `levi setup class` | Set your class |
| `levi setup separator` | Set command separator (default `;`) |
| `levi setup weapons` | Configure weapon IDs |
| `levi setup basher` | Basher settings |
| `levi setup sipping` | Health/mana sip thresholds |
| `levi setup tracking` | Affliction tracking mode (V1/V2) |
| `levi setup combat` | Combat toggles (party relay, looting, etc.) |
| `levi setup gui` | Toggle the GUI |
| `levi setup ndb` | NDB highlighting colours |
| `levi setup status` | Overview of all current settings |

---

## Player Database (ataxiaNDB)

The ataxiaNDB system tracks player information from the Achaea API and provides city-based name highlighting, enemy tracking, mark/army/dauntless detection, and player notes.

### Installation

Run `aninstall` in-game (or `levi setup install ndb`) to initialise the database. This fetches the online player list from the Achaea API and begins populating player records.

### How It Works

1. **API Population** — On `qwp`, the system fetches `http://api.achaea.com/characters/` to get the online player list, then queues `honours` lookups for unknown players
2. **Honours Capture** — When you `honours <player>`, triggers capture city, house, class, level, XP rank, player kills, mark membership, army rank, and Dauntless status
3. **Auto-Honours** — Players with hidden cities are automatically queued for `honours` lookup (2s spacing) to resolve their city
4. **Name Highlighting** — Once a player's city is known, their name is highlighted in the configured city colour whenever it appears in game text
4. **Persistent Storage** — Player data is saved to disk and persists across sessions

### Quick Reference

#### Online & Lookup

| Command | Description |
|---------|-------------|
| `qwp` | Fetch online players from API, display by city |
| `qwp <city>` | Show online players from a specific city only |
| `whois <name>` | Look up a player's full profile (city, class, house, level, kills, mark, army, dauntless) |
| `honours <name>` | Query honours for a player and add/update in database |

#### Database Queries

| Command | Description |
|---------|-------------|
| `an show <city>` | List all tracked players from a city |
| `an class <class>` | List all tracked players of a class |
| `an classes` | Show player count per class |
| `an cclasses <city>` | Show class distribution for a specific city |
| `an citymembers` | Show tracked player count by city |

#### Threat Intelligence

| Command | Description |
|---------|-------------|
| `an marks [city]` | List Ivory and Quisalis Mark members (optional city filter) |
| `an army [city]` | List players with army rank (sorted by rank, optional city filter) |
| `an dauntless [city]` | List Dauntless members (optional city filter) |
| `an threats [city]` | Combined view: marks + army rank 3+ + dauntless (optional city filter) |

#### Player Notes

| Command | Description |
|---------|-------------|
| `an noteadd <name> <text>` | Add a note to a player |
| `an noteshow <name>` | Show all notes for a player |
| `an noteremove <name> <id>` | Remove a note by ID |

#### Database Maintenance

| Command | Description |
|---------|-------------|
| `an recreate` | Re-query API data for every player in database |
| `an redo <city>` | Re-query API data for all players from a specific city |
| `an refresh` | Send `honours` for all players to update mark/army/dauntless |
| `an refresh <city>` | Send `honours` for players from a specific city only |
| `an remove rank <num>` | Remove players with XP rank above threshold |
| `an remove level <num>` | Remove players with level below threshold |

### Highlighting Configuration

Name highlighting colours players by their city affiliation. Toggle and configure via:

| Command | Description |
|---------|-------------|
| `anhl` | Toggle highlighting on/off |
| `anhl <city> <colour>` | Set highlight colour for a city (e.g., `anhl Mhaldor red`) |
| `anss` | Show all current NDB settings |
| `an prio enemies` | Prioritise enemy colour over city colour |
| `an prio city` | Prioritise city colour over enemy colour |
| `aneh i` | Toggle italic formatting for enemies |
| `aneh u` | Toggle underline formatting for enemies |
| `aneh b` | Toggle bold formatting for enemies |
| `highlight <name> <colour>` | Override colour for a specific player |
| `highlight <name> none` | Remove per-player colour override |

**Available cities**: Ashtan, Cyrene, Eleusis, Hashan, Mhaldor, Targossas, Rogues

Or use the setup wizard: `levi setup ndb` for a guided menu.

### Data Tracked Per Player

| Field | Source | Description |
|-------|--------|-------------|
| Name | API / Honours | Player name |
| City | API / Honours | City affiliation (or Rogues) |
| House | Honours | House membership |
| Class | API / Honours | Current class |
| Level | Honours | Player level |
| XP Rank | Honours | Experience ranking |
| Player Kills | Honours | PK count |
| Mark | Honours | Ivory Mark or Quisalis Mark membership |
| Army Rank | Honours | Army rank (1–5) |
| Dauntless | Honours | Member of The Dauntless |
| Notes | User | Custom player notes |

> **Note**: The Achaea API provides name, city, class, and basic stats. Mark, army rank, and Dauntless are **only** available from in-game `honours` output. Use `an refresh` to bulk-update these fields for all tracked players.

---

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
