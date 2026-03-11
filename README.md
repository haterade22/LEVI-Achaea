# LEVI-Achaea

A comprehensive [Mudlet](https://www.mudlet.org/) automation and combat system for [Achaea](https://www.achaea.com/), an Iron Realms Entertainment MUD.

## Credits

The GUI system (zGUI Redux) was originally created by **Zulah**. It has been enhanced and extended with additional features including namespace migration, configurable vital bars, channel-colored chat, and movable window management.

## Features

### Combat System (Ataxia)

| Feature | Description |
|---------|-------------|
| **Affliction Tracking** | Branching probability tracker (V3) — models multiple possible world states, resolves ambiguous cures via probabilistic branching and verification collapse |
| **Automated Curing** | SSC integration with custom priority management, curingset profiles |
| **Defense Management** | Automatic defense rekeeping, parry system, anti-class priority adjustments |
| **Limb Tracking** | Self limb counter (SLC) with percentage-based damage, auto-parry, threshold alerts, party callouts |
| **Target Affliction Tracking** | V3 probability engine with branching cure prediction, lock detection at configurable confidence thresholds |

### Class Offense Modules (18+ Classes)

| Class | Command | Kill Route |
|-------|---------|------------|
| Serpent | `ek` | Ekanelia lock, darkshade, scytherus, hypnosis |
| Shaman | `zz` | Tzantza, affliction locks, bleed, relapse jinx |
| Blademaster | `bmd`/`bmbs` | Limb prep, brokenstar, lightning/ice |
| Infernal DWC | `zz` | Vivisect (4-limb / 2-limb), damage kill, riftlock |
| Apostate | `ll`/`corr` | Lock, corrupt, vivisect, sleep |
| Monk (Shikudo) | varies | Limb prep, spinkick, telepathy lock |
| Psion | `zz`/`psmind`/`psflurry` | Mana kill (Psi Excise), unweave execute (Deconstruct), damage burst (Flurry) |
| Magi | `zz`/`xx`/`vv`/`cc` | Elementalism: salve push, fire burns, water freeze, lock, group, stormhammer |
| Snipe | `snt` | Class-agnostic snipe with auto-scan |
| *+ 10 more* | | Bard, Depthswalker, Pariah, Earth Lord, etc. |

### Automated Basher (PvE Hunting)

| Feature | Description |
|---------|-------------|
| **20+ Class Support** | Class-specific attack builders with optimal ability selection |
| **Area Pathing** | Mapper-integrated speedwalking through configured target lists |
| **Safety System** | Layered danger levels (shield/flee/wait), death recovery with safe-room retreat, stuck detection |
| **Battlerage** | Generic and crowd-control handlers with rage conservation |
| **Stormhammer** | Dirty-flag cached AoE target list for multi-target rooms |
| **Legend Deck** | Data-driven pre-combat card draws for dangerous rooms |
| **Shield Retarget** | Per-mob configurable shield durations with target swapping |
| **Armour Paragons** | Profile-based paragon/trait swapping with auto-swap on basher enable/disable |

### Armour & Paragon Management (`armour`)

Configurable profile system for armour paragon slots (1-3), trait selections, and armour morphing. Replaces 8+ hardcoded aliases with a single `armour` command.

| Command | Action |
|---------|--------|
| `armour` | Show all profiles and auto-swap status |
| `armour <name>` | Swap to a named profile (e.g., `armour bash`, `armour pvp`) |
| `armour add <name>` | Create a new profile |
| `armour set <n> slot1 <id>` | Set paragon in embrasure slot 1 (slot1/slot2/slot3) |
| `armour set <n> traits <...>` | Set trait list (space-separated) |
| `armour set <n> armourtype <t>` | Set morph target (`fullplate`, `cloth`, `auto`, `none`) |
| `armour auto on/off` | Toggle auto-swap on basher enable/disable |
| `armour bash <name>` | Set which profile activates when basher starts |
| `armour pvp <name>` | Set which profile activates when basher stops |
| `armour morph <type/auto>` | Manually morph armour type (10min cooldown) |
| `armour scan` | Auto-detect owned paragons via `ii paragon` + current embrasures via `probe armour` |
| `armour paragons` | Show all known paragons |

**Pre-configured profiles**: bash, pvp, stickpvp, magepve, serppve, stickpve, pariahpve, bmpve

**Auto-swap**: When `armour auto on` is set, the system automatically swaps to your bash profile when the basher starts and your PvP profile when it stops. No manual intervention needed.

**Armour morphing**: If a profile has `armourType = "auto"`, the system looks up the correct armour type for your current class (e.g., fullplate for knights, cloth for magi) and morphs automatically.

### GUI System (Enhanced zGUI Redux)

*Originally created by Zulah, enhanced with additional features.*

| Feature | Description |
|---------|-------------|
| **Draggable Windows** | ~20 `Adjustable.Container` windows with auto-save/load positions |
| **Tabbed Chat** | All, City, House, Order, Party, Clans, Tells, Market, Misc tabs |
| **Native MUD Colors** | Preserves original ANSI colors from the server via `ansi2decho()` + `decho()` |
| **Movable Vital Bars** | Configurable floating gauges for Health, Mana, Willpower, Endurance, Cape (`ataxiabars`) |
| **Health/Mana Gauges** | Gradient-styled gauges with clear overlays in the bottom panel |
| **XP Progress Bar** | Purple gauge showing progress to next level |
| **Deathcape Tracker** | Kill counter (0-50) with 240-second timer bar |
| **Balance Indicators** | Visual bal/eq icons in the bottom panel |
| **Map Display** | Integrated Mudlet mapper window |
| **Pop-Out Windows** | Double-click any window to pop into a separate OS window |
| **Window Reset** | `zfix <name>` to reset any window to default position |
| **Hunting Stats** | Session kill count, gold earned, XP/hour tracking |

### Movable Vital Bars (`ataxiabars`)

Individually movable, configurable gauge bars that float anywhere on screen:

| Command | Action |
|---------|--------|
| `ataxiabars` | Show status of all bars |
| `ataxiabars on` / `ataxiabars off` | Master toggle |
| `ataxiabars health` | Toggle health bar |
| `ataxiabars mana` | Toggle mana bar |
| `ataxiabars willpower` | Toggle willpower bar |
| `ataxiabars endurance` | Toggle endurance bar |
| `ataxiabars cape` | Toggle cape tracker bar |
| `ataxiabars reset` | Reset all bar positions to defaults |

Defaults: health, mana, and cape enabled; willpower and endurance off. Drag bars to reposition; positions auto-save.

### Player Database (ataxiaNDB)

| Feature | Description |
|---------|-------------|
| **API Integration** | Fetches online player data from `api.achaea.com` |
| **City Highlighting** | Color-coded player names by city affiliation |
| **Enemy Tracking** | Enemy formatting (bold/italic/underline), priority over city color |
| **Threat Intelligence** | `an marks`, `an army`, `an dauntless`, `an threats` queries |
| **Auto-Honours** | Automatically honours hidden-city players to resolve affiliation |
| **Bulk Refresh** | `an refresh [city]` to update mark/army/dauntless for all tracked players |
| **Player Notes** | `an noteadd/noteshow/noteremove` per-player notes |

### Navigation (Mudlet Mapper / mmp)

| Feature | Description |
|---------|-------------|
| **Speedwalking** | `mmp.gotoRoom(id)` with optimized pathing |
| **Fast Travel** | Wings, tarot, harness, pebble integration |
| **Balance-Aware** | Movement waits for balance recovery |
| **Multi-Game** | Supports Achaea, Aetolia, Lusternia, Imperian |
| **Area Navigation** | `mmp.gotoArea(name)`, `mmp.gotoFeature(name)` |

### Auto-Update System

| Feature | Description |
|---------|-------------|
| **Version Check** | Automatic check on login — compares local version against GitHub `version.txt` |
| **One-Command Update** | Type `sysupdate` to download, uninstall old, install new, and clean up |
| **Async Downloads** | Uses Mudlet's `sysDownloadDone` event pattern (no fragile timer delays) |
| **Error Handling** | Reports download failures via `sysDownloadError` |

### Configuration & Setup

| Feature | Description |
|---------|-------------|
| **Setup Wizard** | `ataxia setup` — guided configuration for all subsystems |
| **Per-System Install** | `atinstall`, `abinstall`, `aninstall` for targeted setup |
| **Config Guides** | `ataxia setup guide ataxia/basher/ndb` for comprehensive option walkthrough |
| **Settings Persistence** | All settings saved to disk via `table.save`/`table.load` |

## Affliction Tracker (V3 Branching Probability Engine)

The affliction tracker is the core combat intelligence system. It tracks what afflictions the target currently has, resolving the fundamental problem in Achaea combat: **ambiguous cures**. When a target eats an herb that could cure any of several afflictions, which one was actually cured?

### The Problem

In Achaea, each herb cures multiple possible afflictions. For example, eating **kelp** cures one of: asthma, weariness, clumsiness, sensitivity, hypochondria, parasite, or healthleech. When the target eats kelp and we've given them both asthma and clumsiness, we see the cure happen but don't know *which* affliction was removed.

A simple boolean tracker must guess — and guessing wrong means our offense works against a fiction, wasting attacks or missing kill windows. The V3 system eliminates guessing entirely.

### How It Works: Branching States

Instead of tracking afflictions as simple true/false values, V3 maintains **multiple possible world states simultaneously**, each with a probability weight. All probabilities always sum to 1.0.

**Core data structure:**
```
afflictionStatesV3 = {
    {affs = {asthma=true, paralysis=true}, prob = 0.6},
    {affs = {paralysis=true},              prob = 0.4},
}
-- "60% chance target has both asthma+paralysis, 40% chance only paralysis"
```

#### Definite Operations (No Branching)

When we **inflict** an affliction (confirmed by a hit trigger), it's added to every branch:
```
Before:  {asthma=T} @ 60%  |  {} @ 40%
Apply paralysis →
After:   {asthma=T, paralysis=T} @ 60%  |  {paralysis=T} @ 40%
```

When we **confirm** a cure (unambiguous removal), it's removed from every branch:
```
Before:  {asthma=T, paralysis=T} @ 60%  |  {paralysis=T} @ 40%
Remove paralysis →
After:   {asthma=T} @ 60%  |  {} @ 40%
```

#### Ambiguous Cures: The Branching Step

When the target eats an herb that could cure multiple afflictions they have, the system **splits each branch** into sub-branches — one for each possible cure outcome — dividing the probability equally:

```
Before:  {paralysis=T, slickness=T} @ 100%
Target eats bloodroot (cures paralysis OR slickness) →

After:
  Branch A: {slickness=T}  @ 50%   (paralysis was cured)
  Branch B: {paralysis=T}  @ 50%   (slickness was cured)
```

A more complex example with multiple pre-existing branches:
```
Before:
  {asthma=T, paralysis=T, slickness=T} @ 60%
  {paralysis=T, slickness=T}            @ 40%

Target eats bloodroot (cures paralysis OR slickness):

After:
  {asthma=T, slickness=T}  @ 30%   (from 60%, paralysis cured)
  {asthma=T, paralysis=T}  @ 30%   (from 60%, slickness cured)
  {slickness=T}             @ 20%   (from 40%, paralysis cured)
  {paralysis=T}             @ 20%   (from 40%, slickness cured)
```

#### Verification Signals: The Collapse Step

Branches are resolved by **verification signals** — observable in-game events that prove an affliction's presence or absence:

| Signal | Proves | Example |
|--------|--------|---------|
| Target fumbles | Clumsiness present | `collapseAffPresentV3("clumsiness")` |
| Target vomits | Nausea present | `collapseAffPresentV3("nausea")` |
| Target smokes | Asthma absent | `collapseAffAbsentV3("asthma")` |
| Target applies salve | Slickness absent | `collapseAffAbsentV3("slickness")` |
| Target stumbles | Dizziness present | `collapseAffPresentV3("dizziness")` |
| Target has seizure | Epilepsy present | `collapseAffPresentV3("epilepsy")` |
| Target paralysis fires | Paralysis present | `collapseAffPresentV3("paralysis")` |

**Collapse algorithm**: Eliminate all branches that contradict the observation, then renormalize:

```
Before:
  {clumsiness=T, asthma=T}  @ 60%
  {asthma=T}                 @ 40%

Observation: target fumbled (proves clumsiness present)
→ Eliminate branches without clumsiness (40% branch removed)
→ Renormalize: 60% → 100%

After:
  {clumsiness=T, asthma=T}  @ 100%
```

This is mathematically equivalent to Bayesian updating — each observation narrows the probability distribution.

### Querying Affliction State

The system provides probabilistic queries instead of binary answers:

| Function | Returns | Usage |
|----------|---------|-------|
| `haveAffV3(aff)` | Boolean (prob >= 30%) | Standard combat decisions |
| `haveAffV3(aff, 0.9)` | Boolean (prob >= 90%) | High-confidence gates |
| `getAffProbabilityV3(aff)` | Float 0.0–1.0 | Exact probability |
| `getStateProbabilityV3(affList)` | Float 0.0–1.0 | Joint probability of multiple affs |
| `getAllAffProbabilitiesV3()` | Table {aff=prob, ...} | Full state snapshot |

**Lock detection** uses joint probabilities:
```
Softlock  = P(anorexia AND asthma AND slickness)
Hardlock  = P(anorexia AND asthma AND slickness AND impatience)
Truelock  = P(anorexia AND asthma AND slickness AND impatience AND paralysis)
```

Locks display at 30%+ probability, with color intensity increasing at 90%+.

### Performance: Keeping Branch Count Manageable

Without constraints, branches would grow exponentially. Three mechanisms prevent this:

1. **Deduplication**: After branching, identical affliction sets (same affs, different histories) are merged by summing their probabilities. This is the primary reduction — most cures produce duplicate states.

2. **Pruning**: Branches below 1% probability are eliminated and their probability mass is redistributed proportionally to surviving branches.

3. **Hard cap**: If branches exceed 50 (configurable), the lowest-probability branches are dropped and probability is redistributed.

All queries use a **pre-computed cache** (`affCacheV3`) rebuilt after every state change, providing O(1) lookups regardless of branch count.

### Simple Tracking (Non-Branching)

Some afflictions never need branching because they're cured through unambiguous channels (limb restoration, writhing, etc.). These are tracked as simple booleans for efficiency:

- Limb damage states (broken/damaged/mangled legs, arms, head)
- Status effects (prone, stun, unconscious, sleeping)
- Sensory (blindness, deafness)
- Defenses tracked as afflictions (rebounding, shield)

### Architecture

V3 is the single source of truth. The legacy boolean table (`tAffs`) is maintained as a synchronized read cache for backward compatibility with 89+ direct-access sites across 30+ files.

```
                    ┌─────────────────────────┐
                    │    V3 Branching Engine   │
                    │  afflictionStatesV3[]    │
                    │  affCacheV3{}            │
                    └────────┬────────────────┘
                             │ syncToOldSystemV3()
    ┌────────────────────────┼────────────────────────┐
    │                        │                        │
    ▼                        ▼                        ▼
 tarAffed()              erAff()                 haveAff()
 (apply aff)          (remove aff)            (query aff)
    │                        │                        │
    ├─ tAffs[x]=true         ├─ tAffs[x]=false       ├─ haveAffV3()
    ├─ applyAffV3()          ├─ removeAffV3()         └─ fallback: tAffs
    └─ raiseEvent            └─ raiseEvent
```

**Key files:**
- `affliction_tracking_core/007_Branching_State_Tracker.lua` — V3 engine (branching, collapsing, cache, sync)
- `affliction_tracking_core/008_V3_Integration.lua` — Verification handlers, cure lists, lock detection, wrappers
- `017_Affliction_Management.lua` — Public API (`haveAff`, `tarAffed`, `erAff`)

---

## Quick Install

**Option A** — Use a pre-built package:
1. After building (see below), the package is at `muddler_project/build/Levi_Ataxia.mpackage`
2. Open Mudlet → Package Manager → Install
3. Select the `.mpackage` file

> **Note**: The `packages/` directory contains legacy XML builds. For the current version, always build from source using the steps below.

## Updating

The system includes a built-in auto-updater. On every login, it checks for new versions automatically.

| Scenario | What happens |
|----------|-------------|
| **Up to date** | Shows "Levi Ataxia vX.Y is up to date" |
| **New version available** | Shows notification with the new version number |
| **To update** | Type `sysupdate` in-game |

The `sysupdate` command downloads the latest `.mpackage` from GitHub, uninstalls the old package, installs the new one, and cleans up automatically.

---

## Building from Source

### Prerequisites

| Requirement | Details |
|-------------|---------|
| **Python 3.14+** | For the conversion script |
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
ataxia setup
```

### First-Time Install

Run these three commands to initialise the subsystems:

| Step | Command | What it does |
|------|---------|-------------|
| 1 | `atinstall` | Configures server-side curing (priorities, sipping, batching), prompt, and loads defaults. Type it twice within 5s to confirm. |
| 2 | `abinstall` | Initialises the basher (target lists, flee thresholds, shield timers) |
| 3 | `aninstall` | Sets up the player database (API integration, city-based name highlighting) |

Or use `ataxia setup install` for a guided walkthrough.

### Configuration Guide

After installing, `ataxia setup guide` shows every configurable option across all three subsystems:

| Command | Section |
|---------|---------|
| `ataxia setup guide ataxia` | Separator, system toggle, custom prompt, defence profiles, curing priorities, item highlighting, sipping, room shortening, GUI, raid mode |
| `ataxia setup guide basher` | Target lists, flee/shield thresholds, danger mobs, ignore lists, gold pack, shield swap/timer, rageraze, tree blackout |
| `ataxia setup guide ndb` | City highlight colours, highlight toggle/priority, enemy formatting, player notes, whois lookup |

### Quick Reference

| Command | Purpose |
|---------|---------|
| `ataxia setup` | Main menu — all setup categories |
| `ataxia setup class` | Set your class |
| `ataxia setup separator` | Set command separator (default `;`) |
| `ataxia setup weapons` | Configure weapon IDs |
| `ataxia setup basher` | Basher settings |
| `ataxia setup sipping` | Health/mana sip thresholds |
| `ataxia setup tracking` | Affliction tracking settings |
| `ataxia setup combat` | Combat toggles (party relay, looting, etc.) |
| `ataxia setup gui` | Toggle the GUI |
| `ataxia setup ndb` | NDB highlighting colours |
| `ataxia setup status` | Overview of all current settings |

---

## Player Database (ataxiaNDB)

The ataxiaNDB system tracks player information from the Achaea API and provides city-based name highlighting, enemy tracking, mark/army/dauntless detection, and player notes.

### Installation

Run `aninstall` in-game (or `ataxia setup install ndb`) to initialise the database. This fetches the online player list from the Achaea API and begins populating player records.

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

Or use the setup wizard: `ataxia setup ndb` for a guided menu.

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
├── version.txt                 # Package version (fetched by auto-updater on login)
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
| [.claude/classes/](.claude/classes/) | Per-class combat mechanic documentation (26 classes) |

---

## Technology

- **Language**: Lua 5.1
- **Platform**: Mudlet MUD Client
- **Build Tool**: Muddler (Java)
- **Conversion**: Python 3
- **Target Game**: Achaea (Iron Realms Entertainment)

## License

Private use.
