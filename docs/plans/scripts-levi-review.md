# Comprehensive Review: Scripts_Levi.xml

**Date**: 2024-12-18
**Source File**: `C:\Users\mikew\OneDrive\Desktop\Scripts_Levi.xml`
**File Size**: ~2MB

## Overview

This is a **Mudlet package XML file** for the MUD (Multi-User Dungeon) game client. The file is approximately 2MB and contains a sophisticated automation system primarily designed for **Achaea** (an Iron Realms Entertainment MUD), with additional support for other IRE games like Aetolia, Lusternia, Imperian, and Starmourn.

The package is named "For Levi" and consists of two major integrated systems:
1. **Mudlet Mapper (mmp)** - An advanced pathfinding and navigation system
2. **Ataxia** - A comprehensive combat and game automation system

---

## Core System 1: Mudlet Mapper (mmp)

### Purpose
Provides automated speedwalking, pathfinding, and map navigation for IRE MUDs.

### Key Features

#### 1. **Speedwalking System**
- `mmp.gotoRoom(roomID)` - Navigate to a specific room by ID
- `mmp.gotoArea(areaName)` - Navigate to the nearest entrance of an area
- `mmp.gotoFeature(featureName)` - Navigate to map features
- Automatic path recalculation when knocked off-path
- Support for ferry rooms and special transit

#### 2. **Path Optimization**
- `mmp.getPath(from, to)` - Calculate and cache paths
- `mmp.fixPath()` - Optimize paths for sprint/dash/gallop movement
- `mmp.getShortestOfMultipleRooms()` - Find closest destination from multiple options
- Path caching with automatic invalidation

#### 3. **Movement Modes**
- Normal walking
- Sprint, Dash, Gallop, Runaway (Jester ability)
- Swimming for water rooms
- Caravan leading (Imperian)

#### 4. **Fast Travel Integration**
Creates temporary special exits for game-specific travel methods:

**Achaea:**
- Wings (Duanathar, Duanatharan, Duantahar, Duanatharic)
- Aero Soar
- Universe Tarot
- Enchanted Pebble
- Gare
- Stratospheric Harness (for island travel)

**Imperian:**
- Shekinah (Seraphim Wings)
- Suriel (Orphanim Wings)

**Lusternia:**
- Torus, Cubix, Medallion, Prism
- Various Bubblix devices (Tibia, Mud, Cookie, Icicle, etc.)
- Curio collections (Bone, Face, Feather, Figure, Flower, etc.)
- Epic items (Fingerblade, Blossom, Belt, Mandala, etc.)

#### 5. **Configuration System**
- `createOption()` - Factory for typed, validated settings
- `createOptionsTable()` - Proxy table with getter/setter protection
- Settings include: echo colors, lag levels, crowd-sourced maps, movement locks

#### 6. **Balance Detection**
- Integrates with GMCP to check balance/equilibrium before moving
- Waits for combat balances before continuing speedwalk
- Handles Lusternia's extended balance types (psi, limbs)

#### 7. **Area Management**
- Area border detection for efficient area navigation
- Continent tracking (Main, Meropis, Eastern/Northern/Western Isles)
- Environment-based routing (avoids water without waterwalk)

---

## Core System 2: Ataxia Combat System

### Purpose
A comprehensive combat automation, affliction tracking, and defense management system for Achaea.

### Key Features

#### 1. **Affliction Tracking**
- Tracks 100+ afflictions with color-coded display
- Categories include:
  - Physical (paralysis, slickness, asthma, etc.)
  - Mental (stupidity, confusion, dementia, etc.)
  - Spiritual (disfigurement, soul/mind damage)
  - Limb damage (broken legs/arms, mangled, mutilated)
  - Smoke-based (aeon, deadening, disloyalty)
  - Class-specific (Psion, Priest, Pariah afflictions)
  - Writhe afflictions (transfixation, impaled, webbed)
  - Timed effects (blackout, burns, scalded)

