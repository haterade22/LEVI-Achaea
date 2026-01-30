# Getting Started with LEVI Achaea Scripts

## Quick Start

### 1. Install the Package in Mudlet

Install the compiled package from `packages/` via Mudlet's Package Manager, or build it from source:

```bash
# Convert source to Muddler format
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project

# Build with Muddler (requires Java 17+)
cd muddler_project
muddle.bat
```

Output: `muddler_project/build/Levi_Ataxia.mpackage`

The package includes all systems:
- MMP (Mudlet Mapper)
- Ataxia (Combat System)
- Ataxia GUI
- Ataxia NDB (Player Database)
- Ataxia Basher

### 2. Verify GMCP is Enabled

The system heavily relies on GMCP. In Mudlet:
1. Go to Settings → Protocols
2. Ensure "Enable GMCP" is checked
3. Reconnect to Achaea if needed

### 3. Test Basic Functionality

```lua
-- Test mapper
mconfig

-- Check ataxia is loaded
display(ataxia)

-- Create GUI (if desired)
ataxiagui_Create()
```

## System Overview

### MMP (Mudlet Mapper)
**Location**: `src_new/scripts/` and `src_new/triggers/` (mapper components)

**What it does**:
- Navigation and pathfinding
- Speedwalking
- Wings and fast travel
- Map tracking

**Try it**:
```lua
-- Use mapper configuration
mconfig

-- Speedwalk to a room (if you know the room ID)
-- mmp.gotoRoom(12345)
```

### Ataxia Combat System
**Location**: `src_new/scripts/levi_ataxia/levi/ataxia/`

**What it does**:
- Tracks afflictions automatically
- Manages curing priorities
- Defense tracking
- Class-specific combat offense

**Key variables**:
```lua
ataxia.afflictions        -- Current afflictions table
ataxia.defences          -- Active defenses
ataxia.target            -- Combat target
```

**Try it**:
```lua
-- View current afflictions
display(ataxia.afflictions)

-- View defenses
display(ataxia.defences)
```

### Ataxia GUI
**Location**: `src_new/scripts/` (GUI components)

**What it does**:
- Health/mana/willpower/endurance bars
- Integrated map window
- Chat tabs and capture

**Try it**:
```lua
-- Create the GUI
ataxiagui_Create()
```

### Ataxia NDB (Name Database)
**Location**: `src_new/scripts/` (NDB components)

**What it does**:
- Tracks player information (city, house, rank)
- Highlights enemy names
- Provides player lookup API

**Try it**:
```lua
-- Check if someone is an enemy
ataxiaNDB_isEnemy("PlayerName")

-- Get someone's city
ataxiaNDB_getCitizenship("PlayerName")

-- Get highlight color
ataxiaNDB_getColour("PlayerName")
```

### Ataxia Basher
**Location**: `src_new/scripts/levi_ataxia/levi/ataxia/basher/` and `src_new/scripts/levi_ataxia/levi/ataxia/genrunning/`

**What it does**:
- Automated hunting/bashing with 20+ class support
- Two modes: manual (single room) and areabash (full path automation)
- GMCP-based balance tracking (learns per-class attack timing)
- Data-driven legend deck card draws before dangerous rooms
- Stormhammer multi-target tracking with dirty-flag caching
- Configurable shield retarget timers
- Death recovery, flee circuit breaker, mapper-stuck detection
- Battlerage rotation with rage conservation (skips abilities on low-HP mobs)
- Experience tracking and session statistics

**Try it**:
```lua
-- Pause/unpause basher
ataxiaBasher.paused = true   -- pause
ataxiaBasher.paused = false  -- unpause

-- Start manual bashing (single room)
ataxiaBasher_manual()

-- Start areabash (full area path automation)
ataxiaBasher_areabash()

-- Configure gold container
ataxiaBasher.goldPack = "pack436363"

-- Configure shield retarget timers
ataxiaBasher.shieldTimers = { ["a mhun knight"] = 4.7 }
ataxiaBasher.shieldTimerDefault = 3.1

-- Configure legend deck rules
ataxiaBasher.ldeckRules = {
  { mob = "an elite mhun keeper", count = 3, cards = {"maran", "matic"} },
  { mob = "a mhun knight", count = 3, cards = {"maran"} },
}

-- View learned balance samples
display(ataxiaBasher_balanceSamples)
```

