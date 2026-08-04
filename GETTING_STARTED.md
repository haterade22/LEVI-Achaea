# Getting Started with LEVI-Achaea

## Quick Start

### 1. Build and Install

See [README.md](README.md) for full build instructions. The short version:

```bash
# One-command build (recommended)
./build.sh

# Or step by step:
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project
set JAVA_HOME=C:\Path\To\Java
cd muddler_project
/path/to/muddler/bin/muddle.bat
```

**VS Code**: Press `Ctrl+Shift+B` to build. **Claude Code**: Type `/build`.

Output: `muddler_project/build/Levi_Ataxia.mpackage`

Install in Mudlet via Package Manager. **One-time:** add a saved variable `_ataxia_backup` (type: table) in Mudlet's Variables panel — it's the profile-backup fallback the resilient loader uses if a disk save goes missing. Installing loads your settings automatically; reconnect to Achaea for GMCP.

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

### 4. Updating the System

The system checks for updates automatically on every login (5 seconds after load). If a new version is available, you'll see a notification.

To update:
```
sysupdate
```

This downloads the latest package from GitHub, replaces the old installation, and cleans up automatically. No manual download or reinstall needed.

### 5. Test Basic Functionality

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

### Gear Management

Audit your gear inventory and find Best-in-Slot items for PvE.

```lua
gearaudit            -- Scan all gear (GEAR LIST ALL + GEAR PROBE)
gearaudit show       -- Full table of every item and what it does
gearaudit detail 1667 -- Every raw effect line for one item
gearaudit bis        -- PvE Best-in-Slot analysis (per set + overall)
gearaudit bis head   -- BiS for a specific slot
gearaudit score 1667 -- Detailed score breakdown for an item
gearaudit scrap      -- Items to scrap -- AUTO-SENDS the GEAR SCRAP commands
```

Scoring prioritizes: damage % > celerity > burst > resistance penetration > crit > survivability. Weights are configurable via `gearAudit.config.bisWeights`.

`gearaudit show` and `gearaudit bis` never truncate — columns size themselves to your data and long effect text wraps onto continuation rows, fitted to your console width. If an effect prints as a full raw game sentence rather than a short summary, that is a wording the summarizer has no pattern for yet.

> **Warning:** `gearaudit scrap` is destructive and has no confirmation prompt. It queues `GEAR SCRAP <id> CONFIRM` for every recommendation and sends them, one per balance. Review `gearaudit bis` before running it.

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

### Updating the Package

**For users**: Just type `sysupdate` in-game. The system handles everything automatically.

**For developers releasing a new version**:
1. Bump version: `/version-bump <new_version>` in Claude Code, or manually update `version.txt`, `muddler_project/mfile`, and `ataxiaVersion` in `_groups.yaml`
2. Build: `./build.sh` or press `Ctrl+Shift+B` in VS Code
3. Commit, tag, and push: `git tag v<version>` → `git push && git push origin v<version>`
4. CI/CD automatically creates a GitHub Release with the `.mpackage`

> **Push the one tag by name — never `git push --tags`.** It pushes every stale local tag too,
> and each one fires the release workflow against *that tag's old source*. GitHub picks
> "Latest" by publish time rather than version number, so a stale release published last
> hijacks `releases/latest/download/Levi_Ataxia.mpackage` — the URL `sysupdate` installs from.

### Rebuild After Editing

After modifying files in `src_new/`, rebuild:

```bash
./build.sh                 # Full build
./build.sh --convert-only  # Convert only (skip Muddler)
./build.sh --dry-run       # Preview without writing
```

Or press `Ctrl+Shift+B` in VS Code, or use `/build` in Claude Code.

Then reinstall the `.mpackage` in Mudlet.

### Run Tests

```bash
lua5.1 src_new/tests/test_runner.lua
```

Or use the "Run Tests" task in VS Code. Tests use `src_new/tests/mock_mudlet.lua` to stub the Mudlet API so combat logic can run outside the client.

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

## Development Tools

| Tool | Purpose |
|------|---------|
| `build.sh` | One-command build: `./build.sh [--dry-run] [--convert-only]` |
| `.vscode/tasks.json` | VS Code build/test tasks (`Ctrl+Shift+B`) |
| `.luacheckrc` | Lua 5.1 linter config (run with `luacheck src_new/`) |
| `stylua.toml` | Lua formatter config (run with `stylua src_new/path/to/file.lua`) |
| `.github/workflows/build.yml` | CI/CD: syntax check, version check, tests, release builds |
| `.claude/skills/` | `/build` and `/version-bump` slash commands for Claude Code |
| `.claude/agents/` | Custom subagents for offense development, builds, and team work |
| `.claude/hooks/` | Automated quality gates (see below) |

## Claude Code Hooks

The project uses hooks (configured in `.claude/settings.local.json`) to enforce quality gates automatically:

| Hook | Trigger | What it does |
|------|---------|-------------|
| `session-start.sh` | Session start | Shows branch, version, recent commits, uncommitted changes |
| `pre-compact.sh` | Context compaction | Saves working state to stderr so it survives into post-compact context |
| `lint-before-commit.sh` | `git commit` | Validates Lua syntax on staged `.lua` files (strips YAML headers) |
| `protect-config.sh` | Write/Edit | Blocks AI edits to `.claude/settings*.json` |
| `block-git-bypass.sh` | Bash (git) | Blocks `--no-verify`, `--force`, `--hard`, `--no-gpg-sign` |
| *(inline)* | Bash (build) | Prevents concurrent build processes |

Exit codes: **0** = allow, **2** = block. If a hook blocks your commit, fix the issue and retry.

## Further Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview, build instructions, repo structure |
| [CLAUDE.md](CLAUDE.md) | Full technical reference — architecture, combat mechanics, APIs, development guidelines |
| [CHANGELOG.md](CHANGELOG.md) | Detailed change history |
| [docs/legend-deck.md](docs/legend-deck.md) | Legend Deck card effects and PVE guide |
