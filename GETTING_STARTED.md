# Getting Started with LEVI-Achaea

## Quick Start

### 1. Build and Install

See [README.md](README.md) for full build instructions. The short version:

```bash
# Convert source to Muddler format
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project

# Build with Muddler (requires Java 8+)
set JAVA_HOME=C:\Path\To\Java
cd muddler_project
/path/to/muddler/bin/muddle.bat
```

Output: `muddler_project/build/Levi_Ataxia.mpackage`

Install in Mudlet via Package Manager, then reconnect to Achaea.

### 2. Verify GMCP is Enabled

The system relies heavily on GMCP for real-time game data. In Mudlet:
1. Go to Settings > Protocols
2. Ensure "Enable GMCP" is checked
3. Reconnect to Achaea if needed

### 3. First-Time Setup (In-Game)

After connecting to Achaea, run the setup wizard:

```
ataxia setup
```

#### Step 1: Install the subsystems

Run these three commands to initialise everything:

```
atinstall          -- Core system (type twice within 5s to confirm)
abinstall          -- Basher (hunting system)
aninstall          -- Name Database (player tracking)
```

Or use `ataxia setup install` for a guided walkthrough that explains each step.

#### Step 2: Configure your settings

The setup wizard has individual pages for each area:

```
ataxia setup class           -- Set your class (auto-detects via GMCP)
ataxia setup separator       -- Command separator (default ;)
ataxia setup weapons         -- Weapon IDs for your class
ataxia setup basher          -- Flee thresholds, gold pack, shield swap
ataxia setup sipping         -- Health/mana sip percentages
ataxia setup tracking        -- Affliction tracking settings
ataxia setup combat          -- Party relay, auto-loot, gag clot
ataxia setup gui             -- Toggle the GUI on/off
ataxia setup ndb             -- City highlight colours, enemy formatting
```

#### Step 3: Learn what's configurable

For a full walkthrough of every option in each subsystem:

```
ataxia setup guide           -- Overview of all three guides
ataxia setup guide ataxia    -- Core: separator, prompt, defences, highlights, priorities
ataxia setup guide basher    -- Hunting: targets, flee, danger, gold, shields, rageraze
ataxia setup guide ndb       -- Players: city colours, enemy format, notes, whois
```

#### Step 4: Check your settings

```
ataxia setup status          -- One-page overview of all current values
```

### 4. Test Basic Functionality

```lua
-- Test mapper
mconfig

-- Check ataxia is loaded
display(ataxia)

-- Create GUI
ataxiagui_Create()
```

---

## System Overview

### Mudlet Mapper (mmp)

Navigation and pathfinding with speedwalking, fast travel, and balance-aware movement.

```lua
mconfig                      -- Configure mapper
mmp.gotoRoom(12345)          -- Speedwalk to room
mmp.gotoArea("Ashtan")       -- Go to area entrance
```

### Ataxia Combat System

Core combat engine: affliction tracking, curing, defense management, limb tracking.

**Location**: `src_new/scripts/levi_ataxia/levi/ataxia/`

```lua
display(ataxia.afflictions)  -- View current afflictions
display(ataxia.defences)     -- View active defenses
ataxia.target                -- Current combat target
```

### Class Offense Modules

Automated combat for 18+ classes. Each class has its own subdirectory under `src_new/scripts/levi_ataxia/levi/levi_scripts/`.

| Class | Command | Kill Route |
|-------|---------|------------|
| Serpent | `ek` | Ekanelia lock, darkshade, scytherus |
| Shaman | `zz` | Tzantza, affliction locks, bleed |
| Blademaster | `bmd`/`bmbs` | Limb prep, brokenstar |
| Infernal DWC | `zz` | Vivisect, damage kill |
| Apostate | `ll`/`corr` | Lock, corrupt, vivisect |
| Monk (Shikudo) | varies | Limb prep, spinkick |

### Automated Basher

PvE hunting system with 20+ class support, area pathing, and safety features.

**Location**: `src_new/scripts/levi_ataxia/levi/ataxia/basher/` and `genrunning/`

```lua
ataxiaBasher.paused = false   -- Enable basher
ataxiaBasher.paused = true    -- Pause basher
ataxiaBasher_manual()         -- Single-room manual mode
ataxiaBasher_areabash()       -- Full area automation

-- Configure
ataxiaBasher.goldPack = "pack436363"
ataxiaBasher.shieldTimers = { ["a mhun knight"] = 4.7 }
ataxiaBasher.ldeckRules = {
  { mob = "an elite mhun keeper", count = 3, cards = {"maran", "matic"} },
}
```

