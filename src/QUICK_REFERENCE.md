# LEVI Achaea - Quick Reference Guide

## Loading the System

```lua
-- Load everything
dofile(getMudletHomeDir() .. "/LEVI-Achaea/src/loader.lua")
```

## Main Systems Overview

### MMP (Mudlet Mapper)
**What it does**: Navigation, pathfinding, speedwalking

**Key Functions**:
- Speedwalking to rooms
- Wings and fast travel
- Map tracking and updates
- Area locking

**Common Usage**:
```lua
-- Speedwalk to a room
mmp.gotoRoom(room_id)

-- Check configuration
mconfig

-- Lock/unlock areas
-- (see mmp API files)
```

### Ataxia Combat System
**What it does**: Affliction tracking, curing, combat offense

**Key Components**:
- `ataxia.afflictions` - Current afflictions table
- `ataxia.defences` - Defense tracking
- Curing priorities
- Class-specific offense

**Common Variables**:
```lua
ataxia.afflictions.paralysis  -- true/false
ataxia.defences.shield        -- defense status
ataxia.target                 -- current target
```

### Ataxia GUI
**What it does**: Visual interface with health bars, map, chat

**Key Functions**:
```lua
-- Create GUI
ataxiagui_Create()

-- Toggle GUI elements
-- (see GUI files for options)
```

**Features**:
- Health/mana/willpower/endurance bars
- Integrated map window
- Chat tabs and capture
- Responsive to window size

### Ataxia NDB (Name Database)
**What it does**: Player information and highlighting

**Key Functions**:
```lua
-- Check if player is enemy
ataxiaNDB_isEnemy(name)

-- Get player's city
ataxiaNDB_getCitizenship(name)

-- Get player's house
ataxiaNDB_getHouse(name)

-- Check if Mark
ataxiaNDB_isMark(name)

-- Get army rank
ataxiaNDB_armyRank(name)

-- Get color for highlighting
ataxiaNDB_getColour(name)
```

**Data Tracking**:
- City/faction membership
- House affiliations
- Mark status
- Army ranks
- Enemy status

### Ataxia Basher
**What it does**: Automated hunting and experience tracking

**Key Functions**:
```lua
-- Start bashing
ataxiaBasher.paused = false

-- Stop bashing
ataxiaBasher.paused = true

-- Check bash stats
-- (see bash stats functions)
```

**Features**:
- Auto-target selection
- Class-specific bashing attacks
- Experience tracking
- Auto-movement in areas
- Statistics tracking
- Legend Deck emergency cards (Maran barrier)

### Legend Deck Integration
**What it does**: Automatic card usage during bashing

**Key Variables**:
```lua
ataxia.maranThreshold = 25           -- HP% to trigger Maran barrier
ataxiaTables.ldeckcardscount.Maran   -- Remaining charges
```

**Emergency Cards** (triggered automatically):
- **Maran** - 5000hp barrier when HP < 25% while bashing

**See**: `docs/legend-deck.md` for full card reference

## File Organization

### Finding Specific Code

**Navigation/Mapping**: `src/mmp/`
- Speedwalking: `003_speedwalking.lua`, `066_mmp.speedwalking.lua`
- Wings: `004_Wings_functions.lua`, `068_Wings_functions.lua`
- API: `013_API.lua`, `079_API.lua`

**Combat/Afflictions**: `src/ataxia/`
- Affliction tracking: `023_Aff_gains_losses.lua`, `061_Affliction_Management.lua`
- Balance tracking: `007_Balance_Tracking.lua`
- Defenses: `018_Defence_API.lua`, `019_Deffing_Up.lua`
- Curing priorities: `025_Default_Curing_Prios.lua`, `026_Prio_Management.lua`
- Class combat: Files 043+ (Alchemist, Depthswalker, etc.)

**GUI**: `src/ataxiagui/`
- Layout: `001_Creation_Layout.lua`
- Map/Chat: `002_Map_and_Chat.lua`
- Vitals: `004_Vitals_Related.lua`

**Player Database**: `src/ataxiaNDB/`
- API: `005_ataxiaNDB_API.lua`
- Highlighting: `006_ataxiaNDB_Highlighting.lua`

**Bashing**: `src/ataxiaBasher/`
- Core: `005_Bashing_Functions.lua`
- Class attacks: `006_Class_Bashing.lua`
- API: `007_Bashing_API.lua`

## Load Order

The loader loads systems in this order:
1. **mmp** → Navigation (foundation)
2. **ataxia** → Combat system (core)
3. **ataxiagui** → GUI (depends on ataxia)
4. **ataxiaNDB** → Player DB (independent)
5. **ataxiaBasher** → Automated hunting (depends on ataxia)

Within each directory, files load in numeric order (001, 002, 003...).

## Common Tables and Globals

### MMP
```lua
mmp                    -- Main mapper table
mmp.roomslist          -- Room database
mconfig                -- Mapper configuration
```

### Ataxia
```lua
ataxia                 -- Main system table
ataxia.afflictions     -- Current afflictions
ataxia.defences        -- Current defenses
ataxia.target          -- Current combat target
ataxia.class           -- Character class
ataxia.usegui          -- GUI enabled flag
ataxiaTemp             -- Temporary data
```

### GUI
```lua
ataxiagui              -- GUI components
aBorders               -- Border settings
winWid, winHei         -- Window dimensions
```

### NDB
```lua
ataxiaNDB              -- Name database
ataxiaNDB.players      -- Player data
ataxiaNDB.cityEnemies  -- Enemy list
ataxiaNDB.highlighting -- Color settings
```

### Basher
```lua
ataxiaBasher           -- Basher system
ataxiaBasher.paused    -- Pause flag
ataxiaBasher.target    -- Current bash target
```

## Troubleshooting

### Scripts Not Loading
1. Check Mudlet error console
2. Verify file paths
3. Check for syntax errors in modified files
4. Ensure dependencies loaded first

### Finding Functions
1. Use grep to search: `grep -r "function_name" src/`
2. Check the hierarchy comment at top of each file
3. Look in the relevant system directory

### Dependencies
- GUI requires ataxia to be loaded first
- Basher requires ataxia to be loaded first
- Most systems require GMCP to be enabled
- Some features require specific game (Achaea)

## Customization

### Modifying Priorities
Edit: `src/ataxia/026_Prio_Management.lua`

### Changing GUI Layout
Edit: `src/ataxiagui/001_Creation_Layout.lua`

### Adding New Bash Targets
Edit: `src/ataxiaBasher/005_Bashing_Functions.lua`

### Configuring Mapper
Use `mconfig` command in-game or edit config files

## GMCP Integration

The system relies heavily on GMCP data:
- `gmcp.Char.Vitals` - Health, mana, etc.
- `gmcp.Char.Status` - Class, level, etc.
- `gmcp.Room.Info` - Current room data
- `gmcp.Char.Items.List` - Inventory/room items
- `gmcp.Char.Defences.List` - Active defenses
- `gmcp.Char.Afflictions.List` - Current afflictions

Ensure GMCP is enabled in Mudlet settings!

## Next Steps

1. Load the system in Mudlet
2. Test each component individually
3. Configure settings for your character
4. Set up aliases and keybindings
5. Customize priorities and strategies

For detailed information, see:
- `README.md` - Full documentation
- `EXTRACTION_REPORT.md` - Technical details
- Individual `.lua` files - Inline comments