## File Organization

### Understanding the Structure

Each file is numbered for load order:
```
001_Create_Option_Table.lua
002_Load_settings.lua
003_speedwalking.lua
...
```

Each file has a header comment showing where it came from:
```lua
-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Create Option Table
```

### Finding Specific Code

**Want to find navigation code?**
→ Search `src_new/scripts/` and `src_new/triggers/` for mapper-related files

**Want to find affliction tracking?**
→ Look in `src_new/scripts/levi_ataxia/levi/ataxia/` for affliction management files

**Want to modify the GUI?**
→ Search `src_new/scripts/` for GUI creation/layout files

**Want to modify bashing?**
→ Look in `src_new/scripts/levi_ataxia/levi/ataxia/basher/`

## Common Tasks

### Rebuild Package After Editing

After editing files in `src_new/`, rebuild the package with Muddler:

```bash
# Re-convert source to Muddler format
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project

# Build with Muddler
cd muddler_project
muddle.bat
```

Then reinstall the `.mpackage` from `muddler_project/build/` in Mudlet.

### Modify Curing Priorities

Search `src_new/scripts/` for prio management files.

### Add New Bashing Target

Edit files in `src_new/scripts/levi_ataxia/levi/ataxia/basher/`.

### Configure Mapper

Use in-game command: `mconfig`

## Troubleshooting

### Scripts Won't Load

**Check for errors**:
1. Look in Mudlet's error console
2. Check file paths are correct
3. Verify syntax (no typos introduced during edits)

**Common issues**:
- GMCP not enabled
- Missing dependencies
- Syntax errors in modified files

### Finding Functions

Use grep to search:
```bash
cd c:\Users\mikew\source\repos\Achaea\LEVI-Achaea\src_new
grep -r "function_name" .
```

### Understanding Dependencies

Load order matters:
1. **mmp** must load first (navigation foundation)
2. **ataxia** loads second (combat core)
3. **ataxiagui** needs ataxia
4. **ataxiaBasher** needs ataxia
5. **ataxiaNDB** is independent

## Advanced Usage

### Custom Aliases

Create aliases in Mudlet that call the system's functions:

```lua
-- Alias: ^target (.+)$
ataxia.target = matches[2]
echo("Target set to: " .. ataxia.target)

-- Alias: ^bash$
ataxiaBasher.paused = false
echo("Basher enabled")

-- Alias: ^nobash$
ataxiaBasher.paused = true
echo("Basher paused")
```

### Event Handlers

The system uses Mudlet events. You can add your own:

```lua
-- Register event for vitals update
registerAnonymousEventHandler("gmcp.Char.Vitals", "myVitalsHandler")

function myVitalsHandler()
    -- Custom code here
end
```

### Extending Functions

Add your own functions to the existing tables:

```lua
-- Add custom function to ataxia
function ataxia.myCustomFunction()
    -- Your code here
end
```

## Documentation

- **CLAUDE.md** - Full system documentation
- **EXTRACTION_REPORT.md** - Historical extraction details
- This file - Getting started guide

## Next Steps

1. Load the system in Mudlet
2. Enable GMCP
3. Create the GUI with `ataxiagui_Create()`
4. Test navigation with mapper
5. Explore the code in each directory
6. Customize to your preferences
7. Set up your aliases and keybindings

## Support

The code was extracted from a Mudlet XML package and organized into this modular structure. All original functionality is preserved.

For understanding specific systems:
- Check the file headers for hierarchy
- Look at function names and comments
- Search across files with grep
- Read the relevant system's files in numeric order

## Tips

1. **Start small**: Load one system at a time to understand it
2. **Test thoroughly**: Verify each feature works before customizing
3. **Back up**: Keep copies before making major changes
4. **Comment well**: Add your own comments when you understand code
5. **Use version control**: Commit working versions to git

---

**Have fun and happy hunting in Achaea!**