#### 2. **Limb Tracking System**
- `selfLimbDamage` - Tracks damage to your own limbs
- Calculates damage percentages based on max health
- Class-specific damage calculations:
  - Blademaster (armslash, legslash, centreslash)
  - Knight (SnB, DWC)
  - Earth Lord elemental attacks
- Miss detection (parry, dodge, rebounding, reflections)

#### 3. **Fracture Management (Two-Handed Combat)**
- Tracks skull fractures, wrist fractures, torn tendons, cracked ribs
- Automatic affliction relapses based on fracture count
- Color-coded display (green < yellow < orange < red)

#### 4. **Defense Management**
- Automatic parrying with limb priority
- Integration with server-side curing
- Density/shackle handling for movement
- Bard symphony management

#### 5. **Basher System (Automated Hunting)**
- `ataxiaBasher` - Automated mob targeting and killing
- Room scanning for denizens
- Health-based fleeing
- Class-specific bashing (Magi, Dragon, etc.)
- Target pattern matching
- Pause/resume functionality

#### 6. **GUI System (ataxiagui)**
- Custom graphical interface using Geyser
- Components:
  - Left panel: Players, Room info, Bash stats
  - Right panel: Map display, Chat tabs
  - Bottom panel: Health/Mana/Willpower/Endurance gauges
  - Balance/Equilibrium indicators
- Tabbed chat system (All, City, Clans, Misc, Order, Party, Tells)
- GMCP-based chat capture

#### 7. **Player Database (ataxiaNDB)**
- Fetches player info from Achaea API
- Tracks: name, city, house, class, level, XP rank, player kills
- City-based name highlighting
- Enemy tracking
- Army rank and mark tracking
- Automatic API updates on player sighting

#### 8. **Class-Specific Modules**
- **Pariah**: Swarm management, logograph chaining, plague tracking
- **Bard**: Limb counter, symphony tracking
- **Monk**: Tekura limb tracking, guard instead of parry
- **Magi**: Staff/elemental combat
- **Two-Handed**: Fracture relapses

---

## Additional Components

### Matrix Library
A complete Lua matrix mathematics library including:
- Matrix operations (add, sub, mul, div, power)
- Determinant calculation (Gaussian, Laplace, Bareiss)
- Matrix inversion and solving linear systems
- Vector operations (cross product, scalar product)
- Symbolic matrix support

### Utility Functions
- `mmp.deepcopy()` - Deep table copying
- `mmp.searchRoom()`/`mmp.searchRoomExact()` - Cached room searches
- `mmp.cleanAreaName()` - Format area names for display
- `mmp.cleanroomname()` - Strip prefixes/suffixes from room names
- ANSI to decho/cecho conversion

---

## Event System

The package extensively uses Mudlet's event system:

### Mapper Events
- `gmcp.Room.Info` - Room change detection
- `mmp link externals` / `mmp clear externals` - Wing/travel exit management
- `mmapper arrived` / `mmapper failed path` / `mmapper stopped`
- `mmapper went inside` / `mmapper went outside`
- `mmapper changed continent`
- `mmp logged in` - Game detection

### Ataxia Events
- `gmcp.Char.Vitals` - Health/mana updates
- `gmcp.Comm.Channel.Start` - Chat capture
- `aff gained` / `aff lost` - Affliction tracking
- `ataxia system loaded` - Initialization

---

## Configuration Storage

- Settings stored in proxy tables with type validation
- Persistent save/load functionality
- Game-specific settings (some options only apply to certain MUDs)
- Per-city highlighting preferences

---

## Summary

This is a professional-grade MUD automation package that provides:
1. **Complete navigation automation** with intelligent pathfinding
2. **Combat tracking and assistance** with affliction/defense management
3. **Automated hunting/bashing** with safety features
4. **Custom GUI** with health bars and chat organization
5. **Player database** integration with the game's API
6. **Multi-game support** for the entire IRE game family

The code is well-structured with proper namespacing (`mmp`, `ataxia`, `ataxiagui`, `ataxiaNDB`) and extensive use of Mudlet's trigger/alias/script system.