### Custom GUI (ataxiagui)

Health/mana gauges, map display, tabbed chat, balance indicators.

```lua
ataxiagui_Create()  -- Create the GUI
```

### Player Database (ataxiaNDB)

Tracks player information via the Achaea API.

```lua
ataxiaNDB_isEnemy("PlayerName")
ataxiaNDB_getCitizenship("PlayerName")
ataxiaNDB_getColour("PlayerName")
```

---

## Source Code Layout

### File Organization

Each `.lua` file has a YAML metadata header and uses numbered prefixes for load order:

```
src_new/
├── scripts/levi_ataxia/levi/
│   ├── ataxia/                    # Core combat system
│   │   ├── 017_Affliction_Management.lua
│   │   ├── affliction_tracking_v2/  # V2 (deactivated, stubs route to V3)
│   │   ├── affliction_tracking_core/ # V3 probability engine (single source of truth)
│   │   ├── basher/                  # Bashing attack builders
│   │   ├── genrunning/              # Basher API and automation
│   │   ├── deffing/                 # Defense tracking
│   │   └── ...
│   └── levi_scripts/              # Class offense modules
│       ├── serpent/
│       ├── shaman/
│       ├── blademaster/
│       ├── dwc/
│       ├── apostate/
│       └── ...  (18+ class dirs)
├── triggers/                      # 1800+ game text triggers
├── aliases/                       # Command aliases
├── timers/                        # Timer definitions
└── keys/                          # Key bindings
```

### Finding Code

- **Affliction tracking**: `scripts/.../ataxia/017_Affliction_Management.lua`
- **V3 tracker**: `scripts/.../ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua` + `008_V3_Integration.lua`
- **Class offense**: `scripts/.../levi_scripts/<class>/`
- **Basher**: `scripts/.../ataxia/basher/` and `genrunning/`
- **GUI**: search `scripts/` for GUI creation files
- **Triggers**: `triggers/levi_ataxia/` organized by subsystem

### Group Hierarchy

Each item type has a `_groups.yaml` defining the folder tree in Mudlet. The conversion script uses these to build the JSON hierarchy that Muddler consumes.

---

## Common Tasks

### Rebuild After Editing

After modifying files in `src_new/`, rebuild:

```bash
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project
cd muddler_project
/path/to/muddler/bin/muddle.bat
```

Then reinstall the `.mpackage` in Mudlet.

Or use the **Build Levi_Ataxia** task in VS2022 (right-click root folder in Solution Explorer).

### Preview Without Building

```bash
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project --dry-run
```

### Build a Separate Package

```bash
python tools/convert_to_muddler.py --src ./src_new --output ./my_project \
  --package-name My_Package --package-title "My Package" --include-roots My_Package
```

See `python tools/convert_to_muddler.py --help` for all options.

---

## Dependencies and Load Order

1. **mmp** loads first (navigation foundation)
2. **ataxia** loads second (combat core)
3. **ataxiagui** needs ataxia
4. **ataxiaBasher** needs ataxia
5. **ataxiaNDB** is independent

Load order within each group is controlled by the numbered file prefixes.

---

## Extending the System

### Custom Aliases

```lua
-- Alias: ^target (.+)$
ataxia.target = matches[2]
echo("Target set to: " .. ataxia.target)
```

### Event Handlers

```lua
registerAnonymousEventHandler("gmcp.Char.Vitals", "myVitalsHandler")

function myVitalsHandler()
    -- Your code here
end
```

### Adding Functions

```lua
function ataxia.myCustomFunction()
    -- Your code here
end
```

---

## Troubleshooting

### Scripts Won't Load
1. Check Mudlet's error console for syntax errors
2. Verify GMCP is enabled (Settings > Protocols)
3. Ensure the package installed correctly (Package Manager shows it)

### Finding Functions
Use your editor's search across `src_new/`:
```bash
grep -r "functionName" src_new/
```

---

## Further Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview, build instructions, repo structure |
| [CLAUDE.md](CLAUDE.md) | Full technical reference — architecture, combat mechanics, APIs, development guidelines |
| [CHANGELOG.md](CHANGELOG.md) | Detailed change history |
| [docs/legend-deck.md](docs/legend-deck.md) | Legend Deck card effects and PVE guide |
